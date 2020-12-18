# TCL File Generated by Component Editor 18.1
# Sun Jul 07 15:59:15 PDT 2019
# DO NOT MODIFY


# 
# ddr3_reader_fsm "ddr3_reader_fsm" v1.0
#  2019.07.07.15:59:15
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module ddr3_reader_fsm
# 
set_module_property DESCRIPTION ""
set_module_property NAME ddr3_reader_fsm
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME ddr3_reader_fsm
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL ddr3_reader_fsm
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file ddr3_reader_fsm.sv SYSTEM_VERILOG PATH block_matching/ddr3_reader_fsm.sv TOP_LEVEL_FILE

add_fileset SIM_VERILOG SIM_VERILOG "" ""
set_fileset_property SIM_VERILOG TOP_LEVEL ddr3_reader_fsm
set_fileset_property SIM_VERILOG ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property SIM_VERILOG ENABLE_FILE_OVERWRITE_MODE true
add_fileset_file ddr3_reader_fsm.sv SYSTEM_VERILOG PATH block_matching/ddr3_reader_fsm.sv


# 
# parameters
# 
add_parameter test_mode INTEGER 0
set_parameter_property test_mode DEFAULT_VALUE 0
set_parameter_property test_mode DISPLAY_NAME test_mode
set_parameter_property test_mode TYPE INTEGER
set_parameter_property test_mode UNITS None
set_parameter_property test_mode ALLOWED_RANGES -2147483648:2147483647
set_parameter_property test_mode HDL_PARAMETER true


# 
# display items
# 


# 
# connection point clock
# 
add_interface clock clock end
set_interface_property clock clockRate 0
set_interface_property clock ENABLED true
set_interface_property clock EXPORT_OF ""
set_interface_property clock PORT_NAME_MAP ""
set_interface_property clock CMSIS_SVD_VARIABLES ""
set_interface_property clock SVD_ADDRESS_GROUP ""

add_interface_port clock clk clk Input 1


# 
# connection point reset
# 
add_interface reset reset end
set_interface_property reset associatedClock clock
set_interface_property reset synchronousEdges BOTH
set_interface_property reset ENABLED true
set_interface_property reset EXPORT_OF ""
set_interface_property reset PORT_NAME_MAP ""
set_interface_property reset CMSIS_SVD_VARIABLES ""
set_interface_property reset SVD_ADDRESS_GROUP ""

add_interface_port reset reset reset Input 1


# 
# connection point cam_0_ptr_sink
# 
add_interface cam_0_ptr_sink avalon_streaming end
set_interface_property cam_0_ptr_sink associatedClock clock
set_interface_property cam_0_ptr_sink associatedReset reset
set_interface_property cam_0_ptr_sink dataBitsPerSymbol 2
set_interface_property cam_0_ptr_sink errorDescriptor ""
set_interface_property cam_0_ptr_sink firstSymbolInHighOrderBits true
set_interface_property cam_0_ptr_sink maxChannel 0
set_interface_property cam_0_ptr_sink readyLatency 0
set_interface_property cam_0_ptr_sink ENABLED true
set_interface_property cam_0_ptr_sink EXPORT_OF ""
set_interface_property cam_0_ptr_sink PORT_NAME_MAP ""
set_interface_property cam_0_ptr_sink CMSIS_SVD_VARIABLES ""
set_interface_property cam_0_ptr_sink SVD_ADDRESS_GROUP ""

add_interface_port cam_0_ptr_sink cam_0_ptr_data data Input 2
add_interface_port cam_0_ptr_sink cam_0_ptr_ready ready Output 1
add_interface_port cam_0_ptr_sink cam_0_ptr_valid valid Input 1


# 
# connection point cam_1_ptr_sink
# 
add_interface cam_1_ptr_sink avalon_streaming end
set_interface_property cam_1_ptr_sink associatedClock clock
set_interface_property cam_1_ptr_sink associatedReset reset
set_interface_property cam_1_ptr_sink dataBitsPerSymbol 2
set_interface_property cam_1_ptr_sink errorDescriptor ""
set_interface_property cam_1_ptr_sink firstSymbolInHighOrderBits true
set_interface_property cam_1_ptr_sink maxChannel 0
set_interface_property cam_1_ptr_sink readyLatency 0
set_interface_property cam_1_ptr_sink ENABLED true
set_interface_property cam_1_ptr_sink EXPORT_OF ""
set_interface_property cam_1_ptr_sink PORT_NAME_MAP ""
set_interface_property cam_1_ptr_sink CMSIS_SVD_VARIABLES ""
set_interface_property cam_1_ptr_sink SVD_ADDRESS_GROUP ""

add_interface_port cam_1_ptr_sink cam_1_ptr_data data Input 2
add_interface_port cam_1_ptr_sink cam_1_ptr_ready ready Output 1
add_interface_port cam_1_ptr_sink cam_1_ptr_valid valid Input 1


# 
# connection point cam_0_start
# 
add_interface cam_0_start conduit end
set_interface_property cam_0_start associatedClock clock
set_interface_property cam_0_start associatedReset ""
set_interface_property cam_0_start ENABLED true
set_interface_property cam_0_start EXPORT_OF ""
set_interface_property cam_0_start PORT_NAME_MAP ""
set_interface_property cam_0_start CMSIS_SVD_VARIABLES ""
set_interface_property cam_0_start SVD_ADDRESS_GROUP ""

add_interface_port cam_0_start cam_0_start start_addr Input 32


# 
# connection point cam_1_start
# 
add_interface cam_1_start conduit end
set_interface_property cam_1_start associatedClock clock
set_interface_property cam_1_start associatedReset ""
set_interface_property cam_1_start ENABLED true
set_interface_property cam_1_start EXPORT_OF ""
set_interface_property cam_1_start PORT_NAME_MAP ""
set_interface_property cam_1_start CMSIS_SVD_VARIABLES ""
set_interface_property cam_1_start SVD_ADDRESS_GROUP ""

add_interface_port cam_1_start cam_1_start start_addr Input 32


# 
# connection point read_addr_src
# 
add_interface read_addr_src avalon_streaming start
set_interface_property read_addr_src associatedClock clock
set_interface_property read_addr_src associatedReset reset
set_interface_property read_addr_src dataBitsPerSymbol 29
set_interface_property read_addr_src errorDescriptor ""
set_interface_property read_addr_src firstSymbolInHighOrderBits true
set_interface_property read_addr_src maxChannel 0
set_interface_property read_addr_src readyLatency 0
set_interface_property read_addr_src ENABLED true
set_interface_property read_addr_src EXPORT_OF ""
set_interface_property read_addr_src PORT_NAME_MAP ""
set_interface_property read_addr_src CMSIS_SVD_VARIABLES ""
set_interface_property read_addr_src SVD_ADDRESS_GROUP ""

add_interface_port read_addr_src read_addr_ready ready Input 1
add_interface_port read_addr_src read_addr_data data Output 29
add_interface_port read_addr_src read_addr_valid valid Output 1

