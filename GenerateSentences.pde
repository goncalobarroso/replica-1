void drawInitialLetters(int n){
  for (int i=0; i<n; i++){
    addLetter((char) ('a' + int(random(26))), width/2, height/2, false);
  }
}
