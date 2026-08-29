module cpc_hdmi_adaptive_scanconverter #(
    parameter integer FIFO_LINES = 32,
    parameter integer LINE_PIXELS = 720,
    parameter integer CROP_X = 248,
    parameter integer PRE_ACTIVE_LINES = 45,
    parameter integer DEFAULT_FRAME_LINES = 312
) (
    input  logic        src_clk16,
    input  logic        src_reset_n,
    input  logic [3:0]  src_r,
    input  logic [3:0]  src_g,
    input  logic [3:0]  src_b,
    input  logic        src_hsync,
    input  logic        src_vsync,
    input  logic        src_de,

    input  logic        dst_clk27,
    input  logic        dst_reset,
    input  logic [9:0]  dst_x,
    input  logic [9:0]  dst_y,
    output logic [3:0]  dst_r,
    output logic [3:0]  dst_g,
    output logic [3:0]  dst_b,
    output logic        frame_locked,
    output logic [9:0]  measured_frame_lines,
    output logic [10:0] measured_line_clocks,
    output logic [7:0]  lock_error_count
);
    localparam integer MEM_DEPTH = FIFO_LINES * LINE_PIXELS;
    localparam integer SLOT_W = $clog2(FIFO_LINES);

    (* ram_style = "block" *) logic [11:0] line_mem [0:MEM_DEPTH-1];

    logic [SLOT_W-1:0] wr_slot;
    logic [14:0]       wr_base;
    logic [10:0]       src_x;
    logic [10:0]       line_clock_count;
    logic              src_hsync_d, src_vsync_d, src_de_d;
    logic [9:0]        current_line_id;
    logic [9:0]        frame_line_count;
    logic [9:0]        frame_lines_src;
    logic [10:0]       line_clocks_src;
    logic              frame_valid;
    logic              first_active_pending;
    logic              src_epoch;

    logic [9:0] slot_line_id [0:FIFO_LINES-1];
    logic       slot_epoch   [0:FIFO_LINES-1];
    logic       slot_valid   [0:FIFO_LINES-1];

    wire hsync_rise = src_hsync && !src_hsync_d;
    wire vsync_rise = src_vsync && !src_vsync_d;
    wire de_rise    = src_de    && !src_de_d;

    integer si;
    always_ff @(posedge src_clk16 or negedge src_reset_n) begin
        if (!src_reset_n) begin
            wr_slot <= '0;
            wr_base <= 15'd0;
            src_x <= 11'd0;
            line_clock_count <= 11'd0;
            src_hsync_d <= 1'b0;
            src_vsync_d <= 1'b0;
            src_de_d <= 1'b0;
            current_line_id <= 10'd0;
            frame_line_count <= 10'd0;
            frame_lines_src <= DEFAULT_FRAME_LINES;
            line_clocks_src <= 11'd1024;
            frame_valid <= 1'b0;
            first_active_pending <= 1'b0;
            src_epoch <= 1'b0;
            for (si = 0; si < FIFO_LINES; si = si + 1) begin
                slot_line_id[si] <= 10'd0;
                slot_epoch[si] <= 1'b0;
                slot_valid[si] <= 1'b0;
            end
        end else begin
            src_hsync_d <= src_hsync;
            src_vsync_d <= src_vsync;
            src_de_d <= src_de;
            line_clock_count <= line_clock_count + 11'd1;

            if (vsync_rise)
                first_active_pending <= 1'b1;

            if (de_rise && first_active_pending) begin
                if (frame_valid && frame_line_count >= 10'd240 && frame_line_count <= 10'd400)
                    frame_lines_src <= frame_line_count;
                current_line_id <= 10'd0;
                frame_line_count <= 10'd0;
                first_active_pending <= 1'b0;
                frame_valid <= 1'b1;
                src_epoch <= ~src_epoch;
            end

            if (hsync_rise) begin
                slot_line_id[wr_slot] <= current_line_id;
                slot_epoch[wr_slot] <= src_epoch;
                slot_valid[wr_slot] <= frame_valid;

                if (wr_slot == FIFO_LINES-1) begin
                    wr_slot <= '0;
                    wr_base <= 15'd0;
                end else begin
                    wr_slot <= wr_slot + 1'b1;
                    wr_base <= wr_base + LINE_PIXELS;
                end

                if (line_clock_count >= 11'd512 && line_clock_count <= 11'd1792)
                    line_clocks_src <= line_clock_count;
                line_clock_count <= 11'd0;
                src_x <= 11'd1;

                if (frame_valid) begin
                    current_line_id <= current_line_id + 10'd1;
                    frame_line_count <= frame_line_count + 10'd1;
                end
            end else begin
                if ((src_x >= CROP_X) && (src_x < CROP_X + LINE_PIXELS))
                    line_mem[wr_base + (src_x - CROP_X)] <= {src_r, src_g, src_b};
                src_x <= src_x + 11'd1;
            end
        end
    end

    logic [9:0] id_meta [0:FIFO_LINES-1];
    logic [9:0] id_sync [0:FIFO_LINES-1];
    logic       epoch_meta [0:FIFO_LINES-1];
    logic       epoch_sync_slot [0:FIFO_LINES-1];
    logic       valid_meta [0:FIFO_LINES-1];
    logic       valid_sync [0:FIFO_LINES-1];
    logic       epoch_meta_global, epoch_sync_global;
    logic [9:0] frame_lines_meta, frame_lines_sync;
    logic [10:0] line_clocks_meta, line_clocks_sync;

    integer di;
    always_ff @(posedge dst_clk27 or posedge dst_reset) begin
        if (dst_reset) begin
            epoch_meta_global <= 1'b0;
            epoch_sync_global <= 1'b0;
            frame_lines_meta <= DEFAULT_FRAME_LINES;
            frame_lines_sync <= DEFAULT_FRAME_LINES;
            line_clocks_meta <= 11'd1024;
            line_clocks_sync <= 11'd1024;
            for (di = 0; di < FIFO_LINES; di = di + 1) begin
                id_meta[di] <= 10'd0;
                id_sync[di] <= 10'd0;
                epoch_meta[di] <= 1'b0;
                epoch_sync_slot[di] <= 1'b0;
                valid_meta[di] <= 1'b0;
                valid_sync[di] <= 1'b0;
            end
        end else begin
            epoch_meta_global <= src_epoch;
            epoch_sync_global <= epoch_meta_global;
            frame_lines_meta <= frame_lines_src;
            frame_lines_sync <= frame_lines_meta;
            line_clocks_meta <= line_clocks_src;
            line_clocks_sync <= line_clocks_meta;
            for (di = 0; di < FIFO_LINES; di = di + 1) begin
                id_meta[di] <= slot_line_id[di];
                id_sync[di] <= id_meta[di];
                epoch_meta[di] <= slot_epoch[di];
                epoch_sync_slot[di] <= epoch_meta[di];
                valid_meta[di] <= slot_valid[di];
                valid_sync[di] <= valid_meta[di];
            end
        end
    end

    assign measured_frame_lines = frame_lines_sync;
    assign measured_line_clocks = line_clocks_sync;

    logic [9:0] target_line_id;
    always_comb begin
        if (frame_lines_sync > PRE_ACTIVE_LINES)
            target_line_id = frame_lines_sync - PRE_ACTIVE_LINES;
        else
            target_line_id = 10'd0;
    end

    logic target_found;
    logic [SLOT_W-1:0] target_slot;
    integer fi;
    always_comb begin
        target_found = 1'b0;
        target_slot = '0;
        for (fi = 0; fi < FIFO_LINES; fi = fi + 1) begin
            if (valid_sync[fi] &&
                (epoch_sync_slot[fi] == epoch_sync_global) &&
                (id_sync[fi] == target_line_id)) begin
                target_found = 1'b1;
                target_slot = fi;
            end
        end
    end

    function automatic [14:0] slot_base(input logic [SLOT_W-1:0] slot);
        logic [14:0] v;
        begin
            v = {{(15-SLOT_W){1'b0}}, slot};
            slot_base = (v << 9) + (v << 7) + (v << 6) + (v << 4);
        end
    endfunction

    logic [SLOT_W-1:0] rd_slot;
    logic [14:0] rd_base;
    logic locked;
    logic [11:0] rgb_q;
    logic [9:0] expected_line;
    logic expected_epoch;
    logic [2:0] consecutive_misses;

    logic [SLOT_W-1:0] next_slot;
    logic [9:0] next_expected_line;
    logic next_expected_epoch;
    always_comb begin
        if (rd_slot == FIFO_LINES-1)
            next_slot = '0;
        else
            next_slot = rd_slot + 1'b1;

        if (expected_line + 10'd1 >= frame_lines_sync) begin
            next_expected_line = 10'd0;
            next_expected_epoch = ~expected_epoch;
        end else begin
            next_expected_line = expected_line + 10'd1;
            next_expected_epoch = expected_epoch;
        end
    end

    always_ff @(posedge dst_clk27 or posedge dst_reset) begin
        if (dst_reset) begin
            rd_slot <= '0;
            rd_base <= 15'd0;
            locked <= 1'b0;
            rgb_q <= 12'h000;
            expected_line <= 10'd0;
            expected_epoch <= 1'b0;
            consecutive_misses <= 3'd0;
            lock_error_count <= 8'd0;
        end else begin
            if (dst_x == 10'd0) begin
                if (dst_y == 10'd0) begin
                    if (target_found) begin
                        rd_slot <= target_slot;
                        rd_base <= slot_base(target_slot);
                        expected_line <= target_line_id;
                        expected_epoch <= epoch_sync_global;
                        locked <= 1'b1;
                        consecutive_misses <= 3'd0;
                    end else begin
                        if (locked && lock_error_count != 8'hFF)
                            lock_error_count <= lock_error_count + 8'd1;
                        locked <= 1'b0;
                    end
                end else if ((dst_y < 10'd16) && !dst_y[0] && !locked && target_found) begin
                    rd_slot <= target_slot;
                    rd_base <= slot_base(target_slot);
                    expected_line <= target_line_id;
                    expected_epoch <= epoch_sync_global;
                    locked <= 1'b1;
                    consecutive_misses <= 3'd0;
                end else if ((dst_y < 10'd576) && !dst_y[0] && locked) begin
                    if (valid_sync[next_slot] &&
                        (id_sync[next_slot] == next_expected_line) &&
                        (epoch_sync_slot[next_slot] == next_expected_epoch)) begin
                        rd_slot <= next_slot;
                        rd_base <= slot_base(next_slot);
                        expected_line <= next_expected_line;
                        expected_epoch <= next_expected_epoch;
                        consecutive_misses <= 3'd0;
                    end else if (consecutive_misses == 3'd3) begin
                        locked <= 1'b0;
                        consecutive_misses <= 3'd0;
                        if (lock_error_count != 8'hFF)
                            lock_error_count <= lock_error_count + 8'd1;
                    end else begin
                        consecutive_misses <= consecutive_misses + 3'd1;
                    end
                end
            end

            if (locked && (dst_x < 10'd720) && (dst_y < 10'd576))
                rgb_q <= line_mem[rd_base + dst_x];
            else
                rgb_q <= 12'h000;
        end
    end

    assign dst_r = rgb_q[11:8];
    assign dst_g = rgb_q[7:4];
    assign dst_b = rgb_q[3:0];
    assign frame_locked = locked;
endmodule
