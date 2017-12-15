import ddf.minim.*;
import java.time.*;

Minim minim;
AudioInput in;
float gain = 1000; // amplitude of waves (500 works better for music)
int timebase = 1024;
float[] soundBuffer;
float[] fades;

float zoff; float yoff; // Offsets for 3D tranform
float y; float z; // Initial locations for each line
ArrayList<Waveform> lines = new ArrayList<Waveform>();


void setup(){
  // set up processing environment
  fullScreen(P3D);
  stroke(255);
  frameRate(30);
  noFill();
  noCursor();
  z = 1000;
  y = (height/10)*6;
  {  // initialize output array with flat Waveforms
    while(lines.size()<30){
      ArrayList<Float> spectrum = new ArrayList<Float>();
      spectrum.add(0.0);
      Waveform wave = new Waveform(spectrum,30.0,timebase);
      lines.add(wave);
    }
  }
  {  // initialize sound input
    minim = new Minim(this);
    in = minim.getLineIn(Minim.MONO,2048);
    soundBuffer = new float[in.bufferSize()];
  }
  {  // inialize waveform fade in/out
    fades = new float[min(timebase,soundBuffer.length)];
    int fade;
    fade = int(-gain);
    for(int i=0;i<fades.length/5;i++){
      fades[i] = fade;
      fade /= 1 + (gain/1000 * 0.024);
    }
    fade = int(-gain);
    for(int i=fades.length-1;i>((fades.length/5)*4);i--){
      //print("index: " + i + ", " + "fade: " + fade);
      fades[i] = fade;
      fade /= 1 + (gain/1000 * 0.024);
    }
  }
}

void draw(){
  // reset image
  rotateX(-PI/16); // "camera angle"
  translate(400,500,-800); // "camera position"
  background(0);
  yoff=0; zoff=0;
  // shift input by one position
  lines.remove(0);
  lines.add(generateLine());
  // draw lines
  for(int i=lines.size()-1;i>=0;i--){
    translate(0,yoff,zoff);
    lines.get(i).display();
    zoff-=40;
    yoff-=10;
  }
}

void keyPressed(){
  // dont take picture if escaping
  if(key == ESC) {
     // immediatly stop instead
     stop();
  } else {
    // save frame on key press
    saveFrame("output/"+Instant.now().toString()+".tga");
  }
}

void stop(){
  // closing sound inputs
  in.close();
  minim.stop();
  super.stop();
}

class Waveform {
  PShape w;
  ArrayList<Float> spectrum;
  float amplitude;
  int stretch;

  Waveform(ArrayList<Float> d_, float a_, int s_) {
    spectrum = d_;
    amplitude = a_;
    stretch = s_;
  }

  void display(){
    w = createShape();
    w.beginShape();
    w.vertex(width*-5,y,z);
    w.vertex(width/8,y,z);
    for(int i = 0; i < spectrum.size(); i++){
      w.vertex(map(i,0,stretch,width/8,width/8*7),y - spectrum.get(i)*(gain+fades[i]),z);
    }
    w.vertex(width/8*7,y,z);
    w.vertex(width*6,y,z);
    w.endShape();
    shape(w);
  }
}

Waveform generateLine(){
  //collect data from sound buffer in oscilloscope style
// START CODE TAKEN FROM Dan Ellis dpwe@ee.columbia.edu
  // first grab a stationary copy
  for (int i = 0; i < in.bufferSize(); ++i) {
    soundBuffer[i] = in.left.get(i);
  }
  // find trigger point as largest +ve slope in first 1/4 of buffer
  int offset = 0;
  float maxdx = 0;
  for(int i = 0; i < soundBuffer.length/4; ++i){
      float dx = soundBuffer[i+1] - soundBuffer[i];
      if (dx > maxdx){
        offset = i;
        maxdx = dx;
      }
  }
// END CODE INSERTION (original file in resources folder)
  // generate Waveform with collected sound data
  ArrayList<Float> vertices = new ArrayList<Float>();
  int linelength = min(timebase, soundBuffer.length-offset);
  for(int i = 0; i < linelength - 1; i++){
    vertices.add(soundBuffer[i+offset]);
  }
  Waveform wave = new Waveform(vertices,gain,timebase);
  return wave;
}


/**

Next Steps
  Clean up code and make more efficient
  Add adjustable gain
  Fix Bug where first two lines are too close
    (seriously i have no clue why this is happening)

Used to following java references
  ArrayList
  Vector
  Queue
  AudioSystem
  Instant

Used the following processing references
  perspective
  shape
  PShape
  AudioIn
  AudioDevice
  FFT

Used the following processing tutorials
  P3D

Used the following processing examples
  NoiseWave

Used the following external code
  Oscilloscope: 2010-01-25 Dan Ellis (dpwe@ee.columbia.edu)
      From https://www.ee.columbia.edu/~dpwe/resources/Processing/
      Saved to ./ressources/oscilloscope
*/
