# -*- coding: utf-8 -*-
"""
Created on Fri Dec 18 18:27:13 2020

@author: Colin
"""

#import opencv2 as cv2
import numpy as np
import math
import random
from generate_stimulus_xors import array_to_file

def filter_3x1_array(conf_array_in, disp_array_in, gray_array_in, gray_threshold, vertical):
    conf_array_out = conf_array_in.copy()
    disp_array_out = disp_array_in.copy()
    for y in range(conf_array_in.shape[0]):
        for x in range(conf_array_in.shape[1]):
            point_sum = 0
            conf_sum = 0
            disp_sum = 0
            this_gray = gray_array_in[y, x]
            max_gray = min(this_gray + gray_threshold, 255)
            min_gray = max(this_gray - gray_threshold, 0)
            for i in range(3):
                if vertical:
                    y_i = y - 1 + i
                    x_i = x
                elif vertical == 0:
                    y_i = y
                    x_i = x - 1 + i
                if (x_i >= 0) and (y_i >= 0) and (x_i < conf_array_in.shape[1]) and (y_i < conf_array_in.shape[0]):
                    gray_i = gray_array_in[y_i, x_i]
                    if (gray_i >= min_gray) and (gray_i <= max_gray):
                        point_sum += 1
                        conf_sum += conf_array_in[y_i, x_i]
                        disp_sum += int(disp_array_in[y_i, x_i]) * int(conf_array_in[y_i, x_i])
            disp_array_out[y, x] = math.floor(disp_sum / max(1, conf_sum))
            conf_array_out[y, x] = math.ceil(conf_sum / point_sum)
            if (y == 0) and (x < 16):
                print(f"x {x} point_sum {point_sum} conf_sum {conf_sum} disp_sum {disp_sum} this gray {this_gray}")
    return conf_array_out, disp_array_out
                
def write_conf_disp_file(conf_array, disp_array, filename):
    with open("C:/360_cam_proj/modelsim/" + filename, "wb") as conf_disp_file:
        for y in range(conf_array.shape[0]):
            for x in range(conf_array.shape[1]):
                conf_disp_file.write(int(conf_array[y, x]).to_bytes(1, "little"))
                conf_disp_file.write(int(disp_array[y, x]).to_bytes(1, "little"))

def main():
    third_width = 240
    third_height = 480
    dec_factor = 3 # Make sure to change this in the testbench
    dec_w = int(third_width / dec_factor)
    dec_h = int(third_height / dec_factor)
    
    upsampled_gray = np.zeros((third_height, third_width), dtype=np.uint8)
    gray_array = np.zeros((dec_h, dec_w), dtype=np.uint8)
    conf_array = gray_array.copy()
    disp_array = gray_array.copy()
    
    gray_in_file = open("C:/360_cam_proj/modelsim/gray_in_data.bin", "wb")
    
    for y in range(dec_h):
        for x in range(dec_w):
            gray = random.randint(40, 90)#y % 256
            confidence = random.randint(0, 255)
            disp = random.randint(0, 31)
            upsampled_gray[y * dec_factor, x * dec_factor] = gray
            gray_array[y, x] = gray
            conf_array[y, x] = confidence
            disp_array[y, x] = disp
            gray_in_file.write(gray.to_bytes(1, "little"))
            
    print(gray_array[0,:16])
    print(gray_array[:16,0])
            
    write_conf_disp_file(conf_array, disp_array, "disp_conf_in_data.bin")
            
    filtered_conf_array = conf_array.copy()
    filtered_disp_array = disp_array.copy()
    
    for i in range(30):
        filtered_conf_array, filtered_disp_array = filter_3x1_array(filtered_conf_array, filtered_disp_array, gray_array, 10, i % 2)
    
    write_conf_disp_file(filtered_conf_array, filtered_disp_array, "filtered_disp_conf_data.bin")
    
    with open("C:/360_cam_proj/modelsim/upsampled_gray_in.bin", "wb") as upsampled_gray_in_file:
        upsampled_gray_in_file.write(upsampled_gray.tobytes())
    
        
if __name__ == "__main__":
    main()