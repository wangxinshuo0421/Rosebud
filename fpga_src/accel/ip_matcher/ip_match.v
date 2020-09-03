module table_10000010(input [15:0] addr, output reg match);
  always@(addr) begin
    casex (addr)
      16'b11010011000001??: match=1'b1;
      16'b1101001100001???: match=1'b1;
      16'b110100110001????: match=1'b1;
      16'b110100110010????: match=1'b1;
      16'b110100110011????: match=1'b1;
      16'b110100110110????: match=1'b1;
      16'b110100110111????: match=1'b1;
      16'b110100111110????: match=1'b1;
      16'b110100111111????: match=1'b1;
      16'b11010011010?????: match=1'b1;
      16'b11010011110?????: match=1'b1;
      16'b1101001110??????: match=1'b1;
      default: match=1'b0;
    endcase
  end
endmodule

module table_00010111(input [15:0] addr, output reg match);
  always@(addr) begin
    casex (addr)
      16'b111011000011????: match=1'b1;
      16'b111110111000????: match=1'b1;
      16'b111110111001????: match=1'b1;
      default: match=1'b0;
    endcase
  end
endmodule

module table_10100010(input [15:0] addr, output reg match);
  always@(addr) begin
    casex (addr)
      16'b11011000100101??: match=1'b1;
      16'b1101111010110???: match=1'b1;
      default: match=1'b0;
    endcase
  end
endmodule

module table_01101000(input [15:0] addr, output reg match);
  always@(addr) begin
    casex (addr)
      16'b1001101001110001: match=1'b1;
      16'b1100010001000001: match=1'b1;
      16'b100110100111001?: match=1'b1;
      16'b100110100111100?: match=1'b1;
      16'b110001000100001?: match=1'b1;
      16'b110001110100001?: match=1'b1;
      16'b110001111111001?: match=1'b1;
      16'b10011010011101??: match=1'b1;
      16'b11000100010001??: match=1'b1;
      16'b11000111010001??: match=1'b1;
      16'b11000111111101??: match=1'b1;
      16'b1100011101001???: match=1'b1;
      16'b1100011111111???: match=1'b1;
      16'b100110100001????: match=1'b1;
      16'b100110100110????: match=1'b1;
      16'b100110111110????: match=1'b1;
      16'b110001100000????: match=1'b1;
      16'b110001100001????: match=1'b1;
      16'b110001100100????: match=1'b1;
      16'b110001100101????: match=1'b1;
      16'b110001100110????: match=1'b1;
      16'b110001100111????: match=1'b1;
      16'b110001110101????: match=1'b1;
      16'b110001110110????: match=1'b1;
      16'b110001110111????: match=1'b1;
      16'b110001111110????: match=1'b1;
      16'b10011010001?????: match=1'b1;
      16'b10011010010?????: match=1'b1;
      16'b10011011110?????: match=1'b1;
      16'b11000100011?????: match=1'b1;
      16'b11000100110?????: match=1'b1;
      16'b11000100111?????: match=1'b1;
      16'b11000110001?????: match=1'b1;
      16'b11000111110?????: match=1'b1;
      16'b1001101110??????: match=1'b1;
      16'b1100010000??????: match=1'b1;
      16'b1100010010??????: match=1'b1;
      16'b1100011100??????: match=1'b1;
      16'b1100011110??????: match=1'b1;
      16'b100110101???????: match=1'b1;
      16'b100110110???????: match=1'b1;
      16'b110001101???????: match=1'b1;
      16'b11000101????????: match=1'b1;
      default: match=1'b0;
    endcase
  end
endmodule

module table_10101101(input [15:0] addr, output reg match);
  always@(addr) begin
    casex (addr)
      16'b1111111101110???: match=1'b1;
      16'b1111111101111???: match=1'b1;
      default: match=1'b0;
    endcase
  end
endmodule

module table_01101100(input [15:0] addr, output reg match);
  always@(addr) begin
    casex (addr)
      16'b0011101101010???: match=1'b1;
      16'b0011101101011???: match=1'b1;
      default: match=1'b0;
    endcase
  end
endmodule

module table_11000111(input [15:0] addr, output reg match);
  always@(addr) begin
    casex (addr)
      16'b1100000001110011: match=1'b1;
      16'b1101111111101100: match=1'b1;
      16'b11011111111010??: match=1'b1;
      default: match=1'b0;
    endcase
  end
endmodule

