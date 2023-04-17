`default_nettype none

/*Module declaration 

	wire FT_Sim_Start;
	wire FT_Sim_End;
	wire FT_Sim_Proc;
	FT_UartTrigger i_UartTrigger(
	.clock(sys_clk),
	.reset(main_basesoc_reset),
	.tx_payload(main_basesoc_uart_tx_fifo_wrport_dat_w[7:0]),
	.tx_valid(main_basesoc_uart_tx_fifo_wrport_we),
	.sim_start(FT_Sim_Start),
	.sim_end(FT_Sim_End),
	.sim_proc(FT_Sim_Proc)
	);

*/

// Want to trigger start based on "Lift"
// Want to trigger end based on "Welc"


module FT_UartTrigger (
	// -- Common Signals --
	input wire					clock, // module FPGA clock
	input wire					reset, // module reset (global)
	// -- Sync Bus Signals --
	input wire [7:0]			tx_payload, // tx payload data
	input wire 					tx_valid,	// tx valid signal
	// -- Output Signals --
	output reg					sim_start,
	output reg					sim_end,
	output reg					sim_proc
    );


	localparam ar_Len = 8'd04;
	reg [7:0] arS [ar_Len-1:0];
	reg [7:0] arE [ar_Len-1:0];
	reg [7:0] arP [ar_Len-1:0];

	integer i;
	initial begin
		/*
		arS[0] <= 8'h45; //E
		arS[1] <= 8'h6E; //n
		arS[2] <= 8'h6A; //j
		arS[3] <= 8'h6F; //o
		*/

		arS[0] <= 8'h41; //LA
		arS[1] <= 8'h42; //iB
		arS[2] <= 8'h43; //fC
		arS[3] <= 8'h44; //tD


		arE[0] <= 8'h45; //WE
		arE[1] <= 8'h46; //eF
		arE[2] <= 8'h47; //lG
		arE[3] <= 8'h48; //cH

		arP[0] <= 8'h70; //p
		arP[1] <= 8'h72; //r
		arP[2] <= 8'h6F; //o
		arP[3] <= 8'h63; //c
	end

	reg [7:0] countS;
	reg [7:0] countS_c;

	reg [7:0] countE;
	reg [7:0] countE_c;

	reg [7:0] countP;
	reg [7:0] countP_c;

	always @*
	begin
		sim_start <= 1'b0;
		sim_end <= 1'b0;
		sim_proc <= 1'b0;
		countS_c <= countS;
		countE_c <= countE;
		countP_c <= countP;

		// start logic
		if( countS == ar_Len ) begin
			sim_start <= 1'b1;
		end else if( tx_valid ) begin
			if(tx_payload == arS[countS]) begin
				countS_c <= countS + 1;
			end else begin
				countS_c <= 0;
			end
		end

		// end logic
		if( countE == ar_Len ) begin
			sim_end <= 1'b1;
		end else if( tx_valid ) begin
			if(tx_payload == arE[countE]) begin
				countE_c <= countE + 1;
			end else begin
				countE_c <= 0;
			end
		end

		// proc logic
		if( countP == ar_Len ) begin
			sim_proc <= 1'b1;
		end else if( tx_valid ) begin
			if(tx_payload == arP[countP]) begin
				countP_c <= countP + 1;
			end else begin
				countP_c <= 0;
			end
		end
	end


	// clock process
	always @(posedge clock)
	begin
		if( reset) begin
			countS <= 0;
			countE <= 0;
			countP <= 0;
		end else begin
			countS <= countS_c;
			countE <= countE_c;
			countP <= countP_c;
		end
	end


endmodule

`default_nettype wire