// Processing 4 — Letters using your hand-authored 4-vertex boxes (Box2D)
// - Loads letter_boxes.json with 4 centered vertices per glyph (A–Z, a–z)
// - Click to spawn a random sentence (centered on mouse), follows mouse while held
// - Release mouse to turn it into normal dynamic letters

// TODO:
// - parte estetica (cores, fade das frases)
// - spawn das letras off-screen e com rotação

import shiffman.box2d.*;
import org.jbox2d.collision.shapes.*;
import org.jbox2d.common.*;
import org.jbox2d.dynamics.*;

Box2DProcessing box2d;

ArrayList<LetterBody> letters = new ArrayList<LetterBody>();
ArrayList<LetterBody> activeSentence = new ArrayList<LetterBody>(); // current sentence letters being placed
boolean draggingSentence = false;

Body mouseBody;                        // kinematic "mouse collider"
float mouseRadius = 2.0f;              // meters (~20 px)
PVector prevMouseWorld = new PVector();

float bboxFineTune = 0.95;

PFont font;
float baseTextSizePx = 96;             // visual target sizing

// ---- Loaded authoring data ----
HashMap<Character, float[][]> letterVerts = new HashMap<Character, float[][]>(); // 4x2 px verts (centered)
float authoringSizePx = 220;           // fallback; overwritten by JSON if present

String builder = "";                   // type letters, ENTER to spawn the word

float letterSpacingFactor = 1.1;  // space between letters relative to glyph width
float wordSpacingFactor = 0.5;    // space between words relative to average letter width


// ----- Sentences -----
String[] sentencesPool = {
  "Hello world",
  "Processing is fun",
  "Typography is fun",
  "marcacos is fun"
};
ArrayList<String> sentences = new ArrayList<String>();
ArrayList<String> shuffled = new ArrayList<String>();
int nextSentenceIndex = 0;

void settings() { size(960, 540); }

void setup() {
  // Prepare sentence list
  for (String s : sentencesPool) sentences.add(s);
  reshuffleSentences();

  // Font
  font = createFont("Montserrat-Bold.ttf", baseTextSizePx, true);
  textFont(font, baseTextSizePx);
  textAlign(CENTER, CENTER);

  // Load authored vertices
  loadLetterBoxesJSON("letter_boxes.json"); // <-- your file

  // Init Box2D world (no gravity)
  box2d = new Box2DProcessing(this);
  box2d.createWorld(new Vec2(0, 0));
  box2d.setGravity(0, 0);

  // Mouse collider
  mouseBody = createKinematicCircle(mouseX, mouseY, mouseRadius);
  Vec2 mw = box2d.coordPixelsToWorld(mouseX, mouseY);
  prevMouseWorld.set(mw.x, mw.y);

  rectMode(CENTER);
  noStroke();
}

void updateActiveSentenceGathering() {
  // letters are KINEMATIC while gathering -> they push DYNAMIC bodies out of the way
  for (LetterBody lb : activeSentence) {
    if (lb.body.getType() == BodyType.KINEMATIC) {
      lb.updateKinematicChase();
    }
  }
}

