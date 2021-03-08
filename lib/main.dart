import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nudge_me/model/friends_model.dart';
import 'package:nudge_me/model/user_model.dart';
import 'package:nudge_me/pages/intro_screen.dart';
import 'package:pedometer/pedometer.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nudge_me/notification.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uni_links/uni_links.dart';
import 'main_pages.dart';

/// true if app is in production, meant for end users
bool isProduction = false;

/// key to retrieve [bool] that is true if setup is done
const FIRST_TIME_DONE_KEY = "first_time_done";

/// key to retrieve the previous step count total from [SharedPreferences]
const PREV_STEP_COUNT_KEY = "step_count_total";

/// key to retrieve the last time a step was taken (along with timestamp)
const PREV_PEDOMETER_PAIR_KEY = "prev_pedometer_pair";

/// used to push without context
final GlobalKey<NavigatorState> navigatorKey = new GlobalKey();

/// sentry client used for logging errors remotely
final _sentry = SentryClient(SentryOptions(
    dsn:
        'https://b3c6b387b20d47be829e679b3290f99a@o513354.ingest.sentry.io/5615069'));

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  appInit();

  // captures platform/native errors
  FlutterError.onError = (FlutterErrorDetails details) {
    if (isInDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    } else {
      Zone.current.handleUncaughtError(details.exception, details.stack);
    }
  };

  // run app in a special environment to capture errors
  runZonedGuarded(() async {
    runApp(MyApp());
  }, (Object err, StackTrace sTrace) {
    _reportError(err, sTrace);
  });
}

bool get isInDebugMode {
  bool inDebugMode = false;

  // this won't execute if we're in production
  assert(inDebugMode = true);

  return inDebugMode;
}

/// either prints or sends the error to Sentry depending on debug/release mode
Future<void> _reportError(dynamic error, dynamic stackTrace) async {
  // Print the exception to the console.
  print('Caught error: $error');
  if (isInDebugMode) {
    // Print the full stacktrace in debug mode.
    print(stackTrace);
  } else {
    // Send the Exception and Stacktrace to Sentry in Production mode.
    _sentry.captureException(
      error,
      stackTrace: stackTrace,
    );
  }
}

/// returns `true` if setup is not completed
Future<bool> _isFirstTime() async {
  final prefs = await SharedPreferences.getInstance();
  return !prefs.containsKey(FIRST_TIME_DONE_KEY) ||
      !prefs.getBool(FIRST_TIME_DONE_KEY);
}

void appInit() async {
  await _initUniLinks();
  initNotification();

  if (await _isFirstTime()) {
    _setupStepCountTotal();
  }
}

/// The deeplink that opened this app if any. Could be null.
Uri initialUri;

/// set the initialUri if present
Future<Null> _initUniLinks() async {
  try {
    // in case platform fails
    initialUri = await getInitialUri();
  } on FormatException {
    // maybe warn the user here?
  }
}

/// initializes timezone and notification settings
Future initNotification() async {
  tz.initializeTimeZones();
  // app is for UK population, so london timezone should be fine
  tz.setLocalLocation(tz.getLocation("Europe/London"));

  initializePlatformSpecifics(); // init notification settings
}

/// Initialize the 'previous' step count total to the current value.
void _setupStepCountTotal() async {
  final prefs = await SharedPreferences.getInstance();
  final int totalSteps = await Pedometer.stepCountStream.first
      .then((value) => value.steps)
      .catchError((_) => 0);

  if (!prefs.containsKey(PREV_STEP_COUNT_KEY)) {
    prefs.setInt(PREV_STEP_COUNT_KEY, totalSteps);
  }
  if (!prefs.containsKey(PREV_PEDOMETER_PAIR_KEY)) {
    prefs.setStringList(PREV_PEDOMETER_PAIR_KEY,
        // ISO date format allows easier parsing
        [totalSteps.toString(), DateTime.now().toIso8601String()]);
  }
}

/// [StatelessWidget] that is the top level widget for the app.
class MyApp extends StatelessWidget {
  // used to determine if we should open the intro screen
  final Future<bool> _openIntro = _isFirstTime();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

    // provider needs to be above [MaterialApp] so it is persisted through
    // new page routes (e.g. after Navigator.push)
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => UserWellbeingDB(),
        ),
        ChangeNotifierProvider(
          create: (context) => FriendDB(),
        ),
      ],
      child: MaterialApp(
        title: 'NudgeMe',
        theme: ThemeData(
          scaffoldBackgroundColor: Color.fromARGB(255, 251, 249, 255),
          primaryColor: Color.fromARGB(255, 0, 74, 173),
          accentColor: Color.fromARGB(255, 182, 125, 226),
          fontFamily: 'Rosario',
          textTheme: TextTheme(
              headline1: TextStyle(
                  fontSize: 36.0,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Kite_One'),
              headline2: TextStyle(
                fontFamily: 'Rosario',
                fontSize: 25,
              ),
              headline3: TextStyle(fontFamily: 'Rosario', fontSize: 25),
              subtitle1: TextStyle(
                  fontFamily: 'Rosario',
                  fontWeight: FontWeight.w500,
                  fontSize: 20),
              subtitle2: TextStyle(
                  fontFamily: 'Rosario',
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                  fontSize: 20), //for tutorial
              bodyText1: TextStyle(fontFamily: 'Rosario', fontSize: 20),
              bodyText2: TextStyle(fontFamily: 'Rosario', fontSize: 15),
              caption: TextStyle(fontFamily: 'Rosario', fontSize: 12)),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedLabelStyle: TextStyle(
                color: Colors.black, fontFamily: 'Rosario', fontSize: 14.0),
            unselectedLabelStyle: TextStyle(
                color: Colors.black, fontFamily: 'Rosario', fontSize: 14.0),
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.black,
            showUnselectedLabels: true,
          ),
        ),
        home: FutureBuilder(
          future: _openIntro,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return snapshot.data ? IntroScreen() : MainPages();
            } else if (snapshot.hasError) {
              print(snapshot.error);
              return Text("Oops");
            }
            return CircularProgressIndicator();
          },
        ),
        navigatorKey: navigatorKey,
      ),
    );
  }
}
