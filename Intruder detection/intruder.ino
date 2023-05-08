#include<Grove_LED_Bar.h>

// Line sensor pins
#define LINE1 10
#define LINE2 11
#define LINE3 12
#define LINE4 13
#define VCC 14
// pins of yes/no LED
#define NO_LED 2
#define YES_LED 3
// pin for push button
#define PUSH 18

// pin for grove led bar
#define DCKI 9
#define DI 8
// pin for intruder buzzer
#define buzzerPin 15
Grove_LED_Bar bar(9,8,0);

//count of people in room
int count = 0;


void setup() {

  Serial.begin(115200);
  bar.begin();
//  pinMode(buzzerPin, OUTPUT);
// set pin to get input from line sensors
  pinMode(LINE1, INPUT);
  pinMode(LINE2, INPUT);
  pinMode(LINE3, INPUT);
  pinMode(LINE4, INPUT);
  pinMode(VCC, OUTPUT);

// configure push button and LED pins
  pinMode(PUSH, INPUT);
  pinMode(NO_LED, OUTPUT);
  pinMode(YES_LED, OUTPUT);
  digitalWrite(VCC, HIGH);
}

// recognised string received from the raspberry pi through serial
String recognised = "0";

void loop() {
  digitalWrite(VCC, HIGH);
  digitalWrite(4, HIGH);

  // check pushbutton event
  int push = digitalRead(PUSH);
  if(push == HIGH){
    Serial.println("hello");
  }
  // set bar to full brightness
  bar.setLevel(10);

  // reacognised variable from Raspberry Pi
  if (Serial.available() > 0) {
    recognised = Serial.readStringUntil('\n');
  }
  Serial.print("Arduino read: ");
  Serial.println(recognised);

  // grant entry only if recognised otherwise intrusion
  if(recognised == "0"){
    digitalWrite(NO_LED, HIGH);
    digitalWrite(YES_LED, LOW);
  }
  else{
    digitalWrite(NO_LED, LOW);
    digitalWrite(YES_LED, HIGH);
  }

  //read line sensor data
  int sig1 = digitalRead(10);
  int sig2 = digitalRead(11);
  int sig3 = digitalRead(12);
  int sig4 = digitalRead(13);
  Serial.print("Line sensor values: ");
  Serial.print(sig1);
  Serial.print(" ");
  Serial.print(sig2);
  Serial.print(" ");
  Serial.print(sig3);
  Serial.print(" ");
  Serial.println(sig4);

/* 
  entry exit logic using the values of line sensors
  and send data to raspberry pi using serial output
  provide entry if recognised
  else identify exit and intruder

  the sensor will read LOW when door crossed the sensor 
*/


  if(sig1 == LOW || sig2 == LOW || sig3 == LOW || sig4 == LOW){
    if(sig4 == LOW || sig3 == LOW){
      Serial.println("Exit");
      // count--; in pi
    }else{
      if(recognised == "1"){
        Serial.println("Entry");
        //count++; in pi
      }else{
        // sound the buzzer in case of intrusion and send data to raspberry pi
        digitalWrite(buzzerPin, HIGH);
        Serial.println("Intruder entry detected!");
        // intruder alert in pi
      } 
    }
  }else{
    digitalWrite(buzzerPin, LOW);
  }
  delay(100);
}