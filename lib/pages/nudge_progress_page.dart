import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nudge_me/model/friends_model.dart';
import 'package:pedometer/pedometer.dart';
import 'package:provider/provider.dart';

/// Page to track a step goal set by someone in support network
/// Otherwise known as a user nugde.
class NudgeProgressPage extends StatefulWidget {
  final Friend friend; //the friend that set this goal

  const NudgeProgressPage(this.friend);

  @override
  _NudgeProgressPageState createState() => _NudgeProgressPageState();
}

class _NudgeProgressPageState extends State<NudgeProgressPage> {
  ui.Image imageMarker;

  @override
  void initState() {
    super.initState();
    rootBundle.load("lib/images/StepProgressMarker.png").then(
        (value) => ui.decodeImageFromList(value.buffer.asUint8List(), (result) {
              setState(() {
                imageMarker = result;
              });
            }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Step Goal Progress"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
              "${widget.friend.name} set you a goal of ${widget.friend.currentStepsGoal} steps"),
          StreamBuilder(
            stream: Pedometer.stepCountStream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final StepCount sc = snapshot.data;
                final curr = sc.steps;

                int actual;
                if (curr < widget.friend.initialStepCount) {
                  Provider.of<FriendDB>(context)
                      .updateInitialStepCount(widget.friend.identifier, 0);
                  actual = curr;
                } else {
                  actual = curr - widget.friend.initialStepCount;
                }
                if (actual >= widget.friend.currentStepsGoal) {
                  Navigator.pop(context);
                }

                final progress = (actual / widget.friend.currentStepsGoal);
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                          "$actual/${widget.friend.currentStepsGoal} steps completed"),
                      SizedBox(
                        height: 20,
                      ),
                      imageMarker == null
                          ? Container()
                          : Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 300,
                                  height: 300,
                                  child: CustomPaint(
                                    painter:
                                        StepGoalPainter(progress, imageMarker),
                                  ),
                                ),
                                Text(
                                  "${(progress * 100).truncate()}%",
                                  style: Theme.of(context).textTheme.headline1,
                                ),
                              ],
                            )
                    ],
                  ),
                );
              } else if (snapshot.hasError) {
                return Text("Couldn't retrieve step counter.");
              }
              return LinearProgressIndicator();
            },
          ),
        ],
      ),
    );
  }
}

/// Painter that draws a circular representation of the completed fraction.
/// Needs to be given a finite size.
class StepGoalPainter extends CustomPainter {
  /// fraction of the goal completed
  final double completed;

  /// image used to mark the end of the completed bar
  final ui.Image marker;

  StepGoalPainter(this.completed, this.marker);

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    assert(size.isFinite); // we want a finite canvas
    assert(!completed.isNaN);

    Offset center = size.center(Offset.zero);
    final fraction = completed.clamp(0, 1);
    // radius of the arc:
    final radius = size.shortestSide / 2;
    final innerRadius = radius * 0.8;

    final outerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.grey.shade200;
    final innerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.purpleAccent;
    final midPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    // draw the circular ring
    canvas.drawCircle(center, radius, outerPaint);
    canvas.drawArc(
        Rect.fromCenter(center: center, width: size.width, height: size.height),
        0.75 * 2 * pi,
        -fraction * 2 * pi,
        true,
        innerPaint);
    canvas.drawCircle(center, innerRadius, midPaint);

    final target = 0.15;
    final c = (target * size.width) / marker.width;
    final midRadius = (radius + innerRadius) / 2;

    // values to translate by, to get image onto the middle stripe
    double x, y;
    if (completed <= 0.25) {
      // four quadrants
      final theta = completed * 2 * pi;
      x = -midRadius * sin(theta);
      y = -midRadius * cos(theta);
    } else if (completed <= 0.5) {
      final theta = completed * 2 * pi - 0.25 * 2 * pi;
      x = -midRadius * cos(theta);
      y = midRadius * sin(theta);
    } else if (completed <= 0.75) {
      final theta = completed * 2 * pi - 0.5 * 2 * pi;
      x = midRadius * sin(theta);
      y = midRadius * cos(theta);
    } else {
      final theta = completed * 2 * pi - 0.75 * 2 * pi;
      x = midRadius * cos(theta);
      y = -midRadius * sin(theta);
    }

    final imageOffset = center
            .scale(1 / c, 1 / c)
            .translate(-marker.width / 2, -marker.height / 2) +
        Offset(x, y).scale(1 / c, 1 / c);

    canvas.scale(c);
    canvas.translate(
        imageOffset.dx + marker.width / 2, imageOffset.dy + marker.height / 2);
    canvas.rotate(-2 * completed * pi);
    canvas.translate(-imageOffset.dx - marker.width / 2,
        -imageOffset.dy - marker.height / 2);
    canvas.drawImage(marker, imageOffset, Paint());
  }

  @override
  bool shouldRepaint(StepGoalPainter oldDelegate) =>
      completed != oldDelegate.completed || marker != oldDelegate.marker;
}
