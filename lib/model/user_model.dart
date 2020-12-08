import 'dart:collection';

import 'package:flutter/material.dart';

class UserModel extends ChangeNotifier {
  String _postcodePrefix;
  final List<WellbeingItem> _wellbeingWeeks = [
    // TODO: remove this sample data
    new WellbeingItem(week: 1, numSteps: 20000, score: 6),
    new WellbeingItem(week: 2, numSteps: 51230, score: 7),
    new WellbeingItem(week: 3, numSteps: 69531, score: 8.9),
  ];

  /// gets the week which the data currently being recorded will be associated
  /// with. Not 0-indexed.
  int get currentWeek => _wellbeingWeeks.length+1;

  /// n must be non-negative
  List<WellbeingItem> getLastNWeeks(int n) =>
      List.of(_wellbeingWeeks.reversed.take(n), growable: false);

  void addWellbeingItem(WellbeingItem item) {
    _wellbeingWeeks.add(item);
    notifyListeners();
  }

  String get postcodePrefix => _postcodePrefix;

  set postcodePrefix(String s) {
    _postcodePrefix = s;
    notifyListeners();
  }

  /// Not recommended to use since it seems to copy the entire list.
  UnmodifiableListView<WellbeingItem> get wellbeingWeeks =>
      UnmodifiableListView(_wellbeingWeeks);
}

/// Immutable data item of a week's wellbeing record
@immutable
class WellbeingItem {
  final int week;
  final int numSteps;
  final double score;

  WellbeingItem({
    @required this.week,
    @required this.numSteps,
    @required this.score
  });
}
