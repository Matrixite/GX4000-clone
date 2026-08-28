module cpc_cart_cpu_bridge #(
    parameter integer WAIT_CYCLES = 6
)(
    input  logic        clk16,
    input  logic        rst_n,
    input  logic        request,
    input  logic [4:0]  page,
    input  logic [13:0] offset,
    input  logic [7:0]  cart_d,
    output logic [4:0]  cart_ca,
    output logic [13:0] cart_a,
    output logic        cart_ce_n,
    output logic        wait_n,
    output logic [7:0]  data
);
    localparam CW = (WAIT_CYCLES < 2) ? 1 : $clog2(WAIT_CYCLES+1);
    typedef enum logic [1:0] {IDLE, ACCESS, HOLD} state_t;
    state_t state;
    logic [CW-1:0] count;

    assign wait_n = !(request && state != HOLD);

    always_ff @(posedge clk16 or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE; count <= '0; data <= 8'hFF;
            cart_ca <= 5'd0; cart_a <= 14'd0; cart_ce_n <= 1'b1;
        end else begin
            case(state)
                IDLE: begin
                    cart_ce_n <= 1'b1;
                    if (request) begin
                        cart_ca <= page; cart_a <= offset; cart_ce_n <= 1'b0;
                        count <= '0; state <= ACCESS;
                    end
                end
                ACCESS: begin
                    cart_ce_n <= 1'b0;
                    if (count == WAIT_CYCLES-1) begin
                        data <= cart_d;
                        cart_ce_n <= 1'b1;
                        state <= HOLD;
                    end else count <= count + 1'b1;
                end
                HOLD: begin
                    cart_ce_n <= 1'b1;
                    if (!request) state <= IDLE;
                end
            endcase
        end
    end
endmodule
