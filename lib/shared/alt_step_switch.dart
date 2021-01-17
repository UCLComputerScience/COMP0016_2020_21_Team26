import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nudge_me/pages/intro_screen.dart';

/// key for [SharedPreferences] to check if the user has switched on the
/// alternate step counter.
///
/// It may not be set in prefs, so be aware that the value in prefs
/// could be null.
const ALT_STEP_COUNT_KEY = 'using_alt_step_count';

class AltStepSwitch extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AltStepSwitchState();
}

class _AltStepSwitchState extends State<AltStepSwitch> {
  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: SharedPreferences.getInstance(),
        builder: (ctx, data) {
          if (data.hasData) {
            final SharedPreferences prefs = data.data;
            final hasStepCounter = prefs.getBool(HAS_STEP_COUNTER_KEY);
            final isUsingAlt = prefs.getBool(ALT_STEP_COUNT_KEY) == true;

            return SwitchTile(
              disabled: hasStepCounter,
              initial: isUsingAlt == true,
            );
          } else if (data.hasError) {
            return Text("Something went wrong.");
          }
          return LinearProgressIndicator();
        },
      );
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
    // TODO: don't rely on prefs to detemine service running.
    //       Some devices don't reset SharedPreferences on reinstall so
    //       it will think the service is running even though it's not.
  }
}
