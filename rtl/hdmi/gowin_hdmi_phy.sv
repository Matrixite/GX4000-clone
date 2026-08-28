module gowin_hdmi_phy (
    input  logic       tmds_clock,
    input  logic [2:0] tmds_data,
    output wire        O_tmds_clk_p,
    output wire        O_tmds_clk_n,
    output wire [2:0]  O_tmds_data_p,
    output wire [2:0]  O_tmds_data_n
);
    TLVDS_OBUF u_clk (
        .I  (tmds_clock),
        .O  (O_tmds_clk_p),
        .OB (O_tmds_clk_n)
    );

    genvar i;
    generate
        for (i = 0; i < 3; i = i + 1) begin : g_lane
            TLVDS_OBUF u_lane (
                .I  (tmds_data[i]),
                .O  (O_tmds_data_p[i]),
                .OB (O_tmds_data_n[i])
            );
        end
    endgenerate
endmodule
