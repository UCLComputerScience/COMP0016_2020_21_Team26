import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

_getPostcode() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String userPostcode = prefs.getString('postcode');
  return userPostcode;
}

_getSupportCode() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String userSupportCode = prefs.getString('support_code');
  return userSupportCode;
}

_updatePostcode(String value) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('postcode', value);
}

_updateSupportCode(String value) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('support_code', value);
}

class SettingsWidget extends StatefulWidget {
  @override
  _SettingsWidgetState createState() => _SettingsWidgetState();
}

class SettingsWidgetState extends SettingsWidget {}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      Row(children: [
        Text("Postcode: "),
        TextField(
          decoration: InputDecoration(
              border: InputBorder.none, labelText: _getPostcode()),
          maxLength: 4,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z0-9]+"))
          ],
          onChanged: (text) {
            setState(() {
              _currentPostcode = text;
            });
          },
        ),
      ]),
    ]);
  }
}
