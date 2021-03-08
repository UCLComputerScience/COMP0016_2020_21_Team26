import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nudge_me/model/friends_model.dart';
import 'package:nudge_me/notification.dart';
import 'package:nudge_me/pages/add_friend_page.dart';
import 'package:nudge_me/pages/checkup.dart';
import 'package:nudge_me/pages/home_page.dart';
import 'package:nudge_me/pages/nudge_screen.dart';
import 'package:nudge_me/pages/support_page.dart';
import 'package:nudge_me/pages/testing_page.dart';
import 'package:nudge_me/pages/wellbeing_page.dart';
import 'package:nudge_me/pages/settings_page.dart';
import 'package:pedometer/pedometer.dart';
import 'package:provider/provider.dart';
import 'package:uni_links/uni_links.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';

import 'main.dart';

/// URL of the server running back-end code. This should be changed
/// if the domain has changed.
/// Also ensure 'https' is used since we want to securely send data.
const BASE_URL = "https://comp0016.cyberchris.xyz";

/// defines the index of a page
enum NavBarIndex { wellbeing, home, network, settings, testing }

/// Widget that switches between and displays the currently selected
/// page from the navigation bar.
class MainPages extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MainPagesState();
}

class _MainPagesState extends State<MainPages> {
  List<TabItem> navBarItems;

  /// [int] used to determine the current selected page.
  /// Default selected page is the homepage.
  int _selectedIndex = NavBarIndex.home.index;

  /// A subscription of events. They occur whenever a deeplink is pressed,
  /// but the app is already open.
  StreamSubscription _linksSub;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  /// number of unread wellbeing data
  int _unreadNum;

  /// returns the navigation bar items, depending on whether in production.
  /// NOTE: SHOULD change [NavBarIndex] if changing the order of navBarItems.
  List<TabItem> _getNavBarItems() {
    List<TabItem> items = [
      TabItem(
          icon: Icon(Icons.bar_chart, color: Colors.white), title: "Wellbeing"),
      TabItem(icon: Icon(Icons.home, color: Colors.white), title: "Home"),
      TabItem(icon: Icon(Icons.people, color: Colors.white), title: "Network"),
      TabItem(
          icon: Icon(Icons.settings, color: Colors.white), title: "Settings"),
    ];
    if (!isProduction) {
      items.add(TabItem(
          icon: Icon(Icons.receipt, color: Colors.white), title: "Testing"));
    }
    return items;
  }

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

    navBarItems = _getNavBarItems();
  }

  /// Opens the add friend page with friend details pre filled in,
  /// based on the deeplink.
  void _handleAddFriendDeeplink(Uri uri) {
    final params = uri.queryParameters;
    Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    AddFriendPage(params['identifier'], params['pubKey'])))
        .then((_) => setState(() {
              _selectedIndex = NavBarIndex.network.index;
            }));
  }

  void _updateUnread() {
    Provider.of<FriendDB>(context).getUnreadCount().then((value) {
      if (value != _unreadNum) {
        setState(() {
          _unreadNum = value;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _updateUnread();

    final pages = [
      WellbeingPage(),
      HomePage(Pedometer.stepCountStream.map((event) => event.steps)),
      SupportPage(),
      SettingsPage(),
      TestingPage(),
    ];

    final Map<int, dynamic> badgeMap = _unreadNum == null || _unreadNum == 0
        ? {}
        : {NavBarIndex.network.index: _unreadNum.toString()};

    return Scaffold(
      key: _scaffoldKey,
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: ConvexAppBar.badge(badgeMap,
          style: TabStyle.react,
          items: navBarItems,
          initialActiveIndex: _selectedIndex,
          onTap: _onItemTapped,
          top: -16, // affects size of curve of the app bar
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

  //// Pushes a new screen according to the notification payload,
  //// or changes the selected page.
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

  /// changes to the appropriate page
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
