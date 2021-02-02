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