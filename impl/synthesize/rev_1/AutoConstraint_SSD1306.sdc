
#Begin clock constraint
define_clock -name {SSD1306|clk_50M} {p:SSD1306|clk_50M} -period 10.000 -clockgroup Autoconstr_clkgroup_0 -rise 0.000 -fall 5.000 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {SSD1306|clk_ssd1306_derived_clock} {n:SSD1306|clk_ssd1306_derived_clock} -period 10.000 -clockgroup Autoconstr_clkgroup_0 -rise 0.000 -fall 5.000 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {SSD1306|rd_spi_derived_clock} {n:SSD1306|rd_spi_derived_clock} -period 10.000 -clockgroup Autoconstr_clkgroup_0 -rise 0.000 -fall 5.000 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {SSD1306|wr_spi_derived_clock} {n:SSD1306|wr_spi_derived_clock} -period 10.000 -clockgroup Autoconstr_clkgroup_0 -rise 0.000 -fall 5.000 -route 0.000 
#End clock constraint
