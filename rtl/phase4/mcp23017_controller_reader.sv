module mcp23017_controller_reader (
    input  logic       clk16,
    input  logic       rst_n,
    inout  wire        ctrl_sda,
    inout  wire        ctrl_scl,
    output logic [6:0] joy0_n,
    output logic [6:0] joy1_n,
    output logic       controller_valid,
    output logic       controller_fault
);
    // MCP23017 at 7-bit address 0x20 (A2:A0 tied low).
    // The controller adapter supplies 4.7k pull-ups on SDA/SCL and on GPIOA/B.
    // MCP23017 reset defaults already make GPIOA/B inputs, so the FPGA only
    // needs to poll GPIOA (0x12) and GPIOB (0x13).
    //
    // GPIOA[6:0] = P1 Up,Down,Left,Right,Fire1,Fire2,Fire3 (active low)
    // GPIOB[6:0] = P2 Up,Down,Left,Right,Fire1,Fire2,Fire3 (active low)
    // GPIOA7/GPIOB7 remain spare.

    logic scl_drive_low, sda_drive_low;
    assign ctrl_scl = scl_drive_low ? 1'b0 : 1'bz;
    assign ctrl_sda = sda_drive_low ? 1'b0 : 1'bz;
    wire sda_in = ctrl_sda;

    // One state-machine tick every 80 clk16 clocks. Each I2C half-period uses
    // one tick, giving approximately 100 kHz SCL from the 16 MHz master clock.
    logic [6:0] div_count;
    wire tick = (div_count == 7'd79);
    always_ff @(posedge clk16 or negedge rst_n) begin
        if (!rst_n)
            div_count <= 7'd0;
        else if (tick)
            div_count <= 7'd0;
        else
            div_count <= div_count + 7'd1;
    end

    localparam [4:0]
        ST_IDLE         = 5'd0,
        ST_START_RELEASE= 5'd1,
        ST_START_SDA    = 5'd2,
        ST_SEND_LOW     = 5'd3,
        ST_SEND_HIGH    = 5'd4,
        ST_ACK_LOW      = 5'd5,
        ST_ACK_HIGH     = 5'd6,
        ST_READ_LOW     = 5'd7,
        ST_READ_HIGH    = 5'd8,
        ST_MACK_LOW     = 5'd9,
        ST_MACK_HIGH    = 5'd10,
        ST_MNACK_LOW    = 5'd11,
        ST_MNACK_HIGH   = 5'd12,
        ST_STOP_LOW     = 5'd13,
        ST_STOP_HIGH    = 5'd14,
        ST_STOP_RELEASE = 5'd15;

    logic [4:0] state;
    logic [7:0] tx_byte, rx_byte;
    logic [2:0] bit_index;
    logic [1:0] transaction_phase;
    logic       read_index;
    logic [1:0] stop_action;
    logic [8:0] idle_ticks;

    always_ff @(posedge clk16 or negedge rst_n) begin
        if (!rst_n) begin
            scl_drive_low <= 1'b0;
            sda_drive_low <= 1'b0;
            joy0_n <= 7'h7F;
            joy1_n <= 7'h7F;
            controller_valid <= 1'b0;
            controller_fault <= 1'b0;
            state <= ST_IDLE;
            tx_byte <= 8'h40;
            rx_byte <= 8'h00;
            bit_index <= 3'd7;
            transaction_phase <= 2'd0;
            read_index <= 1'b0;
            stop_action <= 2'd0;
            idle_ticks <= 9'd0;
        end else if (tick) begin
            case (state)
                ST_IDLE: begin
                    scl_drive_low <= 1'b0;
                    sda_drive_low <= 1'b0;
                    if (idle_ticks == 9'd199) begin
                        idle_ticks <= 9'd0;
                        tx_byte <= 8'h40;       // 0x20 + write
                        bit_index <= 3'd7;
                        transaction_phase <= 2'd0;
                        read_index <= 1'b0;
                        controller_fault <= 1'b0;
                        state <= ST_START_RELEASE;
                    end else begin
                        idle_ticks <= idle_ticks + 9'd1;
                    end
                end

                ST_START_RELEASE: begin
                    scl_drive_low <= 1'b0;
                    sda_drive_low <= 1'b0;
                    state <= ST_START_SDA;
                end
                ST_START_SDA: begin
                    // START: SDA falls while SCL is high.
                    sda_drive_low <= 1'b1;
                    scl_drive_low <= 1'b0;
                    state <= ST_SEND_LOW;
                end

                ST_SEND_LOW: begin
                    scl_drive_low <= 1'b1;
                    sda_drive_low <= ~tx_byte[bit_index];
                    state <= ST_SEND_HIGH;
                end
                ST_SEND_HIGH: begin
                    scl_drive_low <= 1'b0;
                    if (bit_index == 3'd0)
                        state <= ST_ACK_LOW;
                    else begin
                        bit_index <= bit_index - 3'd1;
                        state <= ST_SEND_LOW;
                    end
                end

                ST_ACK_LOW: begin
                    scl_drive_low <= 1'b1;
                    sda_drive_low <= 1'b0;
                    state <= ST_ACK_HIGH;
                end
                ST_ACK_HIGH: begin
                    scl_drive_low <= 1'b0;
                    // A high SDA is NACK: abort cleanly and preserve last inputs.
                    if (sda_in) begin
                        controller_fault <= 1'b1;
                        stop_action <= 2'd0;
                        state <= ST_STOP_LOW;
                    end else begin
                        case (transaction_phase)
                            2'd0: begin
                                // Address-write ACKed: point at GPIOA (0x12).
                                tx_byte <= 8'h12;
                                bit_index <= 3'd7;
                                transaction_phase <= 2'd1;
                                state <= ST_SEND_LOW;
                            end
                            2'd1: begin
                                // Register pointer ACKed: STOP then start a read.
                                stop_action <= 2'd1;
                                state <= ST_STOP_LOW;
                            end
                            default: begin
                                // Address-read ACKed: receive GPIOA then GPIOB.
                                bit_index <= 3'd7;
                                rx_byte <= 8'h00;
                                read_index <= 1'b0;
                                state <= ST_READ_LOW;
                            end
                        endcase
                    end
                end

                ST_READ_LOW: begin
                    scl_drive_low <= 1'b1;
                    sda_drive_low <= 1'b0;
                    state <= ST_READ_HIGH;
                end
                ST_READ_HIGH: begin
                    scl_drive_low <= 1'b0;
                    rx_byte[bit_index] <= sda_in;
                    if (bit_index == 3'd0) begin
                        if (!read_index) begin
                            joy0_n <= {rx_byte[6:1], sda_in};
                            read_index <= 1'b1;
                            bit_index <= 3'd7;
                            rx_byte <= 8'h00;
                            state <= ST_MACK_LOW;
                        end else begin
                            joy1_n <= {rx_byte[6:1], sda_in};
                            state <= ST_MNACK_LOW;
                        end
                    end else begin
                        bit_index <= bit_index - 3'd1;
                        state <= ST_READ_LOW;
                    end
                end

                // ACK after GPIOA so the MCP23017 auto-increments to GPIOB.
                ST_MACK_LOW: begin
                    scl_drive_low <= 1'b1;
                    sda_drive_low <= 1'b1;
                    state <= ST_MACK_HIGH;
                end
                ST_MACK_HIGH: begin
                    scl_drive_low <= 1'b0;
                    sda_drive_low <= 1'b1;
                    state <= ST_READ_LOW;
                end

                // NACK after GPIOB to end the two-byte read.
                ST_MNACK_LOW: begin
                    scl_drive_low <= 1'b1;
                    sda_drive_low <= 1'b0;
                    state <= ST_MNACK_HIGH;
                end
                ST_MNACK_HIGH: begin
                    scl_drive_low <= 1'b0;
                    sda_drive_low <= 1'b0;
                    stop_action <= 2'd2;
                    state <= ST_STOP_LOW;
                end

                ST_STOP_LOW: begin
                    scl_drive_low <= 1'b1;
                    sda_drive_low <= 1'b1;
                    state <= ST_STOP_HIGH;
                end
                ST_STOP_HIGH: begin
                    scl_drive_low <= 1'b0;
                    sda_drive_low <= 1'b1;
                    state <= ST_STOP_RELEASE;
                end
                ST_STOP_RELEASE: begin
                    // STOP: SDA rises while SCL is high.
                    scl_drive_low <= 1'b0;
                    sda_drive_low <= 1'b0;
                    if (stop_action == 2'd1) begin
                        tx_byte <= 8'h41;       // 0x20 + read
                        bit_index <= 3'd7;
                        transaction_phase <= 2'd2;
                        stop_action <= 2'd0;
                        state <= ST_START_RELEASE;
                    end else begin
                        if (stop_action == 2'd2) begin
                            controller_valid <= 1'b1;
                            controller_fault <= 1'b0;
                        end
                        stop_action <= 2'd0;
                        idle_ticks <= 9'd0;
                        state <= ST_IDLE;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end
endmodule
