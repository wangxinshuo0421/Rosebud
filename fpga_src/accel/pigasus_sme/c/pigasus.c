#include "core.h"
#include "packet_headers.h"

#if 0
#define PROFILE_A(x) do {DEBUG_OUT_L = (x);} while (0)
#else
#define PROFILE_A(x) do {} while (0)
#endif

#if 0
#define PROFILE_B(x) do {DEBUG_OUT_H = (x);} while (0)
#else
#define PROFILE_B(x) do {} while (0)
#endif

#define bswap_16(x) \
  (((x & 0xff00) >> 8) | ((x & 0x00ff) << 8))

#define bswap_32(x) \
  (((x & 0xff000000) >> 24) | ((x & 0x00ff0000) >>  8) | \
   ((x & 0x0000ff00) <<  8) | ((x & 0x000000ff) << 24))

// maximum number of slots (number of context objects)
#define MAX_CTX_COUNT 32
#define REORDER_LIMIT 16
#define HASH_LB

// packet start offset
// DWORD align Ethernet payload
// provide space for header modifications
#define PKT_OFFSET 10
// PMEM in 8 blocks of 128 KB
// accelerators only connected to upper 2 blocks
#define PKTS_START ((8-(MAX_CTX_COUNT/8))*128*1024)

#ifdef HASH_LB
  #define DATA_OFFSET 4
#else
  #define DATA_OFFSET 0
#endif

#define mem_align(x) (((unsigned int)x+3) & 0xFFFFFFFC)

// flows
struct flow {
  unsigned short tag;
  unsigned short ts;
  unsigned int   exp_seq;
  union {
    volatile unsigned long long state_64;
    volatile unsigned int       state_32[2];
    volatile unsigned char      state_8[8];
  } state;
};

// Accel wrapper registers mapping
#define ACC_PIG_CTRL     (*((volatile unsigned char      *)(IO_EXT_BASE + 0x00)))
#define ACC_PIG_MATCH    (*((volatile unsigned char      *)(IO_EXT_BASE + 0x00)))
#define ACC_PIG_STATE    (*((volatile unsigned long long *)(IO_EXT_BASE + 0x10)))
#define ACC_PIG_STATE_L  (*((volatile unsigned int       *)(IO_EXT_BASE + 0x10)))
#define ACC_PIG_STATE_H  (*((volatile unsigned int       *)(IO_EXT_BASE + 0x14)))
#define ACC_PIG_PORTS    (*((volatile unsigned int       *)(IO_EXT_BASE + 0x0c)))
#define ACC_PIG_SRC_PORT (*((volatile unsigned short     *)(IO_EXT_BASE + 0x0c)))
#define ACC_PIG_DST_PORT (*((volatile unsigned short     *)(IO_EXT_BASE + 0x0e)))
#define ACC_PIG_SLOT     (*((volatile unsigned char      *)(IO_EXT_BASE + 0x18)))
#define ACC_PIG_RULE_ID  (*((volatile unsigned int       *)(IO_EXT_BASE + 0x1c)))

#define FLOW_TABLE_ENTRY   ((volatile struct flow        *)(IO_EXT_BASE + 0x40))
#define HASH_LOOKUP      (*((volatile unsigned short     *)(IO_EXT_BASE + 0x60)))
#define HASH_BLOCK_32B   (*((volatile unsigned char      *)(IO_EXT_BASE + 0x64)))

#define ACC_DMA_LEN      (*((volatile unsigned int       *)(IO_EXT_BASE + 0x04)))
#define ACC_DMA_ADDR     (*((volatile unsigned int       *)(IO_EXT_BASE + 0x08)))
#define ACC_DMA_STAT     (*((volatile unsigned int       *)(IO_EXT_BASE + 0x78)))
#define ACC_DMA_BUSY     (*((volatile unsigned char      *)(IO_EXT_BASE + 0x78)))
#define ACC_DMA_DONE     (*((volatile unsigned char      *)(IO_EXT_BASE + 0x79)))
#define ACC_DMA_DONE_ERR (*((volatile unsigned char      *)(IO_EXT_BASE + 0x7a)))

