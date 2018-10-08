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
    output  reg ss,
    output  reg[3:0] led  //  LED is actually 4 discrete LEDs at 4 Output signals. Each LED Output is 1 bit.
);

//  The step ID that we are now executing: 0, 1, 2, ...
reg[`BLOCK_ROM_INIT_ADDR_WIDTH-1:0] step_id;
//  The step details, encoded in 48 bits.  This will be refetched whenever step_id changes.
wire[`BLOCK_ROM_INIT_DATA_WIDTH-1:0] encoded_step;
//  Whenever step_id is updated, fetch the encoded step from ROM.
SSD1306_ROM_cfg_mod oled_rom_init(
	.addr(step_id),
	.dout(encoded_step)
);

//  We define convenience wires to decode our encoded step.  Prefix by "step" so we don't mix up.
//  If encoded_step is changed, these will automatically change.
wire step_backward = encoded_step[47];  //  1 if next step is backwards i.e. a negative offset.
wire step_next = encoded_step[46:44];  //  Offset to the next step, i.e. 1=go to following step.  If step_backward=1, go backwards.
wire step_time = encoded_step[39:16];  //  Number of clk_ssd1306 clock cycles to wait before starting this step. This time is relative to the time of power on.
wire step_tx_data = encoded_step[15:8];  //  Data to be transmitted via SPI (1 byte).
wire step_should_repeat = encoded_step[7];  //  1 if step should be repeated.
wire step_repeat = { encoded_step[6:0], step_tx_data };  //  How many times the step should be repeated.  Only if step_should_repeat=1

wire step_oled_vdd = encoded_step[6];
wire step_oled_vbat = encoded_step[5];
wire step_oled_res = encoded_step[4];
wire step_oled_dc = encoded_step[3];
wire step_wr_spi = encoded_step[2];
wire step_rd_spi = encoded_step[1];
wire step_wait_spi = encoded_step[0];
wire buffempty;
wire charreceived;

reg wait_spi = 1'b0;
reg rd_spi = 1'b0;
reg wr_spi = 1'b0;				
reg[27:0] elapsed_time;
reg[27:0] saved_elapsed_time;
reg internal_state_machine;
reg[14:0] repeat_count;
reg clk_ssd1306;
reg[7:0] data_tmp;
reg[24:0] cnt;

/*
    reg [3:0]clk_div;
    wire clk;
    assign clk = (step_next) ? clk_div[3] : 1'b0;

    always @ (posedge clk_ssd1306)
    begin
        //if(btnc)
            //clk_div <= 4'h0;
        //else
            clk_div <= clk_div + 1;
    end
*/

