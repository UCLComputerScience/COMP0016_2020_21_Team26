import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nudge_me/model/friends_model.dart';
import 'package:nudge_me/model/user_model.dart';
import 'package:nudge_me/notification.dart';
import 'package:nudge_me/pages/add_friend_page.dart';
import 'package:nudge_me/pages/checkup.dart';
import 'package:nudge_me/pages/home_page.dart';
import 'package:nudge_me/pages/nudge_screen.dart';
import 'package:nudge_me/pages/sharing_page.dart';
import 'package:nudge_me/pages/testing_page.dart';
import 'package:nudge_me/pages/wellbeing_page.dart';
import 'package:nudge_me/pages/settings_page.dart';
import 'package:uni_links/uni_links.dart';
import 'package:provider/provider.dart';

import 'main.dart';

/// URL of the server running back-end code. This should be changed
/// if the domain has changed.
/// Also ensure 'https' is used since we want to securely send data.
const BASE_URL = "https://comp0016.cyberchris.xyz";

enum NavBarIndex { wellbeing, home, network, settings, testing }

class MainPages extends StatefulWidget {
  // NOTE: SHOULD change [NavBarIndex] if changing this order
  final navBarItems = [
    BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Wellbeing"),
    BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
    BottomNavigationBarItem(icon: Icon(Icons.people), label: "Network"),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
    BottomNavigationBarItem(icon: Icon(Icons.receipt), label: "Testing"),
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
                FriendDB(),
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
      body: MultiProvider(providers: [
        ChangeNotifierProvider(
          create: (context) => UserWellbeingDB(),
        ),
        ChangeNotifierProvider(
          create: (context) => FriendDB(),
        ),
      ], child: SafeArea(child: pages[_selectedIndex])),
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
    _linksSub.cancel();
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
      case FRIEND_DATA_PAYLOAD:
        setState(() {
          _selectedIndex = NavBarIndex.network.index; // switch to friend tab
        });
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
