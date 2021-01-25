import 'dart:convert';

import 'package:encrypt/encrypt.dart';
import 'package:flutter/material.dart';
import 'package:nudge_me/crypto.dart';
import 'package:nudge_me/model/friends_model.dart';
import 'package:nudge_me/pages/add_friend_page.dart';
import 'package:nudge_me/pages/publish_screen.dart';
import 'package:nudge_me/shared/friend_graph.dart';
import 'package:nudge_me/shared/wellbeing_graph.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SharingPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => SharingPageState();
}

class SharingPageState extends State<SharingPage> {
  Future<List<Friend>> _futureFriends = FriendDB().getFriends();

  @override
  Widget build(BuildContext context) {
    final showKeyButton = ElevatedButton(
      onPressed: () => showDialog(
          builder: (context) => AlertDialog(
                title: Text("My Details"),
                content: FutureBuilder(
                  future: SharedPreferences.getInstance(),
                  builder: (context, data) {
                    if (data.hasData) {
                      final SharedPreferences prefs = data.data;
                      return ListView(
                        children: [
                          Text(prefs.getString(USER_IDENTIFIER_KEY)),
                          SelectableText(prefs.getString(RSA_PUBLIC_PEM_KEY)),
                        ],
                      );
                    }
                    return LinearProgressIndicator();
                  },
                ),
                actions: [
                  TextButton(
                    child: Text('Done'),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
          context: context),
      child: Text("Show Key"),
    );
    final addFriendButton = ElevatedButton(
      onPressed: () {
        Navigator.push(
                context, MaterialPageRoute(builder: (ctx) => AddFriendPage()))
            .then((v) => setState(() {
                  // HACK: this forces the page to rebuild since the user prob
                  //       just added a new friend
                  _futureFriends = FriendDB().getFriends();
                }));
      },
      child: Text("Add Friend"),
    );
    // TODO: use this https://pub.dev/packages/pull_to_refresh
    final refreshButton = ElevatedButton(
      onPressed: _getLatest,
      child: Text("Refresh"),
    );
    final friendsList = FutureBuilder(
      future: _futureFriends,
      builder: (ctx, data) {
        if (data.hasData) {
          final List<Friend> friends = data.data;
          return ListView.builder(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: friends.length,
            itemBuilder: (ctx, i) => FriendListItem(friends[i]),
          );
        }
        return CircularProgressIndicator();
      },
    );

    return Scaffold(
      body: Column(
        children: [
          showKeyButton,
          addFriendButton,
          refreshButton,
          friendsList,
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  /// get the latest messages for this user
  Future<void> _getLatest() async {
    final prefs = await SharedPreferences.getInstance();
    final body = jsonEncode({
      "identifier": prefs.getString(USER_IDENTIFIER_KEY),
      "password": prefs.getString(USER_PASSWORD_KEY),
    });

    http
        .post(BASE_URL + "/user/message",
            headers: {"Content-Type": "application/json"}, body: body)
        .then((response) {
      final List messages = jsonDecode(response.body);
      print("Recieved: $messages");

      final pubKey = RSAKeyParser().parse(prefs.getString(RSA_PUBLIC_PEM_KEY))
          as RSAPublicKey;
      final privKey = RSAKeyParser().parse(prefs.getString(RSA_PRIVATE_PEM_KEY))
          as RSAPrivateKey;
      final encrypter = Encrypter(RSA(publicKey: pubKey, privateKey: privKey));

      if (messages.length > 0) {
        for (var message in messages) {
          String encrypted = message['data'];
          String decrypted = encrypter.decrypt64(encrypted);
          message['data'] = decrypted;
        }
        setState(() {
          FriendDB().updateData(messages);
        });
      }
    });
  }
}

class FriendListItem extends StatelessWidget {
  final Friend friend;

  const FriendListItem(this.friend);

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(Icons.person),
        title: Text(friend.name),
        onTap: () {
          showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                    title: Text("Shared Data"),
                    content: FriendGraph(friend),
                    actions: [
                      TextButton(
                        child: Text('Done'),
                        onPressed: () => Navigator.of(context).pop(),
                      )
                    ],
                  ));
        },
        trailing: ElevatedButton(
          onPressed: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                    title: Text("Send data?"),
                    content: WellbeingGraph(
                      displayShare: false,
                    ),
                    actions: [
                      TextButton(
                        child: Text('No'),
                        onPressed: () => Navigator.pop(context),
                      ),
                      // TODO:
                      TextButton(
                        child: Text('Yes'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  )),
          child: Text("Send"),
        ),
      );
}
