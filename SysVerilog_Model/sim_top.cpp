// Simulation file modified after the example from https://github.com/johnwinans/IceStick-Examples
// by Sergiu Mosanu, UVA-HPLP
//
//**************************************************************************
//
//    Copyright (C) 2020  John Winans
//
//    This library is free software; you can redistribute it and/or
//    modify it under the terms of the GNU Lesser General Public
//    License as published by the Free Software Foundation; either
//    version 2.1 of the License, or (at your option) any later version.
//
//    This library is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//    Lesser General Public License for more details.
//
//    You should have received a copy of the GNU Lesser General Public
//    License along with this library; if not, write to the Free Software
//    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301
//    USA
//
//**************************************************************************


#include <unistd.h>
#include <getopt.h>

#include <verilated.h>          // Defines common routines
#include <verilated_vcd_c.h>
#include <iostream>             // Need std::cout
#include <iomanip>
#include <string>
#include <ctype.h>
#include <iostream>
#include <fstream>

#include "VWrappedDIMM.h"

using namespace std;

static VWrappedDIMM *ptop;                      // Instantiation of module

static vluint64_t main_time = 0;       // Current simulation time
static VerilatedVcdC* tfp = 0;

#define PERIOD  (5)

/**
* Called by $time in Verilog
****************************************************************************/
double sc_time_stamp ()
{
    return main_time;       // converts to double, to match
                            // what SystemC does
}

/**
****************************************************************************/
static void tick(int count)
{
    for (;count > 0; --count)
    {
        //if (tfp)
            //tfp->dump(main_time); // dump traces (inputs stable before outputs change)
        ptop->eval();            // Evaluate model
        main_time++;            // Time passes...
        if (tfp)
            tfp->dump(main_time);   // inputs and outputs all updated at same time
    }
}

/**
****************************************************************************/
static void run(uint64_t limit)
{
    uint64_t count = 0;

    while(count < limit)
    {
        ptop->ck2x = 1;
        tick(PERIOD);
        ptop->ck2x = 0;
        tick(PERIOD);

        ++count;
    }
}

/**
****************************************************************************/
static void reset()
{
	// this module has nothing to reset
}

/**
****************************************************************************/
int main(int argc, char** argv)
{
    Verilated::commandArgs(argc, argv);
    ptop = new VWrappedDIMM;             // Create instance

    int verbose = 0;

    int opt;
    while ((opt = getopt(argc, argv, "tv:")) != -1)
    {
        switch (opt)
        {
        case 'v':
            verbose=atoi(optarg);
            break;
        case 't':
            // init trace dump
            Verilated::traceEverOn(true);
            tfp = new VerilatedVcdC;
            ptop->trace(tfp, 99);
            tfp->open("wave.vcd");
            break;
        }
    }

    // start things going
    reset();
    run(10);

    if (tfp)
        tfp->close();

    ptop->final();               // Done simulating

    if (tfp)
        delete tfp;

    delete ptop;

	return 0;
}
