// lib/tools/audioconvert/models.dart

enum AudioFormat {
  mp3,
  aac,
  m4a,
  wav,
  flac,
  ogg,
  opus,
  wma,
  amr,
}

extension AudioFormatX on AudioFormat {
  String get extension {
    switch (this) {
      case AudioFormat.mp3:
        return 'mp3';
      case AudioFormat.aac:
        return 'aac';
      case AudioFormat.m4a:
        return 'm4a';
      case AudioFormat.wav:
        return 'wav';
      case AudioFormat.flac:
        return 'flac';
      case AudioFormat.ogg:
        return 'ogg';
      case AudioFormat.opus:
        return 'opus';
      case AudioFormat.wma:
        return 'wma';
      case AudioFormat.amr:
        return 'amr';
    }
  }

  String get label {
    switch (this) {
      case AudioFormat.mp3:
        return 'MP3';
      case AudioFormat.aac:
        return 'AAC';
      case AudioFormat.m4a:
        return 'M4A';
      case AudioFormat.wav:
        return 'WAV';
      case AudioFormat.flac:
        return 'FLAC';
      case AudioFormat.ogg:
        return 'OGG';
      case AudioFormat.opus:
        return 'OPUS';
      case AudioFormat.wma:
        return 'WMA';
      case AudioFormat.amr:
        return 'AMR';
    }
  }

  bool get isLossy {
    switch (this) {
      case AudioFormat.mp3:
      case AudioFormat.aac:
      case AudioFormat.m4a:
      case AudioFormat.ogg:
      case AudioFormat.opus:
      case AudioFormat.wma:
      case AudioFormat.amr:
        return true;
      case AudioFormat.wav:
      case AudioFormat.flac:
        return false;
    }
  }
}

class AudioQuality {
  // Bütün sahələr artıq `final` idi — sadəcə konstruktorun qarşısına
  // `const` əlavə etməklə compile-time sabit kimi istifadə oluna bilər
  // (məs. `const AudioQuality()`), lazımsız runtime obyekt yaratmadan.
  const AudioQuality({
    this.bitrate = 192,
    this.sampleRate = 44100,
    this.channels = 2,
  });

  final int bitrate;
  final int sampleRate;
  final int channels;

  AudioQuality copyWith({
    int? bitrate,
    int? sampleRate,
    int? channels,
  }) {
    return AudioQuality(
      bitrate: bitrate ?? this.bitrate,
      sampleRate: sampleRate ?? this.sampleRate,
      channels: channels ?? this.channels,
    );
  }
}

class PickedAudioFile {
  PickedAudioFile({
    required this.name,
    required this.path,
    required this.size,
    this.durationMs = 0,
    this.bitrate = 0,
    this.sampleRate = 0,
    this.codec = '',
  });

  final String name;
  final String path;
  final int size;
  final int durationMs;
  final int bitrate;
  final int sampleRate;
  final String codec;

  PickedAudioFile copyWithInfo({
    int? durationMs,
    int? bitrate,
    int? sampleRate,
    String? codec,
  }) {
    return PickedAudioFile(
      name: name,
      path: path,
      size: size,
      durationMs: durationMs ?? this.durationMs,
      bitrate: bitrate ?? this.bitrate,
      sampleRate: sampleRate ?? this.sampleRate,
      codec: codec ?? this.codec,
    );
  }
}

class ConvertResult {
  ConvertResult({
    required this.success,
    this.outputPath,
    this.outputName,
    this.outputSize = 0,
    this.errorKey,
    this.errorDetail,
  });

  final bool success;
  final String? outputPath;
  final String? outputName;
  final int outputSize;
  final String? errorKey;
  final String? errorDetail;

  factory ConvertResult.success({
    required String outputPath,
    required String outputName,
    required int outputSize,
  }) {
    return ConvertResult(
      success: true,
      outputPath: outputPath,
      outputName: outputName,
      outputSize: outputSize,
    );
  }

  factory ConvertResult.failure({
    required String errorKey,
    String? errorDetail,
  }) {
    return ConvertResult(
      success: false,
      errorKey: errorKey,
      errorDetail: errorDetail,
    );
  }
}