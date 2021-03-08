import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 'Support Code' section on Settings page opens this page
class ChangeSupportCode extends StatefulWidget {
  @override
  _ChangeSupportCodeState createState() => _ChangeSupportCodeState();
}

class _ChangeSupportCodeState extends State<ChangeSupportCode> {
  final _supportCodeKey = GlobalKey<
      FormState>(); //Used to verify that support code is not empty string

  /// Returns the [String] currentSupportCode stored in shared prefs database.
  Future<String> _getSupportCode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String currentSuppCode = prefs.getString('support_code');
    return currentSuppCode;
  }

  /// Replaces the support code stored in shared prefs database with [String] newSuppCode
  void _updateSupportCode(String newSuppCode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('support_code', newSuppCode.toUpperCase());
  }

  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Change Support Code")),
        body: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(height: 30),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text("Currently, your support code is: ",
                style: Theme.of(context).textTheme.subtitle1),
            FutureBuilder(
                future: _getSupportCode(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text(snapshot.data,
                        style: Theme.of(context).textTheme.bodyText1);
                  } else if (snapshot.hasError) {
                    print(snapshot.error);
                    return Text("Something went wrong...",
                        style: Theme.of(context).textTheme.bodyText1);
                  }
                  return CircularProgressIndicator();
                })
          ]),
          Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Text(
                "\nIf your support has changed, follow the following instructions to change it.\n",
                textAlign: TextAlign.center,
              )),
          Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Text(
                  "1.  Click inside the purple box and type in your new support code \n2.  Click the Change button\n",
                  textAlign: TextAlign.start)),
          SizedBox(height: 8),
          Container(
              child: Form(
                  key: _supportCodeKey,
                  child: TextFormField(
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      enabledBorder: const OutlineInputBorder(
                        borderSide: const BorderSide(
                            color: Color.fromARGB(255, 182, 125, 226),
                            width: 1.0),
                      ),
                    ),
                    validator: (text) {
                      if (text.length == 0) {
                        return "You must enter a support code";
                      }
                      return null;
                    },
                    onSaved: _updateSupportCode,
                  )),
              width: 200),
          ElevatedButton(
              style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                      Color.fromARGB(255, 0, 74, 173))),
              child: const Text('Change'),
              onPressed: () {
                if (_supportCodeKey.currentState.validate()) {
                  setState(() {
                    _supportCodeKey.currentState.save();
                  });
                }
              })
        ]));
  }
}
