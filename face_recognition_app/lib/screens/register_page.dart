import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:face_recognition_app/screens/home_page.dart';
import 'package:face_recognition_app/utilities/alert.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:face_recognition_app/main.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:face_recognition_app/services/sign_up_service.dart';
import 'package:face_recognition_app/services/face_recognition.dart';

class RegisterPage extends StatefulWidget {

  RegisterPage({this.email = ''});

  String name = '';
  String mobileNumber = '';
  String? email = '';

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}



class _RegisterPageState extends State<RegisterPage> {

  int _state = 0;
  late List<File> images = List<File>.filled(10, File(''));
  List<bool> isUploaded = List<bool>.filled(10, false);
  final ImagePicker picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: (isLoading) ? SpinKitDoubleBounce(
        color: Colors.red,
        size: 48.0,
      ) : SizedBox.expand(
        child: Stepper(
          currentStep: _state,
          onStepCancel: (){
            if (_state > 0) {
              if(isUploaded[_state-1]){
                setState(() {
                  isUploaded[_state-1] = false;
                });
              }
              else {
                setState(() {
                  _state -= 1;
                });
              }
            }
          },
          onStepContinue: () {
            if (_state <= 1) {
              setState(() {
                _state += 1;
              });
              if(_state == 2){
                _state--;
                // bool allUploaded = true;
                // for(bool b in isUploaded){
                //   if(!b){
                //     allUploaded = false;
                //   }
                // }
                if(this.widget.name != '' && this.widget.mobileNumber != '' && isUploaded[0]){
                  setState(() {
                    isLoading = true;
                  });
                  FirebaseFirestore db = FirebaseFirestore.instance;
                  db.collection('registeredUsers').doc(this.widget.email).set({
                    'name': this.widget.name,
                    'mobile': this.widget.mobileNumber,
                    'email': this.widget.email
                  }).then((value) async {
                    for(int i=0; i<1; i++){
                      String imageName = 'image'+(i+1).toString()+'.jpg';
                      await FirebaseStorage.instance.ref().child('${this.widget.email}/${imageName}').putFile(images[i]).then((p0) {
                        print('INFO: Image ' + (i+1).toString() + ' is uploaded successfully');
                      }).catchError((err) {
                        setState(() {
                          isLoading = false;
                        });
                        showAlert(context, 'Unable to upload user image\n' + err.toString());
                      });
                    }
                    name = this.widget.name;
                    email = this.widget.email;
                    final SharedPreferences prefs = await SharedPreferences.getInstance();
                    prefs.setString('name', name.toString());
                    prefs.setString('email', email.toString());
                    final FaceRecognitionService faceRecognitionService = await signUp(images, context);
                    db.collection('faces').doc('details').set({
                      this.widget.email.toString(): faceRecognitionService.faceVector
                    }, SetOptions(merge: true)).then((value) {
                      setState(() {
                        isLoading = false;
                      });
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage(name: name.toString(), email: email.toString(),)));
                    }).catchError((err) {
                      setState(() {
                        isLoading = false;
                      });
                      showAlert(context, 'Unable to upload face vector\n' + err.toString());
                    });
                  }).catchError((err) {
                    setState(() {
                      isLoading = false;
                    });
                    showAlert(context, 'Unable to upload user data\n' + err.toString());
                  });
                }
                else{
                  showAlert(context, 'Enter all details and upload photo to proceed');
                  _state = 1;
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
              title: Text('User Details'),
              content: Container(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: TextField(
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            labelText: 'Name',
                            hintText: 'Enter Your Name',
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            focusColor: Colors.black
                        ),
                        onChanged: (val) {
                          this.widget.name = val;
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: TextField(
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            labelText: 'Mobile Number',
                            hintText: '+919999099990',
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            focusColor: Colors.black
                        ),
                        onChanged: (val) {
                          this.widget.mobileNumber = val;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
        )
      ),
    );
  }
}
