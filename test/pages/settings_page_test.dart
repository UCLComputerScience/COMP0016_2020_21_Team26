import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge_me/pages/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Widget buildScaffoldWidget(Widget widget) {
    return MaterialApp(home: Scaffold(body: widget));
  }

  testWidgets("Shared preferences test", (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(
        {'postcode': 'ha5', 'support_code': '123'});
    SharedPreferences pref = await SharedPreferences.getInstance();
    expect(pref.getString('postcode'), 'ha5');
    expect(pref.getString('support_code'), '123');
  });

  testWidgets('Current Postcode test', (WidgetTester tester) async {
    await tester.pumpWidget(buildScaffoldWidget(ChangePostcodeWidget()));
    final loadingCircleFinder = find.byType(CircularProgressIndicator);
    expect(loadingCircleFinder, findsOneWidget);
  });

  testWidgets('Current Support Code test', (WidgetTester tester) async {
    await tester.pumpWidget(buildScaffoldWidget(ChangeSupportWidget()));
    final loadingCircleFinder = find.byType(CircularProgressIndicator);
    expect(loadingCircleFinder, findsOneWidget);
  });
}
