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

  Widget _heading(BuildContext ctx) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Text(
        "Welcome",
        style: TextStyle(fontSize: 30),
      ),
    );
  }

  Widget _previouScoreHolder(BuildContext ctx) {
    return Container(
      width: double.infinity, // stretches the width
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
  }

  Widget _thisWeekHolder(BuildContext ctx) {
    return Container(
        width: double.infinity,
        child: Card(
            child: Column(children: [
          const SizedBox(
            height: 5.0,
          ),
          Text("This Week's Activity"),
          const SizedBox(
            height: 5.0,
          ),
          Padding(
            padding: EdgeInsets.all(12.0),
            child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(Icons.directions_walk_outlined),
                Text("Steps")
              ]),
              Text("?") // TODO: pedometer widget
            ],
          ),),
        ])));
  }

  @override
  Widget build(BuildContext context) {
    final heading = _heading(context);
    final previousScoreHolder = _previouScoreHolder(context);
    final thisWeekHolder = _thisWeekHolder(context);

    return Column(
      children: [
        heading,
        previousScoreHolder,
        thisWeekHolder,
      ],
    );
  }
}
