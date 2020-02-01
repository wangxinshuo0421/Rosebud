module riscvcore #(
  parameter DATA_WIDTH      = 64,
  parameter ADDR_WIDTH      = 16,
  parameter BC_START_ADDR   = 16'h7000,
  parameter BC_REGION_SIZE  = 4048,
  parameter MSG_ADDR_WIDTH  = $clog2(BC_REGION_SIZE)-2,
  parameter CORE_ID_WIDTH   = 4,
  parameter STRB_WIDTH      = DATA_WIDTH/8,
  parameter LINE_ADDR_BITS  = $clog2(STRB_WIDTH),
  parameter IMEM_ADDR_WIDTH = 16,
  parameter DMEM_ADDR_WIDTH = 21,
  parameter SLOT_COUNT      = 8,
  parameter SLOT_WIDTH      = $clog2(SLOT_COUNT+1)
)(
    input                        clk,
    input                        rst,
    input                        init_rst,
    input  [CORE_ID_WIDTH-1:0]   core_id,
    
    output                       ext_dmem_en,
    output                       ext_dmem_wen,
    output [STRB_WIDTH-1:0]      ext_dmem_strb,
    output [ADDR_WIDTH-1:0]      ext_dmem_addr,
    output [DATA_WIDTH-1:0]      ext_dmem_wr_data,
    input  [DATA_WIDTH-1:0]      ext_dmem_rd_data,
    input                        ext_dmem_rd_valid,

    output                       ext_imem_ren,
    output [ADDR_WIDTH-1:0]      ext_imem_addr,
    input  [DATA_WIDTH-1:0]      ext_imem_rd_data,

    input  [63:0]                in_desc,
    input                        in_desc_valid,
    output                       in_desc_taken,

    input  [4:0]                 recv_dram_tag,
    input                        recv_dram_tag_valid,

    output [63:0]                data_desc,
    output                       data_desc_valid,
    output [63:0]                dram_wr_addr,
    input                        data_desc_ready,

    output [SLOT_WIDTH-1:0]      slot_wr_ptr, 
    output [ADDR_WIDTH-1:0]      slot_wr_addr,
    output                       slot_wr_valid,
    output                       slot_for_hdr,
    input                        slot_wr_ready,

    output [31:0]                core_msg_data,
    output [MSG_ADDR_WIDTH-1:0]  core_msg_addr,
    output [3:0]                 core_msg_strb,
    output                       core_msg_valid,
    input                        core_msg_ready,

    input                        interrupt_in,
    output                       interrupt_in_ack
);


// Core to memory signals
wire [31:0] imem_read_data, dmem_wr_data, dmem_read_data; 
wire [31:0] imem_addr, dmem_addr;
wire [4:0]  dmem_word_write_mask;
wire [1:0]  dmem_byte_count;
wire        dmem_v, dmem_wr_en, imem_v;

reg [7:0]  mask_r;
reg        imem_read_ready;
reg        imem_access_err, dmem_access_err;
reg        io_access_data_err, io_byte_access_err;
reg        timer_interrupt;
reg        io_ren_r;
wire       dram_recv_any;

