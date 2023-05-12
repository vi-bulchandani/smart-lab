// Importing project packages
import 'package:face_recognition_app/utilities/alert.dart';

// Importing Firebase packages
import 'package:cloud_firestore/cloud_firestore.dart';

// Importing other Flutter packages
import 'package:flutter/material.dart';

class EntryLog {

  // Entry Data
  final String email;
  final DateTime timestamp;

  // An entry can be done only by a user at a particular time
  EntryLog({required this.email, required this.timestamp});

}

int personCount = 0;
List<EntryLog> entryLogs = [];

// Retrieves updated entry logs data from Cloud Firestore
// The data is stored under 'entryLogs' field in 'metadata/environment' document
// The data is parsed and populated in entryLogs[] array
// If any of the above tasks are failed, error is displayed using the showAlert() utility
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