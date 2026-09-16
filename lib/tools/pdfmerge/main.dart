// lib/tools/pdfmerge/main.dart

import 'dart:ui';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/localization/app_localization.dart';
import 'file_picker_helper.dart';
import 'models.dart';
import 'pdf_merge_service.dart';
import 'ui_kit.dart';

class PdfMerge extends StatefulWidget {
  const PdfMerge({super.key});

  @override
  State<PdfMerge> createState() => _PdfMergeState();
}

class _PdfMergeState extends State<PdfMerge> {
  final TextEditingController _outputController =
  TextEditingController(text: 'merged');
  final PdfMergeService _service = const PdfMergeService();

  final List<PdfFileItem> _items = <PdfFileItem>[];
  bool _merging = false;
  bool _saving = false;
  PdfMergeResult? _result;
  String? _lastSavedPath;

  @override
  void dispose() {
    _outputController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final List<PdfFileItem> picked = await FilePickerHelper.pickPdfs();
    if (picked.isEmpty) return;
    setState(() {
      _items.addAll(picked);
      _result = null;
      _lastSavedPath = null;
    });
  }

  void _remove(int index) {
    setState(() {
      _items.removeAt(index);
      _result = null;
      _lastSavedPath = null;
    });
  }

  void _moveUp(int index) {
    if (index <= 0) return;
    setState(() {
      final PdfFileItem item = _items.removeAt(index);
      _items.insert(index - 1, item);
    });
  }

  void _moveDown(int index) {
    if (index >= _items.length - 1) return;
    setState(() {
      final PdfFileItem item = _items.removeAt(index);
      _items.insert(index + 1, item);
    });
  }

  Future<void> _merge() async {
    if (_items.length < 2 || _merging) return;
    setState(() {
      _merging = true;
      _result = null;
      _lastSavedPath = null;
    });
    final PdfMergeResult res = await _service.merge(
      items: _items,
      outputName: _outputController.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _merging = false;
      _result = res;
    });
  }

  Future<void> _saveResult() async {
    final PdfMergeResult? res = _result;
    if (res == null || !res.success || _saving) return;
    setState(() => _saving = true);
    try {
      final String rawName = _outputController.text.trim();
      final String name = rawName.isEmpty ? 'merged' : rawName;
      final String path;
      if (kIsWeb) {
        path = await FileSaver.instance.saveFile(
          name: name,
          bytes: res.bytes,
          fileExtension: 'pdf',
          mimeType: MimeType.pdf,
        );
      } else {
        path = await FileSaver.instance.saveFile(
          name: name,
          filePath: res.path,
          fileExtension: 'pdf',
          mimeType: MimeType.pdf,
        );
      }
      if (!mounted) return;
      setState(() {
        _saving = false;
        _lastSavedPath = path;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.black.withOpacity(0.75),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Text(context.t('pdfmerge_success')),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.black.withOpacity(0.75),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Text(context.t('pdfmerge_error')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: colors.surface.withOpacity(0.35)),
          ),
        ),
        title: Text(
          context.t('pdfmerge_title'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: PdfGlassBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top + kToolbarHeight + 8,
              16,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                PdfGlassButton(
                  label: _items.isEmpty
                      ? context.t('pdfmerge_pick_files')
                      : context.t('pdfmerge_pick_more'),
                  icon: Icons.add_rounded,
                  onPressed: _pickFiles,
                ),
                const SizedBox(height: 14),
                if (_items.isEmpty)
                  PdfGlassSurface(
                    radius: 20,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: <Widget>[
                          Icon(
                            Icons.picture_as_pdf_outlined,
                            size: 56,
                            color: colors.outline,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.t('pdfmerge_no_files'),
                            style: TextStyle(color: colors.outline),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_items.isNotEmpty) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      context.t('pdfmerge_selected_files'),
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  PdfGlassSurface(
                    radius: 20,
                    child: Column(
                      children: <Widget>[
                        for (int i = 0; i < _items.length; i++) ...<Widget>[
                          if (i > 0)
                            Divider(
                              height: 16,
                              color: Colors.white.withOpacity(0.2),
                            ),
                          _fileRow(i),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  PdfGlassSurface(
                    radius: 16,
                    child: TextField(
                      controller: _outputController,
                      decoration: InputDecoration(
                        labelText: context.t('pdfmerge_output_name'),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  PdfGlassButton(
                    label: _merging
                        ? context.t('pdfmerge_merging')
                        : context.t('pdfmerge_merge'),
                    icon: Icons.merge_type_rounded,
                    onPressed: _merge,
                    enabled: _items.length >= 2,
                    loading: _merging,
                  ),
                ],
                if (_result != null) ...<Widget>[
                  const SizedBox(height: 14),
                  if (_result!.success)
                    PdfGlassSurface(
                      radius: 18,
                      opacity: 0.4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Icon(
                                Icons.check_circle_outline_rounded,
                                color: colors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  context.t('pdfmerge_success'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          PdfGlassButton(
                            label: context.t('pdfmerge_download'),
                            icon: Icons.download_rounded,
                            onPressed: _saveResult,
                            loading: _saving,
                          ),
                          if (_lastSavedPath != null &&
                              _lastSavedPath!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _lastSavedPath!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  else
                    PdfGlassSurface(
                      radius: 16,
                      opacity: 0.35,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(
                            Icons.error_outline_rounded,
                            color: colors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  context.t(
                                    _result!.errorKey ?? 'pdfmerge_error',
                                  ),
                                  style: TextStyle(
                                    color: colors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (_result!.errorDetail != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      _result!.errorDetail!,
                                      style: TextStyle(
                                        color: colors.error,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fileRow(int index) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final PdfFileItem item = _items[index];
    return Row(
      children: <Widget>[
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${index + 1}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colors.primary,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                FilePickerHelper.formatSize(item.size),
                style: TextStyle(
                  fontSize: 11,
                  color: colors.outline,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: index == 0 ? null : () => _moveUp(index),
          icon: const Icon(Icons.arrow_upward_rounded, size: 16),
          tooltip: context.t('pdfmerge_move_up'),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed:
          index == _items.length - 1 ? null : () => _moveDown(index),
          icon: const Icon(Icons.arrow_downward_rounded, size: 16),
          tooltip: context.t('pdfmerge_move_down'),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => _remove(index),
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
          tooltip: context.t('pdfmerge_remove'),
        ),
      ],
    );
  }
}