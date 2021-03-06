# TCL File Generated by Component Editor 18.1
# Sun Nov 08 14:20:27 PST 2020
# DO NOT MODIFY


# 
# gray_vertical_filter_bank "gray_vertical_filter_bank" v1.0
#  2020.11.08.14:20:27
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module gray_vertical_filter_bank
# 
set_module_property DESCRIPTION ""
set_module_property NAME gray_vertical_filter_bank
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME gray_vertical_filter_bank
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL gray_vertical_filter_bank
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file gray_vertical_filter_bank.sv SYSTEM_VERILOG PATH block_matching/gray_vertical_filter_bank.sv TOP_LEVEL_FILE
add_fileset_file local_average_filter_v2.sv SYSTEM_VERILOG PATH gray_in/local_average_filter_v2.sv
add_fileset_file local_average_pad_v2.sv SYSTEM_VERILOG PATH gray_in/local_average_pad_v2.sv


# 
# parameters
# 
add_parameter n_filters INTEGER 16
set_parameter_property n_filters DEFAULT_VALUE 16
set_parameter_property n_filters DISPLAY_NAME n_filters
set_parameter_property n_filters TYPE INTEGER
set_parameter_property n_filters UNITS None
set_parameter_property n_filters ALLOWED_RANGES -2147483648:2147483647
set_parameter_property n_filters HDL_PARAMETER true
add_parameter radius INTEGER 8
set_parameter_property radius DEFAULT_VALUE 8
set_parameter_property radius DISPLAY_NAME radius
set_parameter_property radius TYPE INTEGER
set_parameter_property radius UNITS None
set_parameter_property radius ALLOWED_RANGES -2147483648:2147483647
set_parameter_property radius HDL_PARAMETER true
add_parameter frame_lines INTEGER 480
set_parameter_property frame_lines DEFAULT_VALUE 480
set_parameter_property frame_lines DISPLAY_NAME frame_lines
set_parameter_property frame_lines TYPE INTEGER
set_parameter_property frame_lines UNITS None
set_parameter_property frame_lines ALLOWED_RANGES -2147483648:2147483647
set_parameter_property frame_lines HDL_PARAMETER true


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
set_interface_property reset synchronousEdges DEASSERT
set_interface_property reset ENABLED true
set_interface_property reset EXPORT_OF ""
set_interface_property reset PORT_NAME_MAP ""
set_interface_property reset CMSIS_SVD_VARIABLES ""
set_interface_property reset SVD_ADDRESS_GROUP ""

add_interface_port reset reset reset Input 1


# 
# connection point avalon_streaming_source
# 
add_interface avalon_streaming_source avalon_streaming start
set_interface_property avalon_streaming_source associatedClock clock
set_interface_property avalon_streaming_source associatedReset reset
set_interface_property avalon_streaming_source dataBitsPerSymbol 24
set_interface_property avalon_streaming_source errorDescriptor ""
set_interface_property avalon_streaming_source firstSymbolInHighOrderBits true
set_interface_property avalon_streaming_source maxChannel 0
set_interface_property avalon_streaming_source readyLatency 0
set_interface_property avalon_streaming_source ENABLED true
set_interface_property avalon_streaming_source EXPORT_OF ""
set_interface_property avalon_streaming_source PORT_NAME_MAP ""
set_interface_property avalon_streaming_source CMSIS_SVD_VARIABLES ""
set_interface_property avalon_streaming_source SVD_ADDRESS_GROUP ""

add_interface_port avalon_streaming_source bit_pixels data Output 24
add_interface_port avalon_streaming_source bit_pixels_valid valid Output 1


# 
# connection point avalon_streaming_sink
# 
add_interface avalon_streaming_sink avalon_streaming end
set_interface_property avalon_streaming_sink associatedClock clock
set_interface_property avalon_streaming_sink associatedReset reset
set_interface_property avalon_streaming_sink dataBitsPerSymbol 264
set_interface_property avalon_streaming_sink errorDescriptor ""
set_interface_property avalon_streaming_sink firstSymbolInHighOrderBits true
set_interface_property avalon_streaming_sink maxChannel 0
set_interface_property avalon_streaming_sink readyLatency 0
set_interface_property avalon_streaming_sink ENABLED true
set_interface_property avalon_streaming_sink EXPORT_OF ""
set_interface_property avalon_streaming_sink PORT_NAME_MAP ""
set_interface_property avalon_streaming_sink CMSIS_SVD_VARIABLES ""
set_interface_property avalon_streaming_sink SVD_ADDRESS_GROUP ""

add_interface_port avalon_streaming_sink pixel_in data Input 264
add_interface_port avalon_streaming_sink pixel_in_valid valid Input 1

