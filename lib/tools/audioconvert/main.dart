// lib/tools/audioconvert/main.dart

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/localization/app_localization.dart';
import '../../core/theme/app_ui_kit.dart';
import 'audio_convert_service.dart';
import 'models.dart';

class AudioConvert extends StatefulWidget {
  const AudioConvert({super.key});

  @override
  State<AudioConvert> createState() => _AudioConvertState();
}

class _AudioConvertState extends State<AudioConvert> {
  final AudioConvertService _service = const AudioConvertService();

  PickedAudioFile? _input;
  AudioFormat _targetFormat = AudioFormat.mp3;

  AudioQuality _quality = const AudioQuality();

  bool _busy = false;
  bool _loadingInfo = false;
  ConvertResult? _result;
  String? _errorKey;
  String? _errorDetail;

  bool get _locked => _busy || _loadingInfo;

  Future<void> _pick() async {
    if (_locked) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _errorKey = null;
      _errorDetail = null;
      _result = null;
    });

    try {
      final FilePickerResult? picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>[
          'mp3', 'm4a', 'aac', 'wav', 'flac', 'ogg', 'oga',
          'opus', 'wma', 'amr', 'aiff', 'aif', 'caf', 'alac',
          '3gp', 'mp4', 'm4b', 'webm',
        ],
      );

      if (picked == null || picked.files.isEmpty) return;
      final PlatformFile file = picked.files.first;
      if (file.path == null || file.path!.isEmpty) {
        setState(() => _errorKey = 'audioconvert_error_path');
        return;
      }

      final PickedAudioFile initial = PickedAudioFile(
        name: file.name,
        path: file.path!,
        size: file.size,
      );

      setState(() {
        _input = initial;
        _loadingInfo = true;
      });

      final PickedAudioFile enriched = await _service.readInfo(initial);
      if (!mounted) return;
      setState(() {
        _input = enriched;
        _loadingInfo = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingInfo = false;
        _errorKey = 'audioconvert_error_pick';
        _errorDetail = e.toString();
      });
    }
  }

  void _reset() {
    if (_locked) return;
    setState(() {
      _input = null;
      _result = null;
      _errorKey = null;
      _errorDetail = null;
      _quality = const AudioQuality();
      _targetFormat = AudioFormat.mp3;
    });
  }

  Future<void> _convert() async {
    final PickedAudioFile? input = _input;
    if (input == null || _locked) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _busy = true;
      _errorKey = null;
      _errorDetail = null;
      _result = null;
    });

    final ConvertResult res = await _service.convert(
      input: input,
      targetFormat: _targetFormat,
      quality: _quality,
      baseName: input.name,
    );

    if (!mounted) return;

    setState(() {
      _busy = false;
      _result = res;
      if (!res.success) {
        _errorKey = res.errorKey ?? 'audioconvert_error_generic';
        _errorDetail = res.errorDetail;
      }
    });
  }

  Future<void> _save() async {
    if (_locked) return;
    final ConvertResult? r = _result;
    if (r == null || !r.success || r.outputPath == null) return;
    final String base =
    (r.outputName ?? 'audio').replaceAll('.${_targetFormat.extension}', '');

    try {
      await FileSaver.instance.saveFile(
        name: base,
        filePath: r.outputPath,
        fileExtension: _targetFormat.extension,
        mimeType: MimeType.other,
      );
      if (!mounted) return;
      showGlassToast(context, context.t('audioconvert_saved'));
    } catch (e) {
      if (!mounted) return;
      showGlassToast(context, '${context.t('audioconvert_error_save')}: $e');
    }
  }

  Future<void> _share() async {
    if (_locked) return;
    final ConvertResult? r = _result;
    if (r == null || !r.success || r.outputPath == null) return;
    try {
      final Directory dir = await getTemporaryDirectory();
      final String name = r.outputName ?? 'audio.${_targetFormat.extension}';
      final File file = File('${dir.path}/$name');
      await File(r.outputPath!).copy(file.path);
      await Share.shareXFiles(<XFile>[XFile(file.path)], text: name);
    } catch (e) {
      if (!mounted) return;
      showGlassToast(context, '${context.t('audioconvert_error_share')}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: kScaffoldBg,
      appBar: GlassAppBar(
        title: context.t('audioconvert_title'),
        actions: <Widget>[
          if (_input != null)
            GlassIconButton(
              icon: CupertinoIcons.refresh,
              tooltip: context.t('audioconvert_reset'),
              onTap: _reset,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: GlassBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _pickCard(),
                if (_input != null) ...<Widget>[
                  const SizedBox(height: 14),
                  _infoCard(),
                ],
                const SizedBox(height: 14),
                _lockable(child: _formatCard()),
                const SizedBox(height: 14),
                _lockable(child: _qualityCard()),
                const SizedBox(height: 14),
                GradientActionButton(
                  label: _busy
                      ? context.t('audioconvert_converting')
                      : context.t('audioconvert_convert'),
                  icon: CupertinoIcons.arrow_right_arrow_left,
                  onPressed: _convert,
                  enabled: _input != null && !_locked,
                  loading: _busy,
                ),
                if (_errorKey != null) ...<Widget>[
                  const SizedBox(height: 14),
                  ErrorBox(
                    message: context.t(_errorKey!),
                    detail: _errorDetail,
                  ),
                ],
                if (_result != null && _result!.success) ...<Widget>[
                  const SizedBox(height: 14),
                  _resultCard(_result!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Convert gedərkən (_busy) format/keyfiyyət seçimlərini toxunulmaz və
  /// solğun göstərir ki, istifadəçi əməliyyat davam edərkən parametrləri
  /// dəyişib qarışıqlıq yaratmasın.
  Widget _lockable({required Widget child}) {
    return IgnorePointer(
      ignoring: _busy,
      child: AnimatedOpacity(
        duration: GlassTokens.fadeDuration,
        opacity: _busy ? 0.5 : 1,
        child: child,
      ),
    );
  }

  Widget _pickCard() {
    final PickedAudioFile? input = _input;
    final ShapeBorder shape = ContinuousRectangleBorder(
      borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
      side: BorderSide(color: kAccentB.withOpacity(0.4), width: 1.2),
    );

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionTitle(
            icon: CupertinoIcons.music_note_2,
            text: context.t('audioconvert_section_audio'),
          ),
          const SizedBox(height: 10),
          Opacity(
            opacity: _locked ? 0.6 : 1,
            child: IgnorePointer(
              ignoring: _locked,
              child: GestureDetector(
                onTap: _pick,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: ShapeDecoration(
                    shape: shape,
                    color: kAccentB.withOpacity(0.06),
                  ),
                  child: Column(
                    children: <Widget>[
                      Icon(
                        input == null
                            ? CupertinoIcons.cloud_upload
                            : CupertinoIcons.music_note,
                        size: 36,
                        color: kAccentB,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        input?.name ?? context.t('audioconvert_pick'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (input != null) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          formatBytes(input.size),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        context.t('audioconvert_formats_hint'),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard() {
    final PickedAudioFile input = _input!;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: SectionTitle(
                  icon: CupertinoIcons.info_circle,
                  text: context.t('audioconvert_section_info'),
                ),
              ),
              if (_loadingInfo)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: kAccentB,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: MetricBox(
                  label: context.t('audioconvert_duration'),
                  value: _formatDuration(input.durationMs),
                  color: kAccentB,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MetricBox(
                  label: context.t('audioconvert_bitrate'),
                  value: input.bitrate == 0 ? '—' : '${input.bitrate} kbps',
                  color: kAccentA,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MetricBox(
                  label: context.t('audioconvert_size'),
                  value: formatBytes(input.size),
                  color: kSuccess,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: MetricBox(
                  label: context.t('audioconvert_sample_rate'),
                  value: input.sampleRate == 0
                      ? '—'
                      : '${input.sampleRate} Hz',
                  color: kWarning,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: MetricBox(
                  label: context.t('audioconvert_codec'),
                  value: input.codec.isEmpty ? '—' : input.codec,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _formatCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionTitle(
            icon: CupertinoIcons.arrow_right_arrow_left,
            text: context.t('audioconvert_section_format'),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: AudioFormat.values.map((AudioFormat f) {
              return GlassChip(
                label: f.label,
                selected: _targetFormat == f,
                onTap: () => setState(() {
                  _targetFormat = f;
                  _result = null;
                }),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _qualityCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionTitle(
            icon: CupertinoIcons.slider_horizontal_3,
            text: context.t('audioconvert_section_quality'),
          ),
          const SizedBox(height: 8),
          if (_targetFormat.isLossy)
            GlassSliderRow(
              label: context.t('audioconvert_bitrate_label'),
              value: _quality.bitrate.toDouble(),
              min: 32,
              max: 320,
              suffix: ' kbps',
              divisions: 288,
              onChanged: (double v) => setState(() {
                _quality = _quality.copyWith(bitrate: v.round());
                _result = null;
              }),
            ),
          GlassSliderRow(
            label: context.t('audioconvert_sample_rate_label'),
            value: _quality.sampleRate.toDouble(),
            min: 8000,
            max: 48000,
            suffix: ' Hz',
            divisions: 20,
            onChanged: (double v) => setState(() {
              _quality = _quality.copyWith(sampleRate: v.round());
              _result = null;
            }),
          ),
          const SizedBox(height: 8),
          Text(
            context.t('audioconvert_channels'),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              GlassChip(
                label: context.t('audioconvert_mono'),
                selected: _quality.channels == 1,
                onTap: () => setState(() {
                  _quality = _quality.copyWith(channels: 1);
                  _result = null;
                }),
              ),
              GlassChip(
                label: context.t('audioconvert_stereo'),
                selected: _quality.channels == 2,
                onTap: () => setState(() {
                  _quality = _quality.copyWith(channels: 2);
                  _result = null;
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resultCard(ConvertResult r) {
    final int inputSize = _input?.size ?? 0;
    final double ratio = inputSize == 0 ? 0 : r.outputSize / inputSize;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: SectionTitle(
                  icon: CupertinoIcons.check_mark_circled,
                  text: context.t('audioconvert_result'),
                ),
              ),
              GlassIconButton(
                icon: CupertinoIcons.arrow_down_doc,
                tooltip: context.t('audioconvert_save'),
                onTap: _save,
              ),
              const SizedBox(width: 6),
              GlassIconButton(
                icon: CupertinoIcons.share,
                tooltip: context.t('audioconvert_share'),
                onTap: _share,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: MetricBox(
                  label: context.t('audioconvert_before'),
                  value: formatBytes(inputSize),
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MetricBox(
                  label: context.t('audioconvert_after'),
                  value: formatBytes(r.outputSize),
                  color: kAccentB,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MetricBox(
                  label: context.t('audioconvert_ratio'),
                  value: ratio == 0
                      ? '—'
                      : '${(ratio * 100).toStringAsFixed(0)}%',
                  color: kSuccess,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: ShapeDecoration(
              shape: ContinuousRectangleBorder(
                borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
              ),
              color: Colors.black.withOpacity(0.3),
            ),
            child: Text(
              r.outputName ?? '—',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int ms) {
    if (ms <= 0) return '—';
    final int totalSeconds = ms ~/ 1000;
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}