always@(  //  Code below is always triggered when these conditions are true...
    posedge clk_50M or  //  When the clock signal transitions from low to high (positive edge) OR
    negedge rst_n       //  When the reset signal transitions from high to low (negative edge) which
    ) begin             //  happens when the board restarts or reset button is pressed.

    if (!rst_n) begin     //  If board restarts or reset button is pressed...
        clk_ssd1306 <= 1'b0;  //  Init clk_ssd1306 and cnt to 0. "1'b0" means "1-Bit, Binary Value 0"
        cnt <= 25'd0;     //  "25'd0" means "25-bit, Decimal Value 0"
    end
    else begin
        if (cnt == 25'd24_9999) begin  //  If our counter has reached its limit...
        //if (cnt == 25'd2499_9999) begin  //  If our counter has reached its limit...
            clk_ssd1306 <= ~clk_ssd1306;  //  Toggle the clk_led from 0 to 1 (and 1 to 0).
            cnt <= 25'd0;         //  Reset the counter to 0.
        end
        else begin
            cnt <= cnt + 25'd1;  //  Else increment counter by 1. "25'd1" means "25-bit, Decimal Value 1"
        end
    end
end

spi_master # (
.WORD_LEN(8),        //  Default 8
.PRESCALLER_SIZE(8)  //  Default 8, Max 8
)
spi0(
    .clk(clk_50M),
	////.clk(clk_ssd1306),
	.rst(rst_n),
	.data_in(step_tx_data),
	.data_out(data_tmp),
	.wr(wr_spi),
	.rd(rd_spi),
	.buffempty(buffempty),
	.prescaller(3'h2),
	.sck(oled_sclk),
	.mosi(oled_sdin),
	.miso(1'b1),
	.ss(ss),
	.lsbfirst(1'b0),
	.mode(2'h0),
	//.senderr(senderr),
	.res_senderr(1'b0),
	.charreceived(charreceived)
);

//  Synchronous lath to out commands directly from ROM except when is a repeat count load.
always @ (posedge clk_ssd1306)
begin
    if (!rst_n) begin     //  If board restarts or reset button is pressed...
        //  Init the SPI default values.
        oled_vdd <= 1'b1;
		oled_vbat <= 1'b1;
		oled_res <= 1'b0;
		oled_dc <= 1'b0;
		wr_spi <= 1'b0;
		rd_spi <= 1'b0;
		wait_spi <= 1'b0;
    end
    //  If this is not a repeated step...
    else if (!step_should_repeat) begin
        //  Copy the decoded values into registers so they won't change when we go to next step.
        oled_vdd <= step_oled_vdd;
        oled_vbat <= step_oled_vbat;
        oled_res <= step_oled_res;
        oled_dc <= step_oled_dc;
        wr_spi <= step_wr_spi;
        rd_spi <= step_rd_spi;
        wait_spi <= step_wait_spi;
    end
end

always @ (posedge clk_ssd1306)
begin
    if (!rst_n) begin     //  If board restarts or reset button is pressed...
        //  Init the state machine.
		elapsed_time <= 28'h0000000;
		saved_elapsed_time <= 28'h0000000;
		step_id <= `BLOCK_ROM_INIT_ADDR_WIDTH'h00;
		internal_state_machine <= 1'b0;
		repeat_count <= 15'h0000;
    end
    led <= { ~step_id[0], ~step_id[1], ~step_id[2], ~step_id[3] };  //  Show the state machine step ID in LED.

    //  If the start time is up and the step is ready to execute...
    if (elapsed_time >= step_time) begin
        case(internal_state_machine)
            //  Handle repeating steps.
            1'b0 : begin
                //  If this is a repeating step...
                if (step_should_repeat) begin
                    //  Remember in a register how many times to repeat.
                    repeat_count <= step_repeat;
                    //  Remember the elapsed time for recalling later.
                    saved_elapsed_time <= elapsed_time + 1;
                end
                //  If this is not a repeating step...
                else begin
                    //  If we are still repeating...
                    if (repeat_count && step_next > 1)
                        //  Count down number of times to repeat.
                        repeat_count <= repeat_count - 15'h0001;
                end
                internal_state_machine <= 1'b1;
            end
            //  Handle normal steps.
            1'b1 : begin
                //  If we are waiting for SPI command to complete...
                if (wait_spi) begin
                    //  If SPI command has completed...
                    if (charreceived) begin
                        internal_state_machine <= 1'b0;
                        //  If we are still repeating...
                        if (repeat_count) begin
                            //  Restore the elapsed time.
                            elapsed_time <= saved_elapsed_time;
                            //  Jump to the step we should repeat.
                            if (step_backward)
                                step_id <= step_id + ~step_next;
                            else
                                step_id <= step_id + step_next;
                        end
                        //  If we are not repeating, or repeat has completed...
                        else begin
                            elapsed_time <= elapsed_time + 1;
                            //  Move to following step.
                            step_id <= step_id + `BLOCK_ROM_INIT_ADDR_WIDTH'h1;
                        end
                    end
                    //  Else continue waiting for SPI command to complete.
                end
                //  Else we are not waiting for SPI command to complete...
                else begin
                    internal_state_machine <= 1'b0;
                    //  If we are still repeating...
                    if (repeat_count) begin
                        //  Restore the elapsed time.
                        elapsed_time <= saved_elapsed_time;
                        //  Jump to the step we should repeat.
                        if (step_backward)
                            step_id <= step_id + ~step_next;
                        else
                            step_id <= step_id + step_next;
                    end
                    //  If we are not repeating, or repeat has completed...
                    else begin
                        elapsed_time <= elapsed_time + 1;
                        //  Move to following step.
                        step_id <= step_id + `BLOCK_ROM_INIT_ADDR_WIDTH'h1;
                    end
                end
            end
        endcase
    end
    //  If the step start time has not been reached...
    else begin
        //  Wait until the step start time has elapsed.
        elapsed_time <= elapsed_time + 1;
    end
end

endmodule
