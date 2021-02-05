import 'package:flutter/foundation.dart';
import 'package:nudge_me/main.dart';
import 'package:nudge_me/notification.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:nudge_me/pages/sharing_page.dart';

const PEDOMETER_CHECK_KEY = "pedometer_check";
const REFRESH_FRIEND_KEY = "refresh_friend_data";

/// inits the [Workmanager] and registers a background task to track steps
/// and refresh friend data
void initBackground() {
  Workmanager.initialize(callbackDispatcher, isInDebugMode: kDebugMode);

  Workmanager.registerPeriodicTask("pedometer_check_task", PEDOMETER_CHECK_KEY,
      frequency: Duration(minutes: 15));
  Workmanager.registerPeriodicTask("refresh_friend_task", REFRESH_FRIEND_KEY,
      frequency: Duration(minutes: 15), initialDelay: Duration(seconds: 10));
}

void callbackDispatcher() {
  Workmanager.executeTask((taskName, inputData) async {
    switch (taskName) {
      case PEDOMETER_CHECK_KEY:
        final prefs = await SharedPreferences.getInstance();
        final pedometerPair = prefs.getStringList(PREV_PEDOMETER_PAIR_KEY);
        assert(pedometerPair.length == 2);
        final prevTotal = int.parse(pedometerPair.first);
        final prevDateTime = DateTime.parse(pedometerPair.last);

        final int currTotal = await Pedometer.stepCountStream.first
            .then((value) => value.steps)
            .catchError((_) => 0);
        if (currTotal > prevTotal || currTotal < prevTotal) {
          // if steps have increased or the device has been rebooted
          prefs.setStringList(PREV_PEDOMETER_PAIR_KEY,
              [currTotal.toString(), DateTime.now().toIso8601String()]);
        } else if (currTotal == prevTotal &&
            DateTime.now().difference(prevDateTime) >= Duration(days: 2)) {
          // if step count hasn't changed in 2 days
          await initNotification(); // needs to be done since outside app
          scheduleNudge();
          prefs.setStringList(PREV_PEDOMETER_PAIR_KEY,
              [currTotal.toString(), DateTime.now().toIso8601String()]);
        }
        break;
      case REFRESH_FRIEND_KEY:
        final bool newData = await getLatest();
        print(newData);
        if (newData) {
          scheduleNewFriendData();
        }
        break;
    }
    return Future.value(true);
  });
}
