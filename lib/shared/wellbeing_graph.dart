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
Future<bool> _isWBTutorialDone() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.containsKey(WB_TUTORIAL_DONE_KEY) &&
      prefs.getBool(WB_TUTORIAL_DONE_KEY);
}

/// a [StatefulWidget] that displays the last wellbeing items in a graph,
/// along with a share button
///
/// REVIEW: maybe switch to this if have time: https://pub.dev/packages/fl_chart
class WellbeingGraph extends StatefulWidget {
  final bool animate;

  /// true if it should display the share button:
  final bool displayShare;
  final bool shouldShowTutorial;

  WellbeingGraph(
      {this.animate = true,
      this.displayShare = true,
      this.shouldShowTutorial = true});

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
    if (widget.shouldShowTutorial && !(await _isWBTutorialDone())) {
      Timer(Duration(milliseconds: 100), () => showCoachMarkGraph());
    }
  }

  TextStyle tutorialTextStyle = TextStyle(
      //style for tutorial text for large widgets, requires white background
      fontSize: 20,
      color: Colors.black,
      fontStyle: FontStyle.italic,
      backgroundColor: Colors.white);

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
                    "This is where you can find wellbeing data from past weeks.",
                    style: tutorialTextStyle)),
            Padding(
                padding: EdgeInsets.fromLTRB(30, 10.0, 30, 0),
                child: Text(
                    "Wellbeing scores and steps are plotted on the same graph. Wellbeing are represented by the purple bars and the left axis. Steps are represented by the blue bars and the right axis.",
                    style: tutorialTextStyle)),
          ])
        ],
        duration: Duration(seconds: 5),
        onClose: () {
          Timer(Duration(milliseconds: 100), () => showCoachMarkShare());
        });
  }

  ///function to show the second slide of the tutorial, explaining the share button
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
                    "The share button at the bottom allows you to save or share your graph with your care network!",
                    style: Theme.of(context).textTheme.subtitle2))
          ])
        ],
        duration: Duration(seconds: 3),
        onClose: () {
          SharedPreferences.getInstance()
              .then((prefs) => prefs.setBool(WB_TUTORIAL_DONE_KEY, true));
        });
  }

  Widget _getGraph(List<WellbeingItem> items, bool animate) {
    final scoreSeries = new charts.Series<WellbeingItem, String>(
      id: 'Wellbeing',
      colorFn: (_, __) =>
          charts.ColorUtil.fromDartColor(Theme.of(context).accentColor),
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
    final seriesList = [scoreSeries, stepSeries];

    return Flexible(
      child: RepaintBoundary(
        // uses [RepaintBoundary] so we have .toImage()
        key: _printKey, // this container will be 'printed'/shared
        child: charts.BarChart(
          // feedback from UCL recommended to use bar chart
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
            // This should force the wellbeing score axis to go up to 10:
            charts.RangeAnnotation(
              [
                charts.RangeAnnotationSegment(
                  8,
                  10,
                  charts.RangeAnnotationAxisType.measure,
                  color: charts.MaterialPalette.transparent,
                ),
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
            // using title as axes label:
            new charts.ChartTitle('Past weeks',
                behaviorPosition: charts.BehaviorPosition.bottom,
                titleOutsideJustification:
                    charts.OutsideJustification.middleDrawArea),
            new charts.ChartTitle('Wellbeing Scale',
              behaviorPosition: charts.BehaviorPosition.start,
              titleOutsideJustification: charts.OutsideJustification.middleDrawArea,
            ),
            new charts.ChartTitle('Steps Scale',
              behaviorPosition: charts.BehaviorPosition.end,
              titleOutsideJustification: charts.OutsideJustification.middleDrawArea,
            ),
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
            final children = [
              Container(key: _wbGraphTutorialKey, child: graph)
            ];
            if (widget.displayShare) {
              children.add(Container(
                  key: _wbShareTutorialKey,
                  child: ShareButton(_printKey, 'wellbeing-score.pdf')));
            }

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
