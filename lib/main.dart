import 'package:first_time_screen/first_time_screen.dart';
import 'package:flutter/material.dart';
import 'package:nudge_me/model/user_model.dart';
import 'package:provider/provider.dart';
import 'package:nudge_me/pages/intro_screen.dart';


import 'main_pages.dart';

void main() => runApp(MyApp());

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