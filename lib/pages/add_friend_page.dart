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
    return Scaffold(
      body: Form(
        key: _formKey,
        child: SafeArea(
          child: Column(
            children: [
              Visibility(
                child: Text('Scan Friend\'s QR Code'),
                visible: result == null,
              ),
              Expanded(
                child: QRView(
                  key: _qrKey,
                  onQRViewCreated: _onQRViewCreated,
                ),
                flex: 3,
              ),
              Text("Name"),
              TextFormField(
                onSaved: (val) {
                  setState(() {
                    name = val;
                  });
                },
              ),
              ElevatedButton(
                onPressed: () {
                  _formKey.currentState.save();
                  final String scanned = result.code;
                  final mysplit = scanned.indexOf('\n');
                  String identifier = scanned.substring(0, mysplit);
                  String publicKey = scanned.substring(mysplit + 1);
                  // TODO: verify that user identifier exists before inserting
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
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
