import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:face_recognition_app/utilities/alert.dart';
import 'package:flutter/material.dart';

class EntryLog {
  final String email;
  final DateTime timestamp;

  EntryLog({required this.email, required this.timestamp});

}

int personCount = 0;
List<EntryLog> entryLogs = [];

Future<void> getPersonCount(BuildContext context) async {
  entryLogs.clear();
  await FirebaseFirestore.instance.collection('metadata').doc('environment').get().then((DocumentSnapshot documentSnapshot) {
    final data = documentSnapshot.data() as Map<String, dynamic>;
    personCount = int.parse(data['personCount'].toString());
    dynamic logs = data['entryLogs'];
    for(Map<String, dynamic> log in logs){
      entryLogs.insert(0, EntryLog(email: log['email'], timestamp: (log['timeOfEntry'] as Timestamp).toDate()));
    }
  },
  onError: (err) {
    showAlert(context, err.toString());
  });
}