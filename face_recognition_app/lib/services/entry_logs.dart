import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:face_recognition_app/utilities/alert.dart';
import 'package:flutter/material.dart';

int personCount = 0;

Future<void> getPersonCount(BuildContext context) async {
  await FirebaseFirestore.instance.collection('metadata').doc('environment').get().then((DocumentSnapshot documentSnapshot) {
    final data = documentSnapshot.data() as Map<String, dynamic>;
    personCount = int.parse(data['personCount'].toString());
  },
  onError: (err) {
    showAlert(context, err.toString());
  });
}