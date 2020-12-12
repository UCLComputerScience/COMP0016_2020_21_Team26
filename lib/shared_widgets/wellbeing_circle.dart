import 'package:flutter/material.dart';

/// [StatelessWidget] that takes displays a circular representation of a score
class WellbeingCircle extends StatelessWidget {
  /// 0 <= score <= 10 that determines how much green to show
  final int _score;

  // TODO: should support an absence of a score
  const WellbeingCircle(this._score);

  @override
  Widget build(BuildContext context) {
    final greenFraction = _score / 10.0;
    final redStartPoint = greenFraction + 0.15 <= 1 ? greenFraction + 0.15 : 1;

    final bgCircle = Container(
      width: 160.0,
      height: 160.0,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: const [Colors.greenAccent, Colors.redAccent],
            // cumulative points to switch color:
            stops: [greenFraction, redStartPoint]),
        shape: BoxShape.circle,
        boxShadow: [
          // shadow effect around the circle
          BoxShadow(
            color: Colors.grey.withOpacity(0.6),
            spreadRadius: 4,
            blurRadius: 7,
          ),
        ],
      ),
    );

    return Stack(
      alignment: Alignment.center, // aligns all to center by default
      children: [
        bgCircle,
        Text(
          _score.toString(),
          style: TextStyle(color: Colors.white, fontSize: 75),
        ),
      ],
    );
  }
}
