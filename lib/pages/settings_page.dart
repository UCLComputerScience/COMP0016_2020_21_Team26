import 'package:flutter/material.dart';
import 'package:nudge_me/model/user_model.dart';
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
        onPressed: () => UserWellbeingDB()
            .insert(WellbeingItem(wellbeingScore: 8.0, numSteps: 60000)),
        child: Text("new"),
      ),
      ElevatedButton(
        onPressed: () => UserWellbeingDB().delete(),
        child: Text("Reset Wellbeing Data"),
      )
    ]);
  }
}
