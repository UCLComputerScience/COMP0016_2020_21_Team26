import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

/// [StatelessWidget] that can share a widget as a PDF
class ShareButton extends StatelessWidget {
  final GlobalKey _printKey;
  final String _filename;

  /// Uses a [GlobalKey] to find the widget to be shared
  const ShareButton(this._printKey, this._filename);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
        onPressed: _share,
        child: Icon(
          Icons.share,
          color: Colors.blueAccent,
          size: 40,
        ));
  }

  /// will get an [ImageProvider] for the widget associated with _printKey
  Future<ImageProvider> _fromWidgetKey() async {
    final RenderRepaintBoundary wrappedWidget =
        _printKey.currentContext.findRenderObject();
    final img = await wrappedWidget.toImage();
    // needs to be a PNG format, otherwise the conversion won't work
    final byteData = await img.toByteData(format: ImageByteFormat.png);
    return MemoryImage(byteData.buffer.asUint8List());
  }

  void _share() async {
    final doc = pw.Document();
    final ImageProvider flutterImg = await _fromWidgetKey();
    final pw.ImageProvider img = await flutterImageProvider(flutterImg);

    doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) => pw.Center(child: pw.Image.provider(img))));

    // opens the share panel
    await Printing.sharePdf(bytes: doc.save(), filename: _filename);
  }
}
