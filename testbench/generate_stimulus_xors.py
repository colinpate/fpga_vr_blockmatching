# -*- coding: utf-8 -*-
"""
Created on Fri Dec 18 18:27:13 2020

@author: Colin
"""

#import opencv2 as cv2
import numpy as np

third_width = 240
third_height = 480
srch_inc_x = 1
srch_inc_y = 1
blk_width = 16
blk_height = 16
srch_blk_width = 48
srch_blk_height = 24

array_left = np.random.rand(third_height, third_width) * 2
array_left = array_left.astype(np.int8)
array_right = np.random.rand(third_height, third_width) * 2
array_right = array_right.astype(np.int8)
array_center = np.random.rand(third_height, third_width) * 2
array_center = array_center.astype(np.int8)
#print(array_center[0,:8])
#print(array_center[0,8:16])
#print(array_center[0,16:24])
#print(array_center[0,24:32])

def array_to_file(these_arrays, outname="stimulus_in_xor.bin"):
    with open("../../modelsim/" + outname, "wb") as fileout:
        for this_array in these_arrays:
            array_index = 0
            while array_index < len(this_array.flatten()):
                this_byte = 0
                for i in range(8):
                    try:
                        this_byte += int(this_array.flatten()[array_index]) << i
                    except:
                        print("bad")
                        print(this_array.flatten()[array_index])
                    array_index += 1
                byte_out = int(this_byte).to_bytes(1, "little")
                fileout.write(byte_out)

out_count = 0

array_list = []

for srch_y in range(0, third_height - srch_blk_height, blk_height):
    for srch_x in range(0, third_width, blk_width):
        out_count += 1
        y_coord = int(srch_y)
        r_blk_coord = srch_x
        right_block = array_right[y_coord:y_coord+blk_height,r_blk_coord:r_blk_coord+blk_width]
        array_list.append(right_block)
        
        
dec_factor = 2
smol_array = np.zeros((0))
for smol_y in range(0, third_height, dec_factor):
    for smol_x in range(0, third_width, dec_factor):
        smol_block = array_right[smol_y:smol_y+dec_factor,smol_x:smol_x+dec_factor].copy()
        smol_array = np.concatenate((smol_array, smol_block.flatten()))
    
    
array_to_file([smol_array], outname="compare_out_r.bin")
array_to_file(array_list)
print(array_list[0][0,:16])
print(smol_array[:16])
print(array_list[0][:2,:2])
print(array_list[0][:2,2:4])
print(array_list[0][:2,4:6])
print(array_list[0][:2,6:8])
        
min_l_file.close()
min_r_file.close()
        