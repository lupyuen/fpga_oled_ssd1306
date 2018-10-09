# fpga_oled_ssd1306
FPGA controller for SSD1306 OLED module on SPI. Optimised for GOWIN FPGA

Based on:

https://github.com/MorgothCreator/Verilog_SSD1306_CFG_IP

https://git.morgothdisk.com/VERILOG/VERILOG-UTIL-IP/blob/master/spi_master.v

## LED Connections

|  FPGA Pin (J8)  | FPGA Function | OLED Pin | Function | Description |
|-----------------|---------------|----------|----------|-------------|
| 1 (Red)         |               | VCC         | 3.3 to 5.0 volts | Supply voltage (up to 20 mA) |
| 2 (Black)       |               | Gnd         | Ground           | Common return path |
| 3 (Green)       | oled_dc       | DC          | Data / Command   | Data (high), Command (low) |
| 4 (Yellow)      | oled_res      | RES         | Reset            | Reset signal (active low) |
| 5 (Orange)      | oled_sclk     | D0 (or SCK) | SCK              | SPI system clock |
| 6 (Brown/White) | oled_sdin     | D1 (or SDA) | SDIN             | SPI MOSI (system data in for OLED) |
| 7               | ss            | CS          | ChipSelect       | Chip select (active low) |

Excerpt From: Warren Gay. “Beginning STM32.” iBooks. 
  
## VDD, VCC, VBAT

>VDD is the 3.3V logic power. This must be 3 or 3.3V

>VBAT is the input to the charge pump. If you use the charge pump, this must be 3.3V to 4.2V

>VCC is the high voltage OLED pin. If you're using the internal charge pump, this must be left unconnected. 

>If you're not using the charge pump, connect this to a 7-9V DC power supply.
For most users, we suggest connecting VDD and VBAT together to 3.3V and then leaving VCC unconnected.

https://learn.adafruit.com/monochrome-oled-breakouts?view=all

Display needs 20 mA, hence VBAT and VDD have been configured to output 24 mA

## FPGA Power

>Input DC5V power supply via USB port or socket. Input via socket if the
SW1 switch is pressed; input via USB port if the SW1 switch pops up.

## Internal Flash

>1. SRAM:
Scan the device and download the bit file after powering the device on.
The Done indicator lights up to denote that the download has been
successful.
Note!
The mode is independent of the values of MODE0 and MODE1.
>2. Internal Flash:
Power on to download. After downloading the data stream file
successfully, power down to reset and load the bit file from the internal
Flash, and when the Done indicator lights up to denote that the download
has been successful.
Note!
Before downloading the bit file, MODE0 and MODE1 need to set to
"00".
