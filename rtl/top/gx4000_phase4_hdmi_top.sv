module gx4000_phase4_hdmi_top (
    input  wire        clk27,
    output wire [13:0] cart_a,
    output wire [4:0]  cart_ca,
    output wire        cart_ce_n,
    input  wire [7:0]  cart_d,
    output wire        cart_clk4,
    output wire        cart_cclr,
    input  wire        cart_sin,
    output wire        xlat_oe_n,

    // Two-wire controller expansion bus. The default external adapter uses an
    // MCP23017 at I2C address 0x20 for both digital controller ports.
    inout  wire        ctrl_sda,
    inout  wire        ctrl_scl,

    output wire        O_tmds_clk_p,
    output wire        O_tmds_clk_n,
    output wire [2:0]  O_tmds_data_p,
    output wire [2:0]  O_tmds_data_n
);
    wire [3:0] core_r, core_g, core_b;
    wire core_hsync, core_vsync, core_de, core_clk16;
    wire signed [15:0] core_audio_l, core_audio_r;

    wire [6:0] joy0_n;
    wire [6:0] joy1_n;
    wire controller_valid;
    wire controller_fault;

    mcp23017_controller_reader controller_reader (
        .clk16(core_clk16), .rst_n(~xlat_oe_n),
        .ctrl_sda(ctrl_sda), .ctrl_scl(ctrl_scl),
        .joy0_n(joy0_n), .joy1_n(joy1_n),
        .controller_valid(controller_valid),
        .controller_fault(controller_fault)
    );

    gx4000_phase4_top u_core (
        .clk27(clk27),
        .cart_a(cart_a), .cart_ca(cart_ca), .cart_ce_n(cart_ce_n),
        .cart_d(cart_d), .cart_clk4(cart_clk4), .cart_cclr(cart_cclr),
        .cart_sin(cart_sin), .xlat_oe_n(xlat_oe_n),
        .joy0_n(joy0_n), .joy1_n(joy1_n),
        // Analogue controller ADC hardware remains optional; these read as
        // full-scale until a dedicated ADC interface is added to the adapter.
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

    logic ready_meta, ready_sync;
    logic [7:0] reset_hold = 8'd0;
    always_ff @(posedge clk27) begin
        ready_meta <= ~xlat_oe_n;
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
    wire [3:0] hr, hg, hb;
    wire scan_locked;
    cpc_hdmi_scanconverter scan (
        .src_clk16(core_clk16), .src_reset_n(~xlat_oe_n),
        .src_r(core_r), .src_g(core_g), .src_b(core_b),
        .src_hsync(core_hsync), .src_vsync(core_vsync), .src_de(core_de),
        .dst_clk27(clk_pixel), .dst_reset(hdmi_reset),
        .dst_x(hx), .dst_y(hy), .dst_r(hr), .dst_g(hg), .dst_b(hb),
        .frame_locked(scan_locked)
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
        .reset(hdmi_reset), .video_r(hr), .video_g(hg), .video_b(hb),
        .audio_l(audio_l_48k), .audio_r(audio_r_48k),
        .pixel_x(hx), .pixel_y(hy), .video_active(active),
        .tmds_data(tmds_data), .tmds_clock(tmds_clock)
    );

    gowin_hdmi_phy phy (
        .tmds_clock(tmds_clock), .tmds_data(tmds_data),
        .O_tmds_clk_p(O_tmds_clk_p), .O_tmds_clk_n(O_tmds_clk_n),
        .O_tmds_data_p(O_tmds_data_p), .O_tmds_data_n(O_tmds_data_n)
    );

    wire _unused = &{1'b0, active, scan_locked, controller_valid, controller_fault};
endmodule
