import 'package:first_time_screen/first_time_screen.dart';
import 'package:flutter/material.dart';
import 'package:nudge_me/pages/intro_screen.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nudge_me/notification.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'main_pages.dart';

/// key to retrieve the previous step count total from [SharedPreferences]
const PREV_STEP_COUNT_KEY = "step_count_total";

/// used to push without context
final GlobalKey<NavigatorState> navigatorKey = new GlobalKey();

void main() {
  tz.initializeTimeZones();
  // app is for UK population, so london timezone should be fine
  tz.setLocalLocation(tz.getLocation("Europe/London"));

  WidgetsFlutterBinding.ensureInitialized();
  initializePlatformSpecifics(); // init notification settings
  _setupStepCountTotal();

  runApp(MyApp());

  scheduleCheckup(DateTime.sunday, const Time(12));
  schedulePublish(DateTime.monday, const Time(12));
}

/// Initialize the 'previous' step count total to the current value.
void _setupStepCountTotal() async {
  final prefs = await SharedPreferences.getInstance();

  prefs.setInt(PREV_STEP_COUNT_KEY,
      await Pedometer.stepCountStream.first.then((value) => value.steps));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NudgeMe',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FirstTimeScreen(
        introScreen: MaterialPageRoute(builder: (context) => IntroScreen()),
        landingScreen: MaterialPageRoute(builder: (context) => MainPages()),
      ),
      navigatorKey: navigatorKey,
    );
  }
}
