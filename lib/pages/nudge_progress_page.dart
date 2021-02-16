import 'package:flutter/material.dart';
import 'package:nudge_me/model/friends_model.dart';
import 'package:pedometer/pedometer.dart';
import 'package:provider/provider.dart';

class NudgeProgressPage extends StatelessWidget {
  final Friend friend;

  const NudgeProgressPage(this.friend);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Pedometer.stepCountStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final curr = snapshot.data;

          int actual;
          if (curr < friend.initialStepCount) {
            Provider.of<FriendDB>(context)
                .updateInitialStepCount(friend.identifier, 0);
            actual = curr;
          } else {
            actual = curr - friend.initialStepCount;
          }

          final progress = (actual / friend.currentStepsGoal) * 100;
          return Text(
              "${progress.truncate()}% completed of your ${friend.initialStepCount} goal.");
        } else if (snapshot.hasError) {
          return Text("Something went wrong.");
        }
        return LinearProgressIndicator();
      },
    );
  }
}
