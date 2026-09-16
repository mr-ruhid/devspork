// lib/tools/pdfsplit/main.dart

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/cupertino.dart';
// NOTE: both `package:flutter/material.dart` and our own `ui_kit.dart`
// declare a widget named `ActionChip`. Importing both unprefixed made
// the name ambiguous ("defined in libraries A and B"), which is exactly
// the compile error you hit. We only want *our* glass-style ActionChip
// (label/icon/onTap), so we hide Material's version at the import site
// rather than renaming our own widget everywhere it's used.
import 'package:flutter/material.dart' hide ActionChip;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/localization/app_localization.dart';
import 'models.dart';
import 'pdf_preview_service.dart';
import 'pdf_split_service.dart';
import 'ui_kit.dart';

class PdfSplitPage extends StatefulWidget {
  const PdfSplitPage({super.key});

  @override
  State<PdfSplitPage> createState() => _PdfSplitPageState();
}

class _PdfSplitPageState extends State<PdfSplitPage> {
  final PdfPreviewService _previewService = const PdfPreviewService();
  final PdfSplitService _splitService = const PdfSplitService();
  final TextEditingController _rangeController = TextEditingController();

  PickedPdf? _pdf;
  List<PageThumbnail> _thumbnails = <PageThumbnail>[];
  final Set<int> _selectedPages = <int>{};

  SplitMode _mode = SplitMode.extract;
  SplitResult? _result;