module table_00001000(input [15:0] addr, output reg match);
  always@(addr) begin
    casex (addr)
      16'b0010001011010010: match=1'b1;
      16'b0010001011010011: match=1'b1;
      16'b001000101101000?: match=1'b1;
      16'b00100010110101??: match=1'b1;
      16'b00100010110110??: match=1'b1;
      16'b00100010110111??: match=1'b1;
      16'b0010001111000???: match=1'b1;
      default: match=1'b0;
    endcase
  end
endmodule

module table_10010010(input [15:0] addr, output reg match);
  always@(addr) begin
    casex (addr)
      16'b100101000000001?: match=1'b1;
      16'b10010100000001??: match=1'b1;
      16'b1001010000001???: match=1'b1;
      16'b100101000001????: match=1'b1;
      16'b100101000110????: match=1'b1;
      16'b100101000111????: match=1'b1;
      16'b10010100001?????: match=1'b1;
      16'b10010100010?????: match=1'b1;
      default: match=1'b0;
    endcase
  end
endmodule

module table_01101011(input [15:0] addr, output reg match);
  always@(addr) begin
    casex (addr)
      16'b101001111010????: match=1'b1;
      16'b101001111011????: match=1'b1;
      16'b101100101101????: match=1'b1;
      16'b101100101111????: match=1'b1;
      default: match=1'b0;
    endcase
  end
endmodule

module table_00100010(input [15:0] addr, output reg match);
  always@(addr) begin
    casex (addr)
      16'b011010000110100?: match=1'b1;
      16'b011010000110101?: match=1'b1;
      16'b011010000110110?: match=1'b1;
      16'b011010000110111?: match=1'b1;
      16'b011010000111000?: match=1'b1;
      16'b011111000010100?: match=1'b1;
      16'b011111000010101?: match=1'b1;
      16'b011111000010110?: match=1'b1;
      16'b011111000010111?: match=1'b1;
      16'b011111000011000?: match=1'b1;
      16'b01000000010000??: match=1'b1;
      16'b01000000010001??: match=1'b1;
      16'b01000000100000??: match=1'b1;
      16'b01000000100001??: match=1'b1;
      16'b01100101000101??: match=1'b1;
      16'b01100101000110??: match=1'b1;
      16'b01101000010010??: match=1'b1;
      16'b01101000010011??: match=1'b1;
      16'b01111100000010??: match=1'b1;
      16'b01111100000011??: match=1'b1;
      16'b0100000001001???: match=1'b1;
      16'b0100000010001???: match=1'b1;
      16'b0110001010000???: match=1'b1;
      16'b0110100001000???: match=1'b1;
      16'b0110100001010???: match=1'b1;
      16'b0110100001011???: match=1'b1;
      16'b0110100001100???: match=1'b1;
      16'b0111010000000???: match=1'b1;
      16'b0111110000000???: match=1'b1;
      16'b0111110000010???: match=1'b1;
      16'b0111110000011???: match=1'b1;
      16'b0111110000100???: match=1'b1;
      16'b010000000101????: match=1'b1;
      16'b010000001001????: match=1'b1;
      16'b01000000011?????: match=1'b1;
      16'b01000000101?????: match=1'b1;
      16'b0100000011??????: match=1'b1;
      16'b0101011110??????: match=1'b1;
      16'b0101011111??????: match=1'b1;
      16'b0101111100??????: match=1'b1;
      16'b0101111101??????: match=1'b1;
      16'b0110000001??????: match=1'b1;
      16'b0110001001??????: match=1'b1;
      16'b0110010101??????: match=1'b1;
      16'b0111010001??????: match=1'b1;
      16'b0111111001??????: match=1'b1;
      16'b0111111010??????: match=1'b1;
      16'b010101010???????: match=1'b1;
      16'b010101011???????: match=1'b1;
      16'b010101110???????: match=1'b1;
      16'b010110010???????: match=1'b1;
      16'b010110011???????: match=1'b1;
      16'b010111111???????: match=1'b1;
      16'b011000001???????: match=1'b1;
      16'b011001001???????: match=1'b1;
      16'b011001011???????: match=1'b1;
      16'b011001100???????: match=1'b1;
      16'b011001101???????: match=1'b1;
      16'b011010001???????: match=1'b1;
      16'b011010010???????: match=1'b1;
      16'b011010011???????: match=1'b1;
      16'b011010110???????: match=1'b1;
      16'b011010111???????: match=1'b1;
      16'b011111001???????: match=1'b1;
      16'b01000001????????: match=1'b1;
      16'b01001000????????: match=1'b1;
      16'b01001001????????: match=1'b1;
      16'b01010100????????: match=1'b1;
      16'b01010110????????: match=1'b1;
      16'b01011000????????: match=1'b1;
      16'b01011100????????: match=1'b1;
      16'b01011101????????: match=1'b1;
      16'b01011110????????: match=1'b1;
      16'b01100001????????: match=1'b1;
      16'b01101010????????: match=1'b1;
      16'b01111000????????: match=1'b1;
      16'b01111001????????: match=1'b1;
      16'b01111101????????: match=1'b1;
      16'b0100001?????????: match=1'b1;
      16'b0100101?????????: match=1'b1;
      16'b0101000?????????: match=1'b1;
      16'b0101001?????????: match=1'b1;
      16'b0101101?????????: match=1'b1;
      16'b0111101?????????: match=1'b1;
      16'b010001??????????: match=1'b1;
      16'b010011??????????: match=1'b1;
      default: match=1'b0;
    endcase
  end
