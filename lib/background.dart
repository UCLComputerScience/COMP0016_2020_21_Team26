import 'dart:convert';
import 'dart:math';

import 'package:cron/cron.dart';
import 'package:flutter/foundation.dart';
import 'package:nudge_me/crypto.dart';
import 'package:nudge_me/main.dart';
import 'package:nudge_me/main_pages.dart';
import 'package:nudge_me/model/friends_model.dart';
import 'package:nudge_me/model/user_model.dart';
import 'package:nudge_me/notification.dart';
import 'package:nudge_me/shared/wellbeing_graph.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:nudge_me/pages/sharing_page.dart';
import 'package:http/http.dart' as http;

const PEDOMETER_CHECK_KEY = "pedometer_check";
const REFRESH_FRIEND_KEY = "refresh_friend_data";
const NUDGE_CHECK_KEY = "nudge_check";

ScheduledTask publishTask;

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
          await scheduleNudge();
          prefs.setStringList(PREV_PEDOMETER_PAIR_KEY,
              [currTotal.toString(), DateTime.now().toIso8601String()]);
        }
        break;
      case REFRESH_FRIEND_KEY:
        final bool newData = await getLatest();

        if (newData) {
          await initNotification();
          await scheduleNewFriendData();
        }
        break;
      case NUDGE_CHECK_KEY:
        await refreshNudge(true);
        await checkIfGoalsCompleted();
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

  await http
      .post(BASE_URL + "/user/nudge",
          headers: {'Content-Type': 'application/json'}, body: body)
      .then((response) async {
    final List<dynamic> messages = jsonDecode(response.body);
    print("User Nudges received: $messages");

    if (messages.length > 0) {
      if (shouldInitNotifications) {
        await initNotification();
      }
      for (dynamic message in messages) {
        await _handleNudge(message);
      }
    }
  });
}

/// checks if message is from a known friend, and updates DB, depending on type of
/// nudge, if so
Future<Null> _handleNudge(dynamic message) async {
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
        await FriendDB()
            .updateGoalFromFriend(identifierFrom, data['goal'], currStepTotal);
        await scheduleNudgeNewGoal(name, data['goal']);
        break;
      case 'nudge-completed': // friend has completed your goal
        await FriendDB().updateActiveNudge(identifierFrom, false);
        await scheduleNudgeFriendCompletedGoal(name, data['goal']);
        break;
      default:
        print("Unknown nudge type.");
        break;
    }
  }
}

Future<Null> checkIfGoalsCompleted() async {
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
      await FriendDB().updateInitialStepCount(friend.identifier, 0);
      actualSteps = 0;
    } else {
      actualSteps = currStepTotal - friend.initialStepCount;
    }

    if (actualSteps >= friend.currentStepsGoal) {
      await _handleGoalCompleted(friend);
    }
  }
}

Future<Null> _handleGoalCompleted(Friend friend) async {
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

  await http
      .post(
    BASE_URL + "/user/nudge/new",
    headers: {"Content-Type": "application/json"},
    body: body,
  )
      .then((response) {
    final body = json.decode(response.body);
    print(body);
  });

  await FriendDB().updateGoalFromFriend(friend.identifier, null, null);
}

void schedulePublish() {
  final day = DateTime.monday;
  final hour = 12;
  final minute = 0;

  // This may help: https://crontab.guru/
  publishTask =
      Cron().schedule(Schedule.parse("$minute $hour * * $day"), () async {
    if (!await UserWellbeingDB().empty) {
      // publish if there is at least one wellbeing item saved
      _publishData();
    }
  });
}

void cancelPublish() {
  publishTask.cancel();
  publishTask = null;
}

void _publishData() async {
  final items = await UserWellbeingDB().getLastNWeeks(1);
  final item = items[0];
  final int anonScore = _anonymizeScore(item.wellbeingScore);
  // int1/int2 is a double in dart
  final double normalizedSteps =
      (item.numSteps / RECOMMENDED_STEPS_IN_WEEK) * 10.0;
  final double errorRate = (normalizedSteps > anonScore)
      ? normalizedSteps - anonScore
      : anonScore - normalizedSteps;

  final body = jsonEncode({
    "postCode": item.postcode,
    "wellbeingScore": anonScore,
    "weeklySteps": item.numSteps,
    // TODO: Maybe change error rate to double
    //       & confirm the units.
    "errorRate": errorRate.truncate(),
    "supportCode": item.supportCode,
    "date_sent": item.date,
  });

  print("Sending body $body");
  http
      .post(BASE_URL + "/add-wellbeing-record",
          headers: {"Content-Type": "application/json"}, body: body)
      .then((response) {
    print("Reponse status: ${response.statusCode}");
    print("Reponse body: ${response.body}");
    final asJson = jsonDecode(response.body);
    // could be null:
    if (asJson['success'] != true) {
      print("Something went wrong.");
    }
  });
}

/// Lies 30% of the time. Okay technically it lies 3/10 * 10/11 = 3/11 of the
/// time since there's a chance it could just pick the true score anyway
int _anonymizeScore(double score) {
  final random = Random();
  return (random.nextInt(100) > 69) ? random.nextInt(11) : score.truncate();
}
