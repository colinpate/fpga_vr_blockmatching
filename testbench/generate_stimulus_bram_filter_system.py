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

def filter_3x3x1_array(conf_array_in, disp_array_in, gray_threshold, vertical):
    conf_array_out = conf_array_in.copy()
    disp_array_out = disp_array_in.copy()
    for y in conf_array_in.shape[1]:
        for x in conf_array_in.shape[0]:
            ignore_0 = False
            ignore_2 = False
            if vertical:
                if (y == 0):
                    ignore_0 = True
                    conf_0 = 0
                    disp_0 = 0
                    conf_2 = conf_array_in[y + 1, x]
                    disp_2 = disp_array_in[y + 1, x]
                elif (y == (conf_array_in.shape[1] - 1)):
                    ignore_2 = True
                    conf_0 = conf_array_in[y - 1, x]
                    disp_0 = disp_array_in[y - 1, x]
                    conf_2 = 0
                    disp_2 = 0
                else:
                    conf_0 = conf_array_in[y - 1, x]
                    disp_0 = disp_array_in[y - 1, x]
                    conf_2 = conf_array_in[y + 1, x]
                    disp_2 = disp_array_in[y + 1, x]
            else:
                if (x == 0):
                    ignore_0 = True
                    conf_0 = 0
                    disp_0 = 0
                    conf_2 = conf_array_in[y, x + 1]
                    disp_2 = disp_array_in[y, x + 1]
                elif (x == (conf_array_in.shape[0] - 1)):
                    ignore_2 = True
                    conf_0 = conf_array_in[y, x - 1]
                    disp_0 = disp_array_in[y, x - 1]
                    conf_2 = 0
                    disp_2 = 0
                else:
                    conf_0 = conf_array_in[y, x - 1]
                    disp_0 = disp_array_in[y, x - 1]
                    conf_2 = conf_array_in[y, x + 1]
                    disp_2 = disp_array_in[y, x + 1]
            conf_1 = conf_array_in[y, x]
            disp_1 = disp_array_in[y, x]
            
                
                

def main():
    third_width = 240
    third_height = 480
    dec_factor = 2
    dec_w = int(third_width / dec_factor)
    dec_h = int(third_height / dec_factor)
    
    upsampled_gray = np.zeros((third_height, third_width), dtype=np.uint8)
    
    gray_in_file = open("C:/360_cam_proj/modelsim/gray_in_data.bin", "wb")
    disp_conf_in_file = open("C:/360_cam_proj/modelsim/disp_conf_in_data.bin", "wb")
    
    for y in range(dec_h):
        for x in range(dec_w):
            gray = random.randint(0, 255)#y % 256
            upsampled_gray[y * dec_factor, x * dec_factor] = gray
            confidence = x
            disp = 255
            disp_conf_in_file.write(confidence.to_bytes(1, "little"))
            disp_conf_in_file.write(disp.to_bytes(1, "little"))
            gray_in_file.write(gray.to_bytes(1, "little"))
    disp_conf_in_file.close()
    gray_in_file.close()
    
    with open("C:/360_cam_proj/modelsim/upsampled_gray_in.bin", "wb") as upsampled_gray_in_file:
        upsampled_gray_in_file.write(upsampled_gray.tobytes())
    
        
if __name__ == "__main__":
    main()