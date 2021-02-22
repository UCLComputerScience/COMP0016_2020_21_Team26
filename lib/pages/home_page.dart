import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nudge_me/main.dart';
import 'package:nudge_me/model/user_model.dart';
import 'package:nudge_me/shared/wellbeing_circle.dart';
import 'package:pedometer/pedometer.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:highlighter_coachmark/highlighter_coachmark.dart';

/// key to retreive [bool] from [SharedPreferences] that is true if the tutorial
/// has been completed
const HOME_TUTORIAL_DONE_KEY = "home_tutorial_done";

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Future<int> _lastTotalStepsFuture = SharedPreferences.getInstance()
      .then((prefs) => prefs.getInt(PREV_STEP_COUNT_KEY));

  GlobalKey _lastWeekWBTutorialKey = GlobalObjectKey("laskweek_wb");
  GlobalKey _stepsTutorialKey = GlobalObjectKey("steps");

  @override
  void initState() {
    super.initState();
    showTutorial();
  }

  void showTutorial() async {
    if (!(await _isHomeTutorialDone())) {
      Timer(Duration(milliseconds: 500), () => showCoachMarkWB());
    }
  }

  Future<bool> _isHomeTutorialDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(HOME_TUTORIAL_DONE_KEY) &&
        prefs.getBool(HOME_TUTORIAL_DONE_KEY);
  }

  ///function to show the first slide of the tutorial, explaining the wellbeing circle
  void showCoachMarkWB() {
    CoachMark coachMarkWB = CoachMark();
    RenderBox target = _lastWeekWBTutorialKey.currentContext.findRenderObject();
    Rect markRect = target.localToGlobal(Offset.zero) & target.size;
    markRect = Rect.fromCircle(
        center: markRect.center, radius: markRect.longestSide * 0.6);
    coachMarkWB.show(
        targetContext: _lastWeekWBTutorialKey.currentContext,
        markRect: markRect,
        children: [
          Center(
              child: Padding(
                  padding: EdgeInsets.fromLTRB(10, 150, 10, 0),
                  child: Text(
                      "This is where you can view \n last week's score.",
                      style: Theme.of(context).textTheme.subtitle2)))
        ],
        duration: Duration(seconds: 8),
        onClose: () {
          Timer(Duration(milliseconds: 100), () => showCoachMarkSteps());
        });
  }

  ///function to show the second slide of the tutorial, explaining the steps counter
  void showCoachMarkSteps() {
    CoachMark coachMarkSteps = CoachMark();
    RenderBox target = _stepsTutorialKey.currentContext.findRenderObject();
    Rect markRect = target.localToGlobal(Offset.zero) & target.size;
    markRect = Rect.fromCircle(
        center: markRect.center, radius: markRect.longestSide * 0.6);
    coachMarkSteps.show(
        targetContext: _stepsTutorialKey.currentContext,
        markRect: markRect,
        children: [
          Center(
              child: Padding(
                  padding: EdgeInsets.fromLTRB(30, 0, 60, 0),
                  child: Text(
                      "This is where you can view your steps so far (we start counting now)",
                      style: Theme.of(context).textTheme.subtitle2)))
        ],
        duration: Duration(seconds: 10),
        onClose: () {
          SharedPreferences.getInstance()
              .then((prefs) => prefs.setBool(HOME_TUTORIAL_DONE_KEY, true));
        });
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
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 200,
                width: 200,
                key: _lastWeekWBTutorialKey,
              ),
              FutureBuilder(
                  future:
                      Provider.of<UserWellbeingDB>(context).getLastNWeeks(1),
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
                          style: Theme.of(context).textTheme.bodyText1);
                    }
                    return CircularProgressIndicator();
                  }),
            ],
          ),

          const SizedBox(
            height: 5.0,
          ),
        ],
      ),
    );
  }

  Widget _thisWeekHolder(BuildContext ctx) {
    final pedometer = FutureBuilder(
        key: _stepsTutorialKey,
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
                  return Text("N/A");
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
            style: Theme.of(context).textTheme.headline3,
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
                  Text("Steps", style: Theme.of(context).textTheme.subtitle1)
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
