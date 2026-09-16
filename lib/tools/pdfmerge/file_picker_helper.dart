// lib/tools/pdfmerge/file_picker_helper.dart

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'models.dart';

class FilePickerHelper {
  FilePickerHelper._();

  static int _counter = 0;

  static String _nextId() {
    _counter++;
    return 'pdf_${DateTime.now().microsecondsSinceEpoch}_$_counter';
  }

  static Future<List<PdfFileItem>> pickPdfs() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['pdf'],
      allowMultiple: true,
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) {
      return <PdfFileItem>[];
    }
    final List<PdfFileItem> items = <PdfFileItem>[];
    for (final PlatformFile file in result.files) {
      final Uint8List? bytes = file.bytes;
      items.add(
        PdfFileItem(
          id: _nextId(),
          name: file.name,
          path: kIsWeb ? null : file.path,
          bytes: bytes,
          size: file.size,
        ),
      );
    }
    return items;
  }

  static Future<String?> pickSaveLocation({
    required String suggestedName,
  }) async {
    if (kIsWeb) return null;
    final String? output = await FilePicker.platform.saveFile(
      dialogTitle: suggestedName,
      fileName: suggestedName,
      type: FileType.custom,
      allowedExtensions: <String>['pdf'],
    );
    return output;
  }

  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}