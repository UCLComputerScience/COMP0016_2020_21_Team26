import 'dart:convert';

import 'package:encrypt/encrypt.dart';
import 'package:flutter/material.dart';
import 'package:nudge_me/crypto.dart';
import 'package:nudge_me/model/friends_model.dart';
import 'package:nudge_me/pages/publish_screen.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SharingPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => SharingPageState();
}

class SharingPageState extends State<SharingPage> {
  var _futureFriends = FriendDB().getFriends();

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
    final refreshButton = ElevatedButton(
      onPressed: _getLatest,
      child: Text("Refresh"),
    );
    final friendsList = FutureBuilder(
      future: _futureFriends,
      builder: (ctx, data) {
        if (data.hasData) {
          final List<Friend> friends = data.data;
          return Column(
            // prob should change this to ListView eventually
            children:
                friends.map((fr) => Text(fr.name)).toList(growable: false),
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

      for (var message in messages) {
        String encrypted = message['data'];
        String decrypted = encrypter.decrypt64(encrypted);
        message['data'] = decrypted;
      }
      setState(() {
        FriendDB().updateData(messages);
      });
    });
  }
}

class AddFriendPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => AddFriendPageState();
}

class AddFriendPageState extends State<AddFriendPage> {
  final _formKey = GlobalKey<FormState>();

  String name;
  String identifier;
  String publicKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Text("Name"),
            TextFormField(
              onSaved: (val) {
                setState(() {
                  name = val;
                });
              },
            ),
            Text("Id"),
            TextFormField(
              onSaved: (val) {
                setState(() {
                  identifier = val;
                });
              },
            ),
            Text("Key:"),
            TextFormField(
              onSaved: (val) {
                setState(() {
                  publicKey = val;
                });
              },
            ),
            ElevatedButton(
              onPressed: () {
                _formKey.currentState.save();
                // TODO: verify that user identifier exists before inserting
                setState(() {
                  FriendDB().insertWithData(
                      name: name,
                      identifier: identifier,
                      publicKey: publicKey,
                      latestData: null);
                });
                Navigator.pop(context);
              },
              child: Text("Done"),
            ),
          ],
        ),
      ),
    );
  }
}
