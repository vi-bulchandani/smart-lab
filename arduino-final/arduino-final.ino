// #include <ESP8266WiFi.h> // wifi and over the air (OTA) related libraries 
// #include <ESP8266mDNS.h> 
// #include <WiFiUdp.h> 
// #include <ArduinoOTA.h> 
// const char *ssid = "OnePlus Nord"; // using my mobile as router here, as nodemcu 
// const char *pass = "60774ffe9fde"; // will now run on wifi of my mobile's wifi hotspot 
// const char* server = "api.thingspeak.com"; // cloud server 
// WiFiClient client; // represents this end as a client corresponding to the above server (HTTP used to request) 
// #include <ThingSpeak.h> 
// const char* write_apiKey = "TY4WM71I9PJCVEB6"; // write api key of thingspeak cloud server 
// const char* read_apiKey = "5LN4K6TSNIXH8OAC"; 
// unsigned long write_channelID = 1874054; 
// unsigned long read_channelID = 1877865; 

#include <SPI.h>

// OLED display and graphics related libraries
#include <Wire.h> // for i2c with OLED display
#include <Adafruit_GFX.h> // for displaying graphics on the display
#include <Adafruit_SSD1306.h> 
#define SCREEN_WIDTH 128 // OLED display width, in pixels 
#define SCREEN_HEIGHT 64 // OLED display height, in pixels 
#define OLED_RESET -1 // Reset pin # (or -1 if sharing Arduino reset pin) // even though we have included spi.h, actually the communication is i2c, as that's the only thing the OLED display i'm using supports
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET); // creating a display object representing the OLED display 

#include "MQ7.h" // mq7 carbon monoxide sensor related library 
#define MQ7_A_PIN A0 // mq7 pin 
#define MQ7_VOLTAGE 5 // init MQ7 device 
MQ7 CO_sensor(MQ7_A_PIN, MQ7_VOLTAGE); 

#include <Adafruit_Sensor.h> // dht11 temperature and humidity sensor related libraries 
#include "DHT.h" 
#include <DHT_U.h> 
#define DHTPIN 2 // dht pins 
#define DHTTYPE DHT11 
DHT_Unified temp_humidity_sensor(DHTPIN, DHTTYPE);
 

#include <MQUnifiedsensor.h>

//Definitions
#define placa "Arduino MEGA"
#define Voltage_Resolution 5
#define pin A1 //An#include <ESP8266WiFi.h> // wifi and over the air (OTA) related libraries 
// #include <ESP8266mDNS.h> 
// #include <WiFiUdp.h> 
// #include <ArduinoOTA.h> 
// const char *ssid = "OnePlus Nord"; // using my mobile as router here, as nodemcu 
// const char *pass = "60774ffe9fde"; // will now run on wifi of my mobile's wifi hotspot 
// const char* server = "api.thingspeak.com"; // cloud server 
// WiFiClient client; // represents this end as a client corresponding to the above server (HTTP used to request) alog input 0 of your arduino
#define type "MQ-5" //MQ5
#define ADC_Bit_Resolution 10 // For arduino UNO/MEGA/NANO
#define RatioMQ5CleanAir 6.5  //RS / R0 = 6.5 ppm 
//#define calibration_button 13 //Pin to calibrate your sensor

//Declare Sensor
MQUnifiedsensor MQ5(placa, Voltage_Resolution, ADC_Bit_Resolution, pin, type);

