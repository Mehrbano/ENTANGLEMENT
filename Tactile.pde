
int DIM, NUMQUADS, cols,rows; // variables to hold the grid dimensions and total grid size
PImage img; 

class Tactile {
   MainCofig config;
   OpticalFlow flowfield;
    PartiManager particles;

  Tactile () {
    cols = gKinectWidth;
    rows = gKinectHeight;
    img = loadImage("8.png"); 
//  textureMode(NORMAL); // use normalized (0 to 1) texture coordinates
  noStroke(); 
  }
  
  void upGradeTactile() {
    
    float normalizedKinectWidth   = 1.0f / ((float) gKinectWidth);
    float normalizedKinectHeight  = 1.0f / ((float) gKinectHeight);
  
  DIM = (int) map(normalizedKinectWidth, 10, 0, 0, 20); // set DIM in the range from 1 to 40 according to mouseX
  NUMQUADS = DIM*DIM; // calculate the total number of cells in the grid
  beginShape(TRIANGLE); // draw a Shape of QUADS
  blendMode(gConfig.fadeAlpha); 
  texture(img); // use the image as a texture
  // draw all the QUADS in the grid...
  for (int i=0; i<NUMQUADS; i++) {
    drawQuad(i, int(i+noise(i+frameCount*0.001)*NUMQUADS)%NUMQUADS);
  }
  endShape(); // finalize the Shape
}
void drawQuad(int indexPos, int indexTex) {
  // calculate the position of the vertices
  float x1 = float(indexPos%DIM)/DIM*width;
  float y1 = float(indexPos/DIM)/DIM*height;
  float x2 = float(indexPos%DIM+1)/DIM*width;
  float y2 = float(indexPos/DIM+1)/DIM*height;

  // calculate the texture coordinates
  float x1Tex = float(indexTex%DIM)/DIM;
  float y1Tex = float(indexTex/DIM)/DIM;
  float x2Tex = float(indexTex%DIM+1)/DIM;
  float y2Tex = float(indexTex/DIM+1)/DIM;

  // use the above calculations for 4 vertex() calls
  vertex(x1, y1, x1Tex, y1Tex);
  vertex(x2, y1, x2Tex, y1Tex);
  vertex(x2, y2, x2Tex, y2Tex);
  vertex(x1, y2, x1Tex, y2Tex);
}
}


