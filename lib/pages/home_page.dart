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
  Future<List<WellbeingItem>> _lastItemListFuture =
      UserWellbeingDB().getLastNWeeks(1);

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
        style: Theme.of(context).textTheme.headline1,
      ),
    );
  }

  Widget _previouScoreHolder(BuildContext ctx) {
    return Container(
      width: double.infinity, // stretches the width
      child: Column(
        children: [
          // SizedBox to add some spacing
          const SizedBox(
            height: 5.0,
          ),
          Text("Last Week's Wellbeing Score",
              style: Theme.of(context).textTheme.headline3),
          const SizedBox(
            height: 10.0,
          ),
          FutureBuilder(
              future: _lastItemListFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final List<WellbeingItem> lastItemList = snapshot.data;
                  return lastItemList.isNotEmpty
                      ? WellbeingCircle(
                          lastItemList[0].wellbeingScore.truncate())
                      : WellbeingCircle();
                } else if (snapshot.hasError) {
                  print(snapshot.error);
                  Text("Something went wrong.",
                      style: Theme.of(context).textTheme.bodyText2);
                }
                return CircularProgressIndicator();
              }),
          const SizedBox(
            height: 5.0,
          ),
        ],
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
                  final StepCount stepCount = snapshot.data;
                  final int currTotalSteps = stepCount.steps;
                  final actualSteps = lastTotalSteps > currTotalSteps
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
        child: Column(children: [
          const SizedBox(
            height: 5.0,
          ),
          Text(
            "This Week's Activity",
            style: Theme.of(context).textTheme.bodyText1,
          ),
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
                  Text("Steps", style: Theme.of(context).textTheme.bodyText1)
                ]),
                pedometer,
              ],
            ),
          ),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    final heading = _heading(context);
    final previousScoreHolder = _previouScoreHolder(context);
    final thisWeekHolder = _thisWeekHolder(context);

    return Scaffold(
        body: SafeArea(
            child: Column(
          children: [
            heading,
            SizedBox(height: 20),
            previousScoreHolder,
            SizedBox(height: 30),
            thisWeekHolder,
          ],
        )),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor);
  }
}
