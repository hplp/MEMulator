// Created by fizzim.pl version 5.20 on 2021:07:26 at 17:12:21 (www.fizzim.com)

module MEMSync #(
  parameter CHWIDTH = 6,
  parameter ADDRWIDTH = 17,
  
  localparam CHROWS = 2**CHWIDTH,
  localparam ROWS = 2**ADDRWIDTH
  )
  (
  output logic [CHWIDTH-1:0] LRU,
  output logic [CHWIDTH-1:0] cRowId,
  output logic dirty,
  output logic hit,
  output logic load,
  output logic ready,
  output logic stall,
  output logic store,
  input logic RD,
  input logic [ADDRWIDTH-1:0] RowId,
  input logic WR,
  input logic clk,
  input logic rst,
  input logic sync
);

typedef struct packed {
  logic valid;
  logic dirty;
  logic [CHWIDTH-1:0] age; // for LRU
  logic [CHWIDTH-1:0] tag;
  logic [ADDRWIDTH-1:0] rowaddr;
  logic [64-1:0] addr;
} tag_table_type;

tag_table_type tag_tbl [0:CHROWS-1];
genvar idx;
generate
  for (idx=0; idx<CHROWS; idx++) begin
    initial tag_tbl[idx].valid=0;
    initial tag_tbl[idx].dirty=0;
    initial tag_tbl[idx].age=(CHROWS-idx-1);
    initial tag_tbl[idx].tag=idx;
    initial tag_tbl[idx].rowaddr='0;
    initial tag_tbl[idx].addr='0;
  end
endgenerate

  // state bits
  enum logic [2:0] {
    Idle       = 3'b000, 
    Allocate   = 3'b001, 
    CompareTag = 3'b010, 
    WriteBack  = 3'b011, 
    hitRD      = 3'b100, 
    hitWR      = 3'b101
  } state, nextstate;


  // comb always block
  always_comb begin
    nextstate = state; // default to hold value because implied_loopback is set
    case (state)
      Idle      : begin // wait for RD/WR request from BankFSM
        if (RD || WR) begin
          nextstate = CompareTag;
        end
      end
      Allocate  : begin // fetch block from memory
        if (sync) begin
          nextstate = CompareTag;
        end
      end
      CompareTag: begin // determine hit or miss
        if (hit && RD) begin
          nextstate = hitRD;
        end
        else if (hit && WR) begin
          nextstate = hitWR;
        end
        else if (!hit && dirty) begin
          nextstate = WriteBack;
        end
        else if (!hit && !dirty) begin
          nextstate = Allocate;
        end
      end
      WriteBack : begin // write data to memory
        if (sync) begin
          nextstate = Allocate;
        end
      end
      hitRD     : begin // data read
        if (!RD) begin
          nextstate = Idle;
        end
      end
      hitWR     : begin // data write
        if (!WR) begin
          nextstate = Idle;
        end
      end
    endcase
  end

  // Assign reg'd outputs to state bits

  // sequential always block
  always_ff @(posedge clk or posedge rst) begin
    if (rst)
      state <= Idle;
    else
      state <= nextstate;
  end

  // datapath sequential always block
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      LRU[CHWIDTH-1:0] <= 0;
      cRowId[CHWIDTH-1:0] <= 0;
      dirty <= 0;
      hit <= 0;
      load <= 0;
      ready <= 0;
      stall <= 0;
      store <= 0;
    end
    else begin
      // where to allocate? find LRU
      for (int i = 0; i < CHROWS; i++) begin
        if(tag_tbl[i].age>tag_tbl[cRowId].age) begin
          LRU <= tag_tbl[i].tag;
        end
      end
      cRowId <= cRowId; // default
      dirty <= 0; // default
      hit <= 0; // default
      load <= 0; // default
      ready <= 0; // default
      stall <= 0; // default
      store <= 0; // default
      case (nextstate)
        Idle      : begin
          load <= RD;
          store <= WR;
        end
        Allocate  : begin
          cRowId[CHWIDTH-1:0] <= LRU;
          load <= load;
          stall <= 1;
          store <= store;
          tag_tbl[cRowId].valid <= 1;
          tag_tbl[cRowId].rowaddr <= RowId;
          tag_tbl[cRowId].age <= 0;
        end
        CompareTag: begin
          load <= load;
          for (int i = 0; i < CHROWS; i++) begin
            // look for the RowId in the emulation memory cache
            if((RowId == tag_tbl[i].rowaddr) && (tag_tbl[i].valid == 1)) begin
              // this tag_tbl_i rowaddr equals RowId and is valid
              cRowId <= tag_tbl[i].tag; // will focus on this row
              tag_tbl[i].age <= 0; // using -> is Most Recently Used
              hit <= 1;
            end
            // else begin // tag_tbl_i rowaddr =/= RowId or not valid
            // end
          end
          store <= store;
        end
        WriteBack : begin
          load <= load;
          stall <= 1;
          store <= store;
        end
        hitRD     : begin
          ready <= 1;
        end
        hitWR     : begin
          ready <= 1;
          tag_tbl[cRowId].dirty <= 1;
        end
      endcase
    end
  end
endmodule
