import 'dart:async';
import 'dart:convert';

import 'package:encrypt/encrypt.dart';
import 'package:flutter/material.dart';
import 'package:nudge_me/crypto.dart';
import 'package:nudge_me/main_pages.dart';
import 'package:nudge_me/model/friends_model.dart';
import 'package:nudge_me/model/user_model.dart';
import 'package:nudge_me/pages/add_friend_page.dart';
import 'package:nudge_me/pages/contact_share_page.dart';
import 'package:nudge_me/shared/friend_graph.dart';
import 'package:nudge_me/shared/wellbeing_graph.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

/// get the latest messages for this user
/// returns true if there are new messages from a friend
Future<bool> getLatest([BuildContext ctx]) async {
  final friendDB = ctx == null ? FriendDB() : Provider.of<FriendDB>(ctx);
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
      await friendDB.updateData(messages);
    }

    // If any of the messages are from a friend, there is new data:
    for (var message in messages) {
      if (await friendDB.isIdentifierPresent(message['identifier_from'])) {
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
  @override
  void initState() {
    super.initState();

    getLatest();
  }

  /// gets the friends list using provider.
  Future<List<Friend>> _getFriendsList(BuildContext context) =>
      Provider.of<FriendDB>(context).getFriends();

  Widget _getSharableQR(String identifier, String pubKey) {
    // sends user to our website, which should redirect them to the
    // nudgeme://... custom scheme (since many apps don't recognise them as
    // links by default, we redirect them manually).
    final url = "$BASE_URL/add-friend?"
        "identifier=${Uri.encodeComponent(identifier)}"
        "&pubKey=${Uri.encodeComponent(pubKey)}";
    final message = "Add me on NudgeMe by clicking this:\n$url";
    final shareButton = OutlinedButton(
        onPressed: () => Share.share(message),
        child: Icon(
          Icons.share,
          size: 40,
        ));
    final contactShareButton = OutlinedButton(
        onPressed: () async {
          if (await Permission.contacts.request().isGranted) {
            return Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ContactSharePage(message)));
          } else {
            Scaffold.of(context).showSnackBar(SnackBar(
                content: Text("Need permission to share with contacts.")));
          }
        },
        child: Text("Share using SMS"));

    return SingleChildScrollView(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 200,
          height: 200,
          child: QrImage(
            data: "$identifier\n$pubKey",
            version: QrVersions.auto,
          ),
        ),
        SizedBox(
          height: 10,
        ),
        shareButton,
        SizedBox(
          height: 10,
        ),
        contactShareButton,
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
        "Set up your primary care network on this page. This will allow you to share your wellbeing with them.",
        style: Theme.of(context).textTheme.bodyText1,
        textAlign: TextAlign.center);
    final friendsList = FutureBuilder(
      future: _getFriendsList(context),
      builder: (ctx, data) {
        if (data.hasData) {
          final List<Friend> friends = data.data;
          // sort so unread moves to the top
          friends.sort();

          return friends.length == 0
              ? noFriendsWidget
              : Expanded(
                  child: LiquidPullToRefresh(
                    onRefresh: () async => getLatest(),
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
                  // NOTE: not using the new context 'ctx'
                  builder: (ctx) => AddFriendPage(Scaffold.of(context))));
        },
        label: Text("Add to care network"),
        icon: Icon(Icons.people),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
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
      Provider.of<FriendDB>(context, listen: false).setRead(friend.identifier);
      return showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
                title: Text("Shared Data"),
                content: FriendGraph(Provider.of<FriendDB>(context)
                    .getLatestData(friend.identifier)),
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
    final friendKey = Provider.of<FriendDB>(context).getKey(friend.identifier);

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
