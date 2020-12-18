# TCL File Generated by Component Editor 18.1
# Fri Jul 05 14:43:55 PDT 2019
# DO NOT MODIFY


# 
# blk_match_ctrl_fsm "blk_match_ctrl_fsm" v1.0
#  2019.07.05.14:43:55
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module blk_match_ctrl_fsm
# 
set_module_property DESCRIPTION ""
set_module_property NAME blk_match_ctrl_fsm
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME blk_match_ctrl_fsm
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL block_match_ctrl_fsm_new
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file block_match_ctrl_fsm_new.sv SYSTEM_VERILOG PATH block_matching/block_match_ctrl_fsm_new.sv TOP_LEVEL_FILE

add_fileset SIM_VERILOG SIM_VERILOG "" ""
set_fileset_property SIM_VERILOG TOP_LEVEL block_match_ctrl_fsm_new
set_fileset_property SIM_VERILOG ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property SIM_VERILOG ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file block_match_ctrl_fsm_new.sv SYSTEM_VERILOG PATH block_matching/block_match_ctrl_fsm_new.sv


# 
# parameters
# 
add_parameter rd_port_w INTEGER 8
set_parameter_property rd_port_w DEFAULT_VALUE 8
set_parameter_property rd_port_w DISPLAY_NAME rd_port_w
set_parameter_property rd_port_w TYPE INTEGER
set_parameter_property rd_port_w UNITS None
set_parameter_property rd_port_w ALLOWED_RANGES -2147483648:2147483647
set_parameter_property rd_port_w HDL_PARAMETER true
add_parameter bit_frame_w INTEGER 960
set_parameter_property bit_frame_w DEFAULT_VALUE 960
set_parameter_property bit_frame_w DISPLAY_NAME bit_frame_w
set_parameter_property bit_frame_w TYPE INTEGER
set_parameter_property bit_frame_w UNITS None
set_parameter_property bit_frame_w ALLOWED_RANGES -2147483648:2147483647
set_parameter_property bit_frame_w HDL_PARAMETER true
add_parameter bit_frame_h INTEGER 540
set_parameter_property bit_frame_h DEFAULT_VALUE 540
set_parameter_property bit_frame_h DISPLAY_NAME bit_frame_h
set_parameter_property bit_frame_h TYPE INTEGER
set_parameter_property bit_frame_h UNITS None
set_parameter_property bit_frame_h ALLOWED_RANGES -2147483648:2147483647
set_parameter_property bit_frame_h HDL_PARAMETER true
add_parameter block_size INTEGER 16
set_parameter_property block_size DEFAULT_VALUE 16
set_parameter_property block_size DISPLAY_NAME block_size
set_parameter_property block_size TYPE INTEGER
set_parameter_property block_size UNITS None
set_parameter_property block_size ALLOWED_RANGES -2147483648:2147483647
set_parameter_property block_size HDL_PARAMETER true
add_parameter search_blk_w INTEGER 64
set_parameter_property search_blk_w DEFAULT_VALUE 64
set_parameter_property search_blk_w DISPLAY_NAME search_blk_w
set_parameter_property search_blk_w TYPE INTEGER
set_parameter_property search_blk_w UNITS None
set_parameter_property search_blk_w ALLOWED_RANGES -2147483648:2147483647
set_parameter_property search_blk_w HDL_PARAMETER true
add_parameter search_blk_h INTEGER 32
set_parameter_property search_blk_h DEFAULT_VALUE 32
set_parameter_property search_blk_h DISPLAY_NAME search_blk_h
set_parameter_property search_blk_h TYPE INTEGER
set_parameter_property search_blk_h UNITS None
set_parameter_property search_blk_h ALLOWED_RANGES -2147483648:2147483647
set_parameter_property search_blk_h HDL_PARAMETER true


# 
# display items
# 


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
# connection point img_number_sink
# 
add_interface img_number_sink avalon_streaming end
set_interface_property img_number_sink associatedClock clock
set_interface_property img_number_sink associatedReset reset
set_interface_property img_number_sink dataBitsPerSymbol 4
set_interface_property img_number_sink errorDescriptor ""
set_interface_property img_number_sink firstSymbolInHighOrderBits true
set_interface_property img_number_sink maxChannel 0
set_interface_property img_number_sink readyLatency 0
set_interface_property img_number_sink ENABLED true
set_interface_property img_number_sink EXPORT_OF ""
set_interface_property img_number_sink PORT_NAME_MAP ""
set_interface_property img_number_sink CMSIS_SVD_VARIABLES ""
set_interface_property img_number_sink SVD_ADDRESS_GROUP ""

add_interface_port img_number_sink img_number_in data Input 4


# 
# connection point left_control
# 
add_interface left_control conduit end
set_interface_property left_control associatedClock clock
set_interface_property left_control associatedReset reset
set_interface_property left_control ENABLED true
set_interface_property left_control EXPORT_OF ""
set_interface_property left_control PORT_NAME_MAP ""
set_interface_property left_control CMSIS_SVD_VARIABLES ""
set_interface_property left_control SVD_ADDRESS_GROUP ""

add_interface_port left_control srch_addr_left srch_addr Output 16
add_interface_port left_control bm_start_left start Output 1
add_interface_port left_control blk_index_left blk_index Output 16
add_interface_port left_control blk_addr_left blk_addr Output 16
add_interface_port left_control bm_done done Input 1


# 
# connection point right_control
# 
add_interface right_control conduit end
set_interface_property right_control associatedClock clock
set_interface_property right_control associatedReset reset
set_interface_property right_control ENABLED true
set_interface_property right_control EXPORT_OF ""
set_interface_property right_control PORT_NAME_MAP ""
set_interface_property right_control CMSIS_SVD_VARIABLES ""
set_interface_property right_control SVD_ADDRESS_GROUP ""

add_interface_port right_control srch_addr_right srch_addr Output 16
add_interface_port right_control bm_start_right start Output 1
add_interface_port right_control blk_addr_right blk_addr Output 16
add_interface_port right_control blk_index_right blk_index Output 16

