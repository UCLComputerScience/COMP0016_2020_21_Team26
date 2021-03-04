import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:nudge_me/crypto.dart';
import 'package:nudge_me/model/friends_model.dart';
import 'package:nudge_me/pages/add_friend_page.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widget_test.dart';

void main() {
  testWidgets('Displays titles', (WidgetTester tester) async {
    await tester.pumpWidget(wrapAppProvider(
      AddFriendPage(),
    ));

    expect(find.text("Scan their QR code"), findsOneWidget);
    expect(find.text("Enter their name"), findsOneWidget);
  });

  testWidgets('Displays QR view by default', (WidgetTester tester) async {
    await tester.pumpWidget(wrapAppProvider(
      AddFriendPage(),
    ));

    expect(find.byType(QRView), findsOneWidget);
  });

  testWidgets('Given ID/key, skips QR code', (WidgetTester tester) async {
    await tester.pumpWidget(wrapAppProvider(
      AddFriendPage("exampleID", "exampleKey"),
    ));

    expect(find.byType(QRView), findsNothing);
  });

  testWidgets('Given ID/key, inserts new friend into DB',
      (WidgetTester tester) async {
    final identifier = "exampleID";
    final pubKey = "exampleKey";
    final name = "exampleName";
    final mockedDB = _MockedFriendDB();
    when(mockedDB.isIdentifierPresent(identifier))
        .thenAnswer((_) async => false);
    // need to set this initial prefs to empty, otherwise it somehow fails the
    // test. (It appears like it cannot retrieve the prefs during execution.)
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
        wrapAppProvider(AddFriendPage(identifier, pubKey), friendDB: mockedDB));
    // enter name and press done:
    await tester.enterText(find.byType(TextFormField), name);
    await tester.tap(find.byType(ElevatedButton));

    verify(mockedDB.insertWithData(
      name: name,
      identifier: identifier,
      publicKey: pubKey,
      latestData: null,
      read: null,
      currentStepsGoal: null,
      sentActiveGoal: 0,
      initialStepCount: null,
    ));
  });

  testWidgets('Given existing identifier, and a key, does not insert',
      (WidgetTester tester) async {
    final identifier = "existingID";
    final pubKey = "exampleKey";
    final name = "exampleName";
    final mockedDB = _MockedFriendDB();
    when(mockedDB.isIdentifierPresent(identifier))
        .thenAnswer((_) async => true);
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
        wrapAppProvider(AddFriendPage(identifier, pubKey), friendDB: mockedDB));
    // enter name and press done:
    await tester.enterText(find.byType(TextFormField), name);
    await tester.tap(find.byType(ElevatedButton));

    verifyNever(mockedDB.insertWithData(
      name: name,
      identifier: identifier,
      publicKey: pubKey,
      latestData: null,
      read: null,
    ));
  });

  testWidgets('Given own identifier, and key, does not insert',
      (WidgetTester tester) async {
    final identifier = "myID";
    final pubKey = "exampleKey";
    final name = "exampleName";
    final mockedDB = _MockedFriendDB();
    when(mockedDB.isIdentifierPresent(identifier))
        .thenAnswer((_) async => false);
    SharedPreferences.setMockInitialValues({USER_IDENTIFIER_KEY: identifier});

    await tester.pumpWidget(
        wrapAppProvider(AddFriendPage(identifier, pubKey), friendDB: mockedDB));
    // enter name and press done:
    await tester.enterText(find.byType(TextFormField), name);
    await tester.tap(find.byType(ElevatedButton));

    verifyNever(mockedDB.insertWithData(
      name: name,
      identifier: identifier,
      publicKey: pubKey,
      latestData: null,
      read: null,
    ));
  });
}

class _MockedFriendDB extends Mock implements FriendDB {}
