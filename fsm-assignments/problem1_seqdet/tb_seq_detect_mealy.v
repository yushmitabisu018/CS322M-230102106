`timescale 1ns/1ps
module tb_seq_detect_mealy;
    reg clk, rst, din;
    wire y;
    integer i;
    integer cycle;

    reg [10:0] stream;

    seq_detect_mealy uut (
        .clk(clk),
        .rst(rst),
        .din(din),
        .y(y)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Cycle counter
    always @(posedge clk) cycle = cycle + 1;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_seq_detect_mealy);

        
        cycle = 0;
        din = 0;
        rst = 1;
       
        repeat (3) @(posedge clk);
       
        @(posedge clk);
        rst = 0;
        @(posedge clk);

        stream = 11'b11011011101;

        $display("Cycle din y   (bit_idx 0-based into stream)");
       
        for (i = 0; i < 11; i = i + 1) begin
            @(posedge clk);
            din = stream[10 - i];
            #1; // let combinational y settle
            $display("%4d   %b   %b", i, din, y);
        end

        // stop after some cycles
        @(posedge clk); din = 0;
        @(posedge clk);
        $finish;
    end
endmodule
