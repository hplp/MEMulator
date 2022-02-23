`timescale 1ns / 1ps

module testbnch_MEMSync(
);

    parameter CHWIDTH = 6;
    parameter ADDRWIDTH = 17;

    localparam CHROWS = 2**CHWIDTH;
    localparam ROWS = 2**ADDRWIDTH;

    localparam tCK = 0.75;

    logic clk;
    logic rst;

    logic [CHWIDTH-1:0] cRowId;
    logic stall;
    logic ACT;
    logic PR;
    logic RD;
    logic [ADDRWIDTH-1:0] RowId;
    logic WR;
    logic sync;

    MEMSync #(
    .CHWIDTH(CHWIDTH),
    .ADDRWIDTH(ADDRWIDTH)
    )
    dut (
        .cRowId(cRowId),
        .stall(stall),
        .ACT(ACT),
        .RD(RD),
        .PR(PR),
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
        ACT=0;
        PR=0;
        RD=0;
        WR=0;
        RowId=0;
        #tCK;

        rst=0;
        #tCK;

        // repeatedly activate, write, write then read it back
        for (i=0; i<CHROWS; i=i+1) begin
            ACT=1; // activate
            RowId=$urandom; // this row is not in the tag table
            #tCK;
            ACT=0;
            #(2*tCK)
            sync=1; // FSM is in allocate state and will now leave
            #tCK;
            sync=0;
            #(3*tCK)
            assert (dut.state == 3'h2) $display("OK: CompareTag"); else $display(dut.state);

            WR=1; // write
            #(3*tCK)
            assert (dut.state == 3'h6) $display("OK: hitWR"); else $display(dut.state);
            WR=0; // writing completed
            #tCK;

            WR=1; // another write to the same row
            #(3*tCK)
            assert (dut.state == 3'h6) $display("OK: hitWR"); else $display(dut.state);
            WR=0; // this one was a hit
            #tCK;

            RD=1; // read the same row
            #(3*tCK)
            assert (dut.state == 3'h5) $display("OK: hitRD"); else $display(dut.state);
            RD=0; // again, a hit
            RowId=0;
            PR=1; // close row
            #tCK;
            PR=0;
            #tCK;
        end

        // cache should be full now so test WriteBack with WR
        for (i=0; i<16; i=i+1) begin
            ACT=1; // activate
            RowId=$urandom; // this row is not in the tag table
            #tCK;
            ACT=0;
            #(2*tCK) // also, tag table is full and dirty
            sync=1; // to leave WriteBack
            #tCK;
            sync=0;
            #(2*tCK)
            sync=1; // to leave Allocate
            #tCK;
            sync=0;
            #(2*tCK)

            WR=1; // write
            #(3*tCK)
            WR=0; // done writing
            #tCK;
            RD=1; // read same row
            #(3*tCK)
            RD=0; // done reading
            RowId=0;
            PR=1; // close row
            #tCK;
            PR=0;
            #tCK;
        end

        #(4*tCK)
        $finish();
    end;

endmodule
