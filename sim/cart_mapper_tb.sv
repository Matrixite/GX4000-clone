`timescale 1ns/1ps

module cart_mapper_tb;
    logic [15:0] cpu_addr;
    logic [7:0] rmr2;
    logic [7:0] rom_select;
    logic low_rom_enable;
    logic high_rom_enable;
    logic cart_selected;
    logic [4:0] cart_page;
    logic [13:0] cart_offset;

    gx4000_cart_mapper dut (
        .cpu_addr(cpu_addr), .rmr2(rmr2), .rom_select(rom_select),
        .low_rom_enable(low_rom_enable), .high_rom_enable(high_rom_enable),
        .cart_selected(cart_selected), .cart_page(cart_page), .cart_offset(cart_offset)
    );

    task check(input [15:0] a,input [7:0] r2,input [7:0] rs,input low_en,input high_en,input expect_sel,input [4:0] expect_page);
        begin
            cpu_addr=a; rmr2=r2; rom_select=rs; low_rom_enable=low_en; high_rom_enable=high_en; #1;
            if (cart_selected !== expect_sel) $fatal(1,"select mismatch addr=%h",a);
            if (expect_sel && cart_page !== expect_page) $fatal(1,"page mismatch addr=%h got=%0d expected=%0d",a,cart_page,expect_page);
        end
    endtask

    initial begin
        check(16'h0123,8'b0000_0101,8'h00,1,1,1,5);
        check(16'h4567,8'b0000_1001,8'h00,1,1,1,1);
        check(16'hC123,8'h00,8'h00,1,1,1,3);
        check(16'hC123,8'h00,8'h07,1,1,1,3);
        check(16'hC123,8'h00,8'h25,1,1,1,1);
        check(16'hC123,8'h00,8'h9A,1,1,1,26);
        check(16'h8123,8'h00,8'h80,1,1,0,0);
        $display("cart_mapper_tb PASS");
        $finish;
    end
endmodule
