import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:nudge_me/main.dart';
import 'package:nudge_me/model/user_model.dart';
import 'package:nudge_me/pages/checkup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clock/clock.dart';

import '../widget_test.dart';

void main() {
  testWidgets('Slider and button present', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(
        {'postcode': 'N6', 'support_code': '12345', PREV_STEP_COUNT_KEY: 0});
    final fakeStepStream = Stream.fromIterable([0]);

    await tester.pumpWidget(wrapAppProvider(
      WellbeingCheck(fakeStepStream),
    ));
    await tester.pumpAndSettle();

    final buttonFind = find.byType(ElevatedButton);
    final sliderFind = find.byType(Slider);
    expect(buttonFind, findsOneWidget);
    expect(sliderFind, findsOneWidget);
  });

  testWidgets('Correctly adds to DB', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(
        {'postcode': 'N6', 'support_code': '12345', PREV_STEP_COUNT_KEY: 0});
    final mockedDB = _MockedDB();
    when(mockedDB.getLastNWeeks(3)).thenAnswer((_) async => <WellbeingItem>[]);
    final fakeStepStream = Stream.fromIterable([0]);

    await tester.pumpWidget(wrapAppProvider(
      WellbeingCheck(fakeStepStream),
      wbDB: mockedDB,
    ));
    await tester.pumpAndSettle();

    // should be at score of 10 after dragging
    await tester.drag(find.byType(Slider), Offset(500.0, 0.0));
    await tester.pumpAndSettle();
    await withClock(
        // this should use the fake clock when requesting date
        Clock.fixed(DateTime(2021)),
        () async => await tester.tap(find.byType(ElevatedButton)));

    verify(mockedDB.getLastNWeeks(3));
    verify(mockedDB.insertWithData(
        date: "2021-01-01",
        postcode: 'N6',
        wellbeingScore: 10.0,
        numSteps: 0,
        supportCode: '12345'));
  });

  testWidgets('Works when steps reset', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(
        {'postcode': 'N6', 'support_code': '12345', PREV_STEP_COUNT_KEY: 6666});
    final mockedDB = _MockedDB();
    when(mockedDB.getLastNWeeks(3)).thenAnswer((_) async => <WellbeingItem>[]);
    final fakeStepStream = Stream.fromIterable([0]);

    await tester.pumpWidget(
        wrapAppProvider(WellbeingCheck(fakeStepStream), wbDB: mockedDB));
    await tester.pumpAndSettle();

    // should be at score of 10 after dragging
    await tester.drag(find.byType(Slider), Offset(500.0, 0.0));
    await tester.pumpAndSettle();
    await withClock(
        // this should use the fake clock when requesting date
        Clock.fixed(DateTime(2021)),
        () async => await tester.tap(find.byType(ElevatedButton)));

    verify(mockedDB.getLastNWeeks(3));
    verify(mockedDB.insertWithData(
        date: "2021-01-01",
        postcode: 'N6',
        wellbeingScore: 10.0,
        numSteps: 0,
        supportCode: '12345'));
    final newPrev = await SharedPreferences.getInstance()
        .then((prefs) => prefs.getInt(PREV_STEP_COUNT_KEY));
    assert(newPrev == 0);
  });
}

class _MockedDB extends Mock implements UserWellbeingDB {}
