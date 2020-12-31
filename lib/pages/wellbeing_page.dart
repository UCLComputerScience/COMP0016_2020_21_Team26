import 'package:flutter/material.dart';
import 'package:nudge_me/shared/wellbeing_graph.dart';

class WellbeingPage extends StatelessWidget {
  // TODO
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Center(
                child: Column(children: [
          Text("Wellbeing / Steps",
              style: TextStyle(
                  fontSize: 36.0,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Rosario')),
          Flexible(
              child: WellbeingGraph(
            animate: true,
          ))
        ]))),
        backgroundColor: Color.fromARGB(255, 251, 249, 255));
  }
}
