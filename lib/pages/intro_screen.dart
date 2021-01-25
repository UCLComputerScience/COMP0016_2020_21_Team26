import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:nudge_me/background.dart';
import 'package:nudge_me/main.dart';
import 'package:nudge_me/main_pages.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nudge_me/notification.dart';
import 'package:nudge_me/model/user_model.dart';
import 'package:permission_handler/permission_handler.dart';

/// Screen that displays to faciliate the user setup.
/// Also schedules the wbCheck/publish notifications here to ensure that
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
  final stepsController = TextEditingController();

  double _currentSliderValue = 0;
  bool _currentSwitchValue = false;
  int _wbCheckNotifDay;
  int _wbCheckNotifHour;
  int _wbCheckNotifMinute;
  int _shareNotifDay;
  int _shareNotifHour;
  int _shareNotifMinute;
  List<String> days = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday"
  ];
  var hours = [for (var i = 1; i < 25; i += 1) i];
  var minutes = [for (var i = 00; i < 60; i += 1) i];

  void setInitialWellbeing(double _currentSliderValue, String steps,
      String postcode, String suppode) async {
    final dateString = DateTime.now().toIso8601String().substring(0, 10);
    WellbeingItem weeklyWellbeingItem = new WellbeingItem(
        id: null,
        date: dateString,
        postcode: postcode,
        wellbeingScore: _currentSliderValue,
        numSteps: int.parse(steps),
        supportCode: suppode);
    await UserWellbeingDB().insert(weeklyWellbeingItem);
  }

  void _saveInput(
      String postcode, String suppcode, double _currentSliderValue) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('postcode', postcode);
    prefs.setString('support_code', suppcode);

    setInitialWellbeing(
        _currentSliderValue, stepsController.text, postcode, suppcode);
  }

  bool _isInputValid(String postcode, String suppCode, String steps) {
    return 2 <= postcode.length &&
        postcode.length <= 4 &&
        suppCode.length > 0 &&
        int.tryParse(steps) != null;
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
    if (!_isInputValid(postcodeController.text, supportCodeController.text,
        stepsController.text)) {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("Invalid postcode, support code or steps."),
      ));
      return;
    }

    _saveInput(postcodeController.text, supportCodeController.text,
        _currentSliderValue);

    // NOTE: this is the 'proper' way of requesting permissions (instead of
    // just lowering the targetSdkVersion) but it doesn't seem to work and
    // I don't have access to an Android 10 device to further test it
    // so... *shrug*
    await Permission.sensors.request();
    await Permission.activityRecognition.request();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MainPages()),
    );
    _finishSetup(
        _currentSwitchValue,
        _wbCheckNotifDay,
        _wbCheckNotifHour,
        _wbCheckNotifMinute,
        _shareNotifDay,
        _shareNotifHour,
        _shareNotifMinute);
  }

  void _finishSetup(
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
      schedulePublish(DateTime.monday, const Time(12));
    }
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setBool(FIRST_TIME_DONE_KEY, true));
    // only start tracking steps after user has done setup
    initBackground();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    TextStyle introTextStyle =
        TextStyle(fontSize: width * 0.045, color: Colors.black);

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
                  "This app has been designed to encourage you to take care of yourself. \n \n Swipe to set up.",
                  style: introTextStyle,
                  textAlign: TextAlign.center),
              decoration: pageDecoration),
          PageViewModel(
              title: "Postcode",
              image: Center(
                  child: Image.asset("lib/images/IntroPostcode.png",
                      height: 225.0)),
              bodyWidget: (Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                          hintStyle: introTextStyle),
                    ),
                  ])),
              decoration: pageDecoration),
          PageViewModel(
              title: "Support",
              image: Center(
                  child: Image.asset("lib/images/IntroSupport.png",
                      height: 225.0)),
              bodyWidget: (Column(children: <Widget>[
                Text("What is your support code?",
                    style: introTextStyle, textAlign: TextAlign.center),
                TextField(
                  controller: supportCodeController,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Enter support code here",
                      hintStyle: introTextStyle),
                ),
              ])),
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
                        "Move the blue circle left or right on the scale to rate your wellbeing: ",
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
                    SizedBox(height: 15),
                    Text(
                        "Approximately, how many steps have you done in the past week?",
                        style: introTextStyle,
                        textAlign: TextAlign.center),
                    TextField(
                      controller: stepsController,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Enter approximate steps here",
                          hintStyle: introTextStyle),
                    ),
                  ]),
              decoration: pageDecoration),
          PageViewModel(
              title: "Wellbeing Check Notification",
              image: Center(
                  child: Image.asset("lib/images/IntroWBCheckNotification.png",
                      height: 225.0)),
              bodyWidget: Column(
                children: [
                  Text(
                      "Once a week, NudgeMe will send you a notification asking you to report your wellbeing. Clicking on this notification will take you to a page that allows you to do this.\n",
                      style: introTextStyle,
                      textAlign: TextAlign.center),
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
              decoration: pageDecoration),
          PageViewModel(
              title: "Share Data",
              image: Center(
                  child:
                      Image.asset("lib/images/IntroShare.png", height: 225.0)),
              bodyWidget: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                        "Click the toggle to consent to the creation of a map that enables you and other app users to understand the effect of exercise on your wellbeing. By consenting, you will not be sharing personally identifiable data. All data used to create the map will be anonymised to protect your privacy.\n",
                        style: introTextStyle,
                        textAlign: TextAlign.center),
                    Text(
                        "This is not necessary to use the app. The only difference is that you will not be asked to publish your data.",
                        style: introTextStyle,
                        textAlign: TextAlign.center),
                    Switch(
                        value: _currentSwitchValue,
                        onChanged: (value) {
                          setState(() {
                            _currentSwitchValue = value;
                          });
                        }),
                  ]),
              decoration: pageDecoration),
          PageViewModel(
              title: "Share Data Notification",
              image: Center(
                  child: Image.asset("lib/images/Intro_shareNotification.png",
                      height: 225.0)),
              bodyWidget: Column(
                children: [
                  Visibility(
                      visible: _currentSwitchValue,
                      child: Column(children: [
                        Text(
                            "Once a week, NudgeMe will send you a notification asking you to share your wellbeing data. Clicking on this notification will take you to a page that asks you whether you want to share.\n",
                            style: introTextStyle,
                            textAlign: TextAlign.center),
                        Text(
                            "When do you want to receive your weekly Share Data notification?",
                            style: introTextStyle,
                            textAlign: TextAlign.center),
                        SizedBox(height: 5),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              DropdownButton(
                                value: _shareNotifDay,
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
                                      _shareNotifDay = value;
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
                                  value: _shareNotifHour,
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
                                        _shareNotifHour = value;
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
                                  value: _shareNotifMinute,
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
                                        _shareNotifMinute = value;
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
                      ])),
                  Visibility(
                    visible: !_currentSwitchValue,
                    child: Column(
                      children: [
                        Text(
                            "You have disabled publishing data so you will not receive a publish notification.",
                            style: introTextStyle,
                            textAlign: TextAlign.center)
                      ],
                    ),
                  )
                ],
              ),
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
            size: Size(4.5, 4.5),
            color: Color(0xFFBDBDBD),
            activeColor: Color.fromARGB(255, 0, 74, 173),
            activeSize: Size(8.0, 5.0),
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
