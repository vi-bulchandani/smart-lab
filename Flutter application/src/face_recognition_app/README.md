# face_recognition_app

A Flutter application to set up the facial recognition, see the environment sensing data update temperature preferences and see the person count and entry logs.

## Source files

- ```main.dart```: main file of the program
- `firebase_options.dart`: system generated file
- `screens/home_page.dart`: contains the home page of the application after signing in. It has 3 tabs: 1. For updating face photo, 2. FOr displaying the environment sensor data and update temperature preferences and 3. displaying the people count and the entry and the exit logs.
- `screens/register_page.dart`: page for entering personal details after registration.
- `screens/welcome_page.dart`: welcome page of the applicatiaon containing the Google OAuth button
- `services/entry_logs.dart`: functions for retrieving the entry logs from firestore
- `services/face_detection.dart`: functions for retrieving the face in uploaded photo
- `services/face_recognition.dart`: uses TFLite model to calculate the face embeddings of the detected face and update them in the firestore
- `services/thingspeak_data.dart`: gets and posts data from/to the ThingSpeak channel
- `services/sign_ip_service.dart`: for registering a new user on the firebase
- `utilities/alert.dart`: contains functions for displaying an alert dialog box

## Other files

- `*.tflite`: The facenet models used in the app
- `*.apk`: Fat apk files of the app corresponding to the different modesl used
- `install.bat/install.sh`: will download the facenet model and associated files on the computer
  
----------------------------------------------------

