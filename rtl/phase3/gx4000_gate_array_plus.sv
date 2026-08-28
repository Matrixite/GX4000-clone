module gx4000_gate_array_plus (
    input  logic        clk16,
    input  logic        rst_n,
    input  logic        io_we,
    input  logic [7:0]  io_data,
    input  logic        asic_unlocked,
    input  logic        hsync,
    input  logic        vsync,
    input  logic        int_ack,
    input  logic        suppress_classic_raster,
    input  logic        asic_raster_event,

    output logic [1:0]  mode,
    output logic        low_rom_enable,
    output logic        high_rom_enable,
    output logic [7:0]  rmr2,
    output logic        classic_int_n,

    output logic        palette_we,
    output logic [4:0]  palette_index,
    output logic [11:0] palette_rgb,
    output logic        raster_reset
);
    logic [4:0] selected_pen;
    logic [1:0] mode_pending;
    logic hsync_d, vsync_d;
    logic [5:0] int_count;
    logic [1:0] vsync_hsync_delay;

    function automatic [11:0] hw_rgb(input logic [4:0] c);
        begin
            case(c)
                0,1:  hw_rgb=12'h666; 2,17: hw_rgb=12'h0F6;
                3,9:  hw_rgb=12'hFF6; 4,16: hw_rgb=12'h006;
                5,8:  hw_rgb=12'hF06; 6: hw_rgb=12'h066;
                7: hw_rgb=12'hF66; 10: hw_rgb=12'hFF0;
                11: hw_rgb=12'hFFF; 12: hw_rgb=12'hF00;
                13: hw_rgb=12'hF0F; 14: hw_rgb=12'hF60;
                15: hw_rgb=12'hF6F; 18: hw_rgb=12'h0F0;
                19: hw_rgb=12'h0FF; 20: hw_rgb=12'h000;
                21: hw_rgb=12'h00F; 22: hw_rgb=12'h060;
                23: hw_rgb=12'h06F; 24: hw_rgb=12'h606;
                25: hw_rgb=12'h6F6; 26: hw_rgb=12'h6F0;
                27: hw_rgb=12'h6FF; 28: hw_rgb=12'h600;
                29: hw_rgb=12'h60F; 30: hw_rgb=12'h660;
                31: hw_rgb=12'h66F; default: hw_rgb=12'h000;
            endcase
        end
    endfunction

    always_ff @(posedge clk16 or negedge rst_n) begin
        if (!rst_n) begin
            selected_pen <= 5'd0;
            mode <= 2'b00;
            mode_pending <= 2'b00;
            low_rom_enable <= 1'b1;
            high_rom_enable <= 1'b1;
            rmr2 <= 8'h00;
            classic_int_n <= 1'b1;
            int_count <= 6'd0;
            hsync_d <= 1'b0;
            vsync_d <= 1'b0;
            vsync_hsync_delay <= 2'd0;
            palette_we <= 1'b0;
            raster_reset <= 1'b0;
            palette_index <= 5'd0;
            palette_rgb <= 12'h000;
        end else begin
            palette_we <= 1'b0;
            raster_reset <= 1'b0;
            hsync_d <= hsync;
            vsync_d <= vsync;

            if (!hsync_d && hsync)
                mode <= mode_pending;

            // Classic CPC raster mechanism. It is still maintained internally
            // while PRI is active so returning PRI to zero has sensible phase.
            if (hsync_d && !hsync) begin
                if (int_count == 6'd51) begin
                    int_count <= 6'd0;
                    if (!suppress_classic_raster)
                        classic_int_n <= 1'b0;
                end else begin
                    int_count <= int_count + 6'd1;
                end

                if (vsync_hsync_delay != 0) begin
                    if (vsync_hsync_delay == 2'd2) begin
                        if ((int_count < 6'd32) && !suppress_classic_raster)
                            classic_int_n <= 1'b0;
                        int_count <= 6'd0;
                        vsync_hsync_delay <= 2'd0;
                    end else begin
                        vsync_hsync_delay <= vsync_hsync_delay + 2'd1;
                    end
                end
            end
            if (!vsync_d && vsync)
                vsync_hsync_delay <= 2'd1;

            if (asic_raster_event)
                int_count[5] <= 1'b0;

            if (int_ack) begin
                classic_int_n <= 1'b1;
                int_count[5] <= 1'b0;
            end

            if (io_we) begin
                case (io_data[7:6])
                    2'b00: begin
                        selected_pen <= io_data[4] ? 5'd16 : {1'b0,io_data[3:0]};
                    end
                    2'b01: begin
                        if (selected_pen <= 5'd16) begin
                            palette_we <= 1'b1;
                            palette_index <= selected_pen;
                            palette_rgb <= hw_rgb(io_data[4:0]);
                        end
                    end
                    2'b10: begin
                        if (asic_unlocked && io_data[5]) begin
                            // RMR2 exists only while the enhanced-feature lock is open.
                            rmr2 <= io_data;
                        end else begin
                            // MRER: mode, lower/upper ROM enables and raster counter reset.
                            mode_pending <= io_data[1:0];
                            low_rom_enable <= ~io_data[2];
                            high_rom_enable <= ~io_data[3];
                            if (io_data[4]) begin
                                classic_int_n <= 1'b1;
                                int_count <= 6'd0;
                                raster_reset <= 1'b1;
                            end
                        end
                    end
                    default: begin
                        // 11xxxxxx is the classic RAM mapping register; Phase 3 is
                        // still a 64 KiB GX4000 configuration so no extra bank action.
                    end
                endcase
            end
        end
    end
endmodule
