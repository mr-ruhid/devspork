import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class BaseConv extends StatefulWidget {
  const BaseConv({super.key});

  @override
  State<BaseConv> createState() => _BaseConvState();
}

class _BaseConvState extends State<BaseConv> {
  final TextEditingController _binController = TextEditingController();
  final TextEditingController _octController = TextEditingController();
  final TextEditingController _decController = TextEditingController();
  final TextEditingController _hexController = TextEditingController();
  final TextEditingController _customController = TextEditingController();

  int _activeBase = 10;
  String? _errorKey;
  bool _customEnabled = false;
  int _customBase = 36;
  bool _groupDigits = true;
  BigInt? _currentValue;

  final List<_HistoryItem> _history = <_HistoryItem>[];

  static const List<_Preset> _presets = <_Preset>[
    _Preset('255', 'FF'),
    _Preset('65535', '16-bit'),
    _Preset('1024', '1 KB'),
    _Preset('4294967295', '32-bit'),
  ];

  @override
  void initState() {
    super.initState();
    _binController.addListener(() => _onChanged(_binController.text, 2));
    _octController.addListener(() => _onChanged(_octController.text, 8));
    _decController.addListener(() => _onChanged(_decController.text, 10));
    _hexController.addListener(() => _onChanged(_hexController.text, 16));
    _customController.addListener(() => _onChanged(_customController.text, -1));
  }

  @override
  void dispose() {
    _binController.dispose();
    _octController.dispose();
    _decController.dispose();
    _hexController.dispose();
    _customController.dispose();
    super.dispose();
  }

  void _onChanged(String value, int base) {
    final int effectiveBase = base == -1 ? _customBase : base;
    if (_activeBase != effectiveBase) return;

    final String input = value.trim();
    if (input.isEmpty) {
      setState(() {
        _errorKey = null;
        _currentValue = null;
        _clearExcept(effectiveBase);
      });
      return;
    }
    final BigInt? big = BigInt.tryParse(input, radix: effectiveBase);
    if (big == null) {
      setState(() => _errorKey = 'baseconv_error_invalid');
      return;
    }
    if (big.isNegative) {
      setState(() => _errorKey = 'baseconv_error_negative');
      return;
    }
    setState(() {
      _errorKey = null;
      _currentValue = big;
      _setFieldsFromBig(big, effectiveBase);
    });
  }

  void _setFieldsFromBig(BigInt value, int sourceBase) {
    _activeBase = 0;
    if (sourceBase != 2) _binController.text = value.toRadixString(2);
    if (sourceBase != 8) _octController.text = value.toRadixString(8);
    if (sourceBase != 10) _decController.text = value.toRadixString(10);
    if (sourceBase != 16) _hexController.text = value.toRadixString(16).toUpperCase();
    if (_customEnabled && sourceBase != _customBase) {
      _customController.text = value.toRadixString(_customBase).toUpperCase();
    }
    _activeBase = sourceBase;
  }

  void _clearExcept(int base) {
    _activeBase = 0;
    if (base != 2) _binController.clear();
    if (base != 8) _octController.clear();
    if (base != 10) _decController.clear();
    if (base != 16) _hexController.clear();
    if (_customEnabled && base != _customBase) _customController.clear();
    _activeBase = base;
  }

  void _pushHistory() {
    if (_currentValue == null) return;
    final String dec = _currentValue!.toRadixString(10);
    if (_history.isNotEmpty && _history.first.decimal == dec) return;
    _history.insert(0, _HistoryItem(decimal: dec, hex: _currentValue!.toRadixString(16).toUpperCase(), at: DateTime.now()));
    if (_history.length > 6) _history.removeLast();
  }

  void _applyPreset(String decValue) {
    HapticFeedback.selectionClick();
    _activeBase = 10;
    _decController.text = decValue;
  }

  void _applyHistory(_HistoryItem h) {
    HapticFeedback.selectionClick();
    _activeBase = 10;
    _decController.text = h.decimal;
    _pushHistory();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _activeBase = 0;
    _binController.clear();
    _octController.clear();
    _decController.clear();
    _hexController.clear();
    _customController.clear();
    _activeBase = 10;
    setState(() {
      _errorKey = null;
      _currentValue = null;
    });
  }

