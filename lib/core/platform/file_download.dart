import 'dart:typed_data';

import 'file_download_stub.dart'
    if (dart.library.io) 'file_download_io.dart'
    if (dart.library.html) 'file_download_web.dart' as file_download;

Future<bool> downloadBytes({
  required Uint8List bytes,
  required String filename,
  required String mimeType,
}) {
  return file_download.downloadBytes(
    bytes: bytes,
    filename: filename,
    mimeType: mimeType,
  );
}
