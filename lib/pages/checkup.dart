import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nudge_me/main.dart';
import 'package:nudge_me/notification.dart';
import 'package:pedometer/pedometer.dart';
import 'dart:async';
import 'package:nudge_me/model/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

class Checkup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Checkup")), body: CheckupWidgets());
  }
}

class CheckupWidgets extends StatefulWidget {
  CheckupWidgets({Key key}) : super(key: key);

  @override
  _CheckupWidgetsState createState() => _CheckupWidgetsState();
}

class _CheckupWidgetsState extends State<CheckupWidgets> {
  double _currentSliderValue = 0;

  StreamSubscription<StepCount> _subscription;

  // widget records the last weeks & current step total. The difference is
  // the actual step count for the week.
  final Future<int> _lastTotalStepsFuture = SharedPreferences.getInstance()
      .then((prefs) => prefs.getInt(PREV_STEP_COUNT_KEY));
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

  void _onStepCount(StepCount value) async =>
      setState(() => _currentTotalSteps = value.steps);

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

  Future<String> _getPostcode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userPostcode = prefs.getString('postcode');
    return userPostcode;
  }

  Future<String> _getSupportCode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userSupportCode = prefs.getString('support_code');
    return userSupportCode;
  }

  /// returns `true` if given [List] is monotonically decreasing
  bool _isDecreasing(List<dynamic> items) {
    for (int i = 0; i < items.length - 1; ++i) {
      if (items[i] <= items[i + 1]) {
        return false;
      }
    }
    return true;
  }

  /// nudges user if score drops n times in the last n+1 weeks.
  /// For example if n == 2 and we have these 3 weeks/scores 8 7 6, the user
  /// will be nudged.
  void _checkWellbeing(final int n) async {
    assert(n >= 1);
    final List<WellbeingItem> items =
        await UserWellbeingDB().getLastNWeeks(n + 1);
    if (items.length == n + 1 && _isDecreasing(items)) {
      // if there were enough scores, and they were decreasing
      // TODO: perform proper nudge here
      scheduleNotification(
          tz.TZDateTime.now(tz.local).add(const Duration(seconds: 2)));
    }
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
      FutureBuilder(
        future: _lastTotalStepsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final int lastTotalSteps = snapshot.data;
            final thisWeeksSteps = lastTotalSteps > _currentTotalSteps
                ? _currentTotalSteps
                : _currentTotalSteps - lastTotalSteps;
            return Text(thisWeeksSteps.toString());
          } else if (snapshot.hasError) {
            print(snapshot.error);
            return Text("Something went wrong...");
          }
          return Text("Loading");
        },
      ), //steps
      RaisedButton(
          onPressed: () async {
            final lastTotalSteps = await _lastTotalStepsFuture;
            WellbeingItem weeklyWellbeingItem = new WellbeingItem(
                id: null,
                date: DateTime.now()
                    .toString(), // TODO: check if in correct format
                postcode: await _getPostcode(),
                wellbeingScore: _currentSliderValue,
                numSteps: _currentTotalSteps - lastTotalSteps,
                supportCode: await _getSupportCode());
            UserWellbeingDB().insert(weeklyWellbeingItem);
            SharedPreferences.getInstance().then((value) =>
                value.setInt(PREV_STEP_COUNT_KEY, _currentTotalSteps));
            Navigator.pop(context);

            _checkWellbeing(2); // nudges if scores dropped twice
          },
          child: const Text('Done'))
    ]);
  }
}
