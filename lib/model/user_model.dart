import 'dart:collection';

import 'package:flutter/material.dart';

class UserModel extends ChangeNotifier {
  String _postcodePrefix;
  final List<WellbeingWeekItem> _wellbeingWeeks = [];

  /// Get the average wellbeingItem for the last n weeks.
  /// n should be positive.
  List<WellbeingItem> getNWeekAverages(int n) {
    // TODO
    assert(n > 0);
    return null;
  }

  /// Not recommended to use since it seems to copy the entire list.
  UnmodifiableListView<WellbeingWeekItem> get wellbeingWeeks =>
      UnmodifiableListView(_wellbeingWeeks);

  String get postcodePrefix => _postcodePrefix;

  set postcodePrefix(String s) {
    _postcodePrefix = s;
    notifyListeners();
  }
}

class WellbeingWeekItem {
  // this loses null-safety, but it's in beta so we may not want to use it
  final List<WellbeingItem> _items = List(7);

  /// returns the maximum day where the wellbeing was set, so if all days are
  /// filled, this should return 7. The 'day' returned is not zero indexed.
  int get maxDaySet => _items.takeWhile((value) => value != null).length;

  WellbeingItem get average {
    var averageSteps = 0.0, averageScore = 0.0, n;
    for (n = 0; n < _items.length && _items[n] != null; ++n) {
      averageScore += _items[n].score;
      averageSteps += _items[n].numSteps;
    }
    return WellbeingItem(averageSteps/n, averageScore/n);
  }

  UnmodifiableListView<WellbeingItem> get wellbeingItems =>
      UnmodifiableListView(_items);

  void setWellbeingItem(WellbeingItem item, int day) {
    _items[day] = item;
  }
}

/// Immutable data item of a wellbeing record
class WellbeingItem {
  final double _numSteps;
  final double _score;

  WellbeingItem(this._numSteps, this._score);

  double get numSteps => _numSteps;
  double get score => _score;
}
