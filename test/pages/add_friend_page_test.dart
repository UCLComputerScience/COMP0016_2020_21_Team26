import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:nudge_me/model/friends_model.dart';
import 'package:nudge_me/pages/add_friend_page.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

void main() {
  testWidgets('Displays titles', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AddFriendPage(MockedScaffoldState(), MockedFriendDB()),
    ));

    expect(find.text("Scan their QR code"), findsOneWidget);
    expect(find.text("Enter their name"), findsOneWidget);
  });

  testWidgets('Displays QR view by default', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AddFriendPage(MockedScaffoldState(), MockedFriendDB()),
    ));

    expect(find.byType(QRView), findsOneWidget);
  });

  testWidgets('Given ID/key, skips QR code', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AddFriendPage(
          MockedScaffoldState(), MockedFriendDB(), "exampleID", "exampleKey"),
    ));

    expect(find.byType(QRView), findsNothing);
  });

  testWidgets('Given ID/key, inserts new friend into DB',
      (WidgetTester tester) async {
    final identifier = "exampleID";
    final pubKey = "exampleKey";
    final name = "exampleName";
    final mockedDB = MockedFriendDB();

    await tester.pumpWidget(MaterialApp(
      home: AddFriendPage(MockedScaffoldState(), mockedDB, identifier, pubKey),
    ));
    // enter name and press done:
    await tester.enterText(find.byType(TextFormField), name);
    await tester.tap(find.byType(ElevatedButton));

    verify(mockedDB.insertWithData(
      name: name,
      identifier: identifier,
      publicKey: pubKey,
      latestData: null,
      read: null,
    ));
  });

  testWidgets('Given existing identifier, and a key, does not insert',
      (WidgetTester tester) async {
    final identifier = "existingID";
    final pubKey = "exampleKey";
    final name = "exampleName";
    final mockedDB = MockedFriendDB();

    await tester.pumpWidget(MaterialApp(
      home: AddFriendPage(MockedScaffoldState(), mockedDB, identifier, pubKey),
    ));
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

class MockedFriendDB extends Mock implements FriendDB {
  List<String> identifiers = ["existingID"];

  @override
  Future<bool> isIdentifierPresent(String identifier) {
    return Future.value(identifiers.contains(identifier));
  }
}

class MockedScaffoldState extends Mock implements ScaffoldState {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return super.toString();
  }
}
