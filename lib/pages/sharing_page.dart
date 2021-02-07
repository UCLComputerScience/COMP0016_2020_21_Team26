import 'dart:async';
import 'dart:convert';

import 'package:encrypt/encrypt.dart';
import 'package:flutter/material.dart';
import 'package:nudge_me/crypto.dart';
import 'package:nudge_me/main_pages.dart';
import 'package:nudge_me/model/friends_model.dart';
import 'package:nudge_me/model/user_model.dart';
import 'package:nudge_me/pages/add_friend_page.dart';
import 'package:nudge_me/shared/friend_graph.dart';
import 'package:nudge_me/shared/share_button.dart';
import 'package:nudge_me/shared/wellbeing_graph.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

/// get the latest messages for this user
/// returns true if there are new messages from a friend
Future<bool> getLatest() async {
  final prefs = await SharedPreferences.getInstance();
  final body = jsonEncode({
    "identifier": prefs.getString(USER_IDENTIFIER_KEY),
    "password": prefs.getString(USER_PASSWORD_KEY),
  });

  bool hasNewData = false;
  await http
      .post(BASE_URL + "/user/message",
          headers: {"Content-Type": "application/json"}, body: body)
      .then((response) async {
    print("Data Recieved: ${response.body}");
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
      }
      await FriendDB().updateData(messages);
    }

    // If any of the messages are from a friend, there is new data:
    for (var message in messages) {
      if (await FriendDB().isIdentifierPresent(message['identifier_from'])) {
        hasNewData = true;
        break;
      }
    }
  });
  return hasNewData;
}

class SharingPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => SharingPageState();
}

class SharingPageState extends State<SharingPage> {
  final _printKey = GlobalKey();

  Future<List<Friend>> _futureFriends;

  @override
  void initState() {
    super.initState();

    _futureFriends = _getOrderedFriendsList();
    getLatest();
  }

  Future<List<Friend>> _getOrderedFriendsList() =>
      FriendDB().getFriends().then((friends) {
        friends.sort(_compareFriends);
        return friends;
      });

  /// Comparator used to define an ordering on friends. Currently just brings
  /// unread messages to the top.
  int _compareFriends(Friend f1, Friend f2) => f1.read.compareTo(f2.read);

  Widget _getSharableQR(String identifier, String pubKey) {
    return SingleChildScrollView(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RepaintBoundary(
            key: _printKey,
            child: Container(
              // REVIEW: seems a little small on my screen.
              width: 200,
              height: 200,
              child: QrImage(
                data: "$identifier\n$pubKey",
                version: QrVersions.auto,
              ),
            )),
        SizedBox(
          height: 10,
        ),
        ShareButton(_printKey, 'identity_qr.pdf'),
      ],
    ));
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
    final noFriendsWidget = Text(
        "Add people to your care network to share wellbeing data with them.");
    final friendsList = FutureBuilder(
      future: _futureFriends,
      builder: (ctx, data) {
        if (data.hasData) {
          final List<Friend> friends = data.data;
          return friends.length == 0
              ? noFriendsWidget
              : Expanded(
                  child: LiquidPullToRefresh(
                    onRefresh: () async => getLatest().then((hasNew) {
                      if (hasNew) {
                        setState(() {
                          _futureFriends = _getOrderedFriendsList();
                        });
                      }
                    }),
                    child: ListView.builder(
                      padding: kMaterialListPadding,
                      itemCount: friends.length,
                      itemBuilder: (ctx, i) => getListTile(ctx, friends[i]),
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
                    _futureFriends = _getOrderedFriendsList();
                  }));
        },
        label: Text("Add to care network"),
        icon: Icon(Icons.people),
      ),
    );
  }

  Widget getListTile(BuildContext ctx, Friend friend) {
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
                        _sendWellbeingData(context, friend);
                      }),
                ],
              )),
      child: Text("Send"),
    );
    final onView = () {
      FriendDB().setRead(friend.identifier).then((_) => setState(() {
            _futureFriends = _getOrderedFriendsList();
          }));
      return showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
                title: Text("Shared Data"),
                content:
                    FriendGraph(FriendDB().getLatestData(friend.identifier)),
                actions: [
                  TextButton(
                    child: Text('Done'),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ));
    };
    // friend.read might be null
    final unread = friend.read == 0;
    return ListTile(
      leading: unread ? Icon(Icons.message) : Icon(Icons.person),
      selected: unread,
      title: Text(friend.name),
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

  Future<void> _sendWellbeingData(BuildContext context, Friend friend) async {
    final friendKey = FriendDB().getKey(friend.identifier);

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
      'identifier_to': friend.identifier,
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
              : Text("Sent data to ${friend.name}.")));
    });
  }
}
