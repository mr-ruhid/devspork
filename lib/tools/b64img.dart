import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../core/localization/app_localization.dart';

class B64Img extends StatefulWidget {
  const B64Img({super.key});

  @override
  State<B64Img> createState() => _B64ImgState();
}

class _B64ImgState extends State<B64Img> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _inputController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _imageBytes;
  String _mimeType = 'image/png';
  String? _errorKey;
  String? _errorDetail;
  bool _autoPrefix = true;
  bool _isBusy = false;

  final List<_HistoryItem> _history = <_HistoryItem>[];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _errorKey = null;
        _errorDetail = null;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  bool get _isEncode => _tabController.index == 0;

  String _guessMime(String name) {
    final String lower = name.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.bmp')) return 'image/bmp';
    if (lower.endsWith('.svg')) return 'image/svg+xml';
    return 'image/png';
  }

  void _pushHistory(String mime, int size, {required bool encoded}) {
    _history.insert(
      0,
      _HistoryItem(mime: mime, size: size, encoded: encoded, at: DateTime.now()),
    );
    if (_history.length > 6) _history.removeLast();
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isBusy = true);
    try {
      final XFile? file = await _picker.pickImage(source: source, imageQuality: 100);
      if (file == null) {
        setState(() => _isBusy = false);
        return;
      }
      final Uint8List bytes = await file.readAsBytes();
      final String mime = _guessMime(file.name);
      setState(() {
        _imageBytes = bytes;
        _mimeType = mime;
        _errorKey = null;
        _errorDetail = null;
      });
      _encodeImage();
    } catch (e) {
      setState(() {
        _errorKey = 'b64img_error_pick';
        _errorDetail = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _encodeImage() {
    if (_imageBytes == null) return;
    HapticFeedback.mediumImpact();
    final String b64 = base64.encode(_imageBytes!);
    final String result = _autoPrefix ? 'data:$_mimeType;base64,$b64' : b64;
    setState(() {
      _inputController.text = result;
      _errorKey = null;
      _errorDetail = null;
    });
    _pushHistory(_mimeType, _imageBytes!.length, encoded: true);
  }

  void _decodeString() {
    final String raw = _inputController.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _imageBytes = null;
        _errorKey = 'b64img_error_empty';
        _errorDetail = null;
      });
      return;
    }
    try {
      String cleaned = raw;
      String mime = 'image/png';
      if (cleaned.startsWith('data:')) {
        final int comma = cleaned.indexOf(',');
        if (comma == -1) throw Exception('invalid data url');
        final String header = cleaned.substring(5, comma);
        final List<String> hp = header.split(';');
        if (hp.isNotEmpty) mime = hp.first;
        cleaned = cleaned.substring(comma + 1);
      }
      cleaned = cleaned.replaceAll(RegExp(r'\s+'), '');
      final Uint8List bytes = base64.decode(cleaned);
      HapticFeedback.mediumImpact();
      setState(() {
        _imageBytes = bytes;
        _mimeType = mime;
        _errorKey = null;
        _errorDetail = null;
      });
      _pushHistory(mime, bytes.length, encoded: false);
    } catch (e) {
      HapticFeedback.heavyImpact();
      setState(() {
        _imageBytes = null;
        _errorKey = 'b64img_error_invalid';
        _errorDetail = e.toString();
      });
    }
  }

  void _clear() {
    HapticFeedback.lightImpact();
    setState(() {
      _inputController.clear();
      _imageBytes = null;
      _errorKey = null;
      _errorDetail = null;
    });
  }

  Future<void> _paste() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null) return;
    HapticFeedback.selectionClick();
    _inputController.text = data.text!;
    if (!_isEncode) _decodeString();
  }

  Future<void> _copy() async {
    if (_inputController.text.isEmpty) return;
    HapticFeedback.mediumImpact();
    await Clipboard.setData(ClipboardData(text: _inputController.text));
    if (!mounted) return;
    _showToast(context.t('b64img_copied'));
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
    Future<void>.delayed(const Duration(milliseconds: 1400), entry.remove);
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String _formatTime(DateTime dt) {
    final String hh = dt.hour.toString().padLeft(2, '0');
    final String mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  // ---------------------------------------------------------
  // ENCODE TAB
  // ---------------------------------------------------------
  Widget _buildEncode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _ImagePreview(bytes: _imageBytes, busy: _isBusy),
                const SizedBox(height: 12),
                if (_imageBytes != null)
                  Row(
                    children: <Widget>[
                      _MiniTag(text: _mimeType),
                      const SizedBox(width: 8),
                      _MiniTag(text: _formatSize(_imageBytes!.length)),
                    ],
                  ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _GlassActionButton(
                        label: context.t('b64img_pick'),
                        icon: CupertinoIcons.photo_on_rectangle,
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _GlassIconButton(
                      icon: CupertinoIcons.camera,
                      onTap: () => _pickImage(ImageSource.camera),
                    ),
                    const SizedBox(width: 8),
                    _GlassIconButton(
                      icon: CupertinoIcons.refresh,
                      onTap: _imageBytes != null ? _encodeImage : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _GlassCard(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    context.t('b64img_auto_prefix'),
                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                  ),
                ),
                _MiniToggle(
                  value: _autoPrefix,
                  onChanged: (bool v) {
                    HapticFeedback.selectionClick();
                    setState(() => _autoPrefix = v);
                    if (_imageBytes != null) _encodeImage();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        context.t('b64img_output_hint'),
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (_inputController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          '${_inputController.text.length} chars',
                          style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11),
                        ),
                      ),
                    _GlassIconButton(icon: CupertinoIcons.doc_on_doc, onTap: _copy),
                    const SizedBox(width: 6),
                    _GlassIconButton(icon: CupertinoIcons.clear, onTap: _clear),
                  ],
                ),
                const SizedBox(height: 8),
                _GlassTextField(
                  controller: _inputController,
                  readOnly: true,
                  maxLines: 8,
                  minLines: 5,
                  monospace: true,
                ),
              ],
            ),
          ),
          if (_history.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            _HistoryCard(history: _history, formatSize: _formatSize, formatTime: _formatTime),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // DECODE TAB
  // ---------------------------------------------------------
  Widget _buildDecode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        context.t('b64img_input_hint'),
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                    ),
                    _GlassIconButton(icon: CupertinoIcons.doc_on_clipboard, onTap: _paste),
                    const SizedBox(width: 6),
                    _GlassIconButton(icon: CupertinoIcons.clear, onTap: _clear),
                  ],
                ),
                const SizedBox(height: 8),
                _GlassTextField(
                  controller: _inputController,
                  maxLines: 7,
                  minLines: 4,
                  monospace: true,
                  hint: 'data:image/png;base64,iVBORw0KGgo...',
                ),
                const SizedBox(height: 12),
                _GlassActionButton(
                  label: context.t('b64img_decode'),
                  icon: CupertinoIcons.wand_stars,
                  onTap: _decodeString,
                ),
                if (_errorKey != null) ...<Widget>[
                  const SizedBox(height: 12),
                  _ErrorBanner(
                    message: context.t(_errorKey!),
                    detail: _errorDetail,
                  ),
                ],
              ],
            ),
          ),
          if (_imageBytes != null) ...<Widget>[
            const SizedBox(height: 16),
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    context.t('b64img_preview'),
                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  _ImagePreview(bytes: _imageBytes, busy: false),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _MiniTag(text: _mimeType),
                      const SizedBox(width: 8),
                      _MiniTag(text: _formatSize(_imageBytes!.length)),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (_history.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            _HistoryCard(history: _history, formatSize: _formatSize, formatTime: _formatTime),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.t('b64img_title'),
          style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.4),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF1B1035),
              Color(0xFF2A1550),
              Color(0xFF0F2A4A),
            ],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(top: -80, left: -60, child: _blurBlob(220, const Color(0xFF7C4DFF))),
            Positioned(bottom: -100, right: -60, child: _blurBlob(260, const Color(0xFF00E5FF))),
            SafeArea(
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 56),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _GlassSegmentedTabs(
                      controller: _tabController,
                      labels: <String>[
                        context.t('b64img_tab_encode'),
                        context.t('b64img_tab_decode'),
                      ],
                      onChanged: (int i) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _tabController.animateTo(i);
                          _errorKey = null;
                          _errorDetail = null;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: <Widget>[_buildEncode(), _buildDecode()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blurBlob(double size, Color color) {
    return IgnorePointer(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.35)),
          ),
        ),
      ),
    );
  }
}

