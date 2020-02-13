#include "core.h"
	
struct Desc packet;

int main(void){

	unsigned long long dram_rd_addr = 0x000000000000BBBB;
	unsigned long long dram_wr_addr = 0x000000000000BCBB;

	write_timer_interval(0x00000200);
	set_masks(0x1F); //enable just errors 

	// Do this at the beginnig, so scheduler can fill the slots while 
	// initializing other things.
	init_hdr_slots(8, 0x804000, 128);
	init_slots(8, 0x00000A, 16384);
	
	packet.len  = 69;
	packet.tag  = 12;
	packet.data = (unsigned char*)0x800020;
	safe_dram_read_req(&dram_rd_addr, &packet);

	while (dram_flags()==0);
	write_dram_flags(0);

	packet.len  = 69;
	packet.tag  = 12;
	packet.data = (unsigned char*)0x800020;
	safe_dram_write(&dram_wr_addr, &packet);

	while (1){
		if (in_pkt_ready()){
	 		
			read_in_pkt(&packet);

			if (packet.port==0){
				packet.port = 1;
			} else {
				packet.port = 0;
			}
			safe_pkt_send(&packet);
			// safe_pkt_done_msg(&packet);

  	}
  }
  
  return 1;
}
