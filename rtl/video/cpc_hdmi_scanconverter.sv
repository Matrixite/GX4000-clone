module cpc_hdmi_scanconverter #(
    parameter integer FIFO_LINES = 32,
    parameter integer LINE_PIXELS = 720,
    parameter integer CROP_X = 248,
    parameter integer TARGET_FIRST_LINE = 267
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
    output logic        frame_locked
);
    localparam integer MEM_DEPTH = FIFO_LINES * LINE_PIXELS;

    // 32 cropped source scanlines. 32 * 720 * 12 = 276,480 bits.
    // This is deliberately much smaller than a full-frame buffer and is intended
    // to infer Tang Nano 20K BSRAM as a dual-clock read/write store.
    (* ram_style = "block" *) logic [11:0] line_mem [0:MEM_DEPTH-1];

    logic [4:0]  wr_slot;
    logic [14:0] wr_base;
    logic [9:0]  src_x;
    logic        src_hsync_d, src_vsync_d, src_de_d;
    logic [8:0]  current_line_id;
    logic        frame_valid;
    logic        first_active_pending;
    logic        src_epoch;

    logic [8:0] slot_line_id [0:FIFO_LINES-1];
    logic       slot_epoch   [0:FIFO_LINES-1];
    logic       slot_valid   [0:FIFO_LINES-1];

    wire hsync_rise = src_hsync && !src_hsync_d;
    wire vsync_rise = src_vsync && !src_vsync_d;
    wire de_rise    = src_de    && !src_de_d;

    integer si;
    always_ff @(posedge src_clk16 or negedge src_reset_n) begin
        if (!src_reset_n) begin
            wr_slot <= 5'd0;
            wr_base <= 15'd0;
            src_x <= 10'd0;
            src_hsync_d <= 1'b0;
            src_vsync_d <= 1'b0;
            src_de_d <= 1'b0;
            current_line_id <= 9'd0;
            frame_valid <= 1'b0;
            first_active_pending <= 1'b0;
            src_epoch <= 1'b0;
            for (si = 0; si < FIFO_LINES; si = si + 1) begin
                slot_line_id[si] <= 9'd0;
                slot_epoch[si] <= 1'b0;
                slot_valid[si] <= 1'b0;
            end
        end else begin
            src_hsync_d <= src_hsync;
            src_vsync_d <= src_vsync;
            src_de_d <= src_de;

            // CRTC VSYNC occurs in the lower border. The first display-enable
            // line after it is the start of the next visible CPC frame.
            if (vsync_rise)
                first_active_pending <= 1'b1;

            if (de_rise && first_active_pending) begin
                current_line_id <= 9'd0;
                first_active_pending <= 1'b0;
                frame_valid <= 1'b1;
                src_epoch <= ~src_epoch;
            end

            // The source line store is anchored to the rising edge of HSYNC.
            // With the Phase-2 default CRTC timing, source pixels 248..967 form
            // a 720-pixel window containing the 640-pixel display plus border.
            if (hsync_rise) begin
                slot_line_id[wr_slot] <= current_line_id;
                slot_epoch[wr_slot] <= src_epoch;
                slot_valid[wr_slot] <= frame_valid;

                if (wr_slot == FIFO_LINES-1) begin
                    wr_slot <= 5'd0;
                    wr_base <= 15'd0;
                end else begin
                    wr_slot <= wr_slot + 5'd1;
                    wr_base <= wr_base + LINE_PIXELS;
                end
                src_x <= 10'd1;

                if (frame_valid) begin
                    if (current_line_id == 9'd311)
                        current_line_id <= 9'd0;
                    else
                        current_line_id <= current_line_id + 9'd1;
                end
            end else begin
                if ((src_x >= CROP_X) && (src_x < CROP_X + LINE_PIXELS))
                    line_mem[wr_base + (src_x - CROP_X)] <= {src_r, src_g, src_b};
                src_x <= src_x + 10'd1;
            end
        end
    end

    // Synchronize line metadata into the 27 MHz HDMI pixel domain. Pixel RAM
    // itself is dual-clock; metadata changes only once per 64 us source line.
    logic [8:0] id_meta [0:FIFO_LINES-1];
    logic [8:0] id_sync [0:FIFO_LINES-1];
    logic       epoch_meta [0:FIFO_LINES-1];
    logic       epoch_sync_slot [0:FIFO_LINES-1];
    logic       valid_meta [0:FIFO_LINES-1];
    logic       valid_sync [0:FIFO_LINES-1];
    logic       epoch_meta_global, epoch_sync_global;

    integer di;
    always_ff @(posedge dst_clk27 or posedge dst_reset) begin
        if (dst_reset) begin
            epoch_meta_global <= 1'b0;
            epoch_sync_global <= 1'b0;
            for (di = 0; di < FIFO_LINES; di = di + 1) begin
                id_meta[di] <= 9'd0;
                id_sync[di] <= 9'd0;
                epoch_meta[di] <= 1'b0;
                epoch_sync_slot[di] <= 1'b0;
                valid_meta[di] <= 1'b0;
                valid_sync[di] <= 1'b0;
            end
        end else begin
            epoch_meta_global <= src_epoch;
            epoch_sync_global <= epoch_meta_global;
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

    logic       target_found;
    logic [4:0] target_slot;
    integer fi;
    always_comb begin
        target_found = 1'b0;
        target_slot = 5'd0;
        for (fi = 0; fi < FIFO_LINES; fi = fi + 1) begin
            if (valid_sync[fi] &&
                (epoch_sync_slot[fi] == epoch_sync_global) &&
                (id_sync[fi] == TARGET_FIRST_LINE)) begin
                target_found = 1'b1;
                target_slot = fi;
            end
        end
    end

    function automatic [14:0] slot_base(input logic [4:0] slot);
        logic [14:0] v;
        begin
            v = {10'd0, slot};
            // slot * 720 = slot * (512 + 128 + 64 + 16)
            slot_base = (v << 9) + (v << 7) + (v << 6) + (v << 4);
        end
    endfunction

    logic [4:0]  rd_slot;
    logic [14:0] rd_base;
    logic        locked;
    logic [11:0] rgb_q;

    // 720x576p50 has a 31.25 kHz line rate. The CPC source is 15.625 kHz,
    // so each stored source line is read exactly twice. During the 49 HDMI
    // blanking lines the writer can move ahead by about 24.5 CPC lines; the
    // 32-line FIFO absorbs that difference, then the next frame relocks to
    // source line 267. That window produces 45 border lines, 200 active lines
    // and 43 border lines, each doubled to fill the 576-line HDMI picture.
    always_ff @(posedge dst_clk27 or posedge dst_reset) begin
        if (dst_reset) begin
            rd_slot <= 5'd0;
            rd_base <= 15'd0;
            locked <= 1'b0;
            rgb_q <= 12'h000;
        end else begin
            if (dst_x == 10'd0) begin
                if (dst_y == 10'd0) begin
                    if (target_found) begin
                        rd_slot <= target_slot;
                        rd_base <= slot_base(target_slot);
                        locked <= 1'b1;
                    end else begin
                        locked <= 1'b0;
                    end
                end else if ((dst_y < 10'd16) && !dst_y[0] && !locked && target_found) begin
                    // Small acquisition window for the first frame after reset.
                    rd_slot <= target_slot;
                    rd_base <= slot_base(target_slot);
                    locked <= 1'b1;
                end else if ((dst_y < 10'd576) && !dst_y[0] && locked) begin
                    if (rd_slot == FIFO_LINES-1) begin
                        rd_slot <= 5'd0;
                        rd_base <= 15'd0;
                    end else begin
                        rd_slot <= rd_slot + 5'd1;
                        rd_base <= rd_base + LINE_PIXELS;
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
