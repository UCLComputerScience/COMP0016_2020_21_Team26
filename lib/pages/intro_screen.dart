import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

import 'package:cron/cron.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:nudge_me/background.dart';
import 'package:nudge_me/crypto.dart';
import 'package:nudge_me/main.dart';
import 'package:nudge_me/main_pages.dart';
import 'package:nudge_me/shared/wellbeing_graph.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nudge_me/notification.dart';
import 'package:nudge_me/model/user_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:nudge_me/pages/settings_page.dart';

/// Screen that displays to faciliate the user setup.
/// Also schedules the wbCheck/share notifications here to ensure that
/// its only done once.
class IntroScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: IntroScreenWidgets());
  }
}

class IntroScreenWidgets extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _IntroScreenWidgetsState();
}

class _IntroScreenWidgetsState extends State<IntroScreenWidgets> {
  final postcodeController = TextEditingController();
  final supportCodeController = TextEditingController();

  double _currentSliderValue = 0;
  bool _currentSwitchValue = false;
  int _wbCheckNotifDay = DateTime.sunday;
  int _wbCheckNotifHour = 12;
  int _wbCheckNotifMinute = 0;
  int _shareNotifDay = DateTime.monday;
  int _shareNotifHour = 12;
  int _shareNotifMinute = 0;

  void setInitialWellbeing(
      double _currentSliderValue, String postcode, String suppode) async {
    final dateString = DateTime.now().toIso8601String().substring(0, 10);
    WellbeingItem weeklyWellbeingItem = new WellbeingItem(
        id: null,
        date: dateString,
        postcode: postcode,
        wellbeingScore: _currentSliderValue,
        numSteps: 0,
        supportCode: suppode);
    await UserWellbeingDB().insert(weeklyWellbeingItem);
  }

  void _saveInput(
      String postcode, String suppcode, double _currentSliderValue) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('postcode', postcode);
    prefs.setString('support_code', suppcode);