unsigned int reorder_slots_1hot;
unsigned int reorder_slot_count;
unsigned int reorder_slot;
// unsigned int pkt_num;

// Slot contexts
struct slot_context {
  // Flow metadata
  struct   flow  flow;
  unsigned short flow_id;
  unsigned short reorder_ts;

  struct Desc desc;
  int index;
  int is_tcp;

  // Pointers
  unsigned char  *eop;
  unsigned char  *header;
  unsigned short *hash_L;
  unsigned short *hash_H;

  // Packet metadata
  unsigned int payload_addr;
  unsigned int payload_length;
  unsigned int match_cnt;
  unsigned int set_mask;
  unsigned int rst_mask;

  struct eth_header *eth_hdr;
  union {
    struct ipv4_header *ipv4_hdr;
  } l3_header;
  union {
    struct tcp_header *tcp_hdr;
    struct udp_header *udp_hdr;
  } l4_header;

  union {
    struct tcp_header *tcp_hdr;
    struct udp_header *udp_hdr;
  } l4_header_swapped;

};

struct slot_context context[MAX_CTX_COUNT];

unsigned int pkt_num;
unsigned int slot_count;
unsigned int header_slot_base;

const unsigned int slot_size        = 16*1024;
const unsigned int header_slot_size = 128;

