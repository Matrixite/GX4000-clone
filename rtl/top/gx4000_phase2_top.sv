module gx4000_phase2_top(input logic clk27,output logic [13:0] cart_a,output logic [4:0] cart_ca,output logic cart_ce_n,input logic [7:0] cart_d,output logic cart_clk4,output logic cart_cclr,input logic cart_sin,output logic xlat_oe_n,output logic [3:0] video_r,output logic [3:0] video_g,output logic [3:0] video_b,output logic video_hsync,output logic video_vsync,output logic video_de);
logic clk32,clk16,pll_locked,cpu_ce,crtc_ce; logic [3:0] pixel_phase;
cpc_clock_tree clocks(.clk27(clk27),.clk32(clk32),.clk16(clk16),.pll_locked(pll_locked),.pixel_phase(pixel_phase),.cpu_ce(cpu_ce),.crtc_ce(crtc_ce),.cart_clk4(cart_clk4));
logic [7:0] reset_count; logic sys_reset_n;
always_ff @(posedge clk16 or negedge pll_locked) begin if(!pll_locked) begin reset_count<=0;sys_reset_n<=0;end else if(!&reset_count) begin reset_count<=reset_count+1'b1;sys_reset_n<=0;end else sys_reset_n<=1; end
assign cart_cclr=sys_reset_n; assign xlat_oe_n=~sys_reset_n;
wire m1_n,mreq_n,iorq_n,rd_n,wr_n,rfsh_n,halt_n,busak_n; wire [15:0] cpu_addr; wire [7:0] cpu_dout; logic [7:0] cpu_di; logic cpu_wait_n,ga_int_n;
tv80s #(.Mode(0),.T2Write(1),.IOWait(1)) cpu(.reset_n(sys_reset_n),.clk(clk16),.cen(cpu_ce),.wait_n(cpu_wait_n),.int_n(ga_int_n),.nmi_n(1'b1),.busrq_n(1'b1),.m1_n(m1_n),.mreq_n(mreq_n),.iorq_n(iorq_n),.rd_n(rd_n),.wr_n(wr_n),.rfsh_n(rfsh_n),.halt_n(halt_n),.busak_n(busak_n),.A(cpu_addr),.di(cpu_di),.dout(cpu_dout));
wire mem_read=!mreq_n&&!rd_n, mem_write=!mreq_n&&!wr_n, io_read=!iorq_n&&!rd_n&&m1_n, io_write=!iorq_n&&!wr_n&&m1_n, int_ack=!iorq_n&&!m1_n;
wire ga_we=io_write&&(cpu_addr[15:14]==2'b01), crtc_sel_we=io_write&&(cpu_addr[15:8]==8'hBC), crtc_data_we=io_write&&(cpu_addr[15:8]==8'hBD), crtc_data_re=io_read&&(cpu_addr[15:8]==8'hBF);
logic [7:0] crtc_rdata; logic [13:0] crtc_ma; logic [4:0] crtc_ra; logic crtc_hsync,crtc_vsync,crtc_de;
cpc_crtc6845 crtc(.clk16(clk16),.rst_n(sys_reset_n),.char_ce(crtc_ce),.select_we(crtc_sel_we),.data_we(crtc_data_we),.cpu_wdata(cpu_dout),.data_re(crtc_data_re),.cpu_rdata(crtc_rdata),.ma(crtc_ma),.ra(crtc_ra),.hsync(crtc_hsync),.vsync(crtc_vsync),.display_en(crtc_de));
logic [1:0] video_mode; logic low_rom_enable,high_rom_enable; logic [7:0] rmr2; logic [3:0] pixel_pen; logic border;
cpc_gate_array ga(.clk16(clk16),.rst_n(sys_reset_n),.io_we(ga_we),.io_data(cpu_dout),.hsync(crtc_hsync),.vsync(crtc_vsync),.int_ack(int_ack),.mode(video_mode),.low_rom_enable(low_rom_enable),.high_rom_enable(high_rom_enable),.rmr2(rmr2),.int_n(ga_int_n),.pixel_pen(pixel_pen),.border(border),.video_r(video_r),.video_g(video_g),.video_b(video_b));
logic [7:0] rom_select; always_ff @(posedge clk16 or negedge sys_reset_n) if(!sys_reset_n) rom_select<=0; else if(io_write&&cpu_addr[15:8]==8'hDF) rom_select<=cpu_dout;
logic [15:0] video_ram_addr; logic [7:0] ram_cpu_data,ram_video_data;
cpc_ram64k ram(.clk16(clk16),.cpu_addr(cpu_addr),.cpu_wdata(cpu_dout),.cpu_we(mem_write),.cpu_rdata(ram_cpu_data),.video_addr(video_ram_addr),.video_rdata(ram_video_data));
cpc_video video(.clk16(clk16),.rst_n(sys_reset_n),.pixel_phase(pixel_phase),.crtc_ma(crtc_ma),.crtc_ra(crtc_ra),.crtc_de(crtc_de),.crtc_hsync(crtc_hsync),.crtc_vsync(crtc_vsync),.mode(video_mode),.ram_addr(video_ram_addr),.ram_data(ram_video_data),.pen(pixel_pen),.border(border),.hsync(video_hsync),.vsync(video_vsync)); assign video_de=~border;
logic cart_selected; logic [4:0] cart_page; logic [13:0] cart_offset;
gx4000_cart_mapper mapper(.cpu_addr(cpu_addr),.rmr2(rmr2),.rom_select(rom_select),.low_rom_enable(low_rom_enable),.high_rom_enable(high_rom_enable),.cart_selected(cart_selected),.cart_page(cart_page),.cart_offset(cart_offset));
logic [7:0] cart_cpu_data; logic cart_wait_n; wire cart_request=mem_read&&cart_selected;
cpc_cart_cpu_bridge #(.WAIT_CYCLES(6)) bridge(.clk16(clk16),.rst_n(sys_reset_n),.request(cart_request),.page(cart_page),.offset(cart_offset),.cart_d(cart_d),.cart_ca(cart_ca),.cart_a(cart_a),.cart_ce_n(cart_ce_n),.wait_n(cart_wait_n),.data(cart_cpu_data)); assign cpu_wait_n=cart_wait_n;
always_comb begin cpu_di=8'hFF; if(mem_read) cpu_di=cart_selected?cart_cpu_data:ram_cpu_data; else if(crtc_data_re) cpu_di=crtc_rdata; end
wire _unused=&{1'b0,cart_sin,rfsh_n,halt_n,busak_n,clk32};
endmodule