  bool _loadingPreview = false;
  bool _busy = false;
  String? _errorKey;
  String? _errorDetail;

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
        setState(() => _errorKey = 'pdfsplit_error_read');
        return;
      }

      setState(() {
        _pdf = PickedPdf(
          name: file.name,
          path: file.path ?? '',
          bytes: bytes,
          size: bytes!.length,
          pageCount: 0,
        );
        _thumbnails = <PageThumbnail>[];
        _selectedPages.clear();
        _result = null;
        _loadingPreview = true;
      });

      HapticFeedback.selectionClick();
      await _loadPreview(bytes);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingPreview = false;
        _errorKey = 'pdfsplit_error_read';
        _errorDetail = e.toString();
      });
    }
  }

  Future<void> _loadPreview(Uint8List bytes) async {
    final PreviewResult res = await _previewService.generateThumbnails(
      pdfBytes: bytes,
    );

    if (!mounted) return;

    if (!res.success) {
      setState(() {
        _loadingPreview = false;
        _errorKey = res.errorKey ?? 'pdfsplit_error_preview';
        _errorDetail = res.errorDetail;
      });
      return;
    }

    setState(() {
      _loadingPreview = false;
      _thumbnails = res.thumbnails;
      _pdf = _pdf?.copyWithPageCount(res.totalPages);
    });
  }

  void _clear() {
    HapticFeedback.lightImpact();
    setState(() {
      _pdf = null;
      _thumbnails = <PageThumbnail>[];
      _selectedPages.clear();
      _result = null;
      _errorKey = null;
      _errorDetail = null;
      _rangeController.clear();
    });
  }

  void _togglePage(int pageNumber) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedPages.contains(pageNumber)) {
        _selectedPages.remove(pageNumber);
      } else {
        _selectedPages.add(pageNumber);
      }
      _result = null;
    });
  }

  void _selectAll() {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPages
        ..clear()
        ..addAll(_thumbnails.map((PageThumbnail t) => t.pageNumber));
    });
  }

  void _clearSelection() {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPages.clear();
    });
  }

  void _invertSelection() {
    HapticFeedback.selectionClick();
    setState(() {
      final Set<int> inverted = <int>{};
      for (final PageThumbnail t in _thumbnails) {
        if (!_selectedPages.contains(t.pageNumber)) {
          inverted.add(t.pageNumber);
        }
      }
      _selectedPages
        ..clear()
        ..addAll(inverted);
    });
  }

  // NEW: quick odd/even selection — handy for the classic
  // "print double-sided then split" workflow.
  void _selectOdd() {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPages
        ..clear()
        ..addAll(_thumbnails.map((PageThumbnail t) => t.pageNumber).where((int p) => p.isOdd));
    });
  }

  void _selectEven() {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPages
        ..clear()
        ..addAll(_thumbnails.map((PageThumbnail t) => t.pageNumber).where((int p) => p.isEven));
    });
  }

  void _applyRange() {
    final String raw = _rangeController.text.trim();
    if (raw.isEmpty) return;
    final int total = _pdf?.pageCount ?? _thumbnails.length;
    final Set<int> pages = _parseRange(raw, total);
    if (pages.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPages
        ..clear()
        ..addAll(pages);
    });
  }

  Set<int> _parseRange(String raw, int total) {
    final Set<int> pages = <int>{};
    final List<String> parts = raw.split(',');
    for (final String rawPart in parts) {
      final String part = rawPart.trim();
      if (part.isEmpty) continue;
      if (part.contains('-')) {
        final List<String> bounds = part.split('-');
        if (bounds.length != 2) continue;
        final int? lo = int.tryParse(bounds[0].trim());
        final int? hi = int.tryParse(bounds[1].trim());
        if (lo == null || hi == null) continue;
        final int start = lo < 1 ? 1 : lo;
        final int end = hi > total ? total : hi;
        for (int i = start; i <= end; i++) {
          pages.add(i);
        }
      } else {
        final int? single = int.tryParse(part);
        if (single == null) continue;
        if (single >= 1 && single <= total) pages.add(single);
      }
    }
    return pages;
  }

  Future<void> _split() async {
    final PickedPdf? pdf = _pdf;
    if (pdf == null || pdf.bytes == null || _busy) return;
    if (_selectedPages.isEmpty) {
      setState(() {
        _errorKey = 'pdfsplit_error_no_pages';
        _errorDetail = null;
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _busy = true;
      _errorKey = null;
      _errorDetail = null;
      _result = null;
    });

    final SplitResult res = await _splitService.split(
      pdfBytes: pdf.bytes!,
      selectedPages: _selectedPages.toList()..sort(),
      mode: _mode,
      baseName: pdf.name,
    );

    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = res;
      if (!res.success) {
        _errorKey = res.errorKey ?? 'pdfsplit_error_generic';
        _errorDetail = res.errorDetail;
      }
    });

    if (res.success) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _saveItem(SplitResultItem item) async {
    try {
      await FileSaver.instance.saveFile(
        name: item.fileName.replaceAll('.pdf', ''),
        bytes: item.bytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );
      if (!mounted) return;
      _showToast(context.t('pdfsplit_saved'));
      HapticFeedback.lightImpact();
    } catch (e) {
      if (!mounted) return;
      _showToast('${context.t('pdfsplit_error_save')}: $e');
    }
  }

  Future<void> _saveAllZip() async {
    final SplitResult? r = _result;
    if (r == null || !r.success || r.items.isEmpty) return;
    if (r.items.length == 1) {
      await _saveItem(r.items.first);
      return;
    }

    try {
      final Archive archive = Archive();
      for (final SplitResultItem item in r.items) {
        archive.addFile(
          ArchiveFile(item.fileName, item.bytes.length, item.bytes),
        );
      }
      final List<int>? encoded = ZipEncoder().encode(archive);
      if (encoded == null) {
        if (!mounted) return;
        _showToast(context.t('pdfsplit_error_save'));
        return;
      }
      final String base = (_pdf?.name ?? 'split').replaceAll('.pdf', '');
      await FileSaver.instance.saveFile(
        name: '$base-split',
        bytes: Uint8List.fromList(encoded),
        fileExtension: 'zip',
        mimeType: MimeType.zip,
      );
      if (!mounted) return;
      _showToast(context.t('pdfsplit_saved'));
      HapticFeedback.lightImpact();
    } catch (e) {
      if (!mounted) return;
      _showToast('${context.t('pdfsplit_error_save')}: $e');
    }
  }

  Future<void> _shareItem(SplitResultItem item) async {
    try {
      final Directory dir = await getTemporaryDirectory();
      final File file = File('${dir.path}/${item.fileName}');
      await file.writeAsBytes(item.bytes, flush: true);
      await Share.shareXFiles(
        <XFile>[XFile(file.path)],
        text: item.fileName,
      );
    } catch (e) {
      if (!mounted) return;
      _showToast('${context.t('pdfsplit_error_share')}: $e');
    }
  }

  // NEW: share every split file at once, mirroring _saveAllZip.
  Future<void> _shareAll() async {
    final SplitResult? r = _result;
    if (r == null || !r.success || r.items.isEmpty) return;
    try {
      final Directory dir = await getTemporaryDirectory();
      final List<XFile> files = <XFile>[];
      for (final SplitResultItem item in r.items) {
        final File file = File('${dir.path}/${item.fileName}');
        await file.writeAsBytes(item.bytes, flush: true);
        files.add(XFile(file.path));
      }
      await Share.shareXFiles(files);
    } catch (e) {
      if (!mounted) return;
      _showToast('${context.t('pdfsplit_error_share')}: $e');
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
          context.t('pdfsplit_title'),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        actions: <Widget>[
          if (_pdf != null)
            GlassIconButton(
              icon: CupertinoIcons.refresh,
              tooltip: context.t('pdfsplit_reset'),
              onTap: _clear,
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
                if (_pdf != null) ...<Widget>[
                  const SizedBox(height: 14),
                  _pdfInfoCard(),
                ],
                if (_loadingPreview) ...<Widget>[
                  const SizedBox(height: 14),
                  _loadingCard(),
                ],
                if (!_loadingPreview && _thumbnails.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 14),
                  _selectionToolsCard(),
                  const SizedBox(height: 14),
                  _pagesGridCard(),
                  const SizedBox(height: 14),
                  _modeCard(),
                  const SizedBox(height: 14),
                  GradientActionButton(
                    label: _busy
                        ? context.t('pdfsplit_splitting')
                        : context.t('pdfsplit_split'),
                    icon: CupertinoIcons.scissors,
                    onPressed: _split,
                    enabled: _selectedPages.isNotEmpty,
                    loading: _busy,
                  ),
                ],
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

  Widget _pickCard() {
    final PickedPdf? pdf = _pdf;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionTitle(
            icon: CupertinoIcons.doc_text,
            text: context.t('pdfsplit_section_pdf'),
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
                    pdf?.name ?? context.t('pdfsplit_pick_pdf'),
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
        ],
      ),
    );
  }

  Widget _pdfInfoCard() {
    final PickedPdf pdf = _pdf!;
    return GlassCard(
      child: Row(
        children: <Widget>[
          Expanded(
            child: _metric(
              context.t('pdfsplit_total_pages'),
              '${pdf.pageCount}',
              accentB,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _metric(
              context.t('pdfsplit_selected_pages'),
              '${_selectedPages.length}',
              successColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _metric(
              context.t('pdfsplit_file_size'),
              formatBytes(pdf.size),
              warningColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingCard() {
    return GlassCard(
      child: Column(
        children: <Widget>[
          const LinearProgressIndicator(
            backgroundColor: Colors.white12,
            color: accentB,
          ),
          const SizedBox(height: 10),
          Text(
            context.t('pdfsplit_loading_preview'),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _selectionToolsCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionTitle(
            icon: CupertinoIcons.checkmark_seal,
            text: context.t('pdfsplit_section_select'),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ActionChip(
                label: context.t('pdfsplit_select_all'),
                icon: CupertinoIcons.checkmark_alt,
                onTap: _selectAll,
              ),
              ActionChip(
                label: context.t('pdfsplit_invert'),
                icon: CupertinoIcons.arrow_2_circlepath,
                onTap: _invertSelection,
              ),
              // NEW: odd/even quick-select — common for double-sided
              // scan/print workflows.
              ActionChip(
                label: context.t('pdfsplit_select_odd'),
                icon: CupertinoIcons.number,
                onTap: _selectOdd,
              ),
              ActionChip(
                label: context.t('pdfsplit_select_even'),
                icon: CupertinoIcons.number_circle,
                onTap: _selectEven,
              ),
              ActionChip(
                label: context.t('pdfsplit_clear'),
                icon: CupertinoIcons.xmark,
                onTap: _clearSelection,
              ),
            ],
          ),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            radius: 12,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _rangeController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                    onSubmitted: (_) => _applyRange(),
                    decoration: InputDecoration(
                      labelText: context.t('pdfsplit_range_label'),
                      hintText: context.t('pdfsplit_range_hint'),
                      hintStyle: const TextStyle(
                        color: Colors.white24,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                      labelStyle: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                MiniIconButton(
                  icon: CupertinoIcons.arrow_right_circle,
                  tooltip: context.t('pdfsplit_apply_range'),
                  onTap: _applyRange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pagesGridCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: SectionTitle(
                  icon: CupertinoIcons.rectangle_grid_2x2,
                  text: context.t('pdfsplit_pages_preview'),
                ),
              ),
              Text(
                '${_selectedPages.length} / ${_thumbnails.length}',
                style: const TextStyle(
                  color: accentB,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.72,
            ),
            itemCount: _thumbnails.length,
            itemBuilder: (BuildContext context, int index) {
              return _pageThumb(_thumbnails[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _pageThumb(PageThumbnail thumb) {
    final bool selected = _selectedPages.contains(thumb.pageNumber);
    return GestureDetector(
      onTap: () => _togglePage(thumb.pageNumber),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? accentB : Colors.white.withOpacity(0.15),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? <BoxShadow>[
            BoxShadow(
              color: accentB.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Container(
                color: Colors.black.withOpacity(0.4),
                child: Image.memory(
                  thumb.bytes,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
              ),
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${thumb.pageNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              if (selected)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: accentB,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.checkmark,
                      size: 10,
                      color: Colors.black,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionTitle(
            icon: CupertinoIcons.scissors,
            text: context.t('pdfsplit_section_mode'),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              GlassChip(
                label: context.t('pdfsplit_mode_extract'),
                selected: _mode == SplitMode.extract,
                onTap: () => setState(() {
                  _mode = SplitMode.extract;
                  _result = null;
                }),
              ),
              GlassChip(
                label: context.t('pdfsplit_mode_split_each'),
                selected: _mode == SplitMode.splitEach,
                onTap: () => setState(() {
                  _mode = SplitMode.splitEach;
                  _result = null;
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resultCard(SplitResult r) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: SectionTitle(
                  icon: CupertinoIcons.check_mark_circled,
                  text: context.t('pdfsplit_result'),
                ),
              ),
              if (r.items.length > 1) ...<Widget>[
                GlassIconButton(
                  icon: CupertinoIcons.share,
                  tooltip: context.t('pdfsplit_share'),
                  onTap: _shareAll,
                ),
                const SizedBox(width: 6),
                GlassIconButton(
                  icon: CupertinoIcons.arrow_down_doc,
                  tooltip: context.t('pdfsplit_save_all_zip'),
                  onTap: _saveAllZip,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < r.items.length; i++) _resultRow(r.items[i]),
        ],
      ),
    );
  }

  Widget _resultRow(SplitResultItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: successColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: successColor.withOpacity(0.25)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            CupertinoIcons.doc_text_fill,
            size: 14,
            color: successColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.fileName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${context.t('pdfsplit_pages')}: ${item.pageNumbers.join(', ')} · ${formatBytes(item.bytes.length)}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          MiniIconButton(
            icon: CupertinoIcons.arrow_down_doc,
            tooltip: context.t('pdfsplit_save'),
            onTap: () => _saveItem(item),
          ),
          MiniIconButton(
            icon: CupertinoIcons.share,
            tooltip: context.t('pdfsplit_share'),
            onTap: () => _shareItem(item),
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