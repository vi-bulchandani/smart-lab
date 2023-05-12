// Importing project packages
import 'package:face_recognition_app/utilities/alert.dart';

// Importing other Dart and Flutter packages
import 'dart:convert';
import 'dart:convert' as convert;
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;


class ThingspeakData {

  final double field1;
  // final double field2;
  final double field3;
  final double field4;
  final int field5;
  final int field6;
  final int field7;
  final DateTime timestamp;

  ThingspeakData(this.field1, this.field3, this.field4, this.field5, this.field6, this.field7, this.timestamp);

}

List<ThingspeakData> data = [];
String _dataUrl = 'https://thingspeak.com/channels/2098172/feeds.json';

int minTemp = 0;
int maxTemp = 0;

// Retrieves data of live environment from the Thingspeak server using HTTP GET request. See https://in.mathworks.com/help/thingspeak/readdata.html for more information
// Valid data are parsed and populated in data[] array and minTemp, maxTemp variables
// For live environment, valid data comprises of an item which contains readings for all 3 of CO, Temperature, Humidity levels
// For AC temperature threshold, valid data comprises of an item which contains readings for both minimum and maximum temperature
// If the above task fails, error is displayed using the showAlert() utility
Future<void> getData(BuildContext context) async{
  print('INFO: Request made to Thingspeak Server');
  final response = await http.get(Uri.parse(_dataUrl));
  if(response.statusCode == 200){
    data = [];
    dynamic jsonResponseData = jsonDecode(response.body);
    for(var item in jsonResponseData['feeds']){
      if(item['field1']!=null && item['field3']!=null && item['field4']!=null){
        if(item['field1'] == 'nan' || item['field3'] == 'nan' || item['field4'] == 'nan') continue;
        if(item['field5'] == null) item['field5'] = 0;
        if(item['field6'] == null) item['field6'] = 0;
        if(item['field7'] == null) item['field7'] = 0;
        data.add(ThingspeakData(double.parse(item['field1'].toString()), double.parse(item['field3'].toString()), double.parse(item['field4'].toString()), int.parse(item['field5'].toString()), int.parse(item['field6'].toString()), int.parse(item['field7'].toString()), DateTime.parse(item['created_at'].toString())));
      }
      if(item['field6']!=null && item['field7']!=null){
        minTemp = int.parse(item['field6'].toString());
        maxTemp = int.parse(item['field7'].toString());
      }
    }
    for(var feed in data){
      print('INFO: ' + feed.field1.toString() + ', ' + feed.field3.toString() + ', ' + feed.field4.toString() + ', ' + feed.field5.toString() + ', ' + feed.timestamp.toString());
    }
  }
  else{
    showAlert(context, '${response.statusCode} - Failed to fetch data from Thingspeak');
  }
}

// Updates the threshold values set by the user from the app to the Thingspeak server using HTTP POST request. See https://in.mathworks.com/help/thingspeak/writedata.html for more information
// If the above task fails, error is displayed using the showAlert() utility
Future<void> updateFlapState(int updatedState, BuildContext context) async {
  print('INFO: Sending update to Thingspeak Server');
  var url = 'https://api.thingspeak.com/update';
  var body = json.encode({'api_key': 'PX70HD36BJ7MACXK', 'field5': updatedState});
  Map<String, String> headers = {
    'Content-Type': 'application/json'
  };
  final response = await http.post(Uri.parse(url), headers: headers, body: body);
  if(response.statusCode == 200 && response.body != '0'){
    print('INFO: Updated Thingspeak Server successfully');
  }
  else{
    showAlert(context, '${response.statusCode} - Failed updating data to Thingspeak');
  }
}

Future<void> updateThresholdTemperature(BuildContext context) async {
  print('INFO: Sending update to Thingspeak Server');
  var url = 'https://api.thingspeak.com/update';
  var body = json.encode({'api_key': 'PX70HD36BJ7MACXK', 'field6': minTemp, 'field7': maxTemp});
  Map<String, String> headers = {
    'Content-Type': 'application/json'
  };
  final response = await http.post(Uri.parse(url), headers: headers, body: body);
  if(response.statusCode == 200 && response.body != '0'){
    print('INFO: Updated Thingspeak Server successfully');
  }
  else{
    showAlert(context, '${response.statusCode} - Failed updating data to Thingspeak');
  }
}