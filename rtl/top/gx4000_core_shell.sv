module gx4000_core_shell (
    input  logic        clk16,
    input  logic        reset_n,
    output logic [13:0] cart_a,
    output logic [4:0]  cart_ca,
    output logic        cart_ce_n,
    input  logic [7:0]  cart_d,
    output logic        cart_clk4,
    output logic        cart_cclr,
    input  logic        cart_sin,
    output logic [3:0]  video_r,
    output logic [3:0]  video_g,
    output logic [3:0]  video_b,
    output logic        video_hsync,
    output logic        video_vsync,
    output logic        video_de,
    output logic signed [15:0] audio_l,
    output logic signed [15:0] audio_r
);
    assign cart_a=14'd0; assign cart_ca=5'd0; assign cart_ce_n=1'b1;
    assign cart_clk4=clk16; assign cart_cclr=reset_n;
    assign video_r=0; assign video_g=0; assign video_b=0;
    assign video_hsync=0; assign video_vsync=0; assign video_de=0;
    assign audio_l=0; assign audio_r=0;
    wire _unused = &{1'b0,cart_d,cart_sin};
endmodule
