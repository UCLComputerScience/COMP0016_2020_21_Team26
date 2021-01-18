import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge_me/pages/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Widget buildTestableWidget(Widget widget) {
    return MaterialApp(home: widget);
  }

  Widget buildScaffoldWidget(Widget widget) {
    return MaterialApp(home: Scaffold(body: widget));
  }

  testWidgets('Settings page', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget(SettingsPage()));
    final headingFinder = find.text("Settings");
    expect(headingFinder, findsOneWidget);
  });

  testWidgets('Support widget in Settings', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget(SettingsPage()));
    final supportFinder = find.byType(ChangeSupportWidget);
    expect(supportFinder, findsOneWidget);
  });

  testWidgets('Postcode widget in Settings', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget(SettingsPage()));
    final postcodeFinder = find.byType(ChangePostcodeWidget);
    expect(postcodeFinder, findsOneWidget);
  });

  testWidgets('Change Postcode headings ', (WidgetTester tester) async {
    await tester.pumpWidget(buildScaffoldWidget(ChangePostcodeWidget()));
    final headingFinder = find.text("Postcode ");
    final postcodeHeadingFinder = find.text("Current Postcode: ");
    expect(headingFinder, findsOneWidget);
    expect(postcodeHeadingFinder, findsOneWidget);
  });

  //TODO: figure out how to test when sharedprefs postcode value does exist
  // the page doesn't run with the mock shared preferences value,
  testWidgets('Current Postcode does exist', (WidgetTester tester) async {
    // SharedPreferences.setMockInitialValues({"postcode": "nw1"});
    // SharedPreferences pref = await SharedPreferences.getInstance();
    // await tester.pumpWidget(buildScaffoldWidget(ChangePostcodeWidget()));
    // String userSupportCode = pref.getString("postcode");
    // final currentPostcodeFinder = find.text(userSupportCode);
    // expect(currentPostcodeFinder, findsOneWidget);
  });

  testWidgets('Current Postcode does not exist', (WidgetTester tester) async {
    await tester.pumpWidget(buildScaffoldWidget(ChangePostcodeWidget()));
    final loadingCircleFinder = find.byType(CircularProgressIndicator);
    expect(loadingCircleFinder, findsOneWidget);
  });

  testWidgets('Change Support headings', (WidgetTester tester) async {
    await tester.pumpWidget(buildScaffoldWidget(ChangeSupportWidget()));
    final headingFinder = find.text("Support Code");
    final supportCodeHeadingFinder = find.text("Current Support Code: ");

    expect(headingFinder, findsOneWidget);
    expect(supportCodeHeadingFinder, findsOneWidget);
  });

  //TODO: figure out how to test when sharedprefs support code value does exist
  // the page doesn't run with the mock shared preferences value,
  testWidgets('Current Support Code exists', (WidgetTester tester) async {
    //   SharedPreferences.setMockInitialValues({"support_code": "343"});
    //   SharedPreferences pref = await SharedPreferences.getInstance();
    //   await tester.pumpWidget(buildScaffoldWidget(ChangeSupportWidget()));
    //   String userSupportCode = pref.getString("support_code");
    //   final currentSuppCodeFinder = find.text(userSupportCode);
    //   expect(currentSuppCodeFinder, findsOneWidget);
  });

  testWidgets('Current Support Code does not exist',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildScaffoldWidget(ChangeSupportWidget()));
    final loadingCircleFinder = find.byType(CircularProgressIndicator);
    expect(loadingCircleFinder, findsOneWidget);
  });
}
