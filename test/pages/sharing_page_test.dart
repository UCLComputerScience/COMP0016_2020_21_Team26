import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:nudge_me/model/friends_model.dart';
import 'package:nudge_me/pages/sharing_page.dart';

import '../widget_test.dart';

void main() {
  testWidgets('displays detailed help with no friends',
      (WidgetTester tester) async {
    final mockedFriendDB = MockedFriendDB();
    await tester
        .pumpWidget(wrapAppProvider(SharingPage(), friendDB: mockedFriendDB));

    expect(
        find.byWidgetPredicate((widget) =>
            widget is Text && widget.data.contains("texting them a link")),
        findsOneWidget);
  });
}

class MockedFriendDB extends Mock implements FriendDB {}
