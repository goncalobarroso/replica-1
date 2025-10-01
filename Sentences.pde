void reshuffleSentences() {
  shuffled.clear();
  shuffled.addAll(sentences);
  java.util.Collections.shuffle(shuffled);
  nextSentenceIndex = 0;
}

void alignActiveSentenceToMouse(boolean highlight) {
  setSentenceTargetsAt(mouseX, mouseY);
  if (highlight) {
    for (LetterBody lb : activeSentence) {
      lb.targetCol = 255;
    }
  }
}

void updateActiveSentenceGathering() {
  for (LetterBody lb : activeSentence) {
    if (lb.body.getType() == BodyType.KINEMATIC) {
      lb.updateKinematicChase();
    }
  }
}

void setSentenceTargetsAt(float cx, float cy) {
  if (activeSentence.isEmpty()) {
    return;
  }

  float totalWidth = computeSentenceWidth(activeSentence);
  float x = cx - totalWidth / 2.0f;

  for (LetterBody lb : activeSentence) {
    float coreWidth = letterCoreWidth(lb.ch);
    float drawX = x + coreWidth / 2.0f;
    lb.setTargetPx(drawX, cy);
    x += letterAdvance(lb.ch, coreWidth);
  }
}

ArrayList<LetterBody> spawnSentence(String sentence, float centerX, float centerY, boolean kinematic) {
  ArrayList<LetterBody> spawned = new ArrayList<LetterBody>();
  float marginPx = max(width, height) * 0.15f;

  float totalWidth = computeSentenceWidth(sentence);
  float targetX = centerX - totalWidth / 2.0f;

  for (int i = 0; i < sentence.length(); i++) {
    char c = sentence.charAt(i);
    float coreWidth = letterCoreWidth(c);
    float drawTX = targetX + coreWidth / 2.0f;

    PVector spawn = randomOffscreen(marginPx);
    LetterBody lb = (c == ' ')
      ? addLetter(' ', spawn.x, spawn.y, kinematic, coreWidth)
      : addLetter(c, spawn.x, spawn.y, kinematic);

    lb.setWhiteInstant();

    float ang = random(-PI, PI);
    Vec2 posW = box2d.coordPixelsToWorld(spawn.x, spawn.y);
    lb.body.setTransform(posW, ang);

    lb.setTargetPx(drawTX, centerY);
    spawned.add(lb);

    targetX += letterAdvance(c, coreWidth);
  }

  return spawned;
}

float computeSentenceWidth(String sentence) {
  float total = 0;
  for (int i = 0; i < sentence.length(); i++) {
    char c = sentence.charAt(i);
    float coreWidth = letterCoreWidth(c);
    total += letterAdvance(c, coreWidth);
  }
  return total;
}

float computeSentenceWidth(ArrayList<LetterBody> bodies) {
  float total = 0;
  for (LetterBody lb : bodies) {
    float coreWidth = letterCoreWidth(lb.ch);
    total += letterAdvance(lb.ch, coreWidth);
  }
  return total;
}

PVector randomOffscreen(float marginPx) {
  int edge = (int) random(4);
  switch (edge) {
    case 0:
      return new PVector(-marginPx, random(-marginPx, height + marginPx));
    case 1:
      return new PVector(width + marginPx, random(-marginPx, height + marginPx));
    case 2:
      return new PVector(random(-marginPx, width + marginPx), -marginPx);
    default:
      return new PVector(random(-marginPx, width + marginPx), height + marginPx);
  }
}
