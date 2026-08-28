module acid_link_monitor #(
    parameter integer INPUT_CLOCK_HZ = 27_000_000
) (
    input  logic clk,
    input  logic rst_n,

    input  logic cart_sin,
    output logic cart_clk4,
    output logic cart_cclr,

    output logic [31:0] sampled_shift
);

    localparam integer DIV_HALF =
        (INPUT_CLOCK_HZ / 8_000_000 < 1) ? 1 : (INPUT_CLOCK_HZ / 8_000_000);

    logic [15:0] div_count;
    logic [7:0] clear_count;
    logic last_clk4;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_count      <= 16'd0;
            cart_clk4      <= 1'b0;
            cart_cclr      <= 1'b0;
            clear_count    <= 8'd0;
            sampled_shift  <= 32'd0;
            last_clk4      <= 1'b0;
        end else begin
            if (clear_count != 8'hFF)
                clear_count <= clear_count + 1'b1;

            if (clear_count < 8'd64)
                cart_cclr <= 1'b0;
            else
                cart_cclr <= 1'b1;

            if (div_count == DIV_HALF-1) begin
                div_count <= 16'd0;
                cart_clk4 <= ~cart_clk4;
            end else begin
                div_count <= div_count + 1'b1;
            end

            last_clk4 <= cart_clk4;

            if (last_clk4 && !cart_clk4)
                sampled_shift <= {sampled_shift[30:0], cart_sin};
        end
    end
endmodule
