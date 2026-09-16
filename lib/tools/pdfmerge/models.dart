// lib/tools/pdfmerge/models.dart

import 'dart:typed_data';

class PdfFileItem {
  PdfFileItem({
    required this.id,
    required this.name,
    this.path,
    this.bytes,
    required this.size,
  });

  final String id;
  final String name;
  final String? path;
  final Uint8List? bytes;
  final int size;

  PdfFileItem copyWith({
    String? id,
    String? name,
    String? path,
    Uint8List? bytes,
    int? size,
  }) {
    return PdfFileItem(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      bytes: bytes ?? this.bytes,
      size: size ?? this.size,
    );
  }
}

class PdfMergeResult {
  PdfMergeResult({
    required this.success,
    this.path,
    this.bytes,
    this.fileName,
    this.errorKey,
    this.errorDetail,
  });

  final bool success;
  final String? path;
  final Uint8List? bytes;
  final String? fileName;
  final String? errorKey;
  final String? errorDetail;

  factory PdfMergeResult.success({
    String? path,
    Uint8List? bytes,
    required String fileName,
  }) {
    return PdfMergeResult(
      success: true,
      path: path,
      bytes: bytes,
      fileName: fileName,
    );
  }

  factory PdfMergeResult.failure({
    required String errorKey,
    String? errorDetail,
  }) {
    return PdfMergeResult(
      success: false,
      errorKey: errorKey,
      errorDetail: errorDetail,
    );
  }
}