module equality(
  input [3:0] a, b,
 output out
);

assign out = (a^b)?0:1;

endmodule