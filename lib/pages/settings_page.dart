import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../notification.dart';

List<String> days = [
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday",
  "Sunday"
];
final hours = [for (var i = 1; i < 25; i += 1) i];
final minutes = [for (var i = 00; i < 60; i += 1) i];

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: ListView(children: [
          Text("Settings",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headline1),
          SizedBox(height: 20),
          ChangePostcodeWidget(),
          SizedBox(height: 20),
          ChangeSupportWidget(),
          SizedBox(height: 20),
          RescheduleWBCheckNotif(),
          SizedBox(height: 20),
          RescheduleShareNotif()
        ])),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor);
  }
}

class ChangePostcodeWidget extends StatefulWidget {
  @override
  _ChangePostcodeWidgetState createState() => _ChangePostcodeWidgetState();
}

class _ChangePostcodeWidgetState extends State<ChangePostcodeWidget> {
  final _postcodeKey = GlobalKey<FormState>();

  Future<String> _getPostcode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userPostcode = prefs.getString('postcode');
    return userPostcode;
  }

  void _updatePostcode(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('postcode', value);
  }

  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text("Postcode ", style: Theme.of(context).textTheme.headline2),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text("Current Postcode: ",
            style: Theme.of(context).textTheme.subtitle1),
        FutureBuilder(
            future: _getPostcode(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(snapshot.data,
                    style: Theme.of(context).textTheme.bodyText1);
              } else if (snapshot.hasError) {
                print(snapshot.error);
                return Text("Something went wrong...",
                    style: Theme.of(context).textTheme.bodyText1);
              }
              return CircularProgressIndicator();
            })
      ]),
      SizedBox(height: 8),
      Container(
          child: Form(
              key: _postcodeKey,
              child: TextFormField(
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  enabledBorder: const OutlineInputBorder(
                    borderSide: const BorderSide(
                        color: Color.fromARGB(255, 182, 125, 226), width: 1.0),
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
                onSaved: _updatePostcode,
              )),
          width: 200.0),
      ElevatedButton(
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(
                  Theme.of(context).primaryColor)),
          child: const Text('Change'),
          onPressed: () {
            if (_postcodeKey.currentState.validate()) {
              setState(() {
                _postcodeKey.currentState.save();
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
  final _supportCodeKey = GlobalKey<FormState>();

  Future<String> _getSupportCode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userSupportCode = prefs.getString('support_code');
    return userSupportCode;
  }

  void _updateSupportCode(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('support_code', value);
  }

  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text("Support Code", style: Theme.of(context).textTheme.headline2),
      FutureBuilder(
          future: _getSupportCode(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Current Support Code: ",
                        style: Theme.of(context).textTheme.subtitle1),
                    Text(snapshot.data,
                        style: Theme.of(context).textTheme.bodyText1)
                  ]);
            } else if (snapshot.hasError) {
              print(snapshot.error);
              return Text("Something went wrong...",
                  style: Theme.of(context).textTheme.bodyText1);
            }
            return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text("Current Support Code: ",
                  style: Theme.of(context).textTheme.subtitle1),
              SizedBox(width: 10),
              CircularProgressIndicator()
            ]);
          }),
      SizedBox(height: 8),
      Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
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
                    onSaved: _updateSupportCode,
                  )),
              width: 200)),
      ElevatedButton(
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(
                  Color.fromARGB(255, 0, 74, 173))),
          child: const Text('Change'),
          onPressed: () {
            if (_supportCodeKey.currentState.validate()) {
              setState(() {
                _supportCodeKey.currentState.save();
              });
            }
          })
    ]);
  }
}

class RescheduleWBCheckNotif extends StatefulWidget {
  @override
  _RescheduleWBCheckNotifState createState() => _RescheduleWBCheckNotifState();
}

