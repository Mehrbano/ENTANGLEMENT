//***Sketch***///
/*******************************************************************
 *	credits:
 *      VideoAlchemy "Juggling Molecules" Interactive Light Sculpture
 	(c) 2011-2014 Jason Stephens, Owen Williams & VideoAlchemy Collective
 *	Published under CC Attribution-ShareAlike 3.0 (CC BY-SA 3.0)
 *      http://creativecommons.org/licenses/by-sa/3.0/ 
 *      http://evananthony.com/motion/nike-generative-pitch/
 *******************************************************************/

import processing.video.*;
import processing.opengl.*;
import java.util.Iterator;

//*** GLOBAL OBJECTS ***//
Movie myMovie;
//MAIN CONFIGURATION where all data is stored and program reads from
MainCofig gConfig;
//KINECT 
Kinecter gKinecter;
//OPTICAL FLOW converting kinect data to flow field
OpticalFlow gFlowfield;
//PARTICLE MANAGER helps render flow field
PartiManager gPartiManager;
Tactile gTactile;
//INTERVAL
int currTime, nextTime;
final int INTERVAL = 500;
int c = 0;
//RAW DEPTH kinect
int[] gRawDepth;
//ADJUST DEPTH AND THRESHOLD by updateKinectDepth()
int[] gNormalizedDepth;
//DEPTH IMAGE THRESHOLD by updateKinectDepth()
PImage gDepthImg;

//RUNNING CONFIGURATION
void start() {
  gConfig = new MainCofig();
}

//INITIALIZE
void setup() {
  size(1240, 900, OPENGL);
  //set up display parameters
  //Interval
  nextTime = millis() + INTERVAL;
  myMovie = new Movie(this, "Tree_Shape.mov");
  myMovie.loop();
  // set up noise seed
  noiseSeed(gConfig.setupNoiseSeed);
  frameRate(gConfig.setupFPS);
  // helper class for kinect
  gKinecter = new Kinecter(this);
  // initialize depth variables
  gRawDepth = new int[gKinectWidth*gKinectHeight];
  gNormalizedDepth = new int[gKinectWidth*gKinectHeight];
  gDepthImg = new PImage(gKinectWidth, gKinectHeight);
  // Create the particle manager.
  gPartiManager = new PartiManager(gConfig);
  // Create the flowfield
  gFlowfield = new OpticalFlow(gConfig, gPartiManager);
  // Tell the particleManager about the flowfield
  gPartiManager.flowfield = gFlowfield;
  gTactile = new Tactile();
}

// DRAW LOOP
void draw() {
  
 
  pushStyle();
  pushMatrix();
  gTactile.upGradeTactile();
  if (gConfig.showFade) blendScreen(gConfig.fadeColor, gConfig.fadeAlpha);
  // updates the kinect gRawDepth, gNormalizedDepth & gDepthImg variables
  gKinecter.updateKinectDepth();
  // update the optical flow vectors from the gKinecter depth image
  // NOTE: also draws the force vectors if `showFlowLines` is true
  gFlowfield.update();
  //FLOWFIELD AND PARTICLE MANAGER
  if (gConfig.showParticles) gPartiManager.updateWithRender();

  popStyle();
  popMatrix();
}
//CREATE AMBIENCE OF THE PROGRAM 
void blendScreen (color bgColor, int opacity) {
pushStyle(); 
blendMode(gConfig.blendMode); 
noStroke();
fill(255, 100, 50, opacity);//creates orange //BACKGROUND IS BROUGHT IN
rect(0, 0, width, height); 
blendMode(BLEND);
popStyle();
}

// Called every time a new frame for movie
void movieEvent(Movie m) {
  m.read();
}
