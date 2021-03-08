import 'package:flutter/material.dart';
import 'package:nudge_me/main.dart';
import 'package:nudge_me/notification.dart';
import 'dart:async';
import 'package:nudge_me/model/user_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clock/clock.dart';

/// Weekly Checkup notification opens this page.
/// Asks user how they are feeling and adds this score and their steps to their graph.
/// NOTE: Wellbeing Check is sometimes referred to as 'Checkup' in this code, as it was called this previously.
class WellbeingCheck extends StatelessWidget {
  final Stream<int> stepValueStream;

  const WellbeingCheck(this.stepValueStream);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Center(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
              Text("Wellbeing Check",
                  style: Theme.of(context).textTheme.headline1),
              SizedBox(height: 30),
              WellbeingCheckWidgets(stepValueStream),
            ]))),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor);
  }
}

/// Widgets inside Wellbeing Check page
class WellbeingCheckWidgets extends StatefulWidget {
  final Stream<int> stepValueStream;

  const WellbeingCheckWidgets(this.stepValueStream);

  @override
  _WellbeingCheckWidgetsState createState() => _WellbeingCheckWidgetsState();
}

class _WellbeingCheckWidgetsState extends State<WellbeingCheckWidgets> {
  /// Sets original slider value to 0.
  double _currentSliderValue = 0;

  /// Widget records the last weeks & current step total. The difference is
  /// the actual step count for the week.
  final Future<int> _lastTotalStepsFuture = SharedPreferences.getInstance()
      .then((prefs) => prefs.getInt(PREV_STEP_COUNT_KEY));

  /// Returns [String] userPostcode stored in shared prefs database
  Future<String> _getPostcode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userPostcode = prefs.getString('postcode');
    return userPostcode;
  }

  /// Returns [String] userSupportCode stored in shared prefs database
  Future<String> _getSupportCode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userSupportCode = prefs.getString('support_code');
    return userSupportCode;
  }

  /// Returns `true` if given [List] is monotonically decreasing.
  bool _isDecreasing(List<dynamic> items) {
    for (int i = 0; i < items.length - 1; ++i) {
      if (items[i] <= items[i + 1]) {
        return false;
      }
    }
    return true;
  }

  /// Nudges user if score drops n times in the last n+1 weeks.
  /// For example, if n == 2 and we have these 3 weeks/scores 8 7 6, the user
  /// will be nudged.
  void _checkWellbeing(final int n) async {
    assert(n >= 1);
    final List<WellbeingItem> items =
        await Provider.of<UserWellbeingDB>(context, listen: false)
            .getLastNWeeks(n + 1);
    if (items.length == n + 1 &&
        _isDecreasing(items.map((item) => item.wellbeingScore).toList())) {
      // if there were enough scores, and they were decreasing
      scheduleNudge();
    }
  }

  /// Gets the actual steps taken accounting for the fact that the user may
  /// have reset their device.
  int _getActualSteps(int total, int prevTotal) =>
      // using the difference between this week's and last week's steps
      prevTotal > total ? total : total - prevTotal;

  @override
  Widget build(BuildContext context) {
    final slider = Slider(
      value: _currentSliderValue,
      min: 0,
      max: 10,
      divisions: 10,
      label: _currentSliderValue
          .round() //slider increments are whole numbers
          .toString(),
      activeColor: Theme.of(context).primaryColor,
      inactiveColor: Color.fromARGB(189, 189, 189, 255), //lighter blue
      onChanged: (double value) {
        setState(() {
          _currentSliderValue = value;
        });
      },
    );

    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      FutureBuilder(
        future: _lastTotalStepsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final int lastTotalSteps = snapshot.data;
            return StreamBuilder(
              stream: widget.stepValueStream,
              builder: (context, streamSnapshot) {
                if (streamSnapshot.hasData) {
                  final currentTotalSteps = streamSnapshot.data;
                  final thisWeeksSteps =
                      _getActualSteps(currentTotalSteps, lastTotalSteps);
                  return Column(
                    children: [
                      Text("Your steps this week:",
                          style: Theme.of(context).textTheme.bodyText1),
                      Text(thisWeeksSteps.toString(),
                          style: TextStyle(
                              fontFamily: 'Rosario',
                              fontSize: 25,
                              color: Theme.of(context).accentColor)),
                      SizedBox(height: 40),
                      Text("How did you feel this week?",
                          style: Theme.of(context).textTheme.bodyText1),
                      Container(child: slider, width: 300.0),
                      SizedBox(height: 10),
                      ElevatedButton(
                          onPressed: () async {
                            final dateString = // get date with fakeable clock
                                clock.now().toIso8601String().substring(0, 10);

                            await Provider.of<UserWellbeingDB>(context,
                                    listen: false)
                                .insertWithData(
                                    date: dateString,
                                    postcode: await _getPostcode(),
                                    wellbeingScore: _currentSliderValue,
                                    numSteps: thisWeeksSteps,
                                    supportCode: await _getSupportCode());
                            SharedPreferences.getInstance().then((value) =>
                                value.setInt(
                                    PREV_STEP_COUNT_KEY, currentTotalSteps));

                            Navigator.pop(context);

                            _checkWellbeing(
                                2); // nudges if scores dropped twice
                          },
                          style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Theme.of(context).primaryColor)),
                          child: const Text('Done',
                              style: TextStyle(fontFamily: 'Rosario')))
                    ],
                  );
                } else if (streamSnapshot.hasError) {
                  print(streamSnapshot.error);
                  return Text('Could not retrieve step count.');
                }
                return LinearProgressIndicator();
              },
            );
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
    ]);
  }
}
