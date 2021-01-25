import 'package:flutter/material.dart';
import 'package:nudge_me/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharingPage extends StatelessWidget {
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
      onPressed: () => Navigator.push(
          context, MaterialPageRoute(builder: (ctx) => AddFriendPage())),
      child: Text("Add Friend"),
    );

    return Scaffold(
      body: Column(
        children: [
          showKeyButton,
          addFriendButton,
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }
}

class AddFriendPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text("WIP"); // TODO
  }
}
