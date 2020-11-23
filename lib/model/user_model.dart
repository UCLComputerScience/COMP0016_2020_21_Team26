import 'dart:collection';

import 'package:flutter/material.dart';

class UserModel extends ChangeNotifier {
  String _postcodePrefix;
  final List<WellbeingItem> _wellbeingItems = [];

  String get postcodePrefix => _postcodePrefix;

  set postcodePrefix(String s) {
    _postcodePrefix = s;
    notifyListeners();
  }

  UnmodifiableListView<WellbeingItem> get wellbeingItems =>
      UnmodifiableListView(_wellbeingItems);

  void addWellbeingItem(WellbeingItem item) {
    _wellbeingItems.add(item);
    notifyListeners();
  }
}

class WellbeingItem {
  final int _numSteps;
  final int _score;

  WellbeingItem(this._numSteps, this._score);

  int get numSteps => _numSteps;
  int get score => _score;
}
