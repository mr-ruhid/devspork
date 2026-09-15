import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'models.dart';

class ImageConverter {
  ImageConverter._();

  static bool isSupportedExtension(String name) {
    final int dot = name.lastIndexOf('.');
    if (dot == -1) return false;
    final String ext = name.substring(dot + 1).toLowerCase();
    return ImageConvertConfig.inputExtensions.contains(ext);
  }

  static String extensionOf(String name) {
    final int dot = name.lastIndexOf('.');
    if (dot == -1) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  static String buildOutputName(
      String originalName,
      ImageOutputFormat format,
      ) {
    final int dot = originalName.lastIndexOf('.');
    final String base =
    dot == -1 ? originalName : originalName.substring(0, dot);
    final String ext = ImageConvertConfig.extensionFor(format);
    return '${base}_converted.$ext';
  }

  static Future<ConvertResult> convert({
    required Uint8List inputBytes,
    required String fileName,
    required ImageConvertConfig config,
  }) async {
    final int originalSize = inputBytes.length;

    if (originalSize == 0) {
      return ConvertResult(
        originalName: fileName,
        error: 'imageconvert_error_empty',
      );
    }

    try {
      Uint8List? result = await _tryNative(
        bytes: inputBytes,
        fileName: fileName,
        config: config,
      );

      result ??= await _tryPureDart(
        bytes: inputBytes,
        config: config,
      );

      if (result == null || result.isEmpty) {
        return ConvertResult(
          originalName: fileName,
          originalSize: originalSize,
          error: 'imageconvert_error_convert_failed',
        );
      }

      return ConvertResult(
        originalName: fileName,
        originalSize: originalSize,
        convertedSize: result.length,
        bytes: result,
      );
    } catch (e) {
      return ConvertResult(
        originalName: fileName,
        originalSize: originalSize,
        error: e.toString(),
      );
    }
  }

  static Future<Uint8List?> _tryNative({
    required Uint8List bytes,
    required String fileName,
    required ImageConvertConfig config,
  }) async {
    switch (config.format) {
      case ImageOutputFormat.svg:
        return _trySvgEncode(bytes, config);
      default:
        return null;
    }
  }

  static Future<Uint8List?> _trySvgEncode(
      Uint8List bytes,
      ImageConvertConfig config,
      ) async {
    try {
      final img.Image? decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      final img.Image resized = _applyResize(decoded, config);

      final String svg = _rasterToSvg(resized, config.svgThreshold);
      return Uint8List.fromList(svg.codeUnits);
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List?> _tryPureDart({
    required Uint8List bytes,
    required ImageConvertConfig config,
  }) async {
    img.Image? decoded;

    try {
      decoded = img.decodeImage(bytes);
    } catch (_) {
      decoded = null;
    }

    if (decoded == null) {
      return null;
    }

    decoded = _applyRotateIfNeeded(decoded, config);
    decoded = _applyResize(decoded, config);

    return _encodeWithPureDart(decoded, config);
  }

  static img.Image _applyRotateIfNeeded(
      img.Image image,
      ImageConvertConfig config,
      ) {
    return image;
  }

  static img.Image _applyResize(
      img.Image image,
      ImageConvertConfig config,
      ) {
    final int? maxW = config.maxWidth;
    final int? maxH = config.maxHeight;

    if (maxW == null && maxH == null) return image;

    final int w = image.width;
    final int h = image.height;

    int newW = w;
    int newH = h;

    if (maxW != null && w > maxW) {
      newW = maxW;
      newH = (h * maxW / w).round();
    }
    if (maxH != null && newH > maxH) {
      newH = maxH;
      newW = (newW * maxH / newH).round();
    }

    if (newW == w && newH == h) return image;

    return img.copyResize(
      image,
      width: newW,
      height: newH,
      interpolation: img.Interpolation.average,
    );
  }

  static Uint8List? _encodeWithPureDart(
      img.Image image,
      ImageConvertConfig config,
      ) {
    try {
      switch (config.format) {
        case ImageOutputFormat.png:
          return Uint8List.fromList(img.encodePng(image, level: 6));

        case ImageOutputFormat.jpeg:
          return Uint8List.fromList(
            img.encodeJpg(image, quality: config.quality),
          );

        case ImageOutputFormat.bmp:
          return Uint8List.fromList(img.encodeBmp(image));

        case ImageOutputFormat.tga:
          return Uint8List.fromList(img.encodeTga(image));

        case ImageOutputFormat.gif:
          return Uint8List.fromList(img.encodeGif(image));

        case ImageOutputFormat.tiff:
          return Uint8List.fromList(img.encodeTiff(image));

        case ImageOutputFormat.ico:
          return Uint8List.fromList(img.encodeIco(image));

        case ImageOutputFormat.wbmp:
          return Uint8List.fromList(img.encodeJpg(image, quality: config.quality));

        case ImageOutputFormat.webp:
        case ImageOutputFormat.heic:
        case ImageOutputFormat.avif:
        case ImageOutputFormat.jpegXl:
          return Uint8List.fromList(
            img.encodeJpg(image, quality: config.quality),
          );

        case ImageOutputFormat.svg:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  static String _rasterToSvg(img.Image image, int threshold) {
    final StringBuffer sb = StringBuffer();

    sb.writeln(
      '<svg xmlns="http://www.w3.org/2000/svg" '
          'width="${image.width}" height="${image.height}" '
          'viewBox="0 0 ${image.width} ${image.height}">',
    );

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final img.Pixel pixel = image.getPixel(x, y);
        final int r = pixel.r.toInt();
        final int g = pixel.g.toInt();
        final int b = pixel.b.toInt();
        final num a = pixel.a;

        if (a < 32) continue;

        final int gray = ((r + g + b) / 3).round();
        if (gray > threshold) continue;

        final String hex = '#'
            '${r.toRadixString(16).padLeft(2, '0')}'
            '${g.toRadixString(16).padLeft(2, '0')}'
            '${b.toRadixString(16).padLeft(2, '0')}';

        sb.writeln(
          '<rect x="$x" y="$y" width="1" height="1" fill="$hex"/>',
        );
      }
    }

    sb.writeln('</svg>');
    return sb.toString();
  }

  static Future<List<BatchConvertItem>> convertBatch({
    required List<MapEntry<String, Uint8List>> files,
    required ImageConvertConfig config,
    void Function(BatchProgress progress)? onProgress,
  }) async {
    final List<BatchConvertItem> results = <BatchConvertItem>[];

    for (int i = 0; i < files.length; i++) {
      final MapEntry<String, Uint8List> entry = files[i];

      onProgress?.call(
        BatchProgress(
          current: i + 1,
          total: files.length,
          currentFile: entry.key,
        ),
      );

      final ConvertResult r = await convert(
        inputBytes: entry.value,
        fileName: entry.key,
        config: config,
      );

      results.add(
        BatchConvertItem(
          fileName: entry.key,
          originalSize: r.originalSize,
          convertedSize: r.convertedSize,
          outputName: buildOutputName(entry.key, config.format),
          bytes: r.bytes,
          error: r.error,
        ),
      );
    }

    return results;
  }
}