void draw() {
  background(0);

  // Mouse collider follow
  Vec2 targetWorld = box2d.coordPixelsToWorld(mouseX, mouseY);
  float dt = 1.0f / 60.0f;
  Vec2 vel = new Vec2((targetWorld.x - prevMouseWorld.x) / dt,
                      (targetWorld.y - prevMouseWorld.y) / dt);
  mouseBody.setLinearVelocity(vel);
  mouseBody.setTransform(targetWorld, 0);
  prevMouseWorld.set(targetWorld.x, targetWorld.y);

  // If we’re dragging a sentence, update its position to follow mouse
  if (draggingSentence && activeSentence.size() > 0) {
    setSentenceTargetsAt(mouseX, mouseY);
  }

  // Gentle attraction to center
  Vec2 centerWorld = box2d.coordPixelsToWorld(width/2f, height/2f);
  float k = 6.0f;
  for (LetterBody lb : letters) {
    Vec2 toCenter = centerWorld.sub(lb.body.getPosition().clone());
    lb.body.applyForceToCenter(toCenter.mul(k));
  }

  // Physics step
  box2d.step();
  
  for (LetterBody lb : letters) {
    lb.updateColor(1.0f/60.0f);   // same dt you use elsewhere
    lb.draw();
  }

  // Draw letters (polygon hitbox + glyph)
  for (LetterBody lb : letters) lb.draw();
  
  // If dragging, keep targets centered at cursor (letters will chase targets)
  if (draggingSentence && !activeSentence.isEmpty()) {
    setSentenceTargetsAt(mouseX, mouseY);
    for (LetterBody lb : activeSentence) lb.targetCol = 255;
  }
  // advance the kinematic chase
  updateActiveSentenceGathering();
  
  // UI
  /*
  fill(0, 120);
  textAlign(LEFT, TOP);
  textSize(16);
  text("Click to spawn a random sentence.\nDrag with mouse, release to drop it.\nType letters and press ENTER to drop words.\nCurrent: " + builder, 12, 10);
  textAlign(CENTER, CENTER);
  textSize(baseTextSizePx);*/
}

void reshuffleSentences() {
  shuffled.clear();
  shuffled.addAll(sentences);
  java.util.Collections.shuffle(shuffled);
  nextSentenceIndex = 0;
}

/* -------------------- Mouse control -------------------- */

// Returns a random point just outside the viewport
PVector randomOffscreen(float marginPx) {
  int edge = (int)random(4); // 0=left,1=right,2=top,3=bottom
  switch (edge) {
    case 0: return new PVector(-marginPx, random(-marginPx, height+marginPx));
    case 1: return new PVector(width+marginPx, random(-marginPx, height+marginPx));
    case 2: return new PVector(random(-marginPx, width+marginPx), -marginPx);
    default:return new PVector(random(-marginPx, width+marginPx), height+marginPx);
  }
}

// For current active sentence, recompute each letter's target so it is centered at (cx,cy)
void setSentenceTargetsAt(float cx, float cy) {
  if (activeSentence.isEmpty()) return;

  // measure total width using your existing logic
  float totalWidth = 0;
  for (LetterBody lb : activeSentence) {
    if (lb.ch == ' ') totalWidth += baseTextSizePx * wordSpacingFactor;
    else              totalWidth += measureLetterWidthPx(lb.ch) * letterSpacingFactor;
  }

  float x = cx - totalWidth / 2.0;
  for (LetterBody lb : activeSentence) {
    float w = (lb.ch == ' ') ? baseTextSizePx * wordSpacingFactor : measureLetterWidthPx(lb.ch);
    float drawX = x + w/2.0f;
    lb.setTargetPx(drawX, cy);        // <- do not teleport, set target
    x += (lb.ch == ' ') ? w : (w * letterSpacingFactor);
  }
}


void mousePressed() {
  if (mouseButton == LEFT && !draggingSentence) {
    if (nextSentenceIndex >= shuffled.size()) {
      reshuffleSentences(); // start a new cycle
    }
    String sentence = shuffled.get(nextSentenceIndex++);
    activeSentence = spawnSentence(sentence, mouseX, mouseY, true); // true = kinematic group
    draggingSentence = true;
  }
}

void mouseReleased() {
  if (draggingSentence) {
    for (LetterBody lb : activeSentence) {
      lb.gathering = false;
      lb.body.setType(BodyType.DYNAMIC);
      lb.body.setLinearVelocity(new Vec2());
      lb.body.setAngularVelocity(0);
      lb.fadeToGray();  // begin fade toward (49,49,49)
    }
    activeSentence.clear();
    draggingSentence = false;
  }
}

