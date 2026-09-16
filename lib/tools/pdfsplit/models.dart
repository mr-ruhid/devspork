// lib/tools/pdfsplit/models.dart

import 'dart:typed_data';

enum SplitMode { extract, splitEach }

class PickedPdf {
  PickedPdf({
    required this.name,
    required this.path,
    this.bytes,
    required this.size,
    required this.pageCount,
  });

  final String name;
  final String path;
  final Uint8List? bytes;
  final int size;
  final int pageCount;

  PickedPdf copyWithPageCount(int newPageCount) {
    return PickedPdf(
      name: name,
      path: path,
      bytes: bytes,
      size: size,
      pageCount: newPageCount,
    );
  }
}

class PageThumbnail {
  PageThumbnail({
    required this.pageNumber,
    required this.bytes,
    required this.width,
    required this.height,
  });

  final int pageNumber;
  final Uint8List bytes;
  final double width;
  final double height;
}

class PreviewResult {
  PreviewResult({
    required this.success,
    this.thumbnails = const <PageThumbnail>[],
    this.totalPages = 0,
    this.errorKey,
    this.errorDetail,
  });

  final bool success;
  final List<PageThumbnail> thumbnails;
  final int totalPages;
  final String? errorKey;
  final String? errorDetail;
}

class SplitResultItem {
  SplitResultItem({
    required this.fileName,
    required this.bytes,
    required this.pageNumbers,
  });

  final String fileName;
  final Uint8List bytes;
  final List<int> pageNumbers;
}

class SplitResult {
  SplitResult({
    required this.success,
    this.items = const <SplitResultItem>[],
    this.errorKey,
    this.errorDetail,
  });

  final bool success;
  final List<SplitResultItem> items;
  final String? errorKey;
  final String? errorDetail;
}