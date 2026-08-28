module cart_diag_engine #(
    parameter integer CLOCK_HZ = 27_000_000
) (
    input  logic        clk,
    input  logic        rst_n,
    output logic        read_start,
    output logic [4:0]  read_page,
    output logic [13:0] read_offset,
    input  logic        read_busy,
    input  logic        read_done,
    input  logic [7:0]  read_data,
    output logic        uart_valid,
    output logic [7:0]  uart_data,
    input  logic        uart_ready,
    output logic        complete
);
    typedef enum logic [3:0] {S_DELAY,S_START_READ,S_WAIT_READ,S_SEND_HI,S_WAIT_HI,S_SEND_LO,S_WAIT_LO,S_SEND_SPACE,S_WAIT_SPACE,S_SEND_CR,S_WAIT_CR,S_SEND_LF,S_WAIT_LF,S_NEXT,S_DONE} state_t;
    state_t state;
    logic [31:0] delay_count;
    logic [7:0] byte_value;
    logic [7:0] index;

    function automatic [7:0] hex_ascii(input logic [3:0] n);
        if (n < 10) hex_ascii = "0" + n;
        else        hex_ascii = "A" + (n - 10);
    endfunction

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state<=S_DELAY; delay_count<=0; byte_value<=0; index<=0; read_start<=0; read_page<=0; read_offset<=0; uart_valid<=0; uart_data<=0; complete<=0;
        end else begin
            read_start<=0; uart_valid<=0;
            case (state)
                S_DELAY: if (delay_count >= CLOCK_HZ/10) begin delay_count<=0; state<=S_START_READ; end else delay_count<=delay_count+1'b1;
                S_START_READ: if (!read_busy) begin read_page<=0; read_offset<={6'd0,index}; read_start<=1; state<=S_WAIT_READ; end
                S_WAIT_READ: if (read_done) begin byte_value<=read_data; state<=S_SEND_HI; end
                S_SEND_HI: if (uart_ready) begin uart_data<=hex_ascii(byte_value[7:4]); uart_valid<=1; state<=S_WAIT_HI; end
                S_WAIT_HI: if (uart_ready) state<=S_SEND_LO;
                S_SEND_LO: if (uart_ready) begin uart_data<=hex_ascii(byte_value[3:0]); uart_valid<=1; state<=S_WAIT_LO; end
                S_WAIT_LO: if (uart_ready) state <= (index[3:0]==4'hF) ? S_SEND_CR : S_SEND_SPACE;
                S_SEND_SPACE: if (uart_ready) begin uart_data<=" "; uart_valid<=1; state<=S_WAIT_SPACE; end
                S_WAIT_SPACE: if (uart_ready) state<=S_NEXT;
                S_SEND_CR: if (uart_ready) begin uart_data<=8'h0D; uart_valid<=1; state<=S_WAIT_CR; end
                S_WAIT_CR: if (uart_ready) state<=S_SEND_LF;
                S_SEND_LF: if (uart_ready) begin uart_data<=8'h0A; uart_valid<=1; state<=S_WAIT_LF; end
                S_WAIT_LF: if (uart_ready) state<=S_NEXT;
                S_NEXT: if (index==8'hFF) begin complete<=1; state<=S_DONE; end else begin index<=index+1'b1; state<=S_START_READ; end
                S_DONE: complete<=1;
                default: state<=S_DELAY;
            endcase
        end
    end
endmodule
