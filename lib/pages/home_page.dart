import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nudge_me/main.dart';
import 'package:nudge_me/model/user_model.dart';
import 'package:nudge_me/shared/wellbeing_circle.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:highlighter_coachmark/highlighter_coachmark.dart';

/// key to retreive [bool] from [SharedPreferences] that is true if the tutorial
/// has been completed
const HOME_TUTORIAL_DONE_KEY = "home_tutorial_done";

class HomePage extends StatefulWidget {
  final Stream<int> stepValueStream;

  const HomePage(this.stepValueStream);

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
      Timer(Duration(milliseconds: 700), () => showCoachMarkWB());
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
    return Text(
      "Welcome",
      style: Theme.of(context).textTheme.headline1,
    );
  }

  Widget _previouScoreHolder(BuildContext ctx) {
    return Container(
      width: double.infinity, // stretches the width
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text("Last Week's Wellbeing Score",
              style: Theme.of(context).textTheme.headline3),
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
                      return Text("Something went wrong.",
                          style: Theme.of(context).textTheme.bodyText1);
                    }
                    return CircularProgressIndicator();
                  }),
            ],
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
              stream: widget.stepValueStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final int currTotalSteps = snapshot.data;
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
            return Text("Error");
          }
          return CircularProgressIndicator();
        });

    final contentColumn = Column(children: [
      Text(
        'Activity',
        style: Theme.of(context).textTheme.headline3,
      ),
      Divider(),
      ListTile(
        leading: Icon(Icons.directions_walk),
        title: Text('This Week\'s Steps',
            style: Theme.of(context).textTheme.subtitle1),
        trailing: pedometer,
      ),
    ]);

    return Container(
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.6),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ]),
        child: contentColumn);
  }

  @override
  Widget build(BuildContext context) {
    final heading = _heading(context);
    final previousScoreHolder = _previouScoreHolder(context);
    final thisWeekHolder = _thisWeekHolder(context);

    return Scaffold(
        body: SafeArea(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.min,
          children: [
            heading,
            Divider(),
            previousScoreHolder,
            Divider(),
            thisWeekHolder,
          ],
        )),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor);
  }
}
