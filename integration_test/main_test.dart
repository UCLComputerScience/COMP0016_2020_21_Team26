import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nudge_me/pages/intro_screen.dart';
import 'package:flutter/material.dart';

import '../test/widget_test.dart';
import '../test/pages/intro_screen_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('intro screen', () {
    testWidgets('Swiping switches page', (WidgetTester tester) async {
      await tester.pumpWidget(wrapAppProvider(IntroScreen()));

      expect(find.text("Welcome"), findsOneWidget);
      await tester.drag(find.text("Welcome"), Offset(-500.0, 0.0));
      await tester.pumpAndSettle();
      expect(find.text("Welcome"), findsNothing);
    });

    testWidgets('Swipes through without exception', (WidgetTester tester) async {
      await tester.pumpWidget(wrapAppProvider(IntroScreen()));

      for (int i = 0; i < numberOfPages - 1; ++i) {
        await tester.drag(find.byType(Image), Offset(-500.0, 0.0));
        await tester.pumpAndSettle();
      }
    });
  });
}
