`timescale 1ns/1ps

module tb_pipeline();
  logic        clk;
  logic        reset;
  logic [31:0] WriteData;
  logic [31:0] DataAdr;
  logic        MemWrite;

  // instantiate top-level wrapper
  top_pipeline dut (
    .clk(clk),
    .reset(reset),
    .WriteData(WriteData),
    .DataAdr(DataAdr),
    .MemWrite(MemWrite)
  );

  // generate VCD and apply reset
  initial begin
    $dumpfile("pipeline_tb.vcd");
    $dumpvars(0, tb_pipeline);
    reset = 1'b1;
    #22;
    reset = 1'b0;
  end

  // free-running 100 MHz-ish clock (10 ns period)
  always begin
    clk = 1'b1; #5;
    clk = 1'b0; #5;
  end

  // monitor data-memory writes to decide pass/fail
  always @(negedge clk) begin
    if (MemWrite) $display("STORE @ %0d = 0x%08h (t=%0t)", DataAdr, WriteData, $time);

    if (MemWrite) begin
      // original test condition: succeed when address==100 and data==25
      if ((DataAdr === 32'd100) && (WriteData === 32'd25)) begin
        $display("Simulation succeeded");
        // print register x28 (checksum) from datapath (GPR)
        $display("CHECKSUM (x28) = %0d (0x%08h)", dut.cpu_core.pipeline_core.GPR[28], dut.cpu_core.pipeline_core.GPR[28]);
        $finish;
      end

      else if (DataAdr !== 32'd96) begin
        $display("Simulation failed (unexpected store)");
        $finish;
      end
    end
  end

endmodule
