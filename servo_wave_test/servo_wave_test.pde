import processing.serial.*;
import cc.arduino.*;

Arduino arduino;                                          // DIGITAL OUT PINS
                                                          // -------------------------
int[][] servos = {  {  0,  0    },                        // Won't be used = Serial RX
                    {  0,  0    },                        // Won't be used = Serial TX
                    {  0,  0    },                        // 2
                    {  90, 180  },                        // 3
                    {  90, 180  },                        // 4
                    {  30, 180  },                        // 5
                    {  45, 135  },                        // 6
                    {  80, 180  },                        // 7
                    {  135, 15  },                        // 8
                    {  135, 15  },                        // 9
                    {  90, 180  },                        // 10
                    {  90, 170  },                        // 11
                    {  90, 170  },                        // 12
                    {  0, 0  }                            // 13
                 };
int firstServo = 3;
int lastServo = 12;

void setup()
{
  size(360, 200);

  //println(Arduino.list()[8]);
  arduino = new Arduino(this, Arduino.list()[8], 57600);
 
  for (int i = firstServo; i <= lastServo; i++) {
    //arduino.pinMode(i, Arduino.OUTPUT);                  //Don't need to specify with Servo Firmata
    arduino.analogWrite(i, servos[i][1]);
    delay(50);
  }
}

void draw()
{
  for (int i = firstServo; i <= lastServo; i++) {
    println(i + ": Turn Servo on pin #" + i);
    arduino.analogWrite(i, servos[i][0]);
    delay(500);
    arduino.analogWrite(i, servos[i][1]);
    delay(1000);
  }
}  

