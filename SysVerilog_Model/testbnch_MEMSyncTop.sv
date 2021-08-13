`timescale 1ns / 1ps

`define DDR4
// `define DDR3

module testbnch_MEMSyncTop(
       );
       
       parameter BGWIDTH = 2;
       parameter BAWIDTH = 2;
       parameter CHWIDTH = 6;
       parameter ADDRWIDTH = 17;
       
       localparam BANKGROUPS = 2**BGWIDTH;
       localparam BANKSPERGROUP = 2**BAWIDTH;
       localparam CHROWS = 2**CHWIDTH;
       localparam ROWS = 2**ADDRWIDTH;
       
       localparam tCK = 0.75;
       
       reg clk;
       reg reset_n;
       
       reg [BAWIDTH-1:0]ba; // bank address
       `ifdef DDR4
       reg [BGWIDTH-1:0]bg; // bankgroup address, BG0-BG1 in x4/8 and BG0 in x16
       `endif
       reg [ADDRWIDTH-1:0] RowId [BANKGROUPS-1:0][BANKSPERGROUP-1:0];
       reg [4:0] BankFSM [BANKGROUPS-1:0][BANKSPERGROUP-1:0];
       reg sync [BANKGROUPS-1:0][BANKSPERGROUP-1:0];
       reg [CHWIDTH-1:0] cRowId [BANKGROUPS-1:0][BANKSPERGROUP-1:0];
       reg stall;
       
       MEMSyncTop #(
       .BGWIDTH(BGWIDTH),
       .BAWIDTH(BAWIDTH),
       .CHWIDTH(CHWIDTH),
       .ADDRWIDTH(ADDRWIDTH)
       )
       dut (
       .clk(clk),
       .reset_n(reset_n),
       .ba(ba),
       `ifdef DDR4
       .bg(bg),
       `endif
       .RowId(RowId),
       .BankFSM(BankFSM),
       .sync(sync),
       .cRowId(cRowId),
       .stall(stall)       
       );
       
       always #(tCK*0.5) clk = ~clk;
       
       integer i=0, bgi=0, bi=0; // loop variables
       
       initial
       begin
              // initialize all values
              reset_n = 0;
              clk = 1;
              bg = 0;
              ba = 0;
              for (bgi=0; bgi<BANKGROUPS; bgi=bgi+1) begin
                     for (bi=0; bi<BANKGROUPS; bi=bi+1) begin
                            sync[bgi][bi] = 0;
                            BankFSM[bgi][bi] = 0;
                            RowId[bgi][bi]=0;
                            sync[bgi][bi]=0;
                     end
              end
              #tCK
              
              reset_n = 1;
              #tCK
              
              // write then read
              for (i=0; i<CHROWS; i=i+1) begin
                     BankFSM[bg][ba] = 5'b10010;
                     RowId[bg][ba]=$urandom;
                     #(4*tCK)

                     sync[bg][ba]=1;
                     #tCK;
                     sync[bg][ba]=0;
                     #(3*tCK)
                     
                     BankFSM[bg][ba] = 0;
                     #tCK;
                     
                     BankFSM[bg][ba] = 5'b01011;
                     // RowId=RowId+i;
                     #(3*tCK)
                     
                     BankFSM[bg][ba] = 0;
                     #tCK;
                     $display(i);
              end

              #(4*tCK)
              $stop;
       end;
       
endmodule