  Future<void> _copy(String text) async {
    if (text.isEmpty) return;
    HapticFeedback.mediumImpact();
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    _showToast(context.t('baseconv_copied'));
    _pushHistory();
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

  String _group(String raw, int chunk) {
    if (!_groupDigits || raw.isEmpty) return raw;
    final String reversed = raw.split('').reversed.join();
    final StringBuffer buf = StringBuffer();
    for (int i = 0; i < reversed.length; i++) {
      if (i != 0 && i % chunk == 0) buf.write(' ');
      buf.write(reversed[i]);
    }
    return buf.toString().split('').reversed.join();
  }

  @override
  Widget build(BuildContext context) {
    final int? bitLength = _currentValue?.bitLength;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.t('baseconv_title'),
          style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.4),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _GlassIconButton(icon: CupertinoIcons.refresh, onTap: _clearAll),
          ),
        ],
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
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // ---- INFO ----
                    if (_currentValue != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _GlassCard(
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: _InfoStat(label: context.t('baseconv_bits'), value: '$bitLength'),
                              ),
                              Expanded(
                                child: _InfoStat(
                                  label: context.t('baseconv_bytes'),
                                  value: '${((bitLength ?? 0) / 8).ceil()}',
                                ),
                              ),
                              Expanded(
                                child: _InfoStat(
                                  label: context.t('baseconv_group'),
                                  value: '',
                                  trailing: _MiniToggle(
                                    value: _groupDigits,
                                    onChanged: (bool v) {
                                      HapticFeedback.selectionClick();
                                      setState(() => _groupDigits = v);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ---- PRESETS ----
                    SizedBox(
                      height: 32,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _presets.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (BuildContext ctx, int i) {
                          final _Preset p = _presets[i];
                          return _Pill(label: '${p.label} (${p.decimal})', onTap: () => _applyPreset(p.decimal));
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ---- FIELDS ----
                    _BaseField(
                      labelKey: 'baseconv_binary',
                      controller: _binController,
                      keyboard: TextInputType.number,
                      base: 2,
                      onFocus: () => _activeBase = 2,
                      formatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'[01]'))],
                      onCopy: () => _copy(_binController.text),
                      grouped: _groupDigits ? _group(_binController.text, 4) : null,
                    ),
                    const SizedBox(height: 12),
                    _BaseField(
                      labelKey: 'baseconv_octal',
                      controller: _octController,
                      keyboard: TextInputType.number,
                      base: 8,
                      onFocus: () => _activeBase = 8,
                      formatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'[0-7]'))],
                      onCopy: () => _copy(_octController.text),
                    ),
                    const SizedBox(height: 12),
                    _BaseField(
                      labelKey: 'baseconv_decimal',
                      controller: _decController,
                      keyboard: TextInputType.number,
                      base: 10,
                      onFocus: () => _activeBase = 10,
                      formatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                      onCopy: () => _copy(_decController.text),
                    ),
                    const SizedBox(height: 12),
                    _BaseField(
                      labelKey: 'baseconv_hex',
                      controller: _hexController,
                      keyboard: TextInputType.text,
                      base: 16,
                      onFocus: () => _activeBase = 16,
                      formatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]'))],
                      onCopy: () => _copy(_hexController.text),
                      grouped: _groupDigits ? _group(_hexController.text, 2) : null,
                    ),

                    const SizedBox(height: 12),
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  context.t('baseconv_custom_base'),
                                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                                ),
                              ),
                              _MiniToggle(
                                value: _customEnabled,
                                onChanged: (bool v) {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _customEnabled = v;
                                    if (v && _currentValue != null) {
                                      _customController.text = _currentValue!.toRadixString(_customBase).toUpperCase();
                                    } else {
                                      _customController.clear();
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                          if (_customEnabled) ...<Widget>[
                            const SizedBox(height: 10),
                            Row(
                              children: <Widget>[
                                Text(
                                  '${context.t('baseconv_base')}: $_customBase',
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: const Color(0xFF7C4DFF),
                                inactiveTrackColor: Colors.white.withOpacity(0.15),
                                thumbColor: const Color(0xFF00E5FF),
                                trackHeight: 3,
                              ),
                              child: Slider(
                                value: _customBase.toDouble(),
                                min: 2,
                                max: 36,
                                divisions: 34,
                                onChanged: (double v) {
                                  setState(() => _customBase = v.round());
                                },
                                onChangeEnd: (double v) {
                                  HapticFeedback.selectionClick();
                                  if (_currentValue != null) {
                                    setState(() {
                                      _customController.text = _currentValue!.toRadixString(_customBase).toUpperCase();
                                    });
                                  }
                                },
                              ),
                            ),
                            TextField(
                              controller: _customController,
                              onTap: () => _activeBase = _customBase,
                              style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.black.withOpacity(0.25),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                suffixIcon: IconButton(
                                  icon: const Icon(CupertinoIcons.doc_on_doc, size: 16, color: Colors.white70),
                                  onPressed: () => _copy(_customController.text),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    if (_errorKey != null) ...<Widget>[
                      const SizedBox(height: 12),
                      _ErrorBanner(message: context.t(_errorKey!)),
                    ],

                    const SizedBox(height: 16),
                    _GlassActionButton(
                      label: context.t('baseconv_clear'),
                      icon: CupertinoIcons.trash,
                      onTap: _clearAll,
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

class _Preset {
  const _Preset(this.decimal, this.label);
  final String decimal;
  final String label;
}

class _HistoryItem {
  _HistoryItem({required this.decimal, required this.hex, required this.at});
  final String decimal;
  final String hex;
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

class _BaseField extends StatelessWidget {
  const _BaseField({
    required this.labelKey,
    required this.controller,
    required this.keyboard,
    required this.base,
    required this.onFocus,
    required this.formatters,
    required this.onCopy,
    this.grouped,
  });

  final String labelKey;
  final TextEditingController controller;
  final TextInputType keyboard;
  final int base;
  final VoidCallback onFocus;
  final List<TextInputFormatter> formatters;
  final VoidCallback onCopy;
  final String? grouped;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  context.t(labelKey),
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              _GlassIconButton(icon: CupertinoIcons.doc_on_doc, onTap: controller.text.isEmpty ? null : onCopy),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboard,
            inputFormatters: formatters,
            onTap: onFocus,
            style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 15),
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
          ),
          if (grouped != null && grouped!.isNotEmpty && grouped != controller.text) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              grouped!,
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontFamily: 'monospace', fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoStat extends StatelessWidget {
  const _InfoStat({required this.label, required this.value, this.trailing});
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
        const SizedBox(height: 4),
        trailing ?? Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
      ],
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.15)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 16, color: enabled ? Colors.white : Colors.white30),
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

class _MiniToggle extends StatelessWidget {
  const _MiniToggle({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.8,
      child: CupertinoSwitch(value: value, activeColor: const Color(0xFF7C4DFF), onChanged: onChanged),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: Colors.white.withOpacity(0.07),
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
      ),
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
                context.t('baseconv_history'),
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
                    const Icon(CupertinoIcons.number, size: 13, color: Color(0xFF7C4DFF)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'DEC ${h.decimal}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace'),
                      ),
                    ),
                    Text(
                      '0x${h.hex}',
                      style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11, fontFamily: 'monospace'),
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