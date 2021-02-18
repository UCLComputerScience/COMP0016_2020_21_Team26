import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangePostcode extends StatefulWidget {
  @override
  _ChangePostcodeState createState() => _ChangePostcodeState();
}

class _ChangePostcodeState extends State<ChangePostcode> {
  final _postcodeKey = GlobalKey<FormState>();

  Future<String> _getPostcode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userPostcode = prefs.getString('postcode');
    return userPostcode;
  }

  void _updatePostcode(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('postcode', value.toUpperCase());
  }

  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Change Postcode")),
        body: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Text(
                "\nIf your postcode has changed, follow the following instructions to change it.\n",
                textAlign: TextAlign.center,
              )),
          Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Text(
                  "1.  Click inside the purple box and type in your new postcode \n2.  Click the Change button\n",
                  textAlign: TextAlign.start)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text("Currently, your postcode is: ",
                style: Theme.of(context).textTheme.subtitle1),
            FutureBuilder(
                future: _getPostcode(),
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
          SizedBox(height: 8),
          Container(
              child: Form(
                  key: _postcodeKey,
                  child: TextFormField(
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      enabledBorder: const OutlineInputBorder(
                        borderSide: const BorderSide(
                            color: Color.fromARGB(255, 182, 125, 226),
                            width: 1.0),
                      ),
                    ),
                    maxLength: 4,
                    validator: (text) {
                      if (text.length == 0) {
                        return "You must enter a postcode prefix";
                      }
                      if (text.length < 2 || text.length > 4) {
                        return "Must be between 2 and 4 characters";
                      }
                      return null;
                    },
                    onSaved: _updatePostcode,
                  )),
              width: 200.0),
          ElevatedButton(
              style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                      Theme.of(context).primaryColor)),
              child: const Text('Change'),
              onPressed: () {
                if (_postcodeKey.currentState.validate()) {
                  setState(() {
                    _postcodeKey.currentState.save();
                  });
                }
              })
        ]));
  }
}
