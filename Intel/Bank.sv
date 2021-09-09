
`timescale 1ns / 1ps

// this Bank module models the basics in terms of structure and data storage of a memory Bank
// parameter DEVICE_WIDTH corresponds with the width of the memory Chip, Bank Group, Bank
//     sets the number of bits addressed by one row-column address location
// parameter COLWIDTH determines the number of columns in one row
// parameter CHWIDTH determines the number of full rows to be modeled
//     the number of full rows modeled will be much smaller than the real number of rows
//     because of the limited BRAM available on the FPGA chip
//     the small number of full rows modeled are then mapped to any rows in use
module Bank
  #(parameter DEVICE_WIDTH = 4,
  parameter COLWIDTH = 10,
  parameter CHWIDTH = 5,
  parameter COLS=2**COLWIDTH,   ///localparam doesn't work here find a better solution later.
  parameter CHROWS= 2**CHWIDTH,
  parameter DEPTH=COLS*CHROWS
  )
  (
  input  wire clk,
  input  wire [0:0] rd_o_wr,
  input  wire [DEVICE_WIDTH-1:0] dqin,
  output wire [DEVICE_WIDTH-1:0] dqout,
  input  wire [CHWIDTH-1:0]      row,
  input  wire [COLWIDTH-1:0] column
  
  // amount of BRAM per Bank as full rows
  
  //localparam COLS = 2**COLWIDTH, // number of columns
  //localparam CHROWS = 2**CHWIDTH, // number of full rows allocated to a Bank model
  //localparam DEPTH = COLS*CHROWS,
  );
  
  Array #(.WIDTH(DEVICE_WIDTH), .DEPTH(DEPTH)) arrayi (
  .clk(clk),
  .addr({row, column}),
  .rd_o_wr(rd_o_wr), // 0->rd, 1->wr
  .i_data(dqin),
  .o_data(dqout)
  );
  
endmodule
