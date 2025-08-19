module traffic_light(
    input wire clk,
    input wire rst, 
    input wire tick, 
    output reg ns_g, ns_y, ns_r,
    output reg ew_g, ew_y, ew_r
);

    // State encoding (2 bits)
    localparam S_NS_G = 2'b00;
    localparam S_NS_Y = 2'b01;
    localparam S_EW_G = 2'b10;
    localparam S_EW_Y = 2'b11;

    // Phase durations in TICKS
    localparam integer DUR_NS_G = 5;
    localparam integer DUR_NS_Y = 2;
    localparam integer DUR_EW_G = 5;
    localparam integer DUR_EW_Y = 2;

    reg [1:0] state, next_state;
    
    reg [3:0] phase_cnt; // counts ticks inside a phase

    // State register
    always @(posedge clk) begin
        if (rst) begin
            state <= S_NS_G;
            phase_cnt <= 0;
        end else begin
            if (tick) begin
                if (state == S_NS_G) begin
                    if (phase_cnt == DUR_NS_G - 1) begin
                        state <= S_NS_Y;
                        phase_cnt <= 0;
                    end else begin
                        phase_cnt <= phase_cnt + 1;
                    end
                end else if (state == S_NS_Y) begin
                    if (phase_cnt == DUR_NS_Y - 1) begin
                        state <= S_EW_G;
                        phase_cnt <= 0;
                    end else begin
                        phase_cnt <= phase_cnt + 1;
                    end
                end else if (state == S_EW_G) begin
                    if (phase_cnt == DUR_EW_G - 1) begin
                        state <= S_EW_Y;
                        phase_cnt <= 0;
                    end else begin
                        phase_cnt <= phase_cnt + 1;
                    end
                end else begin // S_EW_Y
                    if (phase_cnt == DUR_EW_Y - 1) begin
                        state <= S_NS_G;
                        phase_cnt <= 0;
                    end else begin
                        phase_cnt <= phase_cnt + 1;
                    end
                end
            end
        end
    end

    // Moore outputs
    always @(*) begin
        // default all 0
        ns_g = 0; ns_y = 0; ns_r = 0;
        ew_g = 0; ew_y = 0; ew_r = 0;

        case (state)
            S_NS_G: begin
                ns_g = 1; ns_y = 0; ns_r = 0;
                ew_g = 0; ew_y = 0; ew_r = 1;
            end
            S_NS_Y: begin
                ns_g = 0; ns_y = 1; ns_r = 0;
                ew_g = 0; ew_y = 0; ew_r = 1;
            end
            S_EW_G: begin
                ns_g = 0; ns_y = 0; ns_r = 1;
                ew_g = 1; ew_y = 0; ew_r = 0;
            end
            S_EW_Y: begin
                ns_g = 0; ns_y = 0; ns_r = 1;
                ew_g = 0; ew_y = 1; ew_r = 0;
            end
            default: begin
                ns_g = 0; ns_y = 0; ns_r = 1;
                ew_g = 0; ew_y = 0; ew_r = 1;
            end
        endcase
    end

endmodule