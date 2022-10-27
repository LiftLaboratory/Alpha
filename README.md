# Alpha

## Table of Contents:
### [About the Project](https://github.com/LiftLaboratory/Alpha/blob/main/README.md#about-the-project-1)
  [Summary](https://github.com/LiftLaboratory/Alpha/blob/main/README.md#summary)
  
  [Components](https://github.com/LiftLaboratory/Alpha/blob/main/README.md#components)

### [Raspberry Pi Documentation](https://github.com/LiftLaboratory/Alpha/blob/main/README.md#raspberry-pi-documentation-1)
  [Cameras](https://github.com/LiftLaboratory/Alpha/blob/main/README.md#cameras)
  
  [Serial Communication with Arduino](https://github.com/LiftLaboratory/Alpha/blob/main/README.md#serial-communication-with-arduino)
### [Arduino Documentation](https://github.com/LiftLaboratory/Alpha/blob/main/README.md#arduino-documentation-1)
  [Serial Communication with Raspberry Pi](https://github.com/LiftLaboratory/Alpha/blob/main/README.md#serial-communication-with-raspberry-pi)
  
  [Lights](https://github.com/LiftLaboratory/Alpha/blob/main/README.md#lights)
  
  [Stepper Motor](https://github.com/LiftLaboratory/Alpha/blob/main/README.md#stepper-motor)
### [3D Printing](https://github.com/LiftLaboratory/Alpha/blob/main/README.md#3d-printing-1)
  [Camera Arms and Holders](https://github.com/LiftLaboratory/Alpha/blob/main/README.md#camera-parts)
  
  [Test Tube Racks](https://github.com/LiftLaboratory/Alpha/blob/main/README.md#test-tube-racks)
  
  [Machine and Actuator](https://github.com/LiftLaboratory/Alpha/blob/main/README.md#machine-and-actuator)
  
  [Incubator and Lights](https://github.com/LiftLaboratory/Alpha/blob/main/README.md#incubator-and-lights)
### [Assembly](https://github.com/LiftLaboratory/Alpha/blob/main/README.md#assembly-1)

## About the Project:
### Summary
The goal of this project is to use highthroughput phenotyping to develop *Lemna gibba*, a species of duckweed, into a new crop for U.S. agriculture. If we wish to sever our dependence on fossil fuels, the petrochemical industry must find alternative feedstocks, such as biomass, to meet the rising demands for its products and chemicals, most notably plastics. Current biomass sources require entensive fertilizer use, cause soil degradation, and create high levels of greenhouse gas emissions throughout their life cycle. By developing *Lemna gibba* into a crop suitable for agricultural production, essential biomass can be produced with substantially lower environmental impacts. 

The use of a highthroughput phenotyping system will allow us to selectively focus on traits or phenotypes of interest during this breeding process.

### Components
**Machine Cage:**
The cage enclosing the phenotyping system was built using T-slotted aluminum(??). As a result, the camera arms and other components can be easily mounted to the structure using...

**Linear Actuator:**
The function of the linear actuator is to move the test tube racks along the platform, so they can be imaged by the Raspberry Pi cameras.

**Stepper Motor and Microstep Driver:**
The linear actuator is controlled using a stepper motor, which allows for a high degree of control and accuracy. Stepper motors divide a full rotation of the linear actuator into an equivalent number of steps, making it easier to program the distance to move. The stepper motor is controlled using a microstep driver, which is then controlled by an Arduino.

**Raspberry Pi:**
A Raspberry Pi 4 Model B is used to control the cameras, as well as interface with the Arduino to increase the functionality of the system. Attaching an Arducam Multi Camera Board to the Raspberry Pi allows all four cameras to be controlled from a single Raspberry Pi.

**Arduino:**
For this project, an Arduino is used to control the linear actuator and LED lights. The Arduino is programmed to receive input from the Raspberry Pi to call the light and motor functions and read-in inputs for the specified function. 

**Cameras:**
The cameras used are Raspberry Pi high quality cameras with ArduCam camera lenses (6mm for the sides and 8mm for the top).

**LED Lights:**
The lights surrounding the cameras are RGB NeoPixel Rings, with 24 individually programmable LEDs. These lights make it easily to change the color and intensity of each LED. For this project, only 12 of the 24 LEDs on each ring were programmed to turn on when called by the function.

**Test Tube Racks:**
The design of our test tube racks creates two possible positions: upright and slanted. The first position allows the rack to stand up and be easily stored in an incubator. The second gives a clear top view of the surface area of the plants while imaging the test tubes.

## Raspberry Pi Documentation

[Raspberry Pi Code](./pi_serial_comm.py)

### Cameras
This project uses the libcamera package, by Raspberry Pi. For information on this package, reference this [Raspberry Pi Documentation](https://www.raspberrypi.com/documentation/accessories/camera.html#libcamera-and-libcamera-apps).

```python
import RPi.GPIO as gp
import os
import serial
import time
```
```python
gp.setwarnings(False)
gp.setmode(gp.BOARD)

gp.setup(7, gp.OUT)
gp.setup(11, gp.OUT)
gp.setup(12, gp.OUT)
```
```python
cameras = ['A', 'B', 'C', 'D']
```
```python
def capture(cam):
    cmd = "libcamera-still -o capture_%d.jpg" % cam
    os.system(cmd)
```
Using ```cmd = "libcamera-vid -t 0"``` instead of "libcamera-still" will take a continuous video without saving it, until the program is stopped. It's helpful to use while trying to get the cameras in place and focused.

**Defining the camera function:**
```python
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

### Serial Communication with Arduino
The next section of our [Raspberry Pi code](./pi_serial_comm.py) deals with serial communication between the Raspberry Pi and the Arduino. Serial communication is the process of sending information bit by bit, sequentially, over a communication channel. By using serial communication, we're able to call Arduino functions and send inputs to those functions from the Raspberry Pi. This interface increases the functionality and efficiency of the system by removing the need to update our Arduino script everytime we need to change an input in one of the Arduino functions. 

```python
if __name__ == '__main__':
    ser = serial.Serial('/dev/ttyACM0', 9600, timeout=1)
    ser.reset_input_buffer()
    a = "0"
    a = ser.readline().decode('utf-8').rstrip()
    print("a:",a)
```
```python
    ser.write(b"step_-1]")
    for x in range(5):
        a = ser.readline().decode('utf-8').rstrip()
        print("a:",a)
    ser.write(b"lights_A_200_200_200]")
 ```   
```python
    for x in range(5):
        b = ser.readline().decode('utf-8').rstrip()
        print("b:",b)
```
```python       
    run_cameras('A')
 ```
 ```python   
    ser.close()
 ```

## Arduino Documentation

[Arduino code](./arduino_code.ino)

```C++
#include <SoftwareSerial.h>
#include <AccelStepper.h>
#include <Adafruit_NeoPixel.h>
```
```C++
#define STEPPER_X_DIR_PIN 2
#define STEPPER_X_STEP_PIN 3
#define LED_PIN 5
#define NUM_LEDS 96
```
```C++
AccelStepper stepper(AccelStepper::DRIVER, STEPPER_X_STEP_PIN, STEPPER_X_DIR_PIN);
Adafruit_NeoPixel pixels(NUM_LEDS,LED_PIN, NEO_GRB + NEO_KHZ800); 
```
```C++
int front_photo_sensor = 9;
int back_photo_sensor = 10; 
```
```C++
void setup() {
  Serial.begin(9600);
  stepper.setMaxSpeed(5000);
  pinMode(front_photo_sensor, INPUT_PULLUP); 
  pinMode(back_photo_sensor, INPUT_PULLUP);
  pixels.begin();
}
```
```C++
void loop() {
    String command = Serial.readStringUntil(']');
    char *function_call = strtok(command.c_str(),"_");
    String command_string = function_call;
    delay(100);
```
```String command = Serial.readStringUntil(']');``` reads the incoming bits from the Raspberry Pi, until it gets to a square bracket, and saves it as a String named "command".
```char *function_call = strtok(command.c_str(),"_");``` splits the string on the first "_" character and returns only the command part (i.e. "step" or "lights").
```String command_string = function_call;``` Converts the character string back to a String object for comparison.

**Within the same void loop(), we add an if statement to parse out the information following "step" and use it to call the steppermotor() function:**
```C++
 if (command_string == "step")
    {
      char *step_length = strtok(NULL,"_");
      String step_string = step_length;
      Serial.println("Calling steppermotor() function to move:"+step_string+"mm");
      int command_int = step_string.toInt();
      steppermotor(command_int);
      command_string = "";
    }
```
``` char *step_length = strtok(NULL,"_"); ``` Starting from the last "_" encountered, the string is split again, returning the next section of information contained in the string and saving it as "step_length". Next, we save "step_length" as a String object, named "step_string". This allows us to use Serial.println() to print a line stating how many millimeters are being moved. In order to use the number of steps in our steppermotor() function, it must first be converted to an Integer: ```int command_int = step_string.toInt();``` Now, we call the steppermotor() function: ```steppermotor(command_int);```.

**Also within the void loop(), we follow the same concept for parsing out information for and calling the lights() function:**
```C++
 else if (command_string == "lights")
    {
      Serial.println("Calling lights() function");
      char *which_lights = strtok(NULL,"_");
      String light_string = which_lights;
      Serial.println(light_string);
```
```char *which_lights = strtok(NULL,"_");``` parses out the light being called (A, B, C, or D).
```C++
      char *RedValue = strtok(NULL,"_");
      String RedString = String(RedValue);
      int Red = RedString.toInt();
      Serial.println(Red);
      
      char *GreenValue = strtok(NULL,"_");
      String GreenString = String(GreenValue);
      int Green = GreenString.toInt();
      Serial.println(Green);
      
      char *BlueValue = strtok(NULL,"_");
      String BlueString = String(BlueValue);
      int Blue = BlueString.toInt();
      Serial.println(Blue);
 ```
 These three sections parse out the three RGB values, convert them to an integer, and print the value.
```C++
      int RGBValues[3] = {Red,Green,Blue};
      lights(which_lights,RGBValues);
      command_string="";
```
In the first line, we're creating an array containing the Red, Blue, and Green Integer objects. The lights() function is then called with our two inputs: which_lights and RGBValues.

**Defining the steppermotor() function:**
```C++
int steppermotor(int distance) {
  int numberOfSteps = 320;
  if (distance > 0) 
    {
      
        for (int s=0;s < distance;s=s+1)
          {
            stepper.setCurrentPosition(0); 
            stepper.moveTo(numberOfSteps);
            stepper.setSpeed(5000);
            Serial.println("Value of s:"+String(s)+" of "+String(distance));
            while(stepper.currentPosition()<stepper.targetPosition())
            { 
              if(!isPlatformHere(back_photo_sensor))
                stepper.runSpeedToPosition();
            }
          }
    }
    else 
      {
        
        for (int s=0;s > distance;s=s-1)
          {
            stepper.setCurrentPosition(0); 
            stepper.moveTo(-numberOfSteps);
            stepper.setSpeed(5000);
            Serial.println("Value of s:RGBvalues[0],RGBvalues[1],RGBvalues[2]"+String(s)+" of "+String(distance));
            while(stepper.currentPosition()>stepper.targetPosition())
            { 
              //stepper.runSpeed();
              if(!isPlatformHere(front_photo_sensor))
                stepper.runSpeedToPosition();
            }
          }
      }

}
```

**Defining the lights() function:**
```C++
int lights(String LEDlights,int RGBvalues[3]) {   
   pixels.clear();
   if (LEDlights == "A")
    {
      Serial.println("Using light A");
      for (int i=0;i<24;i=i+2)
        {
          pixels.setPixelColor(i,RGBvalues[0],RGBvalues[1],RGBvalues[2]);
          pixels.show();
        }
    }
    else if (LEDlights == "B") 
      {
        Serial.println("Using light B");
        for (int i=24;i<48;i=i+2)
          {
            pixels.setPixelColor(i,RGBvalues[0],RGBvalues[1],RGBvalues[2]);
            pixels.show();
          }
       
      }
     else if (LEDlights == "C") 
      {
        Serial.println("Using light C");
        for (int i=48;i<72;i=i+2)
          {
            pixels.setPixelColor(i,RGBvalues[0],RGBvalues[1],RGBvalues[2]);
            pixels.show(); 
          }
      }
      else if (LEDlights == "D") 
      {
        Serial.println("Using light D");
        for (int i=72;i<96;i=i+2)
          {
            pixels.setPixelColor(i,RGBvalues[0],RGBvalues[1],RGBvalues[2]);
            pixels.show(); 
          }
      }
}
```
**Creating a boolean to check if the sensor on the linear actuator detects the platform:**
```C++
bool isPlatformHere(int photo_sensor_pin){

 bool result;
 if(digitalRead(photo_sensor_pin)){result = true;}
 else {result= false;}
 return result;
}
```

## 3D Printing
### Camera Arms and Holders

[Camera Arm Base](https://github.com/LiftLaboratory/Alpha/blob/3D-Printing/Camera%20Arm%20Base_Scaled%20(1).stl)

[Camera Arm Base Clamp](https://github.com/LiftLaboratory/Alpha/blob/3D-Printing/Camera%20Arm%20Base%20Clamp_Scaled%20(1).stl)

[Camera Arm 100mm](https://github.com/LiftLaboratory/Alpha/blob/3D-Printing/Camera%20Arm%20100mm_Scaled.stl)

[Camera Arm 60mm](https://github.com/LiftLaboratory/Alpha/blob/3D-Printing/Camera%20Arm%2060mm_Scaled.stl)

[Camera Holder Front Cover](https://github.com/LiftLaboratory/Alpha/blob/3D-Printing/Camera%20Holder%20Front%20Cover%20v6.stl)

[Camera Holder Back Cover](https://github.com/LiftLaboratory/Alpha/blob/3D-Printing/Camera%20Holder%20Back%20Cover%20v5.stl)


### Test Tube Racks
[Rack Hinged Main Body](https://github.com/LiftLaboratory/Alpha/blob/main/Rack%20Hinged%20Main%20Body%20v7%20(2).stl)

[Rack Hinged Main Body - Test Tube Side](https://github.com/LiftLaboratory/Alpha/blob/main/TestTubeSide%20v20%20(1).stl)

[Rack Support Mockup Bottom](https://github.com/LiftLaboratory/Alpha/blob/main/Rack_Support_Mockup_Botttom%20v1%20(2).stl)

[Top Wing Attachment](https://github.com/LiftLaboratory/Alpha/blob/main/Top%20Wing%20Attachment%20v11%20(2).stl)

[Bottom Wing Attachment](https://github.com/LiftLaboratory/Alpha/blob/main/Bottom%20Wing%20Attachment%20(2).stl)

[Hinge Piece Long](https://github.com/LiftLaboratory/Alpha/blob/main/HingePieceLong%20v12%20(1).stl)

[Hinge Piece Short](https://github.com/LiftLaboratory/Alpha/blob/main/HingePieceShort%20v5%20(1).stl)

### Machine and Actuator
[Component Box](https://github.com/LiftLaboratory/Alpha/blob/3D-Printing/Component_Box%20v13%20(1).stl)

[Component Box Lid](https://github.com/LiftLaboratory/Alpha/blob/3D-Printing/Component%20Box_Lid%20v2%20(2).stl)

[Stepper Box](https://github.com/LiftLaboratory/Alpha/blob/3D-Printing/Stepper_Box%20v21%20(1).stl)

[Stepper Box Lid](https://github.com/LiftLaboratory/Alpha/blob/3D-Printing/Stepper_Box_Lid%20v5%20(1).stl)

### Incubator and Lights
[Charger Holster](https://github.com/LiftLaboratory/Alpha/blob/3D-Printing/Charger_Holster_v2%20v6%20(2).stl)

[Lights Case](https://github.com/LiftLaboratory/Alpha/blob/3D-Printing/Lights%20Case%20v10%20(1).stl)

[Rack Clip](https://github.com/LiftLaboratory/Alpha/blob/3D-Printing/Rack%20Clip%20v5%20(1).stl)

[Incubator Platform](https://github.com/LiftLaboratory/Alpha/blob/3D-Printing/IncubatorPlatform_Alone%20v9.stl)


## Assembly
