import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import 'package:jiffy/jiffy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<int>('steps');
  runApp(Checkup());
}

class Checkup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Checkup",
      home: Scaffold(
          appBar: AppBar(title: const Text("Checkup")),
          body:
              Column(children: <Widget>[WBSliderWidget(), PedometerWidget()])),
    );
  }
}

//wb scale
class WBSliderWidget extends StatefulWidget {
  WBSliderWidget({Key key}) : super(key: key);

  @override
  _WBSliderWidgetState createState() => _WBSliderWidgetState();
}

/// This is the private State class that goes with MyStatefulWidget.
class _WBSliderWidgetState extends State<WBSliderWidget> {
  double _currentSliderValue = 0;
  double _weeklyWBScore = 0;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text("How do you feel right now?"),
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
      RaisedButton(
          onPressed: () {
            _weeklyWBScore = _currentSliderValue;
          },
          child: const Text('Done'))
    ]);
  }
}

//pedometer
class PedometerWidget extends StatefulWidget {
  @override
  _PedometerWidgetState createState() => _PedometerWidgetState();
}

class _PedometerWidgetState extends State<PedometerWidget> {
  StreamSubscription<StepCount> _subscription;

  Box<int> stepsBox = Hive.box('steps');
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

  Future<int> getWeeklySteps(StepCount value) async {
    print(value);
    int savedStepsCountKey = 999999;
    int savedStepsCount = stepsBox.get(savedStepsCountKey, defaultValue: 0);

    int todayDayNo = Jiffy(DateTime.now()).dayOfYear;
    if (value.steps < savedStepsCount) {
      // Upon device reboot, pedometer resets. When this happens, the saved counter must be reset as well.
      savedStepsCount = 0;
      // persist this value using a package of your choice here
      stepsBox.put(savedStepsCountKey, savedStepsCount);
    }

    // load the last day saved using a package of your choice here
    int lastWeekSavedKey = 888888;
    int lastWeekSaved = stepsBox.get(lastWeekSavedKey, defaultValue: 0);

    // When the day changes, reset the daily steps count
    // and Update the last day saved as the day changes.
    if (todayDayNo - lastWeekSaved == 7) {
      lastWeekSaved = todayDayNo;
      savedStepsCount = value.steps;

      stepsBox
        ..put(lastWeekSavedKey, lastWeekSaved)
        ..put(savedStepsCountKey, savedStepsCount);
    }

    setState(() {
      thisWeekSteps = value.steps - savedStepsCount;
    });
    stepsBox.put(todayDayNo, thisWeekSteps);
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

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text("Your steps this week:"),
      Text(thisWeekSteps.toString())
    ]);
  }
}
