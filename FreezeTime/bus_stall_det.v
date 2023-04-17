`default_nettype none

/*Module declaration 
	wire busI_write;
	wire busI_read;
	wire busI_stall;
	wire busD_write;
	wire busD_read;
	wire busD_stall;
 FT_BusStallDet i_stallDetI(
	.clock(sys_clk),
	.reset(main_basesoc_reset),
	// -- Bus Signals --
	.wb_bus_cyc(main_basesoc_ibus_cyc), // bus cyc signal
	.wb_bus_stb(main_basesoc_ibus_stb), // bus stb signal
	.wb_bus_ack(main_basesoc_ibus_ack), // bus ack signal
	.wb_bus_we(main_basesoc_ibus_we),  // bus we signal
	// -- Output Signals --
	.bus_write(busI_write),
	.bus_read(busI_read),
	.bus_stall(busI_stall)
	);

 FT_BusStallDet i_stallDetD(
	.clock(sys_clk),
	.reset(main_basesoc_reset),
	// -- Bus Signals --
	.wb_bus_cyc(main_basesoc_dbus_cyc), // bus cyc signal
	.wb_bus_stb(main_basesoc_dbus_stb), // bus stb signal
	.wb_bus_ack(main_basesoc_dbus_ack), // bus ack signal
	.wb_bus_we(main_basesoc_dbus_we),  // bus we signal
	// -- Output Signals --
	.bus_write(busD_write),
	.bus_read(busD_read),
	.bus_stall(busD_stall)
	);

*/



module FT_BusStallDet (
	// -- Common Signals --
	input wire					clock, // module FPGA clock
	input wire					reset, // module reset (global)
	// -- Bus Signals --
	input wire 					wb_bus_cyc, // bus cyc signal
	input wire 					wb_bus_stb, // bus stb signal
	input wire 					wb_bus_ack, // bus ack signal
	input wire					wb_bus_we,  // bus we signal
	// -- Output Signals --
	output wire					bus_write,
	output wire					bus_read,
	output wire					bus_stall
    );


	// hold on to the last cyc and stb states
	reg last_cyc;
	reg last_stb;

	assign bus_write = wb_bus_cyc & wb_bus_stb & wb_bus_we;
	assign bus_read = wb_bus_cyc & wb_bus_stb & (~wb_bus_we);

	assign bus_stall = last_cyc & last_stb & (~wb_bus_ack);

	// clock process
	always @(posedge clock)
	begin
		if( reset) begin
			last_cyc <= 0;
			last_stb <= 0;
		end else begin
			if( ~bus_stall ) begin
				last_cyc <= wb_bus_cyc & (~wb_bus_ack);
				last_stb <= wb_bus_stb & (~wb_bus_ack);
			end
		end
	end


endmodule

`default_nettype wire