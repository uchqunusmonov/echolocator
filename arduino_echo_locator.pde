// ----- serial port
import processing.serial.*;                      //import the serial library
Serial myPort;                                   //the Serial port object
final int Baud_rate = 115200;                    //communication speed
String Input_string;                             //used for incoming data 

// -----custom shape
PShape Object;                                   //give the shape a name
int Frame_count = 0;                             //frame counter
boolean Frame_visible = true;                    //true=visible; false=invisible

// ----- display graphics
PGraphics Canvas;                                //name of drawing area to be created
PFont myFont;                                    //name of font to be created
float Baseline = 50;                            //triangle baseline (cm)
float X;                                         //X coordinate in (cm)
float Y;                                         //Y coordinate in (cm)

// ----- sensor distance BELOW baseline (cm)
float Offset = 50;                               //assumes square display

// =========================
// setup
// ==========================
void setup() {

  // ----- configure screen 
  size(800, 800, P3D);                          //define window size, 3D   
  background(0);                                 //black
  frameRate(60);                                 //60 frames per second

  // ----- create a drawing area for fading the beam
  Canvas = createGraphics(width, height);                          

  // ------ create the screen font
  myFont = createFont("Arial Black", 20);

  // ----- configure the Object
  Object = createShape(ELLIPSE, 0, 0, 30, 30);   //create the Object
  Object.setFill(color(255, 0, 0, 255));         //red, opaque
  Object.setStroke(color(255, 0, 0, 255));       //red, opaque

  // ----- initialize the serial port
  /*
    IMPORTANT:
   If your display can't see the arduino try changing the [number] associated 
   with your COM port.
   
   The code line " printArray(Serial.list());" generates a list 
   of [numbers] within brackets.  e.g: [0] "COM5"
   
   The [number] inside the square bracket MUST match the [number] in the 
   code line "myPort = new Serial(this, Serial.list()[0], Baud_rate);"    
   */
  printArray(Serial.list());                     //lists your COM ports on screen
  myPort = new Serial(this, Serial.list()[0], Baud_rate);
  myPort.bufferUntil('\n');
}

// ==========================
// draw
// ==========================
void draw()
{
  // ----- refresh the screen
  background(0);                      //black background
  textFont(myFont, 20);               //specify font to be used
  draw_grid();                        //draw grid
  draw_object();
}

// =======================
// serial event  (called with each Arduino data string)
// =======================
void serialEvent(Serial myPort)
{
  // ----- wait for a line-feed
  Input_string = myPort.readStringUntil('\n');
  println(Input_string);                              //visual feedback

  // ----- validate
  if (Input_string != null) 
  {
    // ----- trim whitespace
    Input_string = trim(Input_string);
    String[] values = split(Input_string, ',');

    // ----- gather Heron variables
    float a = float(values[1]) - float(values[0]);    //d2 (vertex -> sensor B)
    float b = float(values[0]);                       //d1 (vertex -> sensor A)
    float c = Baseline;                               //baseline
    //float d = c*1.414;                              //display diagonal (square)
    float d = sqrt(150*150 + 100*100);                //diagonal (display + offset)
    float s = (a + b + c)/2;                          //semi-perimeter

    // ----- validate distances
    /* eliminate bogus errors */
    boolean distances_valid = true;
    if 
      (
      (a < 0) ||          //d1 must be less than d2
      (b > d) ||          //d1 out-of-range 
      (a > d) ||          //d2 out-of-range
      ((s - a) < 0) ||    //these values must be positive
      ((s - b) < 0) || 
      ((s - c) < 0)
      ) 
    {
      distances_valid=false;
      X=1000;             //move flashing dot off-screen
      Y=1000;             //move flashing dot off-screen
    }

    // ----- apply Heron's formula
    if (distances_valid)
    {
      float area = sqrt(s * (s - a) * (s - b) * (s - c));
      Y = area * 2 / c;
      X = sqrt(b * b - Y * Y);
      
      // ----- display data for valid echos
      print("    d1: "); 
      println(b);
      print("    d2: "); 
      println(a);
      print("  base: "); 
      println(c);      
      print("offset: "); 
      println(Offset);
      print("     s: "); 
      println(s);
      print("  area: "); 
      println(area);
      print("     X: "); 
      println(X);
      print("     Y: "); 
      println(Y-Offset);
      println("");
    }
    myPort.clear();                                //clear the receive buffer
  }
}

// ==========================
// draw_grid
// ==========================
void draw_grid()
{
  pushMatrix();

  scale(0.8);
  translate(width*0.1, height*0.10);  
  fill(0);
  stroke(255);

  // ----- border
  strokeWeight(4);
  rect(0, 0, width, height, 20, 20, 20, 20);

  // ----- horizontal lines
  strokeWeight(1);
  line(0, height*0.1, width, height*0.1);
  line(0, height*0.2, width, height*0.2);
  line(0, height*0.3, width, height*0.3);
  line(0, height*0.4, width, height*0.4);
  line(0, height*0.5, width, height*0.5);
  line(0, height*0.6, width, height*0.6);
  line(0, height*0.7, width, height*0.7);
  line(0, height*0.8, width, height*0.8);
  line(0, height*0.9, width, height*0.9);

  // ----- vertical lines
  line(width*0.1, 0, width*0.1, height);
  line(width*0.2, 0, width*0.2, height);
  line(width*0.3, 0, width*0.3, height);
  line(width*0.4, 0, width*0.4, height);
  line(width*0.5, 0, width*0.5, height);
  line(width*0.6, 0, width*0.6, height);
  line(width*0.7, 0, width*0.7, height);
  line(width*0.8, 0, width*0.8, height);
  line(width*0.9, 0, width*0.9, height);

  // ----- label the X-axis
  fill(255);                                    //white text
  textAlign(LEFT, TOP);
  text("0", -20, height+10);                    //0cm
  text("50", width*0.5-20, height+10);          //50cm
  text("100cm", width-20, height+10);           //100cm

  // ----- label the y-axis
  textAlign(RIGHT, BOTTOM);
  text("100cm", 10, -10);                      //100cm
  textAlign(RIGHT, CENTER);
  text("50", -10, height/2);                   //100cm

  popMatrix();
}

// ==========================
// draw_object
// ==========================
void draw_object()
{
  pushMatrix();
  scale(0.8);
  stroke(0, 255, 0);
  strokeWeight(1);
  translate(width*0.1, height*1.1);              //(0,0) now lower-left corner

  // ----- make the object flash
  if ((frameCount-Frame_count)>4)
  {
    Frame_visible = !Frame_visible;
    Frame_count = frameCount;
  }

  // ----- object color scheme
  if (Frame_visible)
  {
    // ----- make object visible
    Object.setFill(color(255, 0, 0, 255));      //opaque
    Object.setStroke(color(255, 0, 0, 255));    //opaque
  } else
  {
    // ----- hide the object
    Object.setFill(color(255, 0, 0, 0));        //clear
    Object.setStroke(color(255, 0, 0, 0));      //clear
  }

  // ----- draw the object
  pushMatrix();
  translate(X/100*width, -(Y-Offset)/100*height);
  shape(Object);
  popMatrix();
  popMatrix();
}
