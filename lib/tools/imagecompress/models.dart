enum ImageOutputFormat { jpeg, png, webp, heic }

enum CompressionPreset { low, medium, high, custom }

class ImageCompressConfig {
  int quality;
  int minWidth;
  int minHeight;
  int rotate;
  bool keepExif;
  ImageOutputFormat format;
  CompressionPreset preset;

  ImageCompressConfig({
    this.quality = 80,
    this.minWidth = 1920,
    this.minHeight = 1080,
    this.rotate = 0,
    this.keepExif = false,
    this.format = ImageOutputFormat.jpeg,
    this.preset = CompressionPreset.medium,
  });

  static ImageCompressConfig fromPreset(CompressionPreset p) {
    switch (p) {
      case CompressionPreset.low:
        return ImageCompressConfig(
          quality: 40,
          minWidth: 800,
          minHeight: 600,
          preset: p,
        );
      case CompressionPreset.medium:
        return ImageCompressConfig(
          quality: 70,
          minWidth: 1280,
          minHeight: 720,
          preset: p,
        );
      case CompressionPreset.high:
        return ImageCompressConfig(
          quality: 90,
          minWidth: 1920,
          minHeight: 1080,
          preset: p,
        );
      case CompressionPreset.custom:
        return ImageCompressConfig(preset: p);
    }
  }

  ImageCompressConfig copyWith({
    int? quality,
    int? minWidth,
    int? minHeight,
    int? rotate,
    bool? keepExif,
    ImageOutputFormat? format,
    CompressionPreset? preset,
  }) {
    return ImageCompressConfig(
      quality: quality ?? this.quality,
      minWidth: minWidth ?? this.minWidth,
      minHeight: minHeight ?? this.minHeight,
      rotate: rotate ?? this.rotate,
      keepExif: keepExif ?? this.keepExif,
      format: format ?? this.format,
      preset: preset ?? this.preset,
    );
  }
}

class CompressResult {
  final String? originalName;
  final int originalSize;
  final int compressedSize;
  final String? outputPath;
  final List<int>? bytes;
  final String? error;

  CompressResult({
    this.originalName,
    this.originalSize = 0,
    this.compressedSize = 0,
    this.outputPath,
    this.bytes,
    this.error,
  });

  bool get isSuccess => error == null;

  double get ratio {
    if (originalSize == 0) return 0;
    return 1 - (compressedSize / originalSize);
  }

  String get originalSizeLabel => _formatBytes(originalSize);
  String get compressedSizeLabel => _formatBytes(compressedSize);

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}