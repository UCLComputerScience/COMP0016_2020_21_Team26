import 'package:flutter_test/flutter_test.dart';
import 'package:nudge_me/shared/wellbeing_circle.dart';

void main() {
  testWidgets('WellbeingCircle displays score', (WidgetTester tester) async {
    await tester.pumpWidget(WellbeingCircle(7));
    await tester.pumpAndSettle();

    final scoreFinder = find.text('7');
    expect(scoreFinder, findsOneWidget);
  });

  testWidgets('WellbeingCircle displays N/A if null',
      (WidgetTester tester) async {
    await tester.pumpWidget(WellbeingCircle());
    await tester.pumpAndSettle();

    final scoreFinder = find.text('N/A');
    expect(scoreFinder, findsOneWidget);
  });
}
