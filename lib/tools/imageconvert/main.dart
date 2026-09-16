// lib/tools/imageconvert/main.dart

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
import 'converter.dart';
import 'models.dart';

const Color _accentA = Color(0xFF7C4DFF);
const Color _accentB = Color(0xFF00E5FF);
const Color _danger = Color(0xFFFF5C5C);
const Color _success = Color(0xFF4BD68B);
const Color _warning = Color(0xFFFFC24B);
const Color _bgTop = Color(0xFF1B1035);
const Color _bgMid = Color(0xFF2A1550);
const Color _bgBot = Color(0xFF0F2A4A);

class ImageConvertPage extends StatefulWidget {
  const ImageConvertPage({super.key});

  @override
  State<ImageConvertPage> createState() => _ImageConvertPageState();
}

class _ImageConvertPageState extends State<ImageConvertPage> {
  ImageConvertConfig _config = ImageConvertConfig();

  final List<_PickedFile> _picked = <_PickedFile>[];
  List<BatchConvertItem> _results = <BatchConvertItem>[];

  bool _busy = false;
  bool _batchMode = false;
  BatchProgress? _progress;
  String? _errorKey;
  String? _errorDetail;

  Future<void> _pickFiles() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _errorKey = null;
      _errorDetail = null;
    });

    try {
      final FilePickerResult? picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ImageConvertConfig.inputExtensions.toList(),
        withData: true,
        allowMultiple: _batchMode,
      );

      if (picked == null || picked.files.isEmpty) return;

      final List<_PickedFile> loaded = <_PickedFile>[];

      for (final PlatformFile file in picked.files) {
        Uint8List? bytes = file.bytes;

        if (bytes == null && file.path != null) {
          try {
            bytes = await File(file.path!).readAsBytes();
          } catch (_) {}
        }

        if (bytes == null) continue;

        loaded.add(_PickedFile(name: file.name, bytes: bytes));
      }

      if (loaded.isEmpty) {
        setState(() => _errorKey = 'imageconvert_error_read');
        return;
      }

      setState(() {
        _picked
          ..clear()
          ..addAll(loaded);
        _results = <BatchConvertItem>[];
      });

      HapticFeedback.selectionClick();
    } catch (e) {
      setState(() {
        _errorKey = 'imageconvert_error_pick';
        _errorDetail = e.toString();
      });
    }
  }

  Future<void> _convert() async {
    if (_picked.isEmpty) {
      setState(() => _errorKey = 'imageconvert_error_no_file');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _busy = true;
      _errorKey = null;
      _errorDetail = null;
      _results = <BatchConvertItem>[];
      _progress = null;
    });

    final List<MapEntry<String, Uint8List>> entries = _picked
        .map((_PickedFile p) => MapEntry<String, Uint8List>(p.name, p.bytes))
        .toList();

    final List<BatchConvertItem> results = await ImageConverter.convertBatch(
      files: entries,
      config: _config,
      onProgress: (BatchProgress p) {
        if (mounted) setState(() => _progress = p);
      },
    );

    if (!mounted) return;

    final bool anyFailed = results.any((BatchConvertItem r) => !r.isSuccess);

    setState(() {
      _busy = false;
      _results = results;
      _progress = null;
      if (anyFailed && results.every((BatchConvertItem r) => !r.isSuccess)) {
        _errorKey = 'imageconvert_error_all_failed';
        _errorDetail = results
            .map((BatchConvertItem r) => r.error)
            .whereType<String>()
            .take(1)
            .join();
      }
    });

    if (anyFailed) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _saveSingle(BatchConvertItem item) async {
    if (item.bytes == null) return;
    final String ext = ImageConvertConfig.extensionFor(_config.format);

    try {
      await FileSaver.instance.saveFile(
        name: item.outputName?.replaceAll('.$ext', '') ?? 'converted',
        bytes: Uint8List.fromList(item.bytes!),
        fileExtension: ext,
        mimeType: _mimeType(ext),
      );
      if (!mounted) return;
      _showToast('${context.t('imageconvert_saved')}: ${item.outputName}');
      HapticFeedback.lightImpact();
    } catch (e) {
      if (!mounted) return;
      _showToast('${context.t('imageconvert_error_save')}: $e');
    }
  }

  Future<void> _saveAll() async {
    final List<BatchConvertItem> successful = _results
        .where((BatchConvertItem r) => r.isSuccess && r.bytes != null)
        .toList();

    if (successful.isEmpty) return;

    final String ext = ImageConvertConfig.extensionFor(_config.format);

    for (final BatchConvertItem item in successful) {
      try {
        await FileSaver.instance.saveFile(
          name: item.outputName?.replaceAll('.$ext', '') ?? 'converted',
          bytes: Uint8List.fromList(item.bytes!),
          fileExtension: ext,
          mimeType: _mimeType(ext),
        );
      } catch (_) {}
    }

    if (!mounted) return;
    _showToast('${successful.length} ${context.t('imageconvert_saved_count')}');
    HapticFeedback.lightImpact();
  }

  Future<void> _shareSingle(BatchConvertItem item) async {
    if (item.bytes == null) return;

    try {
      final String outputName =
          item.outputName ?? 'converted.${ImageConvertConfig.extensionFor(_config.format)}';
      final Directory dir = await getTemporaryDirectory();
      final File file = File('${dir.path}/$outputName');
      await file.writeAsBytes(item.bytes!, flush: true);
      await Share.shareXFiles(<XFile>[XFile(file.path)], text: outputName);
    } catch (e) {
      if (!mounted) return;
      _showToast('${context.t('imageconvert_error_share')}: $e');
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

  void _updateConfig(ImageConvertConfig newConfig) {
    setState(() => _config = newConfig);
  }

  void _reset() {
    HapticFeedback.lightImpact();
    setState(() {
      _picked.clear();
      _results = <BatchConvertItem>[];
      _errorKey = null;
      _errorDetail = null;
      _progress = null;
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
          context.t('imageconvert_title'),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        actions: <Widget>[
          if (_picked.isNotEmpty)
            _glassIconButton(
              icon: CupertinoIcons.refresh,
              tooltip: context.t('imageconvert_reset'),
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
                    _buildModeCard(),
                    const SizedBox(height: 14),
                    _buildPickerCard(),
                    if (_picked.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 14),
                      _buildPickedList(),
                    ],
                    const SizedBox(height: 14),
                    _buildFormatCard(),
                    const SizedBox(height: 14),
                    _buildQualityCard(),
                    const SizedBox(height: 14),
                    _buildConvertButton(),
                    if (_busy && _progress != null) ...<Widget>[
                      const SizedBox(height: 14),
                      _buildProgressCard(_progress!),
                    ],
                    if (_errorKey != null) ...<Widget>[
                      const SizedBox(height: 14),
                      _buildErrorBox(_errorKey!, _errorDetail),
                    ],
                    if (_results.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 14),
                      _buildResultsCard(),
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

  Widget _buildModeCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            CupertinoIcons.square_stack_3d_up,
            context.t('imageconvert_section_mode'),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _modeChip(
                  labelKey: 'imageconvert_mode_single',
                  icon: CupertinoIcons.doc,
                  selected: !_batchMode,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _batchMode = false;
                      _picked.clear();
                      _results = <BatchConvertItem>[];
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _modeChip(
                  labelKey: 'imageconvert_mode_batch',
                  icon: CupertinoIcons.square_grid_2x2,
                  selected: _batchMode,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _batchMode = true;
                      _picked.clear();
                      _results = <BatchConvertItem>[];
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeChip({
    required String labelKey,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: <Color>[_accentA, _accentB])
              : null,
          color: selected ? null : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : Colors.white.withOpacity(0.15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              context.t(labelKey),
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
            context.t('imageconvert_section_pick'),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickFiles,
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
                    _picked.isEmpty
                        ? CupertinoIcons.cloud_upload
                        : CupertinoIcons.check_mark_circled,
                    size: 36,
                    color: _accentB,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _picked.isEmpty
                        ? (_batchMode
                        ? context.t('imageconvert_pick_multi')
                        : context.t('imageconvert_pick_single'))
                        : '${_picked.length} ${context.t('imageconvert_files_selected')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.t('imageconvert_formats_hint'),
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

  Widget _buildPickedList() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _sectionTitle(
                  CupertinoIcons.list_bullet,
                  context.t('imageconvert_section_selected'),
                ),
              ),
              Text(
                '${_picked.length}',
                style: const TextStyle(
                  color: _accentB,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < _picked.length; i++) _pickedRow(i),
        ],
      ),
    );
  }

  Widget _pickedRow(int index) {
    final _PickedFile p = _picked[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            CupertinoIcons.photo_fill,
            size: 14,
            color: _accentB,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              p.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _formatBytes(p.bytes.length),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          _miniIconButton(
            icon: CupertinoIcons.xmark,
            onTap: () {
              setState(() {
                _picked.removeAt(index);
                if (_picked.isEmpty) {
                  _results = <BatchConvertItem>[];
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFormatCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            CupertinoIcons.arrow_right_arrow_left,
            context.t('imageconvert_section_format'),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ImageOutputFormat.values.map((ImageOutputFormat f) {
              final bool selected = _config.format == f;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _updateConfig(_config.copyWith(format: f));
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(
                        colors: <Color>[_accentA, _accentB])
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
                    ImageConvertConfig.extensionFor(f).toUpperCase(),
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
        ],
      ),
    );
  }

  Widget _buildQualityCard() {
    final bool isLossy = _config.format == ImageOutputFormat.jpeg ||
        _config.format == ImageOutputFormat.webp ||
        _config.format == ImageOutputFormat.heic ||
        _config.format == ImageOutputFormat.avif ||
        _config.format == ImageOutputFormat.jpegXl;

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            CupertinoIcons.slider_horizontal_3,
            context.t('imageconvert_section_quality'),
          ),
          const SizedBox(height: 6),
          if (isLossy)
            _sliderRow(
              label: context.t('imageconvert_quality'),
              value: _config.quality.toDouble(),
              min: 10,
              max: 100,
              suffix: '%',
              onChanged: (double v) =>
                  _updateConfig(_config.copyWith(quality: v.round())),
            ),
          _sliderRow(
            label: context.t('imageconvert_max_width'),
            value: (_config.maxWidth ?? 0).toDouble(),
            min: 0,
            max: 4096,
            suffix: ' px',
            divisions: 64,
            onChanged: (double v) => _updateConfig(
              _config.copyWith(maxWidth: v.round() == 0 ? null : v.round()),
            ),
          ),
          _sliderRow(
            label: context.t('imageconvert_max_height'),
            value: (_config.maxHeight ?? 0).toDouble(),
            min: 0,
            max: 4096,
            suffix: ' px',
            divisions: 64,
            onChanged: (double v) => _updateConfig(
              _config.copyWith(maxHeight: v.round() == 0 ? null : v.round()),
            ),
          ),
          if (_config.format == ImageOutputFormat.svg)
            _sliderRow(
              label: context.t('imageconvert_svg_threshold'),
              value: _config.svgThreshold.toDouble(),
              min: 16,
              max: 240,
              divisions: 56,
              onChanged: (double v) => _updateConfig(
                _config.copyWith(svgThreshold: v.round()),
              ),
            ),
          const SizedBox(height: 4),
          _switchRow(
            label: context.t('imageconvert_keep_exif'),
            value: _config.keepExif,
            onChanged: (bool v) =>
                _updateConfig(_config.copyWith(keepExif: v)),
          ),
        ],
      ),
    );
  }

  Widget _buildConvertButton() {
    final bool canConvert = _picked.isNotEmpty && !_busy;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canConvert ? _convert : null,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: canConvert ? 1 : 0.5,
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
                      CupertinoIcons.arrow_right_arrow_left,
                      color: Colors.white,
                      size: 20,
                    ),
                  const SizedBox(width: 10),
                  Text(
                    _busy
                        ? context.t('imageconvert_converting')
                        : context.t('imageconvert_convert'),
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

  Widget _buildProgressCard(BatchProgress p) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LinearProgressIndicator(
            value: p.percent,
            backgroundColor: Colors.white12,
            color: _accentB,
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  p.currentFile,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${p.current}/${p.total}',
                style: const TextStyle(
                  color: _accentB,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
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
          if (detail != null && detail.isNotEmpty) ...<Widget>[
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

  Widget _buildResultsCard() {
    final int successCount =
        _results.where((BatchConvertItem r) => r.isSuccess).length;
    final int failCount = _results.length - successCount;

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _sectionTitle(
                  CupertinoIcons.check_mark_circled,
                  context.t('imageconvert_section_results'),
                ),
              ),
              if (successCount > 1)
                _glassIconButton(
                  icon: CupertinoIcons.arrow_down_doc,
                  tooltip: context.t('imageconvert_save_all'),
                  onTap: _saveAll,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: _resultStat(
                  context.t('imageconvert_stat_success'),
                  '$successCount',
                  _success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _resultStat(
                  context.t('imageconvert_stat_failed'),
                  '$failCount',
                  failCount > 0 ? _danger : Colors.white54,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _resultStat(
                  context.t('imageconvert_stat_total'),
                  '${_results.length}',
                  _accentB,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < _results.length; i++) _resultRow(i),
        ],
      ),
    );
  }

  Widget _resultStat(String label, String value, Color color) {
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
              fontSize: 14,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(int index) {
    final BatchConvertItem r = _results[index];
    final Color color = r.isSuccess ? _success : _danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            r.isSuccess
                ? CupertinoIcons.check_mark_circled
                : CupertinoIcons.exclamationmark_triangle,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  r.outputName ?? r.fileName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (r.isSuccess) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    '${_formatBytes(r.originalSize)} → ${_formatBytes(r.convertedSize)}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ] else if (r.error != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    context.t(r.error!),
                    style: const TextStyle(
                      color: Color(0xFFFFBFBF),
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (r.isSuccess && r.bytes != null) ...<Widget>[
            _miniIconButton(
              icon: CupertinoIcons.arrow_down_doc,
              onTap: () => _saveSingle(r),
            ),
            _miniIconButton(
              icon: CupertinoIcons.share,
              onTap: () => _shareSingle(r),
            ),
          ],
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

  Widget _miniIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: Colors.white70),
        ),
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

class _PickedFile {
  final String name;
  final Uint8List bytes;

  _PickedFile({required this.name, required this.bytes});
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