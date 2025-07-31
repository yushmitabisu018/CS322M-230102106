module testbench;
  reg [3:0] a, b;
  wire out;

  equality uut (
    .a(a),
    .b(b),
    .out(out)
  );

  initial begin
     $dumpfile("wave.vcd");     
    $dumpvars; 
    $display(" A   B  | Equal?");
    
    a = 4'b0000; b = 4'b0000; #10 $display("%b %b |   %b", a, b, out);
    a = 4'b1010; b = 4'b1010; #10 $display("%b %b |   %b", a, b, out);
    a = 4'b1111; b = 4'b0000; #10 $display("%b %b |   %b", a, b, out);
    a = 4'b0011; b = 4'b0110; #10 $display("%b %b |   %b", a, b, out);
    a = 4'b1001; b = 4'b1001; #10 $display("%b %b |   %b", a, b, out);

    $finish;
  end
endmodule
