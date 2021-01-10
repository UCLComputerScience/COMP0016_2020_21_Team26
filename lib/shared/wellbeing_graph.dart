import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:nudge_me/model/user_model.dart';
import 'package:nudge_me/shared/share_button.dart';

const RECOMMENDED_STEPS_IN_WEEK = 70000;

/// a [StatefulWidget] that displays the last wellbeing items in a graph,
/// along with a share button
class WellbeingGraph extends StatefulWidget {
  final bool animate;

  WellbeingGraph({this.animate});

  @override
  _WellbeingGraphState createState() => _WellbeingGraphState();
}

class _WellbeingGraphState extends State<WellbeingGraph> {
  final GlobalKey _printKey = GlobalKey();
  Future<List<WellbeingItem>> _wellbeingItems;

  @override
  void initState() {
    super.initState();
    _wellbeingItems = UserWellbeingDB().getLastNWeeks(5);
  }

  Widget _getGraph(List<WellbeingItem> items, bool animate) {
    final scoreSeries = new charts.Series<WellbeingItem, int>(
      id: 'Wellbeing Score',
      colorFn: (_, __) => charts.MaterialPalette.purple.shadeDefault,
      domainFn: (WellbeingItem item, _) => item.id,
      measureFn: (WellbeingItem item, _) => item.wellbeingScore,
      data: items,
    )..setAttribute(charts.rendererIdKey, 'customBar');
    final stepSeries = new charts.Series<WellbeingItem, int>(
      // TODO: use a 'flex factor'? This text may go out of bounds:
      id: 'Normalized Steps',
      colorFn: (_, __) => charts.MaterialPalette.cyan.shadeDefault,
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
              children: [graph, ShareButton(_printKey, 'wellbeing-score.pdf')],
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
