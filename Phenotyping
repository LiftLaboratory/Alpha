import RPi.GPIO as gp
import os
import serial
import time
from picamera2 import Picamera2

gp.setwarnings(False)
gp.setmode(gp.BOARD)

gp.setup(7, gp.OUT)
gp.setup(11, gp.OUT)
gp.setup(12, gp.OUT)

cameras = ['A', 'B', 'C', 'D']

picam = Picamera2()
#camera_config = picam.create_still_configuration({"size": (4056,3040)})
camera_config = picam.create_still_configuration({"size": (2028,1520)})
picam.configure(camera_config)
#picam.start()

def capture(cam, timestamp):
    #cmd = "libcamera-vid -t 0"
    #cmd = "libcamera-still -n -t 500 -o /home/pi/Desktop/Cryogenics_Photos/capture_%d_%r.jpg" % (cam, timestamp)
    #os.system(cmd)
    picam.start()
    time.sleep(0.2)
    picam.capture_file("/home/pi/Desktop/Phenotyping/capture-"+str(cam)+"-"+timestamp+".jpg")
    picam.stop()
    #time.sleep(2)

def run_cameras(camChoice):
  if camChoice == 'A':
    i2c = "i2cset -y 1 0x70 0x00 0x04"
    os.system(i2c)
    gp.output(7, False)
    gp.output(11, False)
    gp.output(12, True)
    capture(1, time.strftime("%Y_%m_%d_%H:%M:%S", time.localtime()))
  if camChoice == 'B':
    i2c = "i2cset -y 1 0x70 0x00 0x05"
    os.system(i2c)
    gp.output(7, True)
    gp.output(11, False)
    gp.output(12, True)
    capture(2, time.strftime("%Y_%m_%d_%H:%M:%S", time.localtime()))
  if camChoice == 'C':
    i2c = "i2cset -y 1 0x70 0x00 0x06"
    os.system(i2c)
    gp.output(7, False)
    gp.output(11, True)
    gp.output(12, False)
    capture(3, time.strftime("%Y_%m_%d_%H:%M:%S", time.localtime()))
  if camChoice == 'D':
    i2c = "i2cset -y 1 0x70 0x00 0x07"
    os.system(i2c)
    gp.output(7, True)
    gp.output(11, True)
    gp.output(12, False)
    capture(4, time.strftime("%Y_%m_%d_%H:%M:%S", time.localtime()))
    
def reset():
    makeCall("step_-600]")
    a = ser.readline().decode('utf-8').rstrip()
    print("a:",a)
    
    
def phenotyping():
    reset()
    makeCall("step_51]")
    a = ser.readline().decode('utf-8').rstrip()
    print("a:",a)
    
    steps = ["74","74","84","75","75","0"]
    #steps = ["74","0"]
    step_com = ""
    for i in range(1,7): # 6 positions to image 3 tubes at a time for 2 racks
        makeCall("lights_A_100_100_50]")
        run_cameras('A')
        #time.sleep(1)
        print("Photo A captured")
        
        makeCall("lights_B_100_100_50]")
        run_cameras('B')
        #time.sleep(1)
        print("Photo B captured")
        
        makeCall("lights_C_100_100_50]")
        run_cameras('C')
        #time.sleep(1)
        print("Photo C captured")
        
        makeCall("lights_D_100_100_50]")
        run_cameras('D')
        #time.sleep(1)
        print("Photo D captured")
        
        step_com = "step_" + steps[i-1] + "]"
        makeCall(step_com) # move platform to next position
        a = ser.readline().decode('utf-8').rstrip()
        print("a:",a)
        #time.sleep(2)
        
        
    reset() # move platform back to starting position
    
def makeCall(command):
    ser.write(bytes(command,'utf-8'))
    readBack = ""
    while(readBack != "Complete"):
        readBack = ser.readline().decode('utf-8').rstrip()
        print("From Arduino:",readBack)
        time.sleep(0.1)
        

if __name__ == '__main__':

    ser = serial.Serial('/dev/ttyACM0', 9600, timeout=1)
    a = "0" 
    a = ser.readline().decode('utf-8').rstrip()
    print("a:",a)

    
    phenotyping()
        
    makeCall("lights_D_0_0_0]")
    
    a = ser.readline().decode('utf-8').rstrip()
    print("a:",a) 
    for x in range(5):
        b = ser.readline().decode('utf-8').rstrip()
        print("b:",b)
        

        
    ser.close()
