// lib/tools/imagecompress/main.dart

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/localization/app_localization.dart';
import 'compressor.dart';
import 'models.dart';

const Color _accentA = Color(0xFF7C4DFF);
const Color _accentB = Color(0xFF00E5FF);
const Color _danger = Color(0xFFFF5C5C);
const Color _success = Color(0xFF4BD68B);
const Color _bgTop = Color(0xFF1B1035);
const Color _bgMid = Color(0xFF2A1550);
const Color _bgBot = Color(0xFF0F2A4A);

class ImageCompressPage extends StatefulWidget {
  const ImageCompressPage({super.key});

  @override
  State<ImageCompressPage> createState() => _ImageCompressPageState();
}

class _ImageCompressPageState extends State<ImageCompressPage> {
  ImageCompressConfig _config =
  ImageCompressConfig.fromPreset(CompressionPreset.medium);

  Uint8List? _originalBytes;
  Uint8List? _compressedBytes;
  String? _fileName;
  CompressResult? _result;

  bool _busy = false;
  String? _errorKey;
  String? _errorDetail;

  Future<void> _pickImage() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _errorKey = null;
      _errorDetail = null;
    });

    try {
      final FilePickerResult? picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>[
          'jpg', 'jpeg', 'jpe', 'jfif', 'png', 'webp', 'heic', 'heif',
          'bmp', 'gif', 'tif', 'tiff', 'ico',
        ],
        withData: true,
      );

      if (picked == null || picked.files.isEmpty) return;

      final PlatformFile file = picked.files.first;
      Uint8List? bytes = file.bytes;

      if (bytes == null && file.path != null) {
        try {
          bytes = await File(file.path!).readAsBytes();
        } catch (_) {}
      }

      if (bytes == null) {
        setState(() => _errorKey = 'imagecompress_error_read');
        return;
      }

      setState(() {
        _originalBytes = bytes;
        _compressedBytes = null;
        _result = null;
        _fileName = file.name;
      });

      HapticFeedback.selectionClick();
    } catch (e) {
      setState(() {
        _errorKey = 'imagecompress_error_pick';
        _errorDetail = e.toString();
      });
    }
  }

  Future<void> _compress() async {
    final Uint8List? input = _originalBytes;
    final String? name = _fileName;
    if (input == null || name == null) {
      setState(() => _errorKey = 'imagecompress_error_no_image');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _busy = true;
      _errorKey = null;
      _errorDetail = null;
      _compressedBytes = null;
      _result = null;
    });

    final CompressResult result = await ImageCompressor.compressBytes(
      inputBytes: input,
      fileName: name,
      config: _config,
    );

    if (!mounted) return;

    final Uint8List? normalizedBytes =
    result.bytes == null ? null : Uint8List.fromList(result.bytes!);

    setState(() {
      _busy = false;
      _result = result;
      _compressedBytes = normalizedBytes;
      if (!result.isSuccess) {
        _errorKey = result.error ?? 'imagecompress_error_unknown';
        _errorDetail = null;
      }
    });

    if (result.isSuccess) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _save() async {
    final Uint8List? bytes = _compressedBytes;
    final String? name = _fileName;
    if (bytes == null || name == null) return;

    final String outputName =
    ImageCompressor.buildOutputName(name, _config.format);
    final String ext = ImageCompressor.outputExtension(_config.format);

    try {
      await FileSaver.instance.saveFile(
        name: outputName.replaceAll('.$ext', ''),
        bytes: bytes,
        fileExtension: ext,
        mimeType: _mimeType(ext),
      );
      if (!mounted) return;
      _showToast('${context.t('imagecompress_saved')}: $outputName');
      HapticFeedback.lightImpact();
    } catch (e) {
      if (!mounted) return;
      _showToast('${context.t('imagecompress_error_save')}: $e');
    }
  }

  Future<void> _share() async {
    final Uint8List? bytes = _compressedBytes;
    final String? name = _fileName;
    if (bytes == null || name == null) return;

    try {
      final String outputName =
      ImageCompressor.buildOutputName(name, _config.format);
      final Directory dir = await getTemporaryDirectory();
      final File file = File('${dir.path}/$outputName');
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles(<XFile>[XFile(file.path)], text: outputName);
    } catch (e) {
      if (!mounted) return;
      _showToast('${context.t('imagecompress_error_share')}: $e');
    }
  }

  MimeType _mimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return MimeType.jpeg;
      case 'png':
        return MimeType.png;
      default:
        return MimeType.other;
    }
  }

  void _applyPreset(CompressionPreset preset) {
    HapticFeedback.selectionClick();
    setState(() {
      _config = ImageCompressConfig.fromPreset(preset);
    });
  }

  void _updateConfig(ImageCompressConfig newConfig) {
    setState(() {
      _config = newConfig;
    });
  }

  void _reset() {
    HapticFeedback.lightImpact();
    setState(() {
      _originalBytes = null;
      _compressedBytes = null;
      _result = null;
      _fileName = null;
      _errorKey = null;
      _errorDetail = null;
    });
  }

  void _showToast(String message) {
    final OverlayState overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (BuildContext ctx) => Positioned(
        bottom: 90,
        left: 40,
        right: 40,
        child: _ToastBubble(message: message),
      ),
    );
    overlay.insert(entry);
    Future<void>.delayed(const Duration(milliseconds: 1600), entry.remove);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0B0B12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.t('imagecompress_title'),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        actions: <Widget>[
          if (_originalBytes != null)
            _glassIconButton(
              icon: CupertinoIcons.refresh,
              tooltip: context.t('imagecompress_reset'),
              onTap: _reset,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[_bgTop, _bgMid, _bgBot],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(top: -80, left: -60, child: _blob(220, _accentA)),
            Positioned(bottom: -100, right: -60, child: _blob(260, _accentB)),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildPickerCard(),
                    if (_originalBytes != null) ...<Widget>[
                      const SizedBox(height: 14),
                      _buildPreviewCard(),
                    ],
                    const SizedBox(height: 14),
                    _buildPresetCard(),
                    const SizedBox(height: 14),
                    if (_config.preset == CompressionPreset.custom)
                      ...<Widget>[
                        _buildCustomCard(),
                        const SizedBox(height: 14),
                      ],
                    _buildCompressButton(),
                    if (_errorKey != null) ...<Widget>[
                      const SizedBox(height: 14),
                      _buildErrorBox(_errorKey!, _errorDetail),
                    ],
                    if (_result != null && _result!.isSuccess) ...<Widget>[
                      const SizedBox(height: 14),
                      _buildResultCard(_result!),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            CupertinoIcons.photo,
            context.t('imagecompress_section_image'),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _accentB.withOpacity(0.4),
                  width: 1.2,
                ),
                color: _accentB.withOpacity(0.06),
              ),
              child: Column(
                children: <Widget>[
                  Icon(
                    _originalBytes == null
                        ? CupertinoIcons.cloud_upload
                        : CupertinoIcons.photo_fill,
                    size: 36,
                    color: _accentB,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _originalBytes == null
                        ? context.t('imagecompress_pick')
                        : (_fileName ?? context.t('imagecompress_picked')),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_originalBytes != null) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      _formatBytes(_originalBytes!.length),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    context.t('imagecompress_formats'),
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
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            CupertinoIcons.rectangle_stack,
            context.t('imagecompress_preview'),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _previewBox(
                  context.t('imagecompress_original'),
                  _originalBytes!,
                  _formatBytes(_originalBytes!.length),
                  Colors.white70,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _previewBox(
                  context.t('imagecompress_compressed'),
                  _compressedBytes,
                  _compressedBytes == null
                      ? '—'
                      : _formatBytes(_compressedBytes!.length),
                  _success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _previewBox(
      String label,
      Uint8List? bytes,
      String size,
      Color accent,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            color: accent,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          clipBehavior: Clip.antiAlias,
          child: bytes == null
              ? const Center(
            child: Icon(
              CupertinoIcons.hourglass,
              color: Colors.white24,
              size: 32,
            ),
          )
              : Image.memory(
            bytes,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(
                CupertinoIcons.exclamationmark_triangle,
                color: Colors.white24,
                size: 32,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          size,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontFamily: 'monospace',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPresetCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            CupertinoIcons.slider_horizontal_3,
            context.t('imagecompress_preset_section'),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _presetChip(
                context.t('imagecompress_preset_low'),
                context.t('imagecompress_preset_low_hint'),
                CompressionPreset.low,
                _success,
              ),
              _presetChip(
                context.t('imagecompress_preset_medium'),
                context.t('imagecompress_preset_medium_hint'),
                CompressionPreset.medium,
                _accentB,
              ),
              _presetChip(
                context.t('imagecompress_preset_high'),
                context.t('imagecompress_preset_high_hint'),
                CompressionPreset.high,
                _accentA,
              ),
              _presetChip(
                context.t('imagecompress_preset_custom'),
                context.t('imagecompress_preset_custom_hint'),
                CompressionPreset.custom,
                Colors.white70,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _presetChip(
      String label,
      String hint,
      CompressionPreset preset,
      Color color,
      ) {
    final bool selected = _config.preset == preset;
    return GestureDetector(
      onTap: () => _applyPreset(preset),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(colors: <Color>[color, color.withOpacity(0.7)])
              : null,
          color: selected ? null : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : Colors.white.withOpacity(0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              hint,
              style: TextStyle(
                color: selected ? Colors.white70 : Colors.white38,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            CupertinoIcons.settings,
            context.t('imagecompress_custom_section'),
          ),
          const SizedBox(height: 8),
          _sliderRow(
            label: context.t('imagecompress_quality'),
            value: _config.quality.toDouble(),
            min: 10,
            max: 100,
            suffix: '%',
            onChanged: (double v) => _updateConfig(
              _config.copyWith(quality: v.round()),
            ),
          ),
          _sliderRow(
            label: context.t('imagecompress_max_width'),
            value: _config.minWidth.toDouble(),
            min: 100,
            max: 4096,
            suffix: ' px',
            divisions: 80,
            onChanged: (double v) => _updateConfig(
              _config.copyWith(minWidth: v.round()),
            ),
          ),
          _sliderRow(
            label: context.t('imagecompress_max_height'),
            value: _config.minHeight.toDouble(),
            min: 100,
            max: 4096,
            suffix: ' px',
            divisions: 80,
            onChanged: (double v) => _updateConfig(
              _config.copyWith(minHeight: v.round()),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.t('imagecompress_output_format'),
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ImageOutputFormat.values.map((ImageOutputFormat f) {
              final bool selected = _config.format == f;
              return GestureDetector(
                onTap: () => _updateConfig(_config.copyWith(format: f)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(
                      colors: <Color>[_accentA, _accentB],
                    )
                        : null,
                    color: selected ? null : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : Colors.white.withOpacity(0.15),
                    ),
                  ),
                  child: Text(
                    f.name.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            context.t('imagecompress_rotate'),
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <int>[0, 90, 180, 270].map((int deg) {
              final bool selected = _config.rotate == deg;
              return GestureDetector(
                onTap: () => _updateConfig(_config.copyWith(rotate: deg)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(
                      colors: <Color>[_accentA, _accentB],
                    )
                        : null,
                    color: selected ? null : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : Colors.white.withOpacity(0.15),
                    ),
                  ),
                  child: Text(
                    '$deg°',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          _switchRow(
            label: context.t('imagecompress_keep_exif'),
            value: _config.keepExif,
            onChanged: (bool v) =>
                _updateConfig(_config.copyWith(keepExif: v)),
          ),
        ],
      ),
    );
  }

  Widget _buildCompressButton() {
    final bool canCompress = _originalBytes != null && !_busy;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canCompress ? _compress : null,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: canCompress ? 1 : 0.5,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[_accentA, _accentB],
                ),
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (_busy)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(
                      CupertinoIcons.arrow_down_right_square,
                      color: Colors.white,
                      size: 20,
                    ),
                  const SizedBox(width: 10),
                  Text(
                    _busy
                        ? context.t('imagecompress_compressing')
                        : context.t('imagecompress_compress'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBox(String errorKey, String? detail) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _danger.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _danger.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 18,
                color: _danger,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.t(errorKey),
                  style: const TextStyle(
                    color: Color(0xFFFFBFBF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (detail != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              detail,
              style: const TextStyle(
                color: Color(0xFFFFBFBF),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultCard(CompressResult r) {
    final double ratio = r.ratio;
    final Color ratioColor = ratio > 0.5
        ? _success
        : (ratio > 0.2 ? _accentB : Colors.white70);

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _sectionTitle(
                  CupertinoIcons.check_mark_circled,
                  context.t('imagecompress_result'),
                ),
              ),
              _glassIconButton(
                icon: CupertinoIcons.arrow_down_doc,
                tooltip: context.t('imagecompress_save'),
                onTap: _save,
              ),
              const SizedBox(width: 6),
              _glassIconButton(
                icon: CupertinoIcons.share,
                tooltip: context.t('imagecompress_share'),
                onTap: _share,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _resultMetric(
                  context.t('imagecompress_original_label'),
                  r.originalSizeLabel,
                  Colors.white70,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _resultMetric(
                  context.t('imagecompress_compressed_label'),
                  r.compressedSizeLabel,
                  _accentB,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _resultMetric(
                  context.t('imagecompress_savings'),
                  '${(ratio * 100).toStringAsFixed(1)}%',
                  ratioColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              ImageCompressor.buildOutputName(
                r.originalName ?? 'image',
                _config.format,
              ),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String text) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    String? suffix,
    int? divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _accentB.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${value.round()}${suffix ?? ''}',
                  style: const TextStyle(
                    color: _accentB,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _accentA,
              inactiveTrackColor: Colors.white24,
              thumbColor: _accentB,
              trackHeight: 3,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions ?? (max - min).round(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: CupertinoSwitch(
              value: value,
              activeColor: _accentA,
              onChanged: (bool v) {
                HapticFeedback.selectionClick();
                onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.white.withOpacity(0.08),
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(icon, size: 18, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return IgnorePointer(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.35),
            ),
          ),
        ),
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.06),
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ToastBubble extends StatelessWidget {
  const _ToastBubble({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}