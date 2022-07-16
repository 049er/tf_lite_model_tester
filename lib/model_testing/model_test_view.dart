import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:model_tester_app/model_testing/camera_view.dart';
import 'package:model_tester_app/functions/round_double.dart';
import 'package:model_tester_app/model_testing/painter.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:vector_math/vector_math_64.dart' as vm;
import 'dart:math' as m;

class ModelTestView extends StatefulWidget {
  const ModelTestView({Key? key}) : super(key: key);

  @override
  State<ModelTestView> createState() => _ModelTestViewState();
}

class _ModelTestViewState extends State<ModelTestView> {
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;
  Interpreter? interpreter;

  vm.Vector3 accelerometerEvent = vm.Vector3(0, 0, 0);
  vm.Vector3 zeroY = vm.Vector3(0, 1, 0);
  vm.Vector3 zeroX = vm.Vector3(1, 0, 0);

  double angleX = 0;
  double angleY = 0;
  double angleZ = 0;

  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  void dispose() {
    _canProcess = false;
    _barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CameraView(
      title: 'Barcode Scanner',
      customPaint: _customPaint,
      text: _text,
      onImage: (inputImage) {
        processImage(inputImage);
      },
    );
  }

  Future<void> processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });

    final barcodes = await _barcodeScanner.processImage(inputImage);

    if (inputImage.inputImageData?.size != null &&
        inputImage.inputImageData?.imageRotation != null) {
      List angles = [];

      for (final barcode in barcodes) {
        final cp = barcode.cornerPoints!;

        var input = [
          (cp[0].x).toDouble(),
          (cp[0].y).toDouble(),
          (cp[1].x).toDouble(),
          (cp[1].y).toDouble(),
          (cp[2].x).toDouble(),
          (cp[2].y).toDouble(),
          (cp[3].x).toDouble(),
          (cp[3].y).toDouble(),
        ];

        log(input.toString());

        List output = List.filled(1 * 3, 0).reshape([1, 3]);
        interpreter!.run(input, output);
        angles.add(output);
      }

      final painter = BarcodeDetectorPainter(
          barcodes,
          inputImage.inputImageData!.size,
          inputImage.inputImageData!.imageRotation,
          angles,
          angleX,
          angleY);

      _customPaint = CustomPaint(painter: painter);
    } else {
      String text = 'Barcodes found: ${barcodes.length}\n\n';
      for (final barcode in barcodes) {
        text += 'Barcode: ${barcode.rawValue}\n\n';
      }
      _text = text;
      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  //TODO: Implement Isolates

  void init() async {
    //Load Custom TfLite Model.
    const modelFile = 'angle_model_spicy.tflite';
    interpreter = await Interpreter.fromAsset(modelFile);
    log('interpreter loaded');

    //Initiate Acceletormeter.
    accelerometerEvents.listen((AccelerometerEvent event) {
      accelerometerEvent = vm.Vector3(event.x, event.y, event.z);
      double dotY = vm.dot3(zeroY, vm.Vector3(0, event.y, 0));
      double magAccY = accelerometerEvent.length;
      double magZeroY = zeroY.length;

      angleX = roundDouble(
          (90 - m.acos((dotY) / (magAccY * magZeroY)) * (180 / m.pi)), 2);

      double dotX = vm.dot3(zeroX, vm.Vector3(event.x, 0, 0));
      double magAccX = accelerometerEvent.length;
      double magZeroX = zeroX.length;

      angleY = roundDouble(
          (90 - m.acos((dotX) / (magAccX * magZeroX)) * (180 / m.pi)), 2);
    });
  }
}
