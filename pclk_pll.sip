set_global_assignment -entity "pclk_pll" -library "lib_pclk_pll" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "pclk_pll" -library "lib_pclk_pll" -name IP_TOOL_VERSION "18.1"
set_global_assignment -entity "pclk_pll" -library "lib_pclk_pll" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_pclk_pll" -name SPD_FILE [file join $::quartus(sip_path) "pclk_pll.spd"]

set_global_assignment -library "lib_pclk_pll" -name MISC_FILE [file join $::quartus(sip_path) "pclk_pll_sim/pclk_pll.vo"]
