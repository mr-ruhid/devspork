import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

/// Safe localization lookup: falls back to [fallback] if the key is
/// missing or the localization layer throws, so new UI strings never
/// crash the screen while translations are being added.
String _tr(BuildContext context, String key, String fallback) {
  try {
    final String value = context.t(key);
    if (value.isEmpty || value == key) return fallback;
    return value;
  } catch (_) {
    return fallback;
  }
}

class BinView extends StatefulWidget {
  const BinView({super.key});

  @override
  State<BinView> createState() => _BinViewState();
}

class _BinViewState extends State<BinView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  Timer? _debounce;
  String? _errorKey;
  String? _errorFallback;
  bool _useSpaces = true;
  bool _isSwapping = false;
  bool _justCopied = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (_isSwapping) return;
      setState(() {
        _inputController.clear();
        _outputController.clear();
        _errorKey = null;
        _errorFallback = null;
      });
    });
    _inputController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _inputController.removeListener(_onInputChanged);
    _tabController.dispose();
    _inputController.dispose();
    _outputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  bool get _isTextToBin => _tabController.index == 0;

  void _onInputChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _convert);
  }

  String _textToBinary(String input) {
    final List<int> bytes = utf8.encode(input);
    final List<String> parts =
    bytes.map((int b) => b.toRadixString(2).padLeft(8, '0')).toList();
    return _useSpaces ? parts.join(' ') : parts.join();
  }

  String _binaryToText(String input) {
    final String cleaned = input.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.isEmpty) return '';
    if (!RegExp(r'^[01]+$').hasMatch(cleaned)) {
      throw const FormatException('invalid');
    }
    if (cleaned.length % 8 != 0) {
      throw const FormatException('length');
    }
    final List<int> bytes = <int>[
      for (int i = 0; i < cleaned.length; i += 8)
        int.parse(cleaned.substring(i, i + 8), radix: 2),
    ];
    return utf8.decode(bytes, allowMalformed: true);
  }

  void _convert() {
    final String input = _inputController.text;
    if (input.isEmpty) {
      setState(() {
        _outputController.text = '';
        _errorKey = null;
        _errorFallback = null;
      });
      return;
    }
    try {
      final String result =
      _isTextToBin ? _textToBinary(input) : _binaryToText(input);
      setState(() {
        _outputController.text = result;
        _errorKey = null;
        _errorFallback = null;
      });
    } on FormatException catch (e) {
      setState(() {
        _outputController.text = '';
        if (e.message == 'length') {
          _errorKey = 'binview_error_length';
          _errorFallback = 'Binary length must be a multiple of 8 bits.';
        } else {
          _errorKey = 'binview_error_invalid';
          _errorFallback = 'Input contains characters other than 0 and 1.';
        }
      });
    }
  }

  void _clear() {
    HapticFeedback.selectionClick();
    setState(() {
      _inputController.clear();
      _outputController.clear();
      _errorKey = null;
      _errorFallback = null;
    });
  }

  Future<void> _paste() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null || data.text!.isEmpty) return;
    HapticFeedback.selectionClick();
    _inputController.text = data.text!;
    _convert();
  }

  Future<void> _copy() async {
    if (_outputController.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _outputController.text));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _justCopied = true);
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _justCopied = false);
    });
  }

  /// Swaps direction and moves the current output into the input, instead
  /// of forcing the user to retype/re-paste what they just produced.
  void _swap() {
    if (_outputController.text.isEmpty) return;
    HapticFeedback.mediumImpact();
    final String newInput = _outputController.text;
    _isSwapping = true;
    _inputController.text = newInput;
    _outputController.text = '';
    _errorKey = null;
    _errorFallback = null;
    _tabController.animateTo(_isTextToBin ? 1 : 0);
    _isSwapping = false;
    _convert();
  }

  int get _byteCount {
    if (_isTextToBin) return utf8.encode(_inputController.text).length;
    final String cleaned =
    _inputController.text.replaceAll(RegExp(r'\s+'), '');
    return cleaned.length ~/ 8;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDark ? const Color(0xFF0B0B12) : const Color(0xFFEFF1F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.t('binview_title'),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        children: <Widget>[
          _AmbientBackground(isDark: isDark),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top > 0 ? 12 : 96,
                16,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _GlassSegmentedControl(
                    isDark: isDark,
                    selectedIndex: _tabController.index,
                    labels: <String>[
                      context.t('binview_tab_t2b'),
                      context.t('binview_tab_b2t'),
                    ],
                    onChanged: (int index) {
                      HapticFeedback.selectionClick();
                      _tabController.animateTo(index);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  _GlassCard(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                _isTextToBin
                                    ? context.t('binview_input_text')
                                    : context.t('binview_input_binary'),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            _GlassIconButton(
                              icon: Icons.content_paste_rounded,
                              isDark: isDark,
                              onTap: _paste,
                              tooltip: _tr(context, 'binview_paste', 'Paste'),
                            ),
                            const SizedBox(width: 8),
                            _GlassIconButton(
                              icon: Icons.close_rounded,
                              isDark: isDark,
                              onTap: _clear,
                              tooltip: _tr(context, 'binview_clear', 'Clear'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _GlassTextField(
                          controller: _inputController,
                          focusNode: _inputFocus,
                          isDark: isDark,
                          minLines: 4,
                          maxLines: 6,
                          hintText: _isTextToBin
                              ? _tr(context, 'binview_input_text_hint',
                              'Type or paste text…')
                              : _tr(context, 'binview_input_binary_hint',
                              '01001000 01101001 …'),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            _isTextToBin
                                ? '$_byteCount ${_tr(context, 'binview_bytes', 'bytes')}'
                                : '$_byteCount ${_tr(context, 'binview_bytes_est', 'bytes (est.)')}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant.withOpacity(0.7),
                            ),
                          ),
                        ),
                        if (_isTextToBin) ...<Widget>[
                          const SizedBox(height: 4),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  context.t('binview_spaces'),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              Switch.adaptive(
                                value: _useSpaces,
                                onChanged: (bool v) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _useSpaces = v);
                                  if (_inputController.text.isNotEmpty) {
                                    _convert();
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _GlassPrimaryButton(
                          isDark: isDark,
                          label: context.t('binview_convert'),
                          icon: Icons.autorenew_rounded,
                          onTap: _convert,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _GlassIconButton(
                        icon: Icons.swap_vert_rounded,
                        isDark: isDark,
                        large: true,
                        onTap: _swap,
                        tooltip: _tr(context, 'binview_swap', 'Swap'),
                      ),
                    ],
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: _errorKey == null
                        ? const SizedBox(width: double.infinity)
                        : Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _ErrorBanner(
                        text: context.t(_errorKey!).isNotEmpty
                            ? context.t(_errorKey!)
                            : (_errorFallback ?? ''),
                        color: colors.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _GlassCard(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                _isTextToBin
                                    ? context.t('binview_output_binary')
                                    : context.t('binview_output_text'),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            _GlassIconButton(
                              icon: _justCopied
                                  ? Icons.check_rounded
                                  : Icons.copy_rounded,
                              isDark: isDark,
                              onTap: _copy,
                              tooltip: _justCopied
                                  ? context.t('binview_copied')
                                  : _tr(context, 'binview_copy', 'Copy'),
                              highlighted: _justCopied,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _GlassTextField(
                          controller: _outputController,
                          isDark: isDark,
                          readOnly: true,
                          minLines: 6,
                          maxLines: null,
                          hintText: _tr(
                              context, 'binview_output_hint', 'Result appears here'),
                        ),
                      ],
                    ),
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

/// Soft blurred colour orbs drifting behind the glass panels — the
/// depth cue that sells the "liquid glass" look.
class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final List<Color> orbColors = isDark
        ? <Color>[
      const Color(0xFF5B8CFF).withOpacity(0.35),
      const Color(0xFFB16CFF).withOpacity(0.30),
      const Color(0xFF37E0C4).withOpacity(0.20),
    ]
        : <Color>[
      const Color(0xFF9FC2FF).withOpacity(0.55),
      const Color(0xFFE3B8FF).withOpacity(0.45),
      const Color(0xFFAFF3E4).withOpacity(0.45),
    ];

    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? <Color>[const Color(0xFF0B0B12), const Color(0xFF14121F)]
                : <Color>[const Color(0xFFF3F5FB), const Color(0xFFE7EAF6)],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: -80,
              left: -60,
              child: _blurOrb(220, orbColors[0]),
            ),
            Positioned(
              top: 120,
              right: -90,
              child: _blurOrb(260, orbColors[1]),
            ),
            Positioned(
              bottom: -100,
              left: 40,
              child: _blurOrb(240, orbColors[2]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blurOrb(double size, Color color) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

/// A frosted, translucent panel with a subtle top highlight — the base
/// building block reused for cards, buttons and the segmented control.
class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    required this.isDark,
    this.padding = const EdgeInsets.all(16),
    this.radius = 26,
  });

  final Widget child;
  final bool isDark;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? <Color>[
                Colors.white.withOpacity(0.10),
                Colors.white.withOpacity(0.04),
              ]
                  : <Color>[
                Colors.white.withOpacity(0.65),
                Colors.white.withOpacity(0.35),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.14 : 0.55),
              width: 1,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  const _GlassTextField({
    required this.controller,
    required this.isDark,
    this.focusNode,
    this.readOnly = false,
    this.minLines,
    this.maxLines,
    this.hintText,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool isDark;
  final bool readOnly;
  final int? minLines;
  final int? maxLines;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: isDark
                ? Colors.black.withOpacity(0.18)
                : Colors.white.withOpacity(0.45),
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.10 : 0.5),
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            readOnly: readOnly,
            minLines: minLines,
            maxLines: maxLines,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.35),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.isDark,
    required this.onTap,
    this.tooltip,
    this.large = false,
    this.highlighted = false,
  });

  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  final String? tooltip;
  final bool large;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final double size = large ? 52 : 36;
    final Widget button = ClipRRect(
      borderRadius: BorderRadius.circular(large ? 18 : 12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: highlighted
              ? Colors.greenAccent.withOpacity(0.25)
              : (isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.white.withOpacity(0.5)),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                icon,
                size: large ? 24 : 18,
                color: highlighted
                    ? Colors.green
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

class _GlassPrimaryButton extends StatefulWidget {
  const _GlassPrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  @override
  State<_GlassPrimaryButton> createState() => _GlassPrimaryButtonState();
}

class _GlassPrimaryButtonState extends State<_GlassPrimaryButton> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapCancel: () => setState(() => _scale = 1),
      onTapUp: (_) {
        setState(() => _scale = 1);
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: <Color>[
                    colors.primary.withOpacity(0.85),
                    colors.primary.withOpacity(0.65),
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.35)),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: colors.primary.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(widget.icon, color: colors.onPrimary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w600,
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

class _GlassSegmentedControl extends StatelessWidget {
  const _GlassSegmentedControl({
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    required this.isDark,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      isDark: isDark,
      radius: 20,
      padding: const EdgeInsets.all(5),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double segmentWidth = constraints.maxWidth / labels.length;
          return SizedBox(
            height: 42,
            child: Stack(
              children: <Widget>[
                AnimatedAlign(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment(
                    labels.length == 1
                        ? 0
                        : -1 + (2 * selectedIndex) / (labels.length - 1),
                    0,
                  ),
                  child: Container(
                    width: segmentWidth,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: (isDark ? Colors.white : Colors.white)
                          .withOpacity(isDark ? 0.20 : 0.9),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: List<Widget>.generate(labels.length, (int i) {
                    final bool selected = i == selectedIndex;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onChanged(i),
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: Text(
                            labels[i],
                            style: TextStyle(
                              fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected
                                  ? (isDark ? Colors.white : Colors.black87)
                                  : (isDark ? Colors.white60 : Colors.black54),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.error_outline_rounded, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}