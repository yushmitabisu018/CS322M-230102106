module slave_fsm(
    input  wire       clk,
    input  wire       rst, 
    input  wire       req,
    input  wire [7:0] data_in,
    output wire       ack,
    output wire [7:0] last_byte
);

reg ack_r;
reg [7:0] last_byte_r;
reg [1:0] ack_cnt;
reg [1:0] state;

assign ack = ack_r;
assign last_byte = last_byte_r;

localparam WAITREQ = 2'd0;
localparam ASSERT1 = 2'd1; // first ack cycle
localparam ASSERT2 = 2'd2; // second ack cycle
localparam WAITDROP = 2'd3; // wait for req to drop, then release ack

always @(posedge clk) begin
    if (rst) begin
        ack_r <= 1'b0;
        last_byte_r <= 8'd0;
        ack_cnt <= 2'd0;
        state <= WAITREQ;
    end else begin
        case (state)
            WAITREQ: begin
                ack_r <= 1'b0;
                ack_cnt <= 2'd0;
                if (req) begin
                    // latch data on request
                    last_byte_r <= data_in;
                    // start asserting ack for two cycles
                    ack_r <= 1'b1;
                    ack_cnt <= 2'd1;
                    state <= ASSERT2;
                end
            end

            ASSERT2: begin
                // second cycle of ack
                ack_r <= 1'b1;
                ack_cnt <= 2'd2;
                state <= WAITDROP;
            end

            WAITDROP: begin
                // ack remains 1 while waiting for master to drop req
                ack_r <= 1'b1;
                if (!req) begin
                    // master dropped req -> release ack next cycle
                    ack_r <= 1'b0;
                    ack_cnt <= 2'd0;
                    state <= WAITREQ;
                end
            end

            default: state <= WAITREQ;
        endcase
    end
end

endmodule