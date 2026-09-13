import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class _MaskCategory {
  const _MaskCategory({
    required this.id,
    required this.labelKey,
    required this.pattern,
  });

  final String id;
  final String labelKey;
  final RegExp pattern;
}

class _MatchSpan {
  _MatchSpan(this.start, this.end);
  int start;
  int end;
}

class TextMasker extends StatefulWidget {
  const TextMasker({super.key});

  @override
  State<TextMasker> createState() => _TextMaskerState();
}

class _TextMaskerState extends State<TextMasker> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _customRegexController = TextEditingController();

  static const Color _accentA = Color(0xFF7C4DFF);
  static const Color _accentB = Color(0xFF00E5FF);

  static const List<String> _maskChars = <String>['•', '*', '#', 'X', '█'];

  static final List<_MaskCategory> _categories = <_MaskCategory>[
    _MaskCategory(
      id: 'email',
      labelKey: 'textmasker_cat_email',
      pattern: RegExp(r'[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}'),
    ),
    _MaskCategory(
      id: 'card',
      labelKey: 'textmasker_cat_card',
      pattern: RegExp(r'\b(?:\d[ -]?){13,16}\b'),
    ),
    _MaskCategory(
      id: 'phone',
      labelKey: 'textmasker_cat_phone',
      pattern: RegExp(r'(?<!\d)(\+?\d{1,3}[\s.\-]?)?(\(?\d{2,4}\)?[\s.\-]?){2,4}\d{2,4}(?!\d)'),
    ),
    _MaskCategory(
      id: 'ip',
      labelKey: 'textmasker_cat_ip',
      pattern: RegExp(r'\b(?:\d{1,3}\.){3}\d{1,3}\b'),
    ),
    _MaskCategory(
      id: 'uuid',
      labelKey: 'textmasker_cat_uuid',
      pattern: RegExp(
        r'\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b',
      ),
    ),
    _MaskCategory(
      id: 'token',
      labelKey: 'textmasker_cat_token',
      pattern: RegExp(r'\b[A-Za-z0-9_\-]{24,}\b'),
    ),
  ];

  final Set<String> _enabled = <String>{'email', 'card', 'phone', 'ip', 'uuid', 'token'};

  String _maskChar = '•';
  bool _partial = false;
  bool _customEnabled = false;
  String? _regexError;

  String _output = '';
  int _matchCount = 0;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _inputController.text =
    'Ad: Ali Veliyev\nEmail: ali.veliyev@example.com\nTelefon: +994 50 123 45 67\n'
        'Kart: 4111 1111 1111 1111\nServer IP: 192.168.1.24\n'
        'Sessiya: 9f8c9a2e-1b3d-4e4a-9c3f-6a1b2c3d4e5f\n'
        'API açarı: api_key_9d8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b';
    _generate();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _inputController.dispose();
    _customRegexController.dispose();
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _generate);
  }

  void _generate() {
    final String input = _inputController.text;
    if (input.isEmpty) {
      setState(() {
        _output = '';
        _matchCount = 0;
        _regexError = null;
      });
      return;
    }

    final List<_MatchSpan> spans = <_MatchSpan>[];
    for (final _MaskCategory category in _categories) {
      if (!_enabled.contains(category.id)) continue;
      for (final RegExpMatch m in category.pattern.allMatches(input)) {
        spans.add(_MatchSpan(m.start, m.end));
      }
    }

    String? regexError;
    if (_customEnabled && _customRegexController.text.trim().isNotEmpty) {
      try {
        final RegExp custom = RegExp(_customRegexController.text.trim());
        for (final RegExpMatch m in custom.allMatches(input)) {
          spans.add(_MatchSpan(m.start, m.end));
        }
      } catch (e) {
        regexError = e.toString();
      }
    }

    spans.sort((_MatchSpan a, _MatchSpan b) => a.start.compareTo(b.start));
    final List<_MatchSpan> merged = <_MatchSpan>[];
    for (final _MatchSpan s in spans) {
      if (merged.isNotEmpty && s.start <= merged.last.end) {
        merged.last.end = merged.last.end > s.end ? merged.last.end : s.end;
      } else {
        merged.add(s);
      }
    }

    final StringBuffer buffer = StringBuffer();
    int last = 0;
    for (final _MatchSpan span in merged) {
      buffer.write(input.substring(last, span.start));
      buffer.write(_maskMatch(input.substring(span.start, span.end)));
      last = span.end;
    }
    buffer.write(input.substring(last));

    setState(() {
      _output = buffer.toString();
      _matchCount = merged.length;
      _regexError = regexError;
    });
  }

  String _maskMatch(String s) {
    if (!_partial || s.length <= 4) {
      return _maskChar * s.length;
    }
    const int visible = 2;
    final String start = s.substring(0, visible);
    final String end = s.substring(s.length - visible);
    final String middle = _maskChar * (s.length - visible * 2);
    return '$start$middle$end';
  }

  void _clear() {
    _inputController.clear();
    setState(() {
      _output = '';
      _matchCount = 0;
    });
  }

  Future<void> _paste() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null) return;
    _inputController.text = data.text!;
    _generate();
  }

  Future<void> _copy() async {
    if (_output.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _output));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withOpacity(0.75),
        content: Text(context.t('textmasker_copied')),
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
        title: Text(context.t('textmasker_title')),
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
            Positioned(top: -80, left: -60, child: _blurBlob(220, _accentA)),
            Positioned(bottom: -100, right: -60, child: _blurBlob(260, _accentB)),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 24),
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
                                  context.t('textmasker_input'),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              _GlassIconButton(icon: Icons.paste, onTap: _paste),
                              const SizedBox(width: 8),
                              _GlassIconButton(icon: Icons.clear, onTap: _clear),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _inputController,
                            onChanged: (_) => _onChanged(),
                            maxLines: 10,
                            minLines: 6,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.black.withOpacity(0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: _accentA,
                                  width: 1.5,
                                ),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            context.t('textmasker_categories'),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _categories.map((_MaskCategory c) {
                              final bool selected = _enabled.contains(c.id);
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (selected) {
                                      _enabled.remove(c.id);
                                    } else {
                                      _enabled.add(c.id);
                                    }
                                  });
                                  _generate();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? _accentA.withOpacity(0.85)
                                        : Colors.white.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: selected
                                          ? _accentA
                                          : Colors.white.withOpacity(0.15),
                                    ),
                                  ),
                                  child: Text(
                                    context.t(c.labelKey),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: <Widget>[
                              Checkbox(
                                value: _customEnabled,
                                activeColor: _accentA,
                                onChanged: (bool? v) {
                                  setState(() => _customEnabled = v ?? false);
                                  _generate();
                                },
                              ),
                              Expanded(
                                child: Text(
                                  context.t('textmasker_custom_regex'),
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                          if (_customEnabled) ...<Widget>[
                            const SizedBox(height: 4),
                            TextField(
                              controller: _customRegexController,
                              onChanged: (_) => _onChanged(),
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: Colors.white,
                              ),
                              decoration: InputDecoration(
                                hintText: context.t('textmasker_custom_regex_hint'),
                                hintStyle: const TextStyle(color: Colors.white30),
                                filled: true,
                                fillColor: Colors.black.withOpacity(0.3),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.12),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.12),
                                  ),
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.all(10),
                              ),
                            ),
                            if (_regexError != null) ...<Widget>[
                              const SizedBox(height: 6),
                              Text(
                                '${context.t('textmasker_regex_error')}: $_regexError',
                                style: const TextStyle(
                                  color: Color(0xFFFF8A8A),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            context.t('textmasker_style'),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _StyleOption(
                                  label: context.t('textmasker_style_full'),
                                  selected: !_partial,
                                  onTap: () {
                                    setState(() => _partial = false);
                                    _generate();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _StyleOption(
                                  label: context.t('textmasker_style_partial'),
                                  selected: _partial,
                                  onTap: () {
                                    setState(() => _partial = true);
                                    _generate();
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            context.t('textmasker_mask_char'),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _maskChars.map((String c) {
                              final bool selected = _maskChar == c;
                              return GestureDetector(
                                onTap: () {
                                  setState(() => _maskChar = c);
                                  _generate();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? _accentB.withOpacity(0.3)
                                        : Colors.white.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: selected
                                          ? _accentB
                                          : Colors.white.withOpacity(0.15),
                                    ),
                                  ),
                                  child: Text(
                                    c,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
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
                                child: Row(
                                  children: <Widget>[
                                    Text(
                                      context.t('textmasker_output'),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (_matchCount > 0) ...<Widget>[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _accentB.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: _accentB.withOpacity(0.5),
                                          ),
                                        ),
                                        child: Text(
                                          '$_matchCount ${context.t('textmasker_matches')}',
                                          style: const TextStyle(
                                            color: _accentB,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              _GlassIconButton(icon: Icons.copy, onTap: _copy),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(minHeight: 140),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: _output.isEmpty
                                ? Text(
                              context.t('textmasker_output_empty'),
                              style: const TextStyle(color: Colors.white38),
                            )
                                : SelectableText(
                              _output,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                height: 1.5,
                                color: Colors.white,
                              ),
                            ),
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.35),
            ),
          ),
        ),
      ),
    );
  }
}

class _StyleOption extends StatelessWidget {
  const _StyleOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
            colors: <Color>[
              _TextMaskerState._accentA,
              _TextMaskerState._accentB,
            ],
          )
              : null,
          color: selected ? null : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.transparent : Colors.white.withOpacity(0.15),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
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
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 20,
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

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
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
    );
  }
}