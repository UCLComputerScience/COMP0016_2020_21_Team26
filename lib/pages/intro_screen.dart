import 'package:flutter/material.dart';
import 'package:nudge_me/main_pages.dart';

class IntroScreen extends StatefulWidget {
  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          body: Column(
        children: [
          Text(
            "NudgeMe",
            style: TextStyle(fontSize: 25.0),
          ),
          Text("Welcome, let's get you started:"),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                      hintText: "Enter your postcode prefix"),
                  validator: (value) {
                    // TODO: could improve validation
                    if (value.length == 0 || value.length > 4) {
                      return "The postcode prefix is the first part";
                    }
                    return null;
                  },
                  onSaved: (value) {
                    // TODO: save postcode
                  }
                ),

                TextFormField(
                  decoration: const InputDecoration(
                      hintText: "Enter your support code"),
                  validator: (value) => null, // NOTE: I assume this is optional
                  onSaved: (value) {
                    // TODO: save support code
                  },
                ),

                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState.validate()) {
                      _formKey.currentState.save();
                      Navigator.pushReplacement( // switch to main app
                        context,
                        MaterialPageRoute(builder: (context) => MainPages())
                      );
                    }
                  },
                  child: Text("Submit"),
                )
              ],
            ),
          )
        ],
      )),
    );
  }
}