void setup(){
  
    Serial.begin(9600); 

  display.begin(SSD1306_SWITCHCAPVCC, 0x3C); //initialize with the I2C addr 0x3C (128x64) 

  display.clearDisplay(); 
  display.setCursor(0,0); 
  display.setTextSize(1); 
  display.setTextColor(WHITE); 
  display.setTextSize(2); 
  display.display(); 

  CO_sensor.calibrate(); // calibrate the CO sensor 
  Serial.println("------------------------------------"); 
  Serial.println("Carbon Monoxide Sensor"); 
  Serial.println("Sensor Type: MQ7"); 
  Serial.print ("Sensor Resistance after calibration: "); 
  Serial.println(CO_sensor.getR0()); 
  temp_humidity_sensor.begin(); // initialise temperature and humidity sensor 
  sensor_t sensor; // print temperature sensor details on monitor 
  temp_humidity_sensor.temperature().getSensor(&sensor); 
  Serial.println("------------------------------------");
  Serial.println("Temperature Sensor"); 
  Serial.print ("Sensor Type: "); 
  Serial.println(sensor.name); 
  Serial.print ("Driver Ver: "); 
  Serial.println(sensor.version); 
  Serial.print ("Unique ID: "); 
  Serial.println(sensor.sensor_id); 
  Serial.print ("Max Value: "); 
  Serial.print(sensor.max_value); 
  Serial.println(F("°C")); 
  Serial.print ("Min Value: "); 
  Serial.print(sensor.min_value); 
  Serial.println("C"); 
  Serial.print ("Resolution: "); 
  Serial.print(sensor.resolution); 
  Serial.println("C"); 
  Serial.println("------------------------------------"); // Print humidity sensor details on monitor 
  temp_humidity_sensor.humidity().getSensor(&sensor);
  Serial.println("Humidity Sensor"); 
  Serial.print ("Sensor Type: "); 
  Serial.println(sensor.name); 
  Serial.print ("Driver Ver: "); 
  Serial.println(sensor.version); 
  Serial.print ("Unique ID: "); 
  Serial.println(sensor.sensor_id); 
  Serial.print ("Max Value: "); 
  Serial.print(sensor.max_value); 
  Serial.println("%"); 
  Serial.print ("Min Value: ");
  Serial.print(sensor.min_value); 
  Serial.println("%"); 
  Serial.print ("Resolution: "); 
  Serial.print(sensor.resolution); 
  Serial.println("%"); 
  Serial.println("------------------------------------"); 

   //Set math model to calculate the PPM concentration and the value of constants
  MQ5.setRegressionMethod(1); //_PPM =  a*ratio^b
  MQ5.setA(177.65); MQ5.setB(-2.56); // Configure the equation to to calculate H2 concentration
  /*
    Exponential regression:
  Gas    | a      | b
  H2     | 1163.8 | -3.874
  LPG    | 80.897 | -2.431
  CH4    | 177.65 | -2.56
  CO     | 491204 | -5.826
  Alcohol| 97124  | -4.918
  */
  
  /*****************************  MQ Init ********************************************/ 
  //Remarks: Configure the pin of arduino as input.
  /************************************************************************************/ 
  MQ5.init();   
  /* 
    //If the RL value is different from 10K please assign your RL value with the following method:
    MQ5.setRL(10);
  */
  /*****************************  MQ CAlibration ********************************************/ 
  // Explanation: 
   // In this routine the sensor will measure the resistance of the sensor supposedly before being pre-heated
  // and on clean air (Calibration conditions), setting up R0 value.
  // We recomend executing this routine only on setup in laboratory conditions.
  // This routine does not need to be executed on each restart, you can load your R0 value from eeprom.
  // Acknowledgements: https://jayconsystems.com/blog/understanding-a-gas-sensor
  Serial.print("Calibrating please wait.");
  float calcR0 = 0;
  for(int i = 1; i<=10; i ++)
  {
    MQ5.update(); // Update data, the arduino will read the voltage from the analog pin
    calcR0 += MQ5.calibrate(RatioMQ5CleanAir);
    Serial.print(".");
  }
  MQ5.setR0(calcR0/10);
  Serial.println("  done!.");
  
  if(isinf(calcR0)) {Serial.println("Warning: Conection issue, R0 is infinite (Open circuit detected) please check your wiring and supply"); while(1);}
  if(calcR0 == 0){Serial.println("Warning: Conection issue found, R0 is zero (Analog pin shorts to ground) please check your wiring and supply"); while(1);}
  /*****************************  MQ CAlibration ********************************************/ 
  MQ5.serialDebug(false);
  
}

void loop(){
  
  // put your main code here, to run repeatedly: 
     display.clearDisplay(); 
     display.setCursor(0,0); 
     display.setTextSize(1); 
     display.setTextColor(WHITE); 
     float CO_ppm = CO_sensor.readPpm(); // no error handling required for this, always returns some value 
     if(isnan(CO_ppm)) { 
      display.print("CO: "); 
      display.println(String(0)); 
      display.println("");
      Serial.println("CO: " + String(0) + " ppm");  
     } 
      else { 
         display.print("CO: "); 
         display.print(CO_ppm); 
         display.println(" ppm");
         display.println(""); 
         Serial.println("CO: " + String(CO_ppm) + " ppm"); 
      } 
          // Get temperature event and print its value
      sensors_event_t event; 
      temp_humidity_sensor.temperature().getEvent(&event); 
      if (isnan(event.temperature)) { 
          display.print("Temperature: "); 
          display.println(String(0)); 
          display.println("");
          Serial.println("Temperature: " + String(0) + " " + "\u2103");  
      } else { 
          display.print("Temperature: "); 
          display.print(event.temperature); 
          display.println(" C"); 
          display.println("");
          Serial.println("Temperature: " + String(event.temperature) + " " + "\u2103"); 
        } // Get humidity event and print its value. 
      temp_humidity_sensor.humidity().getEvent(&event); 
      if (isnan(event.relative_humidity)) { 
        display.print("Humidity: "); 
        display.println(String(0)); 
        display.println("");
        Serial.println("Humidity: " + String(0) + " %"); 
      } 
        else { 
          display.print("Humidity: "); 
          display.print(event.relative_humidity); 
          display.println(" %"); 
          display.println("");
          Serial.println("Humidity: " + String(event.relative_humidity) + " %"); 
          // if((x = ThingSpeak.writeField(write_channelID, 3, event.relative_humidity, write_apiKey)) != 200){
          //   Serial.println("Error uploading humidity measurement to Thingspeak channel. Error: " + String(x)); 
          // } 
          // delay(20000); // thingspeak needs minimum 15s delay between updates 
        } 
      


  MQ5.update(); // Update data, the arduino will read the voltage from the analog pin
  if(isnan(MQ5.readSensor())){
    Serial.print("MQ5: "); 
    Serial.println(String(0));
    display.print("CH4: ");
    display.println(String(0));
  }
  else{
    Serial.print("MQ5: "); 
    Serial.println(MQ5.readSensor());
    display.print("CH4: ");
    display.print(MQ5.readSensor());
    display.println(" ppm");
  }

  display.display(); 
  // Sensor will read PPM concentration using the model, a and b values set previously or from the setup
  //MQ5.serialDebug(); // Will print the table on the serial port
  delay(20000); //Sampling frequency



}
