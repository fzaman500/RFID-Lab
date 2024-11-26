import cocotb
import os
import random
import sys
import logging
from pathlib import Path
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly,with_timeout, First, Join
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner

import numpy as np

import asyncio
 
async def generate_clock(clock_wire):
	while True: # repeat forever
		clock_wire.value = 0
		await Timer(5,units="ns")
		clock_wire.value = 1
		await Timer(5,units="ns")
		
async def generate_clock_picc(clock_wire):
    count = 0
    count_max = 5120
    clock_wire.value = 1
    while True: # repeat forever
        count += 1

        if count == count_max/2:
             clock_wire.value = 0
        if count == count_max:
            clock_wire.value = 1
            count = 0

        await Timer(5,units="ns")

@cocotb.test()
async def first_test(dut):
    """First cocotb test?"""
    await cocotb.start( generate_clock( dut.clk_in ) )
    await cocotb.start( generate_clock_picc( dut.clk_in_picc ) )
    
    await reset(dut, dut.rst_in)
    
    await FallingEdge(dut.clk_in_picc)
    await RisingEdge(dut.clk_in)
    
    print("driving data in")
    await drive_data_in(dut)
    print("data driven in")
    
    await Timer(900000, "ns")
    # await FallingEdge(dut.busy_out)
    # print("data sent")
    
    # await Timer(100, "ns")


async def drive_data_in(dut):
    while True:
        await RisingEdge(dut.clk_in)
        # if dut.busy_out.value == 0:
        break
    
    dut.btn_in.value = 1
    # await ClockCycles(dut.clk_in,1)
    await RisingEdge(dut.clk_in_picc)
    dut.btn_in.value = 0


async def reset(dut, rst_wire):
    rst_wire.value = 1
    await ClockCycles(dut.clk_in,1)
    rst_wire.value = 0


"""the code below should largely remain unchanged in structure, though the specific files and things
specified should get updated for different simulations.
"""
 
def rfid_runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "rfid.sv", proj_path / "hdl" / "picc_to_pcd.sv", proj_path / "hdl" / "sine_generator.sv"] #grow/modify this as needed.
    build_test_args = ["-Wall"]#,"COCOTB_RESOLVE_X=ZEROS"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="rfid",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="rfid",
        test_module="test_rfid",
        test_args=run_test_args,
        waves=True
    )
 
if __name__ == "__main__":
    rfid_runner()
