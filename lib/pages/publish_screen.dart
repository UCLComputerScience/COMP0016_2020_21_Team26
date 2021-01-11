import 'dart:convert';
import 'dart:core';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nudge_me/model/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:nudge_me/shared/wellbeing_graph.dart';

const BASE_URL = "https://comp0016.cyberchris.xyz/add-wellbeing-record";

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
    final content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10.0, bottom: 25.0),
          child: Text("Publish Data?",
              style: Theme.of(context).textTheme.headline1),
        ),
        FutureBuilder(
            future: _singleton,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                WellbeingItem item = snapshot.data[0];
                return Column(
                  children: [
                    Text("Wellbeing Score: ${item.wellbeingScore.truncate()}",
                        style: Theme.of(context).textTheme.bodyText1),
                    SizedBox(height: 10),
                    Text("Number of Steps: ${item.numSteps}",
                        style: Theme.of(context).textTheme.bodyText1)
                  ],
                );
              } else if (snapshot.hasError) {
                return Text("Error: ${snapshot.error}",
                    style: Theme.of(context).textTheme.bodyText1);
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
              ElevatedButton(
                  child: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                          Theme.of(context).primaryColor))),
              Builder(
                // builder provides a context for scaffold
                builder: (context) => ElevatedButton(
                    child: Icon(Icons.check),
                    onPressed: () {
                      _publishData(context);
                      Navigator.pop(context);
                    },
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                            Theme.of(context).primaryColor))),
              ),
            ],
          ),
        ),
        Text("Your data will be sent anonymously.",
            style: Theme.of(context).textTheme.bodyText2),
      ],
    );
    return Scaffold(
        body: SafeArea(child: content),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor);
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
    Scaffold.of(context).showSnackBar(snackBar);

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
      "postCode": item.postcode,
      "wellbeingScore": anonScore,
      "weeklySteps": item.numSteps,
      // TODO: Maybe change error rate to double
      //       & confirm the units.
      "errorRate": errorRate.truncate(),
      "supportCode": item.supportCode,
      "date_sent": item.date,
    });

    print("Sending body $body");
    http
        .post(BASE_URL,
            headers: {"Content-Type": "application/json"}, body: body)
        .then((response) {
      print("Reponse status: ${response.statusCode}");
      print("Reponse body: ${response.body}");
      final asJson = jsonDecode(response.body);
      // could be null:
      if (asJson['success'] != true) {
        Scaffold.of(context).showSnackBar(
            SnackBar(content: Text("Oops. Something went wrong.")));
      }
    });
  }
}
