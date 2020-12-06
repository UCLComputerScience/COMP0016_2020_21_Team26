import 'package:flutter/material.dart';
import 'package:nudge_me/model/user_model.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  // TODO
  @override
  Widget build(BuildContext context) {
    return Center(child: Consumer<UserModel>(builder: (context, model, child) {
      return Text("Your postcode is ${model.postcodePrefix}");
    }));
  }
}
