import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class DevCalc extends StatefulWidget {
  const DevCalc({super.key});

  @override
  State<DevCalc> createState() => _DevCalcState();
}

class _DevCalcState extends State<DevCalc>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Aspect Ratio
  final TextEditingController _arW1 = TextEditingController(text: '1920');
  final TextEditingController _arH1 = TextEditingController(text: '1080');
  final TextEditingController _arW2 = TextEditingController();
  final TextEditingController _arH2 = TextEditingController(text: '720');
  bool _arLockW = true;
  String _arResult = '';
  String? _arError;

  // File Size
  final TextEditingController _fsValue = TextEditingController(text: '1');
  String _fsFrom = 'MB';
  String _fsTo = 'KB';
  String _fsResult = '';
  String? _fsError;

  // PX to REM/EM
  final TextEditingController _pxValue = TextEditingController(text: '16');
  final TextEditingController _pxBase = TextEditingController(text: '16');
  String _pxResultRem = '';
  String _pxResultEm = '';
  String _pxReversePx = '';
  final TextEditingController _remValue = TextEditingController(text: '1');
  final TextEditingController _remBase = TextEditingController(text: '16');
  String? _pxError;

  // Chmod
  bool _chmodOwnerR = true;
  bool _chmodOwnerW = true;
  bool _chmodOwnerX = true;
  bool _chmodGroupR = true;
  bool _chmodGroupW = false;
  bool _chmodGroupX = true;
  bool _chmodOtherR = true;
  bool _chmodOtherW = false;
  bool _chmodOtherX = true;
  bool _chmodDir = false;
  String _chmodOctal = '755';
  String _chmodSymbolic = '-rwxr-xr-x';
  String _chmodCommand = 'chmod 755 file';

  static const List<String> _sizeUnits = <String>[
    'B',
    'KB',
    'MB',
    'GB',
    'TB',
    'PB',
  ];

  static const Map<String, double> _sizeFactors = <String, double>{
    'B': 1,
    'KB': 1024,
    'MB': 1024 * 1024,
    'GB': 1024 * 1024 * 1024,
    'TB': 1024 * 1024 * 1024 * 1024,
    'PB': 1024 * 1024 * 1024 * 1024 * 1024,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _calcAspect();
    _calcFileSize();
    _calcPx();
    _calcChmod();
    _arW2.addListener(_calcAspect);
    _arH2.addListener(_calcAspect);
    _arW1.addListener(_calcAspect);
    _arH1.addListener(_calcAspect);
    _fsValue.addListener(_calcFileSize);
    _pxValue.addListener(_calcPx);
    _pxBase.addListener(_calcPx);
    _remValue.addListener(_calcPx);
    _remBase.addListener(_calcPx);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _arW1.dispose();
    _arH1.dispose();
    _arW2.dispose();
    _arH2.dispose();
    _fsValue.dispose();
    _pxValue.dispose();
    _pxBase.dispose();
    _remValue.dispose();
    _remBase.dispose();
    super.dispose();
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  // -------- Aspect Ratio --------

  int _gcd(int a, int b) {
    while (b != 0) {
      final int t = b;
      b = a % b;
      a = t;
    }
    return a;
  }

  void _calcAspect() {
    final double? w1 = double.tryParse(_arW1.text);
    final double? h1 = double.tryParse(_arH1.text);
    final double? w2 = double.tryParse(_arW2.text);
    final double? h2 = double.tryParse(_arH2.text);

    if (w1 == null || h1 == null || w1 <= 0 || h1 <= 0) {
      setState(() {
        _arResult = '';
        _arError = 'devcalc_error_inputs';
      });
      return;
    }

    final StringBuffer b = StringBuffer();
    final int iw1 = w1.round();
    final int ih1 = h1.round();
    final int g = _gcd(iw1, ih1);
    b.writeln(
      '${context.t('devcalc_ratio')}: ${iw1 ~/ g}:${ih1 ~/ g}   '
          '(${(w1 / h1).toStringAsFixed(4)})',
    );

    if (_arLockW && h2 != null && h2 > 0) {
      final double newW = h2 * (w1 / h1);
      b.writeln(
        '${context.t('devcalc_new_width')}: ${newW.toStringAsFixed(2)}',
      );
      _arW2.text = newW.toStringAsFixed(2);
    } else if (!_arLockW && w2 != null && w2 > 0) {
      final double newH = w2 / (w1 / h1);
      b.writeln(
        '${context.t('devcalc_new_height')}: ${newH.toStringAsFixed(2)}',
      );
      _arH2.text = newH.toStringAsFixed(2);
    }

    setState(() {
      _arResult = b.toString().trimRight();
      _arError = null;
    });
  }

  // -------- File Size --------

  void _calcFileSize() {
    final double? v = double.tryParse(_fsValue.text);
    if (v == null || v < 0) {
      setState(() {
        _fsResult = '';
        _fsError = 'devcalc_error_inputs';
      });
      return;
    }
    final double bytes = v * (_sizeFactors[_fsFrom] ?? 1);
    final double out = bytes / (_sizeFactors[_fsTo] ?? 1);
    setState(() {
      _fsResult = '${out.toStringAsFixed(4)} $_fsTo';
      _fsError = null;
    });
  }

  // -------- PX to REM/EM --------

  void _calcPx() {
    final double? px = double.tryParse(_pxValue.text);
    final double? base = double.tryParse(_pxBase.text);
    if (px == null || base == null || base <= 0) {
      setState(() {
        _pxResultRem = '';
        _pxResultEm = '';
        _pxError = 'devcalc_error_inputs';
      });
      return;
    }
    final double rem = px / base;
    final double em = px / base;

    final double? remIn = double.tryParse(_remValue.text);
    final double? remBaseIn = double.tryParse(_remBase.text);
    final String reverse =
    (remIn != null && remBaseIn != null && remBaseIn > 0)
        ? '${(remIn * remBaseIn).toStringAsFixed(4)} px'
        : '';

    setState(() {
      _pxResultRem = '${rem.toStringAsFixed(4)} rem';
      _pxResultEm = '${em.toStringAsFixed(4)} em';
      _pxReversePx = reverse;
      _pxError = null;
    });
  }

  // -------- Chmod --------

  int _chmodTriplet(bool r, bool w, bool x) {
    return (r ? 4 : 0) + (w ? 2 : 0) + (x ? 1 : 0);
  }

  String _symbolicFor(bool r, bool w, bool x, {bool isDir = false}) {
    return '${r ? 'r' : '-'}${w ? 'w' : '-'}${x ? 'x' : '-'}';
  }

  void _calcChmod() {
    final int owner = _chmodTriplet(_chmodOwnerR, _chmodOwnerW, _chmodOwnerX);
    final int group = _chmodTriplet(_chmodGroupR, _chmodGroupW, _chmodGroupX);
    final int other = _chmodTriplet(_chmodOtherR, _chmodOtherW, _chmodOtherX);
    final String octal = '$owner$group$other';
    final String prefix = _chmodDir ? 'd' : '-';
    final String sym = '$prefix'
        '${_symbolicFor(_chmodOwnerR, _chmodOwnerW, _chmodOwnerX)}'
        '${_symbolicFor(_chmodGroupR, _chmodGroupW, _chmodGroupX)}'
        '${_symbolicFor(_chmodOtherR, _chmodOtherW, _chmodOtherX)}';
    final String recursive =
    _chmodDir ? 'chmod -R $octal <dir>' : 'chmod $octal <file>';
    setState(() {
      _chmodOctal = octal;
      _chmodSymbolic = sym;
      _chmodCommand = recursive;
    });
  }

  Future<void> _copy(String text) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withOpacity(0.75),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(context.t('devcalc_copied')),
      ),
    );
  }

  // -------- Glass helpers --------

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
              BoxShadow(
                color: Colors.white.withOpacity(isDark ? 0.03 : 0.55),
                blurRadius: 1,
                spreadRadius: 0.5,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _numField({
    required String labelKey,
    required TextEditingController controller,
    String? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      style: const TextStyle(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: context.t(labelKey),
        suffixText: suffix,
        isDense: true,
        filled: true,
        fillColor: Colors.white.withOpacity(_isDark ? 0.06 : 0.3),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _resultCard(String text, ColorScheme colors) {
    return _glassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: SelectableText(
              text,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => _copy(text),
            icon: const Icon(Icons.copy_rounded, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _errorText(String? key, ColorScheme colors) {
    if (key == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: <Widget>[
          Icon(Icons.error_outline_rounded, size: 14, color: colors.error),
          const SizedBox(width: 6),
          Text(
            context.t(key),
            style: TextStyle(color: colors.error, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _glassPill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? colors.primary.withOpacity(0.85)
              : Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? colors.onPrimary : colors.onSurface,
          ),
        ),
      ),
    );
  }

  // -------- Tabs --------

  Widget _buildAspect(ColorScheme colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _sectionLabel(context.t('devcalc_ar_original')),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _numField(
                        labelKey: 'devcalc_ar_width',
                        controller: _arW1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _numField(
                        labelKey: 'devcalc_ar_height',
                        controller: _arH1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _sectionLabel(context.t('devcalc_ar_target')),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _numField(
                        labelKey: 'devcalc_ar_width',
                        controller: _arW2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _numField(
                        labelKey: 'devcalc_ar_height',
                        controller: _arH2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    _glassPill(
                      label: context.t('devcalc_ar_lock_w'),
                      selected: _arLockW,
                      onTap: () {
                        setState(() => _arLockW = true);
                        _calcAspect();
                      },
                    ),
                    const SizedBox(width: 8),
                    _glassPill(
                      label: context.t('devcalc_ar_lock_h'),
                      selected: !_arLockW,
                      onTap: () {
                        setState(() => _arLockW = false);
                        _calcAspect();
                      },
                    ),
                  ],
                ),
                _errorText(_arError, colors),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_arResult.isNotEmpty) _resultCard(_arResult, colors),
          const SizedBox(height: 16),
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _sectionLabel(context.t('devcalc_ar_common')),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <MapEntry<String, String>>[
                    const MapEntry<String, String>('16:9', '1920x1080'),
                    const MapEntry<String, String>('4:3', '1024x768'),
                    const MapEntry<String, String>('21:9', '2560x1080'),
                    const MapEntry<String, String>('1:1', '1080x1080'),
                    const MapEntry<String, String>('9:16', '1080x1920'),
                    const MapEntry<String, String>('3:2', '1500x1000'),
                  ].map((MapEntry<String, String> e) {
                    return _glassPill(
                      label: '${e.key}  (${e.value})',
                      selected: false,
                      onTap: () {
                        final List<String> wh = e.value.split('x');
                        _arW1.text = wh[0];
                        _arH1.text = wh[1];
                        _calcAspect();
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileSize(ColorScheme colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _numField(
                  labelKey: 'devcalc_fs_value',
                  controller: _fsValue,
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _fsFrom,
                        decoration: InputDecoration(
                          labelText: context.t('devcalc_fs_from'),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white.withOpacity(_isDark ? 0.06 : 0.3),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _sizeUnits
                            .map((String u) => DropdownMenuItem<String>(
                          value: u,
                          child: Text(u),
                        ))
                            .toList(),
                        onChanged: (String? v) {
                          if (v == null) return;
                          setState(() {
                            _fsFrom = v;
                          });
                          _calcFileSize();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _fsTo,
                        decoration: InputDecoration(
                          labelText: context.t('devcalc_fs_to'),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white.withOpacity(_isDark ? 0.06 : 0.3),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _sizeUnits
                            .map((String u) => DropdownMenuItem<String>(
                          value: u,
                          child: Text(u),
                        ))
                            .toList(),
                        onChanged: (String? v) {
                          if (v == null) return;
                          setState(() {
                            _fsTo = v;
                          });
                          _calcFileSize();
                        },
                      ),
                    ),
                  ],
                ),
                _errorText(_fsError, colors),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_fsResult.isNotEmpty) _resultCard(_fsResult, colors),
          const SizedBox(height: 16),
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _sectionLabel(context.t('devcalc_fs_common')),
                const Text(
                  '1 KB = 1024 B\n1 MB = 1024 KB\n1 GB = 1024 MB\n1 TB = 1024 GB',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPx(ColorScheme colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _sectionLabel(context.t('devcalc_px_section')),
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: _numField(
                        labelKey: 'devcalc_px_value',
                        controller: _pxValue,
                        suffix: 'px',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _numField(
                        labelKey: 'devcalc_px_base',
                        controller: _pxBase,
                        suffix: 'px',
                      ),
                    ),
                  ],
                ),
                _errorText(_pxError, colors),
                const SizedBox(height: 12),
                if (_pxResultRem.isNotEmpty)
                  _resultCard('REM: $_pxResultRem\nEM: $_pxResultEm', colors),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _sectionLabel(context.t('devcalc_rem_section')),
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: _numField(
                        labelKey: 'devcalc_rem_value',
                        controller: _remValue,
                        suffix: 'rem',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _numField(
                        labelKey: 'devcalc_rem_base',
                        controller: _remBase,
                        suffix: 'px',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_pxReversePx.isNotEmpty)
                  _resultCard('PX: $_pxReversePx', colors),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _sectionLabel(context.t('devcalc_px_common')),
                const Text(
                  '1rem = 16px (base)\n'
                      '4px  = 0.25rem\n'
                      '8px  = 0.5rem\n'
                      '12px = 0.75rem\n'
                      '16px = 1rem\n'
                      '24px = 1.5rem\n'
                      '32px = 2rem',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chmodSwitch(String key, bool value, ValueChanged<bool> cb) {
    return Expanded(
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(context.t(key), style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: cb,
      ),
    );
  }

  Widget _buildChmod(ColorScheme colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _sectionLabel(context.t('devcalc_chmod_owner')),
                Row(
                  children: <Widget>[
                    _chmodSwitch('devcalc_chmod_r', _chmodOwnerR, (bool v) {
                      setState(() => _chmodOwnerR = v);
                      _calcChmod();
                    }),
                    _chmodSwitch('devcalc_chmod_w', _chmodOwnerW, (bool v) {
                      setState(() => _chmodOwnerW = v);
                      _calcChmod();
                    }),
                    _chmodSwitch('devcalc_chmod_x', _chmodOwnerX, (bool v) {
                      setState(() => _chmodOwnerX = v);
                      _calcChmod();
                    }),
                  ],
                ),
                Divider(color: Colors.white.withOpacity(0.25)),
                _sectionLabel(context.t('devcalc_chmod_group')),
                Row(
                  children: <Widget>[
                    _chmodSwitch('devcalc_chmod_r', _chmodGroupR, (bool v) {
                      setState(() => _chmodGroupR = v);
                      _calcChmod();
                    }),
                    _chmodSwitch('devcalc_chmod_w', _chmodGroupW, (bool v) {
                      setState(() => _chmodGroupW = v);
                      _calcChmod();
                    }),
                    _chmodSwitch('devcalc_chmod_x', _chmodGroupX, (bool v) {
                      setState(() => _chmodGroupX = v);
                      _calcChmod();
                    }),
                  ],
                ),
                Divider(color: Colors.white.withOpacity(0.25)),
                _sectionLabel(context.t('devcalc_chmod_other')),
                Row(
                  children: <Widget>[
                    _chmodSwitch('devcalc_chmod_r', _chmodOtherR, (bool v) {
                      setState(() => _chmodOtherR = v);
                      _calcChmod();
                    }),
                    _chmodSwitch('devcalc_chmod_w', _chmodOtherW, (bool v) {
                      setState(() => _chmodOtherW = v);
                      _calcChmod();
                    }),
                    _chmodSwitch('devcalc_chmod_x', _chmodOtherX, (bool v) {
                      setState(() => _chmodOtherX = v);
                      _calcChmod();
                    }),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _glassCard(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.t('devcalc_chmod_dir')),
              value: _chmodDir,
              onChanged: (bool v) {
                setState(() => _chmodDir = v);
                _calcChmod();
              },
            ),
          ),
          const SizedBox(height: 12),
          _resultCard(
            'Octal: $_chmodOctal\nSymbolic: $_chmodSymbolic\nCommand: $_chmodCommand',
            colors,
          ),
          const SizedBox(height: 16),
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _sectionLabel(context.t('devcalc_chmod_common')),
                const Text(
                  '755 = rwxr-xr-x (scripts, executables)\n'
                      '644 = rw-r--r-- (regular files)\n'
                      '600 = rw------- (private keys)\n'
                      '700 = rwx------ (private dirs)\n'
                      '777 = rwxrwxrwx (FULL ACCESS — avoid!)',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
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

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isDark = _isDark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          context.t('devcalc_title'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: colors.surface.withOpacity(0.35)),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(isDark ? 0.08 : 0.4),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withOpacity(0.4)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: const EdgeInsets.symmetric(vertical: 2),
                    indicator: BoxDecoration(
                      color: colors.primary.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    labelColor: colors.onPrimary,
                    unselectedLabelColor: colors.onSurface,
                    labelStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                    tabs: <Widget>[
                      Tab(text: context.t('devcalc_tab_ar')),
                      Tab(text: context.t('devcalc_tab_fs')),
                      Tab(text: context.t('devcalc_tab_px')),
                      Tab(text: context.t('devcalc_tab_chmod')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          DecoratedBox(
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
          ),
          Positioned(
            top: -100,
            right: -80,
            child: _blob(colors.primary.withOpacity(0.28), 240),
          ),
          Positioned(
            bottom: -90,
            left: -60,
            child: _blob(colors.tertiary.withOpacity(0.24), 220),
          ),
          SafeArea(
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                _buildAspect(colors),
                _buildFileSize(colors),
                _buildPx(colors),
                _buildChmod(colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}