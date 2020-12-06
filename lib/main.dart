import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:nudge_me/model/user_model.dart';
import 'package:provider/provider.dart';

import 'main_pages.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NudgeMe',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ChangeNotifierProvider(
          create: (context) => UserModel(),
          child: SafeArea( // so the app isn't obscured by notification bar
              child: MainPages()
          )
      ),
    );
  }
}


