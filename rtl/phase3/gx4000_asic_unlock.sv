module gx4000_asic_unlock (
    input  logic       clk16,
    input  logic       rst_n,
    input  logic       bc_access,
    input  logic [7:0] data,
    output logic       unlocked,
    output logic [4:0] sequence_state
);
    // Arnold V 2.11: synchronize with non-zero then zero, then
    // FF,77,B3,51,A8,D4,62,39,9C,46,2B,15,8A,CD,EE.
    logic [7:0] previous_data;
    logic       synced;
    logic [3:0] index;

    function automatic [7:0] seq_byte(input logic [3:0] i);
        begin
            case (i)
                4'd0:  seq_byte = 8'hFF;
                4'd1:  seq_byte = 8'h77;
                4'd2:  seq_byte = 8'hB3;
                4'd3:  seq_byte = 8'h51;
                4'd4:  seq_byte = 8'hA8;
                4'd5:  seq_byte = 8'hD4;
                4'd6:  seq_byte = 8'h62;
                4'd7:  seq_byte = 8'h39;
                4'd8:  seq_byte = 8'h9C;
                4'd9:  seq_byte = 8'h46;
                4'd10: seq_byte = 8'h2B;
                4'd11: seq_byte = 8'h15;
                4'd12: seq_byte = 8'h8A;
                4'd13: seq_byte = 8'hCD;
                4'd14: seq_byte = 8'hEE;
                default: seq_byte = 8'h00;
            endcase
        end
    endfunction

    assign sequence_state = {synced, index};

    always_ff @(posedge clk16 or negedge rst_n) begin
        if (!rst_n) begin
            previous_data <= 8'h00;
            synced <= 1'b0;
            index <= 4'd0;
            unlocked <= 1'b0;
        end else if (bc_access) begin
            // A fresh non-zero -> zero pair always resynchronizes the lock detector.
            if ((previous_data != 8'h00) && (data == 8'h00)) begin
                synced <= 1'b1;
                index <= 4'd0;
            end else if (synced) begin
                if (data == seq_byte(index)) begin
                    if (index == 4'd13) begin
                        // Repeating the sequence only through CD locks an already
                        // unlocked ASIC. A following EE immediately opens it again.
                        if (unlocked)
                            unlocked <= 1'b0;
                        index <= 4'd14;
                    end else if (index == 4'd14) begin
                        unlocked <= 1'b1;
                        synced <= 1'b0;
                        index <= 4'd0;
                    end else begin
                        index <= index + 4'd1;
                    end
                end else begin
                    // Keep the CD terminal state meaningful: if EE is omitted the
                    // device remains locked. Any unrelated byte ends the attempt.
                    synced <= 1'b0;
                    index <= 4'd0;
                end
            end
            previous_data <= data;
        end
    end
endmodule
