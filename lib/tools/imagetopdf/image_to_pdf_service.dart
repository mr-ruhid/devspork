
// lib/tools/imagetopdf/image_to_pdf_service.dart

import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'models.dart';

class ImageToPdfService {
  const ImageToPdfService();

  Future<ImageToPdfResult> convert({
    required List<PickedImageItem> items,
    required ImageToPdfConfig config,
    required String outputName,
  }) async {
    if (items.isEmpty) {
      return ImageToPdfResult(
        success: false,
        errorKey: 'imagetopdf_error_no_images',
      );
    }

    try {
      final pw.Document doc = pw.Document();

      for (final PickedImageItem item in items) {
        final img.Image? decoded = img.decodeImage(item.bytes);
        if (decoded == null) {
          return ImageToPdfResult(
            success: false,
            errorKey: 'imagetopdf_error_decode',
            errorDetail: item.name,
          );
        }

        final Uint8List encoded = _reencode(decoded, config.quality);
        final pw.MemoryImage memImage = pw.MemoryImage(encoded);
        final PdfPageFormat pageFormat = _resolvePageFormat(
          config: config,
          imageWidth: decoded.width.toDouble(),
          imageHeight: decoded.height.toDouble(),
        );

        doc.addPage(
          pw.Page(
            pageFormat: pageFormat,
            margin: pw.EdgeInsets.all(config.margin),
            build: (pw.Context ctx) {
              return pw.Center(
                child: _buildImage(memImage, config.fitMode),
              );
            },
          ),
        );
      }

      final Uint8List bytes = await doc.save();
      final String safeName = _sanitize(outputName);

      return ImageToPdfResult(
        success: true,
        bytes: bytes,
        outputName: '$safeName.pdf',
        pageCount: items.length,
      );
    } catch (e) {
      return ImageToPdfResult(
        success: false,
        errorKey: 'imagetopdf_error_generic',
        errorDetail: e.toString(),
      );
    }
  }

  Uint8List _reencode(img.Image decoded, int quality) {
    final int q = quality.clamp(10, 100);
    return Uint8List.fromList(img.encodeJpg(decoded, quality: q));
  }

  pw.Widget _buildImage(pw.MemoryImage image, FitMode mode) {
    switch (mode) {
      case FitMode.fit:
        return pw.Image(image, fit: pw.BoxFit.contain);
      case FitMode.fill:
        return pw.Image(image, fit: pw.BoxFit.cover);
      case FitMode.stretch:
        return pw.Image(image, fit: pw.BoxFit.fill);
    }
  }

  PdfPageFormat _resolvePageFormat({
    required ImageToPdfConfig config,
    required double imageWidth,
    required double imageHeight,
  }) {
    PdfPageFormat format;
    switch (config.pageSize) {
      case PageSizePreset.a4:
        format = PdfPageFormat.a4;
        break;
      case PageSizePreset.letter:
        format = PdfPageFormat.letter;
        break;
      case PageSizePreset.legal:
        format = PdfPageFormat.legal;
        break;
      case PageSizePreset.auto:
        format = PdfPageFormat(
          imageWidth + config.margin * 2,
          imageHeight + config.margin * 2,
        );
        break;
    }
    if (config.landscape && config.pageSize != PageSizePreset.auto) {
      format = format.landscape;
    }
    return format;
  }

  String _sanitize(String name) {
    final String trimmed = name.trim().replaceAll('.pdf', '');
    final String cleaned = trimmed.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return cleaned.isEmpty ? 'output' : cleaned;
  }
}