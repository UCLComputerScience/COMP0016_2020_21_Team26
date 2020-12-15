import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'dart:async';
import 'package:jiffy/jiffy.dart';
import 'package:nudge_me/model/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Checkup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "Checkup",
        home: Scaffold(
            appBar: AppBar(title: const Text("Checkup")),
            body: CheckupWidgets()));
  }
}

//wb scale
class CheckupWidgets extends StatefulWidget {
  CheckupWidgets({Key key}) : super(key: key);

  @override
  _CheckupWidgetsState createState() => _CheckupWidgetsState();
}

/// This is the private State class that goes with MyStatefulWidget.
class _CheckupWidgetsState extends State<CheckupWidgets> {
  double _currentSliderValue = 0;
  double _weeklyWBScore = 0;

  StreamSubscription<StepCount> _subscription;
  int thisWeekSteps;

  @override
  void initState() {
    super.initState();
    startListening();
  }

  void startListening() {
    //Stream<StepCount> stream = Pedometer.stepCountStream;
    //_pedometer = Pedometer();
    Stream<StepCount> stream = Pedometer.stepCountStream;
    _subscription = stream.listen(
      getWeeklySteps,
      onError: _onError,
      onDone: _onDone,
      cancelOnError: true,
    );
  }

  getSteps(savedStepsCountKey) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int userSupportCode = prefs.getInt(savedStepsCountKey);
    return userSupportCode;
  }

  setSteps(savedStepsCountKey, steps) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(savedStepsCountKey, steps);
  }

  Future<int> getWeeklySteps(StepCount value) async {
    print(value);
    int savedStepsCountKey = 999999;
    int savedStepsCount = getSteps(savedStepsCountKey);

    int todayDayNo = Jiffy(DateTime.now()).dayOfYear;
    if (value.steps < savedStepsCount) {
      // Upon device reboot, pedometer resets. When this happens, the saved counter must be reset as well.
      savedStepsCount = 0;
      // persist this value using a package of your choice here

      setSteps(savedStepsCountKey, savedStepsCount);
    }

    // load the last day saved using a package of your choice here
    int lastWeekSavedKey = 888888;

    int lastWeekSaved = getSteps(lastWeekSavedKey);

    // When the day changes, reset the daily steps count
    // and Update the last day saved as the day changes.
    if (todayDayNo - lastWeekSaved == 7) {
      lastWeekSaved = todayDayNo;
      savedStepsCount = value.steps;

      setSteps(lastWeekSavedKey, lastWeekSaved);
      setSteps(savedStepsCountKey, savedStepsCount);
    }

    setState(() {
      thisWeekSteps = value.steps - savedStepsCount;
    });
    setSteps(todayDayNo, thisWeekSteps);
    return thisWeekSteps;
  }

  void _onError(error) => print("Flutter Pedometer Error: $error");

  void _onDone() => print("Finished pedometer tracking");

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }

  void stopListening() {
    _subscription.cancel();
  }

  getPostcode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userPostcode = prefs.getString('postcode');
    return userPostcode;
  }

  getSupportCode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userSupportCode = prefs.getString('support_code');
    return userSupportCode;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text("How did you feel this week?"),
      Slider(
        value: _currentSliderValue,
        min: 0,
        max: 10,
        divisions: 10,
        label: _currentSliderValue.toString(),
        onChanged: (double value) {
          setState(() {
            _currentSliderValue = value;
          });
        },
      ),
      Text("Your steps this week:"),
      Text(thisWeekSteps.toString()),
      RaisedButton(
          onPressed: () {
            _weeklyWBScore = _currentSliderValue;
            WellbeingItem weeklyWellbeingItem = new WellbeingItem();
            weeklyWellbeingItem.id = 0;
            weeklyWellbeingItem.date = DateTime.now().toString();
            weeklyWellbeingItem.postcode = getPostcode();
            weeklyWellbeingItem.wellbeingScore = _weeklyWBScore;
            weeklyWellbeingItem.numSteps = thisWeekSteps;
            weeklyWellbeingItem.supportCode = getSupportCode();
            UserWellbeingDB().insert(weeklyWellbeingItem);
          },
          child: const Text('Done'))
    ]);
  }
}
