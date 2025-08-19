`timescale 1ns/1ps
module tb_vending_mealy;

reg clk, rst;
reg [1:0] coin;
wire dispense, chg5;

vending_mealy dut(
    .clk(clk),
    .rst(rst),
    .coin(coin),
    .dispense(dispense),
    .chg5(chg5)
);

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_vending_mealy);
end


task put5;
begin
    coin = 2'b01;
    @(posedge clk); 
    coin = 2'b00;
    #1; 
end
endtask

task put10;
begin
    coin = 2'b10;
    @(posedge clk);
    coin = 2'b00;
    #1;
end
endtask

always @(posedge clk) begin
    $display("%0t : coin=%b state=%0d dispense=%b chg5=%b",
        $time, coin, dut.state, dispense, chg5);
end

// Test sequence
initial begin
    
    coin = 2'b00;
    rst  = 1'b1;
    repeat (2) @(posedge clk); // apply synchronous reset for 2 posedges
    rst = 1'b0;

    put10;      
    put5;          
    put5;           
    put10;          
    put10;     
    put5;     
    put10;      
    put10; 

    repeat (2) @(posedge clk);
    $display("Test complete");
    $finish;
end

endmodule
