module compare(
  input a,
  input b,
  output out1,
  output out2,
  output out3
);

assign out1 = (a & ~b);
assign out2 = ~(a ^ b);
assign out3 = (~a & b);

endmodule
