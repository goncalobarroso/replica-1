float letterCoreWidth(char c) {
  return (c == ' ') ? baseTextSizePx * wordSpacingFactor : measureLetterWidthPx(c);
}

float letterAdvance(char c, float coreWidth) {
  return (c == ' ') ? coreWidth : coreWidth * letterSpacingFactor;
}

float measureLetterWidthPx(char c) {
  float[][] vertsAuthPx = letterVerts.get(c);
  if (vertsAuthPx != null) {
    float minX = Float.MAX_VALUE;
    float maxX = -Float.MAX_VALUE;
    for (int i = 0; i < 4; i++) {
      minX = min(minX, vertsAuthPx[i][0]);
      maxX = max(maxX, vertsAuthPx[i][0]);
    }
    return (maxX - minX) * bboxFineTune * (baseTextSizePx / authoringSizePx);
  }
  return textWidth(str(c));
}

float[] measureGlyphTightPx(char ch, float sizePx) {
  int pad = (int) (sizePx * 3);
  PGraphics pg = createGraphics(pad, pad, JAVA2D);
  pg.beginDraw();
  pg.clear();
  pg.textFont(font, sizePx);
  pg.textAlign(CENTER, CENTER);
  pg.fill(0xFF);
  float cx = pg.width * 0.5f;
  float cy = pg.height * 0.5f;
  pg.text(str(ch), cx, cy);
  pg.endDraw();
  pg.loadPixels();

  int w = pg.width;
  int h = pg.height;
  int minX = w;
  int minY = h;
  int maxX = -1;
  int maxY = -1;
  for (int y = 0; y < h; y++) {
    int row = y * w;
    for (int x = 0; x < w; x++) {
      int a = (pg.pixels[row + x] >>> 24) & 0xFF;
      if (a != 0) {
        minX = min(minX, x);
        maxX = max(maxX, x);
        minY = min(minY, y);
        maxY = max(maxY, y);
      }
    }
  }
  if (maxX < minX || maxY < minY) {
    return new float[]{0, 0};
  }
  return new float[]{(maxX - minX + 1), (maxY - minY + 1)};
}

LetterBody addLetter(char c, float xPx, float yPx, boolean kinematic) {
  return addLetter(c, xPx, yPx, kinematic, -1);
}

LetterBody addLetter(char c, float xPx, float yPx, boolean kinematic, float customWidthPx) {
  if (c == ' ' && customWidthPx > 0) {
    BodyDef bd = new BodyDef();
    bd.type = kinematic ? BodyType.KINEMATIC : BodyType.DYNAMIC;
    bd.position.set(box2d.coordPixelsToWorld(xPx, yPx));
    Body b = box2d.world.createBody(bd);

    float wMeters = box2d.scalarPixelsToWorld(customWidthPx);
    float hMeters = box2d.scalarPixelsToWorld(baseTextSizePx * 0.25f);

    PolygonShape ps = new PolygonShape();
    ps.setAsBox(wMeters / 2f, hMeters / 2f);

    FixtureDef fd = new FixtureDef();
    fd.shape = ps;
    fd.density = 0.1f;
    fd.friction = 0.1f;
    fd.restitution = 0.0f;
    b.createFixture(fd);

    b.setLinearDamping(0.9f);
    b.setAngularDamping(0.9f);

    LetterBody lb = new LetterBody(b, ' ', null, 0);
    letters.add(lb);
    return lb;
  }

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

  b.setLinearDamping(0.3f);
  b.setAngularDamping(0.9f);

  float textSizePx = baseTextSizePx * 0.9f;
  LetterBody lb = new LetterBody(b, c, localVertsPx, textSizePx);
  letters.add(lb);
  return lb;
}
