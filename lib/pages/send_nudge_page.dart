import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nudge_me/main_pages.dart';
import 'package:nudge_me/model/friends_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import 'package:http/http.dart' as http;
import 'package:nudge_me/crypto.dart';

class SendNudgePage extends StatelessWidget {
  final Friend friend;
  final ScaffoldState scaffoldState;

  const SendNudgePage(this.friend, this.scaffoldState);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Nudge ${friend.name} to walk"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // maybe use ParagraphBuilder?
            Padding(
                padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: Text(
                  "Set a step goal for ${friend.name}.\n\n"
                  "They will be notified and able to track their progress. \n\n"
                  "You will be notified when they meet their goal.",
                  style: Theme.of(context).textTheme.bodyText1,
                  textAlign: TextAlign.center,
                )),
            Padding(
                padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: Text(
                    "Drag the white circle around to increase the number of steps. You cannot set a goal of 0 steps.",
                    style: Theme.of(context).textTheme.bodyText2,
                    textAlign: TextAlign.center)),

            StepSelector(friend, scaffoldState),
          ],
        ),
      ),
    );
  }
}

class StepSelector extends StatefulWidget {
  final Friend friend;
  final ScaffoldState scaffoldState;

  const StepSelector(
    this.friend,
    this.scaffoldState,
  );

  @override
  State<StatefulWidget> createState() => _StepSelectorState();
}

class _StepSelectorState extends State<StepSelector> {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  int _roundedStep(double val) {
    final int v = val.truncate();
    return v - (v % 500);
  }

  @override
  Widget build(BuildContext context) {
    return SleekCircularSlider(
      min: 10,
      max: 70000,
      initialValue: 7000,
      appearance: CircularSliderAppearance(
        size: 200,
      ),
      onChange: (double val) {},
      innerWidget: (double value) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("${_roundedStep(value)} steps"),
            SizedBox(
              height: 3,
            ),
            ElevatedButton(
              onPressed: () {
                final rounded = _roundedStep(value);
                if (rounded > 0) {
                  Navigator.pop(context);
                  _nudgeFriend(rounded);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Cannot set a goal of 0.")));
                }
              },
              child: Text("Send"),
            )
          ],
        );
      },
    );
  }

  Future<Null> _nudgeFriend(int numSteps) async {
    final prefs = await SharedPreferences.getInstance();

    final data = json.encode({'type': 'nudge-new', 'goal': numSteps});
    final body = json.encode({
      'identifier_from': prefs.getString(USER_IDENTIFIER_KEY),
      'password': prefs.getString(USER_PASSWORD_KEY),
      'identifier_to': widget.friend.identifier,
      'data': data
    });

    http
        .post(
      BASE_URL + "/user/nudge/new",
      headers: {"Content-Type": "application/json"},
      body: body,
    )
        .then((response) {
      final body = json.decode(response.body);

      if (body['success'] == true) {
        // set the goal active (so the sender cannot send another and overwrite
        // their current goal)
        Provider.of<FriendDB>(context)
            .updateActiveNudge(widget.friend.identifier, true);
        scaffoldMessengerKey.currentState.showSnackBar(
            SnackBar(content: Text("Nudged ${widget.friend.name}.")));
      } else {
        scaffoldMessengerKey.currentState
            .showSnackBar(SnackBar(content: Text("Failed to send nudge.")));
      }
    });
  }
}
