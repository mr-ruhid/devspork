import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_compress_plus/image_compress_plus.dart';

import 'models.dart';

class ImageCompressor {
  ImageCompressor._();

  static const Set<String> supportedExtensions = <String>{
    'jpg',
    'jpeg',
    'jpe',
    'jfif',
    'png',
    'webp',
    'heic',
    'heif',
    'bmp',
    'gif',
    'tif',
    'tiff',
    'ico',
  };

  static const Set<String> supportedMimeTypes = <String>{
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
    'image/heic',
    'image/heif',
    'image/bmp',
    'image/gif',
    'image/tiff',
    'image/x-icon',
  };

  static bool isSupportedExtension(String name) {
    final int dot = name.lastIndexOf('.');
    if (dot == -1) return false;
    final String ext = name.substring(dot + 1).toLowerCase();
    return supportedExtensions.contains(ext);
  }

  static bool isSupportedMime(String? mime) {
    if (mime == null) return false;
    return supportedMimeTypes.contains(mime.toLowerCase());
  }

  static String extensionOf(String name) {
    final int dot = name.lastIndexOf('.');
    if (dot == -1) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  static bool _isNativeSupportedFormat(ImageOutputFormat format) {
    switch (format) {
      case ImageOutputFormat.jpeg:
      case ImageOutputFormat.png:
      case ImageOutputFormat.webp:
        return true;
      case ImageOutputFormat.heic:
        return false;
    }
  }

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
      final Uint8List? compressed = await _compressWithNative(
        bytes: inputBytes,
        config: config,
      );

      if (compressed != null && compressed.isNotEmpty) {
        return CompressResult(
          originalName: fileName,
          originalSize: originalSize,
          compressedSize: compressed.length,
          bytes: compressed,
        );
      }

      final Uint8List fallback = await _compressWithPureDart(
        bytes: inputBytes,
        config: config,
      );

      return CompressResult(
        originalName: fileName,
        originalSize: originalSize,
        compressedSize: fallback.length,
        bytes: fallback,
      );
    } catch (e) {
      try {
        final Uint8List fallback = await _compressWithPureDart(
          bytes: inputBytes,
          config: config,
        );
        return CompressResult(
          originalName: fileName,
          originalSize: originalSize,
          compressedSize: fallback.length,
          bytes: fallback,
        );
      } catch (e2) {
        return CompressResult(
          originalName: fileName,
          originalSize: originalSize,
          error: e2.toString(),
        );
      }
    }
  }

  static Future<Uint8List?> _compressWithNative({
    required Uint8List bytes,
    required ImageCompressConfig config,
  }) async {
    if (!_isNativeSupportedFormat(config.format)) return null;

    final CompressFormat format = _nativeFormat(config.format);

    try {
      final Uint8List result = await ImageCompressPlus.compressWithList(
        bytes,
        quality: config.quality,
        format: format,
        minWidth: config.minWidth,
        minHeight: config.minHeight,
        rotate: config.rotate,
        keepExif: config.keepExif,
      );
      return result;
    } catch (_) {
      return null;
    }
  }

  static CompressFormat _nativeFormat(ImageOutputFormat format) {
    switch (format) {
      case ImageOutputFormat.jpeg:
        return CompressFormat.jpeg;
      case ImageOutputFormat.png:
        return CompressFormat.png;
      case ImageOutputFormat.webp:
        return CompressFormat.webp;
      case ImageOutputFormat.heic:
        return CompressFormat.heic;
    }
  }

  static Future<Uint8List> _compressWithPureDart({
    required Uint8List bytes,
    required ImageCompressConfig config,
  }) async {
    img.Image? decoded = img.decodeImage(bytes);

    if (decoded == null) {
      throw Exception('decode_failed');
    }

    if (config.rotate != 0) {
      decoded = img.copyRotate(decoded, angle: config.rotate);
    }

    if (config.minWidth > 0 &&
        config.minHeight > 0 &&
        (decoded.width > config.minWidth ||
            decoded.height > config.minHeight)) {
      decoded = img.copyResize(
        decoded,
        width: decoded.width > config.minWidth ? config.minWidth : null,
        height: decoded.height > config.minHeight ? config.minHeight : null,
        interpolation: img.Interpolation.average,
      );
    }

    Uint8List result;

    switch (config.format) {
      case ImageOutputFormat.png:
        result = Uint8List.fromList(img.encodePng(decoded, level: 6));
        break;
      case ImageOutputFormat.jpeg:
      case ImageOutputFormat.webp:
      case ImageOutputFormat.heic:
        result = Uint8List.fromList(
          img.encodeJpg(decoded, quality: config.quality),
        );
        break;
    }

    return result;
  }

  static String outputExtension(ImageOutputFormat format) {
    switch (format) {
      case ImageOutputFormat.jpeg:
        return 'jpg';
      case ImageOutputFormat.png:
        return 'png';
      case ImageOutputFormat.webp:
        return 'webp';
      case ImageOutputFormat.heic:
        return 'heic';
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