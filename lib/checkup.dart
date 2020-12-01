import 'package:flutter/material.dart';
//import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//import 'package:fit_kit/fit_kit.dart';

class Checkup extends StatelessWidget {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Checkup",
      home: Scaffold(
          appBar: AppBar(title: const Text("Checkup")),
          body: Column(children: <Widget>[
            Text("How do you feel right now?"),
            MyStatefulWidget(),
            Spacer(),
            Text("Your steps this week:"),
            //Text(readStepCount().toString())
          ])),
    );
  }
}

class MyStatefulWidget extends StatefulWidget {
  MyStatefulWidget({Key key}) : super(key: key);

  @override
  _MyStatefulWidgetState createState() => _MyStatefulWidgetState();
}

/// This is the private State class that goes with MyStatefulWidget.
class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  double _currentSliderValue = 0;
  double _weeklyWBScore = 0;

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: _currentSliderValue,
      min: 0,
      max: 10,
      divisions: 1,
      label: _currentSliderValue.toString(),
      onChanged: (double value) {
        setState(() {
          _currentSliderValue = value;
          _weeklyWBScore = value;
        });
      },
    );
  }
}
/*
Future<num> readStepCount() async {
  if (await FitKit.requestPermissions(DataType.values)) {
    List<FitData> stepCount = await FitKit.read(
      DataType.STEP_COUNT,
      dateFrom: DateTime.now().subtract(Duration(days: 7)),
      dateTo: DateTime.now(),
    );
    int weekSteps = 0;
    for (FitData day in stepCount) {
      weekSteps += day.value;
    }
    return (weekSteps);
  }
}


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
  var thisSundayAtTwelve = new DateTime(2020, 11, 22, 12);
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

*/
