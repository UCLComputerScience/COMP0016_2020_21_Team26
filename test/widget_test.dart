// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nudge_me/main.dart';

Finder findSubstring(String target, CommonFinders finder){
  return finder.byWidgetPredicate((widget) =>
  widget is Text && widget.data != null && widget.data.contains(target)
  );
}

void main() {
  testWidgets('Screen changes smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Check the home screen text
    expect(findSubstring("Your postcode is", find), findsOneWidget);
    expect(find.text("Be well!"), findsNothing);

    // Switch screens
    await tester.tap(find.byIcon(Icons.bar_chart));
    await tester.pump();

    // Verify changed screens
    expect(find.text("Your postcode is"), findsNothing);
    expect(find.text("Be well!"), findsOneWidget);
  });
}
