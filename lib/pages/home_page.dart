import 'package:flutter/material.dart';
import 'package:nudge_me/main.dart';
import 'package:nudge_me/model/user_model.dart';
import 'package:nudge_me/shared/wellbeing_circle.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // last wellbeing record
  Future<WellbeingItem> _wellbeingItem = UserWellbeingDB()
      .getLastNWeeks(1)
      .then((value) => value.length > 0 ? value[0] : null);

  final Future<int> _lastTotalStepsFuture = SharedPreferences.getInstance()
      .then((prefs) => prefs.getInt(PREV_STEP_COUNT_KEY));

  @override
  void initState() {
    super.initState();
  }

  Widget _heading(BuildContext ctx) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Text(
        "Welcome",
        style: TextStyle(fontSize: 30),
      ),
    );
  }

  Widget _previouScoreHolder(BuildContext ctx) {
    return Container(
      width: double.infinity, // stretches the width
      child: Card(
        child: Column(
          children: [
            // SizedBox to add some spacing
            const SizedBox(
              height: 5.0,
            ),
            Text("Last Week's Wellbeing Score"),
            const SizedBox(
              height: 10.0,
            ),
            FutureBuilder(
                future: _wellbeingItem,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final WellbeingItem lastWeekItem = snapshot.data;
                    return WellbeingCircle(lastWeekItem == null
                        ? null
                        : lastWeekItem.wellbeingScore.truncate());
                  } else if (snapshot.hasError) {
                    print(snapshot.error);
                    Text("Something went wrong.");
                  }
                  return Text("Loading...");
                }),
            const SizedBox(
              height: 5.0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _thisWeekHolder(BuildContext ctx) {
    final pedometer = FutureBuilder(
        future: _lastTotalStepsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final lastTotalSteps = snapshot.data;
            return StreamBuilder(
              stream: Pedometer.stepCountStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final currTotalSteps = snapshot.data;
                  final actualSteps = (lastTotalSteps > currTotalSteps)
                      ? currTotalSteps
                      : currTotalSteps - lastTotalSteps;
                  return Text(actualSteps.toString());
                } else if (snapshot.hasError) {
                  print(snapshot.error);
                }
                return CircularProgressIndicator();
              },
            );
          } else if (snapshot.hasError) {
            print(snapshot.error);
          }
          return CircularProgressIndicator();
        });

    return Container(
        width: double.infinity,
        child: Card(
            child: Column(children: [
          const SizedBox(
            height: 5.0,
          ),
          Text("This Week's Activity"),
          const SizedBox(
            height: 5.0,
          ),
          Padding(
            padding: EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(Icons.directions_walk_outlined),
                  Text("Steps")
                ]),
                pedometer,
              ],
            ),
          ),
        ])));
  }

  @override
  Widget build(BuildContext context) {
    final heading = _heading(context);
    final previousScoreHolder = _previouScoreHolder(context);
    final thisWeekHolder = _thisWeekHolder(context);

    return Column(
      children: [
        heading,
        previousScoreHolder,
        thisWeekHolder,
      ],
    );
  }
}
