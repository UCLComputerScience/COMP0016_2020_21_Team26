import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// key for [SharedPreferences] to check if the user has switched on the
/// alternate step counter
const ALT_STEP_COUNT_KEY = 'using_alt_step_count';

class AltStepSwitch extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AltStepSwitchState();
}

class _AltStepSwitchState extends State<AltStepSwitch> {
  // booleans to check if the device has a step counter, and if
  // if it's currently in use
  Future<_FutureHolder> _futureHolder = Pedometer.hasStepCounter.then((a1) =>
      SharedPreferences.getInstance().then(
          (prefs) => _FutureHolder(a1, prefs.getBool(ALT_STEP_COUNT_KEY))));

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: _futureHolder,
        builder: (ctx, data) {
          if (data.hasData) {
            final _FutureHolder holder = data.data;
            return SwitchTile(disabled: holder.hasStepCounter, initial: holder.isUsing == true,);
          } else if (data.hasError) {
            return Text("Something went wrong.");
          }
          return LinearProgressIndicator();
        },
      );
}

class _FutureHolder {
  final hasStepCounter;
  final isUsing;

  _FutureHolder(this.hasStepCounter, this.isUsing);
}

class SwitchTile extends StatefulWidget {
  final initial, disabled;

  const SwitchTile({Key key, this.disabled, this.initial}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SwitchTileState(initial);
}

class _SwitchTileState extends State<SwitchTile> {
  bool _on;

  _SwitchTileState(this._on);

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text("Experimental Step Counter"),
      secondary: Icon(Icons.run_circle_outlined),
      value: _on,
      onChanged: widget.disabled ? null : _toggleAltCounter,
    );
  }

  void _toggleAltCounter(bool value) async {
    if (value) {
    // TODO: wait for start/stop and change only if succeeded
      Pedometer.startPlatform();
    } else {
      Pedometer.stopPlatform();
    }
    setState(() {
      _on = value;
    });
    await SharedPreferences.getInstance()
        .then((prefs) => prefs.setBool(ALT_STEP_COUNT_KEY, value));
  }
}
