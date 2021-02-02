import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nudge_me/model/friends_model.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class AddFriendPage extends StatefulWidget {
  /// outer scaffold needed to display snackbar in case error
  final ScaffoldState _scaffoldState;

  const AddFriendPage(this._scaffoldState);

  @override
  State<StatefulWidget> createState() => AddFriendPageState();
}

class AddFriendPageState extends State<AddFriendPage> {
  final _qrKey = GlobalKey(debugLabel: 'QR');
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  Barcode _result;
  QRViewController _controller;

  final _formKey = GlobalKey<FormState>();
  String _name;

  int _currentStep = 0;

  StepState _getQRState() =>
      _result == null ? StepState.editing : StepState.complete;

  @override
  void reassemble() {
    super.reassemble();
    // used to fix Flutter's hot reload:
    if (Platform.isAndroid) {
      _controller.pauseCamera();
    } else if (Platform.isIOS) {
      _controller.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    final _steps = [
      Step(
          title: Text("Scan their QR code"),
          subtitle: Text('Ask them to tap "My Identity"' +
              ' and point the camera at their identity code.'),
          content: Container(
            height: 400,
            child: QRView(
              key: _qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          state: _getQRState()),
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
                      _name = val;
                    });
                  },
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!_formKey.currentState.validate()) {
                      return;
                    }
                    _formKey.currentState.save();

                    final String scanned = _result.code;
                    final mysplit = scanned.indexOf('\n');
                    String identifier = scanned.substring(0, mysplit);
                    String publicKey = scanned.substring(mysplit + 1);

                    // TODO: maybe verify that user identifier exists before inserting
                    //       although this is mostly for if we allow string input
                    if (!await FriendDB().isIdentifierPresent(identifier)) {
                      setState(() {
                        FriendDB().insertWithData(
                          name: _name,
                          identifier: identifier,
                          publicKey: publicKey,
                          latestData: null,
                          read: null,
                        );
                      });
                    } else {
                      widget._scaffoldState.showSnackBar(SnackBar(
                        content: Text("This person has already been added."),
                      ));
                    }

                    Navigator.pop(context);
                  },
                  child: Text("Done"),
                ),
              ],
            ),
          )),
    ];
    final stepper = Stepper(
      steps: _steps,
      currentStep: _currentStep,
      controlsBuilder: _getControls,
    );

    return Scaffold(
      key: _scaffoldKey,
      body: SafeArea(
        child: stepper,
      ),
      appBar: AppBar(
        title: Text("Add Person"),
      ),
    );
  }

  Widget _getControls(BuildContext context,
      {void Function() onStepCancel, void Function() onStepContinue}) {
    return SizedBox();
  }

  void _onQRViewCreated(QRViewController controller) {
    this._controller = controller;
    controller.scannedDataStream.listen((scanData) {
      final String scanned = scanData.code;

      if (_validQRCode(scanned)) {
        setState(() {
          _result = scanData;
          controller?.dispose(); // dispose once scanned
          _currentStep = 1;
        });
      }
    });
  }

  bool _validQRCode(String data) {
    // maybe improve validation?
    return data.split('\n').length == 4;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
