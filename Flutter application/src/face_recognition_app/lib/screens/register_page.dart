// Importing project packages
import 'package:face_recognition_app/main.dart';
import 'package:face_recognition_app/screens/home_page.dart';
import 'package:face_recognition_app/services/sign_up_service.dart';
import 'package:face_recognition_app/services/face_recognition.dart';
import 'package:face_recognition_app/services/entry_logs.dart';
import 'package:face_recognition_app/utilities/alert.dart';

// Importing Firebase packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Importing other Dart and Flutter packages
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';


class RegisterPage extends StatefulWidget {

  // Registration can only be done with email ID used to authenticate in Google
  RegisterPage({this.email = ''});

  // User Details
  String name = '';
  String mobileNumber = '';
  String? email = '';

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  int _state = 0; // State of the registration form (Stepper Widget)
  late List<File> images = List<File>.filled(10, File('')); // Image file of user. Initially empty
  List<bool> isUploaded = List<bool>.filled(10, false); // Boolean variable to check whether user has uploaded image. Initially false
  final ImagePicker picker = ImagePicker(); // Instance of Image Picker package. Used to take image from camera. See https://pub.dev/packages/image_picker for more details

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: (isLoading) ? SpinKitDoubleBounce(
        color: Colors.red,
        size: 48.0,
      ) : SizedBox.expand(
        child: Stepper(

          // Current state of the registration form (Stepper Widget)
          currentStep: _state,

          // On cancelling, the image is un-uploaded.
          // Further cancelling leads to user details step
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

          // On registering, the following actions are done in the order:
          // 1. It is determined whether the user has entered all details and image
          // 2. The user details are uploaded in a document with documentId=emailId in the 'registeredUsers' collection of Cloud Firestore
          // 3. The image is uploaded to Firebase Storage under 'emailId/' bucket
          // 4. The image is run on a face recognition model and the data obtained is uploaded in a document with documentId=faces in the 'metadata' collection of Cloud Firestore
          // 5. The user details are stored in SharedPreferences
          // 6. The live environment data of the smart lab is fetched and processed
          // If any of the above steps fail, error is displayed using showAlert() utility
          onStepContinue: () {
            if (_state <= 1) {
              setState(() {
                _state += 1;
              });
              if(_state == 2){
                _state--;
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
                    db.collection('metadata').doc('faces').set({
                      this.widget.email.toString(): faceRecognitionService.faceVector
                    }, SetOptions(merge: true)).then((value) async{
                      setState(() {
                        isLoading = false;
                      });
                      await getPersonCount(context);
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

            // User Details Step
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

            // User Image Step
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
        )
      ),
    );
  }
}