endmodule

module table_00100011(input [15:0] addr, output reg match);
  always@(addr) begin
    casex (addr)
      16'b1100100100101001: match=1'b1;
      16'b1101110000011010: match=1'b1;
      16'b1101110000011011: match=1'b1;
      16'b1101110000011111: match=1'b1;
      16'b1101110000101000: match=1'b1;
      16'b1101110000101001: match=1'b1;
      16'b1101110000101010: match=1'b1;
      16'b1101110000101011: match=1'b1;
      16'b1101110000101100: match=1'b1;
      16'b1101110000101101: match=1'b1;
      16'b1101110000101110: match=1'b1;
      16'b1101110000101111: match=1'b1;
      16'b1111001000011010: match=1'b1;
      16'b1111001000011011: match=1'b1;
      16'b1111001000011111: match=1'b1;
      16'b1111001000101000: match=1'b1;
      16'b1111001000101001: match=1'b1;
      16'b1111001000101010: match=1'b1;
      16'b1111001000101011: match=1'b1;
      16'b1111001000101100: match=1'b1;
      16'b1111001000101101: match=1'b1;
      16'b1111001000101110: match=1'b1;
      16'b1111001000101111: match=1'b1;
      16'b110010111101001?: match=1'b1;
      16'b110111000001000?: match=1'b1;
      16'b110111000001001?: match=1'b1;
      16'b110111000001100?: match=1'b1;
      16'b111100100001000?: match=1'b1;
      16'b111100100001001?: match=1'b1;
      16'b111100100001100?: match=1'b1;
      16'b11001011110101??: match=1'b1;
      16'b11001011110110??: match=1'b1;
      16'b11011100000101??: match=1'b1;
      16'b11011100001110??: match=1'b1;
      16'b11011100001111??: match=1'b1;
      16'b11110010000101??: match=1'b1;
      16'b11110010001110??: match=1'b1;
      16'b11110010001111??: match=1'b1;
      16'b1100101111101???: match=1'b1;
      16'b1101110000100???: match=1'b1;
      16'b1101110000110???: match=1'b1;
      16'b1110101111011???: match=1'b1;
      16'b1111001000100???: match=1'b1;
      16'b1111001000110???: match=1'b1;
      16'b1111001100000???: match=1'b1;
      16'b1111001100001???: match=1'b1;
      16'b1111001100100???: match=1'b1;
      16'b1111001100101???: match=1'b1;
      16'b1111001100111???: match=1'b1;
      16'b101110011010????: match=1'b1;
      16'b101110011011????: match=1'b1;
      16'b101110101000????: match=1'b1;
      16'b101110101001????: match=1'b1;
      16'b101110111001????: match=1'b1;
      16'b101111100111????: match=1'b1;
      16'b101111101110????: match=1'b1;
      16'b110001111001????: match=1'b1;
      16'b110111000000????: match=1'b1;
      16'b111001010001????: match=1'b1;
      16'b111001101111????: match=1'b1;
      16'b111010101010????: match=1'b1;
      16'b111010101011????: match=1'b1;
      16'b111010101100????: match=1'b1;
      16'b111010101101????: match=1'b1;
      16'b111010101110????: match=1'b1;
      16'b111010101111????: match=1'b1;
      16'b111010110000????: match=1'b1;
      16'b111010110001????: match=1'b1;
      16'b111010110010????: match=1'b1;
      16'b111010110011????: match=1'b1;
      16'b111100100000????: match=1'b1;
      16'b10111001100?????: match=1'b1;
      16'b10111010101?????: match=1'b1;
      16'b10111011101?????: match=1'b1;
      16'b10111011110?????: match=1'b1;
      16'b10111011111?????: match=1'b1;
      16'b10111100110?????: match=1'b1;
      16'b10111100111?????: match=1'b1;
      16'b10111101100?????: match=1'b1;
      16'b10111101101?????: match=1'b1;
      16'b10111110010?????: match=1'b1;
      16'b10111110110?????: match=1'b1;
      16'b11000010010?????: match=1'b1;
      16'b11000010011?????: match=1'b1;
      16'b11000101100?????: match=1'b1;
      16'b11000101101?????: match=1'b1;
      16'b11000111101?????: match=1'b1;
      16'b11001001000?????: match=1'b1;
      16'b11001110001?????: match=1'b1;
      16'b11011100010?????: match=1'b1;
      16'b11011100011?????: match=1'b1;
      16'b11100101001?????: match=1'b1;
      16'b11100110100?????: match=1'b1;
      16'b11100110101?????: match=1'b1;
      16'b11101010100?????: match=1'b1;
      16'b11110010010?????: match=1'b1;
      16'b11110010011?????: match=1'b1;
      16'b1011100111??????: match=1'b1;
      16'b1011101011??????: match=1'b1;
      16'b1011110010??????: match=1'b1;
      16'b1011110100??????: match=1'b1;
      16'b1011110101??????: match=1'b1;
      16'b1011110111??????: match=1'b1;
      16'b1011111000??????: match=1'b1;
      16'b1011111010??????: match=1'b1;
      16'b1100001000??????: match=1'b1;
      16'b1100010111??????: match=1'b1;
      16'b1100011000??????: match=1'b1;
      16'b1100011001??????: match=1'b1;
      16'b1100011010??????: match=1'b1;
      16'b1100011011??????: match=1'b1;
      16'b1100011100??????: match=1'b1;
      16'b1100011101??????: match=1'b1;
      16'b1100100101??????: match=1'b1;
      16'b1100101110??????: match=1'b1;
      16'b1100111001??????: match=1'b1;
      16'b1100111010??????: match=1'b1;
      16'b1100111011??????: match=1'b1;
      16'b1100111100??????: match=1'b1;
      16'b1100111101??????: match=1'b1;
      16'b1100111110??????: match=1'b1;
      16'b1100111111??????: match=1'b1;
      16'b1101010110??????: match=1'b1;
      16'b1101010111??????: match=1'b1;
      16'b1101011100??????: match=1'b1;
      16'b1101011101??????: match=1'b1;
      16'b1101011110??????: match=1'b1;
      16'b1101011111??????: match=1'b1;
      16'b1101100100??????: match=1'b1;
      16'b1101100101??????: match=1'b1;
      16'b1101101110??????: match=1'b1;
      16'b1101110100??????: match=1'b1;
      16'b1101110101??????: match=1'b1;
      16'b1110001110??????: match=1'b1;
      16'b1110001111??????: match=1'b1;
      16'b1110010101??????: match=1'b1;
      16'b1110101000??????: match=1'b1;
      16'b1110101001??????: match=1'b1;
      16'b1110101101??????: match=1'b1;
      16'b1110110010??????: match=1'b1;
      16'b1110110011??????: match=1'b1;
      16'b1111000100??????: match=1'b1;
      16'b1111000101??????: match=1'b1;
      16'b1111001010??????: match=1'b1;
      16'b1111001011??????: match=1'b1;
      16'b1111001101??????: match=1'b1;
      16'b1111010000??????: match=1'b1;
      16'b1111010001??????: match=1'b1;
      16'b1111011110??????: match=1'b1;
      16'b1111011111??????: match=1'b1;
      16'b101110010???????: match=1'b1;
      16'b101110100???????: match=1'b1;
      16'b101110110???????: match=1'b1;
      16'b101111000???????: match=1'b1;
      16'b110000101???????: match=1'b1;
      16'b110001010???????: match=1'b1;
      16'b110010000???????: match=1'b1;
      16'b110010001???????: match=1'b1;
      16'b110010011???????: match=1'b1;
      16'b110010110???????: match=1'b1;
      16'b110101000???????: match=1'b1;
      16'b110101001???????: match=1'b1;
      16'b110101010???????: match=1'b1;
      16'b110101100???????: match=1'b1;
      16'b110101101???????: match=1'b1;
      16'b110110000???????: match=1'b1;
      16'b110110001???????: match=1'b1;
      16'b110110011???????: match=1'b1;
      16'b110110110???????: match=1'b1;
      16'b110111001???????: match=1'b1;
      16'b110111011???????: match=1'b1;
      16'b111000110???????: match=1'b1;
      16'b111001011???????: match=1'b1;
      16'b111001100???????: match=1'b1;
      16'b111010010???????: match=1'b1;
      16'b111010011???????: match=1'b1;
      16'b111011000???????: match=1'b1;
      16'b111100000???????: match=1'b1;
      16'b111100001???????: match=1'b1;
      16'b111100011???????: match=1'b1;
      16'b111100111???????: match=1'b1;
      16'b111101001???????: match=1'b1;
      16'b111101100???????: match=1'b1;
      16'b111101101???????: match=1'b1;
      16'b111101110???????: match=1'b1;
      16'b10111000????????: match=1'b1;
      16'b11000011????????: match=1'b1;
      16'b11000100????????: match=1'b1;
      16'b11001010????????: match=1'b1;
      16'b11001100????????: match=1'b1;
      16'b11001101????????: match=1'b1;
      16'b11010010????????: match=1'b1;
      16'b11010011????????: match=1'b1;
      16'b11100010????????: match=1'b1;
      16'b11100100????????: match=1'b1;
      16'b11100111????????: match=1'b1;
      16'b11101000????????: match=1'b1;
      16'b11101101????????: match=1'b1;
      16'b11110101????????: match=1'b1;
      16'b1100000?????????: match=1'b1;
      16'b1101000?????????: match=1'b1;
      16'b1101111?????????: match=1'b1;
      16'b1110000?????????: match=1'b1;
      16'b1110111?????????: match=1'b1;
      default: match=1'b0;
    endcase
  end
