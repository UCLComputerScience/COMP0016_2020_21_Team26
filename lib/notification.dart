import 'package:flutter_local_notifications/flutter_local_notifications.dart';

//notification
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

initializePlatformSpecifics() {
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
  var initialisationSettings = InitializationSettings(
      initializationSettingsAndroid, initializationSettingsIOS);
}

_requestIOSPermission() {
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
