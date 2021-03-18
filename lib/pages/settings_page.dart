import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nudge_me/background.dart';
import 'package:nudge_me/pages/settings_sections/change_postcode.dart';
import 'package:nudge_me/pages/settings_sections/change_suppcode.dart';
import 'package:nudge_me/pages/settings_sections/reschedule_wb.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main_pages.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final settingsWidget = SettingsList(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
        ]),
        SettingsSection(
          title: 'Data & Privacy',
          tiles: [
            SettingsTile.switchTile(
              title: 'Share Data',
              subtitle: 'Send anonymised data.',
              leading: Icon(Icons.send),
              switchValue: publishTask != null,
              onToggle: (bool value) =>
                  setState(() => value ? schedulePublish() : cancelPublish()),
            )
          ],
        ),
      ],
    );

    return Scaffold(
        body: Column(children: [
          Text("Settings",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headline1),
          SizedBox(height: 10),
          Expanded(flex: 3, child: settingsWidget),
          SizedBox(height: 10),
          Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: RichText(
                      text: new TextSpan(children: [
                        new TextSpan(
                            text:
                                "This will help users understand the general wellbeing of people in a region - ",
                            style: TextStyle(
                                fontFamily: 'Rosario',
                                fontSize: 12,
                                color: Colors.black)),
                        new TextSpan(
                            text: "see here.",
                            style: TextStyle(
                                fontFamily: 'Rosario',
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                                color: Colors.black),
                            recognizer: new TapGestureRecognizer()
                              ..onTap = () {
                                launch(BASE_URL + '/map');
                              })
                      ]),
                      textAlign: TextAlign.start))),
          SizedBox(height: 50),
        ]),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor);
  }
}
