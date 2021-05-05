// Created by fizzim.pl version 5.20 on 2021:03:17 at 13:54:33 (www.fizzim.com)

module cache (
  output logic [4:0] cRowId,
  output logic dummy,
  output logic hold,
  output logic ready,
  input logic RD,
  input logic [16:0] RowId,
  input logic WR,
  input logic clk,
  input logic rst,
  input logic sync
);

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
      Idle      : begin // wait for request from BankFSM
        if (RD || WR) begin
          nextstate = CompareTag;
        end
        else begin
          nextstate = Idle;
        end
      end
      Allocate  : begin // fetch block from memory
        if (sync) begin
          nextstate = CompareTag;
        end
        else if (!sync) begin
          nextstate = Allocate;
        end
      end
      CompareTag: begin // determine hit or miss
        if (hit && RD) begin
          nextstate = hitRD;
        end
        else if (hit && WR) begin
          nextstate = hitWR;
        end
        else if (miss && dirty) begin
          nextstate = WriteBack;
        end
        else if (miss && !dirty) begin
          nextstate = Allocate;
        end
      end
      WriteBack : begin // write data to memory
        if (sync) begin
          nextstate = Allocate;
        end
        else if (!sync) begin
          nextstate = WriteBack;
        end
      end
      hitRD     : begin // data read
        if (!RD) begin
          nextstate = Idle;
        end
        else if (RD) begin
          nextstate = hitRD;
        end
      end
      hitWR     : begin // data write
        if (!WR) begin
          nextstate = Idle;
        end
        else if (WR) begin
          nextstate = hitWR;
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
      cRowId[4:0] <= 5'b0;
      dummy <= 0;
      hold <= 0;
      ready <= 0;
    end
    else begin
      cRowId[4:0] <= 5'b0; // default
      dummy <= 0; // default
      hold <= 0; // default
      ready <= 0; // default
      case (nextstate)
        Idle      : begin
          dummy <= 1;
        end
        Allocate  : begin
          dummy <= 1;
          hold <= 1;
        end
        CompareTag: begin
          cRowId[4:0] <= RowID;
          dummy <= 1;
        end
        WriteBack : begin
          dummy <= 1;
          hold <= 1;
        end
        hitRD     : begin
          cRowId[4:0] <= cRowId;
          dummy <= 1;
          ready <= 1;
        end
        hitWR     : begin
          cRowId[4:0] <= cRowID;
          dummy <= 1;
          ready <= 1;
        end
      endcase
    end
  end
endmodule
