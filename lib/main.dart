import 'package:first_time_screen/first_time_screen.dart';
import 'package:flutter/material.dart';
import 'package:nudge_me/pages/intro_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nudge_me/notification.dart';

import 'main_pages.dart';

/// used to push without context
final GlobalKey<NavigatorState> navigatorKey = new GlobalKey();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initializePlatformSpecifics();

  runApp(MyApp());

  scheduleCheckup(Day.Sunday, new Time(12));
  schedulePublish(Day.Monday, new Time(12));
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
