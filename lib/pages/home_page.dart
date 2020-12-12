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
    _wellbeingItem =
        UserWellbeingDB().getLastNWeeks(1).then((value) => value[0]);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text("Welcome"),
          FutureBuilder(
              future: _wellbeingItem,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final WellbeingItem lastWeekItem = snapshot.data;
                  return WellbeingCircle(
                    lastWeekItem.wellbeingScore.truncate(),
                  );
                } else if (snapshot.hasError) {
                  print(snapshot.error);
                  Text("Something went wrong.");
                }
                return Text("Loading...");
              })
        ],
      ),
    );
  }
}
