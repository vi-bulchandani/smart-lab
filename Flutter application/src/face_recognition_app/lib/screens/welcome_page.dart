import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:face_recognition_app/screens/home_page.dart';
import 'package:face_recognition_app/screens/register_page.dart';
import 'package:face_recognition_app/utilities/alert.dart';
import 'package:face_recognition_app/services/entry_logs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:face_recognition_app/main.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image(
              image: AssetImage('assets/logo.png'),
              height: MediaQuery.of(context).size.height / 3,
            ),
            SizedBox(height: 16,),
            Text(
              'Welcome to Smart Lab',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold
              ),
            ),
            Text(
              'Let\'s get started',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold
              ),
            ),
            SizedBox(height: 16.0,),
            SignInButton(
              Buttons.Google,
              onPressed: () async {
                final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
                final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
                final credential = GoogleAuthProvider.credential(
                  accessToken: googleAuth?.accessToken,
                  idToken: googleAuth?.idToken
                );
                await FirebaseAuth.instance.signInWithCredential(credential).then((userCredentials) {
                  print(userCredentials.user?.email);
                  print(userCredentials.user?.displayName);
                  print(userCredentials.user);
                  FirebaseFirestore db = FirebaseFirestore.instance;
                  final authorizedUser = db.collection('authorizedUsers').doc(userCredentials.user?.email);
                  authorizedUser.get().then((DocumentSnapshot documentSnapshot) async{
                    if(documentSnapshot.exists){
                      final user = db.collection('registeredUsers').doc(userCredentials.user?.email);
                      user.get().then((DocumentSnapshot userDocumentSnapshot) async{
                        if(userDocumentSnapshot.exists){
                          final userData = userDocumentSnapshot.data() as Map<String, dynamic>;
                          name = userData['name'];
                          email = userCredentials.user?.email;
                          final SharedPreferences prefs = await SharedPreferences.getInstance();
                          prefs.setString('name', name);
                          prefs.setString('email', email);
                          await getPersonCount(context);
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage(name: name.toString(), email: email.toString(),)));
                        }
                        else{
                          Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterPage(email: userCredentials.user?.email,)));
                        }
                      }).catchError((err) {
                        showAlert(context, 'Unable to fetch user details\n' + err.toString());
                      });
                    }
                    else{
                      showAlert(context, 'You are not authorized to use the Smart Lab');
                    }
                  }).catchError((err) {
                    showAlert(context, 'Unable to fetch user details\n' + err.toString());
                  });
                });
              },
            )
          ],
        ),
      ),
    );
  }
}
