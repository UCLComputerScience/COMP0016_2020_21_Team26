import 'package:flutter/material.dart';
import 'package:nudge_me/pages/intro_screen.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nudge_me/notification.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'main_pages.dart';

/// key to retrieve [bool] that is true if setup is done
const FIRST_TIME_DONE_KEY = "first_time_done";

/// key to retrieve the previous step count total from [SharedPreferences]
const PREV_STEP_COUNT_KEY = "step_count_total";

/// key to retrieve the last time a step was taken (along with timestamp)
const PREV_PEDOMETER_PAIR_KEY = "prev_pedometer_pair";

/// used to push without context
final GlobalKey<NavigatorState> navigatorKey = new GlobalKey();

void main() {
  // needs to be done synchronously
  WidgetsFlutterBinding.ensureInitialized();
  _appInit();

  runApp(MyApp());
}

/// returns `true` if setup is not completed
Future<bool> _isFirstTime() async {
  final prefs = await SharedPreferences.getInstance();
  return !prefs.containsKey(FIRST_TIME_DONE_KEY) ||
      !prefs.getBool(FIRST_TIME_DONE_KEY);
}

void _appInit() async {
  await initNotification();
  if (await _isFirstTime()) {
    _setupStepCountTotal();
  }
}

/// initializes timezone and notification settings
Future initNotification() async {
  tz.initializeTimeZones();
  // app is for UK population, so london timezone should be fine
  tz.setLocalLocation(tz.getLocation("Europe/London"));

  initializePlatformSpecifics(); // init notification settings
}

/// Initialize the 'previous' step count total to the current value.
void _setupStepCountTotal() async {
  final prefs = await SharedPreferences.getInstance();
  final int totalSteps = await Pedometer.stepCountStream.first
      .then((value) => value.steps)
      .catchError((_) => 0);

  if (!prefs.containsKey(PREV_STEP_COUNT_KEY)) {
    prefs.setInt(PREV_STEP_COUNT_KEY, totalSteps);
  }
  if (!prefs.containsKey(PREV_PEDOMETER_PAIR_KEY)) {
    prefs.setStringList(PREV_PEDOMETER_PAIR_KEY,
        // ISO date format allows easier parsing
        [totalSteps.toString(), DateTime.now().toIso8601String()]);
  }
}

class MyApp extends StatelessWidget {
  final Future<bool> _openIntro = _isFirstTime();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NudgeMe',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder(
        future: _openIntro,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return snapshot.data ? IntroScreen() : MainPages();
          } else if (snapshot.hasError) {
            print(snapshot.error);
            return Text("Oops");
          }
          return CircularProgressIndicator();
        },
      ),
      navigatorKey: navigatorKey,
    );
  }
}
