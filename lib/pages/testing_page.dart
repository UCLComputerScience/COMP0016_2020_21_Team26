import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nudge_me/model/user_model.dart';
import 'package:nudge_me/notification.dart';
import 'package:nudge_me/pages/checkup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class TestingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child:
            Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          Text("Debug Page (NOT IN FINAL APP)"),
          ElevatedButton(
            onPressed: () {
              final datetime =
                  tz.TZDateTime.now(tz.local).add(Duration(milliseconds: 20));
              scheduleCheckupOnce(datetime);
            },
            child: Text("Wellbeing Check Notification"),
          ),
          ElevatedButton(
            onPressed: () {
              final datetime =
                  tz.TZDateTime.now(tz.local).add(Duration(milliseconds: 20));
              schedulePublishOnce(datetime);
            },
            child: Text("Publish Notification"),
          ),
          ElevatedButton(
            onPressed: () => scheduleNudge(),
            child: Text("Example Nudge"),
          ),
          ElevatedButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => WellbeingCheck(UserWellbeingDB()))),
              child: Text("Wellbeing Check Screen")),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final dateStr = DateTime.now().toIso8601String().substring(0, 10);
              UserWellbeingDB().insert(WellbeingItem(
                postcode: prefs.getString('postcode'),
                wellbeingScore: Random().nextDouble() * 10.0,
                numSteps: Random().nextInt(70001),
                supportCode: prefs.getString('support_code'),
                date: dateStr,
              ));
            },
            child: Text("Generate WellbeingItem"),
          ),
          ElevatedButton(
            onPressed: () => UserWellbeingDB().delete(),
            child: Text("Reset Wellbeing Data"),
          )
        ]),
      ),
    );
  }
}
