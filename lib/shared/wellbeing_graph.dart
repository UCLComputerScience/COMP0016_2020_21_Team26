import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:nudge_me/model/user_model.dart';

const RECOMMENDED_STEPS_IN_WEEK = 70000;

class WellbeingGraph extends StatefulWidget {
  final bool animate;

  WellbeingGraph({this.animate});

  @override
  _WellbeingGraphState createState() => _WellbeingGraphState();
}

class _WellbeingGraphState extends State<WellbeingGraph> {
  Future<List<WellbeingItem>> _wellbeingItems;

  @override
  void initState() {
    super.initState();
    _wellbeingItems = UserWellbeingDB().getLastNWeeks(5);
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

    return new charts.NumericComboChart(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _wellbeingItems,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final items = snapshot.data;
            return _getGraph(items, widget.animate);
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
