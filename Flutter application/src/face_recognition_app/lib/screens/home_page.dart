// Importing project packages
import 'package:face_recognition_app/main.dart';
import 'package:face_recognition_app/screens/welcome_page.dart';
import 'package:face_recognition_app/services/entry_logs.dart';
import 'package:face_recognition_app/services/face_recognition.dart';
import 'package:face_recognition_app/services/sign_up_service.dart';
import 'package:face_recognition_app/services/thingspeak_data.dart';
import 'package:face_recognition_app/utilities/alert.dart';

// Importing Firebase packages
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Importing other Dart and Flutter packages
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:syncfusion_flutter_charts/charts.dart';

class HomePage extends StatefulWidget {

  // HomePage can be opened only with a specified emailId and name
  HomePage({this.name = '', this.email = ''});

  // User Details
  String name;
  String email;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  int _selectedPage = 0;

  // Update Images Parameters
  int _state = 0; // State of the registration form (Stepper Widget)
  late List<File> images = List<File>.filled(10, File('')); // Image file of user. Initially empty
  List<bool> isUploaded = List<bool>.filled(10, false); // Boolean variable to check whether user has uploaded image. Initially false
  final ImagePicker picker = ImagePicker(); // Instance of Image Picker package. Used to take image from camera. See https://pub.dev/packages/image_picker for more details

  // Live Environment Parameters
  late ZoomPanBehavior _zoomPanBehavior;
  late TrackballBehavior _trackballBehavior;

  @override
  void initState() {

    // Initializing properties and behaviour of Live Environment Graph rendering widgets. See https://pub.dev/packages/syncfusion_flutter_charts for more details/
    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,
      enableDoubleTapZooming: false
    );

