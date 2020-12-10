import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nudge_me/main.dart';
import 'package:nudge_me/main_pages.dart';

const CHECKUP_PAYLOAD = "checkup";
const PUBLISH_PAYLOAD = "publish";

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

initializePlatformSpecifics() async {
  // TODO: change icon
  final initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final initializationSettingsIOS = IOSInitializationSettings(
    // asks for permissions on first time setup
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
    onDidReceiveLocalNotification: (id, title, body, payload) async {
      _selectNotification(payload);
    },
  );
  final initialisationSettings = InitializationSettings(
      initializationSettingsAndroid, initializationSettingsIOS);

  await flutterLocalNotificationsPlugin.initialize(initialisationSettings,
      onSelectNotification: _selectNotification);
}

Future _selectNotification(String payload) async {
  switch (payload) {
    case CHECKUP_PAYLOAD:
      await navigatorKey.currentState // TODO: change these routes
          .push(MaterialPageRoute(builder: (context) => MainPages()));
      break;
    case PUBLISH_PAYLOAD:
      await navigatorKey.currentState
          .push(MaterialPageRoute(builder: (context) => MainPages()));
      break;
    default:
  }
}

NotificationDetails _getSpecifics() {
  final androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'channel id', // TODO: check what these should actually be
    'channel name',
    'channel description',
    //largeIcon: DrawableResourceAndroidBitmap('flutter_devs'),
  );
  final iOSPlatformChannelSpecifics = IOSNotificationDetails();
  return NotificationDetails(
      androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
}

Future scheduleNotification([DateTime scheduledDate]) async {
  await flutterLocalNotificationsPlugin.schedule(
    0,
    "NudgeMe",
    'Test notification for debugging.',
    scheduledDate,
    _getSpecifics(),
  );
}

/// schedule checkup notification that repeats weekly
Future scheduleCheckup(Day day, Time time) async {
  await flutterLocalNotificationsPlugin.showWeeklyAtDayAndTime(
      0,
      "Weekly Checkup",
      "Tap to get your weekly checkup.",
      day,
      time,
      _getSpecifics(),
      payload: CHECKUP_PAYLOAD);
}

/// schedule publish notification that repeats weekly
Future schedulePublish(Day day, Time time) async {
  await flutterLocalNotificationsPlugin.showWeeklyAtDayAndTime(
      1,
      "Publish Score",
      "Tap to review and publish your weekly score anonymously.",
      day,
      time,
      _getSpecifics(),
      payload: PUBLISH_PAYLOAD);
}
