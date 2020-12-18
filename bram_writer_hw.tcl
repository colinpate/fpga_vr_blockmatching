# TCL File Generated by Component Editor 18.1
# Thu Nov 12 21:48:58 PST 2020
# DO NOT MODIFY


# 
# bram_writer "bram_writer" v1.0
#  2020.11.12.21:48:58
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module bram_writer
# 
set_module_property DESCRIPTION ""
set_module_property NAME bram_writer
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME bram_writer
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL bit_pixel_rotator_bram
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file bit_pixel_rotator_bram.sv SYSTEM_VERILOG PATH block_matching/bit_pixel_rotator_bram.sv
add_fileset_file bit_pix_fifo.v VERILOG PATH bit_pix_fifo.v

add_fileset SIM_VERILOG SIM_VERILOG "" ""
set_fileset_property SIM_VERILOG TOP_LEVEL bit_pixel_rotator_bram
set_fileset_property SIM_VERILOG ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property SIM_VERILOG ENABLE_FILE_OVERWRITE_MODE true
add_fileset_file bit_pixel_rotator_bram.sv SYSTEM_VERILOG PATH block_matching/bit_pixel_rotator_bram.sv
add_fileset_file bit_pix_fifo.v VERILOG PATH bit_pix_fifo.v


# 
# parameters
# 
add_parameter third_cols INTEGER 240
set_parameter_property third_cols DEFAULT_VALUE 240
set_parameter_property third_cols DISPLAY_NAME third_cols
set_parameter_property third_cols TYPE INTEGER
set_parameter_property third_cols UNITS None
set_parameter_property third_cols ALLOWED_RANGES -2147483648:2147483647
set_parameter_property third_cols HDL_PARAMETER true
add_parameter third_rows INTEGER 480
set_parameter_property third_rows DEFAULT_VALUE 480
set_parameter_property third_rows DISPLAY_NAME third_rows
set_parameter_property third_rows TYPE INTEGER
set_parameter_property third_rows UNITS None
set_parameter_property third_rows ALLOWED_RANGES -2147483648:2147483647
set_parameter_property third_rows HDL_PARAMETER true
add_parameter num_pix INTEGER 16
set_parameter_property num_pix DEFAULT_VALUE 16
set_parameter_property num_pix DISPLAY_NAME num_pix
set_parameter_property num_pix TYPE INTEGER
set_parameter_property num_pix ENABLED false
set_parameter_property num_pix UNITS None
set_parameter_property num_pix ALLOWED_RANGES -2147483648:2147483647
set_parameter_property num_pix HDL_PARAMETER true


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
# connection point avalon_master
# 
add_interface avalon_master avalon start
set_interface_property avalon_master addressUnits SYMBOLS
set_interface_property avalon_master associatedClock clock
set_interface_property avalon_master associatedReset reset
set_interface_property avalon_master bitsPerSymbol 16
set_interface_property avalon_master burstOnBurstBoundariesOnly false
set_interface_property avalon_master burstcountUnits WORDS
set_interface_property avalon_master doStreamReads false
set_interface_property avalon_master doStreamWrites false
set_interface_property avalon_master holdTime 0
set_interface_property avalon_master linewrapBursts false
set_interface_property avalon_master maximumPendingReadTransactions 0
set_interface_property avalon_master maximumPendingWriteTransactions 0
set_interface_property avalon_master readLatency 0
set_interface_property avalon_master readWaitTime 1
set_interface_property avalon_master setupTime 0
set_interface_property avalon_master timingUnits Cycles
set_interface_property avalon_master writeWaitTime 0
set_interface_property avalon_master ENABLED true
set_interface_property avalon_master EXPORT_OF ""
set_interface_property avalon_master PORT_NAME_MAP ""
set_interface_property avalon_master CMSIS_SVD_VARIABLES ""
set_interface_property avalon_master SVD_ADDRESS_GROUP ""

add_interface_port avalon_master pix_out writedata Output 16
add_interface_port avalon_master pix_out_wren write Output 1
add_interface_port avalon_master pix_out_addr address Output 19


# 
# connection point bit_pix_sink
# 
add_interface bit_pix_sink avalon_streaming end
set_interface_property bit_pix_sink associatedClock clock
set_interface_property bit_pix_sink associatedReset reset
set_interface_property bit_pix_sink dataBitsPerSymbol 24
set_interface_property bit_pix_sink errorDescriptor ""
set_interface_property bit_pix_sink firstSymbolInHighOrderBits true
set_interface_property bit_pix_sink maxChannel 0
set_interface_property bit_pix_sink readyLatency 0
set_interface_property bit_pix_sink ENABLED true
set_interface_property bit_pix_sink EXPORT_OF ""
set_interface_property bit_pix_sink PORT_NAME_MAP ""
set_interface_property bit_pix_sink CMSIS_SVD_VARIABLES ""
set_interface_property bit_pix_sink SVD_ADDRESS_GROUP ""

add_interface_port bit_pix_sink bit_pix data Input 24
add_interface_port bit_pix_sink bit_pix_valid valid Input 1


# 
# connection point fifo_almost_full_source
# 
add_interface fifo_almost_full_source avalon_streaming start
set_interface_property fifo_almost_full_source associatedClock clock
set_interface_property fifo_almost_full_source associatedReset reset
set_interface_property fifo_almost_full_source dataBitsPerSymbol 1
set_interface_property fifo_almost_full_source errorDescriptor ""
set_interface_property fifo_almost_full_source firstSymbolInHighOrderBits true
set_interface_property fifo_almost_full_source maxChannel 0
set_interface_property fifo_almost_full_source readyLatency 0
set_interface_property fifo_almost_full_source ENABLED true
set_interface_property fifo_almost_full_source EXPORT_OF ""
set_interface_property fifo_almost_full_source PORT_NAME_MAP ""
set_interface_property fifo_almost_full_source CMSIS_SVD_VARIABLES ""
set_interface_property fifo_almost_full_source SVD_ADDRESS_GROUP ""

add_interface_port fifo_almost_full_source fifo_almost_full data Output 1


# 
# connection point avalon_streaming_source
# 
add_interface avalon_streaming_source avalon_streaming start
set_interface_property avalon_streaming_source associatedClock clock
set_interface_property avalon_streaming_source associatedReset reset
set_interface_property avalon_streaming_source dataBitsPerSymbol 4
set_interface_property avalon_streaming_source errorDescriptor ""
set_interface_property avalon_streaming_source firstSymbolInHighOrderBits true
set_interface_property avalon_streaming_source maxChannel 0
set_interface_property avalon_streaming_source readyLatency 0
set_interface_property avalon_streaming_source ENABLED true
set_interface_property avalon_streaming_source EXPORT_OF ""
set_interface_property avalon_streaming_source PORT_NAME_MAP ""
set_interface_property avalon_streaming_source CMSIS_SVD_VARIABLES ""
set_interface_property avalon_streaming_source SVD_ADDRESS_GROUP ""

add_interface_port avalon_streaming_source image_number data Output 4

