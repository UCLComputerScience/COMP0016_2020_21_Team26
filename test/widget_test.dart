// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:nudge_me/main.dart';
import 'package:nudge_me/model/friends_model.dart';
import 'package:nudge_me/model/user_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// wraps a [Widget] with [MaterialApp] and also provides databases
Widget wrapAppProvider(Widget w, {UserWellbeingDB wbDB, FriendDB friendDB}) {
  if (wbDB == null) {
    wbDB = MockedWBDB();
  }
  if (friendDB == null) {
    friendDB = MockedFriendDB();
  }

  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(
        value: wbDB,
      ),
      ChangeNotifierProvider.value(
        value: friendDB,
      ),
    ],
    child: MaterialApp(
      home: w,
    ),
  );
}

void main() {
  testWidgets('Intro screen displayed smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();

    expect(find.text("Welcome"), findsOneWidget);
  });
}

class MockedFriendDB extends Mock implements FriendDB {}

class MockedWBDB extends Mock implements UserWellbeingDB {}
