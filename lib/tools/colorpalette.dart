import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/localization/app_localization.dart';

const Color _accentA = Color(0xFF7C4DFF);
const Color _accentB = Color(0xFF00E5FF);
const Color _danger = Color(0xFFFF5C5C);
const Color _success = Color(0xFF4BD68B);
const Color _bgTop = Color(0xFF1B1035);
const Color _bgMid = Color(0xFF2A1550);
const Color _bgBot = Color(0xFF0F2A4A);

enum HarmonyType {
  monochromatic,
  analogous,
  complementary,
  splitComplementary,
  triadic,
  tetradic,
  square,
}

extension HarmonyTypeX on HarmonyType {
  String get labelKey {
    switch (this) {
      case HarmonyType.monochromatic:
        return 'colorpalette_harmony_mono';
      case HarmonyType.analogous:
        return 'colorpalette_harmony_analogous';
      case HarmonyType.complementary:
        return 'colorpalette_harmony_complementary';
      case HarmonyType.splitComplementary:
        return 'colorpalette_harmony_split';
      case HarmonyType.triadic:
        return 'colorpalette_harmony_triadic';
      case HarmonyType.tetradic:
        return 'colorpalette_harmony_tetradic';
      case HarmonyType.square:
        return 'colorpalette_harmony_square';
    }
  }

  int get colorCount {
    switch (this) {
      case HarmonyType.monochromatic:
        return 5;
      case HarmonyType.analogous:
        return 5;
      case HarmonyType.complementary:
        return 2;
      case HarmonyType.splitComplementary:
        return 3;
      case HarmonyType.triadic:
        return 3;
      case HarmonyType.tetradic:
        return 4;
      case HarmonyType.square:
        return 4;
    }
  }
}

class HslColor {
  final double h;
  final double s;
  final double l;

  const HslColor(this.h, this.s, this.l);

  static HslColor fromColor(Color color) {
    final double r = (color.r * 255.0) / 255.0;
    final double g = (color.g * 255.0) / 255.0;
    final double b = (color.b * 255.0) / 255.0;

    final double maxC = math.max(r, math.max(g, b));
    final double minC = math.min(r, math.min(g, b));
    final double delta = maxC - minC;

    double h = 0;
    if (delta != 0) {
      if (maxC == r) {
        h = 60 * (((g - b) / delta) % 6);
      } else if (maxC == g) {
        h = 60 * (((b - r) / delta) + 2);
      } else {
        h = 60 * (((r - g) / delta) + 4);
      }
    }
    if (h < 0) h += 360;

    final double l = (maxC + minC) / 2;
    double s = 0;
    if (delta != 0) {
      s = delta / (1 - (2 * l - 1).abs());
    }

    return HslColor(h, s * 100, l * 100);
  }

  Color toColor() {
    final double hh = ((h % 360) + 360) % 360;
    final double ss = s.clamp(0, 100) / 100;
    final double ll = l.clamp(0, 100) / 100;

    final double c = (1 - (2 * ll - 1).abs()) * ss;
    final double x = c * (1 - ((hh / 60) % 2 - 1).abs());
    final double m = ll - c / 2;

    double r = 0;
    double g = 0;
    double b = 0;

    if (hh < 60) {
      r = c;
      g = x;
      b = 0;
    } else if (hh < 120) {
      r = x;
      g = c;
      b = 0;
    } else if (hh < 180) {
      r = 0;
      g = c;
      b = x;
    } else if (hh < 240) {
      r = 0;
      g = x;
      b = c;
    } else if (hh < 300) {
      r = x;
      g = 0;
      b = c;
    } else {
      r = c;
      g = 0;
      b = x;
    }

    return Color.fromARGB(
      255,
      ((r + m) * 255).round().clamp(0, 255),
      ((g + m) * 255).round().clamp(0, 255),
      ((b + m) * 255).round().clamp(0, 255),
    );
  }

  HslColor copyWith({double? h, double? s, double? l}) => HslColor(
    h ?? this.h,
    s ?? this.s,
    l ?? this.l,
  );
}

class PaletteGenerator {
  PaletteGenerator._();

  static List<Color> generate(Color base, HarmonyType type) {
    final HslColor hsl = HslColor.fromColor(base);

    switch (type) {
      case HarmonyType.monochromatic:
        return _monochromatic(hsl);
      case HarmonyType.analogous:
        return _analogous(hsl);
      case HarmonyType.complementary:
        return _complementary(hsl);
      case HarmonyType.splitComplementary:
        return _splitComplementary(hsl);
      case HarmonyType.triadic:
        return _triadic(hsl);
      case HarmonyType.tetradic:
        return _tetradic(hsl);
      case HarmonyType.square:
        return _square(hsl);
    }
  }

