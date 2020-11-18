import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NudgeMe',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainPages(),
    );
  }
}

class MainPages extends StatelessWidget {
  final pageTabs = [
    BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Wellbeing"),
    BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("Emacs >= Vim")),
      bottomNavigationBar: BottomNavigationBar(items: pageTabs),
    );
  }
}
