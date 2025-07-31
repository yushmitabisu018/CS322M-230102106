module testbench;
  reg a, b;
  wire out1, out2, out3;

  compare uut(
    .a(a),
    .b(b),
    .out1(out1),
    .out2(out2),
    .out3(out3)
  );

  initial begin
      $dumpfile("wave.vcd");     
      $dumpvars; 
    $display("A B | A>B A==B A<B");
    
    a = 0; b = 0; #10 $display("%b %b |  %b     %b     %b", a, b, out1, out2, out3);
    a = 0; b = 1; #10 $display("%b %b |  %b     %b     %b", a, b, out1, out2, out3);
    a = 1; b = 0; #10 $display("%b %b |  %b     %b     %b", a, b, out1, out2, out3);
    a = 1; b = 1; #10 $display("%b %b |  %b     %b     %b", a, b, out1, out2, out3);
    
    $finish;
  end
endmodule
