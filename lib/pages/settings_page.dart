import 'package:flutter/material.dart';
import 'package:nudge_me/pages/settings_sections/change_postcode.dart';
import 'package:nudge_me/pages/settings_sections/change_suppcode.dart';
import 'package:nudge_me/pages/settings_sections/reschedule_wb.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settingsWidget = SettingsList(
      sections: [
        SettingsSection(
          title: 'User Details',
          tiles: [
            SettingsTile(
              title: 'Postcode',
              subtitle: 'View/Change',
              leading: Icon(Icons.house),
              onPressed: (BuildContext context) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChangePostcode()),
                );
              },
            ),
            SettingsTile(
              title: 'Support Code',
              subtitle: 'View/Change',
              leading: Icon(Icons.phone_android_rounded),
              onPressed: (BuildContext context) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChangeSupportCode()),
                );
              },
            )
          ],
        ),
        SettingsSection(title: 'Notifications', tiles: [
          SettingsTile(
            title: 'Wellbeing Check',
            subtitle: 'Reschedule ',
            leading: Icon(Icons.directions_walk),
            onPressed: (BuildContext context) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => RescheduleWBCheckNotif()),
              );
            },
          )
        ])
      ],
    );

    return Scaffold(
        body: Column(children: [
          Text("Settings",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headline1),
          SizedBox(height: 10),
          Flexible(child: settingsWidget)
        ]),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor);
  }
}
