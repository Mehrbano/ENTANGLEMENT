//***Optical Flow Class***///

class OpticalFlow {
  MainCofig config;
  PartiManager particles;

  PVector[][] field;

  int cols, rows; // Columns and Rows
  int resolution; // How large is each "cell" of the flow field

  int avSize; //as;  // window size for averaging (-as,...,+as)
  float df;

  // regression vectors
  float[] fx, fy, ft;
  int regressionVectorLength = 3*9; // length of the vectors

  // internally used variables
  float[] dtr;         // differentiation by t (red,gree,blue)
  float[] dxr;         // differentiation by x (red,gree,blue)
  float[] dyr;         // differentiation by y (red,gree,blue)
  float[] par;         // averaged grid values (red,gree,blue)
  float[] flowx, flowy;     // computed optical flow
  float[] sflowx, sflowy;   // slowly changing version of the flow


  OpticalFlow(MainCofig _config, PartiManager _particles) {
    // remember our configuration object & particle manager
    config = _config;
    particles = _particles;

    // set up resolution of the flow field.
    // NOTE: requires a restart or at least a re-initialization to change this.
    resolution = config.setupFlowFieldResolution;

    // Determine the number of columns and rows based on sketch's width and height
    cols = gKinectWidth/resolution;
    rows = gKinectHeight/resolution;
    field = makePerlinNoiseField(rows, cols);

    avSize = resolution * 2;

    // arrays
    par = new float[cols*rows];
    dtr = new float[cols*rows];
    dxr = new float[cols*rows];
    dyr = new float[cols*rows];
    flowx = new float[cols*rows];
    flowy = new float[cols*rows];
    sflowx = new float[cols*rows];
    sflowy = new float[cols*rows];

    fx = new float[regressionVectorLength];
    fy = new float[regressionVectorLength];
    ft = new float[regressionVectorLength];

    init();
    update();
  }

  void init() {
  }

  void update() {
    difT();
    difXY();
    solveFlow();
  }

  // Calculate average pixel value (r,g,b) for rectangle region
  float averagePixelsGrayscale(int x1, int y1, int x2, int y2) {
    if (x1 < 0)          x1 = 0;
    if (x2 >= gKinectWidth)    x2 = gKinectWidth - 1;
    if (y1 < 0)          y1 = 0;
    if (y2 >= gKinectHeight)  y2 = gKinectHeight - 1;

    float sum = 0.0;
    for (int y = y1; y <= y2; y++) {
      for (int i = gKinectWidth * y + x1; i <= gKinectWidth * y+x2; i++) {
         sum += gNormalizedDepth[i];
      }
    }
    int pixelCount = (x2-x1+1) * (y2-y1+1); // number of pixels

    return sum / pixelCount;
  }

  // extract values from 9 neighbour grids
  void getNeigboringPixels(float x[], float y[], int i, int j) {
    y[j+0] = x[i+0];
    y[j+1] = x[i-1];
    y[j+2] = x[i+1];
    y[j+3] = x[i-cols];
    y[j+4] = x[i+cols];
    y[j+5] = x[i-cols-1];
    y[j+6] = x[i-cols+1];
    y[j+7] = x[i+cols-1];
    y[j+8] = x[i+cols+1];
  }

  // Solve optical flow at a particular point by least squares (regression analysis)
  void solveFlowForIndex(int index) {
    float xx, xy, yy, xt, yt;
    float a,u,v,w;

    // prepare covariances
    xx = xy = yy = xt = yt = 0.0;
    for (int i = 0; i < regressionVectorLength; i++) {
      xx += fx[i]*fx[i];
      xy += fx[i]*fy[i];
      yy += fy[i]*fy[i];
      xt += fx[i]*ft[i];
      yt += fy[i]*ft[i];
    }

    // least squares computation
    a = xx*yy - xy*xy + config.flowfieldRegularization;
    u = yy*xt - xy*yt; // x direction
    v = xx*yt - xy*xt; // y direction

    // write back
    flowx[index] = -2*resolution*u/a; // optical flow x (pixel per frame)
    flowy[index] = -2*resolution*v/a; // optical flow y (pixel per frame)
  }

  void difT() {
    for (int col = 0; col < cols; col++) {
      int x0 = col * resolution + resolution/2;
      for (int row = 0; row < rows; row++) {
        int y0 = row * resolution + resolution/2;
        int index = row * cols + col;
        // compute average pixel at (x0,y0)
        float avg = averagePixelsGrayscale(x0-avSize, y0-avSize, x0+avSize, y0+avSize);
        // compute time difference
        dtr[index] = avg - par[index]; // red
        // save the pixel
        par[index] = avg;
      }
    }
  }


