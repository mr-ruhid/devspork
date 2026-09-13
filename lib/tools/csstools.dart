import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class CssTools extends StatefulWidget {
  const CssTools({super.key});

  @override
  State<CssTools> createState() => _CssToolsState();
}

class _CssToolsState extends State<CssTools>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  String _gradientType = 'linear';
  String _gradientDirection = 'to bottom';
  List<Color> _gradientColors = <Color>[
    const Color(0xFF7C4DFF),
    const Color(0xFF00E5FF),
  ];
  List<double> _gradientStops = <double>[0.0, 1.0];

  double _shadowX = 0;
  double _shadowY = 4;
  double _shadowBlur = 12;
  double _shadowSpread = 0;
  Color _shadowColor = Colors.black;
  double _shadowOpacity = 0.25;
  bool _shadowInset = false;
  bool _shadowMultiple = false;
  List<_ShadowLayer> _shadowLayers = <_ShadowLayer>[
    _ShadowLayer(
      x: 0,
      y: 4,
      blur: 12,
      spread: 0,
      color: Colors.black,
      opacity: 0.25,
      inset: false,
    ),
  ];

  Color _contrastFg = Colors.black;
  Color _contrastBg = Colors.white;

  static const List<String> _directions = <String>[
    'to top',
    'to top right',
    'to right',
    'to bottom right',
    'to bottom',
    'to bottom left',
    'to left',
    'to top left',
  ];

  static const List<String> _gradientTypes = <String>[
    'linear',
    'radial',
    'conic',
  ];

  static const List<Color> _palette = <Color>[
    Colors.black,
    Colors.white,
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Color(0xFF7C4DFF),
    Color(0xFF00E5FF),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _hex(Color c) {
    final int r = (c.r * 255).round();
    final int g = (c.g * 255).round();
    final int b = (c.b * 255).round();
    return '#'
        '${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  String _buildGradientCss() {
    final StringBuffer b = StringBuffer();
    final List<String> stops = <String>[];
    for (int i = 0; i < _gradientColors.length; i++) {
      final double stop = i < _gradientStops.length
          ? _gradientStops[i]
          : i / (_gradientColors.length - 1);
      stops.add(
        '${_hex(_gradientColors[i])} ${(stop * 100).toStringAsFixed(0)}%',
      );
    }

    if (_gradientType == 'linear') {
      b.write('background: linear-gradient($_gradientDirection, ');
    } else if (_gradientType == 'radial') {
      b.write('background: radial-gradient(circle, ');
    } else {
      b.write('background: conic-gradient(from 0deg, ');
    }
    b.write('${stops.join(', ')}');
    b.write(');');
    return b.toString();
  }

  Gradient _flutterGradient() {
    final bool stopsOk = _gradientStops.length == _gradientColors.length;
    if (_gradientType == 'linear') {
      return LinearGradient(
        begin: _beginFor(_gradientDirection),
        end: _endFor(_gradientDirection),
        colors: _gradientColors,
        stops: stopsOk ? _gradientStops : null,
      );
    } else if (_gradientType == 'radial') {
      return RadialGradient(
        colors: _gradientColors,
        stops: stopsOk ? _gradientStops : null,
      );
    } else {
      return SweepGradient(
        colors: _gradientColors,
        stops: stopsOk ? _gradientStops : null,
      );
    }
  }

  Alignment _beginFor(String dir) {
    switch (dir) {
      case 'to top':
        return Alignment.bottomCenter;
      case 'to top right':
        return Alignment.bottomLeft;
      case 'to right':
        return Alignment.centerLeft;
      case 'to bottom right':
        return Alignment.topLeft;
      case 'to bottom':
        return Alignment.topCenter;
      case 'to bottom left':
        return Alignment.topRight;
      case 'to left':
        return Alignment.centerRight;
      case 'to top left':
        return Alignment.bottomRight;
      default:
        return Alignment.topCenter;
    }
  }

  Alignment _endFor(String dir) {
    switch (dir) {
      case 'to top':
        return Alignment.topCenter;
      case 'to top right':
        return Alignment.topRight;
      case 'to right':
        return Alignment.centerRight;
      case 'to bottom right':
        return Alignment.bottomRight;
      case 'to bottom':
        return Alignment.bottomCenter;
      case 'to bottom left':
        return Alignment.bottomLeft;
      case 'to left':
        return Alignment.centerLeft;
      case 'to top left':
        return Alignment.topLeft;
      default:
        return Alignment.bottomCenter;
    }
  }

  void _addGradientColor() {
    if (_gradientColors.length >= 6) return;
    setState(() {
      _gradientColors.add(_palette[_gradientColors.length % _palette.length]);
      _gradientStops.add(1.0);
    });
  }

  void _removeGradientColor(int index) {
    if (_gradientColors.length <= 2) return;
    setState(() {
      _gradientColors.removeAt(index);
      if (index < _gradientStops.length) {
        _gradientStops.removeAt(index);
      }
    });
  }

  String _buildShadowCss() {
    if (_shadowMultiple) {
      final List<String> parts = <String>[];
      for (final _ShadowLayer l in _shadowLayers) {
        final String color = _rgba(l.color, l.opacity);
        final String inset = l.inset ? 'inset ' : '';
        parts.add(
          '$inset${l.x.toStringAsFixed(0)}px ${l.y.toStringAsFixed(0)}px '
              '${l.blur.toStringAsFixed(0)}px ${l.spread.toStringAsFixed(0)}px $color',
        );
      }
      return 'box-shadow: ${parts.join(', ')};';
    }
    final String color = _rgba(_shadowColor, _shadowOpacity);
    final String inset = _shadowInset ? 'inset ' : '';
    return 'box-shadow: $inset${_shadowX.toStringAsFixed(0)}px '
        '${_shadowY.toStringAsFixed(0)}px '
        '${_shadowBlur.toStringAsFixed(0)}px '
        '${_shadowSpread.toStringAsFixed(0)}px $color;';
  }

  String _rgba(Color c, double opacity) {
    final int r = (c.r * 255).round();
    final int g = (c.g * 255).round();
    final int b = (c.b * 255).round();
    return 'rgba($r, $g, $b, ${opacity.toStringAsFixed(2)})';
  }

  /// Flutter-in daxili `BoxShadow` class-ında `inset` parametri yoxdur —
  /// CSS-dəki "inset" konsepti (kölgənin qutunun içinə düşməsi) Flutter-də
  /// dəstəklənmir. `_shadowInset` / `l.inset` yalnız CSS mətnini qurmaq
  /// üçün (`_buildShadowCss`) istifadə olunur; canlı önizləmə isə həmişə
  /// normal (outset) kölgə kimi göstərilir.
  List<BoxShadow> _flutterShadows() {
    if (_shadowMultiple) {
      return _shadowLayers.map((_ShadowLayer l) {
        return BoxShadow(
          offset: Offset(l.x, l.y),
          blurRadius: l.blur,
          spreadRadius: l.spread,
          color: l.color.withValues(alpha: l.opacity),
        );
      }).toList();
    }
    return <BoxShadow>[
      BoxShadow(
        offset: Offset(_shadowX, _shadowY),
        blurRadius: _shadowBlur,
        spreadRadius: _shadowSpread,
        color: _shadowColor.withValues(alpha: _shadowOpacity),
      ),
    ];
  }

  double _luminance(Color c) {
    double chan(double v) {
      return v <= 0.03928
          ? v / 12.92
          : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    }

    final double r = chan(c.r);
    final double g = chan(c.g);
    final double b = chan(c.b);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  double _contrastRatio(Color fg, Color bg) {
    final double l1 = _luminance(fg);
    final double l2 = _luminance(bg);
    final double lighter = l1 > l2 ? l1 : l2;
    final double darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  String _wcagLevel(double ratio, {required bool large}) {
    if (large) {
      if (ratio >= 4.5) return 'AAA';
      if (ratio >= 3.0) return 'AA';
      return 'FAIL';
    }
    if (ratio >= 7.0) return 'AAA';
    if (ratio >= 4.5) return 'AA';
    return 'FAIL';
  }

  Future<void> _copy(String text) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('csstools_copied'))),
    );
  }

  // ---------- Glass helpers ----------

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Widget _glassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    final bool isDark = _isDark;
    final Color tint =
    isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.55);
    final Color borderColor =
    isDark ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.6);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _glassPreviewFrame({required Widget child, double height = 140}) {
    final bool isDark = _isDark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(isDark ? 0.05 : 0.35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.15 : 0.6),
              width: 1.2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _colorRow({
    required String labelKey,
    required Color color,
    required ValueChanged<Color> onColorChanged,
    VoidCallback? onRemove,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              context.t(labelKey),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _hex(color),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
          if (onRemove != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _colorPalette({
    required Color current,
    required ValueChanged<Color> onSelect,
  }) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _palette.map((Color c) {
        final bool selected = c.value == current.value;
        return GestureDetector(
          onTap: () => onSelect(c),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
                width: selected ? 3 : 1,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _cssOutput(String css) {
    return _glassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: SelectableText(
              css,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => _copy(css),
            icon: const Icon(Icons.copy, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _sliderRow(
      String labelKey,
      double value,
      double min,
      double max,
      ValueChanged<double> onChanged, {
        bool percent = false,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                context.t(labelKey),
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Text(
              percent
                  ? '${(value * 100).toStringAsFixed(0)}%'
                  : value.toStringAsFixed(0),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: percent ? 100 : (max - min).round(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _sliderRowCompact(
      String label,
      double value,
      double min,
      double max,
      ValueChanged<double> onChanged,
      ) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).round(),
            label: value.toStringAsFixed(0),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            value.toStringAsFixed(0),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradient() {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            height: 140,
            decoration: BoxDecoration(
              gradient: _flutterGradient(),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.outlineVariant),
            ),
          ),
          const SizedBox(height: 16),
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  context.t('csstools_gradient_type'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: _gradientTypes.map((String t) {
                    return ButtonSegment<String>(
                      value: t,
                      label: Text(context.t('csstools_gradient_$t')),
                    );
                  }).toList(),
                  selected: <String>{_gradientType},
                  onSelectionChanged: (Set<String> s) {
                    setState(() {
                      _gradientType = s.first;
                    });
                  },
                ),
                if (_gradientType == 'linear') ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    context.t('csstools_gradient_direction'),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _directions.map((String d) {
                      return ChoiceChip(
                        label: Text(d, style: const TextStyle(fontSize: 11)),
                        selected: _gradientDirection == d,
                        backgroundColor: Colors.white.withOpacity(
                          _isDark ? 0.06 : 0.4,
                        ),
                        onSelected: (_) {
                          setState(() {
                            _gradientDirection = d;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        context.t('csstools_gradient_colors'),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    if (_gradientColors.length < 6)
                      IconButton(
                        onPressed: _addGradientColor,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                for (int i = 0; i < _gradientColors.length; i++)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _colorRow(
                        labelKey: 'csstools_gradient_color_n',
                        color: _gradientColors[i],
                        onColorChanged: (Color c) {
                          setState(() {
                            _gradientColors[i] = c;
                          });
                        },
                        onRemove: _gradientColors.length > 2
                            ? () => _removeGradientColor(i)
                            : null,
                      ),
                      Row(
                        children: <Widget>[
                          SizedBox(
                            width: 60,
                            child: Text(
                              '${(_gradientStops[i] * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Slider(
                              value: _gradientStops[i],
                              min: 0,
                              max: 1,
                              divisions: 100,
                              label:
                              '${(_gradientStops[i] * 100).toStringAsFixed(0)}%',
                              onChanged: (double v) {
                                setState(() {
                                  _gradientStops[i] = v;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      Text(
                        context.t('csstools_gradient_pick'),
                        style: const TextStyle(fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      _colorPalette(
                        current: _gradientColors[i],
                        onSelect: (Color c) {
                          setState(() {
                            _gradientColors[i] = c;
                          });
                        },
                      ),
                      if (i < _gradientColors.length - 1)
                        const Divider(height: 24),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _cssOutput(_buildGradientCss()),
        ],
      ),
    );
  }

  Widget _buildShadow() {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _glassPreviewFrame(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: _flutterShadows(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.t('csstools_shadow_multiple')),
                  value: _shadowMultiple,
                  onChanged: (bool v) {
                    setState(() {
                      _shadowMultiple = v;
                    });
                  },
                ),
                if (!_shadowMultiple) ...<Widget>[
                  _sliderRow('csstools_shadow_x', _shadowX, -50, 50,
                          (double v) {
                        setState(() => _shadowX = v);
                      }),
                  _sliderRow('csstools_shadow_y', _shadowY, -50, 50,
                          (double v) {
                        setState(() => _shadowY = v);
                      }),
                  _sliderRow(
                      'csstools_shadow_blur', _shadowBlur, 0, 100, (double v) {
                    setState(() => _shadowBlur = v);
                  }),
                  _sliderRow(
                    'csstools_shadow_spread',
                    _shadowSpread,
                    -50,
                    50,
                        (double v) {
                      setState(() => _shadowSpread = v);
                    },
                  ),
                  _sliderRow(
                    'csstools_shadow_opacity',
                    _shadowOpacity,
                    0,
                    1,
                        (double v) {
                      setState(() => _shadowOpacity = v);
                    },
                    percent: true,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.t('csstools_shadow_inset')),
                    value: _shadowInset,
                    onChanged: (bool v) {
                      setState(() => _shadowInset = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.t('csstools_shadow_color'),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  _colorPalette(
                    current: _shadowColor,
                    onSelect: (Color c) {
                      setState(() => _shadowColor = c);
                    },
                  ),
                ] else ...<Widget>[
                  for (int i = 0; i < _shadowLayers.length; i++)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(
                          _isDark ? 0.05 : 0.35,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  '${context.t('csstools_shadow_layer')} ${i + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: () {
                                  setState(() {
                                    _shadowLayers.removeAt(i);
                                  });
                                },
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                          _sliderRowCompact(
                            'X',
                            _shadowLayers[i].x,
                            -50,
                            50,
                                (double v) {
                              setState(() => _shadowLayers[i].x = v);
                            },
                          ),
                          _sliderRowCompact(
                            'Y',
                            _shadowLayers[i].y,
                            -50,
                            50,
                                (double v) {
                              setState(() => _shadowLayers[i].y = v);
                            },
                          ),
                          _sliderRowCompact(
                            'Blur',
                            _shadowLayers[i].blur,
                            0,
                            100,
                                (double v) {
                              setState(() => _shadowLayers[i].blur = v);
                            },
                          ),
                          _sliderRowCompact(
                            'Spread',
                            _shadowLayers[i].spread,
                            -50,
                            50,
                                (double v) {
                              setState(() => _shadowLayers[i].spread = v);
                            },
                          ),
                        ],
                      ),
                    ),
                  if (_shadowLayers.length < 5)
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _shadowLayers.add(_ShadowLayer(
                            x: 0,
                            y: 4,
                            blur: 12,
                            spread: 0,
                            color: Colors.black,
                            opacity: 0.25,
                            inset: false,
                          ));
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: Text(context.t('csstools_shadow_add_layer')),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _cssOutput(_buildShadowCss()),
        ],
      ),
    );
  }

  Widget _buildContrast() {
    final double ratio = _contrastRatio(_contrastFg, _contrastBg);
    final String normalLevel = _wcagLevel(ratio, large: false);
    final String largeLevel = _wcagLevel(ratio, large: true);
    final Color levelColor = normalLevel == 'FAIL'
        ? Colors.red
        : normalLevel == 'AA'
        ? Colors.orange
        : Colors.green;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: _contrastBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).dividerColor,
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  context.t('csstools_contrast_sample_large'),
                  style: TextStyle(
                    color: _contrastFg,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.t('csstools_contrast_sample_normal'),
                  style: TextStyle(
                    color: _contrastFg,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _glassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                Text(
                  ratio.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: levelColor,
                  ),
                ),
                Text(
                  context.t('csstools_contrast_ratio'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _badge(
                        context.t('csstools_contrast_normal'),
                        normalLevel,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _badge(
                        context.t('csstools_contrast_large'),
                        largeLevel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  context.t('csstools_contrast_foreground'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                _colorPalette(
                  current: _contrastFg,
                  onSelect: (Color c) {
                    setState(() => _contrastFg = c);
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  context.t('csstools_contrast_background'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                _colorPalette(
                  current: _contrastBg,
                  onSelect: (Color c) {
                    setState(() => _contrastBg = c);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.t('csstools_contrast_info'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'AA  normal text:  4.5:1\n'
                      'AA  large text:   3.0:1\n'
                      'AAA normal text:  7.0:1\n'
                      'AAA large text:   4.5:1',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, String level) {
    final Color color = level == 'FAIL'
        ? Colors.red
        : level == 'AA'
        ? Colors.orange
        : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            level,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = _isDark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(context.t('csstools_title')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: <Widget>[
            Tab(text: context.t('csstools_tab_gradient')),
            Tab(text: context.t('csstools_tab_shadow')),
            Tab(text: context.t('csstools_tab_contrast')),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? <Color>[
              const Color(0xFF1B1035),
              const Color(0xFF0F1C3F),
              const Color(0xFF091626),
            ]
                : <Color>[
              const Color(0xFFDCE9FF),
              const Color(0xFFE9E2FF),
              const Color(0xFFF3F6FF),
            ],
          ),
        ),
        child: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: <Widget>[
              _buildGradient(),
              _buildShadow(),
              _buildContrast(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShadowLayer {
  double x;
  double y;
  double blur;
  double spread;
  Color color;
  double opacity;
  bool inset;

  _ShadowLayer({
    required this.x,
    required this.y,
    required this.blur,
    required this.spread,
    required this.color,
    required this.opacity,
    required this.inset,
  });
}