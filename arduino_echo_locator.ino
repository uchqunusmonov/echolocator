// ----- arduino pinouts
#define Trig1 4                       //sensor A "Trig" pin
#define Echo1 5                       //sensor A "Echo" pin

#define Trig2 6                       //sensor B "Trig" pin
#define Echo2 7                       //sensor B "Echo" pin

// ----- results
float Baseline = 50;                  //distance between the transducers (cm)
float Distance1;                      //from active sender (cm)
float Distance2;                      //from passive receiver (cm)

// ----- task scheduler
int TaskTimer1 = 0;                   //task 1 (see ISR(TIMER2_COMPA_vect)
bool TaskFlag1 = false;               //flag 1


// ===============================
// setup
// ===============================
void setup() {

  // ----- configure serial port
  Serial.begin(115200);

  // ----- configure arduino pinouts
  pinMode(Echo1, INPUT);              //make echo pins inputs
  pinMode(Echo2, INPUT);
  pinMode(Trig1, OUTPUT);             //make trig pins OUTPUT
  pinMode(Trig2, OUTPUT);
  digitalWrite(Trig1, LOW);           //set trig pins LOW
  digitalWrite(Trig2, LOW);

  // ----- configure Timer 2 to generate a compare-match interrupt every 1mS
  noInterrupts();                     //disable interrupts
  TCCR2A = 0;                         //clear control registers
  TCCR2B = 0;
  TCCR2B |= (1 << CS22) |             //16MHz/128=8uS
            (1 << CS20) ;
  TCNT2 = 0;                          //clear counter
  OCR2A = 125 - 1;                    //8uS*125=1mS (allow for clock propagation)
  TIMSK2 |= (1 << OCIE2A);            //enable output compare interrupt
  interrupts();                       //enable interrupts
}

// ===============================
// loop()
// ===============================
void loop()
{
  // ----- measure object distances
  if (TaskFlag1)
  {
    TaskFlag1 = false;
    measure();

    // -----Distance1 and Distance2 readings to the display
    Serial.print(Distance1); Serial.print(","); Serial.println(Distance2);
  }
}

// ===============================
// task scheduler (1mS interrupt)
// ===============================
ISR(TIMER2_COMPA_vect)
{
  // ----- timers
  TaskTimer1++;                       //task 1 timer

  // ----- task1
  if (TaskTimer1 > 499)               //interval between pings (50mS=423cm)
  {
    TaskTimer1 = 0;                   //reset timer
    TaskFlag1 = true;                 //signal loop() to perform task
  }
}

// ===============================
// measure distances
// ===============================
void measure()
{
  // ----- locals
  unsigned long start_time;           //microseconds
  unsigned long finish_time1;         //microseconds
  unsigned long finish_time2;         //microseconds
  unsigned long time_taken;           //microseconds
  boolean echo_flag1;                 //flags reflect state of echo line
  boolean echo_flag2;

 // ----- send 10uS trigger pulse
  digitalWrite(Trig1, HIGH);
  digitalWrite(Trig2, HIGH);
  delayMicroseconds(10);
  digitalWrite(Trig1, LOW);
  digitalWrite(Trig2, LOW);

  // ----- wait for both echo lines to go high
  while (!digitalRead(Echo1));
  while (!digitalRead(Echo2));

  // ----- record start time
  start_time = micros();

  // ----- reset the flags
  echo_flag1 = false;
  echo_flag2 = false;

  // ----- measure echo times
  while ((!echo_flag1) || (!echo_flag2))
  {
    // ----- Echo1
    if ((!echo_flag1) && (!digitalRead(Echo1)))    //Echo1 received
    {
      echo_flag1 = true;
      finish_time1 = micros();
      time_taken = finish_time1 - start_time;
      Distance1 = ((float)time_taken) / 59;        //use 59 as there is a return path
    }

    // ----- Echo2
    if ((!echo_flag2) && (!digitalRead(Echo2)))    //Echo2 received
    {
      echo_flag2 = true;
      finish_time2 = micros();
      time_taken = finish_time2 - start_time;
      Distance2 = ((float)time_taken) / 29.5;     //use 29.5 as there is no return path
    }
  }
}
