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
                "Hey! We noticed some low step counts/scores lately, "
                "so we'd recommend sharing your score with your care network.",
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
