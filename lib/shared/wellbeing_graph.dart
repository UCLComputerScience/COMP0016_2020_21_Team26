import 'dart:async';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:highlighter_coachmark/highlighter_coachmark.dart';
import 'package:nudge_me/model/user_model.dart';
import 'package:nudge_me/shared/share_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

const RECOMMENDED_STEPS_IN_WEEK = 70000;

/// key to retreive [bool] from [SharedPreferences] that is true if the tutorial has been completed
const WB_TUTORIAL_DONE_KEY = "wb_tutorial_done";

/// function that returns whether tutorial should be played
Future<bool> _isTutorialDone() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.containsKey(WB_TUTORIAL_DONE_KEY) ||
      prefs.getBool(WB_TUTORIAL_DONE_KEY);
}

/// a [StatefulWidget] that displays the last wellbeing items in a graph,
/// along with a share button
class WellbeingGraph extends StatefulWidget {
  final bool animate;

  WellbeingGraph({this.animate});

  @override
  _WellbeingGraphState createState() => _WellbeingGraphState();
}

class _WellbeingGraphState extends State<WellbeingGraph> {
  GlobalKey _wbGraphTutorialKey = GlobalObjectKey("wb_graph");
  GlobalKey _wbShareTutorialKey = GlobalObjectKey("wb_share");

  final GlobalKey _printKey = GlobalKey();
  Future<List<WellbeingItem>> _wellbeingItems;

  @override
  void initState() {
    super.initState();
    _wellbeingItems = UserWellbeingDB().getLastNWeeks(5);
    showTutorial();
  }

  void showTutorial() async {
    if (!(await _isTutorialDone())) {
      Timer(Duration(seconds: 1), () => showCoachMarkGraph());
    }
  }

  TextStyle tutorialTextStyle = TextStyle(
      //style for tutorial text for large widgets, requires black background
      fontSize: 20,
      color: Colors.white,
      fontStyle: FontStyle.italic,
      backgroundColor: Colors.black);

  ///function to show the first slide of the tutorial, explaining the wellbeing graph
  void showCoachMarkGraph() {
    CoachMark coachMarkWB = CoachMark();
    RenderBox target = _wbGraphTutorialKey.currentContext.findRenderObject();
    Rect markRect = target.localToGlobal(Offset.zero) & target.size;
    markRect = Rect.fromCircle(
        center: markRect.center, radius: markRect.longestSide * 0.6);
    coachMarkWB.show(
        targetContext: _wbGraphTutorialKey.currentContext,
        markRect: markRect,
        children: [
          Column(mainAxisAlignment: MainAxisAlignment.start, children: [
            Padding(
                padding: EdgeInsets.fromLTRB(30, 160.0, 30, 0),
                child: Text(
                    "This is where you can find checkups from past weeks.",
                    style: tutorialTextStyle)),
            Padding(
                padding: EdgeInsets.fromLTRB(30, 160.0, 30, 0),
                child: Text(
                    "Wellbeing scores and steps are plotted on the same graph, as a purple bar chart and a blue line graph respectively.",
                    style: tutorialTextStyle)),
          ])
        ],
        duration: null,
        onClose: () {
          Timer(Duration(seconds: 1), () => showCoachMarkHealthy());
        });
  }

