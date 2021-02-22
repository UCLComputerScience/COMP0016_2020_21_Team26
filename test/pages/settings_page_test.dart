import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge_me/pages/settings_sections/change_postcode.dart';
import 'package:nudge_me/pages/settings_sections/change_suppcode.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Widget buildScaffoldWidget(Widget widget) {
    return MaterialApp(home: Scaffold(body: widget));
  }

  //tests setting and getting shared pref values
  testWidgets("Shared preferences test", (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(
        {'postcode': 'ha5', 'support_code': '123'});
    SharedPreferences pref = await SharedPreferences.getInstance();
    expect(pref.getString('postcode'), 'ha5');
    expect(pref.getString('support_code'), '123');
  });

  // current postcode
  testWidgets("Current Postcode", (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(
        {'postcode': 'ha5', 'support_code': '123'});
    await tester.pumpWidget(buildScaffoldWidget(ChangePostcode()));
    await tester.pumpAndSettle();

    expect(find.text('ha5'), findsOneWidget);
  });

  //current support code
  testWidgets("Current Support Code", (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(
        {'postcode': 'ha5', 'support_code': '123'});
    await tester.pumpWidget(buildScaffoldWidget(ChangeSupportCode()));
    await tester.pumpAndSettle();

    expect(find.text('123'), findsOneWidget);
  });

  //loading circle for postcode widget
  testWidgets('Current Postcode test', (WidgetTester tester) async {
    await tester.pumpWidget(buildScaffoldWidget(ChangePostcode()));
    final loadingCircleFinder = find.byType(CircularProgressIndicator);
    expect(loadingCircleFinder, findsOneWidget);
  });

  //loading circle for support code widget
  testWidgets('Current Support Code test', (WidgetTester tester) async {
    await tester.pumpWidget(buildScaffoldWidget(ChangeSupportCode()));
    final loadingCircleFinder = find.byType(CircularProgressIndicator);
    expect(loadingCircleFinder, findsOneWidget);
  });

  testWidgets('Current Postcode test', (WidgetTester tester) async {
    await tester.pumpWidget(buildScaffoldWidget(ChangePostcode()));
    final loadingCircleFinder = find.byType(CircularProgressIndicator);
    expect(loadingCircleFinder, findsOneWidget);
  });

  //changing postcode using textformfield and change button
  testWidgets('Change Postcode button', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'postcode': 'ha5'});
    SharedPreferences pref = await SharedPreferences.getInstance();
    await tester.pumpWidget(buildScaffoldWidget(ChangePostcode()));
    await tester.enterText(find.byType(TextFormField), "AB");
    await tester.tap(find.byType(ElevatedButton));
    expect(pref.get('postcode'), "AB");
  });

  //change support code using textformfield and change button
  testWidgets('Change Support Code button', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'support_code': '123'});
    SharedPreferences pref = await SharedPreferences.getInstance();
    await tester.pumpWidget(buildScaffoldWidget(ChangeSupportCode()));
    await tester.enterText(find.byType(TextFormField), "567");
    await tester.tap(find.byType(ElevatedButton));
    expect(pref.get('support_code'), "567");
  });

  //should write reschedule notification test
}
