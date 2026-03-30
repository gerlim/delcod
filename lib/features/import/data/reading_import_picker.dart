import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final readingImportPickerProvider = Provider<ReadingImportPicker>((ref) {
  return const FilePickerReadingImportPicker();
});

abstract class ReadingImportPicker {
  Future<PickedImportFile?> pickFile();
}

class FilePickerReadingImportPicker implements ReadingImportPicker {
  const FilePickerReadingImportPicker();

  @override
  Future<PickedImportFile?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'xlsx'],
      allowMultiple: false,
      withData: true,
    );

    final file = result?.files.single;
    final bytes = file?.bytes;
    if (file == null || bytes == null || bytes.isEmpty) {
      return null;
    }

    return PickedImportFile(
      name: file.name,
      bytes: bytes,
    );
  }
}

class PickedImportFile {
  const PickedImportFile({
    required this.name,
    required this.bytes,
  });

  final String name;
  final Uint8List bytes;
}
