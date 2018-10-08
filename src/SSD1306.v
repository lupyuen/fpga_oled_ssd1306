//  Based on https://github.com/MorgothCreator/Verilog_SSD1306_CFG_IP
//  and https://git.morgothdisk.com/VERILOG/VERILOG-UTIL-IP/blob/master/spi_master.
`include "SSD1306_ROM_cfg_mod_header.v"

// Commands for SSD1306
`define SSD1306_SETCONTRAST				81
`define SSD1306_DISPLAYALLON_RESUME		A4
`define SSD1306_DISPLAYALLON			A5
`define SSD1306_NORMALDISPLAY			A6
`define SSD1306_INVERTDISPLAY			A7
`define SSD1306_DISPLAYOFF				AE
`define SSD1306_DISPLAYON				AF
`define SSD1306_SETDISPLAYOFFSET		D3
`define SSD1306_SETCOMPINS				DA
`define SSD1306_SETVCOMDETECT			DB
`define SSD1306_SETDISPLAYCLOCKDIV		D5
`define SSD1306_SETPRECHARGE			D9
`define SSD1306_SETMULTIPLEX			A8
`define SSD1306_SETLOWCOLUMN			00
`define SSD1306_SETHIGHCOLUMN			10
`define SSD1306_SETSTARTLINE			40
`define SSD1306_MEMORYMODE				20
`define SSD1306_COMSCANINC				C0
`define SSD1306_COMSCANDEC				C8
`define SSD1306_SEGREMAP				A0
`define SSD1306_CHARGEPUMP				8D
`define SSD1306_EXTERNALVCC				01
`define SSD1306_INTERNALVCC				02
`define SSD1306_SWITCHCAPVCC			02

module	SSD1306(
    input   clk_50M,  //  Onboard clock is 50MHz.
    input   rst_n,    //  Reset pin is also an Input, triggered by board restart or reset button.
	output	reg oled_dc,
	output	reg oled_res,
	output	oled_sclk,
	output	oled_sdin,
	output	reg oled_vbat,
	output	reg oled_vdd,
    output  reg[3:0] led  //  LED is actually 4 discrete LEDs at 4 Output signals. Each LED Output is 1 bit.
);

reg wait_spi;
reg rd_spi;
reg wr_spi;
				
wire buffempty;
wire charreceived;

reg [27:0]time_count;
reg [27:0]time_count_back;
reg [`BLOCK_ROM_INIT_ADDR_WIDTH-1:0]state_machine_count;
wire [`BLOCK_ROM_INIT_DATA_WIDTH-1:0]rom_bus;

reg internal_state_machine;
reg [14:0]repeat_count;

reg clk_ssd1306;
reg [7:0]data_tmp;
reg [24:0]cnt;

/*
reg [3:0]clk_div;
wire clk;
assign clk = (rom_bus[46:44]) ? clk_div[3] : 1'b0;

always @ (posedge clk_ssd1306)
begin
	//if(btnc)
		//clk_div <= 4'h0;
	//else
		clk_div <= clk_div + 1;
end
*/

always@(                //  Code below is always triggered when these conditions are true...
    posedge clk_50M or  //  When the clock signal transitions from low to high (positive edge) OR
    negedge rst_n       //  When the reset signal transitions from high to low (negative edge) which
    ) begin             //  happens when the board restarts or reset button is pressed.

    if (!rst_n) begin     //  If board restarts or reset button is pressed...
        clk_ssd1306 <= 1'b0;  //  Init clk_ssd1306 and cnt to 0. "1'b0" means "1-Bit, Binary Value 0"
        cnt <= 25'd0;     //  "25'd0" means "25-bit, Decimal Value 0"
    end
    else begin
        if (cnt == 25'd2499_9999) begin  //  If our counter has reached its limit...
            clk_ssd1306 <= ~clk_ssd1306;  //  Toggle the clk_led from 0 to 1 (and 1 to 0).
            cnt <= 25'd0;         //  Reset the counter to 0.
        end
        else begin
            cnt <= cnt + 25'd1;  //  Else increment counter by 1. "25'd1" means "25-bit, Decimal Value 1"
        end
    end
end

SSD1306_ROM_cfg_mod oled_rom_init(
	.addr(state_machine_count),
	.dout(rom_bus)
);

spi_master	#	(
.WORD_LEN(8),/*	Default	8	*/
.PRESCALLER_SIZE(8)/*	Default	8	/	Max	8*/
)
spi0(
	.clk(clk_ssd1306),
	.rst(btnc),
	.data_in(rom_bus[15:8]),
	.data_out(data_tmp),
	.wr(wr_spi),
	.rd(rd_spi),
	.buffempty(buffempty),
	.prescaller(3'h2),
	.sck(oled_sclk),
	.mosi(oled_sdin),
	.miso(1'b1),
	//.ss(ss),
	.lsbfirst(1'b0),
	.mode(2'h0),
	//.senderr(senderr),
	.res_senderr(1'b0),
	.charreceived(charreceived)
);

/* Synchronous lath to out commands directly from ROM except when is a repeat count load. */
always @ (posedge clk_ssd1306)
begin
    if(!rom_bus[7]) begin
        oled_vdd <= rom_bus[6];
        oled_vbat <= rom_bus[5];
        oled_res <= rom_bus[4];
        oled_dc <= rom_bus[3];
        wr_spi <= rom_bus[2];
        rd_spi <= rom_bus[1];
        wait_spi <= rom_bus[0];
    end
end

always @ (posedge clk_ssd1306)
begin
    if (!rst_n) begin     //  If board restarts or reset button is pressed...
        //  Init the state machine.
		time_count <= 28'h0000000;
		time_count_back <= 28'h0000000;
		state_machine_count <= `BLOCK_ROM_INIT_ADDR_WIDTH'h00;
		internal_state_machine <= 1'b0;
		repeat_count <= 15'h0000;
    end

    //led <= state_machine_count[3:0];  //  Show the state machine count in LED.
    led <= { ~state_machine_count[3], ~state_machine_count[2], ~state_machine_count[1], ~state_machine_count[0] };  //  Show the state machine time count in LED.
    if(rom_bus[39:16] == time_count) begin
        case(internal_state_machine)
            1'b0 : begin
                if(rom_bus[7]) begin
                    repeat_count <= {rom_bus[6:0], rom_bus[15:8]};
                    time_count_back <= time_count + 1;
                end
                else begin
                    if(repeat_count && rom_bus[46:44] > 1)
                        repeat_count <= repeat_count - 15'h0001;
                end
                internal_state_machine <= 1'b1;
            end
            1'b1 : begin
                if(wait_spi) begin
                    if(charreceived) begin
                        internal_state_machine <= 1'b0;
                        if(repeat_count) begin
                            time_count <= time_count_back;
                            if(rom_bus[47])
                                state_machine_count <= state_machine_count + ~rom_bus[46:44];
                            else
                                state_machine_count <= state_machine_count + rom_bus[46:44];
                        end
                        else begin
                            time_count <= time_count + 1;
                            state_machine_count <= state_machine_count + `BLOCK_ROM_INIT_ADDR_WIDTH'h01;
                        end
                    end
                end
                else begin
                    internal_state_machine <= 1'b0;
                    if (repeat_count) begin
                        time_count <= time_count_back;
                        if(rom_bus[47])
                            state_machine_count <= state_machine_count + ~rom_bus[46:44];
                        else
                            state_machine_count <= state_machine_count + rom_bus[46:44];
                    end
                    else begin
                        time_count <= time_count + 1;
                        state_machine_count <= state_machine_count + `BLOCK_ROM_INIT_ADDR_WIDTH'h1;
                    end
                end
            end
        endcase
    end
    else begin
        time_count <= time_count + 1;
    end
end

endmodule
