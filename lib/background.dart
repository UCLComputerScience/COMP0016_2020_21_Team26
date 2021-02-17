import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:nudge_me/crypto.dart';
import 'package:nudge_me/main.dart';
import 'package:nudge_me/main_pages.dart';
import 'package:nudge_me/model/friends_model.dart';
import 'package:nudge_me/notification.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:nudge_me/pages/sharing_page.dart';
import 'package:http/http.dart' as http;

const PEDOMETER_CHECK_KEY = "pedometer_check";
const REFRESH_FRIEND_KEY = "refresh_friend_data";
const NUDGE_CHECK_KEY = "nudge_check";

/// inits the [Workmanager] and registers a background task to track steps
/// and refresh friend data
void initBackground() {
  Workmanager.initialize(callbackDispatcher, isInDebugMode: kDebugMode);

  Workmanager.registerPeriodicTask("pedometer_check_task", PEDOMETER_CHECK_KEY,
      frequency: Duration(minutes: 15));
  Workmanager.registerPeriodicTask("refresh_friend_task", REFRESH_FRIEND_KEY,
      frequency: Duration(minutes: 15), initialDelay: Duration(seconds: 10));
  Workmanager.registerPeriodicTask("nudge_check_task", NUDGE_CHECK_KEY,
      frequency: Duration(minutes: 15), initialDelay: Duration(minutes: 1));
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

        if (newData) {
          await initNotification();
          scheduleNewFriendData();
        }
        break;
      case NUDGE_CHECK_KEY:
        checkIfGoalsCompleted();
        refreshNudge(true);
        break;
    }
    return Future.value(true);
  });
}

/// POSTs to the back-end and updates the local DB if needed
Future<Null> refreshNudge(bool shouldInitNotifications) async {
  final prefs = await SharedPreferences.getInstance();
  final body = jsonEncode({
    'identifier': prefs.getString(USER_IDENTIFIER_KEY),
    'password': prefs.getString(USER_PASSWORD_KEY),
  });

  http
      .post(BASE_URL + "/user/nudge",
          headers: {'Content-Type': 'application/json'}, body: body)
      .then((response) async {
    final List<dynamic> messages = jsonDecode(response.body);

    if (messages.length > 0) {
      if (shouldInitNotifications) {
        await initNotification();
      }
      messages.forEach(_handleNudge);
    }
  });
}

/// checks if message is from a known friend, and updates DB, depending on type of
/// nudge, if so
void _handleNudge(dynamic message) async {
  final identifierFrom = message['identifier_from'];

  if (await FriendDB().isIdentifierPresent(identifierFrom)) {
    final data = json.decode(message['data']);
    if (data['type'] == null && data['goal'] == null) {
      return;
    }

    final name = await FriendDB().getName(identifierFrom);

    switch (data['type']) {
      case 'nudge-new': // friend sets you a goal
        final int currStepTotal = await Pedometer.stepCountStream.first
            .then((stepCount) => stepCount.steps)
            .catchError((_) => 0);
        FriendDB()
            .updateGoalFromFriend(identifierFrom, data['goal'], currStepTotal);
        scheduleNudgeNewGoal(name, data['goal']);
        break;
      case 'nudge-completed': // friend has completed your goal
        FriendDB().updateActiveNudge(identifierFrom, false);
        scheduleNudgeFriendCompletedGoal(name, data['goal']);
        break;
      default:
    }
  }
}

void checkIfGoalsCompleted() async {
  final int currStepTotal = await Pedometer.stepCountStream.first
      .then((value) => value.steps)
      .catchError((_) => 0);
  final List<Friend> friends = await FriendDB().getFriends();

  // checking steps goal for every friend who has set us a goal
  for (Friend friend
      in friends.where((element) => element.currentStepsGoal != null)) {
    int actualSteps;
    if (currStepTotal < friend.initialStepCount) {
      // must have rebooted device
      FriendDB().updateInitialStepCount(friend.identifier, 0);
      actualSteps = 0;
    } else {
      actualSteps = currStepTotal - friend.initialStepCount;
    }

    if (actualSteps >= friend.currentStepsGoal) {
      _handleGoalCompleted(friend);
    }
  }
}

void _handleGoalCompleted(Friend friend) async {
  await initNotification();
  await scheduleNudgeCompletedGoal(friend.name, friend.currentStepsGoal);

  // TODO: should probably put API code into a helper file
  final prefs = await SharedPreferences.getInstance();

  final data =
      json.encode({'type': 'nudge-completed', 'goal': friend.currentStepsGoal});
  final body = json.encode({
    'identifier_from': prefs.getString(USER_IDENTIFIER_KEY),
    'password': prefs.getString(USER_PASSWORD_KEY),
    'identifier_to': friend.identifier,
    'data': data
  });

  http
      .post(
    BASE_URL + "/user/nudge/new",
    headers: {"Content-Type": "application/json"},
    body: body,
  )
      .then((response) {
    final body = json.decode(response.body);
    print(body);
  });

  FriendDB().updateGoalFromFriend(friend.identifier, null, null);
}
