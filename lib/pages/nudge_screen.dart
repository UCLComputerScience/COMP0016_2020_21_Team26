import 'package:flutter/material.dart';
import 'package:nudge_me/shared/wellbeing_graph.dart';

class NudgeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text("""We noticed some low step counts or scores lately,
              click the share icon to share your scores."""),
            WellbeingGraph(),
            RaisedButton(
              child: Text("Close"),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
      ),
    );
  }
}
