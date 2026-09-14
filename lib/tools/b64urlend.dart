import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class B64UrlEnd extends StatefulWidget {
  const B64UrlEnd({super.key});

  @override
  State<B64UrlEnd> createState() => _B64UrlEndState();
}

class _B64UrlEndState extends State<B64UrlEnd> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();

  String? _errorKey;
  bool _urlSafe = false;
  bool _liveMode = false;
  Timer? _debounce;

  final List<_HistoryItem> _history = <_HistoryItem>[];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() => _errorKey = null);
    });
    _inputController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabController.dispose();
    _inputController.removeListener(_onInputChanged);
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  bool get _isBase64 => _tabController.index == 0;

  void _onInputChanged() {
    setState(() {}); // refresh char counter
    if (!_liveMode) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _encode);
  }

  void _pushHistory(String input, String output, bool encoded) {
    if (input.trim().isEmpty) return;
    _history.insert(
      0,
      _HistoryItem(
        input: input,
        output: output,
        encoded: encoded,
        mode: _isBase64 ? 'Base64' : 'URL',
        at: DateTime.now(),
      ),
    );
    if (_history.length > 6) _history.removeLast();
  }

  String _b64Encode(String input) {
    final String b64 = base64.encode(utf8.encode(input));
    if (!_urlSafe) return b64;
    return b64.replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '');
  }

  String _b64Decode(String input) {
    String normalized = input.replaceAll('-', '+').replaceAll('_', '/');
    while (normalized.length % 4 != 0) {
      normalized += '=';
    }
    return utf8.decode(base64.decode(normalized));
  }

  void _encode() {
    final String input = _inputController.text;
    if (input.isEmpty) {
      setState(() {
        _outputController.text = '';
        _errorKey = null;
      });
      return;
    }
    try {
      HapticFeedback.mediumImpact();
      final String result = _isBase64 ? _b64Encode(input) : Uri.encodeComponent(input);
      setState(() {
        _outputController.text = result;
        _errorKey = null;
      });
      _pushHistory(input, result, true);
    } catch (_) {
      HapticFeedback.heavyImpact();
      setState(() {
        _outputController.text = '';
        _errorKey = 'b64url_error';
      });
    }
  }

  void _decode() {
    final String input = _inputController.text;
    if (input.isEmpty) {
      setState(() {
        _outputController.text = '';
        _errorKey = null;
      });
      return;
    }
    try {
      HapticFeedback.mediumImpact();
      final String result = _isBase64 ? _b64Decode(input) : Uri.decodeComponent(input);
      setState(() {
        _outputController.text = result;
        _errorKey = null;
      });
      _pushHistory(input, result, false);
    } catch (_) {
      HapticFeedback.heavyImpact();
      setState(() {
        _outputController.text = '';
        _errorKey = 'b64url_error';
      });
    }
  }

  void _clear() {
    HapticFeedback.lightImpact();
    setState(() {
      _inputController.clear();
      _outputController.clear();
      _errorKey = null;
    });
  }

  void _swap() {
    if (_outputController.text.isEmpty) return;
    HapticFeedback.selectionClick();
    final String temp = _inputController.text;
    setState(() {
      _inputController.text = _outputController.text;
      _outputController.text = temp;
      _errorKey = null;
    });
  }

  Future<void> _paste() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null) return;
    HapticFeedback.selectionClick();
    _inputController.text = data.text!;
  }

  Future<void> _copy() async {
    if (_outputController.text.isEmpty) return;
    HapticFeedback.mediumImpact();
    await Clipboard.setData(ClipboardData(text: _outputController.text));
    if (!mounted) return;
    _showToast(context.t('b64url_copied'));
  }

  void _applyHistory(_HistoryItem h) {
    HapticFeedback.selectionClick();
    setState(() {
      _inputController.text = h.input;
      _outputController.text = h.output;
      _errorKey = null;
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
    Future<void>.delayed(const Duration(milliseconds: 1400), entry.remove);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.t('b64url_title'),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 68, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _GlassSegmentedTabs(
                      controller: _tabController,
                      labels: <String>[
                        context.t('b64url_tab_base64'),
                        context.t('b64url_tab_url'),
                      ],
                      onChanged: (int i) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _tabController.animateTo(i);
                          _errorKey = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // ---- OPTIONS ----
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          if (_isBase64)
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    context.t('b64url_urlsafe'),
                                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                _MiniToggle(
                                  value: _urlSafe,
                                  onChanged: (bool v) {
                                    HapticFeedback.selectionClick();
                                    setState(() => _urlSafe = v);
                                  },
                                ),
                              ],
                            ),
                          if (_isBase64) const SizedBox(height: 8),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  context.t('b64url_live'),
                                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                                ),
                              ),
                              _MiniToggle(
                                value: _liveMode,
                                onChanged: (bool v) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _liveMode = v);
                                  if (v) _encode();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ---- INPUT ----
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  context.t('b64url_input_hint'),
                                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                                ),
                              ),
                              Text(
                                '${_inputController.text.length}',
                                style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11),
                              ),
                              const SizedBox(width: 8),
                              _GlassIconButton(icon: CupertinoIcons.doc_on_clipboard, onTap: _paste),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _GlassTextField(
                            controller: _inputController,
                            maxLines: 6,
                            minLines: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _GlassActionButton(
                            label: context.t('b64url_encode'),
                            icon: CupertinoIcons.arrow_down_doc,
                            onTap: _encode,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _GlassActionButton(
                            label: context.t('b64url_decode'),
                            icon: CupertinoIcons.arrow_up_doc,
                            onTap: _decode,
                            tint: const Color(0xFF00E5FF),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _GlassIconButton(
                          icon: CupertinoIcons.arrow_2_squarepath,
                          onTap: _outputController.text.isEmpty ? null : _swap,
                        ),
                      ],
                    ),

                    if (_errorKey != null) ...<Widget>[
                      const SizedBox(height: 12),
                      _ErrorBanner(message: context.t(_errorKey!)),
                    ],

                    const SizedBox(height: 16),

                    // ---- OUTPUT ----
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  context.t('b64url_output_hint'),
                                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                                ),
                              ),
                              Text(
                                '${_outputController.text.length}',
                                style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11),
                              ),
                              const SizedBox(width: 8),
                              _GlassIconButton(icon: CupertinoIcons.doc_on_doc, onTap: _copy),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _GlassTextField(
                            controller: _outputController,
                            readOnly: true,
                            maxLines: 6,
                            minLines: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _GlassActionButton(
                      label: context.t('b64url_clear'),
                      icon: CupertinoIcons.trash,
                      onTap: _clear,
                      tint: const Color(0xFFFF5C7A),
                    ),

                    if (_history.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 16),
                      _HistoryCard(history: _history, onTap: _applyHistory),
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
  _HistoryItem({
    required this.input,
    required this.output,
    required this.encoded,
    required this.mode,
    required this.at,
  });
  final String input;
  final String output;
  final bool encoded;
  final String mode;
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
  });

  final TextEditingController controller;
  final bool readOnly;
  final int maxLines;
  final int? minLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      minLines: minLines,
      style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
      decoration: InputDecoration(
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

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
      child: Row(
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
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.history, required this.onTap});
  final List<_HistoryItem> history;
  final ValueChanged<_HistoryItem> onTap;

  String _formatTime(DateTime dt) {
    final String hh = dt.hour.toString().padLeft(2, '0');
    final String mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _truncate(String s) => s.length > 28 ? '${s.substring(0, 28)}…' : s;

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
                context.t('b64url_history'),
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...history.map(
                (_HistoryItem h) => InkWell(
              onTap: () => onTap(h),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: <Widget>[
                    Icon(
                      h.encoded ? CupertinoIcons.arrow_down_doc : CupertinoIcons.arrow_up_doc,
                      size: 14,
                      color: h.encoded ? const Color(0xFF7C4DFF) : const Color(0xFF00E5FF),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _truncate(h.input),
                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      h.mode,
                      style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 10),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(h.at),
                      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                    ),
                  ],
                ),
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