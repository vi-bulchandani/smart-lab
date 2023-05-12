// Importing project packages
import 'package:face_recognition_app/screens/home_page.dart';
import 'package:face_recognition_app/screens/welcome_page.dart';

// Importing Firebase packages
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Importing other Flutter packages
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {

  // Initializing Flutter App as per Firebase Core configurations
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );

  // Retrieving user details from SharedPreferences
  // NOTE: SharedPreferences is a key-value pair based local storage. See https://pub.dev/packages/shared_preferences for more details
  // NOTE: SharedPreferences is used to maintain persistent authentication of users in the app
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  name = prefs.getString('name');
  email = prefs.getString('email');

  runApp(const MyApp());
}

dynamic name = null;
dynamic email = null;
bool isLoading = false;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Lab App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),

      // Redirecting users directly to HomePage with user details, if user is already logged in
      home: (email == null) ? WelcomePage() : HomePage(name: name.toString(), email: email.toString(),),
    );
  }
}