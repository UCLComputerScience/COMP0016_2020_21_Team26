import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:nudge_me/model/user_model.dart';
import 'package:nudge_me/pages/intro_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widget_test.dart';

// NOTE: update this if the number of pages in intro screen changes
const numberOfPages = 6;

void main() {
  testWidgets('Swiping switches page', (WidgetTester tester) async {
    await tester.pumpWidget(wrapAppProvider(IntroScreen()));

    expect(find.text("Welcome"), findsOneWidget);
    await tester.drag(find.text("Welcome"), Offset(-500.0, 0.0));
    await tester.pumpAndSettle();
    expect(find.text("Welcome"), findsNothing);
  });

  // this test probably seems trivial, but I actually found a bug with it.
  testWidgets('Swipes through without exception', (WidgetTester tester) async {
    await tester.pumpWidget(wrapAppProvider(IntroScreen()));

    for (int i = 0; i < numberOfPages - 1; ++i) {
      await tester.drag(find.byType(Image), Offset(-500.0, 0.0));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Adds first checkup to DB and updates prefs',
      (WidgetTester tester) async {
    final mockedDB = _MockedDB();
    final supportCode = "GP";
    final postcode = "M11";
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(wrapAppProvider(
      IntroScreen(),
      wbDB: mockedDB,
    ));
    for (int i = 0; i < numberOfPages - 1; ++i) {
      await tester.drag(find.byType(Image), Offset(-500.0, 0.0));
      await tester.pumpAndSettle();
    }

    await tester.enterText(
        find.widgetWithText(TextField, "Enter support code here"), supportCode);
    await tester.enterText(
        find.widgetWithText(TextField, "Enter postcode here"), postcode);

    await withClock(Clock.fixed(DateTime(2021)),
        () async => await tester.tap(find.text("Done")));

    verify(mockedDB.insertWithData(
      date: "2021-01-01",
      postcode: postcode,
      wellbeingScore: 0.0,
      numSteps: 0,
      supportCode: supportCode,
    ));
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    assert(prefs.getString('postcode') == postcode);
    assert(prefs.getString('support_code') == supportCode);
  });

  testWidgets('Does not add to DB or prefs if postcode missing',
      (WidgetTester tester) async {
    final mockedDB = _MockedDB();
    final supportCode = "GP";
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(wrapAppProvider(
      IntroScreen(),
      wbDB: mockedDB,
    ));
    for (int i = 0; i < numberOfPages - 1; ++i) {
      await tester.drag(find.byType(Image), Offset(-500.0, 0.0));
      await tester.pumpAndSettle();
    }

    await tester.enterText(
        find.widgetWithText(TextField, "Enter support code here"), supportCode);

    await withClock(Clock.fixed(DateTime(2021)),
        () async => await tester.tap(find.text("Done")));

    verifyNever(mockedDB.insertWithData(
      date: anyNamed("date"),
      postcode: anyNamed("postcode"),
      wellbeingScore: anyNamed("wellbeingScore"),
      numSteps: anyNamed("numSteps"),
      supportCode: anyNamed("supportCode"),
    ));
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    assert(prefs.getString('postcode') == null);
    assert(prefs.getString('support_code') == null);
  });
}

class _MockedDB extends Mock implements UserWellbeingDB {}
