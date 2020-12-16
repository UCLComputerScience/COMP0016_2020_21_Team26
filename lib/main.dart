import 'package:first_time_screen/first_time_screen.dart';
import 'package:flutter/material.dart';
import 'package:nudge_me/pages/intro_screen.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main_pages.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _setupStepCountTotal();
  runApp(MyApp());
}

const STEP_COUNT_TOTAL_KEY = "step_count_total";

void _setupStepCountTotal() async {
  final prefs = await SharedPreferences.getInstance();

  prefs.setInt(STEP_COUNT_TOTAL_KEY,
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
        loadingScreen: Text("Loading..."),
        introScreen: MaterialPageRoute(builder: (context) => IntroScreen()),
        landingScreen: MaterialPageRoute(builder: (context) => MainPages()),
      ),
    );
  }
}
