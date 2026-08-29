module phase5_debug_overlay (
    input  logic        enable,
    input  logic [9:0]  x,
    input  logic [9:0]  y,
    input  logic [3:0]  in_r,
    input  logic [3:0]  in_g,
    input  logic [3:0]  in_b,
    input  logic [7:0]  status_flags,
    input  logic [9:0]  frame_lines,
    input  logic [9:0]  min_frame_lines,
    input  logic [9:0]  max_frame_lines,
    input  logic [10:0] line_clocks,
    input  logic [10:0] min_line_clocks,
    input  logic [10:0] max_line_clocks,
    input  logic [7:0]  lock_errors,
    output logic [3:0]  out_r,
    output logic [3:0]  out_g,
    output logic [3:0]  out_b
);
    logic [5:0] cell_x;
    logic [2:0] row;
    logic bit_value;
    logic bad_value;
    logic in_panel;

    always_comb begin
        out_r = in_r;
        out_g = in_g;
        out_b = in_b;
        cell_x = x[9:3];
        row = y[5:3];
        bit_value = 1'b0;
        bad_value = 1'b0;
        in_panel = enable && (x < 10'd160) && (y < 10'd64);

        if (in_panel) begin
            out_r = {1'b0,in_r[3:1]};
            out_g = {1'b0,in_g[3:1]};
            out_b = {1'b0,in_b[3:1]};

            case (row)
                3'd0: if (cell_x < 6'd8)  begin bit_value = status_flags[7-cell_x]; bad_value = (cell_x == 6'd2) && bit_value; end
                3'd1: if (cell_x < 6'd10) bit_value = frame_lines[9-cell_x];
                3'd2: if (cell_x < 6'd10) bit_value = min_frame_lines[9-cell_x];
                3'd3: if (cell_x < 6'd10) bit_value = max_frame_lines[9-cell_x];
                3'd4: if (cell_x < 6'd11) bit_value = line_clocks[10-cell_x];
                3'd5: if (cell_x < 6'd11) bit_value = min_line_clocks[10-cell_x];
                3'd6: if (cell_x < 6'd11) bit_value = max_line_clocks[10-cell_x];
                3'd7: if (cell_x < 6'd8)  begin bit_value = lock_errors[7-cell_x]; bad_value = bit_value; end
                default: bit_value = 1'b0;
            endcase

            if ((x[2:0] != 3'd7) && (y[2:0] != 3'd7)) begin
                if (bit_value) begin
                    if (bad_value) begin
                        out_r = 4'hF; out_g = 4'h2; out_b = 4'h2;
                    end else begin
                        out_r = 4'h2; out_g = 4'hF; out_b = 4'h4;
                    end
                end else begin
                    out_r = 4'h2; out_g = 4'h2; out_b = 4'h2;
                end
            end
        end
    end
endmodule
