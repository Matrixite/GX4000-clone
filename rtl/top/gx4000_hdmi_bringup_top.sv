module gx4000_hdmi_bringup_top (
    input  wire       I_clk,
    input  wire       I_rst,
    output wire       O_tmds_clk_p,
    output wire       O_tmds_clk_n,
    output wire [2:0] O_tmds_data_p,
    output wire [2:0] O_tmds_data_n
);
    wire clk_135;
    wire pll_lock;
    wire clk_pixel;
    wire clk_audio;

    gowin_pll_135 u_pll (.clkin(I_clk), .clkout(clk_135), .lock(pll_lock));

    CLKDIV u_clkdiv (
        .RESETN(pll_lock), .HCLKIN(clk_135), .CLKOUT(clk_pixel), .CALIB(1'b1)
    );
    defparam u_clkdiv.DIV_MODE = "5";
    defparam u_clkdiv.GSREN = "false";

    logic [7:0] reset_hold = 8'd0;
    always_ff @(posedge I_clk or posedge I_rst) begin
        if (I_rst)
            reset_hold <= 8'd0;
        else if (!pll_lock)
            reset_hold <= 8'd0;
        else if (reset_hold != 8'hFF)
            reset_hold <= reset_hold + 1'b1;
    end
    wire reset = (reset_hold != 8'hFF);

    audio_clock_48k u_audio_clock (.clk_27m(I_clk), .reset(reset), .clk_audio(clk_audio));

    wire [9:0] px;
    wire [9:0] py;
    wire active;
    logic [3:0] r,g,b;

    always_comb begin
        r=4'h0; g=4'h0; b=4'h0;
        if (px < 10'd720 && py < 10'd576) begin
            if (px < 10'd90)       begin r=4'hF; g=4'hF; b=4'hF; end
            else if (px < 10'd180) begin r=4'hF; g=4'hF; b=4'h0; end
            else if (px < 10'd270) begin r=4'h0; g=4'hF; b=4'hF; end
            else if (px < 10'd360) begin r=4'h0; g=4'hF; b=4'h0; end
            else if (px < 10'd450) begin r=4'hF; g=4'h0; b=4'hF; end
            else if (px < 10'd540) begin r=4'hF; g=4'h0; b=4'h0; end
            else if (px < 10'd630) begin r=4'h0; g=4'h0; b=4'hF; end
            else                   begin r=4'h2; g=4'h2; b=4'h2; end
            if (px < 10'd4 || px >= 10'd716 || py < 10'd4 || py >= 10'd572)
                begin r=4'hF; g=4'hF; b=4'hF; end
        end
    end

    logic [5:0] audio_phase;
    logic signed [15:0] audio_l;
    logic signed [15:0] audio_r;

    always_ff @(posedge clk_audio or posedge reset) begin
        if (reset)
            audio_phase <= 6'd0;
        else if (audio_phase == 6'd47)
            audio_phase <= 6'd0;
        else
            audio_phase <= audio_phase + 1'b1;
    end

    always_comb begin
        if (audio_phase < 6'd24) begin
            audio_l = 16'sd8192;
            audio_r = 16'sd8192;
        end else begin
            audio_l = -16'sd8192;
            audio_r = -16'sd8192;
        end
    end

    wire [2:0] tmds;
    wire tmds_clk;

    gx4000_hdmi_tx u_tx (
        .clk_pixel(clk_pixel), .clk_pixel_x5(clk_135), .clk_audio(clk_audio),
        .reset(reset), .video_r(r), .video_g(g), .video_b(b),
        .audio_l(audio_l), .audio_r(audio_r), .pixel_x(px), .pixel_y(py),
        .video_active(active), .tmds_data(tmds), .tmds_clock(tmds_clk)
    );

    gowin_hdmi_phy u_phy (
        .tmds_clock(tmds_clk), .tmds_data(tmds),
        .O_tmds_clk_p(O_tmds_clk_p), .O_tmds_clk_n(O_tmds_clk_n),
        .O_tmds_data_p(O_tmds_data_p), .O_tmds_data_n(O_tmds_data_n)
    );

    wire _unused = active;
endmodule
