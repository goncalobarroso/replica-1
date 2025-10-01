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
      if (arr == null || arr.size() != 4) {
        continue;
      }
      float[][] verts = new float[4][2];
      for (int i = 0; i < 4; i++) {
        JSONArray v = arr.getJSONArray(i);
        verts[i][0] = v.getFloat(0);
        verts[i][1] = v.getFloat(1);
      }
      letterVerts.put(key.charAt(0), verts);
    }
    println("Loaded " + letterVerts.size() + " authored letter boxes from " + filename
      + " (authoring size px: " + authoringSizePx + ").");
  } catch (Exception e) {
    println("Error loading " + filename + ": " + e.getMessage());
  }
}
