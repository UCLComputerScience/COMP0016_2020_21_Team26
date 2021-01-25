import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

const CHECKUP_PAYLOAD = "checkup";
const PUBLISH_PAYLOAD = "publish";
const NUDGE_PAYLOAD = "nudge";

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Stream of [String] payloads that represents notifications sent to the user.
final StreamController<String> notificationStreamController =
    StreamController();

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
  notificationStreamController.add(payload);
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
    "Weekly Wellbeing Check",
    "Tap to report your wellbeing.",
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

/// cancels old checkup notfification and reschedules with new date and time
/// [int] day should be retrieved using DateTime's day enumeration
Future rescheduleCheckup(int day, Time time) async {
  await flutterLocalNotificationsPlugin.cancel(1);
  scheduleCheckup(day, time);
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
    // not important enough, no need to disturb idle mode:
    androidAllowWhileIdle: false,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    payload: PUBLISH_PAYLOAD,
    // schedule recurring notification on matching day & time
    matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
  );
}

/// cancels old publish notfification and reschedules with new date and time
/// [int] day should be retrieved using DateTime's day enumeration
Future reschedulePublish(int day, Time time) async {
  await flutterLocalNotificationsPlugin.cancel(2);
  schedulePublish(day, time);
}

void scheduleNudge() async {
  await flutterLocalNotificationsPlugin.zonedSchedule(
    3,
    "Nudge",
    "Hey, your score or steps are low, want to share with a friend?",
    tz.TZDateTime.now(tz.local).add(Duration(seconds: 2)),
    _getSpecifics(),
    androidAllowWhileIdle: true,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    payload: NUDGE_PAYLOAD,
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
