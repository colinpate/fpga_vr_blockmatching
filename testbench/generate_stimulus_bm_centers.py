# -*- coding: utf-8 -*-
"""
Created on Fri Dec 18 18:27:13 2020

@author: Colin
"""

#import opencv2 as cv2
import numpy as np
import math

center_width = 304
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
array_center = np.random.rand(third_height, center_width) * 2
array_center = array_center.astype(np.int8)
print(array_center[0,:8])
print(array_center[0,8:16])
print(array_center[0,16:24])
print(array_center[0,24:32])

def array_to_file(these_arrays):
    with open("../../modelsim/stimulus_in.bin", "wb") as fileout:
        for this_array in these_arrays:
            array_index = 0
            while array_index < len(this_array.flatten()):
                this_byte = 0
                for i in range(8):
                    this_byte += this_array.flatten()[array_index] << i
                    array_index += 1
                #print(this_byte)
                byte_out = int(this_byte).to_bytes(1, "little")
                #print(byte_out)
                fileout.write(byte_out)

array_to_file([array_left, array_center, array_right])

def find_best_coords(block, srch_block):
    min_diff = blk_width * blk_height * 200000
    for y in range(0, srch_blk_height - blk_height, srch_inc_y):
        for x in range(0, srch_blk_width - blk_width, srch_inc_x):
            srch_blk_area = srch_block[y:y+blk_height, x:x+blk_width]
            #if (x == 0) and (y == 0):
                #print(f"src {srch_blk_area[0]}")
                #print(f"blk {block[0]}")
            diff_area = np.abs(srch_blk_area - block)
            diff_area[15,15] = 0
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
    return min_diff, min_diff_x, min_diff_y, msb

min_l_file = open("../../modelsim/compare_out_l.bin", "wb")
min_r_file = open("../../modelsim/compare_out_r.bin", "wb")

out_count = 0

rows = math.floor((third_height - (srch_blk_height - blk_height)) / blk_height)

for srch_y in range(0, rows * blk_height, blk_height):
    print(out_count)
#for srch_y in range(0, blk_height*2, blk_height):
    for srch_x in range(0, center_width - srch_blk_width + blk_width, blk_width):
    #for srch_x in range(0, blk_width, blk_width):
        srch_blk = array_center[srch_y:srch_y+srch_blk_height,srch_x:srch_x+srch_blk_width]
        y_coord = int(srch_y + (srch_blk_height - blk_height) / 2)
        #print(left_block.shape)
        
        l_blk_coord = srch_x
        if l_blk_coord < third_width:
            left_block = array_left[y_coord:y_coord+blk_height,l_blk_coord:l_blk_coord+blk_width]
            min_diff, min_x, min_y, msb = find_best_coords(left_block, srch_blk)
            #print(hex(min_y) +" " + hex(min_x) + " " + str(msb))
            min_l_file.write(min_y.to_bytes(1, "little"))
            min_l_file.write(min_x.to_bytes(1, "little"))
        
        r_blk_coord = srch_x - (srch_blk_width - blk_width)
        if r_blk_coord >= 0:
            out_count += 1
            right_block = array_right[y_coord:y_coord+blk_height,r_blk_coord:r_blk_coord+blk_width]
            min_diff, min_x, min_y, msb = find_best_coords(right_block, srch_blk)
            print(hex(min_y) +" " + hex(min_x) + " " + str(msb))
            min_r_file.write(min_y.to_bytes(1, "little"))
            min_r_file.write(min_x.to_bytes(1, "little"))
        else:
            print("floop")
print(out_count)
min_l_file.close()
min_r_file.close()
        