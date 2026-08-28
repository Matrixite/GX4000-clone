module cpc_gate_array(
    input  logic        clk16,
    input  logic        rst_n,
    input  logic        io_we,
    input  logic [7:0]  io_data,
    input  logic        hsync,
    input  logic        vsync,
    input  logic        int_ack,
    output logic [1:0]  mode,
    output logic        low_rom_enable,
    output logic        high_rom_enable,
    output logic [7:0]  rmr2,
    output logic        int_n,
    input  logic [3:0]  pixel_pen,
    input  logic        border,
    output logic [3:0]  video_r,
    output logic [3:0]  video_g,
    output logic [3:0]  video_b
);
    logic [4:0] ink[0:16];
    logic [4:0] selected_pen;
    logic [1:0] mode_pending;
    logic hsync_d, vsync_d;
    logic [5:0] int_count;
    logic [1:0] vsync_hsync_delay;
    integer i;

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

    logic [4:0] colour_index;
    logic [11:0] rgb;
    always_comb begin
        colour_index = border ? ink[16] : ink[pixel_pen];
        rgb = hw_rgb(colour_index);
        video_r = rgb[11:8]; video_g = rgb[7:4]; video_b = rgb[3:0];
    end

    always_ff @(posedge clk16 or negedge rst_n) begin
        if (!rst_n) begin
            selected_pen <= 5'd0;
            mode <= 2'b00; mode_pending <= 2'b00;
            low_rom_enable <= 1'b1; high_rom_enable <= 1'b1;
            rmr2 <= 8'h00;
            int_n <= 1'b1; int_count <= 6'd0;
            hsync_d <= 1'b0; vsync_d <= 1'b0; vsync_hsync_delay <= 2'd0;
            for(i=0;i<17;i=i+1) ink[i] <= 5'd20;
        end else begin
            hsync_d <= hsync; vsync_d <= vsync;

            // Mode transitions are synchronised to the next HSYNC.
            if (!hsync_d && hsync) mode <= mode_pending;

            // CPC interrupt counter: falling edge of CRTC HSYNC, terminal count 52.
            if (hsync_d && !hsync) begin
                if (int_count == 6'd51) begin
                    int_count <= 6'd0;
                    int_n <= 1'b0;
                end else begin
                    int_count <= int_count + 6'd1;
                end

                if (vsync_hsync_delay != 0) begin
                    if (vsync_hsync_delay == 2'd2) begin
                        // Two HSYNCs after VSYNC: re-synchronise periodic interrupts.
                        if (int_count < 6'd32) int_n <= 1'b0;
                        int_count <= 6'd0;
                        vsync_hsync_delay <= 2'd0;
                    end else begin
                        vsync_hsync_delay <= vsync_hsync_delay + 2'd1;
                    end
                end
            end
            if (!vsync_d && vsync) vsync_hsync_delay <= 2'd1;

            if (int_ack) begin
                int_n <= 1'b1;
                int_count[5] <= 1'b0;
            end

            if (io_we) begin
                case (io_data[7:6])
                    2'b00: selected_pen <= io_data[4] ? 5'd16 : {1'b0,io_data[3:0]};
                    2'b01: if (selected_pen <= 16) ink[selected_pen] <= io_data[4:0];
                    2'b10: begin
                        mode_pending <= io_data[1:0];
                        low_rom_enable <= ~io_data[2];
                        high_rom_enable <= ~io_data[3];
                        if (io_data[4]) begin
                            int_n <= 1'b1;
                            int_count <= 6'd0;
                        end
                    end
                    2'b11: rmr2 <= io_data;
                endcase
            end
        end
    end
endmodule
