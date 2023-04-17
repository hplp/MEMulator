`default_nettype none

/*Module declaration 
	wire [63:0]			wallTime;
	wire [63:0]			emuTime;
	wire [63:0]			simTime;
	wire [63:0]			freezeTime;

	wire isStalled;
	wire isSim;

	FT_Timer #(
	.READ_LATENCY(1),
	.WRITE_LATENCY(1),
	.TINTERVAL(1)
	) i_FTTimer (
	.clock(sys_clk),
	.reset(main_basesoc_reset),
	// -- Control Signals --
	.sim_Start(FT_Sim_Start),
	.sim_End(FT_Sim_End),
	.ext_stall(1'b0), // external stall signal if needed
	// -- bus Signals --
	.busI_write(busI_write),
	.busI_read(busI_read),
	.busI_stall(busI_stall),
	.busD_write(busD_write),
	.busD_read(busD_read),
	.busD_stall(busD_stall),
	// -- state mirrors --
	.isStalled(isStalled),
	.isSim(isSim),
	// -- timer signals --
	.wallTime(wallTime),
	.emuTime(emuTime),
	.simTime(simTime),
	.freezeTime(freezeTime)
	);

*/

// Proposed emulation rules
//
//	simTime
//		- if not stalled and not read and not write, add 1
//		- if not stalled and read, add read latency
//		- if not stalled and write, add write latency
//		- if stalled, add 0
//
//	emuTime
//		- if stalled, add 1 - do not tick sync timer
//		- if not stalled and not sync, add 1, and tick sync
//		- if not stalled and sync, add 3
//

module FT_Timer #(
	parameter READ_LATENCY = 1,
	parameter WRITE_LATENCY = 1,
	parameter TINTERVAL = 1
	)(
	// -- Common Signals --
	input wire					clock, // module FPGA clock
	input wire					reset, // module reset (global)
	// -- Control Signals --
	input wire 					sim_Start,
	input wire 					sim_End,
	input wire					ext_stall, // external stall signal if needed
	// -- bus Signals --
	input wire					busI_write,
	input wire					busI_read,
	input wire					busI_stall,
	input wire					busD_write,
	input wire					busD_read,
	input wire					busD_stall,
	// -- state mirrors --
	output wire					isStalled,
	output wire					isSim,
	// -- timer signals --
	output reg [63:0]			wallTime,	// true fabric clock time
	output reg [63:0]			emuTime,	// estimate fabric clock of FreezeTime
	output reg [63:0]			simTime,	// estimated simulation time of FreezeTime
	output reg [63:0]			freezeTime	// true time which is not spent stalled
    );

	localparam SYNC_COST = 3; // 3 cycles

	// compute the common state signals
	assign isStalled = busD_stall | busI_stall | ext_stall;
	assign isSim = ({sim_Start, sim_End} == 2'b10)? 1'b1 : 1'b0;

	// timer temps
	reg [63:0]			wallTime_C;
	reg [63:0]			emuTime_C;
	reg [63:0]			simTime_C;
	reg [63:0]			freezeTime_C;	

	reg [63:0] 			syncTimer;
	reg [63:0] 			syncTimer_c;
	reg [63:0] 			syncLimit;
	reg [63:0] 			syncLimit_c;

	// state machine for emulation
	always @*
	begin
		// defaults
		wallTime_C <= wallTime;
		emuTime_C <= emuTime;
		simTime_C <= simTime;
		freezeTime_C <= freezeTime;
		syncTimer_c <= syncTimer;
		syncLimit_c <= syncLimit;
	
		// check to see if we are in simulation
		if( isSim ) begin

			// always update the wall time
			wallTime_C <= wallTime + 1;

			// check to see if stall, if not, always update freeze time
			if( ~isStalled ) begin
				freezeTime_C <= freezeTime + 1;
			end // ~isStalled

			// modify sim time based on actions
			casex({isStalled, busI_write|busD_write, busI_read|busD_read})
			3'b1xx: simTime_C <= simTime; // stalled, so don't update anything
			3'b010:	simTime_C <= simTime + WRITE_LATENCY; // write, increment the by write
			3'b001:	simTime_C <= simTime + READ_LATENCY; // read, increment the by read 
			3'b011: simTime_C <= simTime + READ_LATENCY + WRITE_LATENCY; // read and write, increment the by both
			3'b000: simTime_C <= simTime + 1; // normal operation
			default: simTime_C <= simTime; // this case should never be hit
			endcase

			// tick the sync based on stall logic
			if(  ~isStalled ) begin
				if( syncTimer == syncLimit ) begin
					syncLimit_c <= syncLimit + TINTERVAL;
					emuTime_C <= emuTime + SYNC_COST;
				end else begin // not sync limit, so increment both by 1
					syncTimer_c <= syncTimer + 1;
					emuTime_C <= emuTime + 1;
				end
				
			end else begin//~isStalled
				// just increment the emut timer
				emuTime_C <= emuTime + 1;
			end


		end // isSim
		

	end


	// clock process
	always @(posedge clock)
	begin
		if( reset) begin
			wallTime <= 0;
			emuTime <= 0;
			simTime <= 0;
			freezeTime <= 0;
			syncTimer <= 0;
			syncLimit <= 0;
		end else begin
			wallTime <= wallTime_C;
			emuTime <= emuTime_C;
			simTime <= simTime_C;
			freezeTime <= freezeTime_C;
			syncTimer <= syncTimer_c;
			syncLimit <= syncLimit_c;
		end
	end


endmodule

`default_nettype wire