// lib/tools/pdfmerge/pdf_merge_service.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/exception/pdf_combiner_exception.dart';
import 'models.dart';

class PdfMergeService {
  const PdfMergeService();

  Future<PdfMergeResult> merge({
    required List<PdfFileItem> items,
    required String outputName,
    String? outputPath,
  }) async {
    if (items.length < 2) {
      return PdfMergeResult.failure(errorKey: 'pdfmerge_error_min_files');
    }

    try {
      final List<MergeInput> inputs = <MergeInput>[];

      if (kIsWeb) {
        for (final PdfFileItem item in items) {
          if (item.bytes == null) {
            return PdfMergeResult.failure(
              errorKey: 'pdfmerge_error_missing_data',
              errorDetail: item.name,
            );
          }
          inputs.add(MergeInput.bytes(item.bytes!));
        }
      } else {
        for (final PdfFileItem item in items) {
          if (item.path == null || item.path!.isEmpty) {
            return PdfMergeResult.failure(
              errorKey: 'pdfmerge_error_missing_path',
              errorDetail: item.name,
            );
          }
          inputs.add(MergeInput.path(item.path!));
        }
      }

      final String target = outputPath ??
          '${Directory.systemTemp.path}/${_sanitize(outputName)}.pdf';

      final String resultPath = await PdfCombiner.mergeMultiplePDFs(
        inputs: inputs,
        outputPath: target,
      );

      if (kIsWeb) {
        final Uint8List bytes = await File(resultPath).readAsBytes();
        return PdfMergeResult.success(
          bytes: bytes,
          fileName: '${_sanitize(outputName)}.pdf',
        );
      }

      return PdfMergeResult.success(
        path: resultPath,
        fileName: '${_sanitize(outputName)}.pdf',
      );
    } on PdfCombinerException catch (e) {
      return PdfMergeResult.failure(
        errorKey: 'pdfmerge_error_merge_failed',
        errorDetail: e.message,
      );
    } catch (e) {
      return PdfMergeResult.failure(
        errorKey: 'pdfmerge_error_exception',
        errorDetail: e.toString(),
      );
    }
  }

  String _sanitize(String name) {
    final String trimmed = name.trim().replaceAll('.pdf', '');
    final String cleaned =
    trimmed.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return cleaned.isEmpty ? 'merged' : cleaned;
  }
}