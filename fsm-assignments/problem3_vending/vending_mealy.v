module vending_mealy(
    input  wire       clk,
    input  wire       rst,  
    input  wire [1:0] coin,  // 01=5, 10=10, 00=idle 
    output wire       dispense, 
    output wire       chg5     
);

localparam [1:0] S0  = 2'd0;
localparam [1:0] S5  = 2'd1;
localparam [1:0] S10 = 2'd2;
localparam [1:0] S15 = 2'd3;

reg [1:0] state, next_state;
reg dispense_r, chg5_r;

assign dispense = dispense_r;
assign chg5    = chg5_r;

always @(*) begin
   
    next_state  = state;
    dispense_r  = 1'b0;
    chg5_r      = 1'b0;

    case (state)
        S0: begin
            case (coin)
                2'b01: next_state = S5;   // +5
                2'b10: next_state = S10;  // +10
                default: next_state = S0;
            endcase
        end
        S5: begin
            case (coin)
                2'b01: next_state = S10;  // 5+5 = 10
                2'b10: next_state = S15;  // 5+10 = 15
                default: next_state = S5;
            endcase
        end
        S10: begin
            case (coin)
                2'b01: next_state = S15;  // 10+5 = 15
                2'b10: begin              // 10+10 = 20 -> vend
                    next_state  = S0;     // reset total after vend
                    dispense_r  = 1'b1;
                    chg5_r      = 1'b0;
                end
                default: next_state = S10;
            endcase
        end
        S15: begin
            case (coin)
                2'b01: begin              // 15+5 = 20 -> vend
                    next_state  = S0;
                    dispense_r  = 1'b1;
                    chg5_r      = 1'b0;
                end
                2'b10: begin              // 15+10 = 25 -> vend + change(5)
                    next_state  = S0;
                    dispense_r  = 1'b1;
                    chg5_r      = 1'b1;
                end
                default: next_state = S15;
            endcase
        end
        default: begin
            next_state = S0;
        end
    endcase
end

// Synchronous state register with synchronous active-high reset
always @(posedge clk) begin
    if (rst) begin
        state <= S0;
    end else begin
        state <= next_state;
    end
end

endmodule
