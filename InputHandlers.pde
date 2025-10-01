void mousePressed() {
  if (mouseButton == LEFT && !draggingSentence) {
    if (nextSentenceIndex >= shuffled.size()) {
      reshuffleSentences();
    }
    String sentence = shuffled.get(nextSentenceIndex++);
    activeSentence = spawnSentence(sentence, mouseX, mouseY, true);
    draggingSentence = true;
  }
}

void mouseReleased() {
  if (!draggingSentence) {
    return;
  }
  for (LetterBody lb : activeSentence) {
    lb.gathering = false;
    lb.body.setType(BodyType.DYNAMIC);
    lb.body.setLinearVelocity(new Vec2());
    lb.body.setAngularVelocity(0);
    lb.fadeToGray();
  }
  activeSentence.clear();
  draggingSentence = false;
}

void keyTyped() {
  if (Character.isLetter(key)) {
    addLetter(key, mouseX, mouseY, false);
    builder += key;
  } else if (key == ' ') {
    builder += ' ';
  }
}

void keyPressed() {
  if (keyCode == ENTER || keyCode == RETURN) {
    if (builder.length() > 0) {
      String word = builder;
      float startX = mouseX - (word.length() - 1) * TYPED_SPACE_STEP;
      for (int i = 0; i < word.length(); i++) {
        char c = word.charAt(i);
        if (c == ' ') {
          startX += TYPED_SPACE_STEP;
          continue;
        }
        addLetter(c, startX + i * TYPED_LETTER_STEP, mouseY, false);
      }
    }
    builder = "";
  } else if (key == BACKSPACE && builder.length() > 0) {
    builder = builder.substring(0, builder.length() - 1);
  }
}
