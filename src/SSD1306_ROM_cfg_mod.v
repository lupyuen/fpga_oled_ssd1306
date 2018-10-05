`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/30/2017 06:40:30 PM
// Design Name: 
// Module Name: SSD1306_ROM_cfg_mod
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "SSD1306_ROM_cfg_mod_header.v"

module SSD1306_ROM_cfg_mod(
    input [`BLOCK_ROM_INIT_ADDR_WIDTH-1:0] addr,
	output [`BLOCK_ROM_INIT_DATA_WIDTH-1:0] dout
);

parameter FILENAME="SSD1306_ROM_script.mem";
localparam LENGTH=2**`BLOCK_ROM_INIT_ADDR_WIDTH;
reg [`BLOCK_ROM_INIT_DATA_WIDTH-1:0] mem [LENGTH-1:0];
initial $readmemh(FILENAME, mem);
assign dout = mem[addr];

endmodule

