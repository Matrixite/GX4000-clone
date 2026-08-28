module cpc_clock_tree(
    input  logic clk27,
    output logic clk32,
    output logic clk16,
    output logic pll_locked,
    output logic [3:0] pixel_phase,
    output logic cpu_ce,
    output logic crtc_ce,
    output logic cart_clk4
);
    gowin_pll_32m pll(.clkin(clk27), .clkout(clk32), .lock(pll_locked));

    always_ff @(posedge clk32 or negedge pll_locked) begin
        if (!pll_locked) clk16 <= 1'b0;
        else             clk16 <= ~clk16;
    end

    always_ff @(posedge clk16 or negedge pll_locked) begin
        if (!pll_locked) pixel_phase <= 4'd0;
        else             pixel_phase <= pixel_phase + 4'd1;
    end

    // The CPU advances on four fixed slots per 16-pixel CRTC character.
    // This is a deterministic 4 MHz enable derived from the 16 MHz master.
    assign cpu_ce  = (pixel_phase[1:0] == 2'b11);
    assign crtc_ce = (pixel_phase == 4'd15);
    assign cart_clk4 = pixel_phase[1];
endmodule
