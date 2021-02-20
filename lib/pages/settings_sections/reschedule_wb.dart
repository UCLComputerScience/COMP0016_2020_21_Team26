import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nudge_me/notification.dart';

List<String> days = [
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday",
  "Sunday"
];
final hours = [for (var i = 1; i < 24; i += 1) i];
final minutes = [for (var i = 00; i < 60; i += 1) i];

class NotificationSelector extends StatefulWidget {
  @override
  _NotificationSelectorState createState() => _NotificationSelectorState();
}

class _NotificationSelectorState extends State<NotificationSelector> {
  int _wbCheckNotifDay;
  int _wbCheckNotifHour;
  int _wbCheckNotifMinute;

  void _getWbCheckNotifTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DateTime _wbCheckNotifTime =
        DateTime.parse(prefs.getString('wb_notif_time'));

    setState(() {
      _wbCheckNotifDay = _wbCheckNotifTime.day;
      _wbCheckNotifHour = _wbCheckNotifTime.hour;
      _wbCheckNotifMinute = _wbCheckNotifTime.minute;
    });
  }

  @override
  void initState() {
    super.initState();
    _getWbCheckNotifTime();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        DropdownButton(
          value: _wbCheckNotifDay,
          hint: Text("Day"),
          icon:
              Icon(Icons.arrow_downward, color: Theme.of(context).primaryColor),
          iconSize: 20,
          elevation: 16,
          style: Theme.of(context).textTheme.bodyText1,
          underline: Container(
            height: 2,
            color: Theme.of(context).primaryColor,
          ),
          onChanged: (value) {
            setState(() {
              if (value != null) {
                _wbCheckNotifDay = value;
              }
            });
          },
          items: <int>[
            DateTime.monday,
            DateTime.tuesday,
            DateTime.wednesday,
            DateTime.thursday,
            DateTime.friday,
            DateTime.saturday,
            DateTime.sunday
          ].map<DropdownMenuItem<int>>((int value) {
            return DropdownMenuItem<int>(
              value: value,
              child: Text(days[value - 1]),
            );
          }).toList(),
        ),
        SizedBox(width: 10),
        DropdownButton(
            value: _wbCheckNotifHour,
            hint: Text("Hour"),
            icon: Icon(Icons.arrow_downward,
                color: Theme.of(context).primaryColor),
            iconSize: 20,
            elevation: 16,
            style: Theme.of(context).textTheme.bodyText1,
            underline: Container(
              height: 2,
              color: Theme.of(context).primaryColor,
            ),
            onChanged: (value) {
              setState(() {
                if (value != null) {
                  _wbCheckNotifHour = value;
                }
              });
            },
            items: hours.map<DropdownMenuItem>((value) {
              return DropdownMenuItem(
                value: value,
                child: Text(value.toString().padLeft(2, "0")),
              );
            }).toList()),
        SizedBox(width: 5),
        DropdownButton(
            value: _wbCheckNotifMinute,
            hint: Text("Minutes"),
            icon: Icon(Icons.arrow_downward,
                color: Theme.of(context).primaryColor),
            iconSize: 20,
            elevation: 16,
            style: Theme.of(context).textTheme.bodyText1,
            underline: Container(
              height: 2,
              color: Theme.of(context).primaryColor,
            ),
            onChanged: (value) {
              setState(() {
                if (value != null) {
                  _wbCheckNotifMinute = value;
                }
              });
            },
            items: minutes.map<DropdownMenuItem>((value) {
              return DropdownMenuItem(
                value: value,
                child: Text(value.toString().padLeft(2, "0")),
              );
            }).toList()),
      ]),
      ElevatedButton(
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(
                  Color.fromARGB(255, 0, 74, 173))),
          child: const Text('Reschedule'),
          onPressed: () {
            setState(() {
              if (_wbCheckNotifDay != null &&
                  _wbCheckNotifHour != null &&
                  _wbCheckNotifMinute != null) {
                rescheduleCheckup(_wbCheckNotifDay,
                    Time(_wbCheckNotifHour, _wbCheckNotifMinute));
                String wbCheckNotifDayName = days[_wbCheckNotifDay - 1];

                Scaffold.of(context).showSnackBar(SnackBar(
                    content: Text(
                        "Your Wellbeing Check notification has been rescheduled to $wbCheckNotifDayName at $_wbCheckNotifHour:${_wbCheckNotifMinute.toString().padLeft(2, "0")}")));
              }
            });
          })
    ]);
  }
}

class RescheduleWBCheckNotif extends StatefulWidget {
  @override
  _RescheduleWBCheckNotifState createState() => _RescheduleWBCheckNotifState();
}

class _RescheduleWBCheckNotifState extends State<RescheduleWBCheckNotif> {
  @override
  Widget build(BuildContext context) {
    final _selectorInstructions = Column(children: [
      Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Text(
            "\nTo reschedule your wellbeing check notification, follow the instructions below.\n",
            textAlign: TextAlign.center,
          )),
      Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Text(
              "Using the Date and Time selector below,\n" +
                  "1. Click the weekday it is currently set to and choose the day you would like to receive your Wellbeing Check notification. \n\n" +
                  "2. Click the hour and minute to change these to the time you would like to receive your Wellbeing Check notification. \n\n" +
                  "3. When the day, hour and minute has been set, click the Reschedule button. \n\n",
              textAlign: TextAlign.start))
    ]);

    return Scaffold(
        appBar: AppBar(title: Text("Wellbeing Check")),
        body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [_selectorInstructions, NotificationSelector()]));
  }
}
