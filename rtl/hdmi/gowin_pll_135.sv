module gowin_pll_135 (
    input  wire clkin,
    output wire clkout,
    output wire lock
);
    wire clkoutp_o;
    wire clkoutd_o;
    wire clkoutd3_o;
    wire gnd = 1'b0;

    rPLL u_rpll (
        .CLKOUT(clkout), .LOCK(lock), .CLKOUTP(clkoutp_o),
        .CLKOUTD(clkoutd_o), .CLKOUTD3(clkoutd3_o),
        .RESET(gnd), .RESET_P(gnd), .CLKIN(clkin), .CLKFB(gnd),
        .FBDSEL(6'b0), .IDSEL(6'b0), .ODSEL(6'b0),
        .PSDA(4'b0), .DUTYDA(4'b0), .FDLY(4'b0)
    );

    defparam u_rpll.FCLKIN = "27";
    defparam u_rpll.DYN_IDIV_SEL = "false";
    defparam u_rpll.IDIV_SEL = 0;
    defparam u_rpll.DYN_FBDIV_SEL = "false";
    defparam u_rpll.FBDIV_SEL = 4;
    defparam u_rpll.DYN_ODIV_SEL = "false";
    defparam u_rpll.ODIV_SEL = 4;
    defparam u_rpll.PSDA_SEL = "0000";
    defparam u_rpll.DYN_DA_EN = "true";
    defparam u_rpll.DUTYDA_SEL = "1000";
    defparam u_rpll.CLKOUT_FT_DIR = 1'b1;
    defparam u_rpll.CLKOUTP_FT_DIR = 1'b1;
    defparam u_rpll.CLKOUT_DLY_STEP = 0;
    defparam u_rpll.CLKOUTP_DLY_STEP = 0;
    defparam u_rpll.CLKFB_SEL = "internal";
    defparam u_rpll.CLKOUT_BYPASS = "false";
    defparam u_rpll.CLKOUTP_BYPASS = "false";
    defparam u_rpll.CLKOUTD_BYPASS = "false";
    defparam u_rpll.DYN_SDIV_SEL = 2;
    defparam u_rpll.CLKOUTD_SRC = "CLKOUT";
    defparam u_rpll.CLKOUTD3_SRC = "CLKOUT";
    defparam u_rpll.DEVICE = "GW2AR-18C";
endmodule