/* -------------------- Add letters (uses authored verts) -------------------- */
float measureLetterWidthPx(char c) {
  float[][] vertsAuthPx = letterVerts.get(c);
  if (vertsAuthPx != null) {
    // Use authored box width
    float minX = Float.MAX_VALUE;
    float maxX = -Float.MAX_VALUE;
    for (int i = 0; i < 4; i++) {
      if (vertsAuthPx[i][0] < minX) minX = vertsAuthPx[i][0];
      if (vertsAuthPx[i][0] > maxX) maxX = vertsAuthPx[i][0];
    }
    return (maxX - minX) * bboxFineTune * (baseTextSizePx / authoringSizePx);
  } else {
    // Fallback to textWidth if no authored data
    return textWidth(str(c));
  }
}

// Tight bounds for a glyph rendered at a given pixel size (width, height) in pixels.
float[] measureGlyphTightPx(char ch, float sizePx) {
  int pad = (int)(sizePx * 3);
  PGraphics pg = createGraphics(pad, pad, JAVA2D);
  pg.beginDraw();
  pg.clear();
  pg.textFont(font, sizePx);
  pg.textAlign(CENTER, CENTER);
  pg.fill(0xFF);
  float cx = pg.width * 0.5f, cy = pg.height * 0.5f;
  pg.text(str(ch), cx, cy);
  pg.endDraw();
  pg.loadPixels();

  int w = pg.width, h = pg.height;
  int minX = w, minY = h, maxX = -1, maxY = -1;
  for (int y = 0; y < h; y++) {
    int row = y * w;
    for (int x = 0; x < w; x++) {
      int a = (pg.pixels[row + x] >>> 24) & 0xFF;
      if (a != 0) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  if (maxX < minX || maxY < minY) return new float[]{0,0};
  return new float[]{ (maxX - minX + 1), (maxY - minY + 1) };
}

ArrayList<LetterBody> spawnSentence(String sentence, float centerX, float centerY, boolean kinematic) {
  ArrayList<LetterBody> spawned = new ArrayList<LetterBody>();
  float marginPx = max(width, height) * 0.15f;

  // First compute the *targets* laid out around (centerX, centerY)
  // (same width pass as before)
  float totalWidth = 0;
  for (int i = 0; i < sentence.length(); i++) {
    char c = sentence.charAt(i);
    if (c == ' ') totalWidth += baseTextSizePx * wordSpacingFactor;
    else          totalWidth += measureLetterWidthPx(c) * letterSpacingFactor;
  }
  float tx = centerX - totalWidth / 2.0;

  // Second pass: create each letter OFF-SCREEN with random angle, but assign target
  for (int i = 0; i < sentence.length(); i++) {
    char c = sentence.charAt(i);
    float targetW = (c == ' ') ? baseTextSizePx * wordSpacingFactor : measureLetterWidthPx(c);
    float drawTX = tx + targetW / 2.0f;

    // where it will end up
    float targetX = drawTX;
    float targetY = centerY;

    // where it spawns (off-screen)
    PVector spawn = randomOffscreen(marginPx);
    LetterBody lb; 
    
    if (c == ' ') {
      // spaces get a thin kinematic box so they contribute to pushing while gathering
      lb = addLetter(' ', spawn.x, spawn.y, true, targetW);
    } else {
      lb = addLetter(c, spawn.x, spawn.y, true);
    }

    lb.setWhiteInstant();
    
    // random rotation on spawn
    float ang = random(-PI, PI);
    Vec2 posW = box2d.coordPixelsToWorld(spawn.x, spawn.y);
    lb.body.setTransform(posW, ang);

    // mark as gathering toward its layout target
    lb.setTargetPx(targetX, targetY);

    spawned.add(lb);
    tx += (c == ' ') ? targetW : (targetW * letterSpacingFactor);
  }
  
  return spawned;
}


void centerActiveSentenceAt(float centerX, float centerY) {
  if (activeSentence.isEmpty()) return;

  // Recalculate total width based on actual letter widths
  float totalWidth = 0;
  for (LetterBody lb : activeSentence) {
    totalWidth += measureLetterWidthPx(lb.ch) * letterSpacingFactor;
  }

  float x = centerX - totalWidth / 2.0;

  // Move each letter in the active sentence
  for (LetterBody lb : activeSentence) {
    float letterW = measureLetterWidthPx(lb.ch);
    float drawX = x + letterW / 2.0;
    Vec2 newPos = box2d.coordPixelsToWorld(drawX, centerY);
    lb.body.setTransform(newPos, 0);
    lb.body.setLinearVelocity(new Vec2(0, 0));
    x += letterW * letterSpacingFactor;
  }
}

LetterBody addLetter(char c, float xPx, float yPx, boolean kinematic) {
  return addLetter(c, xPx, yPx, kinematic, -1);
}

LetterBody addLetter(char c, float xPx, float yPx, boolean kinematic, float customWidthPx) {
  // --- Special case: space character ---
  if (c == ' ' && customWidthPx > 0) {
    BodyDef bd = new BodyDef();
    bd.type = kinematic ? BodyType.KINEMATIC : BodyType.DYNAMIC;
    bd.position.set(box2d.coordPixelsToWorld(xPx, yPx));
    Body b = box2d.world.createBody(bd);

    float wMeters = box2d.scalarPixelsToWorld(customWidthPx);
    float hMeters = box2d.scalarPixelsToWorld(baseTextSizePx * 0.25f); // small height for space body

    PolygonShape ps = new PolygonShape();
    ps.setAsBox(wMeters / 2f, hMeters / 2f);

    FixtureDef fd = new FixtureDef();
    fd.shape = ps;
    fd.density = 0.1f; // lighter than letters
    fd.friction = 0.1f;
    fd.restitution = 0.0f;
    b.createFixture(fd);

    b.setLinearDamping(0.9f);
    b.setAngularDamping(0.9f);

    // Create invisible LetterBody for the space
    LetterBody lb = new LetterBody(b, ' ', null, 0);
    letters.add(lb);
    return lb;
  }

  // --- Regular letter logic below ---
  float[][] vertsAuthPx = letterVerts.get(c);
  if (vertsAuthPx == null) {
    char alt = Character.isUpperCase(c) ? Character.toLowerCase(c) : Character.toUpperCase(c);
    vertsAuthPx = letterVerts.get(alt);
  }

  float s = 1.0f;
  if (vertsAuthPx != null) {
    float[] authWH = measureGlyphTightPx(c, authoringSizePx);
    float[] currWH = measureGlyphTightPx(c, baseTextSizePx);
    float authMax = max(authWH[0], authWH[1]);
    float currMax = max(currWH[0], currWH[1]);
    s = (authMax > 0) ? (currMax / authMax) : 1.0f;
    s *= bboxFineTune;
  }

  Vec2[] vsWorld = null;
  PVector[] localVertsPx = null;
  if (vertsAuthPx != null) {
    vsWorld = new Vec2[4];
    localVertsPx = new PVector[4];
    for (int i = 0; i < 4; i++) {
      float px = vertsAuthPx[i][0] * s;
      float py = vertsAuthPx[i][1] * s;
      localVertsPx[i] = new PVector(px, py);
      vsWorld[i] = new Vec2(box2d.scalarPixelsToWorld(px), box2d.scalarPixelsToWorld(py));
    }
  }

  BodyDef bd = new BodyDef();
  bd.type = kinematic ? BodyType.KINEMATIC : BodyType.DYNAMIC;
  bd.position.set(box2d.coordPixelsToWorld(xPx, yPx));
  Body b = box2d.world.createBody(bd);

  if (vertsAuthPx != null) {
    PolygonShape poly = new PolygonShape();
    poly.set(vsWorld, 4);
    FixtureDef fd = new FixtureDef();
    fd.shape = poly;
    fd.density = 1.05f;
    fd.friction = 0.45f;
    fd.restitution = 0.22f;
    b.createFixture(fd);
  } else {
    float glyphW = max(1, textWidth(str(c)));
    float glyphH = textAscent() + textDescent();
    float squarePx = max(glyphW, glyphH);
    float sideMeters = box2d.scalarPixelsToWorld(squarePx);
    PolygonShape ps = new PolygonShape();
    ps.setAsBox(sideMeters / 2f, sideMeters / 2f);
    FixtureDef fd = new FixtureDef();
    fd.shape = ps;
    fd.density = 1.1f;
    fd.friction = 0.45f;
    fd.restitution = 0.22f;
    b.createFixture(fd);
  }

  b.setLinearDamping(0.9f);
  b.setAngularDamping(0.9f);

  float textSizePx = baseTextSizePx * 0.9f;
  LetterBody lb = new LetterBody(b, c, localVertsPx, textSizePx);
  letters.add(lb);
  return lb;
}


/* -------------------- Input typing (unchanged) -------------------- */

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
    String word = builder;
    if (word.length() > 0) {
      float startX = mouseX - (word.length() - 1) * 28;
      for (int i = 0; i < word.length(); i++) {
        char c = word.charAt(i);
        if (c == ' ') {
          startX += 28;
          continue;
        }
        addLetter(c, startX + i * 56, mouseY, false);
      }
    }
    builder = "";
  } else if (key == BACKSPACE && builder.length() > 0) {
    builder = builder.substring(0, builder.length() - 1);
  }
}

