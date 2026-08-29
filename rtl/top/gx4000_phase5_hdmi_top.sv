module gx4000_phase5_hdmi_top (
    input  wire        clk27,
    output wire [13:0] cart_a,
    output wire [4:0]  cart_ca,
    output wire        cart_ce_n,
    input  wire [7:0]  cart_d,
    output wire        cart_clk4,
    output wire        cart_cclr,
    input  wire        cart_sin,
    output wire        xlat_oe_n,
    inout  wire        ctrl_sda,
    inout  wire        ctrl_scl,
    output wire        O_tmds_clk_p,
    output wire        O_tmds_clk_n,
    output wire [2:0]  O_tmds_data_p,
    output wire [2:0]  O_tmds_data_n
);
    wire [13:0] core_cart_a;
    wire [4:0]  core_cart_ca;
    wire        core_cart_ce_n;
    wire        core_cart_clk4;
    wire        core_cart_cclr;
    wire        core_xlat_oe_n;
    wire [3:0] core_r, core_g, core_b;
    wire core_hsync, core_vsync, core_de, core_clk16;
    wire signed [15:0] core_audio_l, core_audio_r;

    logic [6:0] precharge_count = 7'd0;
    logic translator_precharged = 1'b0;
    always_ff @(posedge clk27) begin
        if (!translator_precharged) begin
            if (precharge_count == 7'd63)
                translator_precharged <= 1'b1;
            else
                precharge_count <= precharge_count + 7'd1;
        end
    end

    logic core_ready_meta = 1'b0;
    logic core_ready_sync = 1'b0;
    logic bus_live = 1'b0;
    always_ff @(posedge clk27) begin
        core_ready_meta <= ~core_xlat_oe_n;
        core_ready_sync <= core_ready_meta;
        if (!core_ready_sync)
            bus_live <= 1'b0;
        else if (!core_cart_clk4)
            bus_live <= 1'b1;
    end

    assign xlat_oe_n = ~translator_precharged;
    assign cart_a = bus_live ? core_cart_a : 14'd0;
    assign cart_ca = bus_live ? core_cart_ca : 5'd0;
    assign cart_ce_n = bus_live ? core_cart_ce_n : 1'b1;
    assign cart_clk4 = bus_live ? core_cart_clk4 : 1'b0;
    assign cart_cclr = translator_precharged ? 1'b1 : 1'b0;

    wire [6:0] joy0_n;
    wire [6:0] joy1_n;
    wire controller_valid;
    wire controller_fault;

    mcp23017_controller_reader controller_reader (
        .clk16(core_clk16), .rst_n(bus_live),
        .ctrl_sda(ctrl_sda), .ctrl_scl(ctrl_scl),
        .joy0_n(joy0_n), .joy1_n(joy1_n),
        .controller_valid(controller_valid),
        .controller_fault(controller_fault)
    );

    gx4000_phase4_top u_core (
        .clk27(clk27),
        .cart_a(core_cart_a), .cart_ca(core_cart_ca), .cart_ce_n(core_cart_ce_n),
        .cart_d(cart_d), .cart_clk4(core_cart_clk4), .cart_cclr(core_cart_cclr),
        .cart_sin(cart_sin), .xlat_oe_n(core_xlat_oe_n),
        .joy0_n(joy0_n), .joy1_n(joy1_n),
        .adc0(6'h3F), .adc1(6'h3F), .adc2(6'h3F), .adc3(6'h3F),
        .video_r(core_r), .video_g(core_g), .video_b(core_b),
        .video_hsync(core_hsync), .video_vsync(core_vsync), .video_de(core_de),
        .core_clk16(core_clk16),
        .audio_left(core_audio_l), .audio_right(core_audio_r)
    );

    wire clk_135, hdmi_pll_lock, clk_pixel;
    gowin_pll_135 u_hdmi_pll (
        .clkin(clk27), .clkout(clk_135), .lock(hdmi_pll_lock)
    );
    CLKDIV u_hdmi_clkdiv (
        .RESETN(hdmi_pll_lock), .HCLKIN(clk_135),
        .CLKOUT(clk_pixel), .CALIB(1'b1)
    );
    defparam u_hdmi_clkdiv.DIV_MODE = "5";
    defparam u_hdmi_clkdiv.GSREN = "false";

    logic ready_meta = 1'b0, ready_sync = 1'b0;
    logic [7:0] reset_hold = 8'd0;
    always_ff @(posedge clk27) begin
        ready_meta <= bus_live;
        ready_sync <= ready_meta;
        if (!hdmi_pll_lock || !ready_sync)
            reset_hold <= 8'd0;
        else if (reset_hold != 8'hFF)
            reset_hold <= reset_hold + 8'd1;
    end
    wire hdmi_reset = (reset_hold != 8'hFF);

    wire clk_audio;
    audio_clock_48k u_audio_clock (
        .clk_27m(clk27), .reset(hdmi_reset), .clk_audio(clk_audio)
    );

    wire [9:0] hx, hy;
    wire active;
    wire [3:0] scan_r, scan_g, scan_b;
    wire scan_locked;
    wire [9:0] measured_frame_lines;
    wire [10:0] measured_line_clocks;
    wire [7:0] lock_error_count;

    cpc_hdmi_adaptive_scanconverter scan (
        .src_clk16(core_clk16), .src_reset_n(bus_live),
        .src_r(core_r), .src_g(core_g), .src_b(core_b),
        .src_hsync(core_hsync), .src_vsync(core_vsync), .src_de(core_de),
        .dst_clk27(clk_pixel), .dst_reset(hdmi_reset),
        .dst_x(hx), .dst_y(hy),
        .dst_r(scan_r), .dst_g(scan_g), .dst_b(scan_b),
        .frame_locked(scan_locked),
        .measured_frame_lines(measured_frame_lines),
        .measured_line_clocks(measured_line_clocks),
        .lock_error_count(lock_error_count)
    );

    wire [9:0] min_frame_lines, max_frame_lines;
    wire [10:0] min_line_clocks, max_line_clocks;
    phase5_timing_trace timing_trace (
        .clk27(clk_pixel), .reset(hdmi_reset),
        .frame_lines(measured_frame_lines), .line_clocks(measured_line_clocks),
        .min_frame_lines(min_frame_lines), .max_frame_lines(max_frame_lines),
        .min_line_clocks(min_line_clocks), .max_line_clocks(max_line_clocks)
    );

    logic debug_combo_d = 1'b0;
    logic debug_enable = 1'b0;
    wire debug_combo = controller_valid && !joy0_n[5] && !joy0_n[6];
    always_ff @(posedge core_clk16) begin
        debug_combo_d <= debug_combo;
        if (debug_combo && !debug_combo_d)
            debug_enable <= ~debug_enable;
    end

    wire [7:0] status_flags = {
        scan_locked,
        controller_valid,
        controller_fault,
        bus_live,
        translator_precharged,
        hdmi_pll_lock,
        (core_audio_l != 16'sd0) || (core_audio_r != 16'sd0),
        core_ready_sync
    };

    wire [3:0] hdmi_r, hdmi_g, hdmi_b;
    phase5_debug_overlay overlay (
        .enable(debug_enable), .x(hx), .y(hy),
        .in_r(scan_r), .in_g(scan_g), .in_b(scan_b),
        .status_flags(status_flags),
        .frame_lines(measured_frame_lines),
        .min_frame_lines(min_frame_lines), .max_frame_lines(max_frame_lines),
        .line_clocks(measured_line_clocks),
        .min_line_clocks(min_line_clocks), .max_line_clocks(max_line_clocks),
        .lock_errors(lock_error_count),
        .out_r(hdmi_r), .out_g(hdmi_g), .out_b(hdmi_b)
    );

    logic signed [15:0] audio_l_meta, audio_l_48k;
    logic signed [15:0] audio_r_meta, audio_r_48k;
    always_ff @(posedge clk_audio or posedge hdmi_reset) begin
        if (hdmi_reset) begin
            audio_l_meta <= 16'sd0;
            audio_l_48k <= 16'sd0;
            audio_r_meta <= 16'sd0;
            audio_r_48k <= 16'sd0;
        end else begin
            audio_l_meta <= core_audio_l;
            audio_l_48k <= audio_l_meta;
            audio_r_meta <= core_audio_r;
            audio_r_48k <= audio_r_meta;
        end
    end

    wire [2:0] tmds_data;
    wire tmds_clock;
    gx4000_hdmi_tx tx (
        .clk_pixel(clk_pixel), .clk_pixel_x5(clk_135), .clk_audio(clk_audio),
        .reset(hdmi_reset), .video_r(hdmi_r), .video_g(hdmi_g), .video_b(hdmi_b),
        .audio_l(audio_l_48k), .audio_r(audio_r_48k),
        .pixel_x(hx), .pixel_y(hy), .video_active(active),
        .tmds_data(tmds_data), .tmds_clock(tmds_clock)
    );

    gowin_hdmi_phy phy (
        .tmds_clock(tmds_clock), .tmds_data(tmds_data),
        .O_tmds_clk_p(O_tmds_clk_p), .O_tmds_clk_n(O_tmds_clk_n),
        .O_tmds_data_p(O_tmds_data_p), .O_tmds_data_n(O_tmds_data_n)
    );

    wire _unused = &{1'b0, active, core_cart_cclr};
endmodule
