// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder findSubstring(String target, CommonFinders finder) {
  return finder.byWidgetPredicate((widget) =>
      widget is Text && widget.data != null && widget.data.contains(target));
}

void main() {
  testWidgets('Screen changes smoke test', (WidgetTester tester) async {
    // TODO: add tests. Async has made it slightly difficult to test so I shall
    //       leave this for later.

    // // Build our app and trigger a frame.
    // await tester.pumpWidget(MyApp(), Duration(milliseconds: 100));
    //
    // // Check the home screen text
    // expect(findSubstring("Postcode", find), findsOneWidget);
    // // TODO: investigate why find.text didn't find the text in the graph
    //
    // // Switch screens
    // await tester.tap(find.byIcon(Icons.bar_chart));
    // await tester.pumpAndSettle();
    //
    // // Verify changed screens
    // expect(findSubstring("Postcode", find), findsNothing);
  });
}
