class LetterBody {
  Body body;
  char ch;
  PVector[] localVertsPx;
  float textSizePx;
  boolean gathering = false;
  PVector targetPx = new PVector();
  float gatherSpeedMeters = 1000.0f;
  float arriveEpsMeters = 0.02f;
  float col = 255;
  float targetCol = 255;
  float fadeRatePerSec = 300;

  LetterBody(Body b, char c, PVector[] vertsPx, float textSizePx) {
    this.body = b;
    this.ch = c;
    this.localVertsPx = vertsPx;
    this.textSizePx = textSizePx;
  }
  
  char getValue(){
    return ch;
  }
  
  void setWhiteInstant() {
    col = 255;
    targetCol = 255;
  }
  
  void setGrayInstant() {
    col = 49;
    targetCol = 49;
  }
  
  void fadeToGray() {
    targetCol = 49;
  }

  void updateColor(float dt) {
    if (abs(col - targetCol) < 0.5f) {
      col = targetCol;
      return;
    }
    float dir = (targetCol > col) ? 1 : -1;
    col += dir * fadeRatePerSec * dt;
    if ((dir > 0 && col > targetCol) || (dir < 0 && col < targetCol)) {
      col = targetCol;
    }
  }

  void setTargetPx(float x, float y) {
    targetPx.set(x, y);
    gathering = true;
  }

  boolean updateKinematicChase() {
    if (!gathering) {
      return false;
    }

    Vec2 targetW = box2d.coordPixelsToWorld(targetPx.x, targetPx.y);
    Vec2 posW = body.getPosition().clone();
    Vec2 to = targetW.sub(posW);
    float dist = to.length();

    if (dist < arriveEpsMeters) {
      body.setTransform(targetW, 0);
      body.setLinearVelocity(new Vec2());
      body.setAngularVelocity(0);
      gathering = false;
      return true;
    }

    float dt = FIXED_DT;
    float maxSpeed = gatherSpeedMeters;
    float neededSpeed = dist / dt;
    float chosenSpeed = min(maxSpeed, neededSpeed);

    to.normalize();
    Vec2 vel = to.mul(chosenSpeed);
    body.setLinearVelocity(vel);

    float a = body.getAngle();
    float angVel = (-a) * 8.0f;
    body.setAngularVelocity(angVel);

    return false;
  }

  void draw() {
    Vec2 pos = box2d.getBodyPixelCoord(body);
    float a = body.getAngle();

    pushMatrix();
    translate(pos.x, pos.y);
    rotate(-a);

    if (ch == ' ') {
      noFill();
      noStroke();
      popMatrix();
      return;
    }

    noStroke();
    fill(col, col, col);
    textAlign(CENTER, CENTER);
    textFont(font, textSizePx);
    text(str(ch), 0, 0);

    popMatrix();
  }
}
