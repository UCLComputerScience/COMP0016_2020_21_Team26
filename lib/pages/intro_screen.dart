import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nudge_me/background.dart';
import 'package:nudge_me/main.dart';
import 'package:nudge_me/main_pages.dart';
import 'package:nudge_me/notification.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Screen that displays to faciliate the user setup.
/// Also schedules the checkup/publish notifications here to ensure that
/// its only done once.
class IntroScreen extends StatefulWidget {
  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          body: Column(
        children: [
          Text(
            "NudgeMe",
            style: TextStyle(fontSize: 25.0),
          ),
          Text("Welcome, let's get you started:"),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                      hintText: "Enter your postcode prefix"),
                  validator: (value) {
                    // TODO: could improve validation
                    if (value.length == 0 || value.length > 4) {
                      return "The postcode prefix is the first part";
                    }
                    return null;
                  },
                  onSaved: _savePostcode,
                ),
                TextFormField(
                  decoration: const InputDecoration(
                      hintText: "Enter your support code"),
                  validator: (value) => null, // NOTE: I assume this is optional
                  onSaved: _saveSupportCode,
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState.validate()) {
                      _formKey.currentState.save();
                      _finishSetup();

                      Navigator.pushReplacement(
                          // switch to main app
                          context,
                          MaterialPageRoute(builder: (context) => MainPages()));
                    }
                  },
                  child: Text("Submit"),
                )
              ],
            ),
          )
        ],
      )),
    );
  }

  void _finishSetup() async {
    scheduleCheckup(DateTime.sunday, const Time(12));
    schedulePublish(DateTime.monday, const Time(12));

    SharedPreferences.getInstance()
        .then((prefs) => prefs.setBool(FIRST_TIME_DONE_KEY, true));

    // only start tracking steps after user has done setup
    initBackground();
  }

  void _savePostcode(String value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('postcode', value);
  }

  void _saveSupportCode(String value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('support_code', value);
  }
}
