import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:face_recognition_app/screens/welcome_page.dart';
import 'package:face_recognition_app/main.dart';
import 'package:face_recognition_app/services/face_recognition.dart';
import 'package:face_recognition_app/services/sign_up_service.dart';
import 'package:face_recognition_app/services/thingspeak_data.dart';
import 'package:face_recognition_app/utilities/alert.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:syncfusion_flutter_charts/charts.dart';

class HomePage extends StatefulWidget {

  String name;
  String email;

  HomePage({this.name = '', this.email = ''});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  int _selectedPage = 0;

  // Update Images Parameters
  int _state = 0;
  late List<File> images = List<File>.filled(10, File(''));
  List<bool> isUploaded = List<bool>.filled(10, false);
  final ImagePicker picker = ImagePicker();

  // Live Environment Parameters
  late ZoomPanBehavior _zoomPanBehavior;
  late TrackballBehavior _trackballBehavior;

  @override
  void initState() {

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

    List<Widget> pages = [
      (isLoading) ? SpinKitDoubleBounce(
        color: Colors.red,
        size: 48.0,
      ) :
      Stepper(
        currentStep: _state,
        onStepCancel: (){
          if (_state > 0) {
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
        onStepContinue: () async {
          if (_state <= 0) {
            setState(() {
              _state += 1;
            });
            if(_state == 1){
              _state--;
              // bool allUploaded = true;
              // for(bool b in isUploaded){
              //   if(!b){
              //     allUploaded = false;
              //   }
              // }
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
                FirebaseFirestore.instance.collection('faces').doc('details').set({
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
          // Step(
          //   title: Text('Photo 2'),
          //   content: (!isUploaded[1]) ? Container(
          //     child: IconButton(
          //       icon: Icon(
          //         Icons.camera_alt_rounded,
          //       ),
          //       iconSize: 48,
          //       onPressed: () async {
          //         try{
          //           final pickedFile = await picker.getImage(
          //               source: ImageSource.camera,
          //               maxHeight: 300.0
          //           );
          //           setState(() {
          //             images[1] = File(pickedFile!.path);
          //             isUploaded[1] = true;
          //           });
          //         } catch (err) {
          //           print('ERROR: ' + err.toString());
          //         }
          //       },
          //     ),
          //   ) : Container(
          //       child: Image(
          //         image: FileImage(images[1]),
          //       )
          //   ),
          // ),
          // Step(
          //   title: Text('Photo 3'),
          //   content: (!isUploaded[2]) ? Container(
          //     child: IconButton(
          //       icon: Icon(
          //         Icons.camera_alt_rounded,
          //       ),
          //       iconSize: 48,
          //       onPressed: () async {
          //         try{
          //           final pickedFile = await picker.getImage(
          //               source: ImageSource.camera,
          //               maxHeight: 300.0
          //           );
          //           setState(() {
          //             images[2] = File(pickedFile!.path);
          //             isUploaded[2] = true;
          //           });
          //         } catch (err) {
          //           print('ERROR: ' + err.toString());
          //         }
          //       },
          //     ),
          //   ) : Container(
          //       child: Image(
          //         image: FileImage(images[2]),
          //       )
          //   ),
          // ),
          // Step(
          //   title: Text('Photo 4'),
          //   content: (!isUploaded[3]) ? Container(
          //     child: IconButton(
          //       icon: Icon(
          //         Icons.camera_alt_rounded,
          //       ),
          //       iconSize: 48,
          //       onPressed: () async {
          //         try{
          //           final pickedFile = await picker.getImage(
          //               source: ImageSource.camera,
          //               maxHeight: 300.0
          //           );
          //           setState(() {
          //             images[3] = File(pickedFile!.path);
          //             isUploaded[3] = true;
          //           });
          //         } catch (err) {
          //           print('ERROR: ' + err.toString());
          //         }
          //       },
          //     ),
          //   ) : Container(
          //       child: Image(
          //         image: FileImage(images[3]),
          //       )
          //   ),
          // ),
          // Step(
          //   title: Text('Photo 5'),
          //   content: (!isUploaded[4]) ? Container(
          //     child: IconButton(
          //       icon: Icon(
          //         Icons.camera_alt_rounded,
          //       ),
          //       iconSize: 48,
          //       onPressed: () async {
          //         try{
          //           final pickedFile = await picker.getImage(
          //               source: ImageSource.camera,
          //               maxHeight: 300.0
          //           );
          //           setState(() {
          //             images[4] = File(pickedFile!.path);
          //             isUploaded[4] = true;
          //           });
          //         } catch (err) {
          //           print('ERROR: ' + err.toString());
          //         }
          //       },
          //     ),
          //   ) : Container(
          //       child: Image(
          //         image: FileImage(images[4]),
          //       )
          //   ),
          // ),
          // Step(
          //   title: Text('Photo 6'),
          //   content: (!isUploaded[5]) ? Container(
          //     child: IconButton(
          //       icon: Icon(
          //         Icons.camera_alt_rounded,
          //       ),
          //       iconSize: 48,
          //       onPressed: () async {
          //         try{
          //           final pickedFile = await picker.getImage(
          //               source: ImageSource.camera,
          //               maxHeight: 300.0
          //           );
          //           setState(() {
          //             images[5] = File(pickedFile!.path);
          //             isUploaded[5] = true;
          //           });
          //         } catch (err) {
          //           print('ERROR: ' + err.toString());
          //         }
          //       },
          //     ),
          //   ) : Container(
          //       child: Image(
          //         image: FileImage(images[5]),
          //       )
          //   ),
          // ),
          // Step(
          //   title: Text('Photo 7'),
          //   content: (!isUploaded[6]) ? Container(
          //     child: IconButton(
          //       icon: Icon(
          //         Icons.camera_alt_rounded,
          //       ),
          //       iconSize: 48,
          //       onPressed: () async {
          //         try{
          //           final pickedFile = await picker.getImage(
          //               source: ImageSource.camera,
          //               maxHeight: 300.0
          //           );
          //           setState(() {
          //             images[6] = File(pickedFile!.path);
          //             isUploaded[6] = true;
          //           });
          //         } catch (err) {
          //           print('ERROR: ' + err.toString());
          //         }
          //       },
          //     ),
          //   ) : Container(
          //       child: Image(
          //         image: FileImage(images[6]),
          //       )
          //   ),
          // ),
          // Step(
          //   title: Text('Photo 8'),
          //   content: (!isUploaded[7]) ? Container(
          //     child: IconButton(
          //       icon: Icon(
          //         Icons.camera_alt_rounded,
          //       ),
          //       iconSize: 48,
          //       onPressed: () async {
          //         try{
          //           final pickedFile = await picker.getImage(
          //               source: ImageSource.camera,
          //               maxHeight: 300.0
          //           );
          //           setState(() {
          //             images[7] = File(pickedFile!.path);
          //             isUploaded[7] = true;
          //           });
          //         } catch (err) {
          //           print('ERROR: ' + err.toString());
          //         }
          //       },
          //     ),
          //   ) : Container(
          //       child: Image(
          //         image: FileImage(images[7]),
          //       )
          //   ),
          // ),
          // Step(
          //   title: Text('Photo 9'),
          //   content: (!isUploaded[8]) ? Container(
          //     child: IconButton(
          //       icon: Icon(
          //         Icons.camera_alt_rounded,
          //       ),
          //       iconSize: 48,
          //       onPressed: () async {
          //         try{
          //           final pickedFile = await picker.getImage(
          //               source: ImageSource.camera,
          //               maxHeight: 300.0
          //           );
          //           setState(() {
          //             images[8] = File(pickedFile!.path);
          //             isUploaded[8] = true;
          //           });
          //         } catch (err) {
          //           print('ERROR: ' + err.toString());
          //         }
          //       },
          //     ),
          //   ) : Container(
          //       child: Image(
          //         image: FileImage(images[8]),
          //       )
          //   ),
          // ),
          // Step(
          //   title: Text('Photo 10'),
          //   content: (!isUploaded[9]) ? Container(
          //     child: IconButton(
          //       icon: Icon(
          //         Icons.camera_alt_rounded,
          //       ),
          //       iconSize: 48,
          //       onPressed: () async {
          //         try{
          //           final pickedFile = await picker.getImage(
          //               source: ImageSource.camera,
          //               maxHeight: 300.0
          //           );
          //           setState(() {
          //             images[9] = File(pickedFile!.path);
          //             isUploaded[9] = true;
          //           });
          //         } catch (err) {
          //           print('ERROR: ' + err.toString());
          //         }
          //       },
          //     ),
          //   ) : Container(
          //       child: Image(
          //         image: FileImage(images[9]),
          //       )
          //   ),
          // )
        ],
      ),
      (isLoading) ? SpinKitDoubleBounce(
        color: Colors.red,
        size: 48.0,
      ) :
      Scrollbar(
        isAlwaysShown: true,
        thickness: 22.0,
        interactive: true,
        child: ListView(
          // shrinkWrap: true,
          children: [
            Container(
              height: MediaQuery.of(context).size.height / 3,
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
                  Icon(
                    Icons.ac_unit_rounded,
                    size: 36.0,
                    color: Colors.grey,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      FloatingActionButton(
                        backgroundColor: Colors.green,
                        onPressed: () async{
                          setState(() {
                            isLoading = true;
                          });
                          await updateFlapState(1, context).catchError((err) {
                            setState(() {
                              isLoading = false;
                            });
                            showAlert(context, err.toString());
                          });
                          setState(() {
                            isLoading = false;
                          });
                        },
                        child: Text(
                          'ON'
                        ),
                      ),
                      FloatingActionButton(
                        backgroundColor: Colors.red,
                        onPressed: () async{
                          setState(() {
                            isLoading = true;
                          });
                          await updateFlapState(0, context).catchError((err) {
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
                          'OFF'
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
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
                        text: 'MQ5 (ppm)'
                    )
                ),
                zoomPanBehavior: _zoomPanBehavior,
                trackballBehavior: _trackballBehavior,
                margin: EdgeInsets.all(24.0),
                series: [
                  LineSeries(
                      dataSource: data,
                      xValueMapper: (ThingspeakData info, _) => info.timestamp.toLocal().toString(),
                      yValueMapper: (ThingspeakData info, _) => info.field2
                  )
                ],
              ),
            ),
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
      Container(
        child: Text(
            'Page 3'
        ),
      ),
      Container(
        child: Text(
            'Page 4'
        ),
      )
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
            ),
            onPressed: () async {
              if(_selectedPage == 1){
                setState(() {
                  isLoading = true;
                });
                await getData(context);
                setState(() {
                  isLoading = false;
                });
              }
            },
          ),
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
                Icons.key_rounded
            ),
            label: 'Key Logs',
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
