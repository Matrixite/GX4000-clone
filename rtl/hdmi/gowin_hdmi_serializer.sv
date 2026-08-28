module serializer
#(
    parameter integer NUM_CHANNELS = 3,
    parameter integer VIDEO_RATE = 27000000
)
(
    input  logic clk_pixel,
    input  logic clk_pixel_x5,
    input  logic reset,
    input  logic [9:0] tmds_internal [NUM_CHANNELS-1:0],
    output wire [2:0] tmds,
    output wire tmds_clock
);
    genvar i;
    generate
        for (i = 0; i < 3; i = i + 1) begin : g_oser
            OSER10 u_oser (
                .Q(tmds[i]),
                .D0(tmds_internal[i][0]), .D1(tmds_internal[i][1]),
                .D2(tmds_internal[i][2]), .D3(tmds_internal[i][3]),
                .D4(tmds_internal[i][4]), .D5(tmds_internal[i][5]),
                .D6(tmds_internal[i][6]), .D7(tmds_internal[i][7]),
                .D8(tmds_internal[i][8]), .D9(tmds_internal[i][9]),
                .PCLK(clk_pixel), .FCLK(clk_pixel_x5), .RESET(reset)
            );
            defparam u_oser.GSREN = "false";
            defparam u_oser.LSREN = "true";
        end
    endgenerate

    OSER10 u_clock_oser (
        .Q(tmds_clock),
        .D0(1'b1), .D1(1'b1), .D2(1'b1), .D3(1'b1), .D4(1'b1),
        .D5(1'b0), .D6(1'b0), .D7(1'b0), .D8(1'b0), .D9(1'b0),
        .PCLK(clk_pixel), .FCLK(clk_pixel_x5), .RESET(reset)
    );
    defparam u_clock_oser.GSREN = "false";
    defparam u_clock_oser.LSREN = "true";

    wire _unused_video_rate = (VIDEO_RATE == 27000000);
endmodule
