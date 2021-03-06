# TCL File Generated by Component Editor 18.1
# Sat Jan 09 17:24:32 PST 2021
# DO NOT MODIFY


# 
# bit_pixel_reader "bit_pixel_reader" v1.0
#  2021.01.09.17:24:32
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module bit_pixel_reader
# 
set_module_property DESCRIPTION ""
set_module_property NAME bit_pixel_reader
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME bit_pixel_reader
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL bit_pixel_reader
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file bit_pixel_reader.sv SYSTEM_VERILOG PATH block_matching/bit_pixel_reader.sv TOP_LEVEL_FILE

add_fileset SIM_VERILOG SIM_VERILOG "" ""
set_fileset_property SIM_VERILOG TOP_LEVEL bit_pixel_reader
set_fileset_property SIM_VERILOG ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property SIM_VERILOG ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file bit_pixel_reader.sv SYSTEM_VERILOG PATH block_matching/bit_pixel_reader.sv


# 
# parameters
# 
add_parameter third_width INTEGER 240
set_parameter_property third_width DEFAULT_VALUE 240
set_parameter_property third_width DISPLAY_NAME third_width
set_parameter_property third_width TYPE INTEGER
set_parameter_property third_width UNITS None
set_parameter_property third_width ALLOWED_RANGES -2147483648:2147483647
set_parameter_property third_width HDL_PARAMETER true
add_parameter third_height INTEGER 480
set_parameter_property third_height DEFAULT_VALUE 480
set_parameter_property third_height DISPLAY_NAME third_height
set_parameter_property third_height TYPE INTEGER
set_parameter_property third_height UNITS None
set_parameter_property third_height ALLOWED_RANGES -2147483648:2147483647
set_parameter_property third_height HDL_PARAMETER true
add_parameter center_width INTEGER 304
set_parameter_property center_width DEFAULT_VALUE 304
set_parameter_property center_width DISPLAY_NAME center_width
set_parameter_property center_width TYPE INTEGER
set_parameter_property center_width UNITS None
set_parameter_property center_width ALLOWED_RANGES -2147483648:2147483647
set_parameter_property center_width HDL_PARAMETER true


# 
# display items
# 


# 
# connection point clock_sink
# 
add_interface clock_sink clock end
set_interface_property clock_sink clockRate 0
set_interface_property clock_sink ENABLED true
set_interface_property clock_sink EXPORT_OF ""
set_interface_property clock_sink PORT_NAME_MAP ""
set_interface_property clock_sink CMSIS_SVD_VARIABLES ""
set_interface_property clock_sink SVD_ADDRESS_GROUP ""

add_interface_port clock_sink pclk clk Input 1


# 
# connection point reset_sink
# 
add_interface reset_sink reset end
set_interface_property reset_sink associatedClock clock_sink
set_interface_property reset_sink synchronousEdges DEASSERT
set_interface_property reset_sink ENABLED true
set_interface_property reset_sink EXPORT_OF ""
set_interface_property reset_sink PORT_NAME_MAP ""
set_interface_property reset_sink CMSIS_SVD_VARIABLES ""
set_interface_property reset_sink SVD_ADDRESS_GROUP ""

add_interface_port reset_sink pclk_reset reset Input 1


# 
# connection point centerleft_read_master
# 
add_interface centerleft_read_master conduit end
set_interface_property centerleft_read_master associatedClock clock_sink
set_interface_property centerleft_read_master associatedReset reset_sink
set_interface_property centerleft_read_master ENABLED true
set_interface_property centerleft_read_master EXPORT_OF ""
set_interface_property centerleft_read_master PORT_NAME_MAP ""
set_interface_property centerleft_read_master CMSIS_SVD_VARIABLES ""
set_interface_property centerleft_read_master SVD_ADDRESS_GROUP ""

add_interface_port centerleft_read_master rd_data_centerleft readdata Input 8
add_interface_port centerleft_read_master rd_address_centerleft address Output 16


# 
# connection point centerright_read_master
# 
add_interface centerright_read_master conduit end
set_interface_property centerright_read_master associatedClock clock_sink
set_interface_property centerright_read_master associatedReset reset_sink
set_interface_property centerright_read_master ENABLED true
set_interface_property centerright_read_master EXPORT_OF ""
set_interface_property centerright_read_master PORT_NAME_MAP ""
set_interface_property centerright_read_master CMSIS_SVD_VARIABLES ""
set_interface_property centerright_read_master SVD_ADDRESS_GROUP ""

add_interface_port centerright_read_master rd_address_centerright address Output 16
add_interface_port centerright_read_master rd_data_centerright readdata Input 8


# 
# connection point left_read_master
# 
add_interface left_read_master conduit end
set_interface_property left_read_master associatedClock clock_sink
set_interface_property left_read_master associatedReset reset_sink
set_interface_property left_read_master ENABLED true
set_interface_property left_read_master EXPORT_OF ""
set_interface_property left_read_master PORT_NAME_MAP ""
set_interface_property left_read_master CMSIS_SVD_VARIABLES ""
set_interface_property left_read_master SVD_ADDRESS_GROUP ""

add_interface_port left_read_master rd_address_left address Output 16
add_interface_port left_read_master rd_data_left readdata Input 8


# 
# connection point right_read_master
# 
add_interface right_read_master conduit end
set_interface_property right_read_master associatedClock clock_sink
set_interface_property right_read_master associatedReset reset_sink
set_interface_property right_read_master ENABLED true
set_interface_property right_read_master EXPORT_OF ""
set_interface_property right_read_master PORT_NAME_MAP ""
set_interface_property right_read_master CMSIS_SVD_VARIABLES ""
set_interface_property right_read_master SVD_ADDRESS_GROUP ""

add_interface_port right_read_master rd_address_right address Output 16
add_interface_port right_read_master rd_data_right readdata Input 8


# 
# connection point pixel_stream_source
# 
add_interface pixel_stream_source avalon_streaming start
set_interface_property pixel_stream_source associatedClock clock_sink
set_interface_property pixel_stream_source associatedReset reset_sink
set_interface_property pixel_stream_source dataBitsPerSymbol 8
set_interface_property pixel_stream_source errorDescriptor ""
set_interface_property pixel_stream_source firstSymbolInHighOrderBits true
set_interface_property pixel_stream_source maxChannel 0
set_interface_property pixel_stream_source readyLatency 0
set_interface_property pixel_stream_source ENABLED true
set_interface_property pixel_stream_source EXPORT_OF ""
set_interface_property pixel_stream_source PORT_NAME_MAP ""
set_interface_property pixel_stream_source CMSIS_SVD_VARIABLES ""
set_interface_property pixel_stream_source SVD_ADDRESS_GROUP ""

add_interface_port pixel_stream_source bit_pixels data Output 64
add_interface_port pixel_stream_source pixels_ready ready Input 1
add_interface_port pixel_stream_source pixels_valid valid Output 1


# 
# connection point conduit_end
# 
add_interface conduit_end conduit end
set_interface_property conduit_end associatedClock clock_sink
set_interface_property conduit_end associatedReset reset_sink
set_interface_property conduit_end ENABLED true
set_interface_property conduit_end EXPORT_OF ""
set_interface_property conduit_end PORT_NAME_MAP ""
set_interface_property conduit_end CMSIS_SVD_VARIABLES ""
set_interface_property conduit_end SVD_ADDRESS_GROUP ""

add_interface_port conduit_end image_number image_number Input 4

