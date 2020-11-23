import 'package:flutter/material.dart';
import 'package:nudge_me/model/user_model.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget { // TODO
  @override
  Widget build(BuildContext context) {
    return Center(
        child: ListView(children: [
          TextField(
            onSubmitted: (String value) {
              final model = Provider.of<UserModel>(context, listen: false);
              model.postcodePrefix = value;
            },
          ),
        ],)
    );
  }
}
