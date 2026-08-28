module gx4000_plus_video (
    input logic clk16,input logic rst_n,input logic [3:0] pixel_phase,
    input logic [13:0] crtc_ma,input logic [4:0] crtc_ra,input logic crtc_de,
    input logic crtc_hsync,input logic crtc_vsync,input logic [7:0] hchar_count,
    input logic [7:0] horizontal_displayed,input logic [4:0] max_raster,
    input logic [7:0] compare_line,input logic [1:0] mode,input logic [7:0] splt,
    input logic [13:0] ssa,input logic [7:0] sscr,
    output logic [15:0] ram_addr,input logic [7:0] ram_data,output logic [3:0] pen,
    output logic border,output logic hsync,output logic vsync,output logic [9:0] active_x);
    logic [7:0] pref_b0,active_b0,active_b1; logic [2:0] de_pipe,hs_pipe,vs_pipe;
    logic [3:0] slot; logic [7:0] px_byte; logic [2:0] within;
    logic split_active; logic [13:0] split_row_ma; logic hsync_d,vsync_d;
    wire hsync_fall=hsync_d&&!crtc_hsync, vsync_rise=!vsync_d&&crtc_vsync;
    logic [13:0] ma_eff; logic [2:0] ra_eff; logic cclk;
    function automatic [15:0] cpc_addr(input logic [13:0] ma,input logic [2:0] ra,input logic byte_phase); cpc_addr={ma[13],ma[12],ra,ma[9:0],byte_phase}; endfunction
    always_comb begin ma_eff=split_active?(split_row_ma+{6'd0,hchar_count}):crtc_ma;ra_eff=crtc_ra[2:0]+sscr[6:4];cclk=(pixel_phase!=0);ram_addr=cpc_addr(ma_eff,ra_eff,cclk);end
    always_ff @(posedge clk16 or negedge rst_n) begin if(!rst_n) begin split_active<=0;split_row_ma<=0;hsync_d<=0;vsync_d<=0;end else begin hsync_d<=crtc_hsync;vsync_d<=crtc_vsync;if(vsync_rise)split_active<=0;if(hsync_fall)begin if((splt!=0)&&(compare_line==splt))begin split_active<=1;split_row_ma<=ssa;end else if(split_active&&(crtc_ra==max_raster))split_row_ma<=split_row_ma+{6'd0,horizontal_displayed};end end end
    logic [3:0] raw_pen; logic raw_border;
    always_comb begin slot=(pixel_phase>=3)?pixel_phase-3:pixel_phase+13;px_byte=slot[3]?active_b1:active_b0;within=slot[2:0];raw_pen=0;case(mode)2'b00:raw_pen=within[2]?{px_byte[0],px_byte[4],px_byte[2],px_byte[6]}:{px_byte[1],px_byte[5],px_byte[3],px_byte[7]};2'b01:case(within[2:1])0:raw_pen={2'b00,px_byte[3],px_byte[7]};1:raw_pen={2'b00,px_byte[2],px_byte[6]};2:raw_pen={2'b00,px_byte[1],px_byte[5]};default:raw_pen={2'b00,px_byte[0],px_byte[4]};endcase 2'b10:raw_pen={3'b000,px_byte[7-within]};default:raw_pen=within[2]?{2'b00,px_byte[2],px_byte[6]}:{2'b00,px_byte[3],px_byte[7]};endcase raw_border=~de_pipe[2];hsync=hs_pipe[2];vsync=vs_pipe[2];end
    logic [3:0] pen_history[0:14];logic border_history[0:14];integer j;logic [3:0] delayed_pen;logic delayed_border;
    always_comb begin if(sscr[3:0]==0)begin delayed_pen=raw_pen;delayed_border=raw_border;end else begin delayed_pen=pen_history[sscr[3:0]-1'b1];delayed_border=border_history[sscr[3:0]-1'b1];end if(sscr[7]&&(active_x<16)&&!raw_border)border=1;else border=delayed_border;pen=delayed_pen;end
    always_ff @(posedge clk16 or negedge rst_n) begin if(!rst_n)begin pref_b0<=0;active_b0<=0;active_b1<=0;de_pipe<=0;hs_pipe<=0;vs_pipe<=0;active_x<=0;for(j=0;j<15;j=j+1)begin pen_history[j]<=0;border_history[j]<=1;end end else begin de_pipe<={de_pipe[1:0],crtc_de};hs_pipe<={hs_pipe[1:0],crtc_hsync};vs_pipe<={vs_pipe[1:0],crtc_vsync};if(pixel_phase==2)pref_b0<=ram_data;if(pixel_phase==3)begin active_b0<=pref_b0;active_b1<=ram_data;end pen_history[0]<=raw_pen;border_history[0]<=raw_border;for(j=1;j<15;j=j+1)begin pen_history[j]<=pen_history[j-1];border_history[j]<=border_history[j-1];end if(!de_pipe[2])active_x<=0;else if(active_x!=1023)active_x<=active_x+1'b1;end end
endmodule
