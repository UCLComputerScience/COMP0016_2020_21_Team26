import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "Settings",
        home: Scaffold(
            body: SafeArea(
                child: Column(children: [
          Text("Settings",
              style: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w700)),
          ChangePostcodeWidget(),
          ChangeSupportWidget()
        ]))));
  }
}

class ChangePostcodeWidget extends StatefulWidget {
  @override
  _ChangePostcodeWidgetState createState() => _ChangePostcodeWidgetState();
}

class _ChangePostcodeWidgetState extends State<ChangePostcodeWidget> {
  Widget build(BuildContext context) {
    return Column(children: [
      Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text("Postcode: ")]),
      Row(children: [
        FutureBuilder<String>(
            future: _getPostcode(),
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              return new Flexible(
                  child: TextField(
                decoration: InputDecoration(
                    border: InputBorder.none, hintText: snapshot.data),
                maxLength: 4,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z0-9]+"))
                ],
                onChanged: (text) {
                  setState(() {
                    _updatePostcode(text);
                  });
                },
              ));
            })
      ])
    ]);
  }
}

class ChangeSupportWidget extends StatefulWidget {
  @override
  _ChangeSupportWidgetState createState() => _ChangeSupportWidgetState();
}

class _ChangeSupportWidgetState extends State<ChangeSupportWidget> {
  Widget build(BuildContext context) {
    return Column(children: [
      Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text("Support Code: ")]),
      Row(children: [
        FutureBuilder<String>(
            future: _getSupportCode(),
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              return new Flexible(
                  child: TextField(
                decoration: InputDecoration(
                    border: InputBorder.none, hintText: snapshot.data),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r"[0-9]+"))
                ],
                onChanged: (text) {
                  setState(() {
                    _updateSupportCode(text);
                  });
                },
              ));
            })
      ])
    ]);
  }
}

Future<String> _getPostcode() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String userPostcode = prefs.getString('postcode');
  return userPostcode;
}

Future<String> _getSupportCode() async {
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
