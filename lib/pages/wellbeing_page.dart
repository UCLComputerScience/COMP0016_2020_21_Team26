import 'package:flutter/material.dart';
import 'package:nudge_me/shared/wellbeing_graph.dart';

class WellbeingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Center(
                child: Column(children: [
          Text("Wellbeing Diary", style: Theme.of(context).textTheme.headline1),
          Flexible(
              child: WellbeingGraph(
            animate: true,
          ))
        ]))),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor);
  }
}