  static List<Color> _monochromatic(HslColor base) {
    final List<double> lightness = <double>[25, 40, 55, 70, 85];
    final double targetL = base.l;
    int nearestIdx = 0;
    double minDist = double.infinity;
    for (int i = 0; i < lightness.length; i++) {
      final double d = (lightness[i] - targetL).abs();
      if (d < minDist) {
        minDist = d;
        nearestIdx = i;
      }
    }

    final List<Color> result = <Color>[];
    for (int i = 0; i < lightness.length; i++) {
      result.add(
        HslColor(
          base.h,
          base.s.clamp(15, 90),
          lightness[i],
        ).toColor(),
      );
    }

    result[nearestIdx] = base.toColor();
    return result;
  }

  static List<Color> _analogous(HslColor base) {
    const List<double> offsets = <double>[-40, -20, 0, 20, 40];
    return offsets
        .map((double o) => HslColor(base.h + o, base.s, base.l).toColor())
        .toList();
  }

  static List<Color> _complementary(HslColor base) {
    return <Color>[
      base.toColor(),
      HslColor(base.h + 180, base.s, base.l).toColor(),
    ];
  }

  static List<Color> _splitComplementary(HslColor base) {
    return <Color>[
      base.toColor(),
      HslColor(base.h + 150, base.s, base.l).toColor(),
      HslColor(base.h + 210, base.s, base.l).toColor(),
    ];
  }

  static List<Color> _triadic(HslColor base) {
    return <Color>[
      base.toColor(),
      HslColor(base.h + 120, base.s, base.l).toColor(),
      HslColor(base.h + 240, base.s, base.l).toColor(),
    ];
  }

  static List<Color> _tetradic(HslColor base) {
    return <Color>[
      base.toColor(),
      HslColor(base.h + 60, base.s, base.l).toColor(),
      HslColor(base.h + 180, base.s, base.l).toColor(),
      HslColor(base.h + 240, base.s, base.l).toColor(),
    ];
  }

  static List<Color> _square(HslColor base) {
    return <Color>[
      base.toColor(),
      HslColor(base.h + 90, base.s, base.l).toColor(),
      HslColor(base.h + 180, base.s, base.l).toColor(),
      HslColor(base.h + 270, base.s, base.l).toColor(),
    ];
  }
}

class ColorPalette extends StatefulWidget {
  const ColorPalette({super.key});

  @override
  State<ColorPalette> createState() => _ColorPaletteState();
}

class _ColorPaletteState extends State<ColorPalette> {
  Color _base = const Color(0xFF7C4DFF);
  HarmonyType _harmony = HarmonyType.monochromatic;
  List<Color> _palette = <Color>[];

  final TextEditingController _hexCtrl =
  TextEditingController(text: '7C4DFF');

  @override
  void initState() {
    super.initState();
    _regenerate();
  }

  @override
  void dispose() {
    _hexCtrl.dispose();
    super.dispose();
  }

  void _regenerate() {
    _palette = PaletteGenerator.generate(_base, _harmony);
  }

  void _setBase(Color color) {
    setState(() {
      _base = color;
      _hexCtrl.text = _toHex(color).substring(1);
      _regenerate();
    });
  }

  void _setHarmony(HarmonyType h) {
    setState(() {
      _harmony = h;
      _regenerate();
    });
  }

  void _onHexChanged(String raw) {
    final String cleaned =
    raw.replaceAll('#', '').replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
    if (cleaned.length != 6) return;
    final int? value = int.tryParse(cleaned, radix: 16);
    if (value == null) return;
    setState(() {
      _base = Color(0xFF000000 | value);
      _regenerate();
    });
  }

  void _randomBase() {
    final math.Random rng = math.Random();
    final int r = rng.nextInt(256);
    final int g = rng.nextInt(256);
    final int b = rng.nextInt(256);
    _setBase(Color.fromARGB(255, r, g, b));
  }

  String _toHex(Color color) {
    final int r = (color.r * 255).round();
    final int g = (color.g * 255).round();
    final int b = (color.b * 255).round();
    return '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  String _toRgb(Color color) {
    final int r = (color.r * 255).round();
    final int g = (color.g * 255).round();
    final int b = (color.b * 255).round();
    return 'rgb($r, $g, $b)';
  }

  String _toHsl(Color color) {
    final HslColor hsl = HslColor.fromColor(color);
    return 'hsl(${hsl.h.round()}, '
        '${hsl.s.round()}%, '
        '${hsl.l.round()}%)';
  }

  double _luminance(Color c) => c.computeLuminance();

