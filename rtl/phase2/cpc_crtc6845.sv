module cpc_crtc6845(
    input  logic        clk16,
    input  logic        rst_n,
    input  logic        char_ce,
    input  logic        select_we,
    input  logic        data_we,
    input  logic [7:0]  cpu_wdata,
    input  logic        data_re,
    output logic [7:0]  cpu_rdata,
    output logic [13:0] ma,
    output logic [4:0]  ra,
    output logic        hsync,
    output logic        vsync,
    output logic        display_en
);
    logic [7:0] r[0:17];
    logic [4:0] reg_sel;
    logic [7:0] hchar;
    logic [6:0] vrow;
    logic [4:0] raster;
    logic [4:0] vadj_count;
    logic       in_vadjust;
    logic [13:0] row_ma;
    logic [4:0] hsync_left;
    logic [4:0] vsync_left;
    integer i;

    function automatic [4:0] width16(input logic [3:0] w);
        width16 = (w == 4'd0) ? 5'd16 : {1'b0,w};
    endfunction

    always_comb begin
        ma = row_ma + {6'd0,hchar};
        ra = raster;
        display_en = !in_vadjust && (hchar < r[1]) && (vrow < r[6]);
        cpu_rdata = 8'hFF;
        if (data_re && reg_sel < 18) cpu_rdata = r[reg_sel];
    end

    always_ff @(posedge clk16 or negedge rst_n) begin
        if (!rst_n) begin
            reg_sel <= 5'd0;
            // Common 50 Hz CPC defaults. Software remains free to rewrite all registers.
            r[0] <= 8'd63; r[1] <= 8'd40; r[2] <= 8'd46; r[3] <= 8'h8E;
            r[4] <= 8'd38; r[5] <= 8'd0;  r[6] <= 8'd25; r[7] <= 8'd30;
            r[8] <= 8'd0;  r[9] <= 8'd7;  r[10] <= 8'd0; r[11] <= 8'd0;
            r[12] <= 8'h30; r[13] <= 8'h00; r[14] <= 8'd0; r[15] <= 8'd0;
            r[16] <= 8'd0; r[17] <= 8'd0;
            hchar <= 8'd0; vrow <= 7'd0; raster <= 5'd0;
            vadj_count <= 5'd0; in_vadjust <= 1'b0;
            row_ma <= 14'h3000;
            hsync_left <= 5'd0; vsync_left <= 5'd0;
            hsync <= 1'b0; vsync <= 1'b0;
        end else begin
            if (select_we) reg_sel <= cpu_wdata[4:0];
            if (data_we && reg_sel < 18) r[reg_sel] <= cpu_wdata;

            if (char_ce) begin
                // Horizontal sync is programmed in character clocks.
                if (hsync_left != 0) begin
                    hsync_left <= hsync_left - 5'd1;
                    if (hsync_left == 5'd1) hsync <= 1'b0;
                end
                if (hchar == r[2]) begin
                    hsync <= 1'b1;
                    hsync_left <= width16(r[3][3:0]);
                end

                if (hchar == r[0]) begin
                    hchar <= 8'd0;

                    // Vertical sync width is in scanlines on CPC CRTC types that expose it.
                    if (vsync_left != 0) begin
                        vsync_left <= vsync_left - 5'd1;
                        if (vsync_left == 5'd1) vsync <= 1'b0;
                    end
                    if (!in_vadjust && (vrow == r[7]) && (raster == 0)) begin
                        vsync <= 1'b1;
                        vsync_left <= width16(r[3][7:4]);
                    end

                    if (in_vadjust) begin
                        if (vadj_count + 5'd1 >= r[5][4:0]) begin
                            in_vadjust <= 1'b0;
                            vadj_count <= 5'd0;
                            vrow <= 7'd0;
                            raster <= 5'd0;
                            row_ma <= {r[12][5:0],r[13]};
                        end else begin
                            vadj_count <= vadj_count + 5'd1;
                        end
                    end else if (raster == r[9][4:0]) begin
                        raster <= 5'd0;
                        if (vrow == r[4][6:0]) begin
                            if (r[5][4:0] != 0) begin
                                in_vadjust <= 1'b1;
                                vadj_count <= 5'd0;
                            end else begin
                                vrow <= 7'd0;
                                row_ma <= {r[12][5:0],r[13]};
                            end
                        end else begin
                            vrow <= vrow + 7'd1;
                            // The linear address sequence repeats for each raster in a
                            // character row and advances by displayed characters per row.
                            row_ma <= row_ma + {6'd0,r[1]};
                        end
                    end else begin
                        raster <= raster + 5'd1;
                    end
                end else begin
                    hchar <= hchar + 8'd1;
                end
            end
        end
    end
endmodule
