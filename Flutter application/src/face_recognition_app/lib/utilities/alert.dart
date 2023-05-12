import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

// Shows a customised alert for errors on the screen whose context is passed along with the error message
dynamic showAlert(BuildContext context, String message) {
  return Alert(
    context: context,
    type: AlertType.warning,
    title: "ALERT",
    desc: message,
    buttons: [
      DialogButton(
        child: Text(
          "OK",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        onPressed: () => Navigator.pop(context),
        width: 120,
      )
    ],
  ).show();
}