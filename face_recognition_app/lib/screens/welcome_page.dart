import 'package:face_recognition_app/screens/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
                  Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
                });
              },
            )
          ],
        ),
      ),
    );
  }
}
