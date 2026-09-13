import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/localization/app_localization.dart';

class QrGen extends StatefulWidget {
  const QrGen({super.key});

  @override
  State<QrGen> createState() => _QrGenState();
}

class _QrGenState extends State<QrGen> {
  final TextEditingController _controller = TextEditingController();

  String _data = '';
  int _size = 260;
  int _errorLevel = 1;
  Color _fgColor = Colors.black;
  Color _bgColor = Colors.white;

  static const List<Color> _colorOptions = <Color>[
    Colors.black,
    Colors.white,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.indigo,
    Colors.brown,
    Colors.grey,
  ];

  static const List<int> _errorLevels = <int>[0, 1, 2, 3];

  static const List<String> _errorKeys = <String>[
    'qrgen_err_low',
    'qrgen_err_medium',
    'qrgen_err_quartile',
    'qrgen_err_high',
  ];

  @override
  void initState() {
    super.initState();
    _controller.text = 'https://flutter.dev';
    _data = _controller.text;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _update() {
    setState(() {
      _data = _controller.text.trim();
    });
  }

  void _clear() {
    setState(() {
      _controller.clear();
      _data = '';
    });
  }

  Future<void> _paste() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null) return;
    _controller.text = data.text!;
    _update();
  }

  Future<void> _copyData() async {
    if (_data.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _data));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('qrgen_copied'))),
    );
  }

  /// `QrErrorCorrectLevel` bir enum deyil — `qr_flutter` paketində sadəcə
  /// statik `int` sabitləri olan bir class-dır (L/M/Q/H hamısı `int`).
  /// Ona görə bu funksiya `int` qaytarmalıdır, `QrErrorCorrectLevel` yox.
  int _levelFromInt(int v) {
    switch (v) {
      case 0:
        return QrErrorCorrectLevel.L;
      case 1:
        return QrErrorCorrectLevel.M;
      case 2:
        return QrErrorCorrectLevel.Q;
      case 3:
      default:
        return QrErrorCorrectLevel.H;
    }
  }

  /// Şüşə effektli (frosted glass) kart — iOS-vari blur fon üzərində
  /// yarımşəffaf konteyner və incə sərhəd.
  Widget _glassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    final Brightness brightness = Theme.of(context).brightness;
    final bool isDark = brightness == Brightness.dark;
    final Color tint = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.white.withOpacity(0.55);
    final Color borderColor = isDark
        ? Colors.white.withOpacity(0.15)
        : Colors.white.withOpacity(0.6);

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

  Widget _colorPicker({
    required String labelKey,
    required Color selected,
    required ValueChanged<Color> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.t(labelKey),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _colorOptions.map((Color c) {
            final bool isSelected = c.value == selected.value;
            return GestureDetector(
              onTap: () => onChanged(c),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white.withOpacity(0.6),
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(context.t('qrgen_title')),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top > 0 ? 8 : 16,
              16,
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _glassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              context.t('qrgen_input_hint'),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: _paste,
                            icon: const Icon(Icons.paste, size: 18),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: _clear,
                            icon: const Icon(Icons.clear, size: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _controller,
                        maxLines: 4,
                        minLines: 2,
                        onChanged: (_) => _update(),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(
                            isDark ? 0.06 : 0.5,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: _glassCard(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      child: _data.isEmpty
                          ? SizedBox(
                        width: _size.toDouble(),
                        height: _size.toDouble(),
                        child: Center(
                          child: Text(
                            context.t('qrgen_empty'),
                            style: TextStyle(color: colors.outline),
                          ),
                        ),
                      )
                          : QrImageView(
                        data: _data,
                        version: QrVersions.auto,
                        size: _size.toDouble(),
                        backgroundColor: _bgColor,
                        eyeStyle: QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: _fgColor,
                        ),
                        dataModuleStyle: QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: _fgColor,
                        ),
                        errorCorrectionLevel: _levelFromInt(_errorLevel),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _glassCard(
                  child: OutlinedButton.icon(
                    onPressed: _copyData,
                    icon: const Icon(Icons.copy),
                    label: Text(context.t('qrgen_copy_data')),
                  ),
                ),
                const SizedBox(height: 16),
                _glassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        '${context.t('qrgen_size')}: ${_size}px',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Slider(
                        value: _size.toDouble(),
                        min: 120,
                        max: 400,
                        divisions: 28,
                        label: '$_size',
                        onChanged: (double v) {
                          setState(() {
                            _size = v.round();
                          });
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.t('qrgen_error_level'),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List<Widget>.generate(
                          _errorLevels.length,
                              (int i) {
                            return ChoiceChip(
                              label: Text(context.t(_errorKeys[i])),
                              selected: _errorLevel == i,
                              backgroundColor: Colors.white.withOpacity(
                                isDark ? 0.06 : 0.4,
                              ),
                              onSelected: (_) {
                                setState(() {
                                  _errorLevel = i;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _glassCard(
                  child: _colorPicker(
                    labelKey: 'qrgen_foreground',
                    selected: _fgColor,
                    onChanged: (Color c) {
                      setState(() {
                        _fgColor = c;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _glassCard(
                  child: _colorPicker(
                    labelKey: 'qrgen_background',
                    selected: _bgColor,
                    onChanged: (Color c) {
                      setState(() {
                        _bgColor = c;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}