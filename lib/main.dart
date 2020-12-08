import 'package:flutter/material.dart';

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
      home: SafeArea(
          // so the app isn't obscured by notification bar
          child: MainPages()),
    );
  }
}
