import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:nudge_me/model/friends_model.dart';
import 'package:nudge_me/pages/support_page.dart';

import '../widget_test.dart';

final Friend exampleFriend = Friend(
  id: 0,
  name: 'ExampleName',
  identifier: 'ExampleId',
  publicKey: 'ExamplePubKey',
  latestData: null,
  read: null,
  currentStepsGoal: null,
  sentActiveGoal: 0,
  initialStepCount: null,
);
final List<Friend> friends = [
  exampleFriend,
];

void main() {
  group('conditional page', () {
    testWidgets('shows detailed explanation when user has no friends',
        (WidgetTester tester) async {
      final mockedFriendDB = MockedFriendDB();
      when(mockedFriendDB.getFriends())
          .thenAnswer((realInvocation) => Future.value([]));
      when(mockedFriendDB.empty)
          .thenAnswer((realInvocation) => Future.value(true));

      await tester
          .pumpWidget(wrapAppProvider(SupportPage(), friendDB: mockedFriendDB));
      await tester.pumpAndSettle();

      expect(
          find.byWidgetPredicate((widget) =>
              widget is RichText &&
              widget.text.toPlainText().contains('When you both have NudgeMe')),
          findsOneWidget);
      expect(find.byType(SliverList), findsNothing);
    });

    testWidgets('shows list with 1 or more friends',
        (WidgetTester tester) async {
      final mockedFriendDB = MockedFriendDB();
      when(mockedFriendDB.getFriends())
          .thenAnswer((realInvocation) => Future.value(friends));
      when(mockedFriendDB.empty)
          .thenAnswer((realInvocation) => Future.value(false));

      await tester
          .pumpWidget(wrapAppProvider(SupportPage(), friendDB: mockedFriendDB));
      await tester.pumpAndSettle();
      await tester.drag(find.text('My Identity \nCode'), Offset(0.0, -500.0));
      await tester.pumpAndSettle();

      expect(
          find.byWidgetPredicate((widget) =>
              widget is RichText &&
              widget.text.toPlainText().contains('When you both have NudgeMe')),
          findsNothing);
      expect(find.byType(SliverList), findsOneWidget);
    });
  });

  testWidgets('hides button when scrolled down', (WidgetTester tester) async {
    final mockedFriendDB = MockedFriendDB();
    when(mockedFriendDB.getFriends()).thenAnswer((realInvocation) =>
        Future.value(List.generate(20, (i) => exampleFriend)));
    when(mockedFriendDB.empty)
        .thenAnswer((realInvocation) => Future.value(false));

    await tester
        .pumpWidget(wrapAppProvider(SupportPage(), friendDB: mockedFriendDB));
    await tester.pumpAndSettle();
    await tester.drag(find.text('My Identity \nCode'), Offset(0.0, -700.0));
    await tester.pumpAndSettle();

    expect(find.text('My Identity \nCode'), findsNothing);
  });
}

class MockedFriendDB extends Mock implements FriendDB {}