VexRiscv core (
      .clk(clk),
      .reset(rst),

      .iBus_cmd_valid(imem_v),
      .iBus_cmd_ready(1'b1),
      .iBus_cmd_payload_pc(imem_addr),
      .iBus_rsp_valid(imem_read_ready),
      .iBus_rsp_payload_error(imem_access_err && mask_r[0]),
      .iBus_rsp_payload_inst(imem_read_data),

      .dBus_cmd_valid(dmem_v),
      .dBus_cmd_ready(1'b1),
      .dBus_cmd_payload_wr(dmem_wr_en),
      .dBus_cmd_payload_address(dmem_addr),
      .dBus_cmd_payload_data(dmem_wr_data),
      .dBus_cmd_payload_size(dmem_byte_count),
      .dBus_rsp_ready(ext_dmem_rd_valid || io_ren_r),
      .dBus_rsp_error((dmem_access_err && mask_r[1])    || 
                      (io_access_data_err && mask_r[2]) || 
                      (io_byte_access_err && mask_r[3])),
      .dBus_rsp_data(dmem_read_data),
      
      .timerInterrupt(timer_interrupt && mask_r[5]), 
      .externalInterrupt((interrupt_in && mask_r[4])  || 
                         (dram_recv_any && mask_r[6]) || 
                         (in_desc_valid && mask_r[7])),
      .softwareInterrupt(1'b0)
);

///////////////////////////////////////////////////////////////////////////
///////////////////////////// IO WRITES ///////////////////////////////////
///////////////////////////////////////////////////////////////////////////

localparam SEND_DESC_ADDR = 4'b0000;//???;
localparam WR_DRAM_ADDR   = 4'b0001;//???;
localparam SLOT_LUT_ADDR  = 5'b00100;//??;
localparam TIMER_STP_ADDR = 5'b00101;//??;

localparam DRAM_FLAG_ADDR = 5'b00110;//??;
localparam DEBUG_REG_ADDR = 5'b00111;//??;
// localparam RESERVED_8  = 4'b0100;//???;
// localparam RESERVED_8  = 4'b0101;//???;
// localparam RESERVED_8  = 4'b0110;//???;

localparam SEND_DESC_STRB = 7'b0111000;//;
localparam RD_DESC_STRB   = 7'b0111001;//;
localparam DRAM_FLAG_RST  = 7'b0111010;//;
localparam SLOT_LUT_STRB  = 7'b0111011;//;
localparam MASK_WR        = 7'b0111100;//;
localparam INTERRUPT_ACK  = 7'b0111101;//;
// localparam RESERVED_1  = 7'b0111110;//;
// localparam RESERVED_1  = 7'b0111111;//;

localparam IO_BYTE_ACCESS = 4'b0111;//??;
localparam IO_WRITE_ADDRS = 1'b0;//??????;

wire io_not_mem = dmem_addr[ADDR_WIDTH-1] && !dmem_addr[ADDR_WIDTH-2];
wire io_write = io_not_mem && dmem_v && dmem_wr_en; 

wire data_desc_wen  = io_write && (dmem_addr[6:3]==SEND_DESC_ADDR);
wire dram_addr_wen  = io_write && (dmem_addr[6:3]==WR_DRAM_ADDR);
wire slot_info_wen  = io_write && (dmem_addr[6:2]==SLOT_LUT_ADDR);
wire timer_step_wen = io_write && (dmem_addr[6:2]==TIMER_STP_ADDR);
wire dram_flags_wen = io_write && (dmem_addr[6:2]==DRAM_FLAG_ADDR);
wire debug_reg_wen  = io_write && (dmem_addr[6:2]==DEBUG_REG_ADDR);

wire send_data_desc = io_write && (dmem_addr[6:0]==SEND_DESC_STRB);
wire rd_desc_done   = io_write && (dmem_addr[6:0]==RD_DESC_STRB);
wire dram_flag_rst  = io_write && (dmem_addr[6:0]==DRAM_FLAG_RST);
wire slot_wen       = io_write && (dmem_addr[6:0]==SLOT_LUT_STRB);
wire mask_write     = io_write && (dmem_addr[6:0]==MASK_WR);
wire interrupt_ack  = io_write && (dmem_addr[6:0]==INTERRUPT_ACK);

reg [63:0] dram_wr_addr_r;
reg [31:0] timer_step_r;
reg [31:0] debug_reg;

reg [63:0] data_desc_data_r;
reg [31:0] slot_info_data_r;
reg data_desc_v_r;

assign dram_wr_addr = dram_wr_addr_r;
// Byte writable data_desc
wire [7:0]  wr_desc_mask = {4'd0, dmem_word_write_mask[3:0]} << {dmem_addr[2], 2'd0};
wire [63:0] wr_desc_din  = {dmem_wr_data, dmem_wr_data}; //replicate the data

// byte output is replicated on all 4 locations, so first bit is correct no matter
// LSB of address
wire strb_asserted = dmem_wr_data[0]; 

integer i;
always @ (posedge clk) begin
    if (data_desc_wen)
        for (i = 0; i < 8; i = i + 1) 
            if (wr_desc_mask[i] == 1'b1) 
                data_desc_data_r[i*8 +: 8] <= wr_desc_din[i*8 +: 8];

    if (dram_addr_wen)
        for (i = 0; i < 8; i = i + 1) 
            if (wr_desc_mask[i] == 1'b1) 
                dram_wr_addr_r[i*8 +: 8] <= wr_desc_din[i*8 +: 8];

    if (slot_info_wen)
        for (i = 0; i < 4; i = i + 1) 
            if (wr_desc_mask[i] == 1'b1) 
                slot_info_data_r[i*8 +: 8] <= wr_desc_din[i*8 +: 8];

    if (rst) // if user does not set it there would be an interrupt next cycle
      timer_step_r <= 32'h00000001;
    else if (timer_step_wen)
        for (i = 4; i < 8; i = i + 1) 
            if (wr_desc_mask[i] == 1'b1) 
                timer_step_r[(i-4)*8 +: 8] <= wr_desc_din[i*8 +: 8];
    
    if (debug_reg_wen)
        for (i = 4; i < 8; i = i + 1) 
            if (wr_desc_mask[i] == 1'b1) 
                debug_reg[(i-4)*8 +: 8] <= wr_desc_din[i*8 +: 8];

    if (rst) // Timer, dram recv and incoming packet interrupts are blocked, erros are allowed.
      mask_r <= 8'h1F;
    else if(mask_write && wr_desc_mask[4])
      mask_r <= wr_desc_din[39:32];

end

always @ (posedge clk) begin
    if (rst) 
            data_desc_v_r <= 1'b0;
    else begin
        if (send_data_desc && strb_asserted)
            data_desc_v_r <= 1'b1;
        if (data_desc_v_r && data_desc_ready)
            data_desc_v_r <= 1'b0;
    end
end

assign slot_wr_addr    = slot_info_data_r[ADDR_WIDTH-1:0]; 
assign slot_wr_ptr     = slot_info_data_r[24+:SLOT_WIDTH];
assign slot_wr_valid   = slot_wen && strb_asserted;
assign slot_for_hdr    = slot_info_data_r[31];

assign data_desc       = data_desc_data_r;
assign data_desc_valid = data_desc_v_r;

///////////////////////////////////////////////////////////////////////////
////////////////////////////// IO READS ///////////////////////////////////
///////////////////////////////////////////////////////////////////////////

localparam RD_DESC_ADDR     = 4'b1000;//???;
localparam RD_D_FLAGS_ADDR  = 5'b10010;//??;
localparam RD_STAT_ADDR     = 5'b10011;//??;
localparam RD_ID_ADDR       = 5'b10100;//??;
localparam RD_TIMER_L_ADDR  = 5'b10101;//??;
localparam RD_TIMER_H_ADDR  = 5'b10110;//??;
localparam RD_INT_F_ADDR    = 5'b10111;//??;
localparam RD_ACT_SLOT_ADDR = 5'b11000;//??

// localparam RESERVED_4    = 5'b11001;//??;
// localparam RESERVED_8    = 4'b1101;//???;
// localparam RESERVED_16   = 3'b111;//????;

localparam IO_READ_ADDRS    = 1'b1;//??????;
localparam IO_SPACE         = 64 + 36; 

wire io_read  = io_not_mem && dmem_v && (!dmem_wr_en);

wire in_desc_ren    = io_read  && (dmem_addr[6:3]==RD_DESC_ADDR);
wire dram_flags_ren = io_read  && (dmem_addr[6:2]==RD_D_FLAGS_ADDR);
wire stat_ren       = io_read  && (dmem_addr[6:2]==RD_STAT_ADDR);
wire id_ren         = io_read  && (dmem_addr[6:2]==RD_ID_ADDR);
wire timer_l_ren    = io_read  && (dmem_addr[6:2]==RD_TIMER_L_ADDR);
wire timer_h_ren    = io_read  && (dmem_addr[6:2]==RD_TIMER_H_ADDR);
wire int_flags_ren  = io_read  && (dmem_addr[6:2]==RD_INT_F_ADDR);
wire act_slots_ren  = io_read  && (dmem_addr[6:2]==RD_ACT_SLOT_ADDR);

reg [31:0]         io_read_data;
reg [63:0]         internal_timer;
reg [31:0]         dram_recv_flag;
reg [SLOT_COUNT:1] slots_in_prog;

always @ (posedge clk)
    if (rst)
        io_ren_r <= 1'b0;
    else
        io_ren_r <= io_read; 

always @ (posedge clk) begin
    if (in_desc_ren && in_desc_valid)
        if (dmem_addr[2])
            io_read_data    <= in_desc[63:32];
        else
            io_read_data    <= in_desc[31:0];
 
    if (dram_flags_ren)
        io_read_data <= dram_recv_flag;

    if (stat_ren)
        io_read_data <= {7'd0,core_msg_ready, 7'd0,slot_wr_ready,
                         7'd0,data_desc_ready, 7'd0,in_desc_valid};

    if (id_ren)
        io_read_data <= {{(32-CORE_ID_WIDTH){1'b0}},core_id};
 
    if (timer_l_ren)
        io_read_data <= internal_timer[31:0];
    if (timer_h_ren)
        io_read_data <= internal_timer[63:32];

    if (int_flags_ren)
        io_read_data <= {16'd0, mask_r, 
                         in_desc_valid, dram_recv_any, 
                         timer_interrupt, interrupt_in, 
                         io_byte_access_err, io_access_data_err,
                         dmem_access_err, imem_access_err};
    
    if (act_slots_ren)
        io_read_data <= {{(32-SLOT_COUNT){1'b0}}, slots_in_prog};

end

assign in_desc_taken = rd_desc_done && strb_asserted;

///////////////////////////////////////////////////////////////////////////
//////////////////////// INTERNAL 32-BIT TIMER ////////////////////////////
///////////////////////////////////////////////////////////////////////////
always @ (posedge clk)
  if (init_rst)
    internal_timer <= 64'd0;
  else
    internal_timer <= internal_timer + 64'd1;

reg [31:0] interrupt_time;

always @ (posedge clk)
  if (rst || timer_step_wen) begin
    interrupt_time  <= 32'd0;
    timer_interrupt <= 1'b0;
  end else if (interrupt_time == timer_step_r) begin
    interrupt_time  <= 32'd0;
    timer_interrupt <= 1'b1;
  end else begin
    interrupt_time  <= interrupt_time + 32'd1;
    if (interrupt_ack && wr_desc_din[13])
      timer_interrupt <= 1'b0;
  end

///////////////////////////////////////////////////////////////////////////
/////////////////////////// DRAM RECV FLAGS ///////////////////////////////
///////////////////////////////////////////////////////////////////////////
reg [4:0]  recv_dram_tag_r;
reg        recv_dram_tag_valid_r;

// Register the input to improve timing 
always @ (posedge clk) begin
  recv_dram_tag_r         <= recv_dram_tag;
  recv_dram_tag_valid_r   <= recv_dram_tag_valid;
  if (rst)
    recv_dram_tag_valid_r <= 1'b0;
end

always @ (posedge clk)
  if (rst)
    dram_recv_flag <= 32'd0;
  else begin
    if (dram_flags_wen)
        for (i = 0; i < 4; i = i + 1) 
            if (wr_desc_mask[i] == 1'b1) 
                dram_recv_flag[i*8 +: 8] <= wr_desc_din[i*8 +: 8];
    
    if (dram_flag_rst)
      dram_recv_flag[wr_desc_din[20:16]] <= 1'b0;

    // Incoming dram recv has higher priority than core reset on same bit
    if (recv_dram_tag_valid_r)
      dram_recv_flag[recv_dram_tag_r] <= 1'b1;

    dram_recv_flag[0] <= 1'b0; // synthesizer will hardwire it
  end

assign dram_recv_any = | dram_recv_flag;

///////////////////////////////////////////////////////////////////////////
//////////////////////// ACTIVE SLOTS STATE/// ////////////////////////////
///////////////////////////////////////////////////////////////////////////
wire done_w_slot = ((data_desc[63:60] == 4'd0) ||
                    (data_desc[63:60] == 4'd1) ||
                    (data_desc[63:60] == 4'd2));

always @ (posedge clk)
    if (init_rst)
        slots_in_prog <= {SLOT_COUNT{1'b0}};
    else if (in_desc_valid && in_desc_taken)
        slots_in_prog[in_desc[16+:SLOT_WIDTH]]   <= 1'b1;
    else if (done_w_slot && data_desc_valid && data_desc_ready)
        slots_in_prog[data_desc[16+:SLOT_WIDTH]] <= 1'b0;

// TODO: Add error catching

///////////////////////////////////////////////////////////////////////////
/////////////////////// WORD LENGTH ADJUSTMENT ////////////////////////////
///////////////////////////////////////////////////////////////////////////
wire [DATA_WIDTH-1:0] imem_data_out;
wire [DATA_WIDTH-1:0] dmem_data_in, dmem_data_out; 
wire [STRB_WIDTH-1:0] dmem_line_write_mask;

// Conversion from core dmem_byte_count to normal byte mask
assign dmem_word_write_mask = ((!dmem_wr_en) || (!dmem_v)) ? 5'h0 : 
								     			 	  (dmem_byte_count == 2'd0) ? (5'h01 << dmem_addr[1:0]) :
                              (dmem_byte_count == 2'd1) ? (5'h03 << dmem_addr[1:0]) :
                              5'h0f;

if (STRB_WIDTH==4) begin: same_width_dmem
    assign dmem_read_data = io_ren_r ? io_read_data : dmem_data_out;
    assign dmem_line_write_mask = dmem_word_write_mask[3:0];
    assign dmem_data_in   = dmem_wr_data;
end else begin: width_convert_dmem
    wire [DATA_WIDTH-1:0] dmem_data_out_shifted; 
    reg  [LINE_ADDR_BITS-3:0] dmem_latched_addr;
    localparam REMAINED_BYTES = STRB_WIDTH-4;
    localparam REMAINED_BITS  = 8*REMAINED_BYTES;

    always @ (posedge clk)
      if (dmem_v)
        dmem_latched_addr <= dmem_addr[LINE_ADDR_BITS-1:2];

    assign dmem_data_out_shifted = dmem_data_out >> {dmem_latched_addr, 5'd0};
    assign dmem_read_data = io_ren_r ? io_read_data : dmem_data_out_shifted[31:0];
    assign dmem_line_write_mask = 
                         {{REMAINED_BYTES{1'b0}}, dmem_word_write_mask[3:0]} 
                         << {dmem_addr[LINE_ADDR_BITS-1:2], 2'd0};
    assign dmem_data_in =  
                         {{REMAINED_BITS{1'b0}}, dmem_wr_data} 
                         << {dmem_addr[LINE_ADDR_BITS-1:2], 5'd0};
end

if (STRB_WIDTH==4) begin: same_width_imem
    assign imem_read_data = imem_data_out;
end else begin: width_convert_imem
    wire [DATA_WIDTH-1:0] imem_data_out_shifted;
    reg [LINE_ADDR_BITS-3:0] imem_latched_addr;

    always @ (posedge clk)
        imem_latched_addr <= imem_addr[LINE_ADDR_BITS-1:2];

    assign imem_data_out_shifted = imem_data_out >> {imem_latched_addr, 5'd0};
    assign imem_read_data = imem_data_out_shifted[31:0];
end

always @ (posedge clk)
    if (rst) begin
		    imem_read_ready <= 1'b0;
		end else begin
		    imem_read_ready <= imem_v;
    end

// connection to dmem and imem
  assign ext_dmem_en       = dmem_v && (!io_not_mem);
  assign ext_dmem_wen      = dmem_wr_en;
  assign ext_dmem_strb     = dmem_line_write_mask;
  assign ext_dmem_addr     = dmem_addr;
  assign ext_dmem_wr_data  = dmem_data_in;
  assign dmem_data_out     = ext_dmem_rd_data;

  assign ext_imem_ren     = imem_v;
  assign ext_imem_addr    = imem_addr;
  assign imem_data_out    = ext_imem_rd_data;

///////////////////////////////////////////////////////////////////////////
/////////////////////// ADDRESS ERROR CATCHING ////////////////////////////
///////////////////////////////////////////////////////////////////////////
// Register addresses and enables for error catching 
reg [31:0] imem_addr_r, dmem_addr_r;
reg dmem_v_r, dmem_wr_en_r, imem_v_r;
reg [1:0] dmem_byte_count_r;

wire io_not_mem_r = dmem_addr_r[ADDR_WIDTH-1];

always @ (posedge clk) begin
  imem_addr_r       <= imem_addr;
  dmem_addr_r       <= dmem_addr;
  dmem_v_r          <= dmem_v;
  imem_v_r          <= imem_v;
  dmem_wr_en_r      <= dmem_wr_en;
  dmem_byte_count_r <= dmem_byte_count;
  if (rst) begin
    dmem_v_r        <= 1'b0;
    imem_v_r        <= 1'b0;
    dmem_wr_en_r    <= 1'b0;
  end 
end

// Register the error ack so a simple sync reg would be enough to respond
// assuming the code waits a cycle before resetting it, which is the case
// when responding to an interrupt. 
reg ext_err_ack;
always @ (posedge clk)
  if (rst || (interrupt_ack && wr_desc_din[12])) //5th bit, error write is in second byte
    ext_err_ack <= 1'b0;
  else if (interrupt_ack && wr_desc_din[12])
    ext_err_ack <= 1'b1;

assign interrupt_in_ack = ext_err_ack;

// Each error stays asserted until it is reset by corresponding bit when interrupt_ack is asserted
always @ (posedge clk)
    if (rst) begin
        imem_access_err    <= 1'b0;
        dmem_access_err    <= 1'b0;
        io_access_data_err <= 1'b0;
        io_byte_access_err <= 1'b0;
		end else begin
        imem_access_err    <= !(interrupt_ack && wr_desc_din[8]) && (imem_access_err || 
                              (imem_v_r && (imem_addr_r >= (1 << IMEM_ADDR_WIDTH))));

        dmem_access_err    <= !(interrupt_ack && wr_desc_din[9]) && (dmem_access_err || 
                                (dmem_v_r && ((!io_not_mem_r && (dmem_addr_r >= (1 << DMEM_ADDR_WIDTH)))
                                              || (dmem_addr_r >= ((1 << (ADDR_WIDTH-1))+IO_SPACE)))));
                       
        io_access_data_err <= !(interrupt_ack && wr_desc_din[10]) && (io_access_data_err || 
                                (io_not_mem_r && dmem_v_r && 
                                ((dmem_wr_en_r && !(dmem_addr_r[6]==IO_WRITE_ADDRS)) || 
                                (!dmem_wr_en_r && !(dmem_addr_r[6]==IO_READ_ADDRS)))));

        io_byte_access_err <= !(interrupt_ack && wr_desc_din[11]) && (io_byte_access_err || 
                               (io_not_mem_r && dmem_v_r && 
                               (dmem_byte_count_r != 2'd0) && (dmem_addr_r[6:3]==IO_BYTE_ACCESS)));

    end

///////////////////////////////////////////////////////////////////////////
///////////////////// CORE BROADCAST MESSAGING ////////////////////////////
///////////////////////////////////////////////////////////////////////////

// Any write after the coherent point would become a message. No registering
// to save a clock cycle, assuming proper power of 2 COHERENT START
assign core_msg_data  = dmem_wr_data;
assign core_msg_addr  = dmem_addr[MSG_ADDR_WIDTH+2-1:2];
assign core_msg_strb  = dmem_word_write_mask[3:0];
assign core_msg_valid = dmem_v && dmem_wr_en && 
      (dmem_addr >= BC_START_ADDR) && (dmem_addr < (BC_START_ADDR + BC_REGION_SIZE));

endmodule