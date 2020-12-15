import 'package:flutter/material.dart';
import 'package:nudge_me/model/user_model.dart';
import 'package:nudge_me/notification.dart';
import 'package:nudge_me/pages/home_page.dart';
import 'package:nudge_me/pages/publish_screen.dart';
import 'package:nudge_me/pages/settings_page.dart';
import 'package:nudge_me/pages/wellbeing_page.dart';

import 'main.dart';

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
        await navigatorKey.currentState // TODO: change this to checkup
            .push(MaterialPageRoute(builder: (context) => MainPages()));
        break;
      case PUBLISH_PAYLOAD:
        if (!await UserWellbeingDB().empty) {
          // asks to publish if there is at least one wellbeing item saved
          await navigatorKey.currentState
              .push(MaterialPageRoute(builder: (context) => PublishScreen()));
        }
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