    _trackballBehavior = TrackballBehavior(
      enable: true,
      tooltipSettings: InteractiveTooltip(
        enable: true,
        color: Colors.red,
          format: 'point.x : point.y%'
      ),
      tooltipDisplayMode: TrackballDisplayMode.floatAllPoints,
      tooltipAlignment: ChartAlignment.near,
      activationMode: ActivationMode.longPress
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    // Subscreens on Home Page
    List<Widget> pages = [

      // Update Photo Screen
      (isLoading) ? SpinKitDoubleBounce(
        color: Colors.red,
        size: 48.0,
      ) :
      Stepper(

        // Current state of the update form (Stepper Widget)
        currentStep: _state,

        // On cancelling, the image is un-uploaded.
        onStepCancel: (){
          if (_state >= 0) {
            if(isUploaded[_state]){
              setState(() {
                isUploaded[_state] = false;
              });
            }
            else {
              setState(() {
                _state -= 1;
              });
            }
          }
        },

        // On updating, the following actions are done in the order:
        // 1. It is determined whether the user has uploaded the new image
        // 2. The image is uploaded to Firebase Storage under 'emailId/' bucket
        // 3. The image is run on a face recognition model and the data obtained is updated in a document with documentId=faces in the 'metadata' collection of Cloud Firestore
        // 4. The live environment data of the smart lab is fetched and processed
        // If any of the above steps fail, error is displayed using showAlert() utility
        onStepContinue: () async {
          if (_state <= 0) {
            setState(() {
              _state += 1;
            });
            if(_state == 1){
              _state--;
              if(isUploaded[0]){
                setState(() {
                  isLoading = true;
                });
                for(int i=0; i<1; i++){
                  String imageName = 'image'+(i+1).toString()+'.jpg';
                  await FirebaseStorage.instance.ref().child('${this.widget.email}/${imageName}').putFile(images[i]).then((p0) {
                    print('INFO: Image ' + (i+1).toString() + ' is uploaded successfully');
                  }).catchError((err) {
                    setState(() {
                      isLoading = false;
                      _state = i;
                    });
                    showAlert(context, 'Unable to upload user image\n' + err.toString());
                  });
                }
                final FaceRecognitionService faceRecognitionService = await signUp(images, context);
                FirebaseFirestore.instance.collection('metadata').doc('faces').set({
                  this.widget.email.toString(): faceRecognitionService.faceVector
                }, SetOptions(merge: true)).then((value) {
                  setState(() {
                    isLoading = false;
                    for(int i=0; i<10; i++){
                      isUploaded[i] = false;
                    }
                    _state = 0;
                  });
                }).catchError((err) {
                  setState(() {
                    isLoading = false;
                  });
                  showAlert(context, 'Unable to upload face vector\n' + err.toString());
                });

              }
              else{
                showAlert(context, 'Enter all details and upload photo to proceed');
                _state = 0;
              }
            }
          }
        },

        onStepTapped: (int index) {
          setState(() {
            _state = index;
          });
        },
        steps: [

          // Update Photo Step
          Step(
            title: Text('Photo'),
            content: (!isUploaded[0]) ? Container(
              child: IconButton(
                icon: Icon(
                  Icons.camera_alt_rounded,
                ),
                iconSize: 48,
                onPressed: () async {
                  try{
                    final pickedFile = await picker.getImage(
                        source: ImageSource.camera,
                        maxHeight: 300.0
                    );
                    setState(() {
                      images[0] = File(pickedFile!.path);
                      isUploaded[0] = true;
                    });
                  } catch (err) {
                    showAlert(context, err.toString());
                  }
                },
              ),
            ) : Container(
                child: Image(
                  image: FileImage(images[0]),
                )
            ),
          ),
        ],
      ),

      // Live Environment Screen
      (isLoading) ? SpinKitDoubleBounce(
        color: Colors.red,
        size: 48.0,
      ) :
      Scrollbar(
        isAlwaysShown: true,
        thickness: 22.0,
        interactive: true,
        child: ListView(
          children: [

            // Update AC Temperature Threshold Panel
            // NOTE: The UI is such that MIN can never be >= MAX. Further, MIN >= 10 and MAX <= 40 always
            Container(
              height: MediaQuery.of(context).size.height / 2,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border.all(
                  color: Colors.blue,
                  style: BorderStyle.solid
                ),
                borderRadius: BorderRadius.circular(20.0),
              ),
              margin: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    'Control AC Flap',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.add_circle_outline_rounded
                            ),
                            onPressed: () {
                              if((minTemp+1 < maxTemp) && (minTemp+1 <= 40)){
                                setState(() {
                                  minTemp++;
                                });
                              }
                            },
                          ),
                          Text(
                            minTemp.toString(),
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey
                            ),
                          ),
                          Text(
                            'MIN',
                            style: TextStyle(
                              fontSize: 12
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.remove_circle_outline_rounded,
                            ),
                            onPressed: () {
                              if(minTemp-1 >= 10){
                                setState(() {
                                  minTemp--;
                                });
                              }
                            },
                          )
                        ],
                      ),
                      Icon(
                        Icons.ac_unit_rounded,
                        size: 36.0,
                        color: Colors.grey,
                      ),
                      Column(
                        children: [
                          IconButton(
                            icon: Icon(
                                Icons.add_circle_outline_rounded
                            ),
                            onPressed: () {
                              if(maxTemp+1 <= 40){
                                setState(() {
                                  maxTemp++;
                                });
                              }
                            },
                          ),
                          Text(
                            maxTemp.toString(),
                            style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey
                            ),
                          ),
                          Text(
                            'MAX',
                            style: TextStyle(
                                fontSize: 12
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.remove_circle_outline_rounded,
                            ),
                            onPressed: () {
                              if((maxTemp-1 > minTemp) && (maxTemp-1 >= 10)){
                                setState(() {
                                  maxTemp--;
                                });
                              }
                            },
                          )
                        ],
                      ),
                    ],
                  ),
                  if(!data.isEmpty) Text(
                    'Live Temperature: ${data.last.field3.toStringAsFixed(1)}ºC'
                  ),
                  if(!data.isEmpty) Text(
                      'Live Humidity: ${data.last.field4.toStringAsFixed(0)}%'
                  ),
                  if(!data.isEmpty) Text(
                      'Live CO: ${data.last.field1.toStringAsFixed(2)} ppm'
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Updates the temperature threshold by sending updated values to Thingspeak Server
                      // If the above steps fail, error is displayed using showAlert() utility
                      FloatingActionButton(
                        backgroundColor: Colors.amber,
                        onPressed: () async{
                          setState(() {
                            isLoading = true;
                          });
                          await updateThresholdTemperature(context).catchError((err) {
                            setState(() {
                              isLoading = false;
                            });
                            showAlert(context, err.toString());
                          });
                          await getData(context).catchError((err) {
                            showAlert(context, err.toString());
                            setState(() {
                              isLoading = false;
                            });
                          });
                          setState(() {
                            isLoading = false;
                          });
                        },
                        child: Text(
                          'SET TEMP',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),

            // Graph of Carbon Monoxide levels
            Container(
              height: MediaQuery.of(context).size.height / 3,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  title: AxisTitle(
                    text: 'Timestamp'
                  )
                ),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(
                    text: 'CO (ppm)'
                  )
                ),
                zoomPanBehavior: _zoomPanBehavior,
                trackballBehavior: _trackballBehavior,
                margin: EdgeInsets.all(24.0),
                series: [
                  LineSeries(
                    dataSource: data,
                    xValueMapper: (ThingspeakData info, _) => info.timestamp.toLocal().toString(),
                    yValueMapper: (ThingspeakData info, _) => info.field1
                  )
                ],
              ),
            ),

            // Graph of Temperature levels
            Container(
              height: MediaQuery.of(context).size.height / 3,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                    title: AxisTitle(
                        text: 'Timestamp'
                    )
                ),
                primaryYAxis: NumericAxis(
                    title: AxisTitle(
                        text: 'Temp (in ºC)',
                      textStyle: TextStyle(
                        //fontSize: 12.0
                      )
                    )
                ),
                zoomPanBehavior: _zoomPanBehavior,
                trackballBehavior: _trackballBehavior,
                margin: EdgeInsets.all(24.0),
                series: [
                  LineSeries(
                      dataSource: data,
                      xValueMapper: (ThingspeakData info, _) => info.timestamp.toLocal().toString(),
                      yValueMapper: (ThingspeakData info, _) => info.field3
                  )
                ],
              ),
            ),

            // Graph of Humidity levels
            Container(
              height: MediaQuery.of(context).size.height / 3,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                    title: AxisTitle(
                        text: 'Timestamp'
                    )
                ),
                primaryYAxis: NumericAxis(
                    title: AxisTitle(
                        text: 'Humidity (in %)',
                      textStyle: TextStyle(
                        //fontSize: 12.0
                      )
                    )
                ),
                zoomPanBehavior: _zoomPanBehavior,
                trackballBehavior: _trackballBehavior,
                margin: EdgeInsets.all(24.0),
                series: [
                  LineSeries(
                      dataSource: data,
                      xValueMapper: (ThingspeakData info, _) => info.timestamp.toLocal().toString(),
                      yValueMapper: (ThingspeakData info, _) => info.field4
                  )
                ],
              ),
            ),
          ],
        ),
      ),

      // Entry Logs Screen
      (isLoading) ? SpinKitDoubleBounce(
        color: Colors.red,
        size: 48.0,
      ) : Container(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Scrollbar(
          isAlwaysShown: true,
          thickness: 22,
          interactive: true,
          child: SingleChildScrollView(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'Total Number of Persons:  ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      Text(
                        personCount.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 32
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 16.0,),

                  // Dynamically creates widgets for entries based on retrieved data from Cloud Firestore
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: entryLogs.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: Colors.grey
                            ),
                            borderRadius: BorderRadius.circular(20)
                          ),
                          leading: Icon(
                            Icons.person_rounded,
                            size: 40,
                            color: (entryLogs[index].email == 'Intruder') ? Colors.red : Colors.black,
                          ),
                          title: Text(
                            entryLogs[index].email
                          ),
                          subtitle: Text(
                            entryLogs[index].timestamp.toLocal().toString()
                          ),
                        ),
                      );
                    },
                  )
                ],
              ),
          ),
        ),
      )
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [

          // Refresh Button
          // 1. For update photo screen, the uploaded image is resetted to null
          // 2. For live environment screen, the data from Thingspeak is retrieved live again, the UI of AC Temperature is resetted to last state
          // 3. For entry logs screen, the data of entries is retrieved from Cloud Firestore live again
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
            ),
            onPressed: () async {
              if(_selectedPage == 0){
                setState(() {
                  isUploaded[0] = false;
                });
              }
              else if(_selectedPage == 1){
                setState(() {
                  isLoading = true;
                });
                await getData(context);
                setState(() {
                  isLoading = false;
                });
              }
              else if(_selectedPage == 2){
                setState(() {
                  isLoading = true;
                });
                await getPersonCount(context);
                setState(() {
                  isLoading = false;
                });
              }
            },
          ),

          // Logout Button
          // Firebase Auth Logout is performed followed by resetting of local storage on SharedPreferences
          IconButton(
            icon: Icon(
              Icons.logout_rounded,
            ),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              final SharedPreferences prefs = await SharedPreferences.getInstance();
              prefs.clear();
              Navigator.push(context, MaterialPageRoute(builder: (context) => WelcomePage()));
            },
          )
        ],
        title: Text(
          'Hello, ' + this.widget.name + '!'
        ),
      ),

      body:  pages[_selectedPage],

      // BottomNavigationBar handles various subscrens on one screen
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.shifting,
        currentIndex: _selectedPage,
        onTap: (index) async{
          setState(() {
            isLoading = false;
            _selectedPage = index;
          });

          if(index == 1){
            setState(() {
              isLoading = true;
            });
            await getData(context).catchError((err) {
              showAlert(context, err.toString());
              setState(() {
                isLoading = false;
              });
            });
            setState(() {
              isLoading = false;
            });
          }

          if(index == 2){
            setState(() {
              isLoading = true;
            });
            await getPersonCount(context);
            setState(() {
              isLoading = false;
            });
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.face_rounded
            ),
            label: 'Update Images',
            backgroundColor: Colors.blue
          ),
          BottomNavigationBarItem(
            icon: Icon(
                Icons.query_stats_rounded
            ),
            label: 'Live Environment',
            backgroundColor: Colors.blue
          ),
          BottomNavigationBarItem(
            icon: Icon(
                Icons.note_rounded
            ),
            label: 'Entry Logs',
            backgroundColor: Colors.blue
          ),
        ],
      ),
    );
  }
}
