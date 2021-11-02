import math
from migen import *
from migen.fhdl import verilog


# Create migen wrapper for DIMM.sv
class WrappedDIMM(Module):
    def __init__(self):
        RANKS = 1
        CHIPS = 16
        BGWIDTH = 2
        BAWIDTH = 2
        ADDRWIDTH = 17
        COLWIDTH = 10
        DEVICE_WIDTH = 4
        BL = 8
        CHWIDTH = 5

        BANKGROUPS = 2**BGWIDTH
        BANKSPERGROUP = 2**BAWIDTH
        DQWIDTH = DEVICE_WIDTH*CHIPS

        self.act_n = Signal()
        self.addr = Signal(ADDRWIDTH)
        self.bg = Signal(BGWIDTH)
        self.ba = Signal(BAWIDTH)
        self.ck2x = Signal()
        self.ck_c = Signal()
        self.ck_t = Signal()
        self.reset_n = Signal()
        self.cke = Signal()
        self.cs_n = Signal(RANKS)
        self.dq = Signal(DEVICE_WIDTH*CHIPS)
        self.dqs_c = Signal(CHIPS)
        self.dqs_t = Signal(CHIPS)
        self.odt = Signal()
        self.parity = Signal()
        # self.cachesync = Signal(BANKGROUPS*BANKSPERGROUP)
        self.stall = Signal()

        self.io = {self.act_n, self.addr, self.bg, self.ba,
                   self.ck2x, self.ck_c, self.ck_t, self.reset_n, self.cke, self.cs_n,
                   self.dq, self.dqs_c, self.dqs_t, self.odt, self.parity, # self.cachesync,
                   self.stall}

        DIMMi = Instance("DIMM", name="WrappedDIMMi",
                        p_RANKS=RANKS,
                        p_CHIPS=CHIPS,
                        p_BGWIDTH=BGWIDTH,
                        p_BAWIDTH=BAWIDTH,
                        p_ADDRWIDTH=ADDRWIDTH,
                        p_COLWIDTH=COLWIDTH,
                        p_DEVICE_WIDTH=DEVICE_WIDTH,
                        p_DQWIDTH=DQWIDTH,
                        p_BL=BL,
                        p_CHWIDTH=CHWIDTH,

                        i_act_n=self.act_n,
                        i_A=self.addr,
                        i_bg=self.bg,
                        i_ba=self.ba,
                        i_ck2x=self.ck2x,
                        i_ck_c=self.ck_c,
                        i_ck_t=self.ck_t,
                        i_cke=self.cke,
                        i_cs_n=self.cs_n,
                        i_reset_n=self.reset_n,

                        io_dq=self.dq,
                        io_dqs_c=self.dqs_c,
                        io_dqs_t=self.dqs_t,

                        i_odt=self.odt,
                        i_parity=self.parity,
                        # i_sync=self.cachesync,
                        o_stall=self.stall
                        )

        self.specials += DIMMi


def test_instance_module():
    WD = WrappedDIMM()
    verilog.convert(WD, WD.io, name="WrappedDIMM").write("WrappedDIMM.sv")


if __name__ == "__main__":
    test_instance_module()
