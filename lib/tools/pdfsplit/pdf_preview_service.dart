
// lib/tools/pdfsplit/pdf_preview_service.dart

import 'dart:typed_data';

import 'package:pdfx/pdfx.dart';

import 'models.dart';

class PdfPreviewService {
  const PdfPreviewService();

  Future<PreviewResult> generateThumbnails({
    required Uint8List pdfBytes,
    int thumbnailWidth = 320,
  }) async {
    PdfDocument? document;
    try {
      document = await PdfDocument.openData(pdfBytes);
      final int total = document.pagesCount;
      if (total == 0) {
        return PreviewResult(
          success: false,
          errorKey: 'pdfsplit_error_pdf_empty',
        );
      }

      final List<PageThumbnail> thumbnails = <PageThumbnail>[];

      for (int i = 1; i <= total; i++) {
        final PdfPage page = await document.getPage(i);
        final double ratio = page.height / page.width;
        final int targetWidth = thumbnailWidth;
        final int targetHeight = (targetWidth * ratio).round();

        final PdfPageImage? rendered = await page.render(
          width: targetWidth.toDouble(),
          height: targetHeight.toDouble(),
          format: PdfPageImageFormat.png,
        );

        await page.close();

        if (rendered == null || rendered.bytes.isEmpty) continue;

        thumbnails.add(
          PageThumbnail(
            pageNumber: i,
            bytes: Uint8List.fromList(rendered.bytes),
            width: (rendered.width ?? targetWidth).toDouble(),
            height: (rendered.height ?? targetHeight).toDouble(),
          ),
        );
      }

      return PreviewResult(
        success: true,
        thumbnails: thumbnails,
        totalPages: total,
      );
    } catch (e) {
      return PreviewResult(
        success: false,
        errorKey: 'pdfsplit_error_preview',
        errorDetail: e.toString(),
      );
    } finally {
      await document?.close();
    }
  }
}