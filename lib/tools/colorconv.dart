import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';


String _tr(BuildContext context, String key, String fallback) {
  try {
    final String value = context.t(key);
    if (value.isEmpty || value == key) return fallback;
    return value;
  } catch (_) {
    return fallback;
  }
}

class ColorConv extends StatefulWidget {
  const ColorConv({super.key});

  @override
  State<ColorConv> createState() => _ColorConvState();
}

class _ColorConvState extends State<ColorConv> {
  final TextEditingController _hexController = TextEditingController();
  final TextEditingController _rController = TextEditingController();
  final TextEditingController _gController = TextEditingController();
  final TextEditingController _bController = TextEditingController();
  final TextEditingController _hController = TextEditingController();
  final TextEditingController _sController = TextEditingController();
  final TextEditingController _lController = TextEditingController();

  static const List<Color> _presets = <Color>[
    Color(0xFFF44336),
    Color(0xFFFF9800),
    Color(0xFFFFC107),
    Color(0xFF4CAF50),
    Color(0xFF009688),
    Color(0xFF2196F3),
    Color(0xFF3F51B5),
    Color(0xFF9C27B0),
    Color(0xFFE91E63),
    Color(0xFF795548),
    Color(0xFF607D8B),
    Color(0xFF000000),
    Color(0xFFFFFFFF),
  ];

  int _activeField = 0;
  String? _errorKey;
  Color _color = Colors.black;
  String? _justCopiedField;

  @override
  void initState() {
    super.initState();
    _hexController.addListener(() => _onHex(_hexController.text));
    _rController.addListener(() => _onRgb());
    _gController.addListener(() => _onRgb());
    _bController.addListener(() => _onRgb());
    _hController.addListener(() => _onHsl());
    _sController.addListener(() => _onHsl());
    _lController.addListener(() => _onHsl());
    _setAll(const Color(0xFF6750A4));
  }

  @override
  void dispose() {
    _hexController.dispose();
    _rController.dispose();
    _gController.dispose();
    _bController.dispose();
    _hController.dispose();
    _sController.dispose();
    _lController.dispose();
    super.dispose();
  }

  String _hexFromColor(Color c) {
    final int r = (c.r * 255).round();
    final int g = (c.g * 255).round();
    final int b = (c.b * 255).round();
    return '#'
        '${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  List<double> _rgbToHsl(int r, int g, int b) {
    final double rf = r / 255;
    final double gf = g / 255;
    final double bf = b / 255;
    final double max = <double>[rf, gf, bf].reduce((double a, double c) => a > c ? a : c);
    final double min = <double>[rf, gf, bf].reduce((double a, double c) => a < c ? a : c);
    final double d = max - min;
    double h = 0;
    double s = 0;
    final double l = (max + min) / 2;
    if (d != 0) {
      s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
      if (max == rf) {
        h = ((gf - bf) / d) + (gf < bf ? 6 : 0);
      } else if (max == gf) {
        h = ((bf - rf) / d) + 2;
      } else {
        h = ((rf - gf) / d) + 4;
      }
      h /= 6;
    }
    return <double>[h * 360, s * 100, l * 100];
  }

  Color _hslToColor(double h, double s, double l) {
    final double hh = h / 360;
    final double ss = s / 100;
    final double ll = l / 100;
    if (ss == 0) {
      final int v = (ll * 255).round();
      return Color.fromARGB(255, v, v, v);
    }
    final double q = ll < 0.5 ? ll * (1 + ss) : ll + ss - ll * ss;
    final double p = 2 * ll - q;
    double hue(double t) {
      double tt = t;
      if (tt < 0) tt += 1;
      if (tt > 1) tt -= 1;
      if (tt < 1 / 6) return p + (q - p) * 6 * tt;
      if (tt < 1 / 2) return q;
      if (tt < 2 / 3) return p + (q - p) * (2 / 3 - tt) * 6;
      return p;
    }

    final int r = (hue(hh + 1 / 3) * 255).round();
    final int g = (hue(hh) * 255).round();
    final int b = (hue(hh - 1 / 3) * 255).round();
    return Color.fromARGB(255, r, g, b);
  }

  void _setAll(Color c) {
    _activeField = 0;
    final int r = (c.r * 255).round();
    final int g = (c.g * 255).round();
    final int b = (c.b * 255).round();
    _hexController.text = _hexFromColor(c);
    _rController.text = r.toString();
    _gController.text = g.toString();
    _bController.text = b.toString();
    final List<double> hsl = _rgbToHsl(r, g, b);
    _hController.text = hsl[0].round().toString();
    _sController.text = hsl[1].round().toString();
    _lController.text = hsl[2].round().toString();
    _color = c;
    _errorKey = null;
  }


  String _expandShortHex(String v) {
    if (v.length != 3) return v;
    return v.split('').map((String c) => '$c$c').join();
  }

