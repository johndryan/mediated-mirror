/* --------------------------------------------------------------------------
 * SimpleOpenNI – Mediated Mirror
 * --------------------------------------------------------------------------
 * http://code.google.com/p/simple-openni
 * ----------------------------------------------------------------------------
 */

import SimpleOpenNI.*;
SimpleOpenNI  context;

int currentFrame = 0;
float maxwidth = 600;

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

int numMirrors = 12;
Boolean[] mirrorState = { 
  false, false, false, false, false, false, false, false, false, false, false, false
};
Boolean[] lastMirrorState = { 
  true, true, true, true, true, true, true, true, true, true, true, true
};

void setup()
{
//  frameRate(12);
  
  context = new SimpleOpenNI(this);
  if (context.enableDepth() == false) {
    println("Can't open the depthMap, maybe the camera is not connected!"); 
    exit();
    return;
  }

  context.enableUser(SimpleOpenNI.SKEL_PROFILE_ALL);
  context.enableScene();

  background(200, 0, 0);
  size(context.sceneWidth(), context.sceneHeight());

  //println(Arduino.list()[8]);
  arduino = new Arduino(this, Arduino.list()[8], 57600);

  for (int i = firstServo; i <= lastServo; i++) {
    arduino.analogWrite(i, servos[i][1]);
    delay(50);
  }
}

void draw()
{
  // update the cam
  context.update();

  // draw irImageMap

  image(context.sceneImage(), 0, 0);

  int userCount = context.getNumberOfUsers();
  int[] userMap = null;
  if (userCount > 0)
  {
    userMap = context.getUsersPixels(SimpleOpenNI.USERS_ALL);
  }

  // Reset mirror states
  arrayCopy(mirrorState, lastMirrorState);
  for (int i = 0; i < numMirrors; i++) {
    mirrorState[i] = false;
  }

  PVector pos = new PVector();
  for (int userId = 1; userId <= userCount; userId++) {
    context.getCoM(userId, pos);    //Get center of mass

      fill(255, 0, 0);
    ellipse(pos.x, pos.y, 3, 3);

    if (currentFrame % 100 == 0) {
      println("USER #" + userId + ": " + pos.x + ", " + pos.y);
    }
    //println(pos.x);

    if (pos.x != 0) {
      int currentMirror = int(map(pos.x, -maxwidth, maxwidth, 0, numMirrors-1));
      //println("CURRENT MIRROR: " + pos.x + " = " + currentMirror);
      if (currentMirror >= 0 && currentMirror < numMirrors) mirrorState[currentMirror] = true;
    }
  }  

  for (int i = 0; i < numMirrors; i++) {
    if (mirrorState[i]) {
      fill(255, 0, 0, 175);      
      doServo(i, true);
    } 
    else {
      fill(200, 200, 200, 175);
      // If changed, reset servo
      doServo(i, false);
    }
    rect(i*(width/numMirrors)+5, 5, (width-((numMirrors+1)*5))/numMirrors, (width-((numMirrors+1)*5))/numMirrors);
  }

  //int[] map = context.sceneMap();
  if (currentFrame % 100 == 0) {
    println("userCount: " + userCount);
    println("userMap: " + userMap);
  }
  currentFrame++;
}

void doServo(int mirrorNum, Boolean angled) {
  // Has it changed?
  println("CHECKING");
  if (mirrorState[mirrorNum] != lastMirrorState[mirrorNum]) {
    int serverNum = lastServo - mirrorNum;
    // Does it have a servo?
    if (serverNum >= firstServo && serverNum <= lastServo) {
      if (angled) {
        println("Server " + serverNum + " ANGLED");
        arduino.analogWrite(serverNum, servos[serverNum][0]);
      } 
      else {
        println("Server " + serverNum + " STRAIGHT");        
        arduino.analogWrite(serverNum, servos[serverNum][1]);
      }
    }
  }
}

