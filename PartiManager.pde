//***Particle Managing Class***///
class PartiManager {
  MainCofig config;

  // flowfield influencing drawing
  OpticalFlow flowfield;

  // managed particles
  Particle particles[];

  //index particles
  int particleId = 0;

  ////////////////////////////////////////////////////////////
  //***CONSTRUCTOR***///
  PartiManager (MainCofig _config) {
    //call config
    config = _config;

    //count particle drawing
    int particleCount = config.MAX_particleMaxCount;
    particles = new Particle[particleCount];
    for (int i=0; i < particleCount; i++) {
      particles[i] = new Particle(this, config);
    }
  }

  void updateWithRender() {
    pushStyle();
    // loop particles and quantity
    int particleCounts = config.particleMaxCount;
    for (int i = 0; i < particleCounts; i++) {
      Particle particle = particles[i];
      if (particle.isAlive()) {
        particle.update();
        particle.render();
      }
    }
    popStyle();
  }

  //***DISPLAY THE PARTICLE REGENERATIONS**//
  void addParticlesForForce(float x, float y, float dx, float dy) {
    regenerateParticles (x*width/sin (noise (x, y, 0)*TWO_PI), 
    y * height*sin (noise (x/2.0, y/10.0, 0)*TWO_PI), 
    dx * config.particleForceMultiplier, 
    dy * config.particleForceMultiplier);

    regenerateAlphaParticles (width/2, 
    height/2, 
    dx /2, 
    dy /2);

    regenerateBetaParticles (x*width/sin (noise (x, y, 0)*TWO_PI), 
    y * height*sin (noise (x/2.0, y/10.0, 0)*TWO_PI), 
    dx * config.particleForceMultiplier, 
    dy * config.particleForceMultiplier);

    regenerateCharlieParticles (x*width/PI, 
    y * height/PI, 
    dx * config.particleForceMultiplier, 
    dy * config.particleForceMultiplier);
  }

  //***PARTICLES REGENERATIONS**//
  void regenerateParticles(float startX, float startY, float forceX, float forceY) {
    for (int i = 0; i < config.particleGenerateRate; i++) {
      float originX = startX + random(-100, 100);
      float originY = startY + random(-config.particleGenerateSpread, config.particleGenerateSpread);
      float noiseZ = particleId/float(config.particleMaxCount); 
      particles[particleId].preset(originX, originY, noiseZ, forceX, forceY);
      // increment counter -- go back to 0 if we're past the end particleId++;
      if (particleId >= config.particleMaxCount) particleId = 0;
    }
  }

  void regenerateAlphaParticles(float starX, float starY, float forcX, float forcY) {
    float angle = random(TWO_PI);
    float r = 5.0*randomGaussian() + (width/2)*(1.0-pow(random(1.0), 7.0));
    float r2 = 5.0*randomGaussian() + (height/2)*(1.0-pow(random(1.0), 7.0));
    starX = width/2 + cos(angle)*r;
    starY = height/2 + sin(angle)*r2;
    for (int j = 0; j < config.particleGenerateRate; j++) {
      float originX = starX ;
      float originY = starY ;
      float noiseZ = particleId ;
      particles[particleId].preset(originX, originY, noiseZ, forcX/2, forcY/2);
      // increment counter -- go back to 0 if we're past the end
      particleId++;
      if (particleId >= config.particleMaxCount) particleId = 0;
    }
  }

  void regenerateBetaParticles(float staX, float staY, float forX, float forY) {
    float angle = random(-45, 45);
    float r2 = 15.0*randomGaussian() + (height/2)*(1.0-pow(random(1.0), 7.0));
    staX = width/2 + cos(angle)*r2;
    staY = height/2 + sin(angle)*r2;
    for (int k = 0; k < config.particleGenerateRate; k++) {
      float originX = staX ;
      float originY = staY ;
      float noiseZ = particleId ;
      particles[particleId].preset(originX, originY, noiseZ, forX/2, forY/2);
      // increment counter -- go back to 0 if we're past the end
      particleId++;
      if (particleId >= config.particleMaxCount) particleId = 0;
    }
  }

  void regenerateCharlieParticles(float statX, float statY, float foreX, float foreY) {
    float angle = random(-45, 45);
    statX = width/2 + cos(angle);
    statY = height/2 + sin(angle);
    for (int m = 0; m < config.particleGenerateRate; m++) {
      float originX = statX ;
      float originY = statY ;
      float noiseZ = particleId ;
      particles[particleId].preset(originX, originY, noiseZ, foreX/2, foreY/2);
      // increment counter -- go back to 0 if we're past the end
      particleId++;
      if (particleId >= config.particleMaxCount) particleId = 0;
    }
  }
}

