import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge_me/main.dart';
import 'package:nudge_me/pages/checkup.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Correctly adds to DB', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(
        {
          'postcode': 'N6', 'support_code': '12345',
          PREV_STEP_COUNT_KEY: 0
        }
    );
    await tester.pumpWidget(MaterialApp(home: Checkup(),));

    final buttonFind = find.byType(ElevatedButton);
    final sliderFind = find.byType(Slider);
    expect(buttonFind, findsOneWidget);
    expect(sliderFind, findsOneWidget);

    await tester.drag(sliderFind, Offset(500.0, 0.0));
    await tester.pumpAndSettle();
    await tester.tap(buttonFind);

    // TODO: check that the current item was added to DB, maybe change the class
    //       so it accepts a DB in constructor.
  });
}