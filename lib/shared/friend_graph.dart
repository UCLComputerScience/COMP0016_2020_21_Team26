import 'dart:convert';
import 'package:charts_flutter/flutter.dart' as charts;

import 'package:flutter/material.dart';
import 'package:nudge_me/model/friends_model.dart';

class FriendGraph extends StatelessWidget {
  final Friend friend;
  final animate;

  const FriendGraph(this.friend, {this.animate = true});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: FriendDB().getLatestData(friend.identifier),
      builder: (ctx, dat) {
        if (dat.hasData) {
          String data = dat.data;
          if (data == "") {
            return Text("They haven't sent you anything.");
          }
          final decoded = jsonDecode(data);
          final seriesList = _getSeriesList(decoded);

          return Flexible(
              child: charts.BarChart(
            seriesList,
            animate: animate,
            barGroupingType: charts.BarGroupingType.grouped,
            // 'tick counts' used to match grid lines
            primaryMeasureAxis: charts.NumericAxisSpec(
                tickProviderSpec:
                    charts.BasicNumericTickProviderSpec(desiredTickCount: 3)),
            secondaryMeasureAxis: charts.NumericAxisSpec(
              tickProviderSpec:
                  charts.BasicNumericTickProviderSpec(desiredTickCount: 3),
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
                )
              ]),
              // using title as axes label:
              new charts.ChartTitle('Week Number',
                  behaviorPosition: charts.BehaviorPosition.bottom,
                  titleOutsideJustification:
                      charts.OutsideJustification.middleDrawArea),
              new charts.PanAndZoomBehavior(),
            ],
          ));
        } else if (dat.hasError) {
          return Text(dat.error);
        }
        return CircularProgressIndicator();
      },
    );
  }

  List<dynamic> _getSeriesList(List<Map<String, dynamic>> json) {
    final scoreSeries = new charts.Series<Map, String>(
      id: 'Wellbeing Score',
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