  ///function to show the second slide of the tutorial, explaining the normalised steps
  void showCoachMarkNormalisation() {
    CoachMark coachMarkNormalisation = CoachMark();
    RenderBox target = _wbGraphTutorialKey.currentContext.findRenderObject();
    Rect markRect = target.localToGlobal(Offset.zero) & target.size;
    markRect = Rect.fromCircle(
        center: markRect.center, radius: markRect.longestSide * 0.6);
    coachMarkNormalisation.show(
        targetContext: _wbGraphTutorialKey.currentContext,
        markRect: markRect,
        children: [
          Column(mainAxisAlignment: MainAxisAlignment.start, children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, 120.0, 80, 0),
              child: Text(
                  "'Normalised Steps' means your steps are shown as a score out of 10, where 0 is 0 steps and 10 is 70,000 steps",
                  style: tutorialTextStyle),
            )
          ])
        ],
        duration: null,
        onClose: () {
          Timer(Duration(seconds: 1), () => showCoachMarkShare());
          SharedPreferences.getInstance()
              .then((prefs) => prefs.setBool(WB_TUTORIAL_DONE_KEY, true));
        });
  }

  ///function to show the third slide of the tutorial, explaining the healthy section
  void showCoachMarkHealthy() {
    CoachMark coachMarkHealthy = CoachMark();
    RenderBox target = _wbGraphTutorialKey.currentContext.findRenderObject();
    Rect markRect = target.localToGlobal(Offset.zero) & target.size;
    markRect = Rect.fromCircle(
        center: markRect.center, radius: markRect.longestSide * 0.6);
    coachMarkHealthy.show(
        targetContext: _wbGraphTutorialKey.currentContext,
        markRect: markRect,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
                padding: EdgeInsets.fromLTRB(30, 160.0, 30, 0),
                child: Text(
                  "The 'healthy' section represents the recommended number of steps per week (close to 70,000).",
                  style: tutorialTextStyle,
                )),
          ])
        ],
        duration: null,
        onClose: () {
          Timer(Duration(seconds: 1), () => showCoachMarkNormalisation());
        });
  }

  ///function to show the fourth slide of the tutorial, explaining the share button
  void showCoachMarkShare() {
    CoachMark coachMarkShare = CoachMark();
    RenderBox target = _wbShareTutorialKey.currentContext.findRenderObject();
    Rect markRect = target.localToGlobal(Offset.zero) & target.size;
    markRect = Rect.fromCircle(
        center: markRect.center, radius: markRect.longestSide * 0.6);
    coachMarkShare.show(
        targetContext: _wbShareTutorialKey.currentContext,
        markRect: markRect,
        children: [
          Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            Padding(
                padding: EdgeInsets.fromLTRB(30, 0, 30, 180.0),
                child: Text(
                    "The share button at the bottom allows you to save or share your graph with friends!",
                    style: Theme.of(context).textTheme.subtitle2))
          ])
        ],
        duration: null,
        onClose: () {
          SharedPreferences.getInstance()
              .then((prefs) => prefs.setBool(WB_TUTORIAL_DONE_KEY, true));
        });
  }

  Widget _getGraph(List<WellbeingItem> items, bool animate) {
    final scoreSeries = new charts.Series<WellbeingItem, int>(
      id: 'Wellbeing Score',
      colorFn: (_, __) =>
          charts.ColorUtil.fromDartColor(Color.fromARGB(255, 182, 125, 226)),
      domainFn: (WellbeingItem item, _) => item.id,
      measureFn: (WellbeingItem item, _) => item.wellbeingScore,
      data: items,
    )..setAttribute(charts.rendererIdKey, 'customBar');
    final stepSeries = new charts.Series<WellbeingItem, int>(
      // TODO: use a 'flex factor'? This text may go out of bounds:
      id: 'Normalized Steps',
      colorFn: (_, __) =>
          charts.ColorUtil.fromDartColor(Color.fromARGB(255, 0, 74, 173)),
      domainFn: (WellbeingItem a, _) => a.id,
      measureFn: // normalize the num of steps
          (WellbeingItem a, _) =>
              (a.numSteps / RECOMMENDED_STEPS_IN_WEEK) * 10.0,
      data: items,
    );
    final seriesList = [scoreSeries, stepSeries];

    return Flexible(
      child: RepaintBoundary(
        // uses [RepaintBoundary] so we have .toImage()
        key: _printKey, // this container will be 'printed'/shared
        child: charts.NumericComboChart(
          seriesList,
          animate: animate,
          defaultRenderer: new charts.LineRendererConfig(),
          customSeriesRenderers: [
            new charts.BarRendererConfig(
                cornerStrategy: const charts.ConstCornerStrategy(25),
                customRendererId: 'customBar')
          ],
          behaviors: [
            new charts.SeriesLegend(), // adds labels to colors
            new charts.RangeAnnotation([
              new charts.RangeAnnotationSegment(
                8, // start score for healthy
                10, // end score for healthy
                charts.RangeAnnotationAxisType.measure,
                endLabel: 'Healthy',
                color: charts.MaterialPalette.gray.shade200,
              ),
            ]),
            // using title as axes label:
            new charts.ChartTitle('Week Number',
                behaviorPosition: charts.BehaviorPosition.bottom,
                titleOutsideJustification:
                    charts.OutsideJustification.middleDrawArea),
            new charts.PanAndZoomBehavior(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _wellbeingItems,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final items = snapshot.data;
            final graph = _getGraph(items, widget.animate);
            return Column(
              children: [
                Container(key: _wbGraphTutorialKey, child: graph),
                Container(
                    key: _wbShareTutorialKey,
                    child: ShareButton(_printKey, 'wellbeing-score.pdf'))
              ],
            );
          } else if (snapshot.hasError) {
            return Text("Error: ${snapshot.error}");
          }
          return SizedBox(
            child: CircularProgressIndicator(),
            width: 60,
            height: 60,
          );
        });
  }
}
