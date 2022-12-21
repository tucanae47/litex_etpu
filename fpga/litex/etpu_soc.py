#!/usr/bin/env python3

#
# This file is part of LiteX.
#
# Copyright (c) 2015-2020 Florent Kermarrec <florent@enjoy-digital.fr>
# Copyright (c) 2020 Antmicro <www.antmicro.com>
# Copyright (c) 2017 Pierre-Olivier Vauboin <po@lambdaconcept>
# SPDX-License-Identifier: BSD-2-Clause

import sys
import argparse

from migen import *


from litex_boards.platforms import radiona_ulx3s

from litex.build.lattice.trellis import trellis_args, trellis_argdict

from litex.soc.cores.clock import *

from litex.build.generic_platform import *
from litex.build.sim import SimPlatform
from litex.build.sim.config import SimConfig
from litex.build.sim.verilator import verilator_build_args, verilator_build_argdict

from litex.soc.integration.common import *
from litex.soc.integration.soc_core import *
from litex.soc.integration.builder import *
from litex.soc.integration.soc import *
from litex.soc.cores.bitbang import *
from litex.soc.cores.gpio import GPIOTristate
from litex.soc.cores.cpu import CPUS

from litex.soc.cores.uart import UARTWishboneBridge, UART, RS232PHY, UARTPHY
from litescope import LiteScopeAnalyzer

##############

from migen.genlib.resetsync import AsyncResetSynchronizer

from litex.soc.cores.led import LedChaser
from litex.soc.cores.gpio import GPIOOut

from litex.soc.interconnect import *
from litex.soc.integration.soc import SoCRegion
##############

# IOs ----------------------------------------------------------------------------------------------

_io_serial = [

    # Serial
    ("serial", 0,
        Subsignal("tx", Pins("L4"), IOStandard("LVCMOS33")),
        Subsignal("rx", Pins("M1"), IOStandard("LVCMOS33"))
    )
]

class _CRG(Module):
    def __init__(self, platform, sys_clk_freq):
        self.rst = Signal()
        self.clock_domains.cd_sys    = ClockDomain()

        # # #

        # Clk / Rst
        clk25 = platform.request("clk25")
        rst   = platform.request("rst")

        # PLL
        self.submodules.pll = pll = ECP5PLL()
        self.comb += pll.reset.eq(rst | self.rst)
        pll.register_clkin(clk25, 25e6)
        pll.create_clkout(self.cd_sys, sys_clk_freq)

        # Prevent ESP32 from resetting FPGA
        self.comb += platform.request("wifi_gpio0").eq(1)

# Simulation SoC -----------------------------------------------------------------------------------

class ETPUSoc(SoCMini):

    def __init__(self,
        platform,
        with_analyzer         = False,
        with_led_chaser       = False,
        with_gpio             = False,
        with_wfg              = False,
        sim_debug             = False,
        trace_reset_on        = False,
        sys_clk_freq          = int(10e6),
        simulate              = False,
        device                = "LFE5U-85F",
        revision              = "2.0",
        toolchain             = "trellis",
        **kwargs):

        self.submodules.crg = _CRG(platform, sys_clk_freq)

        SoCMini.__init__(self, platform, sys_clk_freq,
            ident          = "Minisoc on ULX3S",
            **kwargs)

        self.submodules.leds = LedChaser(
            pads         = platform.request_all("user_led"),
            sys_clk_freq = sys_clk_freq)

        # uart_ports = platform.request("serial")
        # self.add_uartbone(name="serial", clk_freq=sys_clk_freq, baudrate=115200)
        # bridge = UARTWishboneBridge(uart_ports, sys_clk_freq, baudrate=115200)
        # self.submodules.bridge = bridge
        # self.add_wb_master(bridge.wishbone)

def main():
    from litex.soc.integration.soc import LiteXSoCArgumentParser
    parser = LiteXSoCArgumentParser(description="LiteX SoC Simulation utility")
    add_args(parser)
    
    trellis_args(parser)
    args = parser.parse_args()

    soc_kwargs             = soc_core_argdict(args)
    builder_kwargs         = builder_argdict(args)
    verilator_build_kwargs = verilator_build_argdict(args)
    trellis_build_kwargs   = trellis_argdict(args) if args.toolchain == "trellis" else {}
    
    sys_clk_freq = int(float(args.sys_clk_freq))
    
    if args.simulate:
        sim_config   = SimConfig()
        sim_config.add_clocker("sys_clk", freq_hz=sys_clk_freq)

    # Configuration --------------------------------------------------------------------------------

    cpu = CPUS.get(soc_kwargs.get("cpu_type", "vexriscv"))

    soc_kwargs["with_uart"]=True
    soc_kwargs["uart_baudrate"]=9600
    soc_kwargs["uart_name"]="serial"
    soc_kwargs["with_timer"]=True

    # ROM.
    if args.rom_init:
        soc_kwargs["integrated_rom_init"] = get_mem_data(args.rom_init, endianness=cpu.endianness)

    device                = "LFE5U-85F"
    revision              = "2.0"
    toolchain             = "trellis"
    platform = radiona_ulx3s.Platform(device=device, revision=revision, toolchain=toolchain)
    #wrong TODO for serial
    platform.add_extension(_io_serial)
    # SoC ------------------------------------------------------------------------------------------
    soc = ETPUSoc(
        platform,
        with_gpio          = args.with_gpio,
        sim_debug          = args.sim_debug,
        trace_reset_on     = int(float(args.trace_start)) > 0 or int(float(args.trace_end)) > 0,
        sys_clk_freq       = sys_clk_freq,
        simulate           = args.simulate,
        **soc_kwargs)

    builder_kwargs["csr_csv"] = "csr.csv"
    builder_kwargs["compile_software"] = True # TODO this is needed for the libraries
    builder = Builder(soc, **builder_kwargs)
    
    builder.build()


if __name__ == "__main__":
    main()

