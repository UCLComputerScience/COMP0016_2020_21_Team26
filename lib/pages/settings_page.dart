import 'package:flutter/material.dart';
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
                  style: TextStyle(
                      fontSize: 36.0,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Rosario')),
              SizedBox(height: 30),
              ChangePostcodeWidget(),
              SizedBox(height: 75),
              ChangeSupportWidget()
            ])),
            backgroundColor: Color.fromARGB(255, 251, 249, 255)));
  }
}

class ChangePostcodeWidget extends StatefulWidget {
  @override
  _ChangePostcodeWidgetState createState() => _ChangePostcodeWidgetState();
}

class _ChangePostcodeWidgetState extends State<ChangePostcodeWidget> {
  String _currentPostcode;
  //final Future<String> _nowPostcode = SharedPreferences.getInstance()
  //    .then((prefs) => prefs.getString('postcode'));
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        FutureBuilder(
            future: _getPostcode(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Row(children: [
                  Text("Current Postcode: ",
                      style: TextStyle(
                          fontFamily: 'Rosario',
                          fontWeight: FontWeight.w500,
                          fontSize: 15)),
                  SizedBox(width: 10),
                  Text(snapshot.data,
                      style: TextStyle(fontFamily: 'Rosario', fontSize: 25))
                ]);
              } else if (snapshot.hasError) {
                print(snapshot.error);
                return Text("Something went wrong...",
                    style: TextStyle(fontFamily: 'Rosario', fontSize: 25));
              }
              return Row(children: [
                Text("Current Postcode: ",
                    style: TextStyle(
                        fontFamily: 'Rosario',
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
                SizedBox(width: 10),
                Text("Loading...")
              ]);
            }),
      ]),
      SizedBox(height: 20),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        Text("Postcode: ",
            style: TextStyle(fontFamily: 'Rosario', fontSize: 20)),
        SizedBox(width: 5),
        Container(
            child: TextField(
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  enabledBorder: const OutlineInputBorder(
                    borderSide: const BorderSide(
                        color: Color.fromARGB(255, 182, 125, 226), width: 1.0),
                  ),
                ),
                maxLength: 4,
                onChanged: (text) {
                  setState(() {
                    _currentPostcode = text;
                  });
                }),
            width: 120.0),
        SizedBox(width: 5),
        ElevatedButton(
            style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                    Color.fromARGB(255, 0, 74, 173))),
            child: const Text('Change'),
            onPressed: () {
              _updatePostcode(_currentPostcode);
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
    String _currentSupportCode;
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        FutureBuilder(
            future: _getSupportCode(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Row(children: [
                  Text("Current Support Code: ",
                      style: TextStyle(
                          fontFamily: 'Rosario',
                          fontWeight: FontWeight.w500,
                          fontSize: 15)),
                  Text(snapshot.data,
                      style: TextStyle(fontFamily: 'Rosario', fontSize: 25))
                ]);
              } else if (snapshot.hasError) {
                print(snapshot.error);
                return Text("Something went wrong...",
                    style: TextStyle(fontFamily: 'Rosario', fontSize: 15));
              }
              return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Current Support Code: ",
                        style: TextStyle(fontFamily: 'Rosario', fontSize: 15)),
                    Text("Loading...",
                        style: TextStyle(fontFamily: 'Rosario', fontSize: 15))
                  ]);
            }),
      ]),
      SizedBox(height: 15),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        Text("Support Code: ",
            style: TextStyle(fontFamily: 'Rosario', fontSize: 20)),
        SizedBox(width: 0),
        Container(
            child: TextField(
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  enabledBorder: const OutlineInputBorder(
                    borderSide: const BorderSide(
                        color: Color.fromARGB(255, 182, 125, 226), width: 1.0),
                  ),
                ),
                maxLength: 4,
                onChanged: (text) {
                  setState(() {
                    _currentSupportCode = text;
                  });
                }),
            width: 120.0),
        SizedBox(width: 5),
        ElevatedButton(
            style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                    Color.fromARGB(255, 0, 74, 173))),
            child: const Text('Change'),
            onPressed: () {
              _updateSupportCode(_currentSupportCode);
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
