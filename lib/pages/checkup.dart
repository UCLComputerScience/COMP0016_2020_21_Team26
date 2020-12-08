import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
//import 'package:nudge_me/notification.dart';

class Checkup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Checkup",
      home: Scaffold(
          appBar: AppBar(title: const Text("Checkup")),
          body:
              Column(children: <Widget>[WBSliderWidget(), PedometerWidget()])),
    );
  }
}

//wb scale
class WBSliderWidget extends StatefulWidget {
  WBSliderWidget({Key key}) : super(key: key);

  @override
  _WBSliderWidgetState createState() => _WBSliderWidgetState();
}

/// This is the private State class that goes with MyStatefulWidget.
class _WBSliderWidgetState extends State<WBSliderWidget> {
  double _currentSliderValue = 0;
  double _weeklyWBScore = 0;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text("How do you feel right now?"),
      Slider(
        value: _currentSliderValue,
        min: 0,
        max: 10,
        divisions: 10,
        label: _currentSliderValue.toString(),
        onChanged: (double value) {
          setState(() {
            _currentSliderValue = value;
          });
        },
      ),
      RaisedButton(
          onPressed: () {
            _weeklyWBScore = _currentSliderValue;
          },
          child: const Text('Done'))
    ]);
  }
}

//pedometer
class PedometerWidget extends StatefulWidget {
  @override
  _PedometerWidgetState createState() => _PedometerWidgetState();
}

class _PedometerWidgetState extends State<PedometerWidget> {
  Stream<StepCount> _stepCountStream;
  String _steps = '?';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  void onStepCount(StepCount event) {
    print(event);
    setState(() {
      _steps = event.steps.toString();
    });
  }

  void onStepCountError(error) {
    print('onStepCountError: $error');
    setState(() {
      _steps = 'Step Count not available';
    });
  }

  void initPlatformState() {
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(onStepCount).onError(onStepCountError);

    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [Text("Your steps this week:"), Text(_steps)]);
  }
}
