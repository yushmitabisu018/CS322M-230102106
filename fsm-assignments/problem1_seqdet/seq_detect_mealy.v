module seq_detect_mealy(
    input  wire clk,
    input  wire rst, 
    input  wire din,
    output wire y  
);

    // State encoding
    localparam S0 = 2'b00;
    localparam S1 = 2'b01;
    localparam S2 = 2'b10;
    localparam S3 = 2'b11;

    reg [1:0] state, next_state;
    reg       y_reg;

    // Combinational next-state + Mealy output logic
    always @(*) begin
        
        next_state = state;
        y_reg = 1'b0;

        case (state)
            S0: begin
                if (din) next_state = S1;
                else     next_state = S0;
            end
            S1: begin
                if (din) next_state = S2;
                else     next_state = S0;
            end
            S2: begin
                if (din) begin
                    next_state = S2;
                end else begin
                    next_state = S3;
                end
            end
            S3: begin
                if (din) begin
                    y_reg = 1'b1;   
                    next_state = S1;
                end else begin
                    next_state = S0;
                end
            end
            default: begin
                next_state = S0;
                y_reg = 1'b0;
            end
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            state <= S0;
        end else begin
            state <= next_state;
        end
    end

    assign y = y_reg;

endmodule
