module master_fsm(
    input  wire       clk,
    input  wire       rst, 
    input  wire       ack,
    output wire       req,
    output wire [7:0] data,
    output wire       done 
);

reg req_r;
reg [7:0] data_r;
reg done_r;
reg [1:0] byte_idx;
reg [2:0] state;

assign req  = req_r;
assign data = data_r;
assign done = done_r;

localparam S_REQ        = 3'd0;
localparam S_WAIT_ACK_DROP = 3'd1;
localparam S_DONE       = 3'd2;
localparam S_IDLE       = 3'd3;

always @(posedge clk) begin
    if (rst) begin
        req_r   <= 1'b0;
        data_r  <= 8'hA0; 
        done_r  <= 1'b0;
        byte_idx<= 2'd0;
        state   <= S_REQ; 
    end else begin
        // default
        done_r <= 1'b0;

        case (state)
            S_REQ: begin
                req_r <= 1'b1;
                data_r<= 8'hA0 + byte_idx;
                if (ack) begin
                    state <= S_WAIT_ACK_DROP;
                end
            end

            S_WAIT_ACK_DROP: begin
                req_r <= 1'b0;
                if (!ack) begin
                    if (byte_idx == 2'd3) begin
                        state <= S_DONE;
                    end else begin
                        byte_idx <= byte_idx + 1'b1;
                        state <= S_REQ;
                    end
                end
            end

            S_DONE: begin
                done_r <= 1'b1; 
                state <= S_IDLE;
            end

            S_IDLE: begin
                req_r <= 1'b0;
            end

            default: state <= S_REQ;
        endcase
    end
end

endmodule