  // 2nd sweep : differentiations by x and y
  void difXY() {
    for (int col = 1; col < cols-1; col++) {
      for (int row = 1; row<rows-1; row++) {
        int index = row * cols + col;
        // compute x difference
        dxr[index] = par[index+1] - par[index-1];
        // compute y difference
        dyr[index] = par[index+cols] - par[index-cols];
      }
    }
  }

  // 3rd sweep : solving optical flow
  void solveFlow() {
    // get time distance between frames at current time
    df = config.flowfieldPredictionTime * config.setupFPS;
    
    // for kinect to window size mapping below
    float normalizedKinectWidth   = 1.0f / ((float) gKinectWidth);
    float normalizedKinectHeight  = 1.0f / ((float) gKinectHeight);
    float kinectToWindowWidth  = ((float) width) * normalizedKinectWidth;
    float kinectToWindowHeight = ((float) height) * normalizedKinectHeight;

    for (int col = 1; col < cols-1; col++) {
      int x0 = col * resolution + resolution/2;
      for (int row = 1; row < rows-1; row++) {
        int y0 = row * resolution + resolution/2;
        int index = row * cols + col;

        // prepare vectors fx, fy, ft
        getNeigboringPixels(dxr, fx, index, 0); // dx grey
        getNeigboringPixels(dyr, fy, index, 0); // dy grey
        getNeigboringPixels(dtr, ft, index, 0); // dt grey

        // solve for (flowx, flowy) such that:
        //   fx flowx + fy flowy + ft = 0
        solveFlowForIndex(index);

        // smoothing
        sflowx[index] += (flowx[index] - sflowx[index]) * config.flowfieldSmoothing;
        sflowy[index] += (flowy[index] - sflowy[index]) * config.flowfieldSmoothing;

        float u = df * sflowx[index];
        float v = df * sflowy[index];

        // amplitude of the vector
        float a = sqrt(u * u + v * v);

        // register new vectors
        if (a >= gConfig.flowfieldMinVelocity) {
          field[col][row] = new PVector(u,v);

          // show optical flow as lines in `flowLineColor`
          if (config.showFlowLines) {
            float startX = width - (((float) x0) * kinectToWindowWidth);
            float startY = ((float) y0) * kinectToWindowHeight;
            float endX   = width - (((float) (x0+u)) * kinectToWindowWidth);
            float endY   = ((float) (y0+v)) * kinectToWindowHeight;
            //LINE
            stroke(255, 100, 50, gConfig.flowLineAlpha);
            line(startX, startY, endX, endY);
            //DOT
            fill (gConfig.flowLineAlpha);
            rect (startX-1, startY-1, 2, 2);
            
          }

          // same syntax as memo's fluid solver (http://memo.tv/msafluid_for_processing)
          float normalizedX = (x0+u) * normalizedKinectWidth;
          float normalizedY = (y0+v) * normalizedKinectHeight;
          float velocityX  = ((x0+u) - x0) * normalizedKinectWidth;
          float velocityY  = ((y0+v) - y0) * normalizedKinectHeight;
          particles.addParticlesForForce(1-normalizedX, normalizedY, -velocityX, velocityY);
        }
      }
    }
  }


  // Look up the vector at a particular world location.
  // Automatically translates into kinect size.
  PVector lookup(PVector worldLocation) {
    int i = (int) constrain(worldLocation.x / resolution, 0, cols-1);
    int j = (int) constrain(worldLocation.y / resolution, 0, rows-1);
    return field[i][j].get();
  }
}


//***PERLIN***//
  PVector[][] makePerlinNoiseField (int rows, int cols) {  
  PVector[][] field = new PVector[cols][rows];
  
  float xOffset = 0;
  for (int col = 0; col < cols; col++) {
  
      float yOffset = 0;
  for (int row = 0; row < rows; row++) {
  
  // Use perlin noise to get an angle between 0 and 2 PI
  float theta = map (noise (xOffset, yOffset), 0, 500, 0, TWO_PI);
  
      // Polar to cartesian coordinate transformation to get x and y components of the vector
      field[col][row] = new PVector(cos(theta+theta), sin(random(theta)), cos(-theta));
      
      yOffset += 0.1;
    }
    xOffset += 0.1;

  }
  return field;
}
