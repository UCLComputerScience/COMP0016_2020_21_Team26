import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nudge_me/pages/intro_screen.dart';
import 'package:flutter/material.dart';

import '../test/widget_test.dart';
import '../test/pages/intro_screen_test.dart';

Future<Null> _swipeThroughIntro(WidgetTester tester) async {
  for (int i = 0; i < numberOfPages - 1; ++i) {
    await tester.drag(find.byType(Image), Offset(-500.0, 0.0));
    await tester.pumpAndSettle();
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
      as IntegrationTestWidgetsFlutterBinding;

  // simulate the way flutter actually responds to animations
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('intro screen', () {
    testWidgets('Swiping switches page', (WidgetTester tester) async {
      await tester.pumpWidget(wrapAppProvider(IntroScreen()));

      expect(find.text("Welcome"), findsOneWidget);
      await tester.drag(find.text("Welcome"), Offset(-500.0, 0.0));
      await tester.pumpAndSettle();
      expect(find.text("Welcome"), findsNothing);
    });

    testWidgets('Swipes through without exception and enforces non-empty input',
        (WidgetTester tester) async {
      // this will generate json data in the build folder
      await binding.watchPerformance(() async {
        await tester.pumpWidget(wrapAppProvider(IntroScreen()));
        await _swipeThroughIntro(tester);

        await tester.tap(find.text("Done"));
        await tester.pumpAndSettle();

        // did not change page:
        expect(find.text("Done"), findsOneWidget);
      });
    });
  });
}
