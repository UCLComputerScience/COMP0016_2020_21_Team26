import 'dart:async';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:highlighter_coachmark/highlighter_coachmark.dart';
import 'package:nudge_me/model/user_model.dart';
import 'package:nudge_me/shared/share_button.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// an upper bound for the recommended number of steps to walk in a week
const RECOMMENDED_STEPS_IN_WEEK = 70000;

/// key to retreive [bool] from [SharedPreferences] that is true if the tutorial has been completed
const WB_TUTORIAL_DONE_KEY = "wb_tutorial_done";

/// a [StatefulWidget] that displays the last wellbeing items in a graph,
/// along with (optionally) a share button, and (optionally) a tutorial button
///
/// REVIEW: maybe switch to this if have time: https://pub.dev/packages/fl_chart
class WellbeingGraph extends StatefulWidget {
  final bool animate;

  /// true if it should display the share button:
  final bool displayShare;

  /// true if it should display the tutorial button:
  final bool shouldShowTutorial;

  WellbeingGraph(
      {this.animate = true,
      this.displayShare = true,
      this.shouldShowTutorial = true});

  @override
  _WellbeingGraphState createState() => _WellbeingGraphState();
}

class _WellbeingGraphState extends State<WellbeingGraph> {
  /// Keys that let the tutorial functions know which widgets to point to.
  GlobalKey _wbGraphTutorialKey = GlobalObjectKey("wb_graph");
  GlobalKey _wbShareTutorialKey = GlobalObjectKey("wb_share");

  final GlobalKey _printKey =
      GlobalKey(); // used by share button to turn graph into pdf

  @override
  void initState() {
    super.initState();
    showTutorial(10);
  }

  /// Displays the tutorial for [int] seconds (each), if it has not been shown
  /// already
  void showTutorial(int duration) async {
    if (widget.shouldShowTutorial && !(await _isWBTutorialDone())) {
      Timer(Duration(milliseconds: 100), () => showCoachMarkGraph(duration));
    }
  }