class _HistoryItem {
  _HistoryItem({required this.mime, required this.size, required this.encoded, required this.at});
  final String mime;
  final int size;
  final bool encoded;
  final DateTime at;
}

// ============================================================
// iOS "liquid glass" building blocks
// ============================================================

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: <BoxShadow>[
              BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 12)),
              BoxShadow(color: Colors.white.withOpacity(0.06), blurRadius: 1, offset: const Offset(0, 1)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white.withOpacity(0.08),
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.15)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: enabled ? Colors.white : Colors.white30),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassActionButton extends StatelessWidget {
  const _GlassActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.tint = const Color(0xFF7C4DFF),
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: tint.withOpacity(enabled ? 0.18 : 0.08),
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tint.withOpacity(enabled ? 0.5 : 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(icon, size: 16, color: enabled ? Colors.white : Colors.white30),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: enabled ? Colors.white : Colors.white30,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
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
}

class _GlassTextField extends StatelessWidget {
  const _GlassTextField({
    required this.controller,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.monospace = false,
    this.hint,
  });

  final TextEditingController controller;
  final bool readOnly;
  final int maxLines;
  final int? minLines;
  final bool monospace;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      minLines: minLines,
      style: TextStyle(
        color: Colors.white,
        fontFamily: monospace ? 'monospace' : null,
        fontSize: monospace ? 11 : 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
        filled: true,
        fillColor: Colors.black.withOpacity(0.25),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 1.5),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _MiniToggle extends StatelessWidget {
  const _MiniToggle({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.85,
      child: CupertinoSwitch(value: value, activeColor: const Color(0xFF7C4DFF), onChanged: onChanged),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.bytes, required this.busy});
  final Uint8List? bytes;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 200,
        width: double.infinity,
        color: Colors.black.withOpacity(0.25),
        child: busy
            ? const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00E5FF)),
        )
            : bytes != null
            ? Image.memory(bytes!, fit: BoxFit.contain)
            : Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(CupertinoIcons.photo, size: 44, color: Colors.white.withOpacity(0.3)),
              const SizedBox(height: 8),
              Text(
                context.t('b64img_no_image'),
                style: TextStyle(color: Colors.white.withOpacity(0.35)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, this.detail});
  final String message;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5C7A).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF5C7A).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(CupertinoIcons.exclamationmark_triangle, size: 15, color: Color(0xFFFF5C7A)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Color(0xFFFF5C7A), fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          if (detail != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 21),
              child: Text(
                detail!,
                style: TextStyle(color: const Color(0xFFFF5C7A).withOpacity(0.7), fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.history, required this.formatSize, required this.formatTime});
  final List<_HistoryItem> history;
  final String Function(int) formatSize;
  final String Function(DateTime) formatTime;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(CupertinoIcons.clock, size: 14, color: Colors.white54),
              const SizedBox(width: 6),
              Text(
                context.t('b64img_history'),
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...history.map(
                (_HistoryItem h) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: <Widget>[
                  Icon(
                    h.encoded ? CupertinoIcons.arrow_up_right_circle : CupertinoIcons.arrow_down_left_circle,
                    size: 14,
                    color: h.encoded ? const Color(0xFF00E5FF) : const Color(0xFF7C4DFF),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      h.mime,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                  Text(
                    formatSize(h.size),
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatTime(h.at),
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassSegmentedTabs extends StatelessWidget {
  const _GlassSegmentedTabs({
    required this.controller,
    required this.labels,
    required this.onChanged,
  });

  final TabController controller;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: AnimatedBuilder(
          animation: controller,
          builder: (BuildContext context, _) {
            return Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: Row(
                children: List<Widget>.generate(labels.length, (int i) {
                  final bool selected = controller.index == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onChanged(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFF7C4DFF).withOpacity(0.85) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: selected
                              ? <BoxShadow>[
                            BoxShadow(
                              color: const Color(0xFF7C4DFF).withOpacity(0.45),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          labels[i],
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          },
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
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}