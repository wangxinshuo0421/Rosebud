# Copyright (c) 2019 Alex Forencich
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# AXI stream asynchronous FIFO timing constraints

foreach fifo_inst [get_cells -hier -filter {(ORIG_REF_NAME == axis_async_fifo || REF_NAME == axis_async_fifo)}] {
    puts "Inserting timing constraints for axis_async_fifo instance $fifo_inst"

    # get clock periods
    set read_clk [get_clocks -of_objects [get_pins -quiet "$fifo_inst/rd_ptr_reg_reg[*]/C $fifo_inst/rd_ptr_gray_reg_reg[*]/C $fifo_inst/wr_ptr_gray_sync1_reg_reg[*]/C"]]
    set write_clk [get_clocks -of_objects [get_pins -quiet "$fifo_inst/wr_ptr_reg_reg[*]/C $fifo_inst/wr_ptr_gray_reg_reg[*]/C $fifo_inst/rd_ptr_gray_sync1_reg_reg[*]/C"]]

    set read_clk_period [get_property -min PERIOD $read_clk]
    set write_clk_period [get_property -min PERIOD $write_clk]

    set min_clk_period [expr $read_clk_period < $write_clk_period ? $read_clk_period : $write_clk_period]

    # reset synchronization
    set reset_ffs [get_cells -quiet -hier -regexp ".*/s_rst_sync\[23\]_reg_reg" -filter "PARENT == $fifo_inst"]

    if {[llength $reset_ffs]} {
        set_property ASYNC_REG TRUE $reset_ffs

        # hunt down source
        set dest [get_cells -include_replicated_objects $fifo_inst/s_rst_sync2_reg_reg]
        set dest_pins [get_pins -include_replicated_objects -of_objects $dest -filter {REF_PIN_NAME == D}]
        set net [get_nets -segments -of_objects $dest_pins]
        set source_pins [get_pins -include_replicated_objects -of_objects $net -filter {IS_LEAF && DIRECTION == OUT}]
        set source [get_cells -include_replicated_objects -of_objects $source_pins]

        set_max_delay -from $source -to $dest -datapath_only $read_clk_period
    }

    set reset_ffs [get_cells -include_replicated_objects -quiet -hier -regexp ".*/m_rst_sync\[23\]_reg_reg" -filter "PARENT == $fifo_inst"]

    if {[llength $reset_ffs]} {
        set_property ASYNC_REG TRUE $reset_ffs

        # hunt down source
        set dest [get_cells -include_replicated_objects $fifo_inst/m_rst_sync2_reg_reg]
        set dest_pins [get_pins -include_replicated_objects -of_objects $dest -filter {REF_PIN_NAME == D}]
        set net [get_nets -segments -of_objects $dest_pins]
        set source_pins [get_pins -include_replicated_objects -of_objects $net -filter {IS_LEAF && DIRECTION == OUT}]
        set source [get_cells -include_replicated_objects -of_objects $source_pins]

        set_max_delay -from $source -to $dest -datapath_only $write_clk_period
    }

    # pointer synchronization
    set sync_ffs [get_cells -include_replicated_objects -quiet -hier -regexp ".*/rd_ptr_gray_sync\[12\]_reg_reg\\\[\\d+\\\]" -filter "PARENT == $fifo_inst"]

    if {[llength $sync_ffs]} {
        set_property ASYNC_REG TRUE $sync_ffs

        set_max_delay -from [get_cells -include_replicated_objects "$fifo_inst/rd_ptr_reg_reg[*] $fifo_inst/rd_ptr_gray_reg_reg[*]"] -to [get_cells -include_replicated_objects "$fifo_inst/rd_ptr_gray_sync1_reg_reg[*]"] -datapath_only $read_clk_period
        set_bus_skew  -from [get_cells -include_replicated_objects "$fifo_inst/rd_ptr_reg_reg[*] $fifo_inst/rd_ptr_gray_reg_reg[*]"] -to [get_cells -include_replicated_objects "$fifo_inst/rd_ptr_gray_sync1_reg_reg[*]"] $write_clk_period
    }

    set sync_ffs [get_cells -quiet -hier -regexp ".*/wr_ptr_gray_sync\[12\]_reg_reg\\\[\\d+\\\]" -filter "PARENT == $fifo_inst"]

    if {[llength $sync_ffs]} {
        set_property ASYNC_REG TRUE $sync_ffs

        set_max_delay -from [get_cells -include_replicated_objects -quiet "$fifo_inst/wr_ptr_reg_reg[*] $fifo_inst/wr_ptr_gray_reg_reg[*] $fifo_inst/wr_ptr_sync_gray_reg_reg[*]"] -to [get_cells -include_replicated_objects "$fifo_inst/wr_ptr_gray_sync1_reg_reg[*]"] -datapath_only $write_clk_period
        set_bus_skew  -from [get_cells -include_replicated_objects -quiet "$fifo_inst/wr_ptr_reg_reg[*] $fifo_inst/wr_ptr_gray_reg_reg[*] $fifo_inst/wr_ptr_sync_gray_reg_reg[*]"] -to [get_cells -include_replicated_objects "$fifo_inst/wr_ptr_gray_sync1_reg_reg[*]"] $read_clk_period
    }

    # output register (needed for distributed RAM sync write/async read)
    set output_reg_ffs [get_cells -quiet -include_replicated_objects "$fifo_inst/mem_read_data_reg_reg[*]"]

    if {[llength $output_reg_ffs]} {
        set_false_path -from $write_clk -to $output_reg_ffs
    }

    # frame FIFO pointer update synchronization
    set update_ffs [get_cells -include_replicated_objects -quiet -hier -regexp ".*/wr_ptr_update(_ack)?_sync\[123\]_reg_reg" -filter "PARENT == $fifo_inst"]

    if {[llength $update_ffs]} {
        set_property ASYNC_REG TRUE $update_ffs

        set_max_delay -from [get_cells -include_replicated_objects "$fifo_inst/wr_ptr_update_reg_reg"] -to [get_cells -include_replicated_objects "$fifo_inst/wr_ptr_update_sync1_reg_reg"] -datapath_only $write_clk_period
        set_max_delay -from [get_cells -include_replicated_objects "$fifo_inst/wr_ptr_update_sync3_reg_reg"] -to [get_cells -include_replicated_objects "$fifo_inst/wr_ptr_update_ack_sync1_reg_reg"] -datapath_only $read_clk_period
    }

    # status synchronization
    foreach i {overflow bad_frame good_frame} {
        set status_sync_regs [get_cells -include_replicated_objects -quiet -hier -regexp ".*/${i}_sync\[123\]_reg_reg" -filter "PARENT == $fifo_inst"]

        if {[llength $status_sync_regs]} {
            set_property ASYNC_REG TRUE $status_sync_regs

            set_max_delay -from [get_cells -include_replicated_objects "$fifo_inst/${i}_sync1_reg_reg"] -to [get_cells -include_replicated_objects "$fifo_inst/${i}_sync2_reg_reg"] -datapath_only $read_clk_period
        }
    }
}
