import 'package:flutter/material.dart';
import 'package:nudge_me/model/friends_model.dart';

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
