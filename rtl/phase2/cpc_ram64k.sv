module cpc_ram64k(
    input  logic        clk16,
    input  logic [15:0] cpu_addr,
    input  logic [7:0]  cpu_wdata,
    input  logic        cpu_we,
    output logic [7:0]  cpu_rdata,
    input  logic [15:0] video_addr,
    output logic [7:0]  video_rdata
);
    // 64 KiB CPC base RAM. Two synchronous ports are used so CPU and display
    // fetches can proceed in deterministic slots. GOWIN can infer BSRAM here.
    (* ram_style = "block" *) logic [7:0] mem [0:65535];

    always_ff @(posedge clk16) begin
        if (cpu_we) mem[cpu_addr] <= cpu_wdata;
        cpu_rdata   <= mem[cpu_addr];
        video_rdata <= mem[video_addr];
    end
endmodule
