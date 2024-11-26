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
		
 
@cocotb.test()
async def first_test(dut):
    """First cocotb test?"""
    await cocotb.start( generate_clock( dut.clk_in ) )
    
    await reset(dut, dut.rst_in)
    
    await RisingEdge(dut.clk_in)
    
    print("driving data in")
    data_in = 0x0001
    num_bytes_in = 2  # doesn't matter w/ short frame
    await drive_data_in(dut, data_in, num_bytes_in)
    print("data driven in")
    
    await Timer(900, "ns")
    # await FallingEdge(dut.busy_out)
    # print("data sent")
    
    # await Timer(100, "ns")


async def drive_data_in(dut, data_in, num_bytes_in):
    while True:
        await RisingEdge(dut.clk_in)
        if dut.busy_out.value == 0:
            break
    
    dut.data_in.value = data_in
    dut.num_bytes_in.value = num_bytes_in

    dut.trigger_in.value = 1
    
    await ClockCycles(dut.clk_in,1)
    
    dut.data_in.value = 0
    dut.num_bytes_in.value = 0
    dut.trigger_in.value = 0


async def reset(dut, rst_wire):
    rst_wire.value = 1
    await ClockCycles(dut.clk_in,2)
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
    sources = [proj_path / "hdl" / "picc_to_pcd.sv"] #grow/modify this as needed.
    build_test_args = ["-Wall"]#,"COCOTB_RESOLVE_X=ZEROS"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="picc_to_pcd",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="picc_to_pcd",
        test_module="test_picc_to_pcd",
        test_args=run_test_args,
        waves=True
    )
 
if __name__ == "__main__":
    rfid_runner()
