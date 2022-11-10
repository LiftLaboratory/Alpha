#! /usr/bin/env python

import RPi.GPIO as gp
import os
import serial
import time

gp.setwarnings(False)
gp.setmode(gp.BOARD)

gp.setup(7, gp.OUT)
gp.setup(11, gp.OUT)
gp.setup(12, gp.OUT)

cameras = ['A', 'B', 'C', 'D']

def capture(cam):
    cmd = "libcamera-vid -t 0"
    #cmd = "libcamera-still -o capture_%d.jpg" % cam
    os.system(cmd)

def run_cameras(camChoice):
  if camChoice == 'A':
    i2c = "i2cset -y 1 0x70 0x00 0x04"
    os.system(i2c)
    gp.output(7, False)
    gp.output(11, False)
    gp.output(12, True)
    capture(1)
  if camChoice == 'B':
    i2c = "i2cset -y 1 0x70 0x00 0x05"
    os.system(i2c)
    gp.output(7, True)
    gp.output(11, False)
    gp.output(12, True)
    capture(2)
  if camChoice == 'C':
    i2c = "i2cset -y 1 0x70 0x00 0x06"
    os.system(i2c)
    gp.output(7, False)
    gp.output(11, True)
    gp.output(12, False)
    capture(3)
  if camChoice == 'D':
    i2c = "i2cset -y 1 0x70 0x00 0x07"
    os.system(i2c)
    gp.output(7, True)
    gp.output(11, True)
    gp.output(12, False)
    capture(4)

def reset():
    ser.write(b"step_-600]")
    a = ser.readline().decode('utf-8').rstrip()
    print("a:",a)
    ser.reset_input_buffer()
    
def phenotyping():
    ser.write(b"step_60]")
    a = ser.readline().decode('utf-8').rstrip()
    print("a:",a)
    time.sleep(4)
    for i in range(0,6): 
        ser.write(b"lights_A_100_100_100]")
        run_cameras('A')
        time.sleep(1)
        print("Photo A captured")
        
        ser.write(b"lights_B_100_100_100]")
        run_cameras('B')
        time.sleep(1)
        print("Photo B captured")
        
        ser.write(b"lights_C_100_100_100]")
        run_cameras('C')
        time.sleep(1)
        print("Photo C captured")
        
        ser.write(b"lights_D_100_100_100]")
        run_cameras('D')
        time.sleep(1)
        print("Photo D captured")
        
        ser.reset_input_buffer()
        ser.write(b"step_80]") #
        a = ser.readline().decode('utf-8').rstrip()
        print("a:",a)
        time.sleep(7)
        ser.reset_input_buffer()
        
    reset()   
    
    
if __name__ == '__main__':
    ser = serial.Serial('/dev/ttyACM0', 9600, timeout=1)
    ser.reset_input_buffer()
    a = "0"
    a = ser.readline().decode('utf-8').rstrip()
    print("a:",a)
    
    #ser.write(b"step_-1]")
    #for x in range(5):
       # a = ser.readline().decode('utf-8').rstrip()
       # print("a:",a)
    #ser.write(b"lights_A_200_200_200]")
    
    #for x in range(5):
       # b = ser.readline().decode('utf-8').rstrip()
       # print("b:",b)
        
    phenotyping()
    
    #run_cameras('A')
        
    ser.close()
    
    
   
    
        
