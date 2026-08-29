module gx4000_adc_regs (
    input  logic        page_enable,
    input  logic [15:0] cpu_addr,
    input  logic        cpu_read,
    input  logic [5:0]  adc0,
    input  logic [5:0]  adc1,
    input  logic [5:0]  adc2,
    input  logic [5:0]  adc3,
    output logic        cpu_hit,
    output logic [7:0]  cpu_rdata
);
    assign cpu_hit = page_enable && cpu_read && (cpu_addr >= 16'h6808) && (cpu_addr <= 16'h680F);
    always_comb begin
        cpu_rdata = 8'hFF;
        if (cpu_hit) begin
            case (cpu_addr[2:0])
                3'd0: cpu_rdata = {2'b00,adc0};
                3'd1: cpu_rdata = {2'b00,adc1};
                3'd2: cpu_rdata = {2'b00,adc2};
                3'd3: cpu_rdata = {2'b00,adc3};
                3'd4: cpu_rdata = 8'h3F;
                3'd5: cpu_rdata = 8'h00;
                3'd6: cpu_rdata = 8'h3F;
                default: cpu_rdata = 8'h00;
            endcase
        end
    end
endmodule
