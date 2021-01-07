import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        backgroundColor: Color.fromARGB(255, 251, 249, 255));
  }
}

class ChangePostcodeWidget extends StatefulWidget {
  @override
  _ChangePostcodeWidgetState createState() => _ChangePostcodeWidgetState();
}

class _ChangePostcodeWidgetState extends State<ChangePostcodeWidget> {
  final _postcodeKey = GlobalKey<FormState>();
  String _currentPostcode;
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text("Postcode ",
          style: TextStyle(
              fontFamily: 'Rosario',
              fontSize: 20,
              decoration: TextDecoration.underline)),
      SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text("Current Postcode: ",
            style: TextStyle(
                fontFamily: 'Rosario',
                fontWeight: FontWeight.w500,
                fontSize: 15)),
        FutureBuilder(
            future: _getPostcode(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(snapshot.data,
                    style: TextStyle(fontFamily: 'Rosario', fontSize: 15));
              } else if (snapshot.hasError) {
                print(snapshot.error);
                return Text("Something went wrong...",
                    style: TextStyle(fontFamily: 'Rosario', fontSize: 15));
              }
              return CircularProgressIndicator();
            })
      ]),
      SizedBox(height: 20),
      Container(
          child: Form(
              key: _postcodeKey,
              child: TextFormField(
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    enabledBorder: const OutlineInputBorder(
                      borderSide: const BorderSide(
                          color: Color.fromARGB(255, 182, 125, 226),
                          width: 1.0),
                    ),
                  ),
                  maxLength: 4,
                  validator: (text) {
                    if (text.length == 0) {
                      return "You must enter a postcode prefix";
                    }
                    if (text.length < 2 || text.length > 4) {
                      return "Must be between 2 and 4 characters";
                    }
                    return null;
                  },
                  onChanged: (String text) {
                    setState(() {
                      _currentPostcode = text;
                    });
                  })),
          width: 200.0),
      SizedBox(width: 5),
      ElevatedButton(
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(
                  Color.fromARGB(255, 0, 74, 173))),
          child: const Text('Change'),
          onPressed: () {
            if (_postcodeKey.currentState.validate()) {
              setState(() {
                _updatePostcode(_currentPostcode);
              });
            }
          })
    ]);
  }
}

class ChangeSupportWidget extends StatefulWidget {
  @override
  _ChangeSupportWidgetState createState() => _ChangeSupportWidgetState();
}

class _ChangeSupportWidgetState extends State<ChangeSupportWidget> {
  String _currentSupportCode;
  final _supportCodeKey = GlobalKey<FormState>();

  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text("Support Code",
          style: TextStyle(
              fontFamily: 'Rosario',
              fontSize: 20,
              decoration: TextDecoration.underline)),
      SizedBox(height: 10),
      FutureBuilder(
          future: _getSupportCode(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Current Support Code: ",
                        style: TextStyle(
                            fontFamily: 'Rosario',
                            fontWeight: FontWeight.w500,
                            fontSize: 15)),
                    SizedBox(width: 10),
                    Text(snapshot.data,
                        style: TextStyle(fontFamily: 'Rosario', fontSize: 15))
                  ]);
            } else if (snapshot.hasError) {
              print(snapshot.error);
              return Text("Something went wrong...",
                  style: TextStyle(fontFamily: 'Rosario', fontSize: 15));
            }
            return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text("Current Support Code: ",
                  style: TextStyle(
                      fontFamily: 'Rosario',
                      fontSize: 15,
                      fontWeight: FontWeight.w500)),
              SizedBox(width: 10),
              CircularProgressIndicator()
            ]);
          }),
      SizedBox(height: 20),
      Container(
          child: Form(
              key: _supportCodeKey,
              child: TextFormField(
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    enabledBorder: const OutlineInputBorder(
                      borderSide: const BorderSide(
                          color: Color.fromARGB(255, 182, 125, 226),
                          width: 1.0),
                    ),
                  ),
                  validator: (text) {
                    if (text.length == 0) {
                      return "You must enter a support code";
                    }
                    return null;
                  },
                  onChanged: (String text) {
                    setState(() {
                      _currentSupportCode = text;
                    });
                  })),
          width: 200),
      SizedBox(width: 5),
      ElevatedButton(
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(
                  Color.fromARGB(255, 0, 74, 173))),
          child: const Text('Change'),
          onPressed: () {
            if (_supportCodeKey.currentState.validate()) {
              setState(() {
                _updateSupportCode(_currentSupportCode);
              });
            }
          })
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

void _updatePostcode(String value) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('postcode', value);
}

void _updateSupportCode(String value) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('support_code', value);
}
