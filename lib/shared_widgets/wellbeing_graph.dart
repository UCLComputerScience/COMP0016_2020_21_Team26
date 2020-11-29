import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:nudge_me/model/user_model.dart';
import 'package:provider/provider.dart';

class WellbeingGraph extends StatelessWidget {
  final bool animate;

  WellbeingGraph({this.animate});

  @override
  Widget build(BuildContext context) {
    const RECOMMENDED_STEPS_IN_WEEK = 70000;
    // this may not be the idiomatic way of getting the data:
    final items = Provider.of<UserModel>(context, listen: true).getLastNWeeks(5);

    final scoreSeries = new charts.Series<WellbeingItem, int>(
      id: 'Wellbeing Score',
      colorFn: (_, __) => charts.MaterialPalette.purple.shadeDefault,
      domainFn: (WellbeingItem item, _) => item.week,
      measureFn: (WellbeingItem item, _) => item.score,
      data: items,
    )..setAttribute(charts.rendererIdKey, 'customBar');
    final stepSeries = new charts.Series<WellbeingItem, int>(
      // TODO: use a 'flex factor'? This text may go out of bounds:
      id: 'Normalized Steps',
      colorFn: (_, __) => charts.MaterialPalette.cyan.shadeDefault,
      domainFn: (WellbeingItem a, _) => a.week,
      measureFn: // normalize the num of steps
          (WellbeingItem a, _) => (a.numSteps/RECOMMENDED_STEPS_IN_WEEK)*10.0,
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
          customRendererId: 'customBar'
        )
      ],
      behaviors: [
        new charts.SeriesLegend(), // adds labels to colors
        new charts.RangeAnnotation([
          new charts.RangeAnnotationSegment(
            8, 10, charts.RangeAnnotationAxisType.measure, endLabel: 'Healthy',
            color: charts.MaterialPalette.gray.shade200,
          ),
        ]),
        // using title as axes label:
        new charts.ChartTitle('Week Number',
          behaviorPosition: charts.BehaviorPosition.bottom,
          titleOutsideJustification: charts.OutsideJustification.middleDrawArea
        ),
      ],
    );
  }
}