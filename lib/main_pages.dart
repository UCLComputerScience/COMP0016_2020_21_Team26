import 'package:flutter/material.dart';
import 'package:nudge_me/pages/home_page.dart';
import 'package:nudge_me/pages/settings_page.dart';
import 'package:nudge_me/pages/wellbeing_page.dart';

class MainPages extends StatefulWidget {
  final pages = [
    WellbeingPage(),
    HomePage(),
    SettingsPage(),
  ];
  final navBarItems = [
    BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Wellbeing"),
    BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
  ];

  @override
  State<StatefulWidget> createState() => MainPagesState();
}

class MainPagesState extends State<MainPages> {
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: widget.pages[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        items: widget.navBarItems,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
