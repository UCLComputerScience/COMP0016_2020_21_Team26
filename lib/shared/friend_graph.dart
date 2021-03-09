import 'dart:convert';
import 'package:charts_flutter/flutter.dart' as charts;

import 'package:flutter/material.dart';

/// [StatelessWidget] that behaves very similarly to [WellbeingGraph].
/// It mainly parses and interprets the wellbeing data differently. Also there
/// are slight visual differences.

/// NOTE: Members of the user's support network are referred to as 'friends' in the code.
class FriendGraph extends StatelessWidget {
  /// json encoded [String] that can be decoded to get the the data
  final Future<String> friendData;

  final animate;

  const FriendGraph(this.friendData, {this.animate = true});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: friendData,
      builder: (ctx, dat) {
        if (dat.hasData) {
          String data = dat.data;
          if (data == "") {
            return Text("They haven't sent you anything.");
          }
          List<Map<String, dynamic>> decoded = (jsonDecode(data) as List)
              // need to typecast each item
              .map((it) => it as Map<String, dynamic>)
              .toList();
          final seriesList = _getSeriesList(decoded);

          return charts.BarChart(
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
              charts.RangeAnnotation([
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
                  axisId: 'secondaryMeasureAxisId', // for steps axis
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
        } else if (dat.hasError) {
          print(dat.error);
          return Text("Couldn't load graph.");
        }
        return LinearProgressIndicator();
      },
    );
  }

  /// Returns the series that the charting library can use to graph the data
  List<charts.Series<Map, String>> _getSeriesList(
      List<Map<String, dynamic>> json) {
    final scoreSeries = new charts.Series<Map, String>(
      id: 'Score',
      colorFn: (_, __) =>
          charts.ColorUtil.fromDartColor(Color.fromARGB(255, 182, 125, 226)),
      domainFn: (Map item, _) => item['week'].toString(),
      measureFn: (Map item, _) => item['score'],
      data: json,
    );
    final stepSeries = new charts.Series<Map, String>(
      id: 'Steps',
      colorFn: (_, __) =>
          charts.ColorUtil.fromDartColor(Color.fromARGB(255, 0, 74, 173)),
      domainFn: (Map a, _) => a['week'].toString(),
      measureFn: (Map a, _) => a['steps'],
      data: json,
    )..setAttribute(charts.measureAxisIdKey, 'secondaryMeasureAxisId');
    return [scoreSeries, stepSeries];
  }
}
