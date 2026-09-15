import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'models.dart';

class ImageCompressor {
  ImageCompressor._();

  static Future<CompressResult> compressBytes({
    required Uint8List inputBytes,
    required String fileName,
    required ImageCompressConfig config,
  }) async {
    final int originalSize = inputBytes.length;

    if (originalSize == 0) {
      return CompressResult(
        originalName: fileName,
        error: 'empty_file',
      );
    }

    try {
      img.Image? decoded = img.decodeImage(inputBytes);

      if (decoded == null) {
        return CompressResult(
          originalName: fileName,
          originalSize: originalSize,
          error: 'decode_failed',
        );
      }

      if (!config.keepExif) {
        decoded.exif.clear();
      }

      if (config.rotate != 0) {
        decoded = img.copyRotate(decoded, angle: config.rotate);
      }

      if (config.minWidth > 0 &&
          config.minHeight > 0 &&
          (decoded.width > config.minWidth ||
              decoded.height > config.minHeight)) {
        final double widthRatio = decoded.width / config.minWidth;
        final double heightRatio = decoded.height / config.minHeight;
        final bool scaleByWidth = widthRatio >= heightRatio;

        decoded = img.copyResize(
          decoded,
          width: scaleByWidth ? config.minWidth : null,
          height: scaleByWidth ? null : config.minHeight,
          interpolation: img.Interpolation.average,
        );
      }

      final Uint8List finalResult;
      switch (config.format) {
        case ImageOutputFormat.png:
          finalResult = Uint8List.fromList(img.encodePng(decoded, level: 6));
          break;
        case ImageOutputFormat.jpeg:
          finalResult = Uint8List.fromList(
            img.encodeJpg(decoded, quality: config.quality),
          );
          break;
        case ImageOutputFormat.webp:
          finalResult = Uint8List.fromList(
            img.encodeWebP(decoded, quality: config.quality),
          );
          break;
      }

      return CompressResult(
        originalName: fileName,
        originalSize: originalSize,
        compressedSize: finalResult.length,
        bytes: finalResult,
      );
    } catch (e) {
      return CompressResult(
        originalName: fileName,
        originalSize: originalSize,
        error: e.toString(),
      );
    }
  }

  static String outputExtension(ImageOutputFormat format) {
    switch (format) {
      case ImageOutputFormat.jpeg:
        return 'jpg';
      case ImageOutputFormat.png:
        return 'png';
      case ImageOutputFormat.webp:
        return 'webp';
    }
  }

  static String buildOutputName(
      String originalName,
      ImageOutputFormat format,
      ) {
    final int dot = originalName.lastIndexOf('.');
    final String base =
    dot == -1 ? originalName : originalName.substring(0, dot);
    return '${base}_compressed.${outputExtension(format)}';
  }
}