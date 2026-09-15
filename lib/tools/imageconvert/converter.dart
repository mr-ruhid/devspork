import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:platform_image_converter/platform_image_converter.dart' as pic;

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
      Uint8List? result = await _tryPlatformConverter(
        bytes: inputBytes,
        config: config,
      );

      result ??= _convertWithPureDart(
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

  static Future<Uint8List?> _tryPlatformConverter({
    required Uint8List bytes,
    required ImageConvertConfig config,
  }) async {
    final pic.OutputFormat? format = _platformFormat(config.format);
    if (format == null) return null;

    try {
      final pic.ResizeMode resizeMode = _buildResizeMode(config);

      final Uint8List result = await pic.ImageConverter.convert(
        inputData: bytes,
        format: format,
        quality: config.quality,
        resizeMode: resizeMode,
      );

      return result;
    } on UnsupportedError {
      return null;
    } on pic.ImageDecodingException {
      return null;
    } on pic.ImageEncodingException {
      return null;
    } on pic.ImageConversionException {
      return null;
    } catch (_) {
      return null;
    }
  }

  static pic.ResizeMode _buildResizeMode(ImageConvertConfig config) {
    if (config.maxWidth == null && config.maxHeight == null) {
      return const pic.OriginalResizeMode();
    }
    return pic.FitResizeMode(
      width: config.maxWidth,
      height: config.maxHeight,
    );
  }

  static pic.OutputFormat? _platformFormat(ImageOutputFormat format) {
    switch (format) {
      case ImageOutputFormat.jpeg:
        return pic.OutputFormat.jpeg;
      case ImageOutputFormat.png:
        return pic.OutputFormat.png;
      case ImageOutputFormat.webp:
        return pic.OutputFormat.webp;
      case ImageOutputFormat.heic:
        return pic.OutputFormat.heic;
      default:
        return null;
    }
  }

  static Uint8List? _convertWithPureDart({
    required Uint8List bytes,
    required ImageConvertConfig config,
  }) {
    img.Image? decoded;
    try {
      decoded = img.decodeImage(bytes);
    } catch (_) {
      decoded = null;
    }

    if (decoded == null) return null;

    if (config.maxWidth != null || config.maxHeight != null) {
      final int w = decoded.width;
      final int h = decoded.height;
      int newW = w;
      int newH = h;

      if (config.maxWidth != null && w > config.maxWidth!) {
        newW = config.maxWidth!;
        newH = (h * config.maxWidth! / w).round();
      }
      if (config.maxHeight != null && newH > config.maxHeight!) {
        newH = config.maxHeight!;
        newW = (newW * config.maxHeight! / newH).round();
      }
      if (newW != w || newH != h) {
        decoded = img.copyResize(
          decoded,
          width: newW,
          height: newH,
          interpolation: img.Interpolation.average,
        );
      }
    }

    try {
      switch (config.format) {
        case ImageOutputFormat.jpeg:
          return Uint8List.fromList(
            img.encodeJpg(decoded, quality: config.quality),
          );
        case ImageOutputFormat.png:
          return Uint8List.fromList(img.encodePng(decoded, level: 6));
        case ImageOutputFormat.webp:
          return Uint8List.fromList(
            img.encodeWebP(decoded, quality: config.quality),
          );
        case ImageOutputFormat.bmp:
          return Uint8List.fromList(img.encodeBmp(decoded));
        case ImageOutputFormat.gif:
          return Uint8List.fromList(img.encodeGif(decoded));
        case ImageOutputFormat.tiff:
          return Uint8List.fromList(img.encodeTiff(decoded));
        case ImageOutputFormat.ico:
          return Uint8List.fromList(img.encodeIco(decoded));
        case ImageOutputFormat.tga:
          return Uint8List.fromList(img.encodeTga(decoded));
        case ImageOutputFormat.wbmp:
        case ImageOutputFormat.heic:
        case ImageOutputFormat.avif:
        case ImageOutputFormat.jpegXl:
        case ImageOutputFormat.svg:
          return Uint8List.fromList(
            img.encodeJpg(decoded, quality: config.quality),
          );
      }
    } catch (_) {
      return null;
    }
  }
}