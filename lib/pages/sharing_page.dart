import 'dart:async';
import 'dart:convert';

import 'package:encrypt/encrypt.dart';
import 'package:flutter/material.dart';
import 'package:highlighter_coachmark/highlighter_coachmark.dart';
import 'package:nudge_me/crypto.dart';
import 'package:nudge_me/main_pages.dart';
import 'package:nudge_me/model/friends_model.dart';
import 'package:nudge_me/model/user_model.dart';
import 'package:nudge_me/pages/add_friend_page.dart';
import 'package:nudge_me/pages/contact_share_page.dart';
import 'package:nudge_me/shared/friend_graph.dart';
import 'package:nudge_me/shared/wellbeing_graph.dart';
import 'package:pointycastle/pointycastle.dart' as pointyCastle;
import 'package:permission_handler/permission_handler.dart';

import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

const NETWORK_TUTORIAL_DONE_KEY = "network_tutorial_done";

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
        as pointyCastle.RSAPublicKey;
    final privKey = RSAKeyParser().parse(prefs.getString(RSA_PRIVATE_PEM_KEY))
        as pointyCastle.RSAPrivateKey;
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
  GlobalKey _networkHeadingKey = GlobalObjectKey("support_network");

  @override
  void initState() {
    super.initState();

    getLatest();
    showTutorial();
  }

  void showTutorial() async {
    if (!(await _isNetworkTutorialDone())) {
      Timer(Duration(milliseconds: 400), () => showCoachMarkHeading());
    }
  }

  Future<bool> _isNetworkTutorialDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(NETWORK_TUTORIAL_DONE_KEY) &&
        prefs.getBool(NETWORK_TUTORIAL_DONE_KEY);
  }

  ///function to show the first slide of the tutorial, explaining the wellbeing circle
  void showCoachMarkHeading() {
    CoachMark coachMarkHeading = CoachMark();
    RenderBox target = _networkHeadingKey.currentContext.findRenderObject();
    Rect markRect = target.localToGlobal(Offset.zero) & target.size;
    markRect = Rect.fromCircle(
        center: markRect.center, radius: markRect.longestSide * 0.6);
    coachMarkHeading.show(
        targetContext: _networkHeadingKey.currentContext,
        markRect: markRect,
        children: [
          Center(
              child: Padding(
                  padding: EdgeInsets.fromLTRB(10, 50, 10, 0),
                  child: Text(
                      "Your support network is a list of people that you would be willing to share your wellbeing diary with. \n\n" +
                          "Sharing your wellbeing diary can help you start conversations about your mental wellbeing with people in your life.\n\n" +
                          "Follow the instructions on this page to add people to your support network.",
                      style: Theme.of(context).textTheme.subtitle2)))
        ],
        duration: Duration(seconds: 15),
        onClose: () {});
  }

  /// gets the friends list using provider.
  Future<List<Friend>> _getFriendsList(BuildContext context) =>
      Provider.of<FriendDB>(context).getFriends();

  Widget _getShareLinkButtons(String identifier, String pubKey) {
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

    return Column(children: [shareButton, contactShareButton]);
  }

  Widget _getQRCode(String identifier, String pubKey) {
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
                      return _getQRCode(identifier, pubKey);
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

    final shareLinkButtons = FutureBuilder(
      future: SharedPreferences.getInstance(),
      builder: (context, data) {
        if (data.hasData) {
          final SharedPreferences prefs = data.data;
          final identifier = prefs.getString(USER_IDENTIFIER_KEY);
          final pubKey = prefs.getString(RSA_PUBLIC_PEM_KEY);
          return _getShareLinkButtons(identifier, pubKey);
        } else if (data.hasError) {
          print(data.error);
          return Text("Couldn't get link.");
        }
        return LinearProgressIndicator();
      },
    );

    final scanCodeButton = OutlinedButton(
      onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              // NOTE: not using the new context 'ctx'
              builder: (ctx) => AddFriendPage(Scaffold.of(context)))),
      child: Text('Scan code to\n add to network', textAlign: TextAlign.center),
    );

    final noFriendsWidget = Column(children: [
      Center(
          child: Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(children: [
                Text("There are two ways to add someone to your support network on NudgeMe.\n\n" +
                    "To add someone, the person must already have NudgeMe on their phone. You must both add each other to be added to each other’s support network.\n"),
                Text("1. In person: ",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  "Ask the person you want to add to click ‘My identity’ and scan the code on their phone. \nThen, click ‘My Identity’ on your phone and allow them to scan your code.",
                  style: Theme.of(context).textTheme.bodyText2,
                )
              ]))),
      showKeyButton,
      scanCodeButton,
      Center(
          child: Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(children: [
                Text("\n2. Over message: ",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                    "Share a link with someone who has NudgeMe. When they click the link, it will add you to their care network.\nAsk them to send you a link so you can add them back.",
                    style: Theme.of(context).textTheme.bodyText2,
                    textAlign: TextAlign.start)
              ]))),
      shareLinkButtons
    ]);

    final friendsDescription = Center(
        child: Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Column(children: [
              Text(
                  "This is your support network. Your support network is a list of people that you would be willing to share your wellbeing diary with. \n\n" +
                      "Sharing your wellbeing diary can help you start conversations about your mental wellbeing with people in your life.\n\n" +
                      "Click the send buttons below to share your diary with your network. Pull down to reload. ",
                  style: Theme.of(context).textTheme.bodyText2)
            ])));

    final friendsList = FutureBuilder(
        future: _getFriendsList(context),
        builder: (ctx, data) {
          if (data.hasData) {
            final List<Friend> friends = data.data;
            // sort so unread moves to the top
            friends.sort();
            return Expanded(
                child: LiquidPullToRefresh(
                    onRefresh: () async => getLatest(),
                    child: ListView.builder(
                      padding: kMaterialListPadding,
                      itemCount: friends.length,
                      itemBuilder: (ctx, i) => getListTile(ctx, friends[i]),
                    )));
          }
          return CircularProgressIndicator();
        });

    final friendsWidget = FutureBuilder(
        future: _getFriendsList(context),
        builder: (ctx, data) {
          final List<Friend> friends = data.data;
          return !data.hasData || friends.length == 0
              ? noFriendsWidget
              : Flexible(
                  child: Column(children: [
                  friendsDescription,
                  friendsList,
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Column(children: [showKeyButton, scanCodeButton]),
                    SizedBox(width: 70),
                    shareLinkButtons
                  ]),
                  SizedBox(height: 10)
                ]));
        });

    return Scaffold(
      body: Column(
        children: [
          Container(
              child: Text("Support Network",
                  style: Theme.of(context).textTheme.headline1,
                  textAlign: TextAlign.center),
              key: _networkHeadingKey),
          SizedBox(height: 10),
          friendsWidget
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
