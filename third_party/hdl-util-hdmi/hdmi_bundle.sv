// Fixed 720x576p50 HDMI transmitter timing core.
// Derived from hdl-util/hdmi by Sameer Puri, MIT licensed.
// Upstream: https://github.com/hdl-util/hdmi
// Pinned reference: 83b1c9543a91b776671a44e68e130f81cae437b7
//
// This adaptation intentionally supports the GX4000 target mode only:
// VIC 17, 720x576p50, 27 MHz pixel clock, true HDMI with data islands.

module hdmi
#(
    parameter int VIDEO_ID_CODE = 17,
    parameter bit IT_CONTENT = 1'b1,
    parameter int BIT_WIDTH = 10,
    parameter int BIT_HEIGHT = 10,
    parameter bit DVI_OUTPUT = 1'b0,
    parameter integer VIDEO_REFRESH_RATE = 50,
    parameter int AUDIO_RATE = 48000,
    parameter int AUDIO_BIT_WIDTH = 16,
    parameter bit [8*8-1:0] VENDOR_NAME = {"MATRIX", 16'd0},
    parameter bit [8*16-1:0] PRODUCT_DESCRIPTION = {"GX4000 FPGA", 40'd0},
    parameter bit [7:0] SOURCE_DEVICE_INFORMATION = 8'h08,
    parameter int START_X = 0,
    parameter int START_Y = 0
)
(
    input  logic clk_pixel_x5,
    input  logic clk_pixel,
    input  logic clk_audio,
    input  logic reset,
    input  logic [23:0] rgb,
    input  logic [AUDIO_BIT_WIDTH-1:0] audio_sample_word [1:0],
    output logic [2:0] tmds,
    output logic tmds_clock,
    output logic [BIT_WIDTH-1:0] cx = START_X,
    output logic [BIT_HEIGHT-1:0] cy = START_Y,
    output logic [BIT_WIDTH-1:0] frame_width,
    output logic [BIT_HEIGHT-1:0] frame_height,
    output logic [BIT_WIDTH-1:0] screen_width,
    output logic [BIT_HEIGHT-1:0] screen_height
);
    localparam int NUM_CHANNELS = 3;
    localparam integer VIDEO_RATE = 27000000;

    assign frame_width   = 10'd864;
    assign frame_height  = 10'd625;
    assign screen_width  = 10'd720;
    assign screen_height = 10'd576;

    logic hsync;
    logic vsync;

    always_comb begin
        // VIC17 sync polarity is negative.
        hsync = 1'b1 ^ (cx >= 10'd732 && cx < 10'd796);
        if (cy == 10'd580)
            vsync = 1'b1 ^ (cx >= 10'd732);
        else if (cy == 10'd585)
            vsync = 1'b1 ^ (cx < 10'd732);
        else
            vsync = 1'b1 ^ (cy >= 10'd581 && cy < 10'd586);
    end

    always_ff @(posedge clk_pixel) begin
        if (reset) begin
            cx <= START_X;
            cy <= START_Y;
        end else begin
            if (cx == 10'd863) begin
                cx <= 10'd0;
                if (cy == 10'd624)
                    cy <= 10'd0;
                else
                    cy <= cy + 1'b1;
            end else begin
                cx <= cx + 1'b1;
            end
        end
    end

    logic video_data_period = 1'b0;
    always_ff @(posedge clk_pixel) begin
        if (reset)
            video_data_period <= 1'b0;
        else
            video_data_period <= (cx < 10'd720) && (cy < 10'd576);
    end

    logic [2:0]  mode = 3'd1;
    logic [23:0] video_data = 24'd0;
    logic [5:0]  control_data = 6'd0;
    logic [11:0] data_island_data = 12'd0;

    generate
        if (!DVI_OUTPUT) begin : g_hdmi
            logic video_guard = 1'b1;
            logic video_preamble = 1'b0;

            always_ff @(posedge clk_pixel) begin
                if (reset) begin
                    video_guard <= 1'b1;
                    video_preamble <= 1'b0;
                end else begin
                    video_guard <= (cx >= 10'd862) &&
                                   (cy == 10'd624 || cy < 10'd575);
                    video_preamble <= (cx >= 10'd854) && (cx < 10'd862) &&
                                      (cy == 10'd624 || cy < 10'd575);
                end
            end

            // VIC17 blanking gives room for exactly three 32-pixel data-island packets.
            logic data_island_period_instantaneous;
            assign data_island_period_instantaneous =
                (cx >= 10'd734) && (cx < 10'd830);

            logic packet_enable;
            assign packet_enable =
                data_island_period_instantaneous && (cx[4:0] == 5'd30);

            logic data_island_guard = 1'b0;
            logic data_island_preamble = 1'b0;
            logic data_island_period = 1'b0;

            always_ff @(posedge clk_pixel) begin
                if (reset) begin
                    data_island_guard <= 1'b0;
                    data_island_preamble <= 1'b0;
                    data_island_period <= 1'b0;
                end else begin
                    data_island_guard <= ((cx >= 10'd732 && cx < 10'd734) ||
                                          (cx >= 10'd830 && cx < 10'd832));
                    data_island_preamble <= (cx >= 10'd724 && cx < 10'd732);
                    data_island_period <= data_island_period_instantaneous;
                end
            end

            logic [23:0] header;
            logic [55:0] sub [3:0];
            logic video_field_end;
            assign video_field_end = (cx == 10'd719) && (cy == 10'd575);

            logic [4:0] packet_pixel_counter;
            packet_picker #(
                .VIDEO_ID_CODE(VIDEO_ID_CODE),
                .VIDEO_RATE(VIDEO_RATE),
                .IT_CONTENT(IT_CONTENT),
                .AUDIO_RATE(AUDIO_RATE),
                .AUDIO_BIT_WIDTH(AUDIO_BIT_WIDTH),
                .VENDOR_NAME(VENDOR_NAME),
                .PRODUCT_DESCRIPTION(PRODUCT_DESCRIPTION),
                .SOURCE_DEVICE_INFORMATION(SOURCE_DEVICE_INFORMATION)
            ) u_packet_picker (
                .clk_pixel(clk_pixel),
                .clk_audio(clk_audio),
                .reset(reset),
                .video_field_end(video_field_end),
                .packet_enable(packet_enable),
                .packet_pixel_counter(packet_pixel_counter),
                .audio_sample_word(audio_sample_word),
                .header(header),
                .sub(sub)
            );

            logic [8:0] packet_data;
            packet_assembler u_packet_assembler (
                .clk_pixel(clk_pixel),
                .reset(reset),
                .data_island_period(data_island_period),
                .header(header),
                .sub(sub),
                .packet_data(packet_data),
                .counter(packet_pixel_counter)
            );

            always_ff @(posedge clk_pixel) begin
                if (reset) begin
                    mode <= 3'd2;
                    video_data <= 24'd0;
                    control_data <= 6'd0;
                    data_island_data <= 12'd0;
                end else begin
                    mode <= data_island_guard ? 3'd4 :
                            data_island_period ? 3'd3 :
                            video_guard ? 3'd2 :
                            video_data_period ? 3'd1 : 3'd0;
                    video_data <= rgb;
                    control_data <= {
                        {1'b0, data_island_preamble},
                        {1'b0, video_preamble || data_island_preamble},
                        {vsync, hsync}
                    };
                    data_island_data[11:4] <= packet_data[8:1];
                    data_island_data[3] <= (cx != 10'd0);
                    data_island_data[2] <= packet_data[0];
                    data_island_data[1:0] <= {vsync, hsync};
                end
            end
        end else begin : g_dvi
            always_ff @(posedge clk_pixel) begin
                if (reset) begin
                    mode <= 3'd0;
                    video_data <= 24'd0;
                    control_data <= 6'd0;
                end else begin
                    mode <= video_data_period ? 3'd1 : 3'd0;
                    video_data <= rgb;
                    control_data <= {4'b0000, vsync, hsync};
                end
            end
        end
    endgenerate

    logic [9:0] tmds_internal [NUM_CHANNELS-1:0];
    genvar i;
    generate
        for (i = 0; i < NUM_CHANNELS; i = i + 1) begin : tmds_gen
            tmds_channel #(.CN(i)) u_timds (
                .clk_pixel(clk_pixel),
                .video_data(video_data[i*8+:+8]),
                .data_island_data(data_island_data[i*4+:4]),
                .control_data(control_data[i*2+2:+2]),
                .mode(mode),
                .tmds(tmds_internal[i])
            );
        end
    endgenerate

    serializer #(
        .NUM_CHANNELS(NUM_CHANNELS),
        .VIDEO_RATE(VIDEO_RATE)
    ) u_serializer (
        .clk_pixel(clk_pixel),
        .clk_pixel_x5(clk_pixel_x5),
        .reset(reset),
        .tmds_internal(tmds_internal),
        .tmds(tmds),
        .tmds_clock(tmds_clock)
    );

endmodule
// TMDS channel encoder for HDMI 1.4a video, control and TERC4 data-island codes.
// Derived from hdl-util/hdmi by Sameer Puri, MIT licensed.

module tmds_channel
#(
    parameter int CN = 0
)
(
    input logic clk_pixel,
    input logic [7:0] video_data,
    input logic [3:0] data_island_data,
    input logic [1:0] control_data,
    input logic [2:0] mode,
    output logic [9:0] tmds = 10'b1101010100
);
    logic signed [4:0] acc = 5'sd0;
    logic [8:0] q_m;
    logic [9:0] q_out;
    logic [3:0] N1D;
    logic signed [4:0] N1q_m07;
    logic signed [4:0] N0q_m07;
    logic signed [4:0] acc_add;
    integer i;

    always_comb begin
        N1D = video_data[0] + video_data[1] + video_data[2] + video_data[3] +
              video_data[4] + video_data[5] + video_data[6] + video_data[7];
        case (q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7])
            4'd0: N1q_m07 = 5'sd0;
            4'd1: N1q_m07 = 5'sd1;
            4'd2: N1q_m07 = 5'sd2;
            4'd3: N1q_m07 = 5'sd3;
            4'd4: N1q_m07 = 5'sd4;
            4'd5: N1q_m07 = 5'sd5;
            4'd6: N1q_m07 = 5'sd6;
            4'd7: N1q_m07 = 5'sd7;
            4'd8: N1q_m07 = 5'sd8;
            default: N1q_m07 = 5'sd0;
        endcase
        N0q_m07 = 5'sd8 - N1q_m07;

        if (N1D > 4'd4 || (N1D == 4'd4 && video_data[0] == 1'b0)) begin
            q_m[0] = video_data[0];
            for (i = 0; i < 7; i = i + 1)
                q_m[i + 1] = q_m[i] ~^ video_data[i + 1];
            q_m[8] = 1'b0;
        end else begin
            q_m[0] = video_data[0];
            for (i = 0; i < 7; i = i + 1)
                q_m[i + 1] = q_m[i] ^ video_data[i + 1];
            q_m[8] = 1'b1;
        end

        if (acc == 5'sd0 || (N1q_m07 == N0q_m07)) begin
            if (q_m[8]) begin
                acc_add = N1q_m07 - N0q_m07;
                q_out = {~q_m[8], q_m[8], q_m[7:0]};
            end else begin
                acc_add = N0q_m07 - N1q_m07;
                q_out = {~q_m[8], q_m[8], ~q_m[7:0]};
            end
        end else begin
            if ((acc > 5'sd0 && N1q_m07 > N0q_m07) || (acc < 5'sd0 && N1q_m07 < N0q_m07)) begin
                q_out = {1'b1, q_m[8], ~q_m[7:0]};
                acc_add = (N0q_m07 - N1q_m07) + (q_m[8] ? 5'sd2 : 5'sd0);
            end else begin
                q_out = {1'b0, q_m[8], q_m[7:0]};
                acc_add = (N1q_m07 - N0q_m07) - (~q_m[8] ? 5'sd2 : 5'sd0);
            end
        end
    end

    logic [9:0] control_coding;
    always_comb begin
        case (control_data)
            2'b00: control_coding = 10'b1101010100;
            2'b01: control_coding = 10'b0010101011;
            vb10: control_coding = 10'b0101010100;
            default: control_coding = 10'b1010101011;
        endcase
    end

    logic [9:0] terc4_coding;
    always_comb begin
        case (data_island_data)
            4'h0: terc4_coding = 10'b1010011100;
            4'h1: terc4_coding = 10'b1001100011;
            4'h2: terc4_coding = 10'b1011100100;
            4'h3: terc4_coding = 10'b1011100010;
            4'h4: terc4_coding = 10'b0101110001;
            4'h5: terc4_coding = 10'b0100011110;
            4'h6: terc4_coding = 10'b0110001110;
            4'h7: terc4_coding = 10'b0100111100;
            4'h8: terc4_coding = 10'b1011001100;
            4'h9: terc4_coding = 10'b0100111001;
            4'hA: terc4_coding = 10'b0110011100;
            4'hB: terc4_coding = 10'b1011000110;
            4'hC: terc4_coding = 10'b1010001110;
            4'hD: terc4_coding = 10'b1001110001;
            4'hE: terc4_coding = 10'b0101100011;
            default: terc4_coding = 10'b1011000011;
        endcase
    end

    logic [9:0] video_guard_band;
    generate
        if (CN == 0 || CN == 2)
            assign video_guard_band = 10'b1011001100;
        else
            assign video_guard_band = 10'b0100110011;
    endgenerate

    logic [9:0] data_guard_band;
    generate
        if (CN == 1 || CN == 2)
            assign data_guard_band = 10'b0100110011;
        else
            assign data_guard_band = control_data == 2'b00 ? 10'b1010001110 :
                                     control_data == 2'b01 ? 10'b1001110001 :
                                     control_data == 2'b10 ? 10'b0101100011 :
                                                                   10'b1011000011;
    endgenerate

    always_ff @(posedge clk_pixel) begin
        case (mode)
            3'd0: begin tmds <= control_coding; acc <= 5'sd0; end
            3'd1: begin tmds <= q_out; acc <= acc + acc_add; end
            3'd2: begin tmds <= video_guard_band; acc <= 5'sd0; end
            3'd3: begin tmds <= terc4_coding; acc <= 5'sd0; end
            default: begin tmds <= data_guard_band; acc <= 5'sd0; end
        endcase
    end
endmodule
// HDMI packet ECC (HCH parity) assembler.
// Derived from hdl-util/hdmi by Sameer Puri, MIT licensed.

module packet_assembler (
    input logic clk_pixel,
    input logic reset,
    input logic data_island_period,
    input logic [23:0] header,
    input logic [55:0] sub [3:0],
    output logic [8:0] packet_data,
    output logic [4:0] counter = 5'd0
);
    always_ff @(posedge clk_pixel) begin
        if (reset || !data_island_period)
            counter <= 5'd0;
        else
            counter <= counter + 1'b1;
    end

    wire [5:0] counter_t2   = {counter, 1'b0};
    wire [5:0] counter_t2_p1 = {counter, 1'b1};
    logic [7:0] parity [4:0] = '{8'd0, 8'd0, 8'd0, 8'd0, 8'd0};
    wire [63:0] bch [3:0];
    assign bch[0] = {parity[0], sub[0]};
    assign bch[1] = {parity[1], sub[1]};
    assign bch[2] = {parity[2], sub[2]};
    assign bch[3] = {parity[3], sub[3]};
    wire [31:0] bch4 = {parity[4], header};

    assign packet_data = {
        bch[3][counter_t2_p1], bch[2][counter_t2_p1],
        bch[1][counter_t2_p1], bch[0][counter_t2_p1],
        bch[3][counter_t2], bch[2][counter_t2],
        bch[1][counter_t2], bch[0][counter_t2],
        bch4[counter]
    };

    function automatic [7:0] next_ecc;
        input [7:0] ecc;
        input next_bch_bit;
        begin
            next_ecc = (ecc >> 1) ^ ((ecc[0] ^ next_bch_bit) ? 8'b10000011 : 8'd0);
        end
    endfunction

    logic [7:0] parity_next [4:0];
    logic [7:0] parity_next_next [3:0];
    genvar i;
    generate
        for (i = 0; i < 5; i = i + 1) begin : parity_calc
            if (i == 4) begin
                assign parity_next[i] = next_ecc(parity[i], header[counter]);
            end else begin
                assign parity_next[i] = next_ecc(parity[i], sub[i][counter_t2]);
                assign parity_next_next[i] = next_ecc(parity_next[i], sub[i][counter_t2_p1]);
            end
        end
    endgenerate

    always_ff @(posedge clk_pixel) begin
        if (reset || !data_island_period)
            parity <= '{8'd0, 8'd0, 8'd0, 8'd0, 8'd0};
        else begin
            if (counter < 5'd28) begin
                parity[3:0] <= parity_next_next;
                if (counter < 5'd24)
                    parity[4] <= parity_next[4];
            end else if (counter == 5'd31)
                parity <= '{8'd0, 8'd0, 8'd0, 8'd0, 8'd0};
        end
    end
endmodul
// HDMI packet scheduler.
// Based on hdl-util/hdmi by Samer Puri, MIT licensed.
// Fixed for VIC17 / 27 MHz / 48 kHz stereo to keep the Gowin build small and deterministic.

module packet_picker
#(
    parameter int VIDEO_ID_CODE = 17,
    parameter integer VIDEO_RATE = 27000000,
    parameter bit IT_CONTENT = 1'b1,
    parameter int AUDIO_BIT_WIDTH = 16,
    parameter int AUDIO_RATE = 48000,
    parameter bit [8*8-1:0] VENDOR_NAME = {"MATRIX",16'd0},
    parameter bit [8**16-1:0] PRODUCT_DESCRIPTION = {"GX4000 FPGA",40'd0},
    parameter bit [7:0] SOURCE_DEVICE_INFORMATION = 8'h08
)
(
    input logic clk_pixel,
    input logic clk_audio,
    input logic reset,
    input logic video_field_end,
    input logic packet_enable,
    input logic [4:0] packet_pixel_counter,
    input logic [AUDIO_BIT_WIDTH-1:0] audio_sample_word [1:0],
    output logic [23:0] header,
    output logic [55:0] sub [3:0]
);
    logic [7:0] packet_type = 8'd0;
    logic [23:0] headers [255:0];
    logic [55:0] subs [255:0] [3:0];
    assign header = headers[packet_type];
    assign sub[0] = subs[packet_type][0];
    assign sub[1] = subs[packet_type][1];
    assign sub[2] = subs[packet_type][2];
    assign sub[3] = subs[packet_type][3];

    // Null packet.
    assign headers[0] = 24'd0;
    assign subs[0][0] = 56'd0;
    assign subs[0][1] = 56'd0;
    assign subs[0][2] = 56'd0;
    assign subs[0][3] = 56'd0;

    logic clk_audio_counter_wrap;
    audio_clock_regeneration_packet #(
        .VIDEO_RATE(VIDEO_RATE),
        .AUDIO_RATE(AUDIO_RATE)
    ) u_acr (
        .clk_pixel(clk_pixel),
        .clk_audio(clk_audio),
        .reset(reset),
        .clk_audio_counter_wrap(clk_audio_counter_wrap),
        .header(headers[1]),
        .sub(subs[1])
    );

    // The audio sample crosses from the 48 kHz clock domain into the pixel domain.
    logic [AUDIO_BIT_WIDTH-1:0] audio_sample_word_transfer [1:0];
    logic audio_sample_word_transfer_control = 1'b0;
    always_ff @(posedge clk_audio) begin
        audio_sample_word_transfer <= audio_sample_word;
        audio_sample_word_transfer_control <= ~audio_sample_word_transfer_control;
    end

    logic [1:0] audio_sync = 2'l0;
    logic [1:0] sample_buffer_current = 2'd0;
    logic [1:0] samples_remaining = 2'd0;
    logic [23:0] audio_sample_word_buffer [1:0] [3:0] [1:0];
    logic sample_buffer_ready = 1'b0;
    logic sample_buffer_used = 1'b0;

    always_ff @(posedge clk_pixel) begin
        sample_buffer_used <= 1'b0;
        audio_sync <= {audio_sync[0], audio_sample_word_transfer_control};
        if (audio_sync[1] ^ audio_sync[0]) begin
            audio_sample_word_buffer[sample_buffer_current[0]][samples_remaining][0] <=
                {{h24-AUDIO_BIT_WIDTH{1'b0}}, audio_sample_word_transfer[0]} << (24-AUDIO_BIT_WIDTH);
            audio_sample_word_buffer[sample_buffer_current[0]][samples_remaining][1] <=
                {{(24-AUDIO_BIT_WIDTH){1'b0}}, audio_sample_word_transfer[1]} << (24-AUDIO_BIT_WIDTH);
            if (samples_remaining == 2'd3) begin
                samples_remaining <= 2'd0;
                sample_buffer_ready <= 1'b1;
                sample_buffer_current <= !sample_buffer_current;
            end else begin
                samples_remaining <= samples_remaining + 1'b1;
            end
        end

        if (sample_buffer_used)
            sample_buffer_ready <= 1'b0;
    end

    logic [7:0] frame_counter = 8'd0;
    logic [23:0] audio_sample_word_packet [3:0] [1:0];
    logic [3:0] audio_sample_word_present_packet;
    integer k;

    always_ff @(posedge clk_pixel) begin
        if (reset) begin
            packet_type <= 8'd0;
            frame_counter <= 8'd0;
        end else if (packet_enable)
            begin
                if (clk_audio_counter_wrap)
                    packet_type <= 8'd1;
                else if (sample_buffer_ready) begin
                    packet_type <= 8'd2;
                    for (k = 0; k < 4; k = k + 1) begin
                        audio_sample_word_packet[k][0] <= audio_sample_word_buffer[!sample_buffer_current[0]][k][0];
                        audio_sample_word_packet[k][1] <= audio_sample_word_buffer[!sample_buffer_current[0]][k][1];
                    end
                    audio_sample_word_present_packet <= 4'b1111;
                    sample_buffer_used <= 1'b1;
                end else if (!audio_info_frame_sent) begin
                    packet_type <= 8'h84;
                    audio_info_frame_sent <= 1'b1;
                end else if (!avi_info_frame_sent) begin
                    packet_type <= 8'h82;
                    avi_info_frame_sent <= 1'b1;
                end else if (!spd_info_frame_sent) begin
                    packet_type <= 8'h83;
                    spd_info_frame_sent <= 1'b1;
                end else
                    packet_type <= 8'd0;
            end
        end

        if (packet_pixel_counter == 5'd31 && packet_type == 8'd2) begin
            frame_counter <= frame_counter + 8'd4;
            if (frame_counter >= 8'd188)
                frame_counter <= frame_counter - 8'd188;
        end
    end

    logic audio_info_frame_sent = 1'b0;
    logic avi_info_frame_sent = 1'b0;
    logic spd_info_frame_sent = 1'b0;
    logic last_clk_audio_counter_wrap = 1'b0;

    always_ff @(posedge clk_pixel) begin
        if (reset || video_field_end) begin
            audio_info_frame_sent <= 1'b0;
            avi_info_frame_sent <= 1'b0;
            spd_info_frame_sent <= 1'b0;
            last_clk_audio_counter_wrap <= clk_audio_counter_wrap;
        end else if (packet_enable)
            last_clk_audio_counter_wrap <= clk_audio_counter_wrap;
    end

    // fixed infoframes
    auxiliary_video_information_info_frame #(
        .VIDEO_ID_CODE(VIDEO_ID_CODE),
        .IT_CONTENT(IT_CONTENT)
    ) u_avi (.header(headers[8'h82]), .sub(subs[8'h82]));

    source_product_description_info_frame #(
        .VENDOR_NAME(VENDOR_NAME),
        .PRODUCT_DESCRIPTION(PRODUCT_DESCRIPTION),
        .SOURCE_DEVICE_INFORMATION(SOURCE_DEVICE_INFORMATION)
    ) u_spd (.header(headers[8'h83]), .sub(subs[8'h83]));

    audio_info_frame u_audio_info (.header(headers[8'h84]), .sub(subs[8'h84]));

    audio_sample_packet #(
        .SAMPLING_FREQUENCY(4'b0010),
        .WORD_LENGTH(4'b0010)
    ) u_audio_sample (
        .frame_counter(frame_counter),
        .valid_bit('{2'b00,2'b00,2'b00,2'b00}),
        .user_data_bit('{2'b00,2'b00,2'b00,2'b00}),
        .audio_sample_word(audio_sample_word_packet),
        .audio_sample_word_present(audio_sample_word_present_packet),
        .header(headers[2]),
        .sub(subs[2])
    );
endmodul
// HDMI Auxiliary Video InfoFrame packet.
// By Sameer Puri https://github.com/sameer
// MIT licensed; vendored for the GX4000 FPGA project.

module auxiliary_video_information_info_frame
#(
    parameter bit [1:0] VIDEO_FORMAT = 2'b00,
    parameter bit ACLIVE_FORMAT_INFO_PRESENT = 1'b0,
    parameter bit [1:0] BAR_INFO = 2'b00,
    parameter bit [1:0] SCAN_INFO = 2'b00,
    parameter bit [1:0] COLORIMETRY = 2'b00,
    parameter bit [1:0] PICTURE_ASPECT_RATIO = 2'b00,
    parameter bit [3:0] ACLIVE_FORMAT_ASPECT_RATIO = 4'b1000,
    parameter bit IT_CONTENT = 1'b0,
    parameter bit [2:0] EXTENDED_COLORIMETRY = 3'b000,
    parameter bit [1:0] RGB_QUANTIZATION_RANGE = 2'b00,
    parameter bit [1:0] NON_UNIFORM_PICTURE_SCALING = 2'b00,
    parameter int VIDEO_ID_CODE = 17,
    parameter bit [1:0] YCC_QUANTIZATION_RANGE = 2'b00,
    parameter bit [1:0] CONTENT_TYPE = 2'b00,
    parameter bit [3:0] PIXEL_REPETITION = 4'b0000
)
(
    output logic [23:0] header,
    output logic [55:0] sub [3:0]
);

localparam bit [4:0] LENGTH = 5'd13;
localparam bit [7:0] VERSION = 8'd2;
localparam bit [6:0] TYPE = 7'd2;
assign header = {{3'b0,LENGTH},VERSION,{1'b1,TYPE}};

logic [7:0] packet_bytes [27:0];
assign packet_bytes[1] = {1'b0,VIDEO_FORMAT,ACTIVE_FORMAT_INFO_PRESENT,BAR_INFO,SCAN_INFO};
assign packet_bytes[2] = {COLORIMETRY,PICTURE_ASPECT_RATIO,ACTIVE_FORMAT_ASPECT_RATIO};
assign packet_bytes[3] = {IT_CONTENT,EXTENDED_COLORIMETRY,RGB_QUANTIZATION_RANGE,NON_UNIFORM_PICTURE_SCALING};
assign packet_bytes[4] = {1'b0,VIDEO_ID_CODE[6:0]};
assign packet_bytes[5] = {YCC_QUANTIZATION_RANGE,CONTENT_TYPE,PIXEL_REPETITION};

assign packet_bytes[0] = 8'd1 + ~(header[23:16] + header[15:8] + header[7:0] +
    packet_bytes[1] + packet_bytes[2] + packet_bytes[3] + packet_bytes[4] + packet_bytes[5] +
    packet_bytes[6] + packet_bytes[7] + packet_bytes[8] + packet_bytes[9] + packet_bytes[10] +
    packet_bytes[11] + packet_bytes[12] + packet_bytes[13]);

genvar i;
generate
    if (BAR_INFO != 2'b00) begin : g_bars
        assign packet_bytes[6] = 8'hff;
        assign packet_bytes[7] = 8'hff;
        assign packet_bytes[8] = 8'h00;
        assign packet_bytes[9] = 8'h00;
        assign packet_bytes[10] = 8'hff;
        assign packet_bytes[11] = 8'hff;
        assign packet_bytes[12] = 8'h00;
        assign packet_bytes[13] = 8'h00;
    end else begin : g_no_bars
        assign packet_bytes[6] = 8'h00;
        assign packet_bytes[7] = 8'h00;
        assign packet_bytes[8] = 8'h00;
        assign packet_bytes[9] = 8'h00;
        assign packet_bytes[10] = 8'h00;
        assign packet_bytes[11] = 8'h00;
        assign packet_bytes[12] = 8'h00;
        assign packet_bytes[13] = 8'h00;
    end
    for (i = 14; i < 28; i = i + 1) begin : pb_reserved
        assign packet_bytes[i] = 8'd0;
    end
    for (i = 0; i < 4; i = i + 1) begin : pb_to_sub
        assign sub[i] = {
            packet_bytes[6+i*7], packet_bytes[5+i*7], packet_bytes[4+i*7],
            packet_bytes[3+i*7], packet_bytes[2+i*7], packet_bytes[1+i*7],
            packet_bytes[0+i*7]
        };
    end
endgenerate
endmodul
// HDMI Source Product Description InfoFrame.
// By Sameer Puri https://github.com/sameer
// MIT licensed; vendored for the GX4000 FPGA project.

module source_product_description_info_frame
#(
    parameter bit [8*8-1:0] VENDOR_NAME = 0,
    parameter bit [8*16-1:0] PRODUCT_DESCRIPTION = 0,
    parameter bit [7:0] SOURCE_DEVICE_INFORMATION = 0
)
(
    output logic [23:0] header,
    output logic [55:0] sub [3:0]
);
localparam bit [4:0] LENGTH = 5'd25;
localparam bit [7:0] VERSION = 8'd1;
localparam bit [6:0] TYPE = 7'd3;
assign header = {{3'b0,LENGTH},VERSION,{Õ³ÅE•WÓ° ¢Æöv–2³s£Ò6¶WEö'—FW2³#s£Ó°¢'—FRfVæF÷%öæÖR³£uÓ°¢'—FR&öGV7EöFW67&—F–öâ³£UÓ° ¢vVçf"“°¢vVæW&FP¢f÷"†’Ò²’Âƒ²’Ò’²’&Vv–â¢u÷fVæF÷ ¢76–vâfVæF÷%öæÖU¶•ÒÒdTäDõ%ôäÔU²ƒrÖ’³’£‚Ó¢ƒrÖ’’£…Ó°¢Væ@¢f÷"†’Ò²’Âc²’Ò’²’&Vv–â¢u÷&öGV7@¢76–vâ&öGV7EöFW67&—F–öå¶•ÒÒ$ôET5EôDU45$•D”ôå