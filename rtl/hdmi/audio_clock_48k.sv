module audio_clock_48k (
    input  logic clk_27m,
    input  logic reset,
    output wire clk_audio
);
    logic [31:0] phase = 32'd0;
    wire clk_audio_raw = phase[31];

    always_ff @(posedge clk_27m) begin
        if (reset)
            phase <= 32'd0;
        else
            phase <= phase + 32'd7635497;
    end

    BUFG u_audio_buf (
        .I(clk_audio_raw),
        .O(clk_audio)
    );
endmodule
