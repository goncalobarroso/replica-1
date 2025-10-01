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
