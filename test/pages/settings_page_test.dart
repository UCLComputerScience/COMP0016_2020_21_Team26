import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge_me/pages/settings_page.dart';
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

  //loading circle for postcode widget
  testWidgets('Current Postcode test', (WidgetTester tester) async {
    await tester.pumpWidget(buildScaffoldWidget(ChangePostcodeWidget()));
    final loadingCircleFinder = find.byType(CircularProgressIndicator);
    expect(loadingCircleFinder, findsOneWidget);
  });

  //loading circle for support code widget
  testWidgets('Current Support Code test', (WidgetTester tester) async {
    await tester.pumpWidget(buildScaffoldWidget(ChangeSupportWidget()));
    final loadingCircleFinder = find.byType(CircularProgressIndicator);
    expect(loadingCircleFinder, findsOneWidget);
  });

  testWidgets('Current Postcode test', (WidgetTester tester) async {
      await tester.pumpWidget(buildScaffoldWidget(ChangePostcodeWidget()));
      final loadingCircleFinder = find.byType(CircularProgressIndicator);
      expect(loadingCircleFinder, findsOneWidget);
    });
    
  //changing postcode using textformfield and change button
  testWidgets('Change Postcode button', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'postcode': 'ha5'});
    SharedPreferences pref = await SharedPreferences.getInstance();
    await tester.pumpWidget(buildScaffoldWidget(ChangePostcodeWidget()));
    await tester.enterText(find.byType(TextFormField), "ab");
    await tester.tap(find.byType(ElevatedButton));
    expect(pref.get('postcode'), "ab");
  });

  //change support code using textformfield and change button
  testWidgets('Change Support Code button', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'support_code': '123'});
    SharedPreferences pref = await SharedPreferences.getInstance();
    await tester.pumpWidget(buildScaffoldWidget(ChangeSupportWidget()));
    await tester.enterText(find.byType(TextFormField), "567");
    await tester.tap(find.byType(ElevatedButton));
    expect(pref.get('support_code'), "567");
  });
}
