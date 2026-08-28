module gx4000_hdmi_tx (
    input  logic               clk_pixel,
    input  logic               clk_pixel_x5,
    input  logic               clk_audio,
    input  logic               reset,
    input  logic [3:0]         video_r,
    input  logic [3:0]         video_g,
    input  logic [3:0]         video_b,
    input  logic signed [15:0] audio_l,
    input  logic signed [15:0] audio_r,
    output logic [9:0]         pixel_x,
    output logic [9:0]         pixel_y,
    output logic               video_active,
    output logic [2:0]         tmds_data,
    output logic               tmds_clock
);
    logic [23:0] rgb888;
    logic [15:0] audio_sample_word [1:0];
    logic [9:0] frame_width, screen_width;
    logic [9:0] frame_height, screen_height;

    assign rgb888 = {video_r,video_r,video_g,video_g,video_b,video_b};
    assign audio_sample_word[0] = audio_l;
    assign audio_sample_word[1] = audio_r;
    assign video_active = (pixel_x < 10'd720) && (pixel_y < 10'd576);

    hdmi #(
        .VIDEO_ID_CODE(17),
        .VIDEO_REFRESH_RATE(50),
        .AUDIO_RATE(48000),
        .AUDIO_BIT_WIDTH(16),
        .DVI_OUTPUT(1'b0),
        .IT_CONTENT(1'b1),
        .VENDOR_NAME({"MATRIX",16'd0}),
        .PRODUCT_DESCRIPTION({"GX4000 FPGA",40'd0}),
        .SOURCE_DEVICE_INFORMATION(8'h08)
    ) u_hdmi (
        .clk_pixel_x5(clk_pixel_x5), .clk_pixel(clk_pixel),
        .clk_audio(clk_audio), .reset(reset), .rgb(rgb888),
        .audio_sample_word(audio_sample_word), .tmds(tmds_data),
        .tmds_clock(tmds_clock), .cx(pixel_x), .cy(pixel_y),
        .frame_width(frame_width), .frame_height(frame_height),
        .screen_width(screen_width), .screen_height(screen_height)
    );

    wire _unused = &{1'b0,frame_width,frame_height,screen_width,screen_height};
endmodule
