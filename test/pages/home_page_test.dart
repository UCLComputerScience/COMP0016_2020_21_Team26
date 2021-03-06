import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:nudge_me/main.dart';
import 'package:nudge_me/model/user_model.dart';
import 'package:nudge_me/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widget_test.dart';

void main() {
  testWidgets('displays the last wellbeing score', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(
        {PREV_STEP_COUNT_KEY: 0, HOME_TUTORIAL_DONE_KEY: true});
    final mockedDB = _MockedDB();
    final wellbeingScore = 10.0;
    when(mockedDB.getLastNWeeks(any)).thenAnswer((_) async => [
          WellbeingItem(
            id: 0,
            date: "2021-02-27",
            postcode: "NP1",
            wellbeingScore: wellbeingScore,
            numSteps: 0,
            supportCode: "selfhelp",
          )
        ]);
    final fakeStepStream = Stream.fromIterable([0]);

    await tester
        .pumpWidget(wrapAppProvider(HomePage(fakeStepStream), wbDB: mockedDB));
    await tester.pumpAndSettle();

    expect(find.text("Last Week's Wellbeing Score"), findsOneWidget);
    expect(find.text(wellbeingScore.truncate().toString()), findsOneWidget);
  });

  testWidgets('displays steps', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(
        {PREV_STEP_COUNT_KEY: 0, HOME_TUTORIAL_DONE_KEY: true});
    final mockedDB = _MockedDB();
    when(mockedDB.getLastNWeeks(any)).thenAnswer((_) async => []);
    final fakeStepStream = Stream.fromIterable([0]);

    await tester
        .pumpWidget(wrapAppProvider(HomePage(fakeStepStream), wbDB: mockedDB));
    await tester.pumpAndSettle();

    expect(find.text('This Week\'s Steps'), findsOneWidget);
    expect(find.text("0"), findsOneWidget);
  });
}

// I often declare these for each file since this allows me to have different
// implementations in the future, if needed for a certain page.
class _MockedDB extends Mock implements UserWellbeingDB {}