/* -------------------- JSON loader -------------------- */

void loadLetterBoxesJSON(String filename) {
  try {
    JSONObject root = loadJSONObject(filename);
    if (root == null) {
      println("Could not load " + filename + " — continuing without authored boxes.");
      return;
    }
    if (root.hasKey("previewSizePx")) {
      authoringSizePx = root.getFloat("previewSizePx");
    }
    JSONObject lettersObj = root.getJSONObject("letters");
    if (lettersObj == null) {
      println("No 'letters' object in " + filename + ".");
      return;
    }

    letterVerts.clear();
    for (Object k : lettersObj.keys()) {
      String key = (String) k;
      JSONArray arr = lettersObj.getJSONArray(key);
      if (arr == null || arr.size() != 4) continue;
      float[][] verts = new float[4][2];
      for (int i = 0; i < 4; i++) {
        JSONArray v = arr.getJSONArray(i);
        verts[i][0] = v.getFloat(0); // x in pixels (centered)
        verts[i][1] = v.getFloat(1); // y in pixels (centered)
      }
      letterVerts.put(key.charAt(0), verts);
    }
    println("Loaded " + letterVerts.size() + " authored letter boxes from " + filename +
            " (authoring size px: " + authoringSizePx + ").");
  } catch (Exception e) {
    println("Error loading " + filename + ": " + e.getMessage());
  }
}

