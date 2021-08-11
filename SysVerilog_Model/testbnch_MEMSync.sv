`timescale 1ns / 1ps

module testbnch_MEMSync(
       );
       
       parameter CHWIDTH = 6;
       parameter ADDRWIDTH = 17;
       
       localparam CHROWS = 2**CHWIDTH;
       localparam ROWS = 2**ADDRWIDTH;
       
       localparam tCK = 0.75;
       
       reg clk;
       reg rst;
       
       reg [CHWIDTH-1:0] cRowId;
       reg stall;
       reg RD;
       reg [ADDRWIDTH-1:0] RowId;
       reg WR;
       reg sync;
       
       MEMSync #(
       .CHWIDTH(CHWIDTH),
       .ADDRWIDTH(ADDRWIDTH)
       ) 
       dut (
       .cRowId(cRowId),
       .stall(stall),
       .RD(RD),
       .RowId(RowId),
       .WR(WR),
       .clk(clk),
       .rst(rst),
       .sync(sync)
       );
       
       always #(tCK*0.5) clk = ~clk;
       
       integer i=0; // loop variable
       
       initial
       begin
              clk=1;
              rst=1;
              sync=0;
              RD=0;
              WR=0;
              RowId=0;
              #tCK;
              
              rst=0;
              #tCK;
              
              // repeatedly write, write then read it back
              for (i=0; i<CHROWS; i=i+1) begin
                     WR=1;
                     RowId=$urandom;
                     #(3*tCK)
                     
                     sync=1;
                     #tCK;
                     sync=0;
                     #(3*tCK)
                     
                     WR=0;
                     #tCK;

                     WR=1;
                     #(3*tCK)
                     
                     WR=0;
                     #tCK;
                     RD=1;
                     #(3*tCK)
                     RD=0;
                     RowId=0;
                     #tCK;
              end

              // cache may be full now so test WriteBack
              for (i=0; i<8; i=i+1) begin
                     WR=1;
                     RowId=$urandom;
                     #(3*tCK)
                     
                     sync=1;
                     #tCK;
                     sync=0;
                     #(3*tCK)

                     sync=1;
                     #tCK;
                     sync=0;
                     #(3*tCK)
                     
                     WR=0;
                     #tCK;

                     WR=0;
                     #tCK;
                     RD=1;
                     #(3*tCK)
                     RD=0;
                     RowId=0;
                     #tCK;
              end

              // cache may be full now so test WriteBack with RD
              for (i=0; i<8; i=i+1) begin
                     RD=1;
                     RowId=$urandom;
                     #(3*tCK)

                     sync=1;
                     #tCK;
                     sync=0;
                     #(1*tCK)

                     sync=1;
                     #tCK;
                     sync=0;
                     #(3*tCK)

                     RD=0;
                     RowId=0;
                     #tCK;
              end

              #(4*tCK)
              $stop;
       end;
       
endmodule