class _RescheduleWBCheckNotifState extends State<RescheduleWBCheckNotif> {
  int wbCheckNotifDay;
  int wbCheckNotifHour;
  int wbCheckNotifMinute;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text("Wellbeing Check Notification",
          style: Theme.of(context).textTheme.headline2),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        DropdownButton(
          value: wbCheckNotifDay,
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
                wbCheckNotifDay = value;
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
            value: wbCheckNotifHour,
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
                  wbCheckNotifHour = value;
                }
              });
            },
            items: hours.map<DropdownMenuItem>((value) {
              return DropdownMenuItem(
                value: value,
                child: Text(value.toString()),
              );
            }).toList()),
        SizedBox(width: 5),
        DropdownButton(
            value: wbCheckNotifMinute,
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
                  wbCheckNotifMinute = value;
                }
              });
            },
            items: minutes.map<DropdownMenuItem>((value) {
              return DropdownMenuItem(
                value: value,
                child: Text(value.toString()),
              );
            }).toList())
      ]),
      ElevatedButton(
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(
                  Color.fromARGB(255, 0, 74, 173))),
          child: const Text('Reschedule'),
          onPressed: () {
            setState(() {
              if (wbCheckNotifDay != null &&
                  wbCheckNotifHour != null &&
                  wbCheckNotifMinute != null) {
                rescheduleCheckup(wbCheckNotifDay,
                    Time(wbCheckNotifHour, wbCheckNotifMinute));
                String wbCheckNotifDayName = days[wbCheckNotifDay - 1];
                if (wbCheckNotifMinute.toString().length == 1) {
                  String shareNotifMinuteFull = "0$wbCheckNotifMinute";
                  Scaffold.of(context).showSnackBar(SnackBar(
                      content: Text(
                          "Your Wellbeing Check notification has been rescheduled to $wbCheckNotifDayName at $wbCheckNotifHour:$shareNotifMinuteFull")));
                } else {
                  Scaffold.of(context).showSnackBar(SnackBar(
                      content: Text(
                          "Your Wellbeing Check notification has been rescheduled to $wbCheckNotifDayName at $wbCheckNotifHour:$wbCheckNotifMinute")));
                }
              }
            });
          })
    ]);
  }
}

class RescheduleShareNotif extends StatefulWidget {
  @override
  _RescheduleShareNotifState createState() => _RescheduleShareNotifState();
}

class _RescheduleShareNotifState extends State<RescheduleShareNotif> {
  int shareNotifDay;
  int shareNotifHour;
  int shareNotifMinute;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text("Share Data Notification",
          style: Theme.of(context).textTheme.headline2),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        DropdownButton(
          value: shareNotifDay,
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
                shareNotifDay = value;
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
            value: shareNotifHour,
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
                  shareNotifHour = value;
                }
              });
            },
            items: hours.map<DropdownMenuItem>((value) {
              return DropdownMenuItem(
                value: value,
                child: Text(value.toString()),
              );
            }).toList()),
        SizedBox(width: 5),
        DropdownButton(
            value: shareNotifMinute,
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
                  shareNotifMinute = value;
                }
              });
            },
            items: minutes.map<DropdownMenuItem>((value) {
              return DropdownMenuItem(
                value: value,
                child: Text(value.toString()),
              );
            }).toList())
      ]),
      ElevatedButton(
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(
                  Color.fromARGB(255, 0, 74, 173))),
          child: const Text('Reschedule'),
          onPressed: () {
            setState(() {
              if (shareNotifDay != null &&
                  shareNotifHour != null &&
                  shareNotifMinute != null) {
                reschedulePublish(
                    shareNotifDay, Time(shareNotifHour, shareNotifMinute));
                String shareNotifDayName = days[shareNotifDay -
                    1]; //name of day means "monday" rather than 1
                if (shareNotifMinute.toString().length == 1) {
                  String shareNotifMinuteFull = "0$shareNotifMinute";
                  Scaffold.of(context).showSnackBar(SnackBar(
                      content: Text(
                          "Your Share Data notification has been rescheduled to $shareNotifDayName at $shareNotifHour:$shareNotifMinuteFull")));
                } else {
                  Scaffold.of(context).showSnackBar(SnackBar(
                      content: Text(
                          "Your Share Data notification has been rescheduled to $shareNotifDayName at $shareNotifHour:$shareNotifMinute")));
                }
              }
            });
          })
    ]);
  }
}
