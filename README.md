# Alpha
Introduction


## Table of Contents:
### [About the Project](https://github.com/LiftLaboratory/Alpha/edit/main/README.md#about-the-project)
### [Raspberry Pi Documentation](https://github.com/LiftLaboratory/Alpha/edit/main/README.md#raspberry-pi-documentation)
  [Cameras](https://github.com/LiftLaboratory/Alpha/edit/main/README.md#cameras)
  
  [Serial Communication with Arduino](https://github.com/LiftLaboratory/Alpha/edit/main/README.md#serial-communication-with-arduino)
### [Arduino Documentation](https://github.com/LiftLaboratory/Alpha/edit/main/README.md#ardunio-documentation)
  [Serial Communication with Raspberry Pi](https://github.com/LiftLaboratory/Alpha/edit/main/README.md#serial-communication-with-raspberry-pi)
  
  [Lights](https://github.com/LiftLaboratory/Alpha/edit/main/README.md#lights)
  
  [Stepper Motor](https://github.com/LiftLaboratory/Alpha/edit/main/README.md#stepper-motor)
### [3D Printing](https://github.com/LiftLaboratory/Alpha/edit/main/README.md#3d-printing-1)
  [Camera Arms and Holders](https://github.com/LiftLaboratory/Alpha/edit/main/README.md#camera-parts)
  
  [Test Tube Racks](https://github.com/LiftLaboratory/Alpha/edit/main/README.md#test-tube-racks)
  
  [Machine and Actuator](https://github.com/LiftLaboratory/Alpha/edit/main/README.md#machine-and-actuator)
  
  [Incubator and Lights](https://github.com/LiftLaboratory/Alpha/edit/main/README.md#incubator-and-lights)
### [Assembly](https://github.com/LiftLaboratory/Alpha/edit/main/README.md#assembly-1)

## About the Project:

...

## Raspberry Pi Documentation

[Complete Raspberry Pi Code](./pi_serial_comm.py)

### Cameras
This project uses the libcamera package, by Raspberry Pi. For information on this package, reference this [Raspberry Pi Documentation](https://www.raspberrypi.com/documentation/accessories/camera.html#libcamera-and-libcamera-apps).

```
import RPi.GPIO as gp
import os
import serial
import time
```
explanation of imports

```
gp.setwarnings(False)
gp.setmode(gp.BOARD)

gp.setup(7, gp.OUT)
gp.setup(11, gp.OUT)
gp.setup(12, gp.OUT)
```
explanation of gp.setups

```
cameras = ['A', 'B', 'C', 'D']
```
Defining cameras A, B, C, and D.

```
def capture(cam):
    cmd = "libcamera-still -o capture_%d.jpg" % cam
    os.system(cmd)
```
...
```
cmd = "libcamera-vid -t 0"
```
An alternate function, "libcamera-vid", will take a continuous video without saving it, until the program is stopped. It's helpful to use while trying to get the cameras in place and focused.

Creating our camera function:
```
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
 ```
 Explain this function...

### Serial Communication with Arduino
The next section of our [Raspberry Pi code](./pi_serial_comm.py) deals with serial communication between the Raspberry Pi and the Arduino. Serial communication is the process of sending information bit by bit, sequentially, over a communication channel. By using serial communication, we're able to call Arduino functions and send inputs to those functions from the Raspberry Pi. This interface increases the functionality and efficiency of the system by removing the need to update our Arduino script everytime we need to change an input in one of the Arduino functions. 

```
if __name__ == '__main__':
    ser = serial.Serial('/dev/ttyACM0', 9600, timeout=1)
    ser.reset_input_buffer()
    a = "0"
    a = ser.readline().decode('utf-8').rstrip()
    print("a:",a)
```

```
    ser.write(b"step_-1]")
    for x in range(5):
        a = ser.readline().decode('utf-8').rstrip()
        print("a:",a)
    ser.write(b"lights_A_200_200_200]")
 ```   
    
```
    for x in range(5):
        b = ser.readline().decode('utf-8').rstrip()
        print("b:",b)
```
Reading, decoding, and printing the bits received by the Ardunio. 
```        
    run_cameras('A')
 ```
 Running our camera function, for camera 'A'.
 ```       
    ser.close()
 ```
Close the serial communication channel(?).

## Arduino Documentation

[Arduino code](./arduino_code.ino)

```
#include <SoftwareSerial.h>
#include <AccelStepper.h>
#include <Adafruit_NeoPixel.h>
```
```
#define STEPPER_X_DIR_PIN 2
#define STEPPER_X_STEP_PIN 3
#define LED_PIN 5
#define NUM_LEDS 96
```
```
AccelStepper stepper(AccelStepper::DRIVER, STEPPER_X_STEP_PIN, STEPPER_X_DIR_PIN);
Adafruit_NeoPixel pixels(NUM_LEDS,LED_PIN, NEO_GRB + NEO_KHZ800); 
```
```
int front_photo_sensor = 9;
int back_photo_sensor = 10; 
```
```
void setup() {
  Serial.begin(9600);
  stepper.setMaxSpeed(5000);
  pinMode(front_photo_sensor, INPUT_PULLUP); 
  pinMode(back_photo_sensor, INPUT_PULLUP);
  pixels.begin();
}
```
```
void loop() {
    String command = Serial.readStringUntil(']');
    char *function_call = strtok(command.c_str(),"_");
    String command_string = function_call;
    delay(100);
```
```String command = Serial.readStringUntil(']');``` reads the incoming bits from the Raspberry Pi, until it gets to a square bracket, and saves it as a String named "command".
```char *function_call = strtok(command.c_str(),"_");``` splits the string on the first "_" character and returns only the command part (i.e. "step" or "lights").
```String command_string = function_call;``` Converts the character string back to a String object for comparison.

Within the same void loop(), we add an if statement to be called if "command_string" reads "step":
```
 if (command_string == "step")
    {
      char *step_length = strtok(NULL,"_");
      String step_string = step_length;
      Serial.println("Calling steppermotor() function to move:"+step_string+"mm");
      int command_int;
      command_int = step_string.toInt();
      steppermotor(command_int);
      command_string = "";
      
    }
```
``` char *step_length = strtok(NULL,"_"); ``` Starting from the last "_" encountered, the string is split again, returning the next section of information contained in the string and saving it as "step_length". Next, we save "step_length" as a String object, named "step_string". This allows us to use Serial.println() to print a line stating how many millimeters are being moved.

## 3D Printing
### Camera Arms and Holders

### Test Tube Racks

### Machine and Actuator

### Incubator and Lights


## Assembly
