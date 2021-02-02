import 'package:flutter/material.dart';

/// [StatelessWidget] that takes displays a circular representation of a score
class WellbeingCircle extends StatelessWidget {
  /// 0 <= score <= 10 that determines how much green to show
  final int _score;

  /// takes an [int] score which could be null
  const WellbeingCircle([this._score]);

  @override
  Widget build(BuildContext context) {
    //substracted 2 from score to allow space for larger gradient
    final double purpleFraction = (_score == null ? 10.0 : _score - 2) / 10.0;
    final double blueStartPoint =
        purpleFraction + 0.4 <= 1 ? purpleFraction + 0.4 : 1;

    final bgCircle = Container(
      width: 160.0,
      height: 160.0,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: const [Colors.purpleAccent, Colors.blueAccent],
            // cumulative points to switch color:
            stops: [purpleFraction, blueStartPoint]),
        shape: BoxShape.circle,
        boxShadow: [
          // shadow effect around the circle
          BoxShadow(
            color: Colors.grey.withOpacity(0.6),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
    );

    return Stack(
      alignment: Alignment.center, // aligns all to center by default
      children: [
        bgCircle,
        Text(_score == null ? "N/A" : _score.toString(),
            style: TextStyle(color: Colors.white, fontSize: 75),
            textDirection: TextDirection.ltr),
      ],
    );
  }
}
