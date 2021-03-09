import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nudge_me/main.dart';
import 'package:nudge_me/model/user_model.dart';
import 'package:nudge_me/shared/wellbeing_circle.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:highlighter_coachmark/highlighter_coachmark.dart';
import 'package:url_launcher/url_launcher.dart';

/// key to retreive [bool] from [SharedPreferences] that is true if the tutorial
/// has been completed
const HOME_TUTORIAL_DONE_KEY = "home_tutorial_done";

// user manual hosted on our development blog as a static asset, it is hosted
// by Github
const URL_USER_MANUAL =
    'https://uclcomputerscience.github.io/COMP0016_2020_21_Team26/'
    'pdfs/usermanual.pdf';

/// Displays Wellbeing Score from last week
/// and steps so far since the last Wellbeing Check.
class HomePage extends StatefulWidget {
  final Stream<int> stepValueStream;

  const HomePage(this.stepValueStream);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// true if we should display a banner to warn that we cannot access the
  /// pedometer
  bool pedometerWarn = false;

  final Future<int> _lastTotalStepsFuture = SharedPreferences.getInstance()
      .then((prefs) => prefs.getInt(PREV_STEP_COUNT_KEY));

  GlobalKey _lastWeekWBTutorialKey = GlobalObjectKey("laskweek_wb");
  GlobalKey _stepsTutorialKey = GlobalObjectKey("steps");

  @override
  void initState() {
    super.initState();
    showTutorial();
  }

  /// If tutorial has not been shown before, calls the first [CoachMark] of the tutorial (showCoachMarkWB()).
  void showTutorial() async {
    if (!(await _isHomeTutorialDone())) {
      Timer(Duration(milliseconds: 700), () => showCoachMarkWB());
    }
  }

  /// Returns whether tutorial has been shown
  Future<bool> _isHomeTutorialDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(HOME_TUTORIAL_DONE_KEY) &&
        prefs.getBool(HOME_TUTORIAL_DONE_KEY);
  }

  /// Shows the first [CoachMark] of the tutorial, explaining the wellbeing circle.
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

  ///Shows the second [CoachMark] of the tutorial, explaining the steps counter.
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
          //sets HOME_TUTORIAL_DONE_KEY to true in shared prefs database
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

  //Displays Wellbeing circle containing last week's wellbeing score
  Widget _previouScoreHolder(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
      child: Container(
        width: double.infinity, // stretches the width
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text('Last Week\'s Wellbeing Score',
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
      ),
    );
  }

  /// Displays this week's steps so far.
  /// If the pedometer throws an error, sets the pedometerWarn [bool] to true.
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
                  // NOTE: we do not have to worry about using setState here
                  // since whenever it builds it will execute this first and
                  // then the [Visibility] banner widget. Therefore, there is
                  // no case where the pedometer throws an error but no
                  // banner is shown.
                  pedometerWarn = true;
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
        leading: Icon(Icons.directions_walk, color: Colors.blue),
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
    final warningBanner = MaterialBanner(
      leading: Icon(
        Icons.warning,
        color: Colors.red,
      ),
      content:
          const Text('No pedometer available. Functionality will be limited.'),
      actions: [
        TextButton(
          child: Text('Ok'),
          onPressed: () => setState(() => pedometerWarn = false),
        )
      ],
    );
    final appBar = AppBar(
      title: heading,
      centerTitle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      actions: [
        IconButton(
          onPressed: () => launch(URL_USER_MANUAL),
          icon: Icon(Icons.help_outline),
          color: Colors.blue,
        )
      ],
    );

    return Scaffold(
        appBar: appBar,
        body: SafeArea(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.min,
          children: [
            Visibility(
              visible: pedometerWarn == true,
              child: warningBanner,
            ),
            previousScoreHolder,
            thisWeekHolder,
          ],
        )),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor);
  }
}
