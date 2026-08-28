module cpc_video(
    input logic clk16,input logic rst_n,input logic [3:0] pixel_phase,
    input logic [13:0] crtc_ma,input logic [4:0] crtc_ra,input logic crtc_de,
    input logic crtc_hsync,input logic crtc_vsync,input logic [1:0] mode,
    output logic [15:0] ram_addr,input logic [7:0] ram_data,output logic [3:0] pen,
    output logic border,output logic hsync,output logic vsync);
    logic [7:0] pref_b0,active_b0,active_b1; logic [2:0] de_pipe,hs_pipe,vs_pipe;
    logic [3:0] slot; logic [7:0] px_byte; logic [2:0] within;
    function automatic [15:0] cpc_addr(input logic [13:0] ma,input logic [4:0] ra,input logic cclk);
        cpc_addr={ma[13],ma[12],ra[2:0],ma[9:0],cclk};
    endfunction
    always_comb begin
        ram_addr=cpc_addr(crtc_ma,crtc_ra,(pixel_phase!=4'd0));
        slot=(pixel_phase>=4'd3)?pixel_phase-4'd3:pixel_phase+4'd13;
        px_byte=slot[3]?active_b1:active_b0; within=slot[2:0]; pen=4'd0;
        case(mode)
          2'b00: pen=within[2]?{px_byte[0],px_byte[4],px_byte[2],px_byte[6]}:{px_byte[1],px_byte[5],px_byte[3],px_byte[7]};
          2'b01: case(within[2:1])
            2'd0: pen={2'b00,px_byte[3],px_byte[7]}; 2'd1: pen={2'b00,px_byte[2],px_byte[6]};
            2'd2: pen={2'b00,px_byte[1],px_byte[5]}; default: pen={2'b00,px_byte[0],px_byte[4]}; endcase
          2'b10: pen={3'b000,px_byte[7-within]};
          default: pen=within[2]?{2'b00,px_byte[2],px_byte[6]}:{2'b00,px_byte[3],px_byte[7]};
        endcase
        border=~de_pipe[2]; hsync=hs_pipe[2]; vsync=vs_pipe[2];
    end
    always_ff @(posedge clk16 or negedge rst_n) begin
      if(!rst_n) begin pref_b0<=0;active_b0<=0;active_b1<=0;de_pipe<=0;hs_pipe<=0;vs_pipe<=0; end
      else begin de_pipe<={de_pipe[1:0],crtc_de};hs_pipe<={hs_pipe[1:0],crtc_hsync};vs_pipe<={vs_pipe[1:0],crtc_vsync};
        if(pixel_phase==4'd2) pref_b0<=ram_data;
        if(pixel_phase==4'd3) begin active_b0<=pref_b0;active_b1<=ram_data; end end
    end
endmodule
