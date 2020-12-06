import 'package:flutter/material.dart';
import 'package:nudge_me/shared_widgets/wellbeing_graph.dart';

class WellbeingPage extends StatelessWidget {
  // TODO
  @override
  Widget build(BuildContext context) {
    return Center(
        child: WellbeingGraph(
      animate: true,
    ));
  }
}
