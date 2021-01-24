import 'package:flutter/material.dart';
import 'package:nudge_me/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final showKeyButton = ElevatedButton(
      onPressed: () => showDialog(
          builder: (context) => AlertDialog(
                title: Text("Public Key"),
                content: FutureBuilder(
                  future: SharedPreferences.getInstance()
                      .then((prefs) => prefs.getString(RSA_PUBLIC_PEM_KEY)),
                  builder: (context, data) {
                    if (data.hasData) {
                      return SelectableText(data.data);
                    }
                    return LinearProgressIndicator();
                  },
                ),
                actions: [
                  TextButton(
                    child: Text('Done'),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
          context: context),
      child: Text("Show Key"),
    );
    return Scaffold(
      body: Column(
        children: [
          showKeyButton,
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }
}
