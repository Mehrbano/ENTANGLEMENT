//***Kinect Class***///
import org.openkinect.processing.*;

//Kinect setup (constant for all configs)
// size of the kinect, use by optical flow and particles
int	gKinectWidth  = 640;
int     gKinectHeight = 480;

class Kinecter {
  Kinect kinect;
  boolean isKinected = false;

 // int kAngle	 = gConfig.kinectAngle;
  int thresholdRange = 8000;

//UNCHANGED FROM "Juggling Molecules" Interactive Light Sculpture (c) 2011-2014 Jason Stephens, Owen Williams
  Kinecter(PApplet parent) {
    try {
      kinect = new Kinect(parent);
      kinect.initDepth();
      kinect.initVideo();
      kinect.enableIR(true);
   //   kinect.setTilt(kAngle);

      isKinected = true;
      println("KINECT IS INITIALISED");
    }
    catch (Throwable t) {
      isKinected = false;
      println("KINECT NOT INITIALISED");
      println(t);
    }
  }

  int lowestMin = 470;
  int highestMax = 1000;
  
  void updateKinectDepth() {
    if (!isKinected) return;

    // checks raw depth of kinect: if within certain depth range - color everything white, else black
    gRawDepth = kinect.getRawDepth();
    int lastPixel = gRawDepth.length;
    for (int i=0; i < lastPixel; i++) {
      int depth = gRawDepth[i];

      // if less than min, make it white
      if (depth <= gConfig.kinectMinDepth) {
        gDepthImg.pixels[i] = color(255, 255, 0);	
        gNormalizedDepth[i] = 255;
      } 
      else if (depth >= gConfig.kinectMaxDepth) {
        gDepthImg.pixels[i] = color(0, 0, 255);
        gNormalizedDepth[i] = 0;
      } 
      else {
        int greyScale = (int) map ((float)depth, gConfig.kinectMinDepth, gConfig.kinectMaxDepth, 255, 0);
        gDepthImg.pixels[i] = (gConfig.depthImageAsGreyscale ? color(greyScale) : 255);
        gNormalizedDepth[i] = 255;
      }
    }
    // update the thresholded image
    gDepthImg.updatePixels();
  }
}

