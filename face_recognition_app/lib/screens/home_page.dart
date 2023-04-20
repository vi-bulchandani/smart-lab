import 'package:face_recognition_app/screens/welcome_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {

  String name;

  HomePage({this.name = ''});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
      ),
      body: SizedBox.expand(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Hello ' + this.widget.name + '!',
            ),
          ],
        ),
      ),
    );
  }
}
