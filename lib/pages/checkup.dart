import 'package:flutter/material.dart';
import 'package:nudge_me/main.dart';
import 'package:pedometer/pedometer.dart';
import 'dart:async';
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

  final Future<int> _lastTotalStepsFuture = SharedPreferences.getInstance().then((value) => value.getInt(STEP_COUNT_TOTAL_KEY));
  int _currentTotalSteps;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    Stream<StepCount> stream = Pedometer.stepCountStream;
    _subscription = stream.listen(
      _onStepCount,
      onError: _onError,
      onDone: _onDone,
      cancelOnError: true,
    );
  }

  void _onStepCount(StepCount value) async {
    setState(() {
      _currentTotalSteps = value.steps;
    });
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
      FutureBuilder(future: _lastTotalStepsFuture, builder: (context, snapshot) {
        if (snapshot.hasData) {
          int x = snapshot.data;
          return Text((_currentTotalSteps-x).toString());
        }
        return Text("Loading");
      },), //steps
      RaisedButton(
          onPressed: () async {
            _weeklyWBScore = _currentSliderValue;
            WellbeingItem weeklyWellbeingItem = new WellbeingItem(
                id: null,
                date: DateTime.now().toString(),
                postcode: _getPostcode(),
                wellbeingScore: _weeklyWBScore,
                numSteps: _currentTotalSteps- await SharedPreferences.getInstance().then((value) => value.getInt(STEP_COUNT_TOTAL_KEY)),
                supportCode: _getSupportCode());
            UserWellbeingDB().insert(weeklyWellbeingItem);
            SharedPreferences.getInstance().then((value) => value.setInt(STEP_COUNT_TOTAL_KEY, _currentTotalSteps));
          },
          child: const Text('Done'))
    ]);
  }
}
