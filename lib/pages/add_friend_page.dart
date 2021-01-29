import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nudge_me/model/friends_model.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class AddFriendPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => AddFriendPageState();
}

class AddFriendPageState extends State<AddFriendPage> {
  final _qrKey = GlobalKey(debugLabel: 'QR');
  Barcode result;
  QRViewController controller;

  final _formKey = GlobalKey<FormState>();
  String name;

  List<Step> steps;
  // TODO

  @override
  void initState() {
    super.initState();
    steps = [
      Step(
          title: Text("Scan their QR code"),
          content: Container(
            height: 400,
            child: QRView(
              key: _qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          )),
      Step(
          title: Text("Enter their name"),
          content: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  validator: (val) => val.length == 0 ? "Required." : null,
                  onSaved: (val) {
                    setState(() {
                      name = val;
                    });
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    if (!_formKey.currentState.validate()) {
                      return;
                    }
                    _formKey.currentState.save();

                    final String scanned = result.code;
                    final mysplit = scanned.indexOf('\n');
                    String identifier = scanned.substring(0, mysplit);
                    String publicKey = scanned.substring(mysplit + 1);

                    // TODO: maybe verify that user identifier exists before inserting
                    //       although this is mostly for if we allow string input
                    setState(() {
                      FriendDB().insertWithData(
                          name: name,
                          identifier: identifier,
                          publicKey: publicKey,
                          latestData: null);
                    });
                    Navigator.pop(context);
                  },
                  child: Text("Done"),
                ),
              ],
            ),
          )),
    ];
  }

  @override
  void reassemble() {
    super.reassemble();
    // used to fix Flutter's hot reload:
    if (Platform.isAndroid) {
      controller.pauseCamera();
    } else if (Platform.isIOS) {
      controller.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepper = Stepper(
      steps: steps,
    );

    return Scaffold(
      body: SafeArea(
        child: stepper,
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      final String scanned = result.code;
      final mysplit = scanned.indexOf('\n');
      String identifier = scanned.substring(0, mysplit);

      if (await FriendDB().isIdentifierPresent(identifier)) {
        // don't save result if user was already added
        Scaffold.of(context).showSnackBar(SnackBar(
          content: Text("Already added user."),
        ));
      } else if (_validQRCode(scanned)) {
        setState(() {
          result = scanData;
        });
      }
    });
  }

  bool _validQRCode(String data) {
    // TODO
    return true;
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
