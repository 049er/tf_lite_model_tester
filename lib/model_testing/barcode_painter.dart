import 'dart:ui';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:model_tester_app/classes/painter_message.dart';
import 'package:model_tester_app/constants/colors.dart';
import 'package:model_tester_app/functions/round_double.dart';

Offset? averageOffsetToBarcode;

class BarcodePainter extends CustomPainter {
  BarcodePainter(
      {required this.message, required this.angleX, required this.angleY});

  ///Message from isolate.
  final dynamic message;

  ///Phone angleX
  final double angleX;

  ///Phone angleY
  final double angleY;

  ///TODO: Add phone angleZ

  final Paint background = Paint()..color = const Color(0x99000000);
  Paint selectedBarcodeColor = paintEasy(barcodeFocusColor, 3.0);
  Paint defaultarcodeColor = paintEasy(barcodeDefaultColor, 3.0);

  @override
  void paint(Canvas canvas, Size size) {
    PainterMesssage painterMesssage = PainterMesssage.fromMessage(message);

    for (BarcodeMessage barcode in painterMesssage.painterData) {
      canvas.drawPoints(
        PointMode.polygon,
        barcode.conrnerPoints,
        selectedBarcodeColor,
      );

      final ParagraphBuilder builder = ParagraphBuilder(
        ParagraphStyle(
            textAlign: TextAlign.left,
            fontSize: 15,
            textDirection: TextDirection.ltr),
      );
      builder.pushStyle(
          ui.TextStyle(color: Colors.lightGreenAccent, background: background));
      builder.addText(
          'X: ${roundDouble(barcode.angle.x, 2)}\nY: ${roundDouble(barcode.angle.y, 2)}\nZ: ${roundDouble(barcode.angle.z, 2)}');
      builder.pop();

      canvas.drawParagraph(
          builder.build()
            ..layout(
              const ParagraphConstraints(
                width: 200,
              ),
            ),
          barcode.conrnerPoints[0]);
    }

    displayPhoneAngle(canvas, size);
  }

  void displayPhoneAngle(Canvas canvas, Size size) {
    final ParagraphBuilder builder = ParagraphBuilder(
      ParagraphStyle(
          textAlign: TextAlign.left,
          fontSize: 20,
          textDirection: TextDirection.ltr),
    );

    builder.pushStyle(
        ui.TextStyle(color: Colors.lightGreenAccent, background: background));
    builder.addText(
        'X: ${roundDouble(angleX, 2)}, Y: ${roundDouble(angleY, 2)},  Z: 0');
    builder.pop();

    canvas.drawParagraph(
      builder.build()
        ..layout(ParagraphConstraints(
          width: size.width,
        )),
      Offset(size.width / 4, 5),
    );
  }

  @override
  bool shouldRepaint(BarcodePainter oldDelegate) {
    return oldDelegate.message != message;
  }
}

Paint paintEasy(
  Color color,
  double strokeWidth,
) {
  var paint = Paint()
    ..color = color
    ..strokeWidth = strokeWidth;
  return paint;
}