endmodule

module table_11000000(input [15:0] addr, output reg match);
  always@(addr) begin
    casex (addr)
      16'b10011110000111??: match=1'b1;
      default: match=1'b0;
    endcase
  end
endmodule

module ip_match(input clk, input [31:0] addr, output reg match);
  reg [31:0] addr_r;

  wire out_10000010;
  table_10000010 m_10000010 (.addr(addr_r[23:8]), .match(out_10000010));
  wire out_00010111;
  table_00010111 m_00010111 (.addr(addr_r[23:8]), .match(out_00010111));
  wire out_10100010;
  table_10100010 m_10100010 (.addr(addr_r[23:8]), .match(out_10100010));
  wire out_01101000;
  table_01101000 m_01101000 (.addr(addr_r[23:8]), .match(out_01101000));
  wire out_10101101;
  table_10101101 m_10101101 (.addr(addr_r[23:8]), .match(out_10101101));
  wire out_01101100;
  table_01101100 m_01101100 (.addr(addr_r[23:8]), .match(out_01101100));
  wire out_11000111;
  table_11000111 m_11000111 (.addr(addr_r[23:8]), .match(out_11000111));
  wire out_00001000;
  table_00001000 m_00001000 (.addr(addr_r[23:8]), .match(out_00001000));
  wire out_10010010;
  table_10010010 m_10010010 (.addr(addr_r[23:8]), .match(out_10010010));
  wire out_01101011;
  table_01101011 m_01101011 (.addr(addr_r[23:8]), .match(out_01101011));
  wire out_00100010;
  table_00100010 m_00100010 (.addr(addr_r[23:8]), .match(out_00100010));
  wire out_00100011;
  table_00100011 m_00100011 (.addr(addr_r[23:8]), .match(out_00100011));
  wire out_11000000;
  table_11000000 m_11000000 (.addr(addr_r[23:8]), .match(out_11000000));

  always@(posedge clk) begin 
    addr_r <= addr;
    case (addr_r[31:24])
      8'b10000010: match <= out_10000010;
      8'b00010111: match <= out_00010111;
      8'b10100010: match <= out_10100010;
      8'b01101000: match <= out_01101000;
      8'b10101101: match <= out_10101101;
      8'b01101100: match <= out_01101100;
      8'b11000111: match <= out_11000111;
      8'b00001000: match <= out_00001000;
      8'b10010010: match <= out_10010010;
      8'b01101011: match <= out_01101011;
      8'b00100010: match <= out_00100010;
      8'b00100011: match <= out_00100011;
      8'b11000000: match <= out_11000000;
      default: match <= 1'b0;
    endcase
  end
endmodule
