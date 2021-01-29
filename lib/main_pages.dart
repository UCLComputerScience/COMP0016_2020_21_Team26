import 'package:flutter/material.dart';
import 'package:nudge_me/model/user_model.dart';
import 'package:nudge_me/notification.dart';
import 'package:nudge_me/pages/checkup.dart';
import 'package:nudge_me/pages/home_page.dart';
import 'package:nudge_me/pages/nudge_screen.dart';
import 'package:nudge_me/pages/sharing_page.dart';
import 'package:nudge_me/pages/testing_page.dart';
import 'package:nudge_me/pages/wellbeing_page.dart';
import 'package:nudge_me/pages/settings_page.dart';

import 'main.dart';

const BASE_URL = "https://comp0016.cyberchris.xyz";

class MainPages extends StatefulWidget {
  final pages = [
    WellbeingPage(),
    HomePage(),
    SharingPage(),
    SettingsPage(),
    TestingPage(),
  ];

  final navBarItems = [
    BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Wellbeing"),
    BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
    BottomNavigationBarItem(icon: Icon(Icons.people), label: "Friends"),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
    BottomNavigationBarItem(icon: Icon(Icons.receipt), label: "Testing"),
  ];

  @override
  State<StatefulWidget> createState() => _MainPagesState();
}

class _MainPagesState extends State<MainPages> {
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    notificationStreamController.stream.listen(_handleNotification);
  }

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

  @override
  void dispose() {
    notificationStreamController.close(); // frees up resources
    super.dispose();
  }

  //// pushes a new screen according to the notification payload
  void _handleNotification(String payload) async {
    switch (payload) {
      case CHECKUP_PAYLOAD:
        await navigatorKey.currentState.push(MaterialPageRoute(
            builder: (context) => WellbeingCheck(UserWellbeingDB())));
        break;
      case NUDGE_PAYLOAD:
        await navigatorKey.currentState
            .push(MaterialPageRoute(builder: (context) => NudgeScreen()));
        break;
      default:
        print("If this isn't a test, something went wrong.");
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
