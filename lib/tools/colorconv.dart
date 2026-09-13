import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

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

  int _activeField = 0;
  String? _errorKey;
  Color _color = Colors.black;

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
    _setAll(const Color(0xFF000000));
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
    final double max = [rf, gf, bf].reduce((a, c) => a > c ? a : c);
    final double min = [rf, gf, bf].reduce((a, c) => a < c ? a : c);
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

  void _onHex(String value) {
    if (_activeField != 1) return;
    final String v = value.trim().replaceAll('#', '');
    if (v.isEmpty) {
      setState(() {
        _errorKey = null;
      });
      return;
    }
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(v)) {
      setState(() {
        _errorKey = 'colorconv_error_hex';
      });
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
      setState(() {
        _errorKey = r == null || g == null || b == null
            ? 'colorconv_error_rgb'
            : null;
      });
      return;
    }
    if (r < 0 || r > 255 || g < 0 || g > 255 || b < 0 || b > 255) {
      setState(() {
        _errorKey = 'colorconv_error_rgb_range';
      });
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
      setState(() {
        _errorKey = 'colorconv_error_hsl';
      });
      return;
    }
    if (h < 0 || h > 360 || s < 0 || s > 100 || l < 0 || l > 100) {
      setState(() {
        _errorKey = 'colorconv_error_hsl_range';
      });
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

  Future<void> _copy(String text) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('colorconv_copied'))),
    );
  }

  Widget _smallField({
    required String label,
    required TextEditingController controller,
    required int fieldId,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(3),
      ],
      onTap: () {
        _activeField = fieldId;
      },
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('colorconv_title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _hexController,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F#]')),
                LengthLimitingTextInputFormatter(7),
              ],
              onTap: () {
                _activeField = 1;
              },
              decoration: InputDecoration(
                labelText: context.t('colorconv_hex'),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () => _copy(_hexController.text),
                  icon: const Icon(Icons.copy),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.t('colorconv_rgb'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: _smallField(
                    label: 'R',
                    controller: _rController,
                    fieldId: 2,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _smallField(
                    label: 'G',
                    controller: _gController,
                    fieldId: 2,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _smallField(
                    label: 'B',
                    controller: _bController,
                    fieldId: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              context.t('colorconv_hsl'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: _smallField(
                    label: 'H',
                    controller: _hController,
                    fieldId: 3,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _smallField(
                    label: 'S',
                    controller: _sController,
                    fieldId: 3,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _smallField(
                    label: 'L',
                    controller: _lController,
                    fieldId: 3,
                  ),
                ),
              ],
            ),
            if (_errorKey != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  context.t(_errorKey!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _activeField = 0;
                  _setAll(const Color(0xFF000000));
                });
              },
              icon: const Icon(Icons.clear),
              label: Text(context.t('colorconv_clear')),
            ),
          ],
        ),
      ),
    );
  }
}