"""

Copyright (c) 2020 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

"""

import logging

import cocotb
from cocotb.triggers import RisingEdge
from cocotb.bus import Bus

from cocotbext.axi.memory import Memory


class PsdpRamWrite(Memory):

    _cmd_signals = ["wr_cmd_be", "wr_cmd_addr", "wr_cmd_data", "wr_cmd_valid", "wr_cmd_ready"]

    def __init__(self, entity, name, clock, reset=None, size=1024, mem=None, *args, **kwargs):
        self.log = logging.getLogger(f"cocotb.{entity._name}.{name}")
        self.entity = entity
        self.clock = clock
        self.reset = reset
        self.cmd_bus = Bus(self.entity, name, self._cmd_signals, **kwargs)

        self.log.info("Parallel Simple Dual Port RAM model (write)")
        self.log.info("Copyright (c) 2020 Alex Forencich")

        super().__init__(size, mem, *args, **kwargs)

        self.pause = False
        self._pause_generator = None
        self._pause_cr = None

        self.width = len(self.cmd_bus.wr_cmd_data)
        self.byte_width = len(self.cmd_bus.wr_cmd_be)

        self.seg_count = len(self.cmd_bus.wr_cmd_valid)
        self.seg_data_width = self.width // self.seg_count
        self.seg_byte_width = self.seg_data_width // 8
        self.seg_addr_width = len(self.cmd_bus.wr_cmd_addr) // self.seg_count
        self.seg_be_width = self.seg_data_width // 8

        self.seg_data_mask = 2**self.seg_data_width-1
        self.seg_addr_mask = 2**self.seg_addr_width-1
        self.seg_be_mask = 2**self.seg_be_width-1

        self.log.info("Parallel Simple Dual Port RAM model configuration:")
        self.log.info("  Memory size: %d bytes", len(self.mem))
        self.log.info("  Segment count: %d", self.seg_count)
        self.log.info("  Segment addr width: %d bits", self.seg_addr_width)
        self.log.info("  Segment data width: %d bits (%d bytes)", self.seg_data_width, self.seg_byte_width)
        self.log.info("  Total data width: %d bits (%d bytes)", self.width, self.width // 8)

        assert self.seg_be_width*self.seg_count == len(self.cmd_bus.wr_cmd_be)

        self.cmd_bus.wr_cmd_ready.setimmediatevalue(0)

        cocotb.fork(self._run())

    def set_pause_generator(self, generator=None):
        if self._pause_cr is not None:
            self._pause_cr.kill()
            self._pause_cr = None

        self._pause_generator = generator

        if self._pause_generator is not None:
            self._pause_cr = cocotb.fork(self._run_pause())

    def clear_pause_generator(self):
        self.set_pause_generator(None)

    async def _run(self):
        while True:
            await RisingEdge(self.clock)

            cmd_be_sample = self.cmd_bus.wr_cmd_be.value
            cmd_addr_sample = self.cmd_bus.wr_cmd_addr.value
            cmd_data_sample = self.cmd_bus.wr_cmd_data.value
            cmd_ready_sample = self.cmd_bus.wr_cmd_ready.value
            cmd_valid_sample = self.cmd_bus.wr_cmd_valid.value

            if self.reset is not None and self.reset.value:
                self.cmd_bus.wr_cmd_ready.setimmediatevalue(0)
                continue

            # process segments
            for seg in range(self.seg_count):
                if cmd_ready_sample & cmd_valid_sample & (1 << seg):
                    seg_addr = (cmd_addr_sample >> self.seg_addr_width*seg) & self.seg_addr_mask
                    seg_data = (cmd_data_sample >> self.seg_data_width*seg) & self.seg_data_mask
                    seg_be = (cmd_be_sample >> self.seg_be_width*seg) & self.seg_be_mask

                    addr = (seg_addr*self.seg_count+seg)*self.seg_byte_width

                    self.mem.seek(addr % self.size)

                    data = seg_data.to_bytes(self.seg_byte_width, 'little')

                    for i in range(self.seg_byte_width):
                        if seg_be & (1 << i):
                            self.mem.write(data[i:i+1])
                        else:
                            self.mem.seek(1, 1)

                    self.log.info("Write word seg: %d addr: 0x%08x be 0x%02x data %s",
                        seg, addr, seg_be, ' '.join((f'{c:02x}' for c in data)))

            if self.pause:
                self.cmd_bus.wr_cmd_ready <= 0
            else:
                self.cmd_bus.wr_cmd_ready <= 2**self.seg_count-1

    async def _run_pause(self):
        for val in self._pause_generator:
            self.pause = val
            await RisingEdge(self.clock)


class PsdpRamRead(Memory):

    _cmd_signals = ["rd_cmd_addr", "rd_cmd_valid", "rd_cmd_ready"]
    _resp_signals = ["rd_resp_data", "rd_resp_valid", "rd_resp_ready"]

    def __init__(self, entity, name, clock, reset=None, size=1024, mem=None, *args, **kwargs):
        self.log = logging.getLogger(f"cocotb.{entity._name}.{name}")
        self.entity = entity
        self.clock = clock
        self.reset = reset
        self.cmd_bus = Bus(self.entity, name, self._cmd_signals, **kwargs)
        self.resp_bus = Bus(self.entity, name, self._resp_signals, **kwargs)

        self.log.info("Parallel Simple Dual Port RAM model (read)")
        self.log.info("Copyright (c) 2020 Alex Forencich")

        super().__init__(size, mem, *args, **kwargs)

        self.pause = False
        self._pause_generator = None
        self._pause_cr = None

        self.width = len(self.resp_bus.rd_resp_data)
        self.byte_width = self.width // 8

        self.seg_count = len(self.cmd_bus.rd_cmd_valid)
        self.seg_data_width = self.width // self.seg_count
        self.seg_byte_width = self.seg_data_width // 8
        self.seg_addr_width = len(self.cmd_bus.rd_cmd_addr) // self.seg_count

        self.seg_data_mask = 2**self.seg_data_width-1
        self.seg_addr_mask = 2**self.seg_addr_width-1

        self.log.info("Parallel Simple Dual Port RAM model configuration:")
        self.log.info("  Memory size: %d bytes", len(self.mem))
        self.log.info("  Segment count: %d", self.seg_count)
        self.log.info("  Segment addr width: %d bits", self.seg_addr_width)
        self.log.info("  Segment data width: %d bits (%d bytes)", self.seg_data_width, self.seg_byte_width)
        self.log.info("  Total data width: %d bits (%d bytes)", self.width, self.width // 8)

        self.cmd_bus.rd_cmd_ready.setimmediatevalue(0)
        self.resp_bus.rd_resp_valid.setimmediatevalue(0)

        cocotb.fork(self._run())

    def set_pause_generator(self, generator=None):
        if self._pause_cr is not None:
            self._pause_cr.kill()
            self._pause_cr = None

        self._pause_generator = generator

        if self._pause_generator is not None:
            self._pause_cr = cocotb.fork(self._run_pause())

    def clear_pause_generator(self):
        self.set_pause_generator(None)

    async def _run(self):
        pipeline = [[None for x in range(1)] for seg in range(self.seg_count)]

        cmd_ready = 0
        resp_valid = 0
        resp_data = 0

        while True:
            await RisingEdge(self.clock)

            cmd_addr_sample = self.cmd_bus.rd_cmd_addr.value
            cmd_ready_sample = self.cmd_bus.rd_cmd_ready.value
            cmd_valid_sample = self.cmd_bus.rd_cmd_valid.value

            resp_ready_sample = self.resp_bus.rd_resp_ready.value
            resp_valid_sample = self.resp_bus.rd_resp_valid.value

            if self.reset is not None and self.reset.value:
                self.cmd_bus.rd_cmd_ready.setimmediatevalue(0)
                self.resp_bus.rd_resp_valid.setimmediatevalue(0)
                cmd_ready = 0
                resp_valid = 0
                continue

            # process segments
            for seg in range(self.seg_count):
                seg_mask = 1 << seg

                if (resp_ready_sample & seg_mask) or not (resp_valid_sample & seg_mask):
                    if pipeline[seg][-1] is not None:
                        resp_data &= ~(self.seg_data_mask << self.seg_data_width*seg)
                        resp_data |= ((pipeline[seg][-1] & self.seg_data_mask) << self.seg_data_width*seg)
                        resp_valid |= seg_mask
                        pipeline[seg][-1] = None
                    else:
                        resp_valid &= ~seg_mask

                for i in range(len(pipeline[seg])-1, 0, -1):
                    if pipeline[seg][i] is None:
                        pipeline[i] = pipeline[i-1]
                        pipeline[i-1] = None

                if cmd_ready_sample & cmd_valid_sample & seg_mask:
                    seg_addr = (cmd_addr_sample >> self.seg_addr_width*seg) & self.seg_addr_mask

                    addr = (seg_addr*self.seg_count+seg)*self.seg_byte_width

                    self.mem.seek(addr % self.size)

                    data = self.mem.read(self.seg_byte_width)
                    pipeline[seg][0] = int.from_bytes(data, 'little')

                    self.log.info("Read word seg: %d addr: 0x%08x data %s",
                        seg, addr, ' '.join((f'{c:02x}' for c in data)))

                if (not resp_valid & seg_mask) or None in pipeline[seg]:
                    cmd_ready |= seg_mask
                else:
                    cmd_ready &= ~seg_mask

            if self.pause:
                self.cmd_bus.rd_cmd_ready <= 0
            else:
                self.cmd_bus.rd_cmd_ready <= cmd_ready

            self.resp_bus.rd_resp_data <= resp_data
            self.resp_bus.rd_resp_valid <= resp_valid

    async def _run_pause(self):
        for val in self._pause_generator:
            self.pause = val
            await RisingEdge(self.clock)


class PsdpRam(Memory):
    def __init__(self, entity, name, clock, reset=None, size=1024, mem=None, *args, **kwargs):
        self.write_if = None
        self.read_if = None

        super().__init__(size, mem, *args, **kwargs)

        self.write_if = PsdpRamWrite(entity, name, clock, reset, mem=self.mem)
        self.read_if = PsdpRamRead(entity, name, clock, reset, mem=self.mem)
