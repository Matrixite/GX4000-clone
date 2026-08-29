module phase5_timing_trace (
    input  logic        clk27,
    input  logic        reset,
    input  logic [9:0]  frame_lines,
    input  logic [10:0] line_clocks,
    output logic [9:0]  min_frame_lines,
    output logic [9:0]  max_frame_lines,
    output logic [10:0] min_line_clocks,
    output logic [10:0] max_line_clocks
);
    logic [9:0] frame_last;
    logic [10:0] line_last;
    logic frame_seen, line_seen;

    always_ff @(posedge clk27 or posedge reset) begin
        if (reset) begin
            frame_last <= 10'd0;
            line_last <= 11'd0;
            frame_seen <= 1'b0;
            line_seen <= 1'b0;
            min_frame_lines <= 10'h3FF;
            max_frame_lines <= 10'd0;
            min_line_clocks <= 11'h7FF;
            max_line_clocks <= 11'd0;
        end else begin
            if (frame_lines != frame_last) begin
                frame_last <= frame_lines;
                if (frame_lines >= 10'd240 && frame_lines <= 10'd400) begin
                    if (!frame_seen) begin
                        min_frame_lines <= frame_lines;
                        max_frame_lines <= frame_lines;
                        frame_seen <= 1'b1;
                    end else begin
                        if (frame_lines < min_frame_lines) min_frame_lines <= frame_lines;
                        if (frame_lines > max_frame_lines) max_frame_lines <= frame_lines;
                    end
                end
            end

            if (line_clocks != line_last) begin
                line_last <= line_clocks;
                if (line_clocks >= 11'd512 && line_clocks <= 11'd1792) begin
                    if (!line_seen) begin
                        min_line_clocks <= line_clocks;
                        max_line_clocks <= line_clocks;
                        line_seen <= 1'b1;
                    end else begin
                        if (line_clocks < min_line_clocks) min_line_clocks <= line_clocks;
                        if (line_clocks > max_line_clocks) max_line_clocks <= line_clocks;
                    end
                end
            end
        end
    end
endmodule
