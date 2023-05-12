# Smart Robotics Lab IITG

This project was done by group VARP for CS321 Smart Systems Lab
Group Members:
- Aadi Arya Chandra
- Pranav Nair
- Ravi Kumar
- Vishal Bulchandani

## Introduction

The aim of this project is to use sensors, microcontrollers and actuators for intelligent management of Robotics Lab of IITG.
The salient features are:
- allowing entry to only the recognised members of the lab through **face recognition**. We have used the Google Facenet model.
- Real time intrusion detection system at the door
- Environment Sensing of the Lab
- Count of people currently in the lab and the entry and exit logs
- Using the environment variables to open/close the AC vent based on user preference
- Android application where you can upload your photo for recognition, see the live environment data and set the temperature preferences

-------------------------------------------------------------
## Materials Used
- Raspberry Pi
- Wireless network
-  NodeMCU
- Temperature/Humidity Sensor and CO sensor
- Arduino
- Line Finder Sensor
- Buzzer
- Stepper Motor
- Gear Assembly
- USB Webcam
- Connecting wires

--------------------------------------------------------------
## Software/Frameworks

- C++ for Arduino and NodeMCU
- Python for RaspberryPi
- Flutter/Dart for the Android application

--------------------------------------------------------------

## Working of the system

- USB webcam is connected to the RaspberryPi and is located outside the door. On the press of a push button the webcam captures the picture of the person. If the person is authorised to enter the lab, the intrusion system will go off for 10 seconds and allow them to enter the lab.
-  In case an unauthorised person tried to enter the lab, logs will be updated and buzzer will go off signifying the intrusion
- Entry and exit of the lab is determined by the foru line sensors placed on both sides of the doors.
- Whenver a door passes below a line sensor the signal of line sensor goes LW thus allowing us to tract entry/ exit and intrusion on the basis of the order of the line sensors getting excited.
- These line sensors are connected to the arduino who in turn is further connected to the raspberry pi who performs the facial recognition and coordinates with the intrusion detection system and updates the entry logs and the count of people in the room.
- The environment sensing module is connected to the NodeMCU and it coolects the environment data and sends to the Thingspeak CHannel at regular intervals. 
- It also reads the min. and max. temp. from the channel and closes/opens the AC vent flap accordingly. 
- This is done by a gear assembly which is driven by the Stepper motor connected to the NodeMCU.
- The app allows an authorised use to login and update his/her face image which in turn is processed through a TFLite model to convert to face embeddings vector. 
- THis same vector is retrieved from the firebase at regular intervals and used in the facial recognition in raspberrypi running TFLite.
- The app allows you to the environment sensing hisry of the Lab through a set of scalable graphs and set the minimum and maximum temperature on the ThingSpeak Channel.

-------------------------------------------------------------

## Purpose of the code files

- ```env.ino, motor-motion-test.ino``` are the files for the environment sensing and AC vent controller part to be use with the NodeMCU. The second file is just a test file to check working of the stepper motor.
- ``` Face Recognition/``` This folder contaisn the tflite models and the python script that runs the face recognition and connects to intrusion detection system using pySerial and TFLite library.
- ``` Flutter application/ ```: contains the android application developed through flutter. For further details see the README in the application folder. 
-```Intruder/intruder.ino```: code uploaded to the arduino which monitors the line sensors and communicates to the RaspberryPi

## Thingspeak channel
See here [https://thingspeak.com/channels/2098172]