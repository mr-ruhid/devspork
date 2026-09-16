// lib/tools/pdfcompress.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as p;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';

import '../core/localization/app_localization.dart';
import '../core/theme/app_ui_kit.dart';

enum _Preset { low, medium, high, custom }

class PdfCompress extends StatefulWidget {
  const PdfCompress({super.key});

  @override
  State<PdfCompress> createState() => _PdfCompressState();
}

class _PdfCompressState extends State<PdfCompress> {
  String? _fileName;
  Uint8List? _originalBytes;
  int _originalSize = 0;
  int _pageCount = 0;

  Uint8List? _compressedBytes;
  int _compressedSize = 0;

  _Preset _preset = _Preset.medium;
  int _quality = 60;
  int _dpi = 100;
  bool _grayscale = false;

  bool _busy = false;
  double _progress = 0;
  String? _errorKey;
  String? _errorDetail;

  Future<void> _pick() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _errorKey = null;
      _errorDetail = null;
    });

    try {
      final FilePickerResult? picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['pdf'],
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
        setState(() => _errorKey = 'pdfcompress_error_read');
        return;
      }

      int pages = 0;
      PdfDocument? doc;
      try {
        doc = await PdfDocument.openData(bytes);
        pages = doc.pagesCount;
      } catch (_) {
        pages = 0;
      } finally {
        await doc?.close();
      }

      setState(() {
        _fileName = file.name;
        _originalBytes = bytes;
        _originalSize = bytes!.length;
        _pageCount = pages;
        _compressedBytes = null;
        _compressedSize = 0;
      });
    } catch (e) {
      setState(() {
        _errorKey = 'pdfcompress_error_read';
        _errorDetail = e.toString();
      });
    }
  }

  void _applyPreset(_Preset preset) {
    setState(() {
      _preset = preset;
      switch (preset) {
        case _Preset.low:
          _quality = 80;
          _dpi = 140;
          break;
        case _Preset.medium:
          _quality = 60;
          _dpi = 100;
          break;
        case _Preset.high:
          _quality = 40;
          _dpi = 72;
          break;
        case _Preset.custom:
          break;
      }
      _compressedBytes = null;
      _compressedSize = 0;
    });
  }

  void _reset() {
    setState(() {
      _fileName = null;
      _originalBytes = null;
      _originalSize = 0;
      _pageCount = 0;
      _compressedBytes = null;
      _compressedSize = 0;
      _errorKey = null;
      _errorDetail = null;
      _progress = 0;
    });
  }

  Future<void> _compress() async {
    final Uint8List? input = _originalBytes;
    if (input == null || _busy) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _busy = true;
      _errorKey = null;
      _errorDetail = null;
      _compressedBytes = null;
      _compressedSize = 0;
      _progress = 0;
    });

    PdfDocument? source;
    try {
      source = await PdfDocument.openData(input);
      final int total = source.pagesCount;

      if (total == 0) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _errorKey = 'pdfcompress_error_empty';
        });
        return;
      }

      final double scale = _dpi / 72.0;
      final pw.Document out = pw.Document();

      for (int i = 1; i <= total; i++) {
        final PdfPage page = await source.getPage(i);
        final int targetWidth = (page.width * scale).round();
        final int targetHeight = (page.height * scale).round();

        final PdfPageImage? rendered = await page.render(
          width: targetWidth.toDouble(),
          height: targetHeight.toDouble(),
          format: PdfPageImageFormat.png,
        );

        await page.close();

        if (rendered == null || rendered.bytes.isEmpty) continue;

        final Uint8List pngBytes = Uint8List.fromList(rendered.bytes);
        img.Image? decoded = img.decodeImage(pngBytes);
        if (decoded == null) continue;

        if (_grayscale) {
          decoded = img.grayscale(decoded);
        }

        final Uint8List jpegBytes = Uint8List.fromList(
          img.encodeJpg(decoded, quality: _quality.clamp(10, 100)),
        );

        final pw.MemoryImage memImage = pw.MemoryImage(jpegBytes);

        out.addPage(
          pw.Page(
            pageFormat: p.PdfPageFormat(page.width, page.height),
            margin: pw.EdgeInsets.zero,
            build: (pw.Context ctx) {
              return pw.FullPage(
                ignoreMargins: true,
                child: pw.Image(memImage, fit: pw.BoxFit.fill),
              );
            },
          ),
        );

        if (mounted) {
          setState(() => _progress = i / total);
        }
      }

      if (out.document.pdfPageList.pages.isEmpty) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _errorKey = 'pdfcompress_error_render';
        });
        return;
      }

      final Uint8List result = await out.save();

      if (!mounted) return;
      setState(() {
        _busy = false;
        _compressedBytes = result;
        _compressedSize = result.length;
        _progress = 1;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorKey = 'pdfcompress_error_generic';
        _errorDetail = e.toString();
      });
    } finally {
      await source?.close();
    }
  }

  Future<void> _save() async {
    final Uint8List? bytes = _compressedBytes;
    final String? name = _fileName;
    if (bytes == null || name == null) return;

    final String base = name.replaceAll('.pdf', '');
    final String outputName = '${base}_compressed';

    try {
      await FileSaver.instance.saveFile(
        name: outputName,
        bytes: bytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );
      if (!mounted) return;
      showGlassToast(context, context.t('pdfcompress_saved'));
    } catch (e) {
      if (!mounted) return;
      showGlassToast(context, '${context.t('pdfcompress_error_save')}: $e');
    }
  }

  Future<void> _share() async {
    final Uint8List? bytes = _compressedBytes;
    final String? name = _fileName;
    if (bytes == null || name == null) return;

    try {
      final String base = name.replaceAll('.pdf', '');
      final Directory dir = await getTemporaryDirectory();
      final File file = File('${dir.path}/${base}_compressed.pdf');
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles(
        <XFile>[XFile(file.path)],
        text: '${base}_compressed.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      showGlassToast(context, '${context.t('pdfcompress_error_share')}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: kScaffoldBg,
      appBar: GlassAppBar(
        title: context.t('pdfcompress_title'),
        actions: <Widget>[
          if (_originalBytes != null)
            GlassIconButton(
              icon: CupertinoIcons.refresh,
              tooltip: context.t('pdfcompress_reset'),
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
                if (_originalBytes != null) ...<Widget>[
                  const SizedBox(height: 14),
                  _infoCard(),
                ],
                const SizedBox(height: 14),
                _presetCard(),
                if (_preset == _Preset.custom) ...<Widget>[
                  const SizedBox(height: 14),
                  _customCard(),
                ],
                const SizedBox(height: 14),
                GradientActionButton(
                  label: _busy
                      ? context.t('pdfcompress_compressing')
                      : context.t('pdfcompress_compress'),
                  icon: CupertinoIcons.arrow_down_right_square,
                  onPressed: _compress,
                  enabled: _originalBytes != null,
                  loading: _busy,
                ),
                if (_busy) ...<Widget>[
                  const SizedBox(height: 14),
                  _progressCard(),
                ],
                if (_errorKey != null) ...<Widget>[
                  const SizedBox(height: 14),
                  ErrorBox(
                    message: context.t(_errorKey!),
                    detail: _errorDetail,
                  ),
                ],
                if (_compressedBytes != null) ...<Widget>[
                  const SizedBox(height: 14),
                  _resultCard(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pickCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionTitle(
            icon: CupertinoIcons.doc_text,
            text: context.t('pdfcompress_section_pdf'),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pick,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: kAccentB.withOpacity(0.4),
                  width: 1.2,
                ),
                color: kAccentB.withOpacity(0.06),
              ),
              child: Column(
                children: <Widget>[
                  Icon(
                    _originalBytes == null
                        ? CupertinoIcons.cloud_upload
                        : CupertinoIcons.doc_text_fill,
                    size: 36,
                    color: kAccentB,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _fileName ?? context.t('pdfcompress_pick_pdf'),
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
                      formatBytes(_originalSize),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard() {
    return GlassCard(
      child: Row(
        children: <Widget>[
          Expanded(
            child: MetricBox(
              label: context.t('pdfcompress_pages'),
              value: '$_pageCount',
              color: kAccentB,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: MetricBox(
              label: context.t('pdfcompress_original_size'),
              value: formatBytes(_originalSize),
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: MetricBox(
              label: context.t('pdfcompress_savings'),
              value: _compressedSize == 0
                  ? '—'
                  : '${((1 - _compressedSize / _originalSize) * 100).toStringAsFixed(1)}%',
              color: _compressedSize == 0
                  ? Colors.white54
                  : (_compressedSize < _originalSize ? kSuccess : kDanger),
            ),
          ),
        ],
      ),
    );
  }

  Widget _presetCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionTitle(
            icon: CupertinoIcons.slider_horizontal_3,
            text: context.t('pdfcompress_section_preset'),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _presetChip(
                context.t('pdfcompress_preset_low'),
                context.t('pdfcompress_preset_low_hint'),
                _Preset.low,
                kSuccess,
              ),
              _presetChip(
                context.t('pdfcompress_preset_medium'),
                context.t('pdfcompress_preset_medium_hint'),
                _Preset.medium,
                kAccentB,
              ),
              _presetChip(
                context.t('pdfcompress_preset_high'),
                context.t('pdfcompress_preset_high_hint'),
                _Preset.high,
                kAccentA,
              ),
              _presetChip(
                context.t('pdfcompress_preset_custom'),
                context.t('pdfcompress_preset_custom_hint'),
                _Preset.custom,
                Colors.white70,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _presetChip(String label, String hint, _Preset preset, Color color) {
    final bool selected = _preset == preset;
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

  Widget _customCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionTitle(
            icon: CupertinoIcons.settings,
            text: context.t('pdfcompress_section_custom'),
          ),
          const SizedBox(height: 8),
          GlassSliderRow(
            label: context.t('pdfcompress_quality'),
            value: _quality.toDouble(),
            min: 10,
            max: 100,
            suffix: '%',
            onChanged: (double v) => setState(() {
              _quality = v.round();
              _compressedBytes = null;
              _compressedSize = 0;
            }),
          ),
          GlassSliderRow(
            label: context.t('pdfcompress_dpi'),
            value: _dpi.toDouble(),
            min: 50,
            max: 200,
            divisions: 150,
            onChanged: (double v) => setState(() {
              _dpi = v.round();
              _compressedBytes = null;
              _compressedSize = 0;
            }),
          ),
          GlassSwitchRow(
            label: context.t('pdfcompress_grayscale'),
            value: _grayscale,
            onChanged: (bool v) => setState(() {
              _grayscale = v;
              _compressedBytes = null;
              _compressedSize = 0;
            }),
          ),
        ],
      ),
    );
  }

  Widget _progressCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.white12,
            color: kAccentB,
          ),
          const SizedBox(height: 10),
          Text(
            '${(_progress * 100).toStringAsFixed(0)}%',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kAccentB,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultCard() {
    final bool smaller = _compressedSize < _originalSize;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: SectionTitle(
                  icon: CupertinoIcons.check_mark_circled,
                  text: context.t('pdfcompress_result'),
                ),
              ),
              GlassIconButton(
                icon: CupertinoIcons.arrow_down_doc,
                tooltip: context.t('pdfcompress_save'),
                onTap: _save,
              ),
              const SizedBox(width: 6),
              GlassIconButton(
                icon: CupertinoIcons.share,
                tooltip: context.t('pdfcompress_share'),
                onTap: _share,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: MetricBox(
                  label: context.t('pdfcompress_before'),
                  value: formatBytes(_originalSize),
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MetricBox(
                  label: context.t('pdfcompress_after'),
                  value: formatBytes(_compressedSize),
                  color: kAccentB,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MetricBox(
                  label: context.t('pdfcompress_saved_label'),
                  value:
                  '${((1 - _compressedSize / _originalSize) * 100).toStringAsFixed(1)}%',
                  color: smaller ? kSuccess : kWarning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}