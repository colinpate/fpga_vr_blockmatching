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
                #print(this_byte)
                byte_out = int(this_byte).to_bytes(1, "little")
                #print(byte_out)
                fileout.write(byte_out)
#array_to_file([array_left, array_center, array_right])

"""def find_best_coords(block, srch_block):
    min_diff = blk_width * blk_height * 200000
    for y in range(0, srch_blk_height - blk_height, srch_inc_y):
        for x in range(0, srch_blk_width - blk_width, srch_inc_x):
            srch_blk_area = srch_block[y:y+blk_height, x:x+blk_width]
            #if (x == 0) and (y == 0):
                #print(f"src {srch_blk_area[0]}")
                #print(f"blk {block[0]}")
            diff_area = np.abs(srch_blk_area - block)
            diff = np.sum(diff_area)
            #if (x == 47) and (y % 2):
                #print(f"{x} y {y} diff {diff} src {srch_blk_area[0]}")
            #print(f"{x} y {y} diff {diff} src {srch_blk_area[0]}")
            if diff < min_diff:
                min_diff = diff
                min_diff_x = x
                min_diff_y = y
                msb = srch_blk_area[0]
            #break
        #break
    return min_diff, min_diff_x, min_diff_y, msb"""

#min_l_file = open("../../modelsim/compare_out_l.bin", "wb")
#min_r_file = open("../../modelsim/compare_out_r.bin", "wb")

out_count = 0

array_list = []

for srch_y in range(0, third_height - srch_blk_height, blk_height):
#for srch_y in range(0, blk_height*2, blk_height):
    for srch_x in range(0, third_width - srch_blk_width, blk_width):
        out_count += 1
    #for srch_x in range(0, blk_width, blk_width):
        #srch_blk = array_center[srch_y:srch_y+srch_blk_height,srch_x:srch_x+srch_blk_width]
        y_coord = int(srch_y)
        #l_blk_coord = srch_x + srch_blk_width - blk_width
        r_blk_coord = srch_x
        #left_block = array_left[y_coord:y_coord+blk_height,l_blk_coord:l_blk_coord+blk_width]
        #print(left_block.shape)
        right_block = array_right[y_coord:y_coord+blk_height,r_blk_coord:r_blk_coord+blk_width]
        array_list.append(right_block)
        
        
dec_factor = 2
smol_array = np.zeros((0))
for smol_y in range(0, third_height, dec_factor):
    for smol_x in range(0, third_width, dec_factor):
        if smol_x < (third_width - srch_blk_width + blk_width):
            smol_block = array_right[smol_y:smol_y+dec_factor,smol_x:smol_x+dec_factor].copy()
        else:
            smol_block = np.zeros((dec_factor, dec_factor))
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
        