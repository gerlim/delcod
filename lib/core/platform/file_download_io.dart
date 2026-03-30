import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<bool> downloadBytes({
  required Uint8List bytes,
  required String filename,
  required String mimeType,
}) async {
  final _ = mimeType;
  final outputPath = await FilePicker.platform.saveFile(
    dialogTitle: 'Salvar arquivo exportado',
    fileName: filename,
    bytes: bytes,
  );

  return outputPath != null && outputPath.isNotEmpty;
}
