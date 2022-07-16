import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:model_tester_app/classes/image_message.dart';
import 'package:model_tester_app/classes/image_processor_config.dart';
import 'package:model_tester_app/model_testing/camera_view.dart';
import 'package:model_tester_app/functions/round_double.dart';
import 'package:model_tester_app/isolates/image_processor.dart';
import 'package:model_tester_app/model_testing/barcode_painter.dart';
import 'package:sensors_plus/sensors_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:vector_math/vector_math_64.dart' as vm;
import 'dart:math' as m;
import 'dart:isolate';
import 'package:flutter_isolate/flutter_isolate.dart';

//ImageProcessor Counter.
int counter = 0;
String modelName = 'angle_model_spicy.tflite';

class ModelTestView extends StatefulWidget {
  const ModelTestView({Key? key}) : super(key: key);

  @override
  State<ModelTestView> createState() => _ModelTestViewState();
}

class _ModelTestViewState extends State<ModelTestView> {
  //UI-Ports (multiple-ports are snappier)
  ReceivePort uiPort1 = ReceivePort('uiPort1'); //ImageProcessor
  ReceivePort uiPort2 = ReceivePort('uiPort2'); //ImageProcessor

  //Isolate-Ports
  SendPort? imageProcessor1;
  SendPort? imageProcessor2;

  bool hasConfiguredIPs = false;

  final BarcodeScanner _barcodeScanner = BarcodeScanner();

  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;

  vm.Vector3 accelerometerEvent = vm.Vector3(0, 0, 0);
  vm.Vector3 zeroY = vm.Vector3(0, 1, 0);
  vm.Vector3 zeroX = vm.Vector3(1, 0, 0);

  double angleX = 0;
  double angleY = 0;
  double angleZ = 0;

  @override
  void initState() {
    initiate();
    super.initState();
  }

  @override
  void dispose() {
    _barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CameraView(
          title: 'Barcode Scanner',
          customPaint: _customPaint,
          text: _text,
          onImage: (inputImage) {
            if (hasConfiguredIPs == false) {
              configureImageProcessors(inputImage);
            } else {
              sendImageDataMessage(inputImage);
            }
          },
        ),
        Visibility(
          visible: imageProcessor1 == null && imageProcessor2 == null,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ],
    );
  }

  ///Initiate accelerometer && isolates.
  void initiate() async {
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

    //Spawn Isolates
    FlutterIsolate.spawn(
      imageProcessor,
      [
        1, //[0] ID
        uiPort1.sendPort, //[1] SendPort
      ],
    );

    FlutterIsolate.spawn(
      imageProcessor,
      [
        2, //[0] ID
        uiPort2.sendPort, //[1] SendPort
      ],
    );

    uiPort1.listen((message) {
      if (message[0] == 'Sendport') {
        imageProcessor1 = message[1];
        log('UI: ImageProcessor1 Port Set');
      } else if (message[0] == 'painterMessage') {
        drawImage(message);
      }
    });

    uiPort2.listen((message) {
      if (message[0] == 'Sendport') {
        imageProcessor2 = message[1];
        log('UI: ImageProcessor2 Port Set');
      } else if (message[0] == 'painterMessage') {
        drawImage(message);
      }
    });
  }

  //Draw on canvas from barcode message.
  void drawImage(message) {
    log('drawing');
    if (_isBusy) return;
    _isBusy = true;

    final painter = BarcodePainter(
      message: message,
      angleX: angleX,
      angleY: angleY,
    );

    _customPaint = CustomPaint(painter: painter);

    if (mounted) {
      setState(() {
        _isBusy = false;
      });
    }
  }

  ///Configures the ImageProcessor(s) so they can receive ImageBytes.
  void configureImageProcessors(InputImage inputImage) {
    if (imageProcessor1 != null && imageProcessor2 != null) {
      //1. Abosulte Image Size.
      Size absoluteSize = inputImage.inputImageData!.size;

      //2. Canvas Size.
      Size canvasSize = Size(
          MediaQuery.of(context).size.width,
          MediaQuery.of(context).size.height -
              kToolbarHeight -
              MediaQuery.of(context).padding.top);

      //3. InputImageFormat.
      InputImageFormat inputImageFormat =
          inputImage.inputImageData!.inputImageFormat;

      //4. Compile ImageProcessorConfig.
      ImageProcessorConfig config = ImageProcessorConfig(
        absoluteSize: absoluteSize,
        canvasSize: canvasSize,
        inputImageFormat: inputImageFormat,
      );

      //5. Send Config(s).
      imageProcessor1!.send(config.toMessage());
      imageProcessor2!.send(config.toMessage());

      setState(() {
        hasConfiguredIPs = true;
      });
    }
  }

  ///Sends ImageData to the ImageProcessor(s)
  void sendImageDataMessage(InputImage inputImage) {
    ImageMessage imageDataMessage = ImageMessage(
      bytes: inputImage.bytes!,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    //Send Data.
    if (counter == 0) {
      imageProcessor1!.send(imageDataMessage.toMessage());
    } else if (counter == 3) {
      imageProcessor2!.send(imageDataMessage.toMessage());
    }

    counter++;
    if (mounted && counter == 6) {
      setState(() {
        counter = 0;
      });
    }
  }
}
