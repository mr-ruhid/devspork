// lib/tools/audioconvert/audio_convert_service.dart

import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new_audio/media_information_session.dart';
import 'package:ffmpeg_kit_flutter_new_audio/media_information.dart';
import 'package:path_provider/path_provider.dart';

import 'models.dart';

class AudioConvertService {
  const AudioConvertService();

  Future<PickedAudioFile> readInfo(PickedAudioFile file) async {
    try {
      final MediaInformationSession session =
      await FFprobeKit.getMediaInformation(file.path);
      final MediaInformation? info = session.getMediaInformation();
      if (info == null) return file;

      final String? durationRaw = info.getDuration();
      final double? durationSec =
      durationRaw == null ? null : double.tryParse(durationRaw);
      final String? bitrateRaw = info.getBitrate();
      final int? bitrate = bitrateRaw == null ? null : int.tryParse(bitrateRaw);

      int sampleRate = 0;
      String codec = '';
      final Map<dynamic, dynamic>? streams = info.getStreams()?.isNotEmpty == true
          ? null
          : null;
      final List<dynamic>? streamList = info.getStreams();
      if (streamList != null && streamList.isNotEmpty) {
        final dynamic first = streamList.first;
        final String? sr = first.getSampleRate();
        if (sr != null) sampleRate = int.tryParse(sr) ?? 0;
        final String? c = first.getCodec();
        if (c != null) codec = c;
      }

      return file.copyWithInfo(
        durationMs: durationSec == null ? 0 : (durationSec * 1000).round(),
        bitrate: bitrate ?? 0,
        sampleRate: sampleRate,
        codec: codec,
      );
    } catch (_) {
      return file;
    }
  }

  Future<ConvertResult> convert({
    required PickedAudioFile input,
    required AudioFormat targetFormat,
    required AudioQuality quality,
    required String baseName,
  }) async {
    try {
      final Directory dir = await getTemporaryDirectory();
      final String safeBase = _sanitize(baseName);
      final String outputPath =
          '${dir.path}/${safeBase}_${DateTime.now().millisecondsSinceEpoch}.${targetFormat.extension}';

      final String command = _buildCommand(
        input: input.path,
        output: outputPath,
        format: targetFormat,
        quality: quality,
      );

      final FFmpegSession session = await FFmpegKit.execute(command);
      final ReturnCode? returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        final File outFile = File(outputPath);
        if (!await outFile.exists()) {
          return ConvertResult.failure(
            errorKey: 'audioconvert_error_output_missing',
          );
        }
        final int size = await outFile.length();
        return ConvertResult.success(
          outputPath: outputPath,
          outputName: '${safeBase}.${targetFormat.extension}',
          outputSize: size,
        );
      }

      final String? logs = await session.getOutput();
      return ConvertResult.failure(
        errorKey: 'audioconvert_error_ffmpeg',
        errorDetail: logs,
      );
    } catch (e) {
      return ConvertResult.failure(
        errorKey: 'audioconvert_error_generic',
        errorDetail: e.toString(),
      );
    }
  }

  String _buildCommand({
    required String input,
    required String output,
    required AudioFormat format,
    required AudioQuality quality,
  }) {
    final StringBuffer buffer = StringBuffer();
    buffer.write('-y ');
    buffer.write('-i "${_escape(input)}" ');
    buffer.write('-vn ');

    final int channels = quality.channels.clamp(1, 2);
    buffer.write('-ac $channels ');

    final int sampleRate = quality.sampleRate.clamp(8000, 192000);
    buffer.write('-ar $sampleRate ');

    final int bitrate = quality.bitrate.clamp(32, 320);

    switch (format) {
      case AudioFormat.mp3:
        buffer.write('-c:a libmp3lame -b:a ${bitrate}k ');
        break;
      case AudioFormat.aac:
      case AudioFormat.m4a:
        buffer.write('-c:a aac -b:a ${bitrate}k ');
        break;
      case AudioFormat.wav:
        buffer.write('-c:a pcm_s16le ');
        break;
      case AudioFormat.flac:
        buffer.write('-c:a flac ');
        break;
      case AudioFormat.ogg:
        buffer.write('-c:a libvorbis -b:a ${bitrate}k ');
        break;
      case AudioFormat.opus:
        buffer.write('-c:a libopus -b:a ${bitrate}k ');
        break;
      case AudioFormat.wma:
        buffer.write('-c:a wmav2 -b:a ${bitrate}k ');
        break;
      case AudioFormat.amr:
        buffer.write('-c:a libopencore_amrnb -b:a 12.2k -ar 8000 -ac 1 ');
        break;
    }

    buffer.write('"${_escape(output)}"');
    return buffer.toString();
  }

  String _escape(String path) {
    return path.replaceAll('"', r'\"');
  }

  String _sanitize(String name) {
    final String trimmed = name.trim();
    final String withoutExt =
    trimmed.replaceAll(RegExp(r'\.[^.]+$'), '');
    final String cleaned =
    withoutExt.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return cleaned.isEmpty ? 'audio' : cleaned;
  }
}