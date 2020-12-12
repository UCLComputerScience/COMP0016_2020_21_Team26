import 'package:flutter/material.dart';
import 'package:nudge_me/model/user_model.dart';
import 'package:nudge_me/shared_widgets/wellbeing_circle.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<WellbeingItem> _wellbeingItem; // last wellbeing record

  @override
  void initState() {
    super.initState();
    _wellbeingItem = UserWellbeingDB()
        .getLastNWeeks(1)
        .then((value) => value.length > 0 ? value[0] : null);
  }

  @override
  Widget build(BuildContext context) {
    final heading = Padding(
      padding: EdgeInsets.all(10),
      child: Text(
        "Welcome",
        style: TextStyle(fontSize: 30),
      ),
    );
    final previousScoreHolder = Container(
      width: double.infinity,
      child: Card(
        child: Column(
          children: [
            // SizedBox to add some spacing
            const SizedBox(
              height: 5.0,
            ),
            Text("Last Week's Wellbeing Score"),
            const SizedBox(
              height: 10.0,
            ),
            FutureBuilder(
                future: _wellbeingItem,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final WellbeingItem lastWeekItem = snapshot.data;
                    return WellbeingCircle(lastWeekItem == null
                        ? null
                        : lastWeekItem.wellbeingScore.truncate());
                  } else if (snapshot.hasError) {
                    print(snapshot.error);
                    Text("Something went wrong.");
                  }
                  return Text("Loading...");
                }),
            const SizedBox(
              height: 5.0,
            ),
          ],
        ),
      ),
    );

    return Column(
      children: [
        heading,
        previousScoreHolder,
      ],
    );
  }
}
