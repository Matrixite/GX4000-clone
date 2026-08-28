module gx4000_realcart_diag_top #(
    parameter integer CLOCK_HZ = 27_000_000
) (
    input  logic        clk,
    input  logic        reset_n,
    output logic [13:0] cart_a,
    output logic [4:0]  cart_ca,
    output logic        cart_ce_n,
    input  logic [7:0]  cart_d,
    output logic        cart_clk4,
    output logic        cart_cclr,
    input  logic        cart_sin,
    output logic        uart_tx_o,
    output logic        led_done
);
    logic read_start;
    logic [4:0] read_page;
    logic [13:0] read_offset;
    logic read_busy, read_done;
    logic [7:0] read_data;
    logic uart_valid, uart_ready;
    logic [7:0] uart_data;
    logic [31:0] acid_samples;

    cart_read_cycle #(.WAIT_CYCLES(12)) u_cart_read (
        .clk(clk), .rst_n(reset_n), .start(read_start), .page(read_page), .offset(read_offset),
        .cart_ca(cart_ca), .cart_a(cart_a), .cart_ce_n(cart_ce_n), .cart_d(cart_d),
        .busy(read_busy), .done(read_done), .data(read_data)
    );

    acid_link_monitor #(.INPUT_CLOCK_HZ(CLOCK_HZ)) u_acid (
        .clk(clk), .rst_n(reset_n), .cart_sin(cart_sin), .cart_clk4(cart_clk4),
        .cart_cclr(cart_cclr), .sampled_shift(acid_samples)
    );

    cart_diag_engine #(.CLOCK_HZ(CLOCK_HZ)) u_diag (
        .clk(clk), .rst_n(reset_n), .read_start(read_start), .read_page(read_page),
        .read_offset(read_offset), .read_busy(read_busy), .read_done(read_done),
        .read_data(read_data), .uart_valid(uart_valid), .uart_data(uart_data),
        .uart_ready(uart_ready), .complete(led_done)
    );

    uart_tx #(.CLOCK_HZ(CLOCK_HZ), .BAUD(115200)) u_uart (
        .clk(clk), .rst_n(reset_n), .valid(uart_valid), .data(uart_data),
        .ready(uart_ready), .tx(uart_tx_o)
    );
endmodule
