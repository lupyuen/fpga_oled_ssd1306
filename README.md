# fpga_oled_ssd1306
FPGA controller for SSD1306 OLED module on SPI. Optimised for GOWIN FPGA

Based on:

https://github.com/MorgothCreator/Verilog_SSD1306_CFG_IP

https://git.morgothdisk.com/VERILOG/VERILOG-UTIL-IP/blob/master/spi_master.v

## LED Connections

|  FPGA Pin (J8)  | FPGA Function | OLED Pin | Bus Pirate | Function | Description |
|-----------------|---------------|----------|------------|----------|-------------|
| 1 (Red)         |               | VCC         | 3.3V | 3.3 to 5.0 volts | Supply voltage (up to 20 mA) |
| 2 (Black)       |               | Gnd         | GND  | Ground           | Common return path |
| 3 (Green)       | oled_dc       | DC          | AUX1 | Data / Command   | Data (high, `kA`), Command (low, `ka`) |
| 4 (Yellow)      | oled_res      | RES         | AUX  | Reset            | Reset signal (active low). Normally should be high (BP: `cA`) |
| 5 (Orange)      | oled_sclk     | D0 (or SCK) | CLK  | SCK              | SPI system clock |
| 6 (Brown/White) | oled_sdin     | D1 (or SDA) | MOSI | SDIN             | SPI MOSI (system data in for OLED) |
| 7               | ss            | CS          | CS   | ChipSelect       | Chip select (active low) |

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

## BME280 SPI With Bus Pirate

```
HiZ>menu
1. HiZ
2. 1-WIRE
3. UART
4. I2C
5. SPI
6. 2WIRE
7. 3WIRE
8. KEYB
9. LCD
10. PIC
11. DIO
x. exit(without change)

(1)>5
Set speed:
 1. 30KHz
 2. 125KHz
 3. 250KHz
 4. 1MHz

(1)>
Clock polarity:
 1. Idle low *default
 2. Idle high

(1)>
Output clock edge:
 1. Idle to active
 2. Active to idle *default

(2)>
Input sample phase:
 1. Middle *default
 2. End

(1)>
CS:
 1. CS
 2. /CS *default

(2)>
Select output type:
 1. Open drain (H=Hi-Z, L=GND)
 2. Normal (H=3.3V, L=GND)

(1)>
Clutch disengaged!!!
To finish setup, start up the power supplies with command 'W'

Ready
SPI>v
Pinstates:
#12     #11     #10     #09     #08     #07     #06     #05     #04     #03     #02     #01
GND     5.0V    3.3V    VPU     ADC     AUX2    AUX1    AUX     CS      MISO    CLK     MOSI
P       P       P       I       I       I       I       I       I       I       I       I
GND     0.00V   0.00V   0.00V   0.00V   L       L       L       L       L       L       L
SPI>i
Bus Pirate v4
Community Firmware v7.0 - goo.gl/gCzQnW [HiZ 1-WIRE UART I2C SPI 2WIRE 3WIRE KEYB LCD PIC DIO]
DEVID:0x1019 REVID:0x0004 (24FJ256GB106 UNK)
http://dangerousprototypes.com
CFG0: 0xFFFF CFG1:0xFFFF CFG2:0xFFFF
*----------*
Pinstates:
#12     #11     #10     #09     #08     #07     #06     #05     #04     #03     #02     #01
GND     5.0V    3.3V    VPU     ADC     AUX2    AUX1    AUX     CS      MISO    CLK     MOSI
P       P       P       I       I       I       I       I       I       I       I       I
GND     0.00V   0.00V   0.00V   0.00V   L       L       L       L       L       L       L
POWER SUPPLIES OFF, Pull-up resistors OFF, Open drain outputs (H=Hi-Z, L=GND)
MSB set: MOST sig bit first, Number of bits read/write: 8
a/A/@ controls CS pin
SPI (spd ckp ske smp csl hiz)=( 1 0 1 0 1 1 )
*----------*
SPI>W
POWER SUPPLIES ON
Clutch engaged!!!
SPI>i
Bus Pirate v4
Community Firmware v7.0 - goo.gl/gCzQnW [HiZ 1-WIRE UART I2C SPI 2WIRE 3WIRE KEYB LCD PIC DIO]
DEVID:0x1019 REVID:0x0004 (24FJ256GB106 UNK)
http://dangerousprototypes.com
CFG0: 0xFFFF CFG1:0xFFFF CFG2:0xFFFF
*----------*
Pinstates:
#12     #11     #10     #09     #08     #07     #06     #05     #04     #03     #02     #01
GND     5.0V    3.3V    VPU     ADC     AUX2    AUX1    AUX     CS      MISO    CLK     MOSI
P       P       P       I       I       I       I       I       O       I       O       O
GND     4.97V   3.29V   0.00V   0.00V   L       L       L       H       H       L       L
POWER SUPPLIES ON, Pull-up resistors OFF, Open drain outputs (H=Hi-Z, L=GND)
MSB set: MOST sig bit first, Number of bits read/write: 8
a/A/@ controls CS pin
SPI (spd ckp ske smp csl hiz)=( 1 0 1 0 1 1 )
*----------*
SPI>[0xd0]
/CS ENABLED
WRITE: 0xD0
/CS DISABLED
SPI>?
General                                 Protocol interaction
---------------------------------------------------------------------------
?       This help                       (0)     List current macros
=X/|X   Converts X/reverse X            (x)     Macro x
~       Selftest                        [       Start
o       Set output type                 ]       Stop
$       Jump to bootloader              {       Start with read
&/%     Delay 1 us/ms                   }       Stop
a/A/@   AUXPIN (low/HI/READ)            "abc"   Send string
b       Set baudrate                    123     Send integer value
c/C/k/K AUX assignment (A0/CS/A1/A2)    0x123   Send hex value
d/D     Measure ADC (once/CONT.)        0b110   Send binary value
f       Measure frequency               r       Read
g/S     Generate PWM/Servo              /       CLK hi
h       Commandhistory                  \       CLK lo
i       Versioninfo/statusinfo          ^       CLK tick
l/L     Bitorder (msb/LSB)              -       DAT hi
m       Change mode                     _       DAT lo
e       Set Pullup Method               .       DAT read
p/P     Pullup resistors (off/ON)       !       Bit read
s       Script engine                   :       Repeat e.g. r:10
v       Show volts/states               ;       Bits to read/write e.g. 0x55;2
w/W     PSU (off/ON)            <x>/<x= >/<0>   Usermacro x/assign x/list all
SPI>r
READ: 0xFF
SPI>{0xd0}
/CS ENABLED
WRITE: 0xD0 READ: 0xFF
/CS DISABLED
SPI>{0x60}
/CS ENABLED
WRITE: 0x60 READ: 0xFF
/CS DISABLED
SPI>[0x60]
/CS ENABLED
WRITE: 0x60
/CS DISABLED
SPI>r
READ: 0xFF
SPI>[0x0]
/CS ENABLED
WRITE: 0x00
/CS DISABLED
SPI>[0xd0]
/CS ENABLED
WRITE: 0xD0
/CS DISABLED
SPI>[0xd0 r]
/CS ENABLED
WRITE: 0xD0
READ: 0x60
/CS DISABLED
SPI>
```

`0x60` is the device ID read from BME280