  Color _contrastText(Color bg) =>
      _luminance(bg) > 0.5 ? Colors.black87 : Colors.white;

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    _showSnack(context.t('colorpalette_copied'));
  }

  Future<void> _copyAll() async {
    final StringBuffer sb = StringBuffer();
    for (int i = 0; i < _palette.length; i++) {
      sb.writeln(
        '${i + 1}. ${_toHex(_palette[i])}  '
            '${_toRgb(_palette[i])}  '
            '${_toHsl(_palette[i])}',
      );
    }
    await Clipboard.setData(ClipboardData(text: sb.toString().trimRight()));
    if (!mounted) return;
    _showSnack(context.t('colorpalette_copied_all'));
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withOpacity(0.75),
        content: Text(message),
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
        title: Text(context.t('colorpalette_title')),
        actions: <Widget>[
          _glassIconButton(
            icon: Icons.casino_outlined,
            tooltip: context.t('colorpalette_random'),
            onTap: _randomBase,
          ),
          _glassIconButton(
            icon: Icons.copy_all_rounded,
            tooltip: context.t('colorpalette_copy_all'),
            onTap: _copyAll,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[_bgTop, _bgMid, _bgBot],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(top: -80, left: -60, child: _blurBlob(220, _accentA)),
            Positioned(
              bottom: -100,
              right: -60,
              child: _blurBlob(260, _accentB),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 72, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _baseColorCard(),
                    const SizedBox(height: 16),
                    _palettePreviewCard(),
                    const SizedBox(height: 16),
                    _harmonyCard(),
                    const SizedBox(height: 16),
                    _shadesCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _baseColorCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.colorize_rounded,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 8),
              Text(
                context.t('colorpalette_base_color'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _base,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: _base.withOpacity(0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: _hexCtrl,
                  onChanged: _onHexChanged,
                  maxLength: 6,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: '7C4DFF',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontFamily: 'monospace',
                      fontSize: 16,
                      letterSpacing: 1.5,
                    ),
                    prefixText: '#',
                    prefixStyle: const TextStyle(
                      color: _accentB,
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    counterText: '',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.06),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: _accentB,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _colorCodeChip(
                  label: 'HEX',
                  value: _toHex(_base),
                  onCopy: () => _copy(_toHex(_base)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _colorCodeChip(
                  label: 'RGB',
                  value: _toRgb(_base),
                  onCopy: () => _copy(_toRgb(_base)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _colorCodeChip(
            label: 'HSL',
            value: _toHsl(_base),
            onCopy: () => _copy(_toHsl(_base)),
          ),
        ],
      ),
    );
  }

  Widget _palettePreviewCard() {
    if (_palette.isEmpty) return const SizedBox.shrink();

    return _GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.palette_rounded,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 8),
              Text(
                context.t('colorpalette_preview'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${_palette.length}',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 80,
              child: Row(
                children: _palette.map((Color c) {
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _copy(_toHex(c)),
                      child: Container(
                        color: c,
                        alignment: Alignment.center,
                        child: Text(
                          _toHex(c).substring(1),
                          style: TextStyle(
                            color: _contrastText(c),
                            fontFamily: 'monospace',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < _palette.length; i++) ...<Widget>[
            _paletteRow(i, _palette[i]),
            if (i < _palette.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Widget _paletteRow(int index, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _toHex(color),
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_toRgb(color)}  •  ${_toHsl(color)}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontFamily: 'monospace',
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          _glassIconButton(
            icon: Icons.copy_rounded,
            tooltip: context.t('colorpalette_copy'),
            onTap: () => _copy(_toHex(color)),
          ),
        ],
      ),
    );
  }

  Widget _harmonyCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 8),
              Text(
                context.t('colorpalette_harmony'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: HarmonyType.values.map((HarmonyType h) {
              final bool selected = _harmony == h;
              return GestureDetector(
                onTap: () => _setHarmony(h),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(
                      colors: <Color>[_accentA, _accentB],
                    )
                        : null,
                    color: selected
                        ? null
                        : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : Colors.white.withOpacity(0.15),
                    ),
                  ),
                  child: Text(
                    context.t(h.labelKey),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _shadesCard() {
    final HslColor baseHsl = HslColor.fromColor(_base);
    final List<Color> shades = <Color>[];
    for (int i = 1; i <= 9; i++) {
      shades.add(
        HslColor(
          baseHsl.h,
          baseHsl.s,
          (i * 10).toDouble(),
        ).toColor(),
      );
    }

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.gradient_rounded,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 8),
              Text(
                context.t('colorpalette_shades'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 60,
              child: Row(
                children: shades.map((Color c) {
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _copy(_toHex(c)),
                      child: Container(
                        color: c,
                        alignment: Alignment.bottomCenter,
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${(HslColor.fromColor(c).l).round()}',
                          style: TextStyle(
                            color: _contrastText(c),
                            fontFamily: 'monospace',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorCodeChip({
    required String label,
    required String value,
    required VoidCallback onCopy,
  }) {
    return GestureDetector(
      onTap: onCopy,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: _accentA.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white70,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.copy_rounded,
              size: 12,
              color: Colors.white38,
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: ClipRRect(
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