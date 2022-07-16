// ignore_for_file: depend_on_referenced_packages

import 'dart:isolate';
import 'dart:typed_data';

///This is the
class ImageMessage {
  ImageMessage({
    required this.bytes,
    required this.timestamp,
  });

  ///Identifier. [String]
  final String identifier = 'ImageDataMessage';

  ///Image Bytes. [Uint8List]
  final Uint8List bytes;

  ///Timestamp. [int]
  final int timestamp;

  List toMessage() {
    return [
      identifier, // Identifier [0]
      TransferableTypedData.fromList([bytes]), //Bytes [1]
      timestamp, //Timestamp [2]
    ];
  }

  factory ImageMessage.fromMessage(message) {
    return ImageMessage(
        bytes:
            (message[1] as TransferableTypedData).materialize().asUint8List(),
        timestamp: message[2]);
  }
}
