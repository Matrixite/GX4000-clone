module uart_tx #(
    parameter integer CLOCK_HZ = 27_000_000,
    parameter integer BAUD     = 115200
) (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       valid,
    input  logic [7:0] data,
    output logic       ready,
    output logic       tx
);

    localparam integer DIVISOR = (CLOCK_HZ + BAUD/2) / BAUD;
    localparam integer CW = (DIVISOR < 2) ? 1 : $clog2(DIVISOR);

    logic [CW-1:0] baud_count;
    logic [3:0] bit_index;
    logic [9:0] shift_reg;
    logic sending;

    assign ready = !sending;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_count <= '0;
            bit_index  <= 4'd0;
            shift_reg  <= 10'h3FF;
            sending    <= 1'b0;
            tx         <= 1'b1;
        end else begin
            if (!sending) begin
                tx <= 1'b1;
                if (valid) begin
                    shift_reg <= {1'b1, data, 1'b0};
                    bit_index <= 4'd0;
                    baud_count <= '0;
                    sending <= 1'b1;
                    tx <= 1'b0;
                end
            end else begin
                if (baud_count == DIVISOR-1) begin
                    baud_count <= '0;
                    if (bit_index == 4'd9) begin
                        sending <= 1'b0;
                        tx <= 1'b1;
                    end else begin
                        bit_index <= bit_index + 1'b1;
                        shift_reg <= {1'b1, shift_reg[9:1]};
                        tx <= shift_reg[1];
                    end
                end else begin
                    baud_count <= baud_count + 1'b1;
                end
            end
        end
    end
endmodule
