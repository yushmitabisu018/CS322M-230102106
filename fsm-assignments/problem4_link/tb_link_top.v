`timescale 1ns/1ps
module tb_link_top;

reg clk;
reg rst;
wire done;

link_top dut(.clk(clk), .rst(rst), .done(done));

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_link_top);
end

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin
    rst = 1;
    #20;
    rst = 0;

    $display("TIME  REQ ACK DATA LAST_BYTE DONE");
    $monitor("%0t  %b   %b  %02h   %02h       %b", $time,
             dut.master_inst.req,
             dut.slave_inst.ack,
             dut.master_inst.data,
             dut.slave_inst.last_byte,
             dut.done);

   
    wait (done == 1);
    #20;
    $display("Burst complete at time %0t", $time);
    $finish;
end

endmodule