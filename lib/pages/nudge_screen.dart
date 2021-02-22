import 'package:flutter/material.dart';
import 'package:nudge_me/shared/wellbeing_graph.dart';

class NudgeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Nudge"),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              SizedBox(
                height: 5,
              ),
              Text(
                "Would you like to let your care network how you are? "
                "If yes, click the share button at the bottom of the screen.",
                textAlign: TextAlign.center,
              ),
              Divider(),
              Flexible(child: WellbeingGraph()),
              SizedBox(
                height: 10,
              )
            ],
          ),
        ),
      ),
    );
  }
}
