module gx4000_input_matrix (
    input  logic [3:0] row_select,
    input  logic [6:0] joy0_n,
    input  logic [6:0] joy1_n,
    output logic [7:0] matrix_data
);
    always_comb begin
        matrix_data = 8'hFF;
        case (row_select)
            4'd6: matrix_data = {1'b1, joy1_n[6], joy1_n[5], joy1_n[4], joy1_n[3], joy1_n[2], joy1_n[1], joy1_n[0]};
            4'd9: matrix_data = {1'b1, joy0_n[6], joy0_n[5], joy0_n[4], joy0_n[3], joy0_n[2], joy0_n[1], joy0_n[0]};
            default: matrix_data = 8'hFF;
        endcase
    end
endmodule
