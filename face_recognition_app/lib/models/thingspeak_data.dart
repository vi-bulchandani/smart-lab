import 'dart:convert';

import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

class ThingspeakData {

  final double field1;
  final double field2;
  final double field3;
  final double field4;
  final int field5;
  final DateTime timestamp;

  ThingspeakData(this.field1, this.field2, this.field3, this.field4, this.field5, this.timestamp);

}

List<ThingspeakData> data = [];
String _dataUrl = 'https://thingspeak.com/channels/2098172/feeds.json';

Future<void> getData() async{
  print('INFO: Request made to Thingspeak Server');
  final response = await http.get(Uri.parse(_dataUrl));
  if(response.statusCode == 200){
    data = [];
    dynamic jsonResponseData = jsonDecode(response.body);
    for(var item in jsonResponseData['feeds']){
      if(item['field1']!=null && item['field2']!=null && item['field3']!=null && item['field4']!=null){
        if(item['field5'] == null) item['field5'] = 0;
        data.add(ThingspeakData(double.parse(item['field1'].toString()), double.parse(item['field2'].toString()), double.parse(item['field3'].toString()), double.parse(item['field4'].toString()), int.parse(item['field5'].toString()), DateTime.parse(item['created_at'].toString())));
      }
    }
    for(var feed in data){
      print('INFO: ' + feed.field1.toString() + ', ' + feed.field2.toString() + ', ' + feed.field3.toString() + ', ' + feed.field4.toString() + ', ' + feed.field5.toString() + ', ' + feed.timestamp.toString());
    }
  }
  else{
    print('ERR: ${response.statusCode} - Failed to fetch data from Thingspeak');
  }
}