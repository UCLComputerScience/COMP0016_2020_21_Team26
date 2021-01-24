import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:nudge_me/model/user_model.dart';
import 'package:nudge_me/pages/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Widget buildTestableWidget(Widget widget) {
  //   return MaterialApp(home: widget);
  // }

  Widget buildScaffoldWidget(Widget widget) {
    return MaterialApp(home: Scaffold(body: widget));
  }

  testWidgets('Current Postcode does not exist', (WidgetTester tester) async {
    await tester.pumpWidget(
        buildScaffoldWidget(ChangePostcodeWidget(UserWellbeingDB())));
    final loadingCircleFinder = find.byType(CircularProgressIndicator);
    expect(loadingCircleFinder, findsOneWidget);
  });

  testWidgets('Current Support Code does not exist',
      (WidgetTester tester) async {
    await tester.pumpWidget(
        buildScaffoldWidget(ChangeSupportWidget(UserWellbeingDB())));
    final loadingCircleFinder = find.byType(CircularProgressIndicator);
    expect(loadingCircleFinder, findsOneWidget);
  });

  testWidgets('Current Postcode does exist', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(
        {"postcode": "nw1", "support_code": "343"});
    await tester
        .pumpWidget(buildScaffoldWidget(ChangePostcodeWidget(MockedDB())));
    final currentPostcodeFinder = find.text("nw1");
    expect(currentPostcodeFinder, findsOneWidget);
  });

  testWidgets('Current Support Code exists', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(
        {"postcode": "nw1", "support_code": "343"});
    await tester
        .pumpWidget(buildScaffoldWidget(ChangeSupportWidget(MockedDB())));
    // debugDumpApp();
    final currentSuppCodeFinder = find.text("343");
    expect(currentSuppCodeFinder, findsOneWidget);
  });
}

class MockedDB extends Mock implements UserWellbeingDB {}
