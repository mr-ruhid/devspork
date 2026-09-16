
// lib/tools/imagetopdf/main.dart

import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/localization/app_localization.dart';
import 'image_to_pdf_service.dart';
import 'models.dart';
import 'pdf_to_image_service.dart';
import 'ui_kit.dart';

class ImageToPdfPage extends StatefulWidget {
  const ImageToPdfPage({super.key});

  @override
  State<ImageToPdfPage> createState() => _ImageToPdfPageState();
}

class _ImageToPdfPageState extends State<ImageToPdfPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0B0B12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: colors.surface.withOpacity(0.35)),
          ),
        ),
        title: Text(
          context.t('imagetopdf_title'),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: accentB,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: <Widget>[
            Tab(text: context.t('imagetopdf_tab_image_to_pdf')),
            Tab(text: context.t('imagetopdf_tab_pdf_to_image')),
          ],
        ),
      ),
      body: GlassBackground(
        child: SafeArea(
          child: TabBarView(
            controller: _tabs,
            children: const <Widget>[
              _ImageToPdfTab(),
              _PdfToImageTab(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageToPdfTab extends StatefulWidget {
  const _ImageToPdfTab();

  @override
  State<_ImageToPdfTab> createState() => _ImageToPdfTabState();
}

class _ImageToPdfTabState extends State<_ImageToPdfTab>
    with AutomaticKeepAliveClientMixin {
  final ImageToPdfService _service = const ImageToPdfService();
  final TextEditingController _outputController =
  TextEditingController(text: 'output');

  final List<PickedImageItem> _items = <PickedImageItem>[];
  ImageToPdfConfig _config = ImageToPdfConfig();

  bool _busy = false;
  ImageToPdfResult? _result;
  String? _errorKey;
  String? _errorDetail;

  int _counter = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _outputController.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _errorKey = null;
      _errorDetail = null;
    });

    try {
      final FilePickerResult? picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>[
          'jpg', 'jpeg', 'jpe', 'png', 'webp', 'bmp', 'gif', 'tif', 'tiff',
        ],
        withData: true,
        allowMultiple: true,
      );

      if (picked == null || picked.files.isEmpty) return;

      final List<PickedImageItem> loaded = <PickedImageItem>[];

      for (final PlatformFile file in picked.files) {
        Uint8List? bytes = file.bytes;
        if (bytes == null && file.path != null) {
          try {
            bytes = await File(file.path!).readAsBytes();
          } catch (_) {}
        }
        if (bytes == null) continue;
        _counter++;
        loaded.add(
          PickedImageItem(
            id: 'img_${DateTime.now().microsecondsSinceEpoch}_$_counter',
            name: file.name,
            bytes: bytes,
            size: bytes.length,
          ),
        );
      }

      if (loaded.isEmpty) {
        setState(() => _errorKey = 'imagetopdf_error_decode');
        return;
      }

      setState(() {
        _items.addAll(loaded);
        _result = null;
      });
      HapticFeedback.selectionClick();
    } catch (e) {
      setState(() {
        _errorKey = 'imagetopdf_error_generic';
        _errorDetail = e.toString();
      });
    }
  }

  void _remove(int index) {
    setState(() {
      _items.removeAt(index);
      _result = null;
    });
  }

  void _moveUp(int index) {
    if (index <= 0) return;
    setState(() {
      final PickedImageItem item = _items.removeAt(index);
      _items.insert(index - 1, item);
      _result = null;
    });
  }

  void _moveDown(int index) {
    if (index >= _items.length - 1) return;
    setState(() {
      final PickedImageItem item = _items.removeAt(index);
      _items.insert(index + 1, item);
      _result = null;
    });
  }

  Future<void> _convert() async {
    if (_items.isEmpty || _busy) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _busy = true;
      _errorKey = null;
      _errorDetail = null;
      _result = null;
    });

    final ImageToPdfResult res = await _service.convert(
      items: _items,
      config: _config,
      outputName: _outputController.text,
    );

    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = res;
      if (!res.success) {
        _errorKey = res.errorKey ?? 'imagetopdf_error_generic';
        _errorDetail = res.errorDetail;
      }
    });

    if (res.success) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _save() async {
    final ImageToPdfResult? r = _result;
    if (r == null || !r.success || r.bytes == null) return;
    final String name =
    (r.outputName ?? 'output.pdf').replaceAll('.pdf', '');
    try {
      await FileSaver.instance.saveFile(
        name: name,
        bytes: r.bytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );
      if (!mounted) return;
      _showToast(context.t('imagetopdf_saved'));
      HapticFeedback.lightImpact();
    } catch (e) {
      if (!mounted) return;
      _showToast('${context.t('imagetopdf_error_save')}: $e');
    }
  }

  Future<void> _share() async {
    final ImageToPdfResult? r = _result;
    if (r == null || !r.success || r.bytes == null) return;
    try {
      final Directory dir = await getTemporaryDirectory();
      final File file = File('${dir.path}/${r.outputName ?? 'output.pdf'}');
      await file.writeAsBytes(r.bytes!, flush: true);
      await Share.shareXFiles(
        <XFile>[XFile(file.path)],
        text: r.outputName,
      );
    } catch (e) {
      if (!mounted) return;
      _showToast('${context.t('imagetopdf_error_share')}: $e');
    }
  }

  void _showToast(String message) {
    final OverlayState overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (BuildContext ctx) => Positioned(
        bottom: 90,
        left: 40,
        right: 40,
        child: ToastBubble(message: message),
      ),
    );
    overlay.insert(entry);
    Future<void>.delayed(const Duration(milliseconds: 1600), entry.remove);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _pickCard(),
          if (_items.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            _imageListCard(),
          ],
          const SizedBox(height: 14),
          _pageCard(),
          const SizedBox(height: 14),
          _qualityCard(),
          const SizedBox(height: 14),
          _outputNameCard(),
          const SizedBox(height: 14),
          GradientActionButton(
            label: _busy
                ? context.t('imagetopdf_converting')
                : context.t('imagetopdf_convert'),
            icon: CupertinoIcons.doc_text,
            onPressed: _convert,
            enabled: _items.isNotEmpty,
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
    );
  }

  Widget _pickCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionTitle(
            icon: CupertinoIcons.photo_on_rectangle,
            text: context.t('imagetopdf_section_images'),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pick,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: accentB.withOpacity(0.4),
                  width: 1.2,
                ),
                color: accentB.withOpacity(0.06),
              ),
              child: Column(
                children: <Widget>[
                  Icon(
                    _items.isEmpty
                        ? CupertinoIcons.cloud_upload
                        : CupertinoIcons.check_mark_circled,
                    size: 36,
                    color: accentB,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _items.isEmpty
                        ? context.t('imagetopdf_pick_images')
                        : context.t('imagetopdf_pick_more'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.t('imagetopdf_formats_hint'),
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

  Widget _imageListCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: SectionTitle(
                  icon: CupertinoIcons.list_bullet,
                  text: context.t('imagetopdf_images_selected'),
                ),
              ),
              Text(
                '${_items.length}',
                style: const TextStyle(
                  color: accentB,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < _items.length; i++) _imageRow(i),
        ],
      ),
    );
  }

  Widget _imageRow(int index) {
    final PickedImageItem item = _items[index];
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
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accentB.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: accentB,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  formatBytes(item.size),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          MiniIconButton(
            icon: CupertinoIcons.arrow_up,
            tooltip: context.t('imagetopdf_move_up'),
            onTap: index == 0 ? () {} : () => _moveUp(index),
          ),
          MiniIconButton(
            icon: CupertinoIcons.arrow_down,
            tooltip: context.t('imagetopdf_move_down'),
            onTap: index == _items.length - 1
                ? () {}
                : () => _moveDown(index),
          ),
          MiniIconButton(
            icon: CupertinoIcons.xmark,
            tooltip: context.t('imagetopdf_remove'),
            onTap: () => _remove(index),
          ),
        ],
      ),
    );
  }

  Widget _pageCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionTitle(
            icon: CupertinoIcons.doc,
            text: context.t('imagetopdf_section_page'),
          ),
          const SizedBox(height: 10),
          Text(
            context.t('imagetopdf_page_size'),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              GlassChip(
                label: context.t('imagetopdf_page_auto'),
                selected: _config.pageSize == PageSizePreset.auto,
                onTap: () => setState(() {
                  _config = _config.copyWith(pageSize: PageSizePreset.auto);
                }),
              ),
              GlassChip(
                label: context.t('imagetopdf_page_a4'),
                selected: _config.pageSize == PageSizePreset.a4,
                onTap: () => setState(() {
                  _config = _config.copyWith(pageSize: PageSizePreset.a4);
                }),
              ),
              GlassChip(
                label: context.t('imagetopdf_page_letter'),
                selected: _config.pageSize == PageSizePreset.letter,
                onTap: () => setState(() {
                  _config = _config.copyWith(pageSize: PageSizePreset.letter);
                }),
              ),
              GlassChip(
                label: context.t('imagetopdf_page_legal'),
                selected: _config.pageSize == PageSizePreset.legal,
                onTap: () => setState(() {
                  _config = _config.copyWith(pageSize: PageSizePreset.legal);
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.t('imagetopdf_fit_mode'),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              GlassChip(
                label: context.t('imagetopdf_fit'),
                selected: _config.fitMode == FitMode.fit,
                onTap: () => setState(() {
                  _config = _config.copyWith(fitMode: FitMode.fit);
                }),
              ),
              GlassChip(
                label: context.t('imagetopdf_fill'),
                selected: _config.fitMode == FitMode.fill,
                onTap: () => setState(() {
                  _config = _config.copyWith(fitMode: FitMode.fill);
                }),
              ),
              GlassChip(
                label: context.t('imagetopdf_stretch'),
                selected: _config.fitMode == FitMode.stretch,
                onTap: () => setState(() {
                  _config = _config.copyWith(fitMode: FitMode.stretch);
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GlassSwitchRow(
            label: context.t('imagetopdf_landscape'),
            value: _config.landscape,
            onChanged: (bool v) => setState(() {
              _config = _config.copyWith(landscape: v);
            }),
          ),
          GlassSliderRow(
            label: context.t('imagetopdf_margin'),
            value: _config.margin,
            min: 0,
            max: 60,
            suffix: ' pt',
            onChanged: (double v) => setState(() {
              _config = _config.copyWith(margin: v);
            }),
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
            text: context.t('imagetopdf_section_quality'),
          ),
          const SizedBox(height: 8),
          GlassSliderRow(
            label: context.t('imagetopdf_quality'),
            value: _config.quality.toDouble(),
            min: 10,
            max: 100,
            suffix: '%',
            onChanged: (double v) => setState(() {
              _config = _config.copyWith(quality: v.round());
            }),
          ),
        ],
      ),
    );
  }

  Widget _outputNameCard() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: TextField(
        controller: _outputController,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'monospace',
          fontSize: 13,
        ),
        decoration: InputDecoration(
          labelText: context.t('imagetopdf_output_name'),
          labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
          border: InputBorder.none,
          suffixText: '.pdf',
          suffixStyle: const TextStyle(
            color: Colors.white38,
            fontFamily: 'monospace',
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _resultCard(ImageToPdfResult r) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: SectionTitle(
                  icon: CupertinoIcons.check_mark_circled,
                  text: context.t('imagetopdf_result'),
                ),
              ),
              GlassIconButton(
                icon: CupertinoIcons.arrow_down_doc,
                tooltip: context.t('imagetopdf_save'),
                onTap: _save,
              ),
              const SizedBox(width: 6),
              GlassIconButton(
                icon: CupertinoIcons.share,
                tooltip: context.t('imagetopdf_share'),
                onTap: _share,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _metric(
                  context.t('imagetopdf_pages'),
                  '${r.pageCount}',
                  accentB,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _metric(
                  context.t('imagetopdf_size'),
                  formatBytes(r.bytes?.length ?? 0),
                  successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              r.outputName ?? 'output.pdf',
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

  Widget _metric(String label, String value, Color color) {
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
}

class _PdfToImageTab extends StatefulWidget {
  const _PdfToImageTab();

  @override
  State<_PdfToImageTab> createState() => _PdfToImageTabState();
}

class _PdfToImageTabState extends State<_PdfToImageTab>
    with AutomaticKeepAliveClientMixin {
  final PdfToImageService _service = const PdfToImageService();
  final TextEditingController _rangeController = TextEditingController();

  PickedPdfItem? _pdf;
  PdfToImageConfig _config = PdfToImageConfig();
  PdfToImageResult? _result;

  bool _busy = false;
  String? _errorKey;
  String? _errorDetail;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _rangeController.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
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
        setState(() => _errorKey = 'imagetopdf_error_pdf_generic');
        return;
      }

      setState(() {
        _pdf = PickedPdfItem(
          name: file.name,
          path: file.path ?? '',
          bytes: bytes,
          size: bytes!.length,
        );
        _result = null;
      });
      HapticFeedback.selectionClick();
    } catch (e) {
      setState(() {
        _errorKey = 'imagetopdf_error_pdf_generic';
        _errorDetail = e.toString();
      });
    }
  }

  void _clear() {
    HapticFeedback.lightImpact();
    setState(() {
      _pdf = null;
      _result = null;
      _errorKey = null;
      _errorDetail = null;
      _rangeController.clear();
    });
  }

  Future<void> _convert() async {
    final PickedPdfItem? pdf = _pdf;
    if (pdf == null || pdf.bytes == null || _busy) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _busy = true;
      _errorKey = null;
      _errorDetail = null;
      _result = null;
    });

    final PdfToImageResult res = await _service.convert(
      pdfBytes: pdf.bytes!,
      config: _config,
    );

    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = res;
      if (!res.success) {
        _errorKey = res.errorKey ?? 'imagetopdf_error_pdf_generic';
        _errorDetail = res.errorDetail;
      }
    });

    if (res.success) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  String _extFor(PdfImageFormat f) {
    switch (f) {
      case PdfImageFormat.png:
        return 'png';
      case PdfImageFormat.jpeg:
        return 'jpg';
      case PdfImageFormat.webp:
        return 'webp';
    }
  }

  MimeType _mimeFor(PdfImageFormat f) {
    switch (f) {
      case PdfImageFormat.png:
        return MimeType.png;
      case PdfImageFormat.jpeg:
        return MimeType.jpeg;
      case PdfImageFormat.webp:
        return MimeType.other;
    }
  }

  Future<void> _savePage(PdfPageItem page) async {
    final String ext = _extFor(_config.format);
    try {
      await FileSaver.instance.saveFile(
        name: 'page_${page.pageNumber}',
        bytes: page.bytes,
        fileExtension: ext,
        mimeType: _mimeFor(_config.format),
      );
      if (!mounted) return;
      _showToast(context.t('imagetopdf_saved'));
      HapticFeedback.lightImpact();
    } catch (e) {
      if (!mounted) return;
      _showToast('${context.t('imagetopdf_error_save')}: $e');
    }
  }

  Future<void> _saveAllZip() async {
    final PdfToImageResult? r = _result;
    if (r == null || !r.success || r.pages.isEmpty) return;

    try {
      final Archive archive = Archive();
      final String ext = _extFor(_config.format);
      for (final PdfPageItem page in r.pages) {
        final ArchiveFile file = ArchiveFile(
          'page_${page.pageNumber}.$ext',
          page.bytes.length,
          page.bytes,
        );
        archive.addFile(file);
      }
      final List<int>? encoded = ZipEncoder().encode(archive);
      if (encoded == null) {
        if (!mounted) return;
        _showToast(context.t('imagetopdf_error_save'));
        return;
      }
      await FileSaver.instance.saveFile(
        name: (_pdf?.name ?? 'pages').replaceAll('.pdf', ''),
        bytes: Uint8List.fromList(encoded),
        fileExtension: 'zip',
        mimeType: MimeType.zip,
      );
      if (!mounted) return;
      _showToast(context.t('imagetopdf_saved'));
      HapticFeedback.lightImpact();
    } catch (e) {
      if (!mounted) return;
      _showToast('${context.t('imagetopdf_error_save')}: $e');
    }
  }

  void _showToast(String message) {
    final OverlayState overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (BuildContext ctx) => Positioned(
        bottom: 90,
        left: 40,
        right: 40,
        child: ToastBubble(message: message),
      ),
    );
    overlay.insert(entry);
    Future<void>.delayed(const Duration(milliseconds: 1600), entry.remove);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _pickCard(),
          const SizedBox(height: 14),
          _optionsCard(),
          const SizedBox(height: 14),
          GradientActionButton(
            label: _busy
                ? context.t('imagetopdf_rendering')
                : context.t('imagetopdf_convert_images'),
            icon: CupertinoIcons.photo_on_rectangle,
            onPressed: _convert,
            enabled: _pdf != null,
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
            _resultsHeader(_result!),
            const SizedBox(height: 10),
            for (final PdfPageItem page in _result!.pages) ...<Widget>[
              _pagePreview(page),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }

  Widget _pickCard() {
    final PickedPdfItem? pdf = _pdf;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionTitle(
            icon: CupertinoIcons.doc_text,
            text: context.t('imagetopdf_section_pdf'),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickPdf,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: accentB.withOpacity(0.4),
                  width: 1.2,
                ),
                color: accentB.withOpacity(0.06),
              ),
              child: Column(
                children: <Widget>[
                  Icon(
                    pdf == null
                        ? CupertinoIcons.cloud_upload
                        : CupertinoIcons.doc_text_fill,
                    size: 36,
                    color: accentB,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pdf?.name ?? context.t('imagetopdf_pick_pdf'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (pdf != null) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      formatBytes(pdf.size),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (pdf != null) ...<Widget>[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _clear,
                icon: const Icon(
                  CupertinoIcons.xmark_circle,
                  size: 16,
                  color: dangerColor,
                ),
                label: Text(
                  context.t('imagetopdf_remove'),
                  style: const TextStyle(color: dangerColor, fontSize: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _optionsCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionTitle(
            icon: CupertinoIcons.slider_horizontal_3,
            text: context.t('imagetopdf_section_output'),
          ),
          const SizedBox(height: 10),
          Text(
            context.t('imagetopdf_format'),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: PdfImageFormat.values.map((PdfImageFormat f) {
              return GlassChip(
                label: _extFor(f).toUpperCase(),
                selected: _config.format == f,
                onTap: () => setState(() {
                  _config = _config.copyWith(format: f);
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          GlassSliderRow(
            label: context.t('imagetopdf_dpi'),
            value: _config.dpi.toDouble(),
            min: 72,
            max: 300,
            divisions: 228,
            onChanged: (double v) => setState(() {
              _config = _config.copyWith(dpi: v.round());
            }),
          ),
          if (_config.format != PdfImageFormat.png)
            GlassSliderRow(
              label: context.t('imagetopdf_quality'),
              value: _config.quality.toDouble(),
              min: 10,
              max: 100,
              suffix: '%',
              onChanged: (double v) => setState(() {
                _config = _config.copyWith(quality: v.round());
              }),
            ),
          const SizedBox(height: 4),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            radius: 12,
            child: TextField(
              controller: _rangeController,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
              onChanged: (String v) => setState(() {
                _config = _config.copyWith(pageRange: v);
              }),
              decoration: InputDecoration(
                labelText: context.t('imagetopdf_page_range'),
                hintText: context.t('imagetopdf_page_range_hint'),
                hintStyle: const TextStyle(
                  color: Colors.white24,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
                labelStyle:
                const TextStyle(color: Colors.white60, fontSize: 12),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultsHeader(PdfToImageResult r) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: SectionTitle(
                  icon: CupertinoIcons.check_mark_circled,
                  text: context.t('imagetopdf_pages_found'),
                ),
              ),
              if (r.pages.length > 1)
                GlassIconButton(
                  icon: CupertinoIcons.arrow_down_doc,
                  tooltip: context.t('imagetopdf_save_all_zip'),
                  onTap: _saveAllZip,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _metric(
                  context.t('imagetopdf_total'),
                  '${r.totalPages}',
                  accentB,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _metric(
                  context.t('imagetopdf_exported'),
                  '${r.pages.length}',
                  successColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pagePreview(PdfPageItem page) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${context.t('imagetopdf_page')} ${page.pageNumber}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              Text(
                formatBytes(page.bytes.length),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 6),
              MiniIconButton(
                icon: CupertinoIcons.arrow_down_doc,
                tooltip: context.t('imagetopdf_save_page'),
                onTap: () => _savePage(page),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 340),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.memory(
              page.bytes,
              fit: BoxFit.contain,
              gaplessPlayback: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
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
}