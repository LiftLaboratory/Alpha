
#include <SoftwareSerial.h>
#include <AccelStepper.h>
#include <Adafruit_NeoPixel.h>

#define STEPPER_X_DIR_PIN 2
#define STEPPER_X_STEP_PIN 3
#define LED_PIN 5
#define NUM_LEDS 96

AccelStepper stepper(AccelStepper::DRIVER, STEPPER_X_STEP_PIN, STEPPER_X_DIR_PIN);
Adafruit_NeoPixel pixels(NUM_LEDS,LED_PIN, NEO_GRB + NEO_KHZ800); 

int front_photo_sensor = 9;
int back_photo_sensor = 10; 


void setup() {
  Serial.begin(9600);
  stepper.setMaxSpeed(7000);
  pinMode(front_photo_sensor, INPUT_PULLUP); 
  pinMode(back_photo_sensor, INPUT_PULLUP);
  pixels.begin();
}

void loop() {
    String command = Serial.readStringUntil(']');
    // Split the string on the first "-" character and return the command part
    char *function_call = strtok(command.c_str(),"_");
    // convert cstring back to String object for comparison
    String command_string = function_call;
    delay(100);
 
    if (command_string == "step")
    {
      char *step_length = strtok(NULL,"_");
      command_string = step_length;
      Serial.println("Calling steppermotor() function to move:"+command_string+"mm");
      int command_int;
      command_int = command_string.toInt();
     int answer = command_int * 3;
      command_string = String(answer);
      steppermotor(command_int);
      command_string = "";
      Serial.println("Max Speed Set:"+String(stepper.maxSpeed()));
      Serial.println("Complete");
      
    }
    
    else if (command_string == "lights")
    {
      //Serial.println("Calling lights() function");
      char *which_lights = strtok(NULL,"_");
      String light_string = which_lights;
      //Serial.println(light_string);
      
      char *RedValue = strtok(NULL,"_");
      String RedString = String(RedValue);
      int Red = RedString.toInt();
      //Serial.println(Red);
      
      char *GreenValue = strtok(NULL,"_");
      String GreenString = String(GreenValue);
      int Green = GreenString.toInt();
      //Serial.println(Green);
      
      char *BlueValue = strtok(NULL,"_");
      String BlueString = String(BlueValue);
      int Blue = BlueString.toInt();
      //Serial.println(Blue);
      Serial.println("Calling lights() function on light:"+light_string+" RGB:"+Red+","+Green+","+Blue);
      
      int RGBValues[3] = {Red,Green,Blue};
      lights(which_lights,RGBValues);
      command_string="";
      Serial.println("Complete");
    } 

    else if (command_string == "check")
    {
      Serial.println("Still Connected");
      Serial.println("Complete");
    }
  }

/*
int steppermotor(int distance)
{
  int stepsPerMM = 320;
  int numberOfSteps = stepsPerMM * distance;
  stepper.setCurrentPosition(0); 
  stepper.moveTo(numberOfSteps);
  //stepper.setMaxSpeed(10000);
  stepper.setAcceleration(6000);
  //stepper.setSpeed(6000);
  if (distance > 0) 
    {
     while((stepper.currentPosition()<stepper.targetPosition()) && (!isPlatformHere(back_photo_sensor)))
            { 
               stepper.run();
            }
    }
  else
    {
     while((stepper.currentPosition()>stepper.targetPosition()) && (!isPlatformHere(front_photo_sensor)))
            { 
                stepper.run();
            }
    }
}
*/


int steppermotor(int distance) {
  int numberOfSteps = 320;
  if (distance > 0) 
    {
      
        for (int s=0;s < distance;s=s+1)
          {
            stepper.setCurrentPosition(0); 
            stepper.moveTo(numberOfSteps);
            stepper.setSpeed(7000);
            //Serial.println("Value of s:"+String(s)+" of "+String(distance));
            while((stepper.currentPosition()<stepper.targetPosition()) && (!isPlatformHere(back_photo_sensor)))
            { 
              if(!isPlatformHere(back_photo_sensor))
              {
                stepper.runSpeedToPosition();
                //stepper.run();
              }
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
            //Serial.println("Value of s:"+String(s)+" of "+String(distance));
            while((stepper.currentPosition()>stepper.targetPosition()) && (!isPlatformHere(front_photo_sensor)))
            { 
              if(!isPlatformHere(front_photo_sensor))
              {
                stepper.runSpeedToPosition();
              }
            }
          }
      }

}



bool isPlatformHere(int photo_sensor_pin){ // Simple boolean to check if the sensor detects anything

 bool result;
 if(digitalRead(photo_sensor_pin)){result = true;}
 else {result= false;}
 return result;
}


int lights(String LEDlights,int RGBvalues[3]) {   
   pixels.clear();
   if (LEDlights == "A")
    {
      //Serial.println("Using light A");
      for (int i=0;i<24;i=i+2)
        {
          pixels.setPixelColor(i,RGBvalues[0],RGBvalues[1],RGBvalues[2]);
          pixels.show();
        }
    }
    else if (LEDlights == "B") 
      {
        //Serial.println("Using light B");
        for (int i=24;i<48;i=i+2)
          {
            pixels.setPixelColor(i,RGBvalues[0],RGBvalues[1],RGBvalues[2]);
            pixels.show();
          }
      }
     else if (LEDlights == "C") 
      {
        //Serial.println("Using light C");
        for (int i=48;i<72;i=i+2)
          {
            pixels.setPixelColor(i,RGBvalues[0],RGBvalues[1],RGBvalues[2]);
            pixels.show(); 
          }
      }
      else if (LEDlights == "D") 
      {
        //Serial.println("Using light D");
        for (int i=72;i<96;i=i+2)
          {
            pixels.setPixelColor(i,RGBvalues[0],RGBvalues[1],RGBvalues[2]);
            pixels.show(); 
          }
      }
      else if (LEDlights == "ABCD")
      {
        //Serial.println("Using all lights");
        for (int i=0;i<96;i=i+2)
          {
            pixels.setPixelColor(i,RGBvalues[0],RGBvalues[1],RGBvalues[2]);
            pixels.show(); 
          }
      }
}
   
  
