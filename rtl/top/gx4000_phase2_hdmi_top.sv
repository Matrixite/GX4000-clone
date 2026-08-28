module gx4000_phase2_hdmi_top (
    input  wire        clk27,

    output wire [13:0] cart_a,
    output wire [4:0]  cart_ca,
    output wire        cart_ce_n,
    input  wire [7:0]  cart_d,
    output wire        cart_clk4,
    output wire        cart_cclr,
    input  wire        cart_sin,
    output wire        xlat_oe_n,

    output wire        O_tmds_clk_p,
    output wire        O_tmds_clk_n,
    output wire [2:0]  O_tmds_data_p,
    output wire [2:0]  O_tmds_data_n
);
    wire [3:0] p2_r, p2_g, p2_b;
    wire p2_hsync, p2_vsync, p2_de;

    // Existing Phase-2 machine core: real cartridge -> mapper -> Z80/RAM/CRTC/GA.
    gx4000_phase2_top u_phase2 (
        .clk27(clk27),
        .cart_a(cart_a), .cart_ca(cart_ca), .cart_ce_n(cart_ce_n),
        .cart_d(cart_d), .cart_clk4(cart_clk4), .cart_cclr(cart_cclr),
        .cart_sin(cart_sin), .xlat_oe_n(xlat_oe_n),
        .video_r(p2_r), .video_g(p2_g), .video_b(p2_b),
        .video_hsync(p2_hsync), .video_vsync(p2_vsync), .video_de(p2_de)
    );

    // Existing standards-oriented HDMI transport clocking: 27 MHz pixel,
    // 135 MHz OSER10 serializer clock.
    wire clk_135;
    wire hdmi_pll_lock;
    wire clk_pixel;
    gowin_pll_135 u_hdmi_pll (
        .clkin(clk27), .clkout(clk_135), .lock(hdmi_pll_lock)
    );

    CLKDIV u_hdmi_clkdiv (
        .RESETN(hdmi_pll_lock), .HCLKIN(clk_135),
        .CLKOUT(clk_pixel), .CALIB(1'b1)
    );
    defparam u_hdmi_clkdiv.DIV_MODE = "5";
    defparam u_hdmi_clkdiv.GSREN = "false";

    // Phase-2 drives XLAT_OE_N low only after its own PLL/reset sequence.
    // Synchronize that ready state before releasing the HDMI pipeline.
    logic phase2_ready_meta, phase2_ready_sync;
    always_ff @(posedge clk27) begin
        phase2_ready_meta <= ~xlat_oe_n;
        phase2_ready_sync <= phase2_ready_meta;
    end

    logic [7:0] hdmi_reset_hold = 8'd0;
    always_ff @(posedge clk27) begin
        if (!hdmi_pll_lock || !phase2_ready_sync)
            hdmi_reset_hold <= 8'd0;
        else if (hdmi_reset_hold != 8'hFF)
            hdmi_reset_hold <= hdmi_reset_hold + 8'd1;
    end
    wire hdmi_reset = (hdmi_reset_hold != 8'hFF);

    wire clk_audio;
    audio_clock_48k u_audio_clock (
        .clk_27m(clk27), .reset(hdmi_reset), .clk_audio(clk_audio)
    );

    wire [9:0] hdmi_x, hdmi_y;
    wire hdmi_active;
    wire [3:0] hdmi_r, hdmi_g, hdmi_b;
    wire scan_locked;

    // Native 16 MHz CPC raster -> 720x576 HDMI active raster.
    cpc_hdmi_scanconverter u_scanconverter (
        .src_clk16(u_phase2.clk16),
        .src_reset_n(~xlat_oe_n),
        .src_r(p2_r), .src_g(p2_g), .src_b(p2_b),
        .src_hsync(p2_hsync), .src_vsync(p2_vsync), .src_de(p2_de),
        .dst_clk27(clk_pixel), .dst_reset(hdmi_reset),
        .dst_x(hdmi_x), .dst_y(hdmi_y),
        .dst_r(hdmi_r), .dst_g(hdmi_g), .dst_b(hdmi_b),
        .frame_locked(scan_locked)
    );

    wire [2:0] tmds_data;
    wire tmds_clock;

    // Phase 4 will replace these zero samples with AY + ASIC DMA audio.
    wire signed [15:0] silence_l = 16'sd0;
    wire signed [15:0] silence_r = 16'sd0;

    gx4000_hdmi_tx u_hdmi_tx (
        .clk_pixel(clk_pixel), .clk_pixel_x5(clk_135), .clk_audio(clk_audio),
        .reset(hdmi_reset),
        .video_r(hdmi_r), .video_g(hdmi_g), .video_b(hdmi_b),
        .audio_l(silence_l), .audio_r(silence_r),
        .pixel_x(hdmi_x), .pixel_y(hdmi_y), .video_active(hdmi_active),
        .tmds_data(tmds_data), .tmds_clock(tmds_clock)
    );

    gowin_hdmi_phy u_hdmi_phy (
        .tmds_clock(tmds_clock), .tmds_data(tmds_data),
        .O_tmds_clk_p(O_tmds_clk_p), .O_tmds_clk_n(O_tmds_clk_n),
        .O_tmds_data_p(O_tmds_data_p), .O_tmds_data_n(O_tmds_data_n)
    );

    wire _unused = &{1'b0, hdmi_active, scan_locked};
endmodule
