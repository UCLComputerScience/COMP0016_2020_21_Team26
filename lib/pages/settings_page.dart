import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nudge_me/model/user_model.dart';
import 'package:nudge_me/notification.dart';
import 'package:nudge_me/pages/publish_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

_updatePostcode(String value) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('postcode', value);
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      TextField(
        onSubmitted: _updatePostcode,
      ),
      ElevatedButton(
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => SafeArea(
                          child: Scaffold(
                        body: PublishScreen(),
                      )))),
          child: Text("Publish Data")),
      ElevatedButton(
          onPressed: () => scheduleNotification(
              tz.TZDateTime.now(tz.local).add(Duration(seconds: 2))),
          child: Text("Test Notification")),
      ElevatedButton(
        onPressed: () => UserWellbeingDB().insert(WellbeingItem(
            wellbeingScore: Random().nextDouble() * 10.0,
            numSteps: Random().nextInt(70001))),
        child: Text("Generate WellbeingItem"),
      ),
      ElevatedButton(
        onPressed: () => UserWellbeingDB().delete(),
        child: Text("Reset Wellbeing Data"),
      )
    ]);
  }
}
