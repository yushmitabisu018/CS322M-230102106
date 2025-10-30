`timescale 1ns/1ps

// top_pipeline: wrapper that hooks instruction memory, CPU pipeline and data mem
module top_pipeline(
  input  logic        clk,
  input  logic        reset,
  output logic [31:0] WriteData,
  output logic [31:0] DataAdr,
  output logic        MemWrite
);

  // Program counter (drives imem address)
  logic [31:0] pc_word;
  // Instruction fetched from instruction memory
  logic [31:0] instr_fetched;
  // Data memory read-back
  logic [31:0] dmem_readback;

  // Instruction memory (word-aligned)
  imem instr_mem_inst (
    .a(pc_word),
    .rd(instr_fetched)
  );

  // Pipeline core instance
  riscvpipeline cpu_core (
    .clk(clk),
    .reset(reset),
    .PC(pc_word),
    .InstrIF(instr_fetched),
    .MemWrite_out(MemWrite),
    .DataAdr_out(DataAdr),
    .WriteData_out(WriteData),
    .ReadData(dmem_readback)
  );

  // Data memory (behavioral)
  dmem data_mem_inst (
    .clk(clk),
    .reset(reset),
    .we(MemWrite),
    .a(DataAdr),
    .wd(WriteData),
    .rd(dmem_readback)
  );

endmodule

// imem: small instruction memory (word addressed). Loads test hex at start.
module imem(
  input  logic [31:0] a,   // byte address (word-aligned expected)
  output logic [31:0] rd
);

  localparam int WORDS = 64;
  logic [31:0] mem_array [0:WORDS-1];

  initial begin
    $readmemh("tests/rvx10_pipeline.hex", mem_array);
  end

  assign rd = mem_array[a[31:2]];

endmodule

// dmem: simple synchronous write, combinational read behavioral data memory
module dmem(
  input  logic        clk,
  input  logic        reset,
  input  logic        we,
  input  logic [31:0] a,   // byte address (word-aligned expected)
  input  logic [31:0] wd,  // write data
  output logic [31:0] rd   // read data (combinational)
);

  localparam int DEPTH = 64;
  logic [31:0] mem_array [0:DEPTH-1];

  // clear memory at time-0
  initial begin : zero_init
    integer ii;
    for (ii = 0; ii < DEPTH; ii = ii + 1) begin
      mem_array[ii] = 32'd0;
    end
  end

  assign rd = mem_array[a[31:2]];

  // synchronous write on rising clock (respect reset)
  always_ff @(posedge clk) begin
    if (we && !reset) begin
      mem_array[a[31:2]] <= wd;
    end
  end

endmodule

// riscvpipeline: top pipeline module (thin wrapper that instantiates datapath)
module riscvpipeline(
  input  logic        clk,
  input  logic        reset,
  output logic [31:0] PC,
  input  logic [31:0] InstrIF,
  output logic        MemWrite_out,
  output logic [31:0] DataAdr_out,
  output logic [31:0] WriteData_out,
  input  logic [31:0] ReadData
);

  datapath pipeline_core (
    .clk(clk),
    .reset(reset),
    .PC(PC),
    .InstrIF(InstrIF),
    .MemWrite_out(MemWrite_out),
    .DataAdr_out(DataAdr_out),
    .WriteData_out(WriteData_out),
    .ReadData(ReadData)
  );

endmodule
