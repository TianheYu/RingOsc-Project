create_pblock ay; 
add_cells_to_pblock [get_pblocks ay] [get_cells -quiet [list design_1_i/processing_system7_0_axi_periph]]
resize_pblock [get_pblocks ay] -add {SLICE_X26Y0:SLICE_X31Y149}