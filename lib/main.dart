import 'package:first_time_screen/first_time_screen.dart';
import 'package:flutter/material.dart';
import 'package:nudge_me/pages/intro_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nudge_me/notification.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'main_pages.dart';

/// used to push without context
final GlobalKey<NavigatorState> navigatorKey = new GlobalKey();

void main() {
  tz.initializeTimeZones();
  // app is for UK population, so london timezone should be fine
  tz.setLocalLocation(tz.getLocation("Europe/London"));
  WidgetsFlutterBinding.ensureInitialized();
  initializePlatformSpecifics();

  runApp(MyApp());

  scheduleCheckup(DateTime.sunday, const Time(12));
  schedulePublish(DateTime.monday, const Time(12));
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
        loadingScreen: Text("Loading..."),
        introScreen: MaterialPageRoute(builder: (context) => IntroScreen()),
        landingScreen: MaterialPageRoute(builder: (context) => MainPages()),
      ),
      navigatorKey: navigatorKey,
    );
  }
}
