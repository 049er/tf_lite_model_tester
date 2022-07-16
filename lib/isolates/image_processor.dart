import 'dart:developer';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:model_tester_app/classes/image_message.dart';
import 'package:model_tester_app/classes/image_processor_config.dart';
import 'package:model_tester_app/classes/painter_message.dart';
import 'dart:math' as math;

import 'package:model_tester_app/functions/coordinates_translator.dart';
import 'package:model_tester_app/model_testing/model_test_view.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:vector_math/vector_math_64.dart' as vm;

void imageProcessor(List init) {
  //Initiate
//[0] ID.
  SendPort sendPort = init[1]; //[1] SendPort.

  //2. ReceivePort.
  ReceivePort receivePort = ReceivePort();
  sendPort.send([
    'Sendport', //[0] Identifier.
    receivePort.sendPort, //[1] Sendport
  ]);

  //5. Spawn BarcodeScanner.
  BarcodeScanner barcodeScanner =
      GoogleMlKit.vision.barcodeScanner([BarcodeFormat.qrCode]);

  //6. Image Config
  InputImageData? inputImageData;
  Size? canvasSize;

  Interpreter? interpreter;
  void loadInterpreter() async {
    //Load Custom TfLite Model.
    String modelFile = modelName;
    interpreter = await Interpreter.fromAsset(modelFile);
    log('interpreter loaded');
  }

  loadInterpreter();

  void configureInputImageData(message) {
    //Decode Message.
    ImageProcessorConfig config = ImageProcessorConfig.fromMessage(message);
    //Configure InputImageData.
    inputImageData = InputImageData(
      size: config.absoluteSize,
      imageRotation: InputImageRotation.rotation90deg,
      inputImageFormat: config.inputImageFormat,
      planeData: null,
    );
    canvasSize = config.canvasSize;
  }

  void processImage(message) async {
    //1. Decode Message.
    ImageMessage imageDataMessage = ImageMessage.fromMessage(message);

    //2. Decode ImageBytes.
    InputImage inputImage = InputImage.fromBytes(
        bytes: imageDataMessage.bytes, inputImageData: inputImageData!);

    //3. Scan Image.
    final List<Barcode> barcodes =
        await barcodeScanner.processImage(inputImage);

    //4. Initiate Painter Message variables.
    List<BarcodeMessage> painterData = [];

    for (Barcode barcode in barcodes) {
      ///1. Caluclate barcode OnScreen CornerPoints.
      List<Offset> conrnerPoints = <Offset>[];
      List<math.Point<num>> cornerPoints = barcode.cornerPoints!;
      for (var point in cornerPoints) {
        double x = translateX(point.x.toDouble(), inputImageData!.imageRotation,
            canvasSize!, inputImageData!.size);
        double y = translateY(point.y.toDouble(), inputImageData!.imageRotation,
            canvasSize!, inputImageData!.size);

        conrnerPoints.add(Offset(x, y));
      }

      var input = [
        (cornerPoints[0].x).toDouble(),
        (cornerPoints[0].y).toDouble(),
        (cornerPoints[1].x).toDouble(),
        (cornerPoints[1].y).toDouble(),
        (cornerPoints[2].x).toDouble(),
        (cornerPoints[2].y).toDouble(),
        (cornerPoints[3].x).toDouble(),
        (cornerPoints[3].y).toDouble(),
      ];

      List output = List.filled(1 * 3, 0).reshape([1, 3]);
      interpreter!.run(input, output);

      BarcodeMessage barcodePainterData = BarcodeMessage(
        barcodeUID: barcode.displayValue!,
        conrnerPoints: conrnerPoints,
        angle: vm.Vector3(output[0][0], output[0][1], output[0][2]),
      );

      painterData.add(barcodePainterData);
    }

    PainterMesssage painterMessage = PainterMesssage(
      painterData: painterData,
    );

    sendPort.send(painterMessage.toMessage());
  }

  receivePort.listen((message) {
    if (message[0] == 'ImageProcessorConfig') {
      configureInputImageData(message);
    } else if (message[0] == 'ImageDataMessage') {
      processImage(message);
    }
  });
}
