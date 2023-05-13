/* 
this is the file run for the environment sensing and the AC flpa part on the NodeMCU
 */

#include <ESP8266WiFi.h>  // wifi and over the air (OTA) related libraries
#include <ESP8266mDNS.h>
#include <WiFiUdp.h>
#include <ArduinoOTA.h>
#include <SPI.h>
// OLED display and graphics related libraries
#include <Wire.h>          // for i2c with OLED display
#include <Adafruit_GFX.h>  // for displaying graphics on the display
#include <Adafruit_SSD1306.h>

//wifi authentication parameters
const char* ssid = "";                                            // name of the wifi network being used
const char* pass = "";                                            // wifi password
const char* server = "api.thingspeak.com";                                 // cloud server
WiFiClient client;                                                         // represents this end as a client corresponding to the above server (HTTP used to request)
#define SCREEN_WIDTH 128                                                   // OLED display width, in pixels
#define SCREEN_HEIGHT 64                                                   // OLED display height, in pixels
#define OLED_RESET -1                                                      // Reset pin # (or -1 if sharing Arduino reset pin) // even though we have included spi.h, actually the communication is i2c, as that's the only thing the OLED display i'm using supports
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);  // creating a display object representing the OLED display


#include "MQ7.h"       // mq7 carbon monoxide sensor related library
#define MQ7_A_PIN A0   // mq7 pin
#define MQ7_VOLTAGE 5  // init MQ7 device
MQ7 CO_sensor(MQ7_A_PIN, MQ7_VOLTAGE);


#include <Adafruit_Sensor.h>  // dht11 temperature and humidity sensor related libraries
#include "DHT.h"
#include <DHT_U.h>
#define DHTPIN 2  // dht pins
#define DHTTYPE DHT11
DHT_Unified temp_humidity_sensor(DHTPIN, DHTTYPE);


#include <ThingSpeak.h>
const char* write_apiKey = "";  // write api key of thingspeak cloud server
const char* read_apiKey = "";   // read api key of thingspeak server
unsigned long write_channelID = ;   // read and write channel IDs of thingspeak channel on which data is present
unsigned long read_channelID = ;

//Motor
#include <AccelStepper.h>
const int stepsPerRevolution = 2048; 
const int adjustment = 3.2;            // change this to adjust how much the motor rotates
// ULN2003 Motor Driver Pins
#define IN1 D5
#define IN2 D6
#define IN3 D7
#define IN4 D8
#define out D0

// initialize the stepper library
AccelStepper stepper(AccelStepper::HALF4WIRE, IN1, IN3, IN2, IN4);


// Varables
volatile bool flap_closed = false;  //True when AC flap is closed
volatile float temp_min = 20.0;     //Default value
volatile float temp_max = 25.0;
volatile float CO_ppm;
volatile float temp;
volatile float humidity;
volatile int count = 0;


