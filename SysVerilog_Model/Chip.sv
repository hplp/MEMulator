`timescale 1ns / 1ps

// A memory Chip module model that bundles multiple BankGroups.
// Notice that the Chip model interface is nothing like the real DRAM Chip
// interface, which is much narrower, with the addressing logic performed
// inside the Chip. Doing the addressing logic, the state and time management,
// and the data synchronization outside the chip is more efficient in terms
// of resource utilization and allows having the relevant control data all in
// one place while still achieving the goal of slicing and hierarchically
// placing the data.
// * parameter `BGWIDTH` determines the number of Bank Groups, and
//     `BGWIDTH=0` for single Bank Group is achieved with `BGWIDTH=1` and `BANKGROUPS=1`
module Chip
    #(parameter BGWIDTH = 2,
    parameter BANKGROUPS = 2**BGWIDTH, // set to 1 for DDR3 and prior gen
    parameter BAWIDTH = 2,
    parameter COLWIDTH = 10,
    parameter DEVICE_WIDTH = 4,
    parameter CHWIDTH = 5,
    
    localparam BANKSPERGROUP = 2**BAWIDTH,
    localparam COLS = 2**COLWIDTH
    )
    (
    input logic clk,
    // SystemVerilog multi-dimensional arrays allows to easily scale the bundling
    // of inputs. For example, the data of bank 2 and bank group 3 can be read
    // out as dqout[3][2] and setting the row and column value will give the
    // relevant word
    input logic  [0:0]             rd_o_wr [BANKGROUPS-1:0][BANKSPERGROUP-1:0],
    input logic  [DEVICE_WIDTH-1:0]dqin    [BANKGROUPS-1:0][BANKSPERGROUP-1:0],
    output logic [DEVICE_WIDTH-1:0]dqout   [BANKGROUPS-1:0][BANKSPERGROUP-1:0],
    input logic  [CHWIDTH-1:0]     row     [BANKGROUPS-1:0][BANKSPERGROUP-1:0],
    input logic  [COLWIDTH-1:0]    column  [BANKGROUPS-1:0][BANKSPERGROUP-1:0]
    );
    
    // generating bank groups and assigning the corresponding inputs/outputs
    genvar bgi;
    generate
        for (bgi = 0; bgi < BANKGROUPS ; bgi=bgi+1)
        begin:BG
            BankGroup #(.BAWIDTH(BAWIDTH),
            .COLWIDTH(COLWIDTH),
            .DEVICE_WIDTH(DEVICE_WIDTH),
            .CHWIDTH(CHWIDTH)) BGi (
            .clk(clk),
            .rd_o_wr(rd_o_wr[bgi]),
            .dqin(dqin[bgi]),
            .dqout(dqout[bgi]),
            .row(row[bgi]),
            .column(column[bgi])
            );
        end
    endgenerate
    
endmodule
