`timescale 1ns/1ps
module tb_traffic_light;
    reg clk;
    reg rst;
    reg tick;

    wire ns_g, ns_y, ns_r, ew_g, ew_y, ew_r;

 
    traffic_light dut(
        .clk(clk), .rst(rst), .tick(tick),
        .ns_g(ns_g), .ns_y(ns_y), .ns_r(ns_r),
        .ew_g(ew_g), .ew_y(ew_y), .ew_r(ew_r)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // Reset sequence
    initial begin
        rst = 1;
        tick = 0;
        #50; // 5 clock cycles of reset
        @(posedge clk);
        rst = 0;
    end

    // 1-cycle pulse every 20 clk cycles 
    integer cyc;
    initial cyc = 0;
    always @(posedge clk) begin
        if (rst) begin
            cyc <= 0;
            tick <= 0;
        end else begin
            cyc <= cyc + 1;
            tick <= (cyc % 20 == 0); // 1-cycle pulse
        end
    end

   
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_traffic_light);
        $display("time\tclk\trst\ttick\tstate\tns_g ns_y ns_r\tew_g ew_y ew_r");
        #20000; 
        $finish;
    end

endmodule