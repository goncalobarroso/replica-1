void initializeSentences() {
  sentences.clear();
  for (String s : sentencesPool) {
    sentences.add(s);
  }
  reshuffleSentences();
}

void initializeFont() {
  font = createFont("Montserrat-Bold.ttf", baseTextSizePx, true);
  textFont(font, baseTextSizePx);
  textAlign(CENTER, CENTER);
}

void initializePhysics() {
  box2d = new Box2DProcessing(this);
  box2d.createWorld(new Vec2(0, 0));
  box2d.setGravity(0, 0);

  mouseBody = createKinematicCircle(mouseX, mouseY, mouseRadius);
  Vec2 mw = box2d.coordPixelsToWorld(mouseX, mouseY);
  prevMouseWorld.set(mw.x, mw.y);
}

void updateMouseCollider() {
  Vec2 targetWorld = box2d.coordPixelsToWorld(mouseX, mouseY);
  Vec2 velocity = new Vec2(
    (targetWorld.x - prevMouseWorld.x) / FIXED_DT,
    (targetWorld.y - prevMouseWorld.y) / FIXED_DT
  );
  mouseBody.setLinearVelocity(velocity);
  mouseBody.setTransform(targetWorld, 0);
  prevMouseWorld.set(targetWorld.x, targetWorld.y);
}

void attractLettersToCenter() {
  Vec2 centerWorld = box2d.coordPixelsToWorld(width / 2f, height / 2f);
  float k = 6.0f;
  for (LetterBody lb : letters) {
    Vec2 toCenter = centerWorld.sub(lb.body.getPosition().clone());
    lb.body.applyForceToCenter(toCenter.mul(k));
  }
}

void updateLetterColors() {
  for (LetterBody lb : letters) {
    lb.updateColor(FIXED_DT);
  }
}

void renderLetters() {
  for (LetterBody lb : letters) {
    lb.draw();
  }
}