void setup() {  // put your setup code here, to run once:
  Serial.begin(115200);
  display.begin(SSD1306_SWITCHCAPVCC, 0x3C);  //initialize with the I2C addr 0x3C (128x64)
  display.clearDisplay();
  delay(10);
  Serial.println("Connecting to ");
  Serial.println(ssid);
  display.clearDisplay();                       // initialising LED display parameters
  display.setCursor(0, 0);
  display.setTextSize(1);
  display.setTextColor(WHITE);
  display.setTextSize(1);
  display.println("Connecting to ");
  display.print(ssid);
  display.display();
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, pass);  // initiate wifi connection with ssid and pass
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
    display.print(".");
    display.display();
  }
  // setting up OTA, which allows uploading code on the NodeMCU wirelessly 
  ArduinoOTA.setPassword("123");
  ArduinoOTA.onStart([]() {
    String type;
    if (ArduinoOTA.getCommand() == U_FLASH) {
      type = "sketch";
    } else {
      // U_FS
      type = "filesystem";
    }  // NOTE: if updating FS this would be the place to unmount FS using FS.end()
    Serial.println("Start updating " + type);
  });
  ArduinoOTA.onEnd([]() {
    Serial.println("\nEnd");
  });
  ArduinoOTA.onProgress([](unsigned int progress, unsigned int total) {
    Serial.printf("Progress: %u%%\r", (progress / (total / 100)));
  });
  ArduinoOTA.onError([](ota_error_t error) {
    Serial.printf("Error[%u]: ", error);
    if (error == OTA_AUTH_ERROR) {
      Serial.println("Auth Failed");
    } else if (error == OTA_BEGIN_ERROR) {
      Serial.println("Begin Failed");
    } else if (error == OTA_CONNECT_ERROR) {
      Serial.println("Connect Failed");
    } else if (error == OTA_RECEIVE_ERROR) {
      Serial.println("Receive Failed");
    } else if (error == OTA_END_ERROR) {
      Serial.println("End Failed");
    }
  });
  ArduinoOTA.begin();
  WiFi.setAutoReconnect(true);
  WiFi.persistent(true);
  Serial.println("");
  Serial.println("WiFi connected");
  display.clearDisplay();                     // displaying wifi connected on the led display
  display.setCursor(0, 0);
  display.setTextSize(2);
  display.setTextColor(WHITE);
  display.print("WiFi");
  display.display();
  display.print("connected");
  display.display();
  delay(4000);

  ThingSpeak.begin(client);

  CO_sensor.calibrate();  // calibrate the CO sensor
  Serial.println(F("------------------------------------"));
  Serial.println(F("Carbon Monoxide Sensor"));
  Serial.println(F("Sensor Type: MQ7"));
  Serial.print(F("Sensor Resistance after calibration: "));
  Serial.println(CO_sensor.getR0());

  temp_humidity_sensor.begin();  // initialise temperature and humidity sensor
  sensor_t sensor;               // print temperature sensor calibration details on monitor
  temp_humidity_sensor.temperature().getSensor(&sensor);
  Serial.println(F("------------------------------------"));
  Serial.println(F("Temperature Sensor"));
  Serial.print(F("Sensor Type: "));
  Serial.println(sensor.name);
  Serial.print(F("Driver Ver: "));
  Serial.println(sensor.version);
  Serial.print(F("Unique ID: "));
  Serial.println(sensor.sensor_id);
  Serial.print(F("Max Value: "));
  Serial.print(sensor.max_value);
  Serial.println(F("°C"));
  Serial.print(F("Min Value: "));
  Serial.print(sensor.min_value);
  Serial.println(F("°C"));
  Serial.print(F("Resolution: "));
  Serial.print(sensor.resolution);
  Serial.println(F("°C"));
  Serial.println(F("------------------------------------"));  // Print humidity sensor details on monitor
  temp_humidity_sensor.humidity().getSensor(&sensor);
  Serial.println(F("Humidity Sensor"));
  Serial.print(F("Sensor Type: "));
  Serial.println(sensor.name);
  Serial.print(F("Driver Ver: "));
  Serial.println(sensor.version);
  Serial.print(F("Unique ID: "));
  Serial.println(sensor.sensor_id);
  Serial.print(F("Max Value: "));
  Serial.print(sensor.max_value);
  Serial.println(F("%"));
  Serial.print(F("Min Value: "));
  Serial.print(sensor.min_value);
  Serial.println(F("%"));
  Serial.print(F("Resolution: "));
  Serial.print(sensor.resolution);
  Serial.println(F("%"));
  Serial.println(F("------------------------------------"));

  // // set the speed and acceleration of motor
  stepper.setMaxSpeed(500);
  stepper.setAcceleration(400);
  pinMode(out,OUTPUT);

  flap_closed = ThingSpeak.readFloatField(read_channelID, (unsigned int)5, read_apiKey);
  //This loop is only to sync the flap position at the time of installation and the ac flap position stored on the cloud.
  //Once the installation is done, comment out this if loop and upload this code again to NodeMCU. 
  //If you don't want to upload the code twice then make sure the position of ac flaps on cloud is zero and after making sure, upload the code after commenting the if loop.
  if (flap_closed) { 
    digitalWrite(out,1);
    stepper.move(2.5 * stepsPerRevolution);
    while (stepper.distanceToGo() != 0) {
      stepper.run();
    }
    digitalWrite(out,0);
  }
}
void loop() {
  // put your main code here, to run repeatedly:
  count++;
  ArduinoOTA.handle();        // OTA communication is allowed, but it may not work. OTA allows modifying the code uploaded on the NodeMCU wirelessly having the host uploading the code and the NodeMCU on the same wireless network
  display.clearDisplay();
  display.setCursor(0, 0);
  display.setTextSize(1);
  display.setTextColor(WHITE);

  CO_ppm = CO_sensor.readPpm(); 
  if (isnan(CO_sensor.readPpm())) {
    Serial.println(F("Error reading CO ppm value"));
  } else {
    Serial.println("CO: " + String(CO_ppm) + " ppm");
  }


  // Get temperature event and print its value
  sensors_event_t event;
  temp_humidity_sensor.temperature().getEvent(&event);
  temp = event.temperature;
  if (isnan(event.temperature)) {
    Serial.println(F("Error reading temperature\n"));
  } else {
    Serial.println("Temperature: " + String(temp) + " " + "\u2103");
  }


  // Get humidity event and print its value.
  temp_humidity_sensor.humidity().getEvent(&event);
  humidity = event.relative_humidity;                     // reading humidity
  if (isnan(event.relative_humidity)) {
    Serial.println(F("Error reading humidity"));
  } else {
    Serial.println("Humidity: " + String(humidity) + " %");
  }


  //Data printing on display
  display.print("CO: ");
  display.print(CO_ppm);
  display.println(" ppm");
  display.display();
  display.print("Temperature: ");
  display.print(temp);
  display.println(" C");
  display.display();
  display.print("Humidity: ");
  display.print(humidity);
  display.println(" %");
  display.display();

  //Read temp range from server
  temp_min = ThingSpeak.readFloatField(read_channelID, (unsigned int)6, read_apiKey);
  temp_max = ThingSpeak.readFloatField(read_channelID, (unsigned int)7, read_apiKey);
  ThingSpeak.readMultipleFields(read_channelID, read_apiKey);                               // reading the flap state and the min and max temperature from the server that was last set in the app 
  temp_min = ThingSpeak.getFieldAsFloat(6);
  temp_max = ThingSpeak.getFieldAsFloat(7);
  Serial.println(String(temp_min));
  Serial.println(String(temp_max));
  Serial.println(String(flap_closed));
  //Check AC flap and changed its state if required
  if (temp > temp_max && flap_closed) {
    flap_closed = false;
    digitalWrite(out,1);
    if (stepper.distanceToGo() == 0) {
      // stepper.moveTo(-stepper.currentPosition());
      stepper.move(0);
      Serial.println("AC opened!");
      display.println("AC opened!");
    }
    while (stepper.distanceToGo() != 0) {
      stepper.run();                              // making the motor rotate and the flap move
    }
    if (ThingSpeak.writeField(write_channelID, 5, flap_closed, write_apiKey) != 200) {     // writing flap state to Thingspeak channel
      Serial.println(F("Error uploading flap state to ThingSpeak channel\n "));
    }
    digitalWrite(out,0);
    delay(20000);  // thingspeak needs minimum 15s delay between updates
  }
  if (temp < temp_min && !flap_closed) {
    flap_closed = true;
    digitalWrite(out,1);
    if (stepper.distanceToGo() == 0) {
      // stepper.moveTo(-stepper.currentPosition());
      stepper.move(adjustment * stepsPerRevolution);     // this can be set as you wish for perfect opening and closing action
      Serial.println("AC closed!");
      display.println("AC closed!");
      
    }
    while (stepper.distanceToGo() != 0) {
      stepper.run();                            // making the motor rotate and the flap move
    }
    digitalWrite(out,0);
    if (ThingSpeak.writeField(write_channelID, 5, flap_closed, write_apiKey) != 200) { // writing flap state to Thingspeak channel
      Serial.println(F("Error uploading flap state to ThingSpeak channel\n "));
    }
    delay(20000);  // thingspeak needs minimum 15s delay between updates
  }
  if (count == 5) {
    count = 0;
    ThingSpeak.setField(1, CO_ppm);
    ThingSpeak.setField(3, temp);
    ThingSpeak.setField(4, humidity);
    if (ThingSpeak.writeFields(write_channelID, write_apiKey) != 200) {       // writing environment-sensed data to Thingspeak channel
      Serial.println(F("Error uploading sensors' data to ThingSpeak channel\n"));
    }
    delay(10000);
  }
  delay(10000);
}
