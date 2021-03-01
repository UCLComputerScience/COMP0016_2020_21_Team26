import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nudge_me/notification.dart';
import 'package:nudge_me/pages/add_friend_page.dart';
import 'package:nudge_me/pages/checkup.dart';
import 'package:nudge_me/pages/home_page.dart';
import 'package:nudge_me/pages/nudge_screen.dart';
import 'package:nudge_me/pages/sharing_page.dart';
import 'package:nudge_me/pages/testing_page.dart';
import 'package:nudge_me/pages/wellbeing_page.dart';
import 'package:nudge_me/pages/settings_page.dart';
import 'package:pedometer/pedometer.dart';
import 'package:uni_links/uni_links.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';

import 'main.dart';

/// URL of the server running back-end code. This should be changed
/// if the domain has changed.
/// Also ensure 'https' is used since we want to securely send data.
const BASE_URL = "https://comp0016.cyberchris.xyz";

enum NavBarIndex { wellbeing, home, network, settings, testing }

class MainPages extends StatefulWidget {
  // NOTE: SHOULD change [NavBarIndex] if changing this order
  final navBarItems = [
    TabItem(
        icon: Icon(Icons.bar_chart, color: Colors.white), title: "Wellbeing"),
    TabItem(icon: Icon(Icons.home, color: Colors.white), title: "Home"),
    TabItem(icon: Icon(Icons.people, color: Colors.white), title: "Network"),
    TabItem(icon: Icon(Icons.settings, color: Colors.white), title: "Settings"),
    TabItem(icon: Icon(Icons.receipt, color: Colors.white), title: "Testing"),
  ];

  @override
  State<StatefulWidget> createState() => _MainPagesState();
}

class _MainPagesState extends State<MainPages> {
  int _selectedIndex = NavBarIndex.home.index;
  StreamSubscription _linksSub;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    notificationStreamController.stream.listen(_handleNotification);

    // We handle deep links here (and not the Intro Screen or main.dart) since
    // we want the user to have set up the app first.
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // This runs once the screen's layout is complete. There would be an error
      // otherwise.
      if (initialUri != null) {
        _handleAddFriendDeeplink(initialUri);
        initialUri = null;
      }
    });
    _linksSub =
        getUriLinksStream().listen(_handleAddFriendDeeplink, onError: (err) {
      // warn user, maybe create a snackbar?
      print(err);
    });
  }

  void _handleAddFriendDeeplink(Uri uri) {
    final params = uri.queryParameters;
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => AddFriendPage(
                _scaffoldKey.currentState,
                params['identifier'],
                params['pubKey']))).then((_) => setState(() {
          _selectedIndex = NavBarIndex.network.index;
        }));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      WellbeingPage(),
      HomePage(),
      SharingPage(),
      SettingsPage(),
      TestingPage(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: ConvexAppBar(
          style: TabStyle.react,
          items: widget.navBarItems,
          initialActiveIndex: _selectedIndex,
          onTap: _onItemTapped,
          top: -16, // affects size of curve,
          color: Colors.white,
          backgroundColor: Theme.of(context).primaryColor),
    );
  }

  @override
  void dispose() {
    notificationStreamController.close(); // frees up resources
    _linksSub.cancel();
    super.dispose();
  }

  //// pushes a new screen according to the notification payload
  void _handleNotification(String payload) async {
    switch (payload) {
      case CHECKUP_PAYLOAD:
        await navigatorKey.currentState.push(MaterialPageRoute(
            builder: (context) => WellbeingCheck(Pedometer.stepCountStream
                .map((stepCount) => stepCount.steps))));
        break;
      case NUDGE_PAYLOAD:
        await navigatorKey.currentState
            .push(MaterialPageRoute(builder: (context) => NudgeScreen()));
        break;
      case FRIEND_DATA_PAYLOAD:
        setState(() {
          _selectedIndex = NavBarIndex.network.index; // switch to friend tab
        });
        break;
      // TODO: should probably open up the respective goal, could modify the payload
      // format to achieve this
      case NEW_GOAL_PAYLOAD:
        setState(() {
          _selectedIndex = NavBarIndex.network.index;
        });
        break;
      case COMPLETED_GOAL_PAYLOAD:
        setState(() {
          _selectedIndex = NavBarIndex.network.index;
        });
        break;
      default:
        print('If this is not a test, something went wrong.');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
