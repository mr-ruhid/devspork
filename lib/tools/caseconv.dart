import 'dart:async';
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

class CaseConv extends StatefulWidget {
  const CaseConv({super.key});

  @override
  State<CaseConv> createState() => _CaseConvState();
}

class _CaseConvState extends State<CaseConv> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  String _mode = 'upper';
  Timer? _debounce;
  bool _justCopied = false;

  static const List<String> _modes = <String>[
    'upper',
    'lower',
    'title',
    'sentence',
    'camel',
    'pascal',
    'snake',
    'kebab',
    'constant',
  ];

  static const Map<String, IconData> _modeIcons = <String, IconData>{
    'upper': Icons.text_fields_rounded,
    'lower': Icons.text_fields_rounded,
    'title': Icons.title_rounded,
    'sentence': Icons.short_text_rounded,
    'camel': Icons.text_format_rounded,
    'pascal': Icons.text_format_rounded,
    'snake': Icons.horizontal_rule_rounded,
    'kebab': Icons.remove_rounded,
    'constant': Icons.format_bold_rounded,
  };

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _inputController.removeListener(_onInputChanged);
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), _convert);
  }

  List<String> _splitWords(String text) {
    final String normalized = text
        .replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'),
          (Match m) => '${m[1]} ${m[2]}',
    )
        .replaceAll(RegExp(r'[_\-\s]+'), ' ')
        .trim();
    if (normalized.isEmpty) return <String>[];
    return normalized.split(RegExp(r'\s+'));
  }

  String _applyMode(String text, String mode) {
    if (text.isEmpty) return '';
    switch (mode) {
      case 'upper':
        return text.toUpperCase();
      case 'lower':
        return text.toLowerCase();
      case 'title':
        return _splitWords(text)
            .map((String w) => w.isEmpty
            ? w
            : w[0].toUpperCase() + w.substring(1).toLowerCase())
            .join(' ');
      case 'sentence':
        final String lower = text.toLowerCase();
        return lower.isEmpty
            ? lower
            : lower[0].toUpperCase() + lower.substring(1);
      case 'camel':
        final List<String> words =
        _splitWords(text).map((String w) => w.toLowerCase()).toList();
        if (words.isEmpty) return '';
        return words.first +
            words
                .skip(1)
                .map((String w) =>
            w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
                .join();
      case 'pascal':
        return _splitWords(text)
            .map((String w) => w.isEmpty
            ? w
            : w[0].toUpperCase() + w.substring(1).toLowerCase())
            .join();
      case 'snake':
        return _splitWords(text).map((String w) => w.toLowerCase()).join('_');
      case 'kebab':
        return _splitWords(text).map((String w) => w.toLowerCase()).join('-');
      case 'constant':
        return _splitWords(text).map((String w) => w.toUpperCase()).join('_');
      default:
        return text;
    }
  }

  void _convert() {
    setState(() {
      _outputController.text = _applyMode(_inputController.text, _mode);
    });
  }

  void _selectMode(String mode) {
    HapticFeedback.selectionClick();
    setState(() {
      _mode = mode;
      _outputController.text = _applyMode(_inputController.text, _mode);
    });
  }

  void _clear() {
    HapticFeedback.selectionClick();
    setState(() {
      _inputController.clear();
      _outputController.clear();
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

  int get _charCount => _inputController.text.length;
  int get _wordCount => _splitWords(_inputController.text).length;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor:
      isDark ? const Color(0xFF0B0B12) : const Color(0xFFEFF1F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.t('caseconv_title'),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        children: <Widget>[
          _AmbientBackground(isDark: isDark),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top > 0 ? 12 : 96,
                16,
                16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    flex: 5,
                    child: _GlassCard(
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  context.t('caseconv_input_hint'),
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
                                tooltip: _tr(context, 'caseconv_paste', 'Paste'),
                              ),
                              const SizedBox(width: 8),
                              _GlassIconButton(
                                icon: Icons.close_rounded,
                                isDark: isDark,
                                onTap: _clear,
                                tooltip: _tr(context, 'caseconv_clear', 'Clear'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: _GlassTextField(
                              controller: _inputController,
                              isDark: isDark,
                              expands: true,
                              hintText: _tr(context, 'caseconv_input_hint',
                                  'Type or paste text…'),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '$_charCount ${_tr(context, 'caseconv_chars', 'chars')} · '
                                  '$_wordCount ${_tr(context, 'caseconv_words', 'words')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: (isDark ? Colors.white70 : Colors.black54)
                                    .withOpacity(0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _GlassCard(
                    isDark: isDark,
                    radius: 22,
                    padding: const EdgeInsets.all(10),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _modes.map((String m) {
                        return _GlassChoiceChip(
                          label: context.t('caseconv_mode_$m'),
                          icon: _modeIcons[m] ?? Icons.text_fields_rounded,
                          selected: _mode == m,
                          isDark: isDark,
                          onTap: () => _selectMode(m),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _GlassPrimaryButton(
                    isDark: isDark,
                    label: context.t('caseconv_convert'),
                    icon: Icons.autorenew_rounded,
                    onTap: _convert,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    flex: 5,
                    child: _GlassCard(
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  context.t('caseconv_output_hint'),
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
                                    ? context.t('caseconv_copied')
                                    : _tr(context, 'caseconv_copy', 'Copy'),
                                highlighted: _justCopied,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: _GlassTextField(
                              controller: _outputController,
                              isDark: isDark,
                              readOnly: true,
                              expands: true,
                              hintText: _tr(context, 'caseconv_output_hint',
                                  'Result appears here'),
                            ),
                          ),
                        ],
                      ),
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
            Positioned(top: -80, left: -60, child: _blurOrb(220, orbColors[0])),
            Positioned(
                top: 120, right: -90, child: _blurOrb(260, orbColors[1])),
            Positioned(
                bottom: -100, left: 40, child: _blurOrb(240, orbColors[2])),
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
/// building block reused for cards, buttons and chips.
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
    this.readOnly = false,
    this.expands = false,
    this.hintText,
  });

  final TextEditingController controller;
  final bool isDark;
  final bool readOnly;
  final bool expands;
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
            readOnly: readOnly,
            expands: expands,
            maxLines: expands ? null : 1,
            minLines: expands ? null : 1,
            textAlignVertical:
            expands ? TextAlignVertical.top : TextAlignVertical.center,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                fontSize: 14,
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
    this.highlighted = false,
  });

  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  final String? tooltip;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final Widget button = ClipRRect(
      borderRadius: BorderRadius.circular(12),
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
              width: 36,
              height: 36,
              child: Icon(
                icon,
                size: 18,
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

class _GlassChoiceChip extends StatelessWidget {
  const _GlassChoiceChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: selected
              ? colors.primary.withOpacity(0.85)
              : (isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.white.withOpacity(0.55)),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? Colors.white.withOpacity(0.4)
                      : Colors.white.withOpacity(isDark ? 0.10 : 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    icon,
                    size: 15,
                    color: selected
                        ? colors.onPrimary
                        : (isDark ? Colors.white70 : Colors.black54),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? colors.onPrimary
                          : (isDark ? Colors.white70 : Colors.black87),
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