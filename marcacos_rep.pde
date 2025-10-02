import shiffman.box2d.*;
import org.jbox2d.collision.shapes.*;
import org.jbox2d.common.*;
import org.jbox2d.dynamics.*;

final float FIXED_DT = 1.0f / 60.0f;
final float TYPED_LETTER_STEP = 56;
final float TYPED_SPACE_STEP = 28;

Box2DProcessing box2d;

ArrayList<LetterBody> letters = new ArrayList<LetterBody>();
ArrayList<LetterBody> activeSentence = new ArrayList<LetterBody>();
boolean draggingSentence = false;

Body mouseBody;
float mouseRadius = 4.0f;
PVector prevMouseWorld = new PVector();

float bboxFineTune = 0.95;

PFont font;
float baseTextSizePx = 96;

HashMap<Character, float[][]> letterVerts = new HashMap<Character, float[][]>();
float authoringSizePx = 220;

String builder = "";

float letterSpacingFactor = 1.1;
float wordSpacingFactor = 0.5;

String[] sentencesPool = {
  "Hello world",
  "Processing is fun.",
  "Typography is fun",
  "marcacos is fun"
};
ArrayList<String> sentences = new ArrayList<String>();
ArrayList<String> shuffled = new ArrayList<String>();
int nextSentenceIndex = 0;

void settings() { size(960, 540); }

void setup() {
  initializeSentences();
  initializeFont();
  loadLetterBoxesJSON("letter_boxes.json");
  initializePhysics();
  rectMode(CENTER);
  noStroke();
  drawInitialLetters(100);
}

void draw() {
  background(0);
  
  updateMouseCollider();

  if (draggingSentence && !activeSentence.isEmpty()) {
    alignActiveSentenceToMouse(false);
  }

  attractLettersToCenter();
  box2d.step();

  if (draggingSentence && !activeSentence.isEmpty()) {
    alignActiveSentenceToMouse(true);
  }

  updateLetterColors();
  renderLetters();
  updateActiveSentenceGathering();
  /*
  for(int i=0; i<letters.size(); i++){
    print(letters.get(i).getValue());
  }*/
}