static inline void slot_rx_packet(struct slot_context *slot)
{
  char ch;
  unsigned int   payload_offset = ETH_HEADER_SIZE + IPV4_HEADER_SIZE;
  unsigned int   packet_length  = slot->desc.len;
  unsigned short cur_time;
  unsigned int   cur_seq_num;
  struct   flow  *flow_wr;
  int            tag_match, time_out; // Actually bool

  PROFILE_B(0x00010005);

  slot->flow_id  = (*(slot->hash_H)) >> 1;
  HASH_LOOKUP    = slot->flow_id;
  asm volatile("" ::: "memory");
  slot->flow.tag = *(slot->hash_L);

  // check eth type
  if (slot->eth_hdr->type == bswap_16(0x0800))
  {
    // IPv4 packet

    // check version
    ch = slot->l3_header.ipv4_hdr->version_ihl;
    if ((ch & 0xF0) != 0x40)
    {
      // invalid version, drop it
      PROFILE_B(0x00010009);
      goto drop;
    }

    // Assumed IPV4_HEADER_SIZE
    // payload_offset += (ch & 0xf) << 2;

    // check protocol
    if (slot->l3_header.ipv4_hdr->protocol==0x6) // TCP
    {
      PROFILE_B(0x00010007);
      // // header size from flags field
      // ch = ((char *)slot->l4_header.tcp_hdr)[12];
      // payload_offset += (ch & 0xF0) >> 2;
      payload_offset += TCP_HEADER_SIZE;

      // if (payload_offset >= packet_length){
      //   // no payload
      //   PROFILE_B(0x00010002);
      //   goto drop;
      // }

      slot->flow.state.state_32[1] = FLOW_TABLE_ENTRY->state.state_32[1];

      // Clean entry
      if (slot->flow.state.state_8[7]==0){
        // Hardware would set the has_preamble bit, no need to change state
        PROFILE_B(0xBEEF0001);
        ACC_PIG_STATE_H = 0x01FFFFFF;
        flow_wr = (struct flow *) (PMEM_BASE) + (slot->flow_id);
        flow_wr->tag = slot->flow.tag;
        goto process_tcp;
      }

      cur_time      = TIMER_16_HL;
      slot->flow.ts = FLOW_TABLE_ENTRY->ts;

      // TCP time out. If it's not a tag match the previous flow has finished,
      // if it's a tag match it's same flow resend or there was a problem,
      // consider this to be first of new set of packet. Both cases like clean entry
      time_out  = ((cur_time < slot->flow.ts) || ((cur_time - slot->flow.ts) > 4));
      if (time_out){
        PROFILE_B(0xBEEF0002);
        ACC_PIG_STATE_H = 0x01FFFFFF;
        flow_wr = (struct flow *) (PMEM_BASE) + (slot->flow_id);
        flow_wr->tag = slot->flow.tag;
        goto process_tcp;
      }

      // tag collision, send to host
      tag_match = (slot->flow.tag == FLOW_TABLE_ENTRY->tag);
      if (!tag_match){
        // apply offset
        PROFILE_B(0xBEEF0003);
        slot->desc.port = 2;
        pkt_send(&slot->desc);
        return;
      }

      slot->flow.exp_seq = FLOW_TABLE_ENTRY->exp_seq;
      cur_seq_num        = slot->l4_header_swapped.tcp_hdr->seq;


      if (cur_seq_num == slot->flow.exp_seq){
        ACC_PIG_STATE = FLOW_TABLE_ENTRY->state.state_64;
        PROFILE_B(0xBEEF0004);
        // goto process_tcp;
      } else if ((cur_seq_num > (slot->flow.exp_seq + 30000)) || //assuming 3 jumbo
               (cur_seq_num <  slot->flow.exp_seq )) {
        PROFILE_B(0xBEEF0005);
        // PROFILE_A(cur_seq_num);
        // PROFILE_A(slot->flow.exp_seq);
        goto drop;
      } else if (reorder_slot_count <= REORDER_LIMIT){
        // Save the remaining slot info and raise the reorder flag
        PROFILE_B(0xBEEF0006);
        slot->payload_addr   = (unsigned int)(slot->desc.data)+payload_offset;
        slot->payload_length = packet_length - payload_offset;
        slot->is_tcp         = 1;
        slot->reorder_ts     = TIMER_16_LH;

        reorder_slot_count ++;
        reorder_slots_1hot |= slot->set_mask;
        PROFILE_B(0xFEEB0000 | reorder_slots_1hot);
        return;
      } else {
        PROFILE_B(0xBEEF0007);
        goto drop;
      }

process_tcp:
      slot->payload_addr   = (unsigned int)(slot->desc.data)+payload_offset;
      slot->payload_length = packet_length - payload_offset;

      ACC_DMA_ADDR  = slot->payload_addr;
      ACC_DMA_LEN   = slot->payload_length;
      ACC_PIG_PORTS = * (unsigned int *) slot->l4_header.tcp_hdr; // both ports
      ACC_PIG_SLOT  = slot->index;
      ACC_PIG_CTRL  = 1;

      slot->is_tcp  = 1;
      return;
    }
    else // UDP
    {
      PROFILE_B(0x00010006);
      payload_offset += UDP_HEADER_SIZE;

      // if (payload_offset >= packet_length)
      //   // no payload
      //   goto drop;

      slot->payload_addr   = (unsigned int)(slot->desc.data)+payload_offset;
      slot->payload_length = packet_length - payload_offset;

      ACC_DMA_ADDR  = slot->payload_addr;
      ACC_DMA_LEN   = slot->payload_length;
      ACC_PIG_PORTS = * (unsigned int *) slot->l4_header.udp_hdr; // both ports
      ACC_PIG_STATE = 0;
      ACC_PIG_SLOT  = slot->index;
      ACC_PIG_CTRL  = 1;

      slot->is_tcp  = 0;
      return;
    }
  }

drop:
  slot->desc.len = 0;
  pkt_send(&slot->desc);
}

