import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//import 'package:flutter/material.dart';
//import 'package:nudge_me/pages/checkup.dart';

//notification
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

initializePlatformSpecifics() async {
  var initializationSettingsAndroid =
      AndroidInitializationSettings('app_notf_icon');
  var initializationSettingsIOS = IOSInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
    onDidReceiveLocalNotification: (id, title, body, payload) async {
      // your call back to the UI
    },
  );
  var initializationSettings = InitializationSettings(
      initializationSettingsAndroid, initializationSettingsIOS);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: selectNotification);
}

Future selectNotification(String payload) async {}
/*if (payload != null) {
      print('notification payload: $payload');
    }
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => Checkup()),
    );*/

_requestIOSPermission() {
  //at some point we need to ask ios  notifications permission using this
  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      .requestPermissions(
        alert: false,
        badge: true,
        sound: true,
      );
}

Future<void> scheduleNotification() async {
  var thisSundayAtTwelve = new DateTime(2020, 12, 8, 14, 40);
  var sundayDiff = thisSundayAtTwelve.difference(new DateTime.now());
  var scheduledNotificationDateTime;
  if (sundayDiff.inDays == 7) {
    scheduledNotificationDateTime = DateTime.now();
  }
  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'channel id',
    'channel name',
    'channel description',
    icon: 'flutter_devs',
    //largeIcon: DrawableResourceAndroidBitmap('flutter_devs'),
  );
  var iOSPlatformChannelSpecifics = IOSNotificationDetails();
  var platformChannelSpecifics = NotificationDetails(
      androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin.schedule(
      0,
      'Hi there',
      'We noticed you’re not feeling so good - what do you think about a short walk down the road?',
      scheduledNotificationDateTime,
      platformChannelSpecifics);
}
