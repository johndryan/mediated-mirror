import processing.serial.*;
import cc.arduino.*;

Arduino arduino;                                          // DIGITAL OUT PINS
// ----------------- OFF, PARALLEL ---------------------- // -------------------------
int[][] servos = {  {  0,  0    },                        // Won't be used = Serial RX
                    {  0,  0    },                        // Won't be used = Serial TX
                    
                    {  70, 160  },                        // 2
                    {  105, 15  },                        // 3
                    {  90, 180  },                        // 4
                    {  90, 180  },                        // 5
                    {  45, 135  },                        // 6
                    {  155, 65  },                        // 7
                    
                    {  105, 15  },                        // 8
                    {  105, 15  },                        // 9
                    {  90, 180  },                        // 10
                    {  170, 80  },                        // 11
                    {  140, 50  },                        // 12
                    {  95, 5  }                         // 13
                 };
int firstServo = 2;
int lastServo = 13;

void setup()
{
  size(360, 200);

  println(Arduino.list());
  arduino = new Arduino(this, Arduino.list()[4], 57600);
 
  for (int i = firstServo; i <= lastServo; i++) {
    arduino.pinMode(i, Arduino.OUTPUT);                  //Don't need to specify with Servo Firmata
    arduino.analogWrite(i, servos[i][1]);
    delay(75);
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

