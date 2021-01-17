import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nudge_me/main.dart';
import 'package:nudge_me/notification.dart';
import 'package:nudge_me/shared/alt_step_switch.dart';
import 'package:pedometer/pedometer.dart';
import 'dart:async';
import 'package:nudge_me/model/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Checkup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Center(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
              Text("Checkup", style: Theme.of(context).textTheme.headline1),
              SizedBox(height: 30),
              CheckupWidgets(),
            ]))),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor);
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
  int _currentTotalSteps = 0;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() async {
    final isUsingAlt = await SharedPreferences.getInstance()
        .then((prefs) => prefs.getBool(ALT_STEP_COUNT_KEY));

    Stream<StepCount> stream =
        isUsingAlt ? Pedometer.altStepCountStream : Pedometer.stepCountStream;
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
    if (items.length == n + 1 &&
        _isDecreasing(items.map((item) => item.wellbeingScore).toList())) {
      // if there were enough scores, and they were decreasing
      scheduleNudge();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text("Your steps this week:",
          style: Theme.of(context).textTheme.bodyText1),
      FutureBuilder(
        future: _lastTotalStepsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final int lastTotalSteps = snapshot.data;
            final thisWeeksSteps = lastTotalSteps > _currentTotalSteps
                ? _currentTotalSteps
                : _currentTotalSteps - lastTotalSteps;
            return Text(thisWeeksSteps.toString(),
                style: TextStyle(
                    fontFamily: 'Rosario',
                    fontSize: 25,
                    color: Theme.of(context).accentColor));
          } else if (snapshot.hasError) {
            print(snapshot.error);
            return Text("Something went wrong...",
                style: TextStyle(
                    fontFamily: 'Rosario',
                    fontSize: 25,
                    color: Theme.of(context).accentColor));
          }
          return CircularProgressIndicator();
        },
      ),
      SizedBox(height: 40),
      Text("How did you feel this week?",
          style: Theme.of(context).textTheme.bodyText1),
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
      SizedBox(height: 10),
      ElevatedButton(
          onPressed: () async {
            final lastTotalSteps = await _lastTotalStepsFuture;
            final dateString =
                DateTime.now().toIso8601String().substring(0, 10);
            WellbeingItem weeklyWellbeingItem = new WellbeingItem(
                id: null,
                date: dateString,
                postcode: await _getPostcode(),
                wellbeingScore: _currentSliderValue,
                numSteps: _currentTotalSteps - lastTotalSteps,
                supportCode: await _getSupportCode());
            await UserWellbeingDB().insert(weeklyWellbeingItem);
            SharedPreferences.getInstance().then((value) =>
                value.setInt(PREV_STEP_COUNT_KEY, _currentTotalSteps));
            Navigator.pop(context);

            _checkWellbeing(2); // nudges if scores dropped twice
          },
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(
                  Theme.of(context).primaryColor)),
          child: const Text('Done', style: TextStyle(fontFamily: 'Rosario')))
    ]);
  }
}