    setInitialWellbeing(_currentSliderValue, postcode, suppcode);
  }

  bool _isInputValid(String postcode, String suppCode) {
    return 2 <= postcode.length && postcode.length <= 4 && suppCode.length > 0;
  }

  void _onIntroEnd(
      context,
      double _currentSliderValue,
      bool _currentSwitchValue,
      _wbCheckNotifDay,
      _wbCheckNotifHour,
      _wbCheckNotifMinute,
      _shareNotifDay,
      _shareNotifHour,
      _shareNotifMinute) async {
    if (!_isInputValid(
      postcodeController.text,
      supportCodeController.text,
    )) {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("Invalid postcode or support code."),
      ));
      return;
    }

    _saveInput(postcodeController.text.toUpperCase(),
        supportCodeController.text.toUpperCase(), _currentSliderValue);

    // NOTE: this is the 'proper' way of requesting permissions (instead of
    // just lowering the targetSdkVersion) but it doesn't seem to work and
    // I don't have access to an Android 10 device to further test it
    // so... *shrug*
    await Permission.sensors.request();
    await Permission.activityRecognition.request();

    await _finishSetup(
        _currentSwitchValue,
        _wbCheckNotifDay,
        _wbCheckNotifHour,
        _wbCheckNotifMinute,
        _shareNotifDay,
        _shareNotifHour,
        _shareNotifMinute);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MainPages()),
    );
  }

  Future<void> _finishSetup(
      bool _currentSwitchValue,
      _wbCheckNotifDay,
      _wbCheckNotifHour,
      _wbCheckNotifMinute,
      _shareNotifDay,
      _shareNotifHour,
      _shareNotifMinute) async {
    scheduleCheckup(
        _wbCheckNotifDay, Time(_wbCheckNotifHour, _wbCheckNotifMinute));
    if (_currentSwitchValue) {
      schedulePublish(DateTime.monday, 12, 0);
    }
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setBool(FIRST_TIME_DONE_KEY, true));

    // slight performance hit to await but ensures crypto is properly set up:
    await setupCrypto();

    // only start tracking steps after user has done setup
    initBackground();
  }

  void schedulePublish(int day, int hour, int minute) {
    // This may help: https://crontab.guru/
    Cron().schedule(Schedule.parse("$minute $hour * * $day"), () async {
      if (!await UserWellbeingDB().empty) {
        // publish if there is at least one wellbeing item saved
        _publishData();
      }
    });
  }

  /// Lies 30% of the time. Okay technically it lies 3/10 * 10/11 = 3/11 of the
  /// time since there's a chance it could just pick the true score anyway
  int anonymizeScore(double score) {
    final random = Random();
    return (random.nextInt(100) > 69) ? random.nextInt(11) : score.truncate();
  }

  void _publishData() async {
    final items = await UserWellbeingDB().getLastNWeeks(1);
    final item = items[0];
    final int anonScore = anonymizeScore(item.wellbeingScore);
    // int1/int2 is a double in dart
    final double normalizedSteps =
        (item.numSteps / RECOMMENDED_STEPS_IN_WEEK) * 10.0;
    final double errorRate = (normalizedSteps > anonScore)
        ? normalizedSteps - anonScore
        : anonScore - normalizedSteps;

    final body = jsonEncode({
      "postCode": item.postcode,
      "wellbeingScore": anonScore,
      "weeklySteps": item.numSteps,
      // TODO: Maybe change error rate to double
      //       & confirm the units.
      "errorRate": errorRate.truncate(),
      "supportCode": item.supportCode,
      "date_sent": item.date,
    });

    print("Sending body $body");
    http
        .post(BASE_URL + "/add-wellbeing-record",
            headers: {"Content-Type": "application/json"}, body: body)
        .then((response) {
      print("Reponse status: ${response.statusCode}");
      print("Reponse body: ${response.body}");
      final asJson = jsonDecode(response.body);
      // could be null:
      if (asJson['success'] != true) {
        print("Something went wrong.");
      }
    });
  }

  PageViewModel _getWBCheckNotificationPage(
      context, TextStyle introTextStyle, PageDecoration pageDecoration) {
    return PageViewModel(
        title: "Wellbeing Check Notification",
        image: Center(
            child: Image.asset("lib/images/IntroWBCheckNotification.png",
                height: 225.0)),
        bodyWidget: Column(
          children: [
            Text(
                "When do you want to receive your weekly Wellbeing Check notification?",
                style: introTextStyle,
                textAlign: TextAlign.center),
            SizedBox(height: 5),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              DropdownButton(
                value: _wbCheckNotifDay,
                hint: Text("Day"),
                icon: Icon(Icons.arrow_downward,
                    color: Theme.of(context).primaryColor),
                iconSize: 20,
                elevation: 16,
                style: introTextStyle,
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
                  style: introTextStyle,
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
                      child: Text(value.toString()),
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
                  style: introTextStyle,
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
                      child: Text(value.toString()),
                    );
                  }).toList())
            ]),
          ],
        ),
        decoration: pageDecoration);
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    TextStyle introTextStyle =
        TextStyle(fontSize: width * 0.045, color: Colors.black);
    TextStyle introHintStyle =
        TextStyle(fontSize: width * 0.045, color: Colors.grey);

    const pageDecoration = const PageDecoration(
        titleTextStyle: TextStyle(fontSize: 27.0, fontWeight: FontWeight.w700),
        descriptionPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 0.0),
        pageColor: Color.fromARGB(255, 251, 249, 255),
        imagePadding: EdgeInsets.zero);

    return IntroductionScreen(
        pages: [
          PageViewModel(
              title: "Welcome",
              image: Image.asset("lib/images/IntroLogo.png", height: 250.0),
              bodyWidget: Text(
                  "Someone from the NHS will have recommended this app to you. \n\n " +
                      "This app has been designed to encourage you to take care of yourself. \n \n" +
                      "Swipe left to learn more",
                  style: introTextStyle,
                  textAlign: TextAlign.center),
              decoration: pageDecoration),
          PageViewModel(
              title: "How?",
              image: Image.asset("lib/images/IntroLogo.png", height: 250.0),
              bodyWidget: Text(
                  "It does this by sending weekly notifications asking you how you feel, and show how walking more can improve your wellbeing. \n\n" +
                      "Occasionally, it will nudge you to share your wellbeing with people you know. \n \n ",
                  style: introTextStyle,
                  textAlign: TextAlign.center),
              decoration: pageDecoration),
          PageViewModel(
              title: "Wellbeing Check",
              image: Center(
                  child: Image.asset("lib/images/IntroWBCheck.png",
                      height: 225.0)),
              bodyWidget: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                        "This is your first wellbeing check. NudgeMe will allow you to keep a weekly record of your wellbeing and allow you to understand the importance of movement in your life.",
                        style: introTextStyle,
                        textAlign: TextAlign.center),
                    Text(
                        "\n Over the past 7 days, rate how well you have felt out of 10. ",
                        style: introTextStyle,
                        textAlign: TextAlign.center),
                    Container(
                        child: Slider(
                          value: _currentSliderValue,
                          min: 0,
                          max: 10,
                          divisions: 10,
                          label: _currentSliderValue.round().toString(),
                          activeColor: Theme.of(context).primaryColor,
                          inactiveColor: Color.fromARGB(189, 189, 189, 255),
                          onChanged: (double value) {
                            setState(() {
                              _currentSliderValue = value;
                            });
                          },
                        ),
                        width: 300.0),
                    Text(
                        "Move the blue circle up or down the scale to log how you feel." +
                            " (On the scale, 0 is the lowest score and 10 is the highest score)",
                        style: introTextStyle,
                        textAlign: TextAlign.center),
                    SizedBox(height: 15),
                  ]),
              decoration: pageDecoration),
          _getWBCheckNotificationPage(context, introTextStyle, pageDecoration),
          PageViewModel(
              title: "Share Data",
              image: Center(
                  child:
                      Image.asset("lib/images/IntroShare.png", height: 225.0)),
              bodyWidget: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Switch(
                        value: _currentSwitchValue,
                        onChanged: (value) {
                          setState(() {
                            _currentSwitchValue = value;
                          });
                        }),
                    Text(
                        "Click the toggle to consent to the creation of a map that enables you and other app " +
                            "users to understand the effect of exercise on your wellbeing. " +
                            "By consenting, you will not be sharing personally identifiable data. " +
                            "All data used to create the map will be anonymised to protect your privacy.\n",
                        style: introTextStyle,
                        textAlign: TextAlign.center),
                    Text(
                        "This is not necessary to use the app. " +
                            "The only difference is that you will not be asked to publish your data.",
                        style: introTextStyle,
                        textAlign: TextAlign.center),
                  ]),
              decoration: pageDecoration),
          PageViewModel(
              title: "Postcode and Support Code",
              image: Center(
                  child: Image.asset("lib/images/IntroPostcode.png",
                      height: 225.0)),
              bodyWidget: (Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("What is your support code?",
                        style: introTextStyle, textAlign: TextAlign.center),
                    TextField(
                      controller: supportCodeController,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Enter support code here",
                          hintStyle: introHintStyle),
                    ),
                    Text(
                        "(This is the code given to you by the person who recommended you this app.)",
                        style: Theme.of(context).textTheme.caption,
                        textAlign: TextAlign.center),
                    SizedBox(height: 20),
                    Text("What is the first half of your postcode?",
                        style: introTextStyle, textAlign: TextAlign.center),
                    TextField(
                      controller: postcodeController,
                      textAlign: TextAlign.center,
                      // https://github.com/flutter/flutter/issues/67236
                      maxLength: 4, // length of a postcode prefix
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Enter postcode here",
                          hintStyle: introHintStyle),
                    ),
                    SizedBox(height: 10),
                  ])),
              decoration: pageDecoration),
        ],
        onDone: () => _onIntroEnd(
            context,
            _currentSliderValue,
            _currentSwitchValue,
            _wbCheckNotifDay,
            _wbCheckNotifHour,
            _wbCheckNotifMinute,
            _shareNotifDay,
            _shareNotifHour,
            _shareNotifMinute),
        showSkipButton: false,
        next: const Icon(Icons.arrow_forward,
            color: Color.fromARGB(255, 182, 125, 226)),
        done: const Text('Done',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color.fromARGB(255, 182, 125, 226))),
        onChange: (int _) {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            // unfocusing dismisses the keyboard
            currentFocus.unfocus();
          }
        },
        dotsDecorator: const DotsDecorator(
            size: Size(2, 2.5),
            color: Color(0xFFBDBDBD),
            activeColor: Color.fromARGB(255, 0, 74, 173),
            activeSize: Size(3, 3.5),
            activeShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(25.0)))));
  }

  void dispose() {
    // need to dispose of [TextEditingController]
    postcodeController.dispose();
    supportCodeController.dispose();
    super.dispose();
  }
}
