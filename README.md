# Automated Lab-Scale Phenotyping Apparatus (ALPHA) Project

## Table of Contents:
### [About the Project](https://github.com/LiftLaboratory/Alpha/blob/main/README.md#about-the-project-1)
  [Summary](https://github.com/LiftLaboratory/Alpha/blob/main/README.md#summary)
  
  [Components](https://github.com/LiftLaboratory/Alpha/blob/main/README.md#components)

### [Raspberry Pi Documentation](https://github.com/LiftLaboratory/Alpha/blob/main/README.md#raspberry-pi-documentation-1)
  [Cameras](https://github.com/LiftLaboratory/Alpha/blob/main/README.md#cameras)
  
  [Serial Communication with Arduino](https://github.com/LiftLaboratory/Alpha/blob/main/README.md#serial-communication-with-the-arduino)
### [Arduino Documentation](https://github.com/LiftLaboratory/Alpha/blob/main/README.md#arduino-documentation-1)
  
### [3D Printing](https://github.com/LiftLaboratory/Alpha/blob/main/README.md#3d-printing-1)
  [Camera Arms and Holders](https://github.com/LiftLaboratory/Alpha/blob/main/README.md#camera-parts)
  
  [Test Tube Racks](https://github.com/LiftLaboratory/Alpha/blob/main/README.md#test-tube-racks)
  
  [Machine and Actuator](https://github.com/LiftLaboratory/Alpha/blob/main/README.md#machine-and-actuator)
  
  [Incubator and Lights](https://github.com/LiftLaboratory/Alpha/blob/main/README.md#incubator-and-lights)
### [Assembly](https://github.com/LiftLaboratory/Alpha/blob/main/README.md#assembly-1)

## About the Project:
### Summary
The goal of this project is to use highthroughput phenotyping to develop *Lemna gibba*, a species of duckweed, into a new crop for U.S. agriculture. If we wish to sever our dependence on fossil fuels, the petrochemical industry must find alternative feedstocks, such as biomass, to meet the rising demands for its products and chemicals, most notably plastics. Current biomass sources require entensive fertilizer use, cause soil degradation, and create high levels of greenhouse gas emissions throughout their life cycle. By developing *Lemna gibba* into a crop suitable for agricultural production, essential biomass can be produced with substantially lower environmental impacts. The use of a highthroughput phenotyping system will allow us to selectively focus on traits or phenotypes of interest during this breeding process.

One of our traits of interest is growth rate. Currently, the growth rates of *Lemna gibba* decrease during the warmer months, limiting the species ability to be used for year-round agricultural production. Our experiment will expose *Lemna gibba* hybrids to colder winter temperatures, warmer spring/fall temperatures, and hot summer temperatures to analyze which varieties maintain high growth rates throughout the seasons. These temperatures will be simulated using incubators, where the *Lemna gibba* will grow in test tube racks so they can be easily transported and phenotyped.

### Components
**Machine Cage:**
The cage enclosing the phenotyping system was built using T-slotted aluminum. As a result, the camera arms and other components can be easily mounted to the structure.

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
The lights surrounding the cameras are RGB NeoPixel Rings, with 24 individually programmable LEDs. These lights make it easy to change the color and intensity of each LED. For this project, only 12 of the 24 LEDs on each ring were programmed to turn on when called by the function. LED lights are also used in the incubators to mimic summer, spring/fall, and winter light intensities.

**Test Tube Racks:**
The design of our test tube racks creates two possible positions: upright and slanted. The first position allows the rack to stand up and be easily stored in an incubator. The second gives a clear top view of the surface area of the plants while imaging the test tubes.

## Raspberry Pi Documentation

[Raspberry Pi Code](./Phenotyping.py)

### Cameras
This project uses PiCamera2 to operate the cameras. For information on this library, reference this [documentation](https://pypi.org/project/picamera2/0.2.2/).

```python
import RPi.GPIO as gp
import os
import serial
import time
from picamera2 import Picamera2
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
picam = Picamera2()
camera_config = picam.create_still_configuration({"size": (2028,1520)}) 
picam.configure(camera_config)
```
```python
def capture(cam, timestamp):
    picam.start()
    time.sleep(0.2)
    picam.capture_file("/home/pi/Desktop/Phenotyping/capture-"+str(cam)+"-"+timestamp+".jpg")
    picam.stop()
```

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
**Defining the function that resets the actuator to its starting position:**
```python
def reset():
    makeCall("step_-600]")
    a = ser.readline().decode('utf-8').rstrip()
    print("a:",a)
```
### Serial Communication with the Arduino:
The next section of our [Raspberry Pi code](./Phenotyping.py) deals with serial communication between the Raspberry Pi and the Arduino. Serial communication is the process of sending information bit by bit, sequentially, over a communication channel. By using serial communication, we're able to call Arduino functions and send inputs to those functions from the Raspberry Pi. This interface increases the functionality and efficiency of the system by removing the need to update our Arduino script everytime we need to change an input in one of the Arduino functions. 

**Defining the makeCall function:**
This function facilitates serial communication between the Raspberry Pi and the Arduino. The parameter, "command", is a string containing information to call a specific function on the Arduino. Feedback from the Arduino is continuously read until "Complete" is sent to the Raspberry Pi, signaling that the function has finished running.
```python
def makeCall(command):
    ser.write(bytes(command,'utf-8'))
    readBack = ""
    while(readBack != "Complete"):
        readBack = ser.readline().decode('utf-8').rstrip()
        print("From Arduino:",readBack)
        time.sleep(0.1)
```

**Defining the phenotyping function:**
```python
def phenotyping():
    reset()
    makeCall("step_51]")
    a = ser.readline().decode('utf-8').rstrip()
    print("a:",a)
    
    steps = ["74","74","84","75","75","0"]
    step_com = ""
    for i in range(1,7): # 6 positions to image 3 tubes at a time for 2 racks
        makeCall("lights_A_100_100_50]")
        run_cameras('A')
        print("Photo A captured")
        
        makeCall("lights_B_100_100_50]")
        run_cameras('B')
        print("Photo B captured")
        
        makeCall("lights_C_100_100_50]")
        run_cameras('C')
        print("Photo C captured")
        
        makeCall("lights_D_100_100_50]")
        run_cameras('D')
        print("Photo D captured")
        
        step_com = "step_" + steps[i-1] + "]"
        makeCall(step_com) # move platform to next position
        a = ser.readline().decode('utf-8').rstrip()
        print("a:",a)

    reset()
```
**Main script:**
```python
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
  stepper.setMaxSpeed(7000);
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
**If the steppermotor is called:**
```C++
 if (command_string == "step")
    {
      char *step_length = strtok(NULL,"_");
      String step_string = step_length;
      Serial.println("Calling steppermotor() function to move:"+step_string+"mm");
      int command_int = step_string.toInt();
      steppermotor(command_int);
      command_string = "";
      Serial.println("Max Speed Set:"+String(stepper.maxSpeed()));
      Serial.println("Complete");
    }
```
**If the lights are called:**
```C++
 else if (command_string == "lights")
    {
      Serial.println("Calling lights() function");
      char *which_lights = strtok(NULL,"_");
      String light_string = which_lights;
      Serial.println(light_string);
```
```C++
      char *RedValue = strtok(NULL,"_");
      String RedString = String(RedValue);
      int Red = RedString.toInt();
      
      char *GreenValue = strtok(NULL,"_");
      String GreenString = String(GreenValue);
      int Green = GreenString.toInt();
      
      char *BlueValue = strtok(NULL,"_");
      String BlueString = String(BlueValue);
      int Blue = BlueString.toInt();
      Serial.println("Calling lights() function on light:"+light_string+" RGB:"+Red+","+Green+","+Blue);
```
```C++
      int RGBValues[3] = {Red,Green,Blue};
      lights(which_lights,RGBValues);
      command_string="";
      Serial.println("Complete");
```
**To check serial communication:**
 ```C++
 else if (command_string == "check")
    {
      Serial.println("Still Connected");
      Serial.println("Complete");
    }
```
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
            stepper.setSpeed(7000);
            while((stepper.currentPosition()<stepper.targetPosition()) && (!isPlatformHere(back_photo_sensor)))
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
            stepper.setSpeed(7000);
            while((stepper.currentPosition()>stepper.targetPosition()) && (!isPlatformHere(front_photo_sensor)))
            { 
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
      for (int i=0;i<24;i=i+2)
        {
          pixels.setPixelColor(i,RGBvalues[0],RGBvalues[1],RGBvalues[2]);
          pixels.show();
        }
    }
    else if (LEDlights == "B") 
      {
        for (int i=24;i<48;i=i+2)
          {
            pixels.setPixelColor(i,RGBvalues[0],RGBvalues[1],RGBvalues[2]);
            pixels.show();
          }
       
      }
     else if (LEDlights == "C") 
      {
        for (int i=48;i<72;i=i+2)
          {
            pixels.setPixelColor(i,RGBvalues[0],RGBvalues[1],RGBvalues[2]);
            pixels.show(); 
          }
      }
      else if (LEDlights == "D") 
      {
        for (int i=72;i<96;i=i+2)
          {
            pixels.setPixelColor(i,RGBvalues[0],RGBvalues[1],RGBvalues[2]);
            pixels.show(); 
          }
      }
      else if (LEDlights == "ABCD")
      {
        for (int i=0;i<96;i=i+2)
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

[Camera Arm Base](https://github.com/LiftLaboratory/Alpha/blob/main/Camera%20Arm%20Base_Scaled%20(1).stl)

[Camera Arm Base Clamp](https://github.com/LiftLaboratory/Alpha/blob/main/Camera%20Arm%20Base%20Clamp_Scaled%20(1).stl)

[Camera Arm 100mm](https://github.com/LiftLaboratory/Alpha/blob/main/Camera%20Arm%20100mm_Scaled.stl)

[Camera Arm 60mm](https://github.com/LiftLaboratory/Alpha/blob/main/Camera%20Arm%2060mm_Scaled.stl)

[Camera Holder Front Cover](https://github.com/LiftLaboratory/Alpha/blob/main/Camera%20Holder%20Front%20Cover%20v6.stl)

[Camera Holder Back Cover](https://github.com/LiftLaboratory/Alpha/blob/main/Camera%20Holder%20Back%20Cover%20v5.stl)


### Test Tube Racks
[Rack Hinged Main Body](https://github.com/LiftLaboratory/Alpha/blob/main/Rack%20Hinged%20Main%20Body%20v12.stl)

[Rack Support Mockup Bottom](https://github.com/LiftLaboratory/Alpha/blob/main/Rack_Support_Mockup_Botttom%20v5.stl)

[Rack Support Mockup Top](https://github.com/LiftLaboratory/Alpha/blob/main/Rack_Support_Mockup_Top%20v4.stl)

[Top Wing Attachment](https://github.com/LiftLaboratory/Alpha/blob/main/Top%20Wing%20Attachment%20v23.stl)

[Bottom Wing Attachment](https://github.com/LiftLaboratory/Alpha/blob/main/Bottom%20Wing%20Attachment%20v8.stl)

[Hinge Piece Long](https://github.com/LiftLaboratory/Alpha/blob/main/HingePieceLong%20v12%20(1).stl)

[Hinge Piece Short](https://github.com/LiftLaboratory/Alpha/blob/main/HingePieceShort%20v5%20(1).stl)

[Handle](https://github.com/LiftLaboratory/Alpha/blob/main/Handle_Ryan%20v2.stl)

### Machine and Actuator
[Component Box](https://github.com/LiftLaboratory/Alpha/blob/main/Component_Box%20v13%20(1).stl)

[Component Box Lid](https://github.com/LiftLaboratory/Alpha/blob/main/Component%20Box_Lid%20v2%20(2).stl)

[Stepper Box](https://github.com/LiftLaboratory/Alpha/blob/main/Stepper_Box%20v21%20(1).stl)

[Stepper Box Lid](https://github.com/LiftLaboratory/Alpha/blob/main/Stepper_Box_Lid%20v5%20(1).stl)

### Incubator and Lights
[Charger Holster](https://github.com/LiftLaboratory/Alpha/blob/main/Charger_Holster_v2%20v7%20(1).stl)

[Lights Case](https://github.com/LiftLaboratory/Alpha/blob/main/Lights%20Case%20v10%20(1).stl)

[Rack Clip](https://github.com/LiftLaboratory/Alpha/blob/main/Rack%20Clip%20v6.stl)

[Incubator Platform](https://github.com/LiftLaboratory/Alpha/blob/main/IncubatorPlatform_Alone%20v11.stl)


## Assembly
### Wiring Diagrams
<details><summary>Lights and Arduino</summary>
<p>

![Lights Wiring Diagram](https://github.com/LiftLaboratory/Alpha/blob/main/Lights_Wiring%20Diagram.jpg?raw=true)

</p>
</details>

### Cage and Actuator
<details><summary>Cage and Actuator Diagram</summary>
<p>
  
![Cage and Actuator Diagram](https://github.com/LiftLaboratory/Alpha/blob/main/AlphaCage%20(1).png?raw=true)

</p>
</details>

<details><summary>Attaching Components to the Cage</summary>
<p>
  
T-slotted framing fasteners and M4 screws can be used to attach the camera arms and Raspberry Pi case to the cage.
  
How is linear actuator attached?

</p>
</details>

### Test Tube Racks
<details><summary>Hinge Open Diagram</summary>
<p>

![Hinge Open Diagram](https://github.com/LiftLaboratory/Alpha/blob/main/HingeOpen%20(1).png?raw=true)

</p>
</details>

<details><summary>Hinge Closed Diagram</summary>
<p>

![Hinge Closed Diagram](https://github.com/LiftLaboratory/Alpha/blob/main/HingeClosed%20(1).png?raw=true)

</p>
</details>

### Cameras

<details><summary>Camera Angles Diagram</summary>
<p>
  
![Camera Angles Diagram](https://github.com/LiftLaboratory/Alpha/blob/main/Imaging%20angle%20diagram.png?raw=true)

</p>
</details>

### Arduino and Stepper Motor
<details><summary>Arduino and Stepper Motor Diagram</summary>
<p>

![Arduino and Stepper Motor Diagram](https://github.com/LiftLaboratory/Alpha/blob/main/Arduino%20and%20Stepper%20motor%20Diagram.png?raw=true)

</p>
</details>