/* -------------------- Utilities -------------------- */

// Return the long side length (in px) of a 4-vertex quad (assumed ordered loop around center)
float quadLongSide(float[][] v) {
  float e0 = dist(v[0][0], v[0][1], v[1][0], v[1][1]);
  float e1 = dist(v[1][0], v[1][1], v[2][0], v[2][1]);
  float e2 = dist(v[2][0], v[2][1], v[3][0], v[3][1]);
  float e3 = dist(v[3][0], v[3][1], v[0][0], v[0][1]);
  return max(max(e0, e1), max(e2, e3));
}

/* -------------------- Mouse collider -------------------- */

Body createKinematicCircle(float xPx, float yPx, float radiusMeters) {
  BodyDef bd = new BodyDef();
  bd.type = BodyType.KINEMATIC;
  bd.position.set(box2d.coordPixelsToWorld(xPx, yPx));
  Body b = box2d.world.createBody(bd);

  CircleShape cs = new CircleShape();
  cs.m_radius = radiusMeters;

  FixtureDef fd = new FixtureDef();
  fd.shape = cs;
  fd.density = 1.0f;
  fd.friction = 0.0f;
  fd.restitution = 0.0f;
  b.createFixture(fd);
  return b;
}

/* -------------------- Letter drawable -------------------- */

