import 'package:face_recognition_app/screens/welcome_page.dart';
import 'package:face_recognition_app/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class HomePage extends StatefulWidget {

  String name;

  HomePage({this.name = ''});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  int _selectedPage = 0;

  //Update Images Parameters
  int _state = 0;
  late List<File> images = List<File>.filled(10, File(''));
  List<bool> isUploaded = List<bool>.filled(10, false);
  final ImagePicker picker = ImagePicker();

  @override
  Widget build(BuildContext context) {

    List<Widget> pages = [
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
          if (_state <= 9) {
            setState(() {
              _state += 1;
            });
            if(_state == 10){
              _state--;
              bool allUploaded = true;
              for(bool b in isUploaded){
                if(!b){
                  allUploaded = false;
                }
              }
              if(allUploaded){
                setState(() {
                  isLoading = true;
                });
                // for(int i=0; i<10; i++){
                //   String imageName = 'image'+(i+1).toString()+'.jpg';
                //   await FirebaseStorage.instance.ref().child('${this.widget.email}/${imageName}').putFile(images[i]).then((p0) {
                //     print('INFO: Image ' + (i+1).toString() + ' is uploaded successfully');
                //   }).catchError((err) {
                //     setState(() {
                //       isLoading = false;
                //     });
                //     print('ERROR: Unable to upload user image ' + (i+1).toString());
                //     print('ERROR: ' + err.toString());
                //   });
                // }
                setState(() {
                  isLoading = false;
                });
              }
              else{
                print('ERROR: Enter all details and 10 pictures to proceed');
                _state--;
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
            title: Text('Photo 1'),
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
                    print('ERROR: ' + err.toString());
                  }
                },
              ),
            ) : Container(
                child: Image(
                  image: FileImage(images[0]),
                )
            ),
          ),
          Step(
            title: Text('Photo 2'),
            content: (!isUploaded[1]) ? Container(
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
                      images[1] = File(pickedFile!.path);
                      isUploaded[1] = true;
                    });
                  } catch (err) {
                    print('ERROR: ' + err.toString());
                  }
                },
              ),
            ) : Container(
                child: Image(
                  image: FileImage(images[1]),
                )
            ),
          ),
          Step(
            title: Text('Photo 3'),
            content: (!isUploaded[2]) ? Container(
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
                      images[2] = File(pickedFile!.path);
                      isUploaded[2] = true;
                    });
                  } catch (err) {
                    print('ERROR: ' + err.toString());
                  }
                },
              ),
            ) : Container(
                child: Image(
                  image: FileImage(images[2]),
                )
            ),
          ),
          Step(
            title: Text('Photo 4'),
            content: (!isUploaded[3]) ? Container(
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
                      images[3] = File(pickedFile!.path);
                      isUploaded[3] = true;
                    });
                  } catch (err) {
                    print('ERROR: ' + err.toString());
                  }
                },
              ),
            ) : Container(
                child: Image(
                  image: FileImage(images[3]),
                )
            ),
          ),
          Step(
            title: Text('Photo 5'),
            content: (!isUploaded[4]) ? Container(
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
                      images[4] = File(pickedFile!.path);
                      isUploaded[4] = true;
                    });
                  } catch (err) {
                    print('ERROR: ' + err.toString());
                  }
                },
              ),
            ) : Container(
                child: Image(
                  image: FileImage(images[4]),
                )
            ),
          ),
          Step(
            title: Text('Photo 6'),
            content: (!isUploaded[5]) ? Container(
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
                      images[5] = File(pickedFile!.path);
                      isUploaded[5] = true;
                    });
                  } catch (err) {
                    print('ERROR: ' + err.toString());
                  }
                },
              ),
            ) : Container(
                child: Image(
                  image: FileImage(images[5]),
                )
            ),
          ),
          Step(
            title: Text('Photo 7'),
            content: (!isUploaded[6]) ? Container(
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
                      images[6] = File(pickedFile!.path);
                      isUploaded[6] = true;
                    });
                  } catch (err) {
                    print('ERROR: ' + err.toString());
                  }
                },
              ),
            ) : Container(
                child: Image(
                  image: FileImage(images[6]),
                )
            ),
          ),
          Step(
            title: Text('Photo 8'),
            content: (!isUploaded[7]) ? Container(
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
                      images[7] = File(pickedFile!.path);
                      isUploaded[7] = true;
                    });
                  } catch (err) {
                    print('ERROR: ' + err.toString());
                  }
                },
              ),
            ) : Container(
                child: Image(
                  image: FileImage(images[7]),
                )
            ),
          ),
          Step(
            title: Text('Photo 9'),
            content: (!isUploaded[8]) ? Container(
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
                      images[8] = File(pickedFile!.path);
                      isUploaded[8] = true;
                    });
                  } catch (err) {
                    print('ERROR: ' + err.toString());
                  }
                },
              ),
            ) : Container(
                child: Image(
                  image: FileImage(images[8]),
                )
            ),
          ),
          Step(
            title: Text('Photo 10'),
            content: (!isUploaded[9]) ? Container(
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
                      images[9] = File(pickedFile!.path);
                      isUploaded[9] = true;
                    });
                  } catch (err) {
                    print('ERROR: ' + err.toString());
                  }
                },
              ),
            ) : Container(
                child: Image(
                  image: FileImage(images[9]),
                )
            ),
          )
        ],
      ),
      Container(
        child: Text(
            'Page 2'
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
            icon:
            Icon(
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
      body: pages[_selectedPage],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.shifting,
        currentIndex: _selectedPage,
        onTap: (index) {
          setState(() {
            _selectedPage = index;
          });
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
