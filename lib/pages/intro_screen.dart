import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nudge_me/main_pages.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:introduction_screen/introduction_screen.dart';

class IntroScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "Welcome", home: Scaffold(body: IntroScreenWidgets()));
  }
}

class IntroScreenWidgets extends StatefulWidget {
  @override
  _IntroScreenWidgetsState createState() => _IntroScreenWidgetsState();
}

enum SingingCharacter { one, two, three }

class _IntroScreenWidgetsState extends State<IntroScreenWidgets> {
  final introKey = GlobalKey<IntroductionScreenState>();
  String _currentPostcode = "Enter your postcode here";
  SingingCharacter _currentSupportCode = SingingCharacter.one;

  void _onIntroEnd(context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MainPages()),
    );
    _savePostcode(_currentPostcode);
    _saveSupportCode(_currentSupportCode.toString());
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
        key: introKey,
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
                        maxLength: 4,
                        textAlign: TextAlign.center,
                        onChanged: (text) {
                          setState(() {
                            _currentPostcode = text;
                          });
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r"[a-zA-Z0-9]+"))
                        ],
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Enter postcode here")),
                  ])),
              decoration: pageDecoration),
          PageViewModel(
              title: "Support",
              image: Center(
                  child: Image.asset("lib/images/IntroSupport.png",
                      height: 270.0)),
              bodyWidget: (Column(
                children: <Widget>[
                  Text("Where do you primarily go to find support?",
                      style: TextStyle(fontSize: 20.0),
                      textAlign: TextAlign.center),
                  RadioListTile<SingingCharacter>(
                    title: const Text('one'),
                    value: SingingCharacter.one,
                    groupValue: _currentSupportCode,
                    onChanged: (SingingCharacter value) {
                      setState(() {
                        _currentSupportCode = value;
                      });
                    },
                  ),
                  RadioListTile<SingingCharacter>(
                    title: const Text('two'),
                    value: SingingCharacter.two,
                    groupValue: _currentSupportCode,
                    onChanged: (SingingCharacter value) {
                      setState(() {
                        _currentSupportCode = value;
                      });
                    },
                  ),
                  RadioListTile<SingingCharacter>(
                    title: const Text('three'),
                    value: SingingCharacter.three,
                    groupValue: _currentSupportCode,
                    onChanged: (SingingCharacter value) {
                      setState(() {
                        _currentSupportCode = value;
                      });
                    },
                  ),
                ],
              )),
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

  void _savePostcode(String value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('postcode', value);
  }

  void _saveSupportCode(String value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('support_code', value);
  }
}