static inline void slot_match(struct slot_context *slot){
  unsigned int rule_id;
  struct flow * flow_wr;
  PROFILE_B(0xDEAD6666);

  while (1){
    rule_id = ACC_PIG_RULE_ID;
    asm volatile("" ::: "memory");

    if (rule_id!=0){
      ACC_PIG_CTRL = 2; // release the match
      asm volatile("" ::: "memory");
      // Add rule IDs to the end of the packet
      slot->eop = (unsigned char *) mem_align(slot->desc.data + slot->desc.len);
      * (unsigned int *) slot->eop = rule_id;
      slot->desc.len = (unsigned int) slot->eop - (unsigned int) slot->desc.data + 4;
      slot->match_cnt ++;
      slot->desc.port = 2;
      PROFILE_B(0xDEAD0001);
    } else { // EoP

      // pkt_num ++;
      PROFILE_B(0xDEAD0002);

      // Decide what to do with the packet
      if (slot->flow.state.state_8[7]>0x80){
        PROFILE_B(0xDEAD0003);
        // PROFILE_A(0xDDDD0000|pkt_num);
        slot->desc.port = 2;
      }

      // else if (match_cnt ==0) {// IDS: drop, IPS: forward
      //   // slot->desc.len = 0;
      //   PROFILE_B(0xDEAD0004);
      //   slot->desc.port ^= 0x1;
      // }

      if (slot->is_tcp){
        PROFILE_B(0xDEAD0005);
        // Update state in the flow table
        flow_wr = (struct flow *) (PMEM_BASE) + (slot->flow_id);

        if (slot->l4_header.tcp_hdr->flags & bswap_16(0x0001)) { // FIN
          flow_wr->state.state_8[7]  = 0;
          PROFILE_B(0xDEAD0006);
        } else if (slot->match_cnt!=0) {
          flow_wr->state.state_32[1] = ACC_PIG_STATE_H | 0x80000000;
          flow_wr->state.state_32[0] = ACC_PIG_STATE_L;
          PROFILE_B(0xDEAD0007);
        } else {
          flow_wr->state.state_64    = ACC_PIG_STATE;
          PROFILE_B(0xDEAD0008);
        }

        if (slot->l4_header.tcp_hdr->flags & bswap_16(0x0002)) // SYN
          flow_wr->exp_seq = slot->l4_header_swapped.tcp_hdr->seq + slot->payload_length+1;
        else
          flow_wr->exp_seq = slot->l4_header_swapped.tcp_hdr->seq + slot->payload_length;

        flow_wr->ts = TIMER_16_HL;
      }

      ACC_PIG_CTRL    = 2; // release the EoP
      asm volatile("" ::: "memory");
      pkt_send(&slot->desc);
      return; // Go back to main loop when done with a packet
    }

    if (ACC_PIG_MATCH) // continue draining FIFO
      slot = &context[ACC_PIG_SLOT];
    else
      break;
  }
}

static inline void process_reorder(struct slot_context *slot)
{
  unsigned short cur_time, test;

  PROFILE_B(0xDCDC0000 | slot->index);

  asm volatile("" ::: "memory");
  HASH_LOOKUP        = slot->flow_id;
  asm volatile("" ::: "memory");
  cur_time           = TIMER_16_LH;
  asm volatile("" ::: "memory");
  slot->flow.exp_seq = FLOW_TABLE_ENTRY->exp_seq;

  if (slot->l4_header_swapped.tcp_hdr->seq == slot->flow.exp_seq){
    PROFILE_B(0xBEEF0101);
    ACC_DMA_ADDR  = slot->payload_addr;
    ACC_DMA_LEN   = slot->payload_length;
    ACC_PIG_PORTS = * (unsigned int *) slot->l4_header.tcp_hdr; // both ports
    ACC_PIG_STATE = FLOW_TABLE_ENTRY->state.state_64;
    ACC_PIG_SLOT  = slot->index;
    ACC_PIG_CTRL  = 1;
    reorder_slots_1hot &= slot->rst_mask;
    reorder_slot_count --;
    return;
  }

  // TCP time out (from packet arrival, no need to check FLOW_TABLE_ENTRY->ts)
  if ((cur_time < slot->reorder_ts) || ((cur_time - slot->reorder_ts) > 3000)){ // 0.78s
    PROFILE_B(0xBEEF0100);
    slot->desc.len = 0;
    pkt_send(&slot->desc);
    reorder_slots_1hot &= slot->rst_mask;
    reorder_slot_count --;
  }

}

