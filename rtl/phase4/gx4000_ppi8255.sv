module gx4000_ppi8255 (
    input  logic        clk16,
    input  logic        rst_n,
    input  logic        io_read,
    input  logic        io_write,
    input  logic [15:0] cpu_addr,
    input  logic [7:0]  cpu_wdata,
    input  logic        vsync,

    input  logic [7:0]  ay_read_data,
    output logic        ay_select_strobe,
    output logic        ay_write_strobe,
    output logic [7:0]  ay_bus_data,
    output logic [3:0]  keyboard_row,

    output logic        cpu_hit,
    output logic [7:0]  cpu_rdata
);
    logic [7:0] port_a_latch;
    logic [7:0] port_c_latch;
    logic [7:0] control;

    wire ppi_selected = ~cpu_addr[11];
    wire [1:0] port_sel = cpu_addr[9:8];
    wire port_a_input = control[4];
    wire port_b_input = control[1];
    wire port_c_upper_input = control[3];
    wire port_c_lower_input = control[0];
    wire [1:0] ay_mode = port_c_latch[7:6];

    assign cpu_hit = ppi_selected && (io_read || io_write);
    assign ay_bus_data = port_a_latch;
    assign keyboard_row = port_c_latch[3:0];

    logic [7:0] port_b_input_value;
    logic [7:0] port_c_read_value;
    always_comb begin
        // GX4000/CPC-compatible status defaults: cassette/printer/expansion inactive,
        // PAL/50 Hz selected, Amstrad distributor ID, and CRTC VSYNC on bit 0.
        port_b_input_value = {4'b1111, 3'b111, vsync};

        port_c_read_value = port_c_latch;
        if (port_c_upper_input)
            port_c_read_value[7:4] = 4'hF;
        if (port_c_lower_input)
            port_c_read_value[3:0] = 4'hF;

        cpu_rdata = 8'hFF;
        if (ppi_selected && io_read) begin
            case (port_sel)
                2'b00: begin
                    if (port_a_input)
                        cpu_rdata = (ay_mode == 2'b01) ? ay_read_data : 8'hFF;
                    else
                        cpu_rdata = port_a_latch;
                end
                2'b01: cpu_rdata = port_b_input ? port_b_input_value : 8'hFF;
                2'b10: cpu_rdata = port_c_read_value;
                default: cpu_rdata = 8'hFF;
            endcase
        end
    end

    function automatic [7:0] bsr_update(
        input logic [7:0] old_pc,
        input logic [7:0] bsr
    );
        logic [7:0] tmp;
        logic [2:0] bitno;
        begin
            tmp = old_pc;
            bitno = bsr[3:1];
            tmp[bitno] = bsr[0];
            bsr_update = tmp;
        end
    endfunction

    logic [7:0] next_pc;
    always_ff @(posedge clk16 or negedge rst_n) begin
        if (!rst_n) begin
            port_a_latch <= 8'h00;
            port_c_latch <= 8'h00;
            // 8255 reset state: all ports input, mode 0.
            control <= 8'h9B;
            ay_select_strobe <= 1'b0;
            ay_write_strobe <= 1'b0;
        end else begin
            ay_select_strobe <= 1'b0;
            ay_write_strobe <= 1'b0;

            if (ppi_selected && io_write) begin
                case (port_sel)
                    2'b00: begin
                        port_a_latch <= cpu_wdata;
                        // If software changes PA while AY control is already asserted,
                        // emulate the visible bus action. Normal CPC code uses 00 inactive
                        // between operations, so this also catches non-standard sequences.
                        if (!port_a_input) begin
                            if (ay_mode == 2'b11)
                                ay_select_strobe <= 1'b1;
                            else if (ay_mode == 2'b10)
                                ay_write_strobe <= 1'b1;
                        end
                    end
                    2'b10: begin
                        port_c_latch <= cpu_wdata;
                        if (!port_c_upper_input) begin
                            if (cpu_wdata[7:6] == 2'b11)
                                ay_select_strobe <= 1'b1;
                            else if (cpu_wdata[7:6] == 2'b10)
                                ay_write_strobe <= 1'b1;
                        end
                    end
                    2'b11: begin
                        if (cpu_wdata[7]) begin
                            // Mode-set command. The CPC/GX4000 uses mode 0.
                            control <= cpu_wdata;
                            port_a_latch <= 8'h00;
                            port_c_latch <= 8'h00;
                        end else begin
                            // Bit set/reset operates on Port C without altering mode.
                            next_pc = bsr_update(port_c_latch, cpu_wdata);
                            port_c_latch <= next_pc;
                            if ((cpu_wdata[3:1] >= 3'd6) && !port_c_upper_input) begin
                                if (next_pc[7:6] == 2'b11)
                                    ay_select_strobe <= 1'b1;
                                else if (next_pc[7:6] == 2'b10)
                                    ay_write_strobe <= 1'b1;
                            end
                        end
                    end
                    default: ;
                endcase
            end
        end
    end
endmodule
