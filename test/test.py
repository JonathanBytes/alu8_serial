import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, ReadOnly


async def reset_dut(dut):
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 2)
    await FallingEdge(dut.clk)
    dut.rst_n.value = 1


async def shift_16bits(dut, a, b, op, carry_in=0):
    """Shift in 16 bits: 8 bits of A (LSB-first), then 8 bits of B (LSB-first)"""
    op_bits = ((op & 0x7) << 1) | ((carry_in & 0x1) << 4)
    
    # Shift in operand A (8 bits, LSB-first)
    for idx in range(8):
        bit = (a >> idx) & 0x1
        dut.ui_in.value = op_bits | bit
        await ClockCycles(dut.clk, 1)
    
    # Shift in operand B (8 bits, LSB-first)
    for idx in range(8):
        bit = (b >> idx) & 0x1
        dut.ui_in.value = op_bits | bit
        await ClockCycles(dut.clk, 1)

    # Wait for Done signal with timeout
    for _ in range(5):
        if (int(dut.uio_out.value) >> 4) & 0x1:
            break
        await ClockCycles(dut.clk, 1)
    
    await ReadOnly()


@cocotb.test()
async def test_add(dut):
    dut._log.info("TEST: ADD 5 + 3 = 8")
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)
    await shift_16bits(dut, a=5, b=3, op=0, carry_in=0)

    result = int(dut.uo_out.value)
    uio_out = int(dut.uio_out.value)
    done = (uio_out >> 4) & 0x1
    
    dut._log.info(f"Result: {result}, Done: {done}, UIO_OUT: {uio_out:#04x}")
    assert done == 1, f"Done should be high, got {done}"
    assert result == 8, f"Expected 8, got {result}"
    dut._log.info("✓ PASS")


@cocotb.test()
async def test_sub(dut):
    dut._log.info("TEST: SUB 10 - 3 = 7")
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)
    await shift_16bits(dut, a=10, b=3, op=1, carry_in=0)

    result = int(dut.uo_out.value)
    done = (int(dut.uio_out.value) >> 4) & 0x1
    
    dut._log.info(f"Result: {result}, Done: {done}")
    assert done == 1, f"Done should be high, got {done}"
    assert result == 7, f"Expected 7, got {result}"
    dut._log.info("✓ PASS")


@cocotb.test()
async def test_and(dut):
    dut._log.info("TEST: AND 0xFF & 0x0F = 0x0F")
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)
    await shift_16bits(dut, a=0xFF, b=0x0F, op=2, carry_in=0)

    result = int(dut.uo_out.value)
    done = (int(dut.uio_out.value) >> 4) & 0x1
    
    dut._log.info(f"Result: {result:#x}, Done: {done}")
    assert done == 1, f"Done should be high, got {done}"
    assert result == 0x0F, f"Expected 0x0F, got {result:#x}"
    dut._log.info("✓ PASS")


@cocotb.test()
async def test_or(dut):
    dut._log.info("TEST: OR 0xF0 | 0x0F = 0xFF")
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)
    await shift_16bits(dut, a=0xF0, b=0x0F, op=3, carry_in=0)

    result = int(dut.uo_out.value)
    done = (int(dut.uio_out.value) >> 4) & 0x1
    
    dut._log.info(f"Result: {result:#x}, Done: {done}")
    assert done == 1, f"Done should be high, got {done}"
    assert result == 0xFF, f"Expected 0xFF, got {result:#x}"
    dut._log.info("✓ PASS")


@cocotb.test()
async def test_xor(dut):
    dut._log.info("TEST: XOR 0xAA ^ 0x55 = 0xFF")
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)
    await shift_16bits(dut, a=0xAA, b=0x55, op=4, carry_in=0)

    result = int(dut.uo_out.value)
    done = (int(dut.uio_out.value) >> 4) & 0x1
    
    dut._log.info(f"Result: {result:#x}, Done: {done}")
    assert done == 1, f"Done should be high, got {done}"
    assert result == 0xFF, f"Expected 0xFF, got {result:#x}"
    dut._log.info("✓ PASS")


@cocotb.test()
async def test_not(dut):
    dut._log.info("TEST: NOT 0x00 = 0xFF")
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)
    await shift_16bits(dut, a=0x00, b=0xFF, op=5, carry_in=0)  # B doesn't matter for NOT

    result = int(dut.uo_out.value)
    done = (int(dut.uio_out.value) >> 4) & 0x1
    
    dut._log.info(f"Result: {result:#x}, Done: {done}")
    assert done == 1, f"Done should be high, got {done}"
    assert result == 0xFF, f"Expected 0xFF, got {result:#x}"
    dut._log.info("✓ PASS")


@cocotb.test()
async def test_shl(dut):
    dut._log.info("TEST: SHL 0x55 << 1 = 0xAA")
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)
    await shift_16bits(dut, a=0x55, b=0xFF, op=6, carry_in=0)  # B doesn't matter for SHL

    result = int(dut.uo_out.value)
    done = (int(dut.uio_out.value) >> 4) & 0x1
    
    dut._log.info(f"Result: {result:#x}, Done: {done}")
    assert done == 1, f"Done should be high, got {done}"
    assert result == 0xAA, f"Expected 0xAA, got {result:#x}"
    dut._log.info("✓ PASS")


@cocotb.test()
async def test_shr(dut):
    dut._log.info("TEST: SHR 0xAA >> 1 = 0x55")
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)
    await shift_16bits(dut, a=0xAA, b=0xFF, op=7, carry_in=0)  # B doesn't matter for SHR

    result = int(dut.uo_out.value)
    done = (int(dut.uio_out.value) >> 4) & 0x1
    
    dut._log.info(f"Result: {result:#x}, Done: {done}")
    assert done == 1, f"Done should be high, got {done}"
    assert result == 0x55, f"Expected 0x55, got {result:#x}"
    dut._log.info("✓ PASS")
