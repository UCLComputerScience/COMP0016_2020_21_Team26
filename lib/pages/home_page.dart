import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<SharedPreferences> _prefs;

  @override
  void initState() {
    super.initState();
    _prefs = SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: FutureBuilder(
      future: _prefs,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          SharedPreferences data = snapshot.data;
          return Text("Postcode: ${data.getString('postcode')}");
        } else if (snapshot.hasError) {
          return Text("Error: ${snapshot.error}");
        }
        return Text("Loading");
      },
    ));
  }
}
