import 'dart:convert';
import 'dart:core';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nudge_me/model/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:nudge_me/shared_widgets/wellbeing_graph.dart';

const BASE_URL = "http://178.79.172.202:8080/androidData";

class PublishScreen extends StatefulWidget {
  @override
  _PublishScreenState createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  Future<List<WellbeingItem>> _singleton;

  @override
  void initState() {
    super.initState();
    _singleton = UserWellbeingDB().getLastNWeeks(1);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10.0, bottom: 25.0),
          child: Text("Publish Data?", style: TextStyle(fontSize: 35.0)),
        ),
        FutureBuilder(
            future: _singleton,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                WellbeingItem item = snapshot.data[0];
                return Column(
                  children: [
                    Text("Wellbeing Score: ${item.wellbeingScore.truncate()}"),
                    Text("Number of Steps: ${item.numSteps}")
                  ],
                );
              } else if (snapshot.hasError) {
                return Text("Error: ${snapshot.error}");
              }
              return SizedBox(
                child: CircularProgressIndicator(),
                width: 60,
                height: 60,
              );
            }),
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RaisedButton(
                  child: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
              RaisedButton(
                  child: Icon(Icons.check),
                  onPressed: () {
                    _publishData(context);
                    Navigator.pop(context);
                  })
            ],
          ),
        ),
        Text("Your data will be sent anonymously.",
            style: TextStyle(fontSize: 10.0)),
      ],
    );
  }

  /// Lies 30% of the time. Okay technically it lies 3/10 * 10/11 = 3/11 of the
  /// time since there's a chance it could just pick the true score anyway
  int anonymizeScore(double score) {
    final random = Random();
    return (random.nextInt(100) > 69) ? random.nextInt(11) : score.truncate();
  }

  void _publishData(BuildContext context) async {
    final snackBar = SnackBar(
      content: Text("Sending data"),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    final items = await _singleton;
    final item = items[0];
    final int anonScore = anonymizeScore(item.wellbeingScore);
    // int1/int2 is a double in dart
    final double normalizedSteps =
        (item.numSteps / RECOMMENDED_STEPS_IN_WEEK) * 10.0;
    final double errorRate = (normalizedSteps > anonScore)
        ? normalizedSteps - anonScore
        : anonScore - normalizedSteps;

    final body = jsonEncode({
      /*
      TODO: improve the API, it shouldn't need weeklyCalls anymore. And
            and it prob doesn't need everything as a string.
       */
      "postCode": item.postcode,
      "wellbeingScore": anonScore.toString(),
      "weeklySteps": item.numSteps.toString(),
      "weeklyCalls": "0",
      "errorRate": errorRate.truncate().toString(),
      "supportCode": item.supportCode,
      "date": item.date,
    });

    http
        .post(BASE_URL,
            headers: {"Content-Type": "application/json;charset=UTF-8"},
            body: body)
        .then((response) {
      print("Reponse status: ${response.statusCode}");
      print("Reponse body: ${response.body}");
      final asJson = jsonDecode(response.body);
      if (!asJson['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
            // HACK: this sometimes throws an exception because it is used async
            //       and the scaffold might not exist anymore or something?
            //       (This is unrelated to the actual POST failure)
            SnackBar(content: Text("Oops. Something went wrong.")));
      }
    });
  }
}
