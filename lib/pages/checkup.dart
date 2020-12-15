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

class CheckupWidgets extends StatefulWidget {
  CheckupWidgets({Key key}) : super(key: key);

  @override
  _CheckupWidgetsState createState() => _CheckupWidgetsState();
}

class _CheckupWidgetsState extends State<CheckupWidgets> {
  double _currentSliderValue = 0;
  double _weeklyWBScore = 0;

  StreamSubscription<StepCount> _subscription;
  int _thisWeekSteps;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    Stream<StepCount> stream = Pedometer.stepCountStream;
    _subscription = stream.listen(
      _getWeeklySteps,
      onError: _onError,
      onDone: _onDone,
      cancelOnError: true,
    );
  }

  _getSteps(savedStepsCountKey) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int userSupportCode = prefs.getInt(savedStepsCountKey);
    return userSupportCode;
  }

  _setSteps(savedStepsCountKey, steps) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(savedStepsCountKey, steps);
  }

  Future<int> _getWeeklySteps(StepCount value) async {
    print(value);
    String _savedStepsCountKey = 'saved_step_count';
    int _savedStepsCount = _getSteps(_savedStepsCountKey);

    int todayDayNo = Jiffy(DateTime.now()).dayOfYear;
    if (value.steps < _savedStepsCount) {
      // Upon device reboot, pedometer resets. When this happens, the saved counter must be reset as well.
      _savedStepsCount = 0;
      // persist this value using a package of your choice here

      _setSteps(_savedStepsCountKey, _savedStepsCount);
    }

    // load the last week saved using a package of your choice here
    String lastWeekSavedKey = "last_week_step_count";

    int lastWeekSaved = _getSteps(lastWeekSavedKey);

    // When the week changes, reset the weekly steps count
    // and Update the last week saved as the week changes.
    if (todayDayNo - lastWeekSaved == 7) {
      lastWeekSaved = todayDayNo;
      _savedStepsCount = value.steps;

      _setSteps(lastWeekSavedKey, lastWeekSaved);
      _setSteps(_savedStepsCountKey, _savedStepsCount);
    }

    setState(() {
      _thisWeekSteps = value.steps - _savedStepsCount;
    });
    _setSteps(todayDayNo, _thisWeekSteps);
    return _thisWeekSteps;
  }

  void _onError(error) => print("Flutter Pedometer Error: $error");

  void _onDone() => print("Finished pedometer tracking");

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }

  void _stopListening() {
    _subscription.cancel();
  }

  _getPostcode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userPostcode = prefs.getString('postcode');
    return userPostcode;
  }

  _getSupportCode() async {
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
      Text(_thisWeekSteps.toString()), //steps
      RaisedButton(
          onPressed: () {
            _weeklyWBScore = _currentSliderValue;
            WellbeingItem weeklyWellbeingItem = new WellbeingItem(
                id: null,
                date: DateTime.now().toString(),
                postcode: _getPostcode(),
                wellbeingScore: _weeklyWBScore,
                numSteps: _thisWeekSteps,
                supportCode: _getSupportCode());
            UserWellbeingDB().insert(weeklyWellbeingItem);
          },
          child: const Text('Done'))
    ]);
  }
}
