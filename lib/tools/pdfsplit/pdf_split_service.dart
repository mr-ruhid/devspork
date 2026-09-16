// lib/tools/pdfsplit/pdf_split_service.dart

import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart' as p;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart';

import 'models.dart';

class PdfSplitService {
  const PdfSplitService();

  Future<SplitResult> split({
    required Uint8List pdfBytes,
    required List<int> selectedPages,
    required SplitMode mode,
    required String baseName,
    int dpi = 200,
  }) async {
    if (selectedPages.isEmpty) {
      return SplitResult(
        success: false,
        errorKey: 'pdfsplit_error_no_pages',
      );
    }

    PdfDocument? source;
    try {
      source = await PdfDocument.openData(pdfBytes);
      final int total = source.pagesCount;
      final List<int> valid = selectedPages
          .where((int p) => p >= 1 && p <= total)
          .toList()
        ..sort();

      if (valid.isEmpty) {
        return SplitResult(
          success: false,
          errorKey: 'pdfsplit_error_no_pages',
        );
      }

      final String safeBase = _sanitize(baseName);

      if (mode == SplitMode.extract) {
        final Uint8List? out = await _renderPagesToPdf(
          source: source,
          pages: valid,
          dpi: dpi,
        );
        if (out == null) {
          return SplitResult(
            success: false,
            errorKey: 'pdfsplit_error_render',
          );
        }
        return SplitResult(
          success: true,
          items: <SplitResultItem>[
            SplitResultItem(
              fileName: '$safeBase-extract.pdf',
              bytes: out,
              pageNumbers: valid,
            ),
          ],
        );
      }

      final List<SplitResultItem> items = <SplitResultItem>[];
      for (final int page in valid) {
        final Uint8List? out = await _renderPagesToPdf(
          source: source,
          pages: <int>[page],
          dpi: dpi,
        );
        if (out == null) continue;
        items.add(
          SplitResultItem(
            fileName: '$safeBase-page-$page.pdf',
            bytes: out,
            pageNumbers: <int>[page],
          ),
        );
      }

      if (items.isEmpty) {
        return SplitResult(
          success: false,
          errorKey: 'pdfsplit_error_render',
        );
      }

      return SplitResult(success: true, items: items);
    } catch (e) {
      return SplitResult(
        success: false,
        errorKey: 'pdfsplit_error_generic',
        errorDetail: e.toString(),
      );
    } finally {
      await source?.close();
    }
  }

  Future<Uint8List?> _renderPagesToPdf({
    required PdfDocument source,
    required List<int> pages,
    required int dpi,
  }) async {
    final double scale = dpi / 72.0;
    final pw.Document doc = pw.Document();

    for (final int pageNumber in pages) {
      final PdfPage page = await source.getPage(pageNumber);
      final int targetWidth = (page.width * scale).round();
      final int targetHeight = (page.height * scale).round();

      final PdfPageImage? rendered = await page.render(
        width: targetWidth.toDouble(),
        height: targetHeight.toDouble(),
        format: PdfPageImageFormat.png,
      );

      await page.close();

      if (rendered == null || rendered.bytes.isEmpty) continue;

      final Uint8List pngBytes = Uint8List.fromList(rendered.bytes);
      final img.Image? decoded = img.decodeImage(pngBytes);
      if (decoded == null) continue;

      final Uint8List jpegBytes = Uint8List.fromList(
        img.encodeJpg(decoded, quality: 92),
      );

      final pw.MemoryImage memImage = pw.MemoryImage(jpegBytes);

      doc.addPage(
        pw.Page(
          pageFormat: p.PdfPageFormat(
            page.width,
            page.height,
          ),
          margin: pw.EdgeInsets.zero,
          build: (pw.Context ctx) {
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Image(memImage, fit: pw.BoxFit.fill),
            );
          },
        ),
      );
    }

    if (doc.document.pdfPageList.pages.isEmpty) return null;
    return await doc.save();
  }

  String _sanitize(String name) {
    final String trimmed = name.trim().replaceAll('.pdf', '');
    final String cleaned =
    trimmed.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return cleaned.isEmpty ? 'output' : cleaned;
  }
}