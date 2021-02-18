import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nudge_me/crypto.dart';
import 'package:nudge_me/model/friends_model.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddFriendPage extends StatefulWidget {
  /// outer scaffold needed to display snackbar in case error
  final ScaffoldState _scaffoldState;
  final String identifier;
  final String pubKey;

  const AddFriendPage(this._scaffoldState, [this.identifier, this.pubKey]);

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

  int _currentStep;

  @override
  initState() {
    super.initState();
    // if identifier/pubKey is already provided, we skip the first step:
    _currentStep = widget.identifier == null ? 0 : 1;
  }

  StepState _getQRState() => _result == null && widget.identifier == null
      ? StepState.editing
      : StepState.complete;

  @override
  void reassemble() {
    super.reassemble();
    // used to fix Flutter's hot reload:
    if (Platform.isAndroid) {
      _controller?.pauseCamera();
    } else if (Platform.isIOS) {
      _controller?.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    final _steps = [
      Step(
          title: Text("Scan their QR code"),
          subtitle: Text('Ask them to tap "My Identity"' +
              ' and point the camera at their identity code.'),
          content: widget.identifier == null
              ? Container(
                  height: 400,
                  child: QRView(
                    key: _qrKey,
                    onQRViewCreated: _onQRViewCreated,
                  ),
                )
              : Text("QR not needed."),
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

                    String identifier, publicKey;
                    if (_result == null) {
                      identifier = widget.identifier;
                      publicKey = widget.pubKey;
                    } else {
                      final String scanned = _result.code;
                      final mysplit = scanned.indexOf('\n');
                      identifier = scanned.substring(0, mysplit);
                      publicKey = scanned.substring(mysplit + 1);
                    }

                    if (identifier.length == 0 || publicKey.length == 0) {
                      widget._scaffoldState.showSnackBar(SnackBar(
                        content: Text("Invalid QR code or URL."),
                      ));
                      return;
                    }

                    if (await Provider.of<FriendDB>(context, listen: false)
                        .isIdentifierPresent(identifier)) {
                      widget._scaffoldState.showSnackBar(SnackBar(
                        content: Text("This person has already been added."),
                      ));
                    } else if (identifier ==
                        await SharedPreferences.getInstance().then(
                            (value) => value.getString(USER_IDENTIFIER_KEY))) {
                      widget._scaffoldState.showSnackBar(SnackBar(
                        content: Text("You cannot add yourself."),
                      ));
                    } else {
                      Provider.of<FriendDB>(context, listen: false)
                          .insertWithData(
                        name: _name,
                        identifier: identifier,
                        publicKey: publicKey,
                        // could leave these out, but making them explicit means
                        // we can verify they are null in tests
                        latestData: null,
                        read: null,
                        currentStepsGoal: null,
                        sentActiveGoal: 0,
                        initialStepCount: null,
                      );
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
        title: Text("Add to Network"),
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
