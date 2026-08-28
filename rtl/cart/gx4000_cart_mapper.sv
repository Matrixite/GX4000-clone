module gx4000_cart_mapper (
    input  logic [15:0] cpu_addr,
    input  logic [7:0]  rmr2,
    input  logic [7:0]  rom_select,
    input  logic        low_rom_enable,
    input  logic        high_rom_enable,

    output logic        cart_selected,
    output logic [4:0]  cart_page,
    output logic [13:0] cart_offset
);

    logic low_window_hit;
    logic high_window_hit;
    logic [1:0] low_window;

    always_comb begin
        // Arnold V RMR2 D4:D3:
        // 00 -> low ROM at 0000-3FFF
        // 01 -> low ROM at 4000-7FFF
        // 10 -> low ROM at 8000-BFFF
        // 11 -> low ROM at 0000-3FFF, ASIC register page enabled
        low_window = rmr2[4:3];

        low_window_hit = 1'b0;
        case (low_window)
            2'b00: low_window_hit = (cpu_addr[15:14] == 2'b00);
            2'b01: low_window_hit = (cpu_addr[15:14] == 2'b01);
            2'b10: low_window_hit = (cpu_addr[15:14] == 2'b10);
            2'b11: low_window_hit = (cpu_addr[15:14] == 2'b00);
            default: low_window_hit = 1'b0;
        endcase

        high_window_hit = (cpu_addr[15:14] == 2'b11);

        cart_selected = 1'b0;
        cart_page     = 5'd0;
        cart_offset   = cpu_addr[13:0];

        if (low_rom_enable && low_window_hit) begin
            cart_selected = 1'b1;
            cart_page = {2'b00, rmr2[2:0]};
        end
        else if (high_rom_enable && high_window_hit) begin
            cart_selected = 1'b1;

            // Arnold V logical-to-physical high-bank translation.
            if (rom_select[7]) begin
                cart_page = rom_select[4:0];
            end
            else if ((rom_select[6:0] == 7'd0) ||
                     (rom_select[6:0] == 7'd7)) begin
                cart_page = 5'd3;
            end
            else begin
                cart_page = 5'd1;
            end
        end
    end
endmodule