class LetterBody {
  Body body;
  char ch;
  PVector[] localVertsPx;  // null == fallback square
  float textSizePx;
  boolean gathering = false;    // while true, this letter moves toward target as KINEMATIC
  PVector targetPx = new PVector(); // where the glyph should end up (in pixels)
  float gatherSpeedMeters = 1000.0f;  // kinematic chase speed in world units/sec
  float arriveEpsMeters = 0.02f;    // when we're "close enough" to snap
  float col = 255;                // current grayscale (0..255)
  float targetCol = 255;          // where we're fading to
  float fadeRatePerSec = 300;     // <<< tweak this: units per second
  
  void setWhiteInstant() {
    col = 255;
    targetCol = 255;
  }
  
  void fadeToGray() {             // call on mouse release
    targetCol = 49;
  }
  
  void updateColor(float dt) {
    if (abs(col - targetCol) < 0.5f) { col = targetCol; return; }
    float dir = (targetCol > col) ? 1 : -1;
    col += dir * fadeRatePerSec * dt;
    if ((dir > 0 && col > targetCol) || (dir < 0 && col < targetCol)) col = targetCol;
  }
  
  
  void setTargetPx(float x, float y) {
    targetPx.set(x, y);
    gathering = true;
  }
  
  boolean updateKinematicChase() {
    if (!gathering) return false;
    
    // Move body toward target and damp the angle to 0
    Vec2 targetW = box2d.coordPixelsToWorld(targetPx.x, targetPx.y);
    Vec2 posW = body.getPosition().clone();
    Vec2 to = targetW.sub(posW);
    float dist = to.length();
  
     // --- arrival snap ---
    if (dist < arriveEpsMeters) {
      body.setTransform(targetW, 0);
      body.setLinearVelocity(new Vec2());
      body.setAngularVelocity(0);
      gathering = false;
      return true;  
    }
  
    // --- move toward target without overshooting ---
    float dt = 1.0f / 60.0f;                 // your sketch runs at 60 Hz
    float maxSpeed = gatherSpeedMeters;       // m/s
    float neededSpeed = dist / dt;            // exact speed to arrive next step
    float chosenSpeed = min(maxSpeed, neededSpeed);
  
    to.normalize();
    Vec2 vel = to.mul(chosenSpeed);
    body.setLinearVelocity(vel);
  
    // rotate toward upright
    float a = body.getAngle();
    float angVel = (-a) * 8.0f;
    body.setAngularVelocity(angVel);
  
    return false;
  }


  LetterBody(Body b, char c, PVector[] vertsPx, float textSizePx) {
    this.body = b;
    this.ch = c;
    this.localVertsPx = vertsPx;
    this.textSizePx = textSizePx;
  }
  

  void draw() {
    Vec2 pos = box2d.getBodyPixelCoord(body);
    float a = body.getAngle();
    
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(-a);
  
    // --- Invisible SPACE handling ---
    if (ch == ' ') {
      // Draw an invisible rectangle for debugging / placeholder
      // (No stroke, no fill — but it still exists as a body)
      noFill();
      noStroke();
      // If you want to *see* the space for debugging, uncomment below:
      // fill(255, 0, 0, 50);
      // rectMode(CENTER);
      // rect(0, 0, baseTextSizePx * wordSpacingFactor, baseTextSizePx * 0.25f);
      popMatrix();
      return;
    }

    // Draw the letter glyph centered inside
    noStroke();
    fill(col, col, col);
    textAlign(CENTER, CENTER);
    textFont(font, textSizePx);
    text(str(ch), 0, 0);
  
    popMatrix();
  }
}