  void _onHex(String value) {
    if (_activeField != 1) return;
    String v = value.trim().replaceAll('#', '');
    if (v.isEmpty) {
      setState(() => _errorKey = null);
      return;
    }
    if (v.length == 3 && RegExp(r'^[0-9a-fA-F]{3}$').hasMatch(v)) {
      v = _expandShortHex(v);
    }
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(v)) {
      setState(() => _errorKey = 'colorconv_error_hex');
      return;
    }
    final int r = int.parse(v.substring(0, 2), radix: 16);
    final int g = int.parse(v.substring(2, 4), radix: 16);
    final int b = int.parse(v.substring(4, 6), radix: 16);
    setState(() {
      _errorKey = null;
      _activeField = 0;
      _rController.text = r.toString();
      _gController.text = g.toString();
      _bController.text = b.toString();
      final List<double> hsl = _rgbToHsl(r, g, b);
      _hController.text = hsl[0].round().toString();
      _sController.text = hsl[1].round().toString();
      _lController.text = hsl[2].round().toString();
      _color = Color.fromARGB(255, r, g, b);
      _activeField = 1;
    });
  }

  void _onRgb() {
    if (_activeField != 2) return;
    final int? r = int.tryParse(_rController.text.trim());
    final int? g = int.tryParse(_gController.text.trim());
    final int? b = int.tryParse(_bController.text.trim());
    if (r == null || g == null || b == null) {
      setState(() => _errorKey = 'colorconv_error_rgb');
      return;
    }
    if (r < 0 || r > 255 || g < 0 || g > 255 || b < 0 || b > 255) {
      setState(() => _errorKey = 'colorconv_error_rgb_range');
      return;
    }
    setState(() {
      _errorKey = null;
      _activeField = 0;
      final Color c = Color.fromARGB(255, r, g, b);
      _hexController.text = _hexFromColor(c);
      final List<double> hsl = _rgbToHsl(r, g, b);
      _hController.text = hsl[0].round().toString();
      _sController.text = hsl[1].round().toString();
      _lController.text = hsl[2].round().toString();
      _color = c;
      _activeField = 2;
    });
  }

  void _onHsl() {
    if (_activeField != 3) return;
    final int? h = int.tryParse(_hController.text.trim());
    final int? s = int.tryParse(_sController.text.trim());
    final int? l = int.tryParse(_lController.text.trim());
    if (h == null || s == null || l == null) {
      setState(() => _errorKey = 'colorconv_error_hsl');
      return;
    }
    if (h < 0 || h > 360 || s < 0 || s > 100 || l < 0 || l > 100) {
      setState(() => _errorKey = 'colorconv_error_hsl_range');
      return;
    }
    setState(() {
      _errorKey = null;
      _activeField = 0;
      final Color c = _hslToColor(h.toDouble(), s.toDouble(), l.toDouble());
      _hexController.text = _hexFromColor(c);
      _rController.text = (c.r * 255).round().toString();
      _gController.text = (c.g * 255).round().toString();
      _bController.text = (c.b * 255).round().toString();
      _color = c;
      _activeField = 3;
    });
  }

  String get _rgbString =>
      'rgb(${_rController.text}, ${_gController.text}, ${_bController.text})';

  String get _hslString =>
      'hsl(${_hController.text}, ${_sController.text}%, ${_lController.text}%)';

  Future<void> _copy(String text, String fieldKey) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _justCopiedField = fieldKey);
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (mounted && _justCopiedField == fieldKey) {
        setState(() => _justCopiedField = null);
      }
    });
  }

  void _clear() {
    HapticFeedback.selectionClick();
    setState(() {
      _activeField = 0;
      _setAll(const Color(0xFF000000));
    });
  }

  void _randomColor() {
    HapticFeedback.mediumImpact();
    final Random rng = Random();
    setState(() {
      _activeField = 0;
      _setAll(Color.fromARGB(
        255,
        rng.nextInt(256),
        rng.nextInt(256),
        rng.nextInt(256),
      ));
    });
  }

  void _pickPreset(Color c) {
    HapticFeedback.selectionClick();
    setState(() {
      _activeField = 0;
      _setAll(c);
    });
  }

  bool get _isLightColor => _color.computeLuminance() > 0.5;

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
          context.t('colorconv_title'),
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
                  _SwatchPreview(
                    color: _color,
                    hex: _hexController.text,
                    isLight: _isLightColor,
                    justCopied: _justCopiedField == 'swatch',
                    onTap: () => _copy(_hexController.text, 'swatch'),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _presets.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (BuildContext context, int i) {
                        final Color p = _presets[i];
                        final bool selected =
                            _hexFromColor(p) == _hexFromColor(_color);
                        return GestureDetector(
                          onTap: () => _pickPreset(p),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: p,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? (isDark ? Colors.white : Colors.black)
                                    : Colors.white.withOpacity(0.5),
                                width: selected ? 2.5 : 1.5,
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
                                context.t('colorconv_hex'),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            _GlassIconButton(
                              icon: _justCopiedField == 'hex'
                                  ? Icons.check_rounded
                                  : Icons.copy_rounded,
                              isDark: isDark,
                              highlighted: _justCopiedField == 'hex',
                              tooltip: _tr(context, 'colorconv_copy', 'Copy'),
                              onTap: () =>
                                  _copy(_hexController.text, 'hex'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _GlassTextField(
                          controller: _hexController,
                          isDark: isDark,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9a-fA-F#]')),
                            LengthLimitingTextInputFormatter(7),
                          ],
                          onTap: () => _activeField = 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _GlassCard(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                context.t('colorconv_rgb'),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            _GlassIconButton(
                              icon: _justCopiedField == 'rgb'
                                  ? Icons.check_rounded
                                  : Icons.copy_rounded,
                              isDark: isDark,
                              highlighted: _justCopiedField == 'rgb',
                              tooltip: _tr(context, 'colorconv_copy', 'Copy'),
                              onTap: () => _copy(_rgbString, 'rgb'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _GlassNumberField(
                                label: 'R',
                                controller: _rController,
                                isDark: isDark,
                                onTap: () => _activeField = 2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _GlassNumberField(
                                label: 'G',
                                controller: _gController,
                                isDark: isDark,
                                onTap: () => _activeField = 2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _GlassNumberField(
                                label: 'B',
                                controller: _bController,
                                isDark: isDark,
                                onTap: () => _activeField = 2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _GlassCard(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                context.t('colorconv_hsl'),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            _GlassIconButton(
                              icon: _justCopiedField == 'hsl'
                                  ? Icons.check_rounded
                                  : Icons.copy_rounded,
                              isDark: isDark,
                              highlighted: _justCopiedField == 'hsl',
                              tooltip: _tr(context, 'colorconv_copy', 'Copy'),
                              onTap: () => _copy(_hslString, 'hsl'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _GlassNumberField(
                                label: 'H',
                                controller: _hController,
                                isDark: isDark,
                                onTap: () => _activeField = 3,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _GlassNumberField(
                                label: 'S',
                                controller: _sController,
                                isDark: isDark,
                                onTap: () => _activeField = 3,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _GlassNumberField(
                                label: 'L',
                                controller: _lController,
                                isDark: isDark,
                                onTap: () => _activeField = 3,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: _errorKey == null
                        ? const SizedBox(width: double.infinity)
                        : Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _ErrorBanner(
                        text: context.t(_errorKey!),
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _GlassOutlinedButton(
                          isDark: isDark,
                          label: context.t('colorconv_clear'),
                          icon: Icons.close_rounded,
                          onTap: _clear,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _GlassPrimaryButton(
                          isDark: isDark,
                          label: _tr(context, 'colorconv_random', 'Random'),
                          icon: Icons.shuffle_rounded,
                          onTap: _randomColor,
                        ),
                      ),
                    ],
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

class _SwatchPreview extends StatelessWidget {
  const _SwatchPreview({
    required this.color,
    required this.hex,
    required this.isLight,
    required this.justCopied,
    required this.onTap,
  });

  final Color color;
  final String hex;
  final bool isLight;
  final bool justCopied;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color textColor = isLight ? Colors.black87 : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: justCopied
              ? Row(
            key: const ValueKey<String>('copied'),
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.check_circle_rounded, color: textColor),
              const SizedBox(width: 8),
              Text(
                _tr(context, 'colorconv_copied', 'Copied'),
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ],
          )
              : Text(
            hex,
            key: const ValueKey<String>('hex'),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 24,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}


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
/// building block reused for cards, buttons and fields.
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
    this.onTap,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final bool isDark;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDark
                ? Colors.black.withOpacity(0.18)
                : Colors.white.withOpacity(0.45),
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.10 : 0.5),
            ),
          ),
          child: TextField(
            controller: controller,
            onTap: onTap,
            inputFormatters: inputFormatters,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassNumberField extends StatelessWidget {
  const _GlassNumberField({
    required this.label,
    required this.controller,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final TextEditingController controller;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isDark
                ? Colors.black.withOpacity(0.18)
                : Colors.white.withOpacity(0.45),
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.10 : 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: (isDark ? Colors.white70 : Colors.black54)
                      .withOpacity(0.7),
                ),
              ),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                onTap: onTap,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
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
              height: 50,
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

class _GlassOutlinedButton extends StatelessWidget {
  const _GlassOutlinedButton({
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
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.white.withOpacity(0.4),
          child: InkWell(
            onTap: onTap,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withOpacity(isDark ? 0.14 : 0.6),
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(icon,
                      size: 18,
                      color: isDark ? Colors.white70 : Colors.black87),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
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