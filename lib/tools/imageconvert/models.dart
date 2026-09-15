enum ImageOutputFormat {
  jpeg,
  png,
  webp,
  heic,
  bmp,
  gif,
  tiff,
  ico,
  avif,
  jpegXl,
  tga,
  wbmp,
  svg,
}

class ConvertResult {
  final String? originalName;
  final int originalSize;
  final int convertedSize;
  final List<int>? bytes;
  final String? error;

  ConvertResult({
    this.originalName,
    this.originalSize = 0,
    this.convertedSize = 0,
    this.bytes,
    this.error,
  });

  bool get isSuccess => error == null;

  double get ratio {
    if (originalSize == 0) return 0;
    return convertedSize / originalSize;
  }

  String get originalSizeLabel => _formatBytes(originalSize);
  String get convertedSizeLabel => _formatBytes(convertedSize);

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class BatchConvertItem {
  final String fileName;
  final int originalSize;
  final int convertedSize;
  final String? outputName;
  final List<int>? bytes;
  final String? error;

  BatchConvertItem({
    required this.fileName,
    this.originalSize = 0,
    this.convertedSize = 0,
    this.outputName,
    this.bytes,
    this.error,
  });

  bool get isSuccess => error == null;
}

class BatchProgress {
  final int current;
  final int total;
  final String currentFile;

  BatchProgress({
    required this.current,
    required this.total,
    required this.currentFile,
  });

  double get percent => total == 0 ? 0 : current / total;
}

class ImageConvertConfig {
  ImageOutputFormat format;
  int quality;
  int? maxWidth;
  int? maxHeight;
  bool keepExif;
  int svgThreshold;

  ImageConvertConfig({
    this.format = ImageOutputFormat.png,
    this.quality = 90,
    this.maxWidth,
    this.maxHeight,
    this.keepExif = false,
    this.svgThreshold = 128,
  });

  ImageConvertConfig copyWith({
    ImageOutputFormat? format,
    int? quality,
    int? maxWidth,
    int? maxHeight,
    bool? keepExif,
    int? svgThreshold,
  }) {
    return ImageConvertConfig(
      format: format ?? this.format,
      quality: quality ?? this.quality,
      maxWidth: maxWidth ?? this.maxWidth,
      maxHeight: maxHeight ?? this.maxHeight,
      keepExif: keepExif ?? this.keepExif,
      svgThreshold: svgThreshold ?? this.svgThreshold,
    );
  }

  static const Set<String> inputExtensions = <String>{
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
    'svg',
    'avif',
    'psd',
    'tga',
    'wbmp',
    'jxl',
  };

  static String extensionFor(ImageOutputFormat format) {
    switch (format) {
      case ImageOutputFormat.jpeg:
        return 'jpg';
      case ImageOutputFormat.png:
        return 'png';
      case ImageOutputFormat.webp:
        return 'webp';
      case ImageOutputFormat.heic:
        return 'heic';
      case ImageOutputFormat.bmp:
        return 'bmp';
      case ImageOutputFormat.gif:
        return 'gif';
      case ImageOutputFormat.tiff:
        return 'tiff';
      case ImageOutputFormat.ico:
        return 'ico';
      case ImageOutputFormat.avif:
        return 'avif';
      case ImageOutputFormat.jpegXl:
        return 'jxl';
      case ImageOutputFormat.tga:
        return 'tga';
      case ImageOutputFormat.wbmp:
        return 'wbmp';
      case ImageOutputFormat.svg:
        return 'svg';
    }
  }
}