// lib/tools/imagetopdf/models.dart

import 'dart:typed_data';

enum ConvertMode { imageToPdf, pdfToImage }

enum PageSizePreset { auto, a4, letter, legal }

enum FitMode { fit, fill, stretch }

enum PdfImageFormat { png, jpeg, webp }

class PickedImageItem {
  PickedImageItem({
    required this.id,
    required this.name,
    required this.bytes,
    required this.size,
  });

  final String id;
  final String name;
  final Uint8List bytes;
  final int size;
}

class PickedPdfItem {
  PickedPdfItem({
    required this.name,
    required this.path,
    this.bytes,
    required this.size,
  });

  final String name;
  final String path;
  final Uint8List? bytes;
  final int size;
}

class ImageToPdfConfig {
  ImageToPdfConfig({
    this.pageSize = PageSizePreset.a4,
    this.landscape = false,
    this.fitMode = FitMode.fit,
    this.margin = 0,
    this.quality = 90,
  });

  final PageSizePreset pageSize;
  final bool landscape;
  final FitMode fitMode;
  final double margin;
  final int quality;

  ImageToPdfConfig copyWith({
    PageSizePreset? pageSize,
    bool? landscape,
    FitMode? fitMode,
    double? margin,
    int? quality,
  }) {
    return ImageToPdfConfig(
      pageSize: pageSize ?? this.pageSize,
      landscape: landscape ?? this.landscape,
      fitMode: fitMode ?? this.fitMode,
      margin: margin ?? this.margin,
      quality: quality ?? this.quality,
    );
  }
}

class PdfToImageConfig {
  PdfToImageConfig({
    this.format = PdfImageFormat.png,
    this.dpi = 150,
    this.quality = 90,
    this.pageRange = '',
  });

  final PdfImageFormat format;
  final int dpi;
  final int quality;
  final String pageRange;

  PdfToImageConfig copyWith({
    PdfImageFormat? format,
    int? dpi,
    int? quality,
    String? pageRange,
  }) {
    return PdfToImageConfig(
      format: format ?? this.format,
      dpi: dpi ?? this.dpi,
      quality: quality ?? this.quality,
      pageRange: pageRange ?? this.pageRange,
    );
  }
}

class PdfPageItem {
  PdfPageItem({
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

class PdfToImageResult {
  PdfToImageResult({
    required this.success,
    this.pages = const <PdfPageItem>[],
    this.totalPages = 0,
    this.errorKey,
    this.errorDetail,
  });

  final bool success;
  final List<PdfPageItem> pages;
  final int totalPages;
  final String? errorKey;
  final String? errorDetail;
}

class ImageToPdfResult {
  ImageToPdfResult({
    required this.success,
    this.bytes,
    this.outputName,
    this.pageCount = 0,
    this.errorKey,
    this.errorDetail,
  });

  final bool success;
  final Uint8List? bytes;
  final String? outputName;
  final int pageCount;
  final String? errorKey;
  final String? errorDetail;
}