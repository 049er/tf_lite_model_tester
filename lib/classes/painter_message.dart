import 'dart:ui';
// ignore: depend_on_referenced_packages
import 'package:vector_math/vector_math_64.dart' as vm;

///Message sent to the painter.
class PainterMesssage {
  PainterMesssage({
    required this.painterData,
  });

  String identifier = 'painterMessage';

  List<BarcodeMessage> painterData;

  List toMessage() {
    List messagePainterData = painterData.map((e) => e.toMessage()).toList();
    return [
      identifier,
      messagePainterData,
    ];
  }

  factory PainterMesssage.fromMessage(message) {
    List messagePainterData = message[1];
    return PainterMesssage(
      painterData:
          messagePainterData.map((e) => BarcodeMessage.fromMessage(e)).toList(),
    );
  }

  @override
  String toString() {
    return '''_______________________________________________
    identifier: $identifier
    painterData: ${painterData.length}
_______________________________________________''';
  }
}

///Passed to the painter for drawing
class BarcodeMessage {
  BarcodeMessage({
    required this.barcodeUID,
    required this.conrnerPoints,
    required this.angle,
  });
  final String barcodeUID;
  List<Offset> conrnerPoints;
  vm.Vector3 angle;

  List toMessage() {
    return [
      barcodeUID, //[0]
      [
        conrnerPoints[0].dx,
        conrnerPoints[0].dy,
        conrnerPoints[1].dx,
        conrnerPoints[1].dy,
        conrnerPoints[2].dx,
        conrnerPoints[2].dy,
        conrnerPoints[3].dx,
        conrnerPoints[3].dy,
      ], //[1] cornerPoints
      [angle.x, angle.y, angle.z], //[2] angle
    ];
  }

  factory BarcodeMessage.fromMessage(List message) {
    List<Offset> cornerPoints = [
      Offset(message[1][0], message[1][1]),
      Offset(message[1][2], message[1][3]),
      Offset(message[1][4], message[1][5]),
      Offset(message[1][6], message[1][7]),
      Offset(message[1][0], message[1][1]),
    ];

    vm.Vector3 angle = vm.Vector3(
      message[2][0] as double,
      message[2][1] as double,
      message[2][2] as double,
    );

    return BarcodeMessage(
      barcodeUID: message[0],
      conrnerPoints: cornerPoints,
      angle: angle,
    );
  }
}
