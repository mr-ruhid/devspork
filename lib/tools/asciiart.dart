import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class AsciiArt extends StatefulWidget {
  const AsciiArt({super.key});

  @override
  State<AsciiArt> createState() => _AsciiArtState();
}

class _AsciiArtState extends State<AsciiArt> with SingleTickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _customCharController = TextEditingController();
  final ScrollController _outputHScroll = ScrollController();

  String _output = '';
  bool _isGenerating = false;
  bool _invert = false;
  bool _bold = true;
  bool _useCustomChar = false;

  String _char = '█';
  double _resolution = 60;
  double _letterSpacing = 0.02;

  Timer? _debounce;

  final List<String> _history = <String>[];

  static const List<String> _chars = <String>[
    '█', '▓', '▒', '░', '#', '*', '@', 'O', 'X', '.',
  ];

  static const List<String> _quickPresets = <String>[
    'DEVSPORK', 'HELLO', '2026', 'FLUTTER', 'AI',
  ];

  @override
  void initState() {
    super.initState();
    _inputController.text = 'DEVSPORK';
    _generate();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _inputController.dispose();
    _customCharController.dispose();
    _outputHScroll.dispose();
    super.dispose();
  }

  String get _activeChar =>
      _useCustomChar && _customCharController.text.trim().isNotEmpty
          ? _customCharController.text.trim().substring(0, 1)
          : _char;

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _generate);
  }

  void _pushHistory(String text) {
    if (text.trim().isEmpty) return;
    _history.remove(text);
    _history.insert(0, text);
    if (_history.length > 8) _history.removeLast();
  }

  Future<void> _generate() async {
    final String text = _inputController.text;
    if (text.trim().isEmpty) {
      setState(() => _output = '');
      return;
    }

    setState(() => _isGenerating = true);

    final String result = await _rasterizeToAscii(
      text,
      cols: _resolution.round(),
      char: _activeChar.isEmpty ? '█' : _activeChar,
      bold: _bold,
      letterSpacingFactor: _letterSpacing,
      invert: _invert,
    );

    if (!mounted) return;
    setState(() {
      _output = result;
      _isGenerating = false;
    });
    _pushHistory(text);
  }

  Future<String> _rasterizeToAscii(
      String text, {
        required int cols,
        required String char,
        required bool bold,
        required double letterSpacingFactor,
        required bool invert,
      }) async {
    const double fontSize = 140;

    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.w900 : FontWeight.w500,
          color: const Color(0xFFFFFFFF),
          letterSpacing: fontSize * letterSpacingFactor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final int width = painter.width.ceil();
    final int height = painter.height.ceil();
    if (width <= 0 || height <= 0) return '';

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );
    painter.paint(canvas, Offset.zero);
    final ui.Picture picture = recorder.endRecording();

    final ui.Image image = await picture.toImage(width, height);
    final ByteData? byteData =
    await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    if (byteData == null) return '';
    final Uint8List pixels = byteData.buffer.asUint8List();

    const double glyphAspect = 2.0;
    final double cellW = width / cols;
    final int rows = (height / (cellW * glyphAspect)).round().clamp(1, 400);
    final double cellH = height / rows;

    final StringBuffer buffer = StringBuffer();
    for (int r = 0; r < rows; r++) {
      final int y0 = (r * cellH).floor().clamp(0, height);
      final int y1 = ((r + 1) * cellH).ceil().clamp(0, height);
      for (int c = 0; c < cols; c++) {
        final int x0 = (c * cellW).floor().clamp(0, width);
        final int x1 = ((c + 1) * cellW).ceil().clamp(0, width);

        int sum = 0;
        int count = 0;
        for (int y = y0; y < y1; y++) {
          final int rowBase = y * width;
          for (int x = x0; x < x1; x++) {
            final int idx = (rowBase + x) * 4;
            sum += pixels[idx + 3];
            count++;
          }
        }
        double avg = count > 0 ? sum / count / 255.0 : 0.0;
        if (invert) avg = 1.0 - avg;
        buffer.write(avg > 0.35 ? char : ' ');
      }
      if (r != rows - 1) buffer.writeln();
    }
    return buffer.toString();
  }

  void _clear() {
    HapticFeedback.lightImpact();
    _inputController.clear();
    setState(() => _output = '');
  }

  Future<void> _paste() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null) return;
    HapticFeedback.selectionClick();
    _inputController.text = data.text!;
    _generate();
  }

  Future<void> _copy() async {
    if (_output.isEmpty) return;
    HapticFeedback.mediumImpact();
    await Clipboard.setData(ClipboardData(text: _output));
    if (!mounted) return;
    _showToast(context.t('asciiart_copied'));
  }

  void _reset() {
    HapticFeedback.lightImpact();
    setState(() {
      _char = '█';
      _resolution = 60;
      _bold = true;
      _invert = false;
      _useCustomChar = false;
      _letterSpacing = 0.02;
      _customCharController.clear();
    });
    _generate();
  }

  void _applyPreset(String text) {
    HapticFeedback.selectionClick();
    _inputController.text = text;
    _generate();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.t('asciiart_title'),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _GlassIconButton(icon: CupertinoIcons.refresh, onTap: _reset),
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
            Positioned(
              top: -80,
              left: -60,
              child: _blurBlob(220, const Color(0xFF7C4DFF)),
            ),
            Positioned(
              bottom: -100,
              right: -60,
              child: _blurBlob(260, const Color(0xFF00E5FF)),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // ---------- INPUT CARD ----------
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  context.t('asciiart_input_hint'),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              _GlassIconButton(icon: CupertinoIcons.doc_on_clipboard, onTap: _paste),
                              const SizedBox(width: 8),
                              _GlassIconButton(icon: CupertinoIcons.clear, onTap: _clear),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _GlassTextField(
                            controller: _inputController,
                            onChanged: (_) => _onChanged(),
                          ),
                          if (_quickPresets.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 32,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _quickPresets.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (BuildContext ctx, int i) {
                                  final String p = _quickPresets[i];
                                  return _Pill(
                                    label: p,
                                    onTap: () => _applyPreset(p),
                                  );
                                },
                              ),
                            ),
                          ],
                          if (_history.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 32,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _history.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (BuildContext ctx, int i) {
                                  final String h = _history[i];
                                  return _Pill(
                                    label: h,
                                    icon: CupertinoIcons.clock,
                                    onTap: () => _applyPreset(h),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ---------- STYLE CARD ----------
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  context.t('asciiart_char'),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              _MiniToggle(
                                label: context.t('asciiart_custom') ,
                                value: _useCustomChar,
                                onChanged: (bool v) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _useCustomChar = v);
                                  _generate();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_useCustomChar)
                            SizedBox(
                              width: 90,
                              child: _GlassTextField(
                                controller: _customCharController,
                                maxLength: 1,
                                centered: true,
                                onChanged: (_) => _onChanged(),
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _chars.map((String c) {
                                final bool selected = _char == c;
                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _char = c);
                                    _generate();
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    curve: Curves.easeOutCubic,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? const Color(0xFF7C4DFF).withOpacity(0.85)
                                          : Colors.white.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: selected
                                            ? const Color(0xFF7C4DFF)
                                            : Colors.white.withOpacity(0.15),
                                      ),
                                      boxShadow: selected
                                          ? <BoxShadow>[
                                        BoxShadow(
                                          color: const Color(0xFF7C4DFF).withOpacity(0.5),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                          : null,
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
                          const SizedBox(height: 18),
                          _SliderRow(
                            label: context.t('asciiart_resolution'),
                            value: _resolution,
                            display: _resolution.round().toString(),
                            min: 20,
                            max: 120,
                            divisions: 20,
                            onChanged: (double v) => setState(() => _resolution = v),
                            onChangeEnd: (_) => _generate(),
                          ),
                          _SliderRow(
                            label: context.t('asciiart_spacing'),
                            value: _letterSpacing,
                            display: '${(_letterSpacing * 100).round()}%',
                            min: 0.0,
                            max: 0.15,
                            divisions: 15,
                            onChanged: (double v) => setState(() => _letterSpacing = v),
                            onChangeEnd: (_) => _generate(),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  context.t('asciiart_bold'),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              _MiniToggle(
                                value: _bold,
                                onChanged: (bool v) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _bold = v);
                                  _generate();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  context.t('asciiart_invert'),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              _MiniToggle(
                                value: _invert,
                                onChanged: (bool v) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _invert = v);
                                  _generate();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ---------- OUTPUT CARD ----------
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
                                      context.t('asciiart_output_hint'),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (_isGenerating) ...<Widget>[
                                      const SizedBox(width: 10),
                                      const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF00E5FF),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (_output.isNotEmpty)
                                Text(
                                  '${_output.split('\n').length}×${_resolution.round()}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.35),
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              const SizedBox(width: 8),
                              _GlassIconButton(icon: CupertinoIcons.doc_on_doc, onTap: _copy),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(minHeight: 120),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: _output.isEmpty
                                ? Center(
                              child: Text(
                                context.t('asciiart_empty'),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                ),
                              ),
                            )
                                : Scrollbar(
                              controller: _outputHScroll,
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                controller: _outputHScroll,
                                scrollDirection: Axis.horizontal,
                                child: SelectableText(
                                  _output,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 8,
                                    height: 1.0,
                                    color: Colors.white,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_output.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 12),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: _GlassActionButton(
                                    label: context.t('asciiart_copy'),
                                    icon: CupertinoIcons.doc_on_doc,
                                    onTap: _copy,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _GlassActionButton(
                                    label: context.t('asciiart_clear'),
                                    icon: CupertinoIcons.trash,
                                    onTap: _clear,
                                    tint: const Color(0xFFFF5C7A),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.06),
                blurRadius: 1,
                offset: const Offset(0, 1),
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
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white.withOpacity(0.08),
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.15)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: Colors.white),
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
  final VoidCallback onTap;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: tint.withOpacity(0.18),
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tint.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(icon, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
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

class _GlassTextField extends StatelessWidget {
  const _GlassTextField({
    required this.controller,
    required this.onChanged,
    this.maxLength,
    this.centered = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final int? maxLength;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLength: maxLength,
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        counterText: '',
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
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
    );
  }
}

class _MiniToggle extends StatelessWidget {
  const _MiniToggle({required this.value, required this.onChanged, this.label});

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (label != null) ...<Widget>[
          Text(
            label!,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(width: 6),
        ],
        Transform.scale(
          scale: 0.85,
          child: CupertinoSwitch(
            value: value,
            activeColor: const Color(0xFF7C4DFF),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.display,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final String label;
  final double value;
  final String display;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
              ),
            ),
            Text(display, style: const TextStyle(color: Colors.white)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF7C4DFF),
            inactiveTrackColor: Colors.white.withOpacity(0.15),
            thumbColor: const Color(0xFF00E5FF),
            overlayColor: const Color(0xFF7C4DFF).withOpacity(0.2),
            trackHeight: 3,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.onTap, this.icon});

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon, size: 12, color: Colors.white60),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
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