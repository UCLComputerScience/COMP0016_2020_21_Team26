import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:nudge_me/background.dart';
import 'package:nudge_me/main.dart';
import 'package:nudge_me/main_pages.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nudge_me/notification.dart';

/// Screen that displays to faciliate the user setup.
/// Also schedules the checkup/publish notifications here to ensure that
/// its only done once.
class IntroScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: IntroScreenWidgets());
  }
}

class IntroScreenWidgets extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _IntroScreenWidgetsState();
}

class _IntroScreenWidgetsState extends State<IntroScreenWidgets> {
  final postcodeController = TextEditingController();
  final supportCodeController = TextEditingController();

  void _saveInput(String postcode, String suppcode) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('postcode', postcode);
    prefs.setString('support_code', suppcode);
  }

  bool _isInputValid(String postcode, String suppCode) {
    return 2 <= postcode.length && postcode.length <= 4 && suppCode.length > 0;
  }

  void _onIntroEnd(context) {
    if (!_isInputValid(postcodeController.text, supportCodeController.text)) {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("Invalid postcode or support code."),
      ));
      return;
    }

    _saveInput(postcodeController.text, supportCodeController.text);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MainPages()),
    );
    _finishSetup();
  }

  void _finishSetup() async {
    scheduleCheckup(DateTime.sunday, const Time(12));
    schedulePublish(DateTime.monday, const Time(12));
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setBool(FIRST_TIME_DONE_KEY, true));
    // only start tracking steps after user has done setup
    initBackground();
  }

  @override
  Widget build(BuildContext context) {
    const pageDecoration = const PageDecoration(
        titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w700),
        bodyTextStyle: TextStyle(fontSize: 20.0),
        descriptionPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
        pageColor: Color.fromARGB(255, 251, 249, 255),
        imagePadding: EdgeInsets.zero);

    return IntroductionScreen(
        pages: [
          PageViewModel(
              title: "Welcome",
              image: Image.asset("lib/images/IntroLogo.png", height: 350.0),
              body: "Swipe to set up",
              decoration: pageDecoration),
          PageViewModel(
              title: "Postcode",
              image: Center(
                  child: Image.asset("lib/images/IntroPostcode.png",
                      height: 270.0)),
              bodyWidget: (Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("What is the first half of your postcode?",
                        style: TextStyle(fontSize: 20.0),
                        textAlign: TextAlign.center),
                    TextField(
                      controller: postcodeController,
                      textAlign: TextAlign.center,
                      // https://github.com/flutter/flutter/issues/67236
                      maxLength: 4, // length of a postcode prefix
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Enter postcode here"),
                    ),
                  ])),
              decoration: pageDecoration),
          PageViewModel(
              title: "Support",
              image: Center(
                  child: Image.asset("lib/images/IntroSupport.png",
                      height: 270.0)),
              bodyWidget: (Column(children: <Widget>[
                Text("Where do you primarily go to find support?",
                    style: TextStyle(fontSize: 20.0),
                    textAlign: TextAlign.center),
                TextField(
                  controller: supportCodeController,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Enter support code here"),
                ),
              ])),
              decoration: pageDecoration),
        ],
        onDone: () => _onIntroEnd(context),
        showSkipButton: false,
        next: const Icon(Icons.arrow_forward,
            color: Color.fromARGB(255, 182, 125, 226)),
        done: const Text('Done',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color.fromARGB(255, 182, 125, 226))),
        dotsDecorator: const DotsDecorator(
            size: Size(10.0, 10.0),
            color: Color(0xFFBDBDBD),
            activeColor: Color.fromARGB(255, 0, 74, 173),
            activeSize: Size(22.0, 10.0),
            activeShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(25.0)))));
  }

  void dispose() {
    // need to dispose of [TextEditingController]
    postcodeController.dispose();
    supportCodeController.dispose();
    super.dispose();
  }
}
