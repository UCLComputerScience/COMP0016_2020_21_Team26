import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nudge_me/model/user_model.dart';
import 'package:nudge_me/pages/publish_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

_updatePostcode(String value) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('postcode', value);
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TextField(
        onSubmitted: _updatePostcode,
      ),
      ElevatedButton(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => SafeArea(
                  child: Scaffold(body: PublishScreen(),))
              )),
          child: Text("Publish Data")),
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
