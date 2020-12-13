import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nudge_me/main.dart';
import 'package:nudge_me/main_pages.dart';
import 'package:nudge_me/pages/publish_screen.dart';

import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(initialisationSettings,
      onSelectNotification: _selectNotification);
}

Future _selectNotification(String payload) async {
  switch (payload) {
    case CHECKUP_PAYLOAD:
      await navigatorKey.currentState // TODO: change this to checkup
          .push(MaterialPageRoute(builder: (context) => MainPages()));
      break;
    case PUBLISH_PAYLOAD:
      print("Publishing....");
      await navigatorKey.currentState // FIXME: doesnt work if app closed
          .push(MaterialPageRoute(builder: (context) => PublishScreen()));
      break;
    default:
      print("If this isn't a test, something went wrong.");
  }
}

NotificationDetails _getSpecifics() {
  final androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'NudgeMe_0', // channel id
    'NudgeMe', // channel name
    'NudgeMe notification channel', // channel description
    //largeIcon: DrawableResourceAndroidBitmap('flutter_devs'),
  );
  final iOSPlatformChannelSpecifics = IOSNotificationDetails();
  return NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: iOSPlatformChannelSpecifics,
  );
}

Future scheduleNotification([tz.TZDateTime scheduledDate]) async {
  await flutterLocalNotificationsPlugin.zonedSchedule(0, "NudgeMe",
      'Test notification for debugging.', scheduledDate, _getSpecifics(),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime);
}

/// schedule checkup notification that repeats weekly.
/// [int] day should be retrieved using DateTime's day enumeration
Future scheduleCheckup(int day, Time time) async {
  await flutterLocalNotificationsPlugin.zonedSchedule(
    1,
    "Weekly Checkup",
    "Tap to get your weekly checkup.",
    _nextInstanceOfDayTime(day, time),
    _getSpecifics(),
    androidAllowWhileIdle: true,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    payload: CHECKUP_PAYLOAD,
    // schedule recurring notification on matching day & time
    matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
  );
}

/// schedule publish notification that repeats weekly
/// [int] day should be retrieved using DateTime's day enumeration
Future schedulePublish(int day, Time time) async {
  await flutterLocalNotificationsPlugin.zonedSchedule(
    2,
    "Publish Score",
    "Tap to review and publish your weekly score anonymously.",
    _nextInstanceOfDayTime(day, time),
    _getSpecifics(),
    androidAllowWhileIdle: true,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    payload: PUBLISH_PAYLOAD,
    // schedule recurring notification on matching day & time
    matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
  );
}

tz.TZDateTime _nextInstanceOfDayTime(int weekday, Time time) {
  final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  tz.TZDateTime targetDate = tz.TZDateTime(tz.local, now.year, now.month,
      now.day, time.hour, time.minute, time.second);
  if (targetDate.isBefore(now)) {
    targetDate = targetDate.add(const Duration(days: 1));
  }
  while (targetDate.weekday != weekday) {
    targetDate = targetDate.add(const Duration(days: 1));
  }
  return targetDate;
}
