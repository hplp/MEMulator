FILES = WrappedDIMM.sv
IGNORE = -Wno-CASEINCOMPLETE -Wno-PINCONNECTEMPTY -Wno-PINMISSING -Wno-UNUSED -Wno-UNDRIVEN

.PHONY: all clean world

all: VWrappedDIMM

VWrappedDIMM:
	$(info Verilate wrapped memory model...)
	verilator -Wall $(IGNORE) --cc -CFLAGS "-g" --trace WrappedDIMM.sv --exe sim_top.cpp
	cd obj_dir
	make -j -C obj_dir -f VWrappedDIMM.mk VWrappedDIMM

clean:
	rm -rf obj_dir

world: clean all
