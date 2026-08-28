module cpc_ram64k_plus (
    input  logic        clk16,
    input  logic [15:0] cpu_addr,
    input  logic [7:0]  cpu_wdata,
    input  logic        cpu_we,
    output logic [7:0]  cpu_rdata,

    input  logic [15:0] video_addr,
    output logic [7:0]  video_rdata,

    input  logic [15:0] dma_addr,
    output logic [7:0]  dma_rdata
);
    // Phase 3 adds a physical-RAM DMA read port. The ASIC DMA engine is never
    // affected by ROM mapping; it always reads the underlying 64 KiB RAM.
    (* ram_style = "block" *) logic [7:0] mem [0:65535];

    always_ff @(posedge clk16) begin
        if (cpu_we)
            mem[cpu_addr] <= cpu_wdata;
        cpu_rdata   <= mem[cpu_addr];
        video_rdata <= mem[video_addr];
        dma_rdata   <= mem[dma_addr];
    end
endmodule
