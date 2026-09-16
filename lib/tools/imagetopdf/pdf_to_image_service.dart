
// lib/tools/imagetopdf/pdf_to_image_service.dart

import 'dart:typed_data';

import 'package:pdfx/pdfx.dart';

import 'models.dart';

class PdfToImageService {
  const PdfToImageService();

  Future<PdfToImageResult> convert({
    required Uint8List pdfBytes,
    required PdfToImageConfig config,
  }) async {
    PdfDocument? document;
    try {
      document = await PdfDocument.openData(pdfBytes);
      final int totalPages = document.pagesCount;
      if (totalPages == 0) {
        return PdfToImageResult(
          success: false,
          errorKey: 'imagetopdf_error_pdf_empty',
        );
      }

      final List<int> selected = _parseRange(config.pageRange, totalPages);
      if (selected.isEmpty) {
        return PdfToImageResult(
          success: false,
          errorKey: 'imagetopdf_error_range_invalid',
        );
      }

      final double scale = config.dpi / 72.0;
      final List<PdfPageItem> pages = <PdfPageItem>[];

      for (final int pageNumber in selected) {
        final PdfPage page = await document.getPage(pageNumber);
        final int targetWidth = (page.width * scale).round();
        final int targetHeight = (page.height * scale).round();

        final PdfPageImage? rendered = await page.render(
          width: targetWidth.toDouble(),
          height: targetHeight.toDouble(),
          format: _resolveFormat(config.format),
          quality: config.quality,
        );

        await page.close();

        if (rendered == null || rendered.bytes.isEmpty) {
          return PdfToImageResult(
            success: false,
            errorKey: 'imagetopdf_error_render',
            errorDetail: 'page $pageNumber',
          );
        }

        pages.add(
          PdfPageItem(
            pageNumber: pageNumber,
            bytes: Uint8List.fromList(rendered.bytes),
            width: (rendered.width ?? targetWidth).toDouble(),
            height: (rendered.height ?? targetHeight).toDouble(),
          ),
        );
      }

      return PdfToImageResult(
        success: true,
        pages: pages,
        totalPages: totalPages,
      );
    } catch (e) {
      return PdfToImageResult(
        success: false,
        errorKey: 'imagetopdf_error_pdf_generic',
        errorDetail: e.toString(),
      );
    } finally {
      await document?.close();
    }
  }

  PdfPageImageFormat _resolveFormat(PdfImageFormat format) {
    switch (format) {
      case PdfImageFormat.png:
        return PdfPageImageFormat.png;
      case PdfImageFormat.jpeg:
        return PdfPageImageFormat.jpeg;
      case PdfImageFormat.webp:
        return PdfPageImageFormat.webp;
    }
  }

  List<int> _parseRange(String range, int total) {
    final String trimmed = range.trim();
    if (trimmed.isEmpty) {
      return List<int>.generate(total, (int i) => i + 1);
    }

    final Set<int> pages = <int>{};
    final List<String> parts = trimmed.split(',');

    for (final String raw in parts) {
      final String part = raw.trim();
      if (part.isEmpty) continue;

      if (part.contains('-')) {
        final List<String> bounds = part.split('-');
        if (bounds.length != 2) continue;
        final int? lo = int.tryParse(bounds[0].trim());
        final int? hi = int.tryParse(bounds[1].trim());
        if (lo == null || hi == null) continue;
        final int start = lo < 1 ? 1 : lo;
        final int end = hi > total ? total : hi;
        for (int i = start; i <= end; i++) {
          pages.add(i);
        }
      } else {
        final int? single = int.tryParse(part);
        if (single == null) continue;
        if (single >= 1 && single <= total) pages.add(single);
      }
    }

    final List<int> sorted = pages.toList()..sort();
    return sorted;
  }
}