  /// Returns whether tutorial should be played.
  Future<bool> _isWBTutorialDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(WB_TUTORIAL_DONE_KEY) &&
        prefs.getBool(WB_TUTORIAL_DONE_KEY);
  }

  /// Style for tutorial text for large widgets. Gives text a white background.
  TextStyle tutorialTextStyle = TextStyle(
      fontSize: 20,
      color: Colors.black,
      fontStyle: FontStyle.italic,
      backgroundColor: Colors.white);

  /// Shows the first slide of the tutorial, explaining the wellbeing
  /// graph. Will be displayed for [int] seconds.
  void showCoachMarkGraph(int duration) {
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
                    "This is where you can find wellbeing data from past weeks.",
                    style: tutorialTextStyle)),
            Padding(
                padding: EdgeInsets.fromLTRB(30, 10.0, 30, 0),
                child: Text(
                    "Wellbeing levels and steps are plotted on the same graph. "
                    "Wellbeing is represented by the purple bars and the "
                    "left axis. Steps are represented by the blue bars and "
                    "the right axis.",
                    style: tutorialTextStyle)),
          ])
        ],
        duration: Duration(seconds: duration),
        onClose: () {
          if (widget.displayShare) {
            Timer(Duration(milliseconds: 100),
                () => showCoachMarkShare(duration));
          }
        });
  }

  /// Shows the second slide of the tutorial, explaining the share
  /// button. Will be displayed for [int] seconds.
  void showCoachMarkShare(int duration) {
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
                    "The share button allows you to save or share your graph as a PDF.",
                    style: Theme.of(context).textTheme.subtitle2))
          ])
        ],
        duration: Duration(seconds: duration),
        onClose: () {
          SharedPreferences.getInstance()
              .then((prefs) => prefs.setBool(WB_TUTORIAL_DONE_KEY, true));
        });
  }

  /// Returns [charts.BarChart] graph widget using the [List] of [WellbeingItem]
  Widget _getGraph(List<WellbeingItem> items, bool animate) {
    // we create the series to convert the data into a format that the charting
    // library can understand
    final scoreSeries = new charts.Series<WellbeingItem, String>(
      id: 'Wellbeing',
      colorFn: (_, __) =>
          charts.ColorUtil.fromDartColor(Theme.of(context).accentColor),
      // we have to convert the id to a string since bar charts expect strings
      // on the x axis
      domainFn: (WellbeingItem item, _) => item.id.toString(),
      measureFn: (WellbeingItem item, _) => item.wellbeingScore,
      data: items,
    );
    final stepSeries = new charts.Series<WellbeingItem, String>(
      id: 'Steps',
      colorFn: (_, __) =>
          charts.ColorUtil.fromDartColor(Theme.of(context).primaryColor),
      domainFn: (WellbeingItem a, _) => a.id.toString(),
      measureFn: (WellbeingItem a, _) => a.numSteps,
      data: items,
    )..setAttribute(charts.measureAxisIdKey, 'secondaryMeasureAxisId');
    // we have only set an attribute on stepSeries to configure how it
    // is displayed
    final seriesList = [scoreSeries, stepSeries];

    return Flexible(
      child: RepaintBoundary(
        // wraps it in a [RepaintBoundary] so we can use .toImage()
        key: _printKey, // this [RepaintBoundary] will be 'printed'/shared
        child: charts.BarChart(
          // feedback from UCL recommended us to use a bar chart
          seriesList,
          animate: animate,
          barGroupingType: charts.BarGroupingType.grouped,
          // 'tick counts' used to match grid lines
          primaryMeasureAxis: charts.NumericAxisSpec(
              tickProviderSpec:
                  charts.BasicNumericTickProviderSpec(desiredTickCount: 3)),
          secondaryMeasureAxis: charts.NumericAxisSpec(
            tickProviderSpec:
                charts.BasicNumericTickProviderSpec(desiredTickCount: 2),
          ),
          behaviors: [
            new charts.SeriesLegend(), // adds labels to colors
            charts.RangeAnnotation(
              [
                // This should force the wellbeing score axis to go up to 10:
                charts.RangeAnnotationSegment(
                  8,
                  10,
                  charts.RangeAnnotationAxisType.measure,
                  color: charts.MaterialPalette.transparent,
                ),
                // this displays the region of steps considered healthy
                charts.RangeAnnotationSegment(
                  7000, // min recommended weekly steps
                  70000, // upper bound recommended weekly steps
                  charts.RangeAnnotationAxisType.measure,
                  color: charts.MaterialPalette.green.makeShades(10)[7],
                  startLabel: "7,000",
                  axisId: 'secondaryMeasureAxisId', // for steps axis
                  labelPosition: charts.AnnotationLabelPosition.margin,
                ),
              ],
            ),

            // using title as the x axis label:
            new charts.ChartTitle('Week',
                behaviorPosition: charts.BehaviorPosition.bottom,
                titleOutsideJustification:
                    charts.OutsideJustification.middleDrawArea),
            new charts.ChartTitle(
              'Wellbeing Scale',
              behaviorPosition: charts.BehaviorPosition.start,
              titleOutsideJustification:
                  charts.OutsideJustification.middleDrawArea,
            ),
            new charts.ChartTitle(
              'Steps Scale',
              behaviorPosition: charts.BehaviorPosition.end,
              titleOutsideJustification:
                  charts.OutsideJustification.middleDrawArea,
            ),

            // zooms onto the data points, without this there may be empty
            // spaces
            new charts.PanAndZoomBehavior(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        // display the last five weeks
        future: Provider.of<UserWellbeingDB>(context).getLastNWeeks(5),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final items = snapshot.data;
            final graph = _getGraph(items, widget.animate);

            final List<Widget> buttons = [];
            if (widget.shouldShowTutorial) {
              buttons.add(Container(
                  child: OutlinedButton(
                      //help button replays tutorial
                      child: Icon(Icons.info_outline,
                          color: Theme.of(context).primaryColor),
                      onPressed: () {
                        showCoachMarkGraph(20);
                      })));
            }
            if (widget.displayShare) {
              buttons.add(Container(
                  key: _wbShareTutorialKey,
                  child: ShareButton(_printKey, 'wellbeing-score.pdf')));
            }

            final children = [
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: buttons),
              Container(key: _wbGraphTutorialKey, child: graph)
            ];

            return Column(
              children: children,
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
