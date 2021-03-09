import math
from migen import *
from migen.fhdl import verilog


# Create migen wrapper for sram.sv
class dimmW(Module):
    def __init__(self):
        RANKS = 1
        CHIPS = 16
        BGWIDTH = 2
        BAWIDTH = 2
        ADDRWIDTH = 17
        COLWIDTH = 10
        # // x4, x8, x16 -> DQ width = Device_Width x BankGroups (Chips)
        DEVICE_WIDTH = 4
        BL = 8  # // Burst Length
        CHWIDTH = 5  # // Emulation Memory Cache Width

        BANKGROUPS = 2**BGWIDTH
        BANKSPERGROUP = 2**BAWIDTH

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
        self.cachesync = Signal(BANKGROUPS*BANKSPERGROUP)

        self.io = {self.act_n, self.addr, self.bg, self.ba,
                   self.ck2x, self.ck_c, self.ck_t, self.reset_n, self.cke, self.cs_n,
                   self.dq, self.dqs_c, self.dqs_t, self.odt, self.parity, self.cachesync}

        dimm = Instance("dimm",
                        p_RANKS=RANKS,
                        p_CHIPS=CHIPS,
                        p_BGWIDTH=BGWIDTH,
                        p_BAWIDTH=BAWIDTH,
                        p_ADDRWIDTH=ADDRWIDTH,
                        p_COLWIDTH=COLWIDTH,
                        p_DEVICE_WIDTH=DEVICE_WIDTH,
                        p_BL=BL,
                        p_CHWIDTH=CHWIDTH,

                        i_act_n=self.act_n,
                        i_A=self.addr,
                        i_bg=self.bg,
                        i_ba=self.ba,
                        i_ck2x=self.ck2x,
                        i_ck_c=self.ck_c,
                        i_ck_t=self.ck_t,
                        i_reset_n=self.reset_n,
                        i_cke=self.cke,
                        i_cs_n=self.cs_n,

                        io_dq=self.dq,
                        io_dqs_c=self.dqs_c,
                        io_dqs_t=self.dqs_t,

                        i_odt=self.odt,
                        i_parity=self.parity,
                        i_sync=self.cachesync)

        self.specials += dimm


def test_instance_module():
    dimm0 = dimmW()
    verilog.convert(dimm0, dimm0.io, name="dimmW").write("dimmW.sv")


if __name__ == "__main__":
    test_instance_module()
