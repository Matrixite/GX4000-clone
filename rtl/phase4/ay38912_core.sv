module ay38912_core (
    input  logic        clk16,
    input  logic        rst_n,

    input  logic        ppi_select_strobe,
    input  logic        ppi_write_strobe,
    input  logic [7:0]  ppi_data,

    input  logic        dma_write_strobe,
    input  logic [3:0]  dma_reg,
    input  logic [7:0]  dma_data,

    input  logic [7:0]  port_a_in,
    output logic [7:0]  selected_read_data,

    output logic signed [15:0] audio_left,
    output logic signed [15:0] audio_right
);
    logic [7:0] regs [0:15];
    logic [3:0] selected_reg;

    wire do_write = dma_write_strobe || ppi_write_strobe;
    wire [3:0] write_reg = dma_write_strobe ? dma_reg : selected_reg;
    wire [7:0] write_data = dma_write_strobe ? dma_data : ppi_data;

    function automatic [7:0] masked_value(
        input logic [3:0] r,
        input logic [7:0] d
    );
        begin
            case (r)
                4'd1,4'd3,4'd5: masked_value = {4'h0,d[3:0]};
                4'd6: masked_value = {3'b000,d[4:0]};
                4'd8,4'd9,4'd10: masked_value = {3'b000,d[4:0]};
                4'd13: masked_value = {4'h0,d[3:0]};
                default: masked_value = d;
            endcase
        end
    endfunction

    always_comb begin
        case (selected_reg)
            4'd14: begin
                if (!regs[7][6])
                    selected_read_data = port_a_in;
                else
                    selected_read_data = regs[14] & port_a_in;
            end
            4'd15: begin
                if (!regs[7][7])
                    selected_read_data = 8'hFF;
                else
                    selected_read_data = regs[15];
            end
            default: selected_read_data = regs[selected_reg];
        endcase
    end

    // AY timing from the 1 MHz CPC PSG input clock:
    // tone counter step = clk/8, noise = clk/16, envelope = clk/256.
    // From a 16 MHz master those are /128, /256 and /4096 respectively.
    logic [6:0]  tone_div;
    logic [7:0]  noise_div;
    logic [11:0] env_div;
    wire tone_tick = (tone_div == 7'd127);
    wire noise_tick = (noise_div == 8'd255);
    wire env_tick = (env_div == 12'd4095);

    logic [11:0] tone_counter [0:2];
    logic [2:0] tone_state;
    logic [4:0] noise_counter;
    logic [16:0] noise_lfsr;
    logic [15:0] env_counter;
    logic [3:0] env_level;
    logic env_direction_up;
    logic env_holding;
    logic env_continue, env_attack, env_alternate, env_hold;

    function automatic [11:0] tone_period(input integer ch);
        logic [11:0] p;
        begin
            case (ch)
                0: p = {regs[1][3:0],regs[0]};
                1: p = {regs[3][3:0],regs[2]};
                default: p = {regs[5][3:0],regs[4]};
            endcase
            tone_period = (p == 0) ? 12'd1 : p;
        end
    endfunction

    function automatic [4:0] noise_period;
        begin
            noise_period = (regs[6][4:0] == 0) ? 5'd1 : regs[6][4:0];
        end
    endfunction

    function automatic [15:0] envelope_period;
        logic [15:0] p;
        begin
            p = {regs[12],regs[11]};
            envelope_period = (p == 0) ? 16'd1 : p;
        end
    endfunction

    integer i;
    always_ff @(posedge clk16 or negedge rst_n) begin
        if (!rst_n) begin
            selected_reg <= 4'd0;
            tone_div <= 7'd0;
            noise_div <= 8'd0;
            env_div <= 12'd0;
            tone_state <= 3'b111;
            noise_lfsr <= 17'h1FFFF;
            noise_counter <= 5'd0;
            env_counter <= 16'd0;
            env_level <= 4'd0;
            env_direction_up <= 1'b0;
            env_holding <= 1'b1;
            env_continue <= 1'b0;
            env_attack <= 1'b0;
            env_alternate <= 1'b0;
            env_hold <= 1'b0;
            for (i=0;i<16;i=i+1)
                regs[i] <= 8'h00;
            regs[7] <= 8'h3F;
            for (i=0;i<3;i=i+1)
                tone_counter[i] <= 12'd0;
        end else begin
            if (ppi_select_strobe)
                selected_reg <= ppi_data[3:0];

            if (do_write) begin
                regs[write_reg] <= masked_value(write_reg, write_data);
                if (write_reg == 4'd13) begin
                    env_continue <= write_data[3];
                    env_attack <= write_data[2];
                    env_alternate <= write_data[1];
                    env_hold <= write_data[0];
                    env_level <= write_data[2] ? 4'd0 : 4'd15;
                    env_direction_up <= write_data[2];
                    env_holding <= 1'b0;
                    env_counter <= 16'd0;
                    env_div <= 12'd0;
                end
            end

            if (tone_tick)
                tone_div <= 7'd0;
            else
                tone_div <= tone_div + 7'd1;

            if (noise_tick)
                noise_div <= 8'd0;
            else
                noise_div <= noise_div + 8'd1;

            if (env_tick)
                env_div <= 12'd0;
            else
                env_div <= env_div + 12'd1;

            if (tone_tick) begin
                for (i=0;i<3;i=i+1) begin
                    if (tone_counter[i] + 12'd1 >= tone_period(i)) begin
                        tone_counter[i] <= 12'd0;
                        tone_state[i] <= ~tone_state[i];
                    end else begin
                        tone_counter[i] <= tone_counter[i] + 12'd1;
                    end
                end
            end

            if (noise_tick) begin
                if (noise_counter + 5'd1 >= noise_period()) begin
                    noise_counter <= 5'd0;
                    noise_lfsr <= {noise_lfsr[0] ^ noise_lfsr[3], noise_lfsr[16:1]};
                end else begin
                    noise_counter <= noise_counter + 5'd1;
                end
            end

            if (env_tick && !env_holding) begin
                if (env_counter + 16'd1 >= envelope_period()) begin
                    env_counter <= 16'd0;
                    if (env_direction_up) begin
                        if (env_level == 4'd15) begin
                            if (!env_continue) begin
                                env_level <= 4'd0;
                                env_holding <= 1'b1;
                            end else if (env_hold) begin
                                env_level <= env_alternate ? 4'd0 : 4'd15;
                                env_holding <= 1'b1;
                            end else if (env_alternate) begin
                                env_direction_up <= 1'b0;
                                env_level <= 4'd14;
                            end else begin
                                env_level <= 4'd0;
                            end
                        end else begin
                            env_level <= env_level + 4'd1;
                        end
                    end else begin
                        if (env_level == 4'd0) begin
                            if (!env_continue) begin
                                env_level <= 4'd0;
                                env_holding <= 1'b1;
                            end else if (env_hold) begin
                                env_level <= env_alternate ? 4'd15 : 4'd0;
                                env_holding <= 1'b1;
                            end else if (env_alternate) begin
                                env_direction_up <= 1'b1;
                                env_level <= 4'd1;
                            end else begin
                                env_level <= 4'd15;
                            end
                        end else begin
                            env_level <= env_level - 4'd1;
                        end
                    end
                end else begin
                    env_counter <= env_counter + 16'd1;
                end
            end
        end
    end

    function automatic [11:0] amp_table(input logic [3:0] v);
        begin
            case (v)
                4'd0:  amp_table=12'd0;
                4'd1:  amp_table=12'd31;
                4'd2:  amp_table=12'd45;
                4'd3:  amp_table=12'd63;
                4'd4:  amp_table=12'd90;
                4'd5:  amp_table=12'd127;
                4'd6:  amp_table=12'd180;
                4'd7:  amp_table=12'd255;
                4'd8:  amp_table=12'd360;
                4'd9:  amp_table=12'd509;
                4'd10: amp_table=12'd720;
                4'd11: amp_table=12'd1018;
                4'd12: amp_table=12'd1440;
                4'd13: amp_table=12'd2036;
                4'd14: amp_table=12'd2880;
                default: amp_table=12'd4095;
            endcase
        end
    endfunction

    logic [2:0] gate;
    logic [11:0] amp [0:2];
    logic signed [13:0] ch [0:2];
    logic signed [14:0] left_mix, right_mix;
    integer c;
    always_comb begin
        gate[0] = (regs[7][0] || tone_state[0]) && (regs[7][3] || noise_lfsr[0]);
        gate[1] = (regs[7][1] || tone_state[1]) && (regs[7][4] || noise_lfsr[0]);
        gate[2] = (regs[7][2] || tone_state[2]) && (regs[7][5] || noise_lfsr[0]);

        for (c=0;c<3;c=c+1) begin
            amp[c] = amp_table(regs[8+c][4] ? env_level : regs[8+c][3:0]);
            if (amp[c] == 0)
                ch[c] = 14'sd0;
            else if (regs[7][c] && regs[7][c+3])
                // Both generators disabled: preserve DAC/volume-change playback.
                ch[c] = $signed({2'b00,amp[c]});
            else if (gate[c])
                ch[c] = $signed({2'b00,amp[c]});
            else
                ch[c] = -$signed({2'b00,amp[c]});
        end

        // Original CPC+/GX4000 stereo wiring: A left, B both, C right.
        left_mix = ch[0] + ch[1];
        right_mix = ch[1] + ch[2];
        audio_left = left_mix <<< 1;
        audio_right = right_mix <<< 1;
    end
endmodule
