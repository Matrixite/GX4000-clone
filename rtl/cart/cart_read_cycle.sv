module cart_read_cycle #(
    parameter integer WAIT_CYCLES = 12
) (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        start,
    input  logic [4:0]  page,
    input  logic [13:0] offset,

    output logic [4:0]  cart_ca,
    output logic [13:0] cart_a,
    output logic        cart_ce_n,
    input  logic [7:0]  cart_d,

    output logic        busy,
    output logic        done,
    output logic [7:0]  data
);

    localparam integer CW = (WAIT_CYCLES < 2) ? 1 : $clog2(WAIT_CYCLES + 1);

    logic [CW-1:0] counter;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cart_ca   <= 5'd0;
            cart_a    <= 14'd0;
            cart_ce_n <= 1'b1;
            busy      <= 1'b0;
            done      <= 1'b0;
            data      <= 8'h00;
            counter   <= '0;
        end else begin
            done <= 1'b0;

            if (!busy) begin
                cart_ce_n <= 1'b1;
                if (start) begin
                    cart_ca   <= page;
                    cart_a    <= offset;
                    cart_ce_n <= 1'b0;
                    busy      <= 1'b1;
                    counter   <= '0;
                end
            end else begin
                if (counter == WAIT_CYCLES-1) begin
                    data      <= cart_d;
                    cart_ce_n <= 1'b1;
                    busy      <= 1'b0;
                    done      <= 1'b1;
                    counter   <= '0;
                end else begin
                    counter <= counter + 1'b1;
                end
            end
        end
    end
endmodule