int main(void)
{
  struct slot_context *slot;
  unsigned int reorder_mask;
  unsigned int reorder_left_mask;
  unsigned int init_left_mask;

  DEBUG_OUT_L = 0;
  DEBUG_OUT_H = 0;

  // set slot configuration parameters
  slot_count       = 32;
  header_slot_base = DMEM_BASE + (DMEM_SIZE >> 1);

  if (slot_count > MAX_SLOT_COUNT)
    slot_count = MAX_SLOT_COUNT;

  if (slot_count > MAX_CTX_COUNT)
    slot_count = MAX_CTX_COUNT;

  // Do this at the beginning, so LB can fill the slots while
  // initializing other things.
  init_hdr_slots(slot_count, header_slot_base, header_slot_size);
  init_slots(slot_count, PKTS_START+PKT_OFFSET, slot_size);
  set_masks(0x30); // Enable only Evict + Poke
  set_lb_offset(DATA_OFFSET);

  // init slot context structures
  for (int i = 0; i < slot_count; i++)
  {
    context[i].index     = i;
    context[i].desc.tag  = i+1;
    context[i].desc.data = (unsigned char *)(PMEM_BASE + PKTS_START + PKT_OFFSET + DATA_OFFSET + i*slot_size);
    context[i].header    = (unsigned char *)(header_slot_base + PKT_OFFSET + DATA_OFFSET + i*header_slot_size);
    context[i].hash_L    = (unsigned short *)(header_slot_base + PKT_OFFSET + i*header_slot_size);
    context[i].hash_H    = (unsigned short *)(header_slot_base + PKT_OFFSET + i*header_slot_size + 2);
    context[i].eth_hdr   = (struct eth_header*)(context[i].header);
    context[i].match_cnt = 0;
    context[i].set_mask  =   0x1L << i;
    context[i].rst_mask  = ~(0x1L << i);

    // We only process IPv4
    context[i].l3_header.ipv4_hdr        = (struct ipv4_header*)(context[i].header +
                                     ETH_HEADER_SIZE);
    context[i].l4_header.tcp_hdr         = (struct tcp_header*) (context[i].header +
                                     ETH_HEADER_SIZE + IPV4_HEADER_SIZE);
    context[i].l4_header_swapped.tcp_hdr = (struct tcp_header*) (context[i].header +
                                     ETH_HEADER_SIZE + IPV4_HEADER_SIZE + 0x08000000);
  }

  reorder_slots_1hot = 0;
  reorder_slot_count = 0;
  if (slot_count==32)
    init_left_mask = ~0x0;
  else
    init_left_mask = (1<<slot_count) - 1;
  // pkt_num = 0;
  reorder_left_mask = init_left_mask;
  reorder_mask      = 1;
  reorder_slot      = 0;

  while (1)
  {
    // check for new packets
    if (in_pkt_ready())
    {
      // compute index
      slot = &context[RECV_DESC.tag-1];

      // copy descriptor into context, we already know the data pointer
      slot->desc.desc_low = RECV_DESC.desc_low;
      asm volatile("" ::: "memory");
      RECV_DESC_RELEASE = 1;

      // handle packet
      slot->match_cnt = 0;
      slot_rx_packet(slot);
    }

    if (ACC_PIG_MATCH) {
      slot_match(&context[ACC_PIG_SLOT]);
    }

    if (reorder_slots_1hot) {
      if (reorder_slots_1hot & reorder_mask)
        process_reorder(&context[reorder_slot]);

      reorder_mask      = reorder_mask      << 1;
      reorder_left_mask = reorder_left_mask << 1;
      reorder_slot++;

      if (reorder_slot==slot_count){
        reorder_slot      = 0;
        reorder_left_mask = init_left_mask;
        reorder_mask      = 1;
      }
    }
  }

  return 1;
}
