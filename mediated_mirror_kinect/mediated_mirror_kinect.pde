/* --------------------------------------------------------------------------
 * Mediated Mirror - with SimpleOpenNI
 * https://github.com/johndryan/mediated-mirror
 * --------------------------------------------------------------------------
 * LIBRARY: http://code.google.com/p/simple-openni
 * ----------------------------------------------------------------------------
 */

import SimpleOpenNI.*;
SimpleOpenNI  context;
boolean autoCalib = true;

int currentFrame = 0;
int debugFreq = 100;
//float realOffset = 685;
float maxwidth = 575;
//float maxwidth = 2000+realOffset;
PFont font;

float realLeft = 600;
float realRight = -1600;

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

int numMirrors = lastServo - firstServo + 1;
Boolean[] mirrorState = { 
  false, false, false, false, false, false, false, false, false, false, false, false
};
Boolean[] lastMirrorState = { 
  true, true, true, true, true, true, true, true, true, true, true, true
};

void setup()
{
  
  font = loadFont("SansSerif-28.vlw");
  textFont(font, 28);
  
  context = new SimpleOpenNI(this);
  if (context.enableDepth() == false) {
    println("Can't open the depthMap, maybe the camera is not connected!"); 
    exit();
    return;
  }

  context.enableUser(SimpleOpenNI.SKEL_PROFILE_ALL);
  context.enableScene();

  background(200, 0, 0);
  
  noStroke();
  smooth();
  
  size(context.sceneWidth(), context.sceneHeight());

  //println(Arduino.list()[8]);
  arduino = new Arduino(this, Arduino.list()[8], 57600);

  for (int i = firstServo; i <= lastServo; i++) {
    arduino.analogWrite(i, servos[i][1]);
    delay(75);
  }
}

void draw() {
  
  
  // RESET MIRROR STATES
  arrayCopy(mirrorState, lastMirrorState);
  for (int i = 0; i < numMirrors; i++) {
    mirrorState[i] = false;
  }


  // UPDATE KINECT CAM
  context.update();

  // USERS
  int userCount = context.getNumberOfUsers();
  int[] userMap = null;
  if (userCount > 0) {
    userMap = context.getUsersPixels(SimpleOpenNI.USERS_ALL);
  }


  // GET POSITION
  PVector projPosition = new PVector();
  PVector worldPosition = new PVector();
  for (int userId = 1; userId <= userCount; userId++) {
    

    if(context.isTrackingSkeleton(userId)) {
      
      // IF HAS SKELETON
      context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_HEAD, projPosition);
      
    } else {
      
      // USE Center of Mass, NOT SKELETON
      context.getCoM(userId, projPosition);
  
    }
    
    context.convertProjectiveToRealWorld(projPosition, worldPosition);
    
    // SELECT MIRROR FOR CURRENT POSITION
    if (projPosition.x != 0) {
      int currentMirror = int(map(projPosition.x, -maxwidth, maxwidth, firstServo-2, lastServo-2));
      //println("CURRENT MIRROR: " + worldPosition.x + " = " + currentMirror);
      if (currentMirror >= 0 && currentMirror < numMirrors) mirrorState[currentMirror] = true;
    }
    
    // DEBUG POSITION
    if (currentFrame % debugFreq == 0) {
      println("USER #" + userId + ": PROJ  : " + projPosition.x + ", " + projPosition.y);
      println("USER #" + userId + ": WORLD : " + worldPosition.x + ", " + worldPosition.y);
    }
  }  
  
  // DRAW IR DEPTH MAP TO SCREEN
  image(context.sceneImage(), 0, 0);

  // DRAW MIRRORS
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

  //DEBUGGING
  fill(0);
  rect(0, height-90, width, 90);
  //if (worldPosition.x > realLeft) realLeft = worldPosition.x;
  //if (worldPosition.x < realRight) realRight = worldPosition.x;
  //if (projPosition.x < 0.5 && projPosition.x > -0.5) realMiddle = worldPosition.x;
  //text("WORLD : " + worldPosition.x + ", PROJ  : " + projPosition.x, 10, height-10);
  fill(0,255,0);
  textAlign(LEFT);
  text( realLeft + " : " + realRight, 10, height-10);
  textAlign(RIGHT);
  fill(255);
  text( int(worldPosition.x) + " , " + int(worldPosition.y) + " , " + int(worldPosition.z), width-10, height-10);
  fill(255,0,0);
  text( int(projPosition.x) + " , " + int(projPosition.y) + " , " + int(projPosition.z), width-10, height-40);
  
  if (currentFrame % debugFreq == 0) {
    println("userCount: " + userCount);
  }
  currentFrame++;
}

void doServo(int mirrorNum, Boolean angled) {
  // Has it changed?
  // println("CHECKING");
  if (mirrorState[mirrorNum] != lastMirrorState[mirrorNum]) {
    int serverNum = lastServo - mirrorNum;
    // Does it have a servo?
    if (serverNum >= firstServo && serverNum <= lastServo) {
      if (angled) {
        // println("Server " + serverNum + " ANGLED");
        arduino.analogWrite(serverNum, servos[serverNum][0]);
      } 
      else {
        // println("Server " + serverNum + " STRAIGHT");        
        arduino.analogWrite(serverNum, servos[serverNum][1]);
      }
    }
  }
}

// -----------------------------------------------------------------
// SimpleOpenNI events

void onNewUser(int userId)
{
  println("onNewUser - userId: " + userId);
  println("  start pose detection");
  
  if(autoCalib)
    context.requestCalibrationSkeleton(userId,true);
  else    
    context.startPoseDetection("Psi",userId);
}

void onLostUser(int userId)
{
  println("onLostUser - userId: " + userId);
}

void onStartCalibration(int userId)
{
  println("onStartCalibration - userId: " + userId);
}

void onEndCalibration(int userId, boolean successfull)
{
  println("onEndCalibration - userId: " + userId + ", successfull: " + successfull);
  
  if (successfull) 
  { 
    println("  User calibrated !!!");
    context.startTrackingSkeleton(userId); 
  } 
  else 
  { 
    println("  Failed to calibrate user !!!");
    println("  Start pose detection");
    context.startPoseDetection("Psi",userId);
  }
}

void onStartPose(String pose,int userId)
{
  println("onStartPose - userId: " + userId + ", pose: " + pose);
  println(" stop pose detection");
  
  context.stopPoseDetection(userId); 
  context.requestCalibrationSkeleton(userId, true);
 
}

void onEndPose(String pose,int userId)
{
  println("onEndPose - userId: " + userId + ", pose: " + pose);
}

