import 'dart:async';
import 'dart:convert';

import 'package:encrypt/encrypt.dart';
import 'package:flutter/material.dart';
import 'package:nudge_me/crypto.dart';
import 'package:nudge_me/model/friends_model.dart';
import 'package:nudge_me/model/user_model.dart';
import 'package:nudge_me/pages/add_friend_page.dart';
import 'package:nudge_me/pages/publish_screen.dart';
import 'package:nudge_me/shared/friend_graph.dart';
import 'package:nudge_me/shared/share_button.dart';
import 'package:nudge_me/shared/wellbeing_graph.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

class SharingPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => SharingPageState();
}

class SharingPageState extends State<SharingPage> {
  final _printKey = GlobalKey();

  Future<List<Friend>> _futureFriends = FriendDB().getFriends();

  /// map to check if user has seen the latest data from a user
  final Map<String, bool> _friendUnreadData = {};

  @override
  void initState() {
    super.initState();

    _getLatest();
    // refresh every 2 minutes (while app is open)
    Timer.periodic(Duration(minutes: 2), (timer) => _getLatest());
  }

  Widget _getSharableQR(String identifier, String pubKey) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RepaintBoundary(
          key: _printKey,
          child: Container(
            // HACK: Using a container should fix the LayoutBuilder exception.
            //       Not ideal though.
            height: 275,
            child: QrImage(
              data: "$identifier\n$pubKey",
              version: QrVersions.auto,
            ),
          ),
        ),
        SizedBox(
          height: 10,
        ),
        ShareButton(_printKey, 'identity_qr.pdf'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final showKeyButton = OutlinedButton(
      onPressed: () => showDialog(
          builder: (context) => AlertDialog(
                title: Text("Identity - QR Code"),
                content: FutureBuilder(
                  future: SharedPreferences.getInstance(),
                  builder: (context, data) {
                    if (data.hasData) {
                      final SharedPreferences prefs = data.data;
                      final identifier = prefs.getString(USER_IDENTIFIER_KEY);
                      final pubKey = prefs.getString(RSA_PUBLIC_PEM_KEY);
                      return _getSharableQR(identifier, pubKey);
                    } else if (data.hasError) {
                      print(data.error);
                      return Text("Couldn't get data.");
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
      child: Text('My Identity'),
    );
    final noFriendsWidget =
        Text("Add friends to share wellbeing data with them.");
    final friendsList = FutureBuilder(
      future: _futureFriends,
      builder: (ctx, data) {
        if (data.hasData) {
          final List<Friend> friends = data.data;
          return friends.length == 0
              ? noFriendsWidget
              : Expanded(
                  child: LiquidPullToRefresh(
                    onRefresh: _getLatest,
                    child: ListView.builder(
                      padding: kMaterialListPadding,
                      itemCount: friends.length,
                      itemBuilder: (ctx, i) =>
                          FriendListItem(friends[i], _friendUnreadData),
                    ),
                  ),
                );
        }
        return CircularProgressIndicator();
      },
    );

    return Scaffold(
      body: Column(
        children: [
          showKeyButton,
          Divider(
            thickness: 3,
          ),
          friendsList,
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (ctx) => AddFriendPage(Scaffold.of(context))))
              .then((v) => setState(() {
                    // HACK: this forces the page to rebuild since the user prob
                    //       just added a new friend
                    _futureFriends = FriendDB().getFriends();
                  }));
        },
        label: Text("Add Friend"),
        icon: Icon(Icons.people),
      ),
    );
  }

  /// get the latest messages for this user
  Future<void> _getLatest() async {
    final prefs = await SharedPreferences.getInstance();
    final body = jsonEncode({
      "identifier": prefs.getString(USER_IDENTIFIER_KEY),
      "password": prefs.getString(USER_PASSWORD_KEY),
    });

    await http
        .post(BASE_URL + "/user/message",
            headers: {"Content-Type": "application/json"}, body: body)
        .then((response) {
      print("Recieved: ${response.body}");
      // this typecast may cause an error if the password doesn't match, but
      // that shouldn't happen (and if it does I want it to be reported
      // anway). So I'm not doing any special error-handling.
      final List<dynamic> messages = jsonDecode(response.body);

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
          _friendUnreadData[message['identifier_from']] = true;
        }
        FriendDB().updateData(messages).then((_) {
          if (mounted) {
            setState(() {});
          }
        });
      }
    });
  }
}

class FriendListItem extends StatefulWidget {
  final Friend friend;

  // this is the stateful part, but its based on 'outside' state
  final Map<String, bool> unreadData;

  const FriendListItem(this.friend, this.unreadData);

  @override
  State<StatefulWidget> createState() => FriendListItemState();
}

class FriendListItemState extends State<FriendListItem> {
  @override
  Widget build(BuildContext context) {
    final sendButton = ElevatedButton(
      onPressed: () => showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
                title: Text("Send data?"),
                content: WellbeingGraph(
                  displayShare: false,
                  shouldShowTutorial: false,
                ),
                actions: [
                  TextButton(
                    child: Text('No'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  TextButton(
                      child: Text('Yes'),
                      onPressed: () async {
                        Navigator.pop(context);
                        _sendWellbeingData(context);
                      }),
                ],
              )),
      child: Text("Send"),
    );
    final onView = () {
      setState(() {
        widget.unreadData[widget.friend.identifier] = false;
      });
      return showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
                title: Text("Shared Data"),
                content: FriendGraph(
                    FriendDB().getLatestData(widget.friend.identifier)),
                actions: [
                  TextButton(
                    child: Text('Done'),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ));
    };
    final unread = widget.unreadData[widget.friend.identifier] == true;
    return ListTile(
      leading: unread ? Icon(Icons.message) : Icon(Icons.person),
      selected: unread,
      title: Text(widget.friend.name),
      onTap: onView,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton(
            child: Text("View"),
            onPressed: onView,
          ),
          SizedBox(
            width: 5,
          ),
          sendButton,
        ],
      ),
    );
  }

  Future<void> _sendWellbeingData(BuildContext context) async {
    final friendKey = FriendDB().getKey(widget.friend.identifier);

    final List<WellbeingItem> items = await UserWellbeingDB().getLastNWeeks(5);
    final List<Map<String, int>> mapped = items
        .map((e) => {
              'week': e.id,
              'score': e.wellbeingScore.truncate(),
              'steps': e.numSteps
            })
        .toList(growable: false);
    final jsonString = json.encode(mapped);

    final encrypter = Encrypter(RSA(publicKey: await friendKey));
    final data = encrypter.encrypt(jsonString).base64;

    final prefs = await SharedPreferences.getInstance();
    final body = json.encode({
      'identifier_from': prefs.getString(USER_IDENTIFIER_KEY),
      'password': prefs.getString(USER_PASSWORD_KEY),
      'identifier_to': widget.friend.identifier,
      'data': data
    });
    http
        .post(BASE_URL + "/user/message/new",
            headers: {"Content-Type": "application/json"}, body: body)
        .then((response) {
      final body = json.decode(response.body);
      print(body);
      Scaffold.of(context).showSnackBar(SnackBar(
          content: body['success'] == false
              ? Text("Failed to send.")
              : Text("Sent data to ${widget.friend.name}.")));
    });
  }
}
