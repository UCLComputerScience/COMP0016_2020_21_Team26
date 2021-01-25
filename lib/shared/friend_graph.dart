import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nudge_me/model/friends_model.dart';

class FriendGraph extends StatelessWidget {
  final Friend friend;

  const FriendGraph(this.friend);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: FriendDB().getLatestData(friend.identifier),
      builder: (ctx, dat) {
        if (dat.hasData) {
          String data = dat.data;
          if (data == null) {
            return Text("They haven't sent you anything.");
          }
          String decoded = jsonDecode(data);
          // TODO: create graph based on data
        } else if (dat.hasError) {
          return Text(dat.error);
        }
        return CircularProgressIndicator();
    },);
  }
}
