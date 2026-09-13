import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class AsciiArt extends StatefulWidget {
  const AsciiArt({super.key});

  @override
  State<AsciiArt> createState() => _AsciiArtState();
}

class _AsciiArtState extends State<AsciiArt> {
  final TextEditingController _inputController = TextEditingController();

  String _output = '';
  bool _isGenerating = false;

  String _char = '█';
  double _resolution = 60;
  bool _bold = true;

  Timer? _debounce;

  static const List<String> _chars = <String>[
    '█', '▓', '▒', '░', '#', '*', '@', 'O', 'X', '.',
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
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _generate);
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
      char: _char,
      bold: _bold,
    );

    if (!mounted) return;
    setState(() {
      _output = result;
      _isGenerating = false;
    });
  }

  Future<String> _rasterizeToAscii(
      String text, {
        required int cols,
        required String char,
        required bool bold,
      }) async {
    const double fontSize = 140;

    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.w900 : FontWeight.w500,
          color: const Color(0xFFFFFFFF),
          letterSpacing: fontSize * 0.02,
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
    final int rows =
    (height / (cellW * glyphAspect)).round().clamp(1, 400);
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
        final double avg = count > 0 ? sum / count / 255.0 : 0.0;
        buffer.write(avg > 0.35 ? char : ' ');
      }
      if (r != rows - 1) buffer.writeln();
    }
    return buffer.toString();
  }

  void _clear() {
    _inputController.clear();
    setState(() => _output = '');
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
      SnackBar(content: Text(context.t('asciiart_copied'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.t('asciiart_title')),
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
                              _GlassIconButton(
                                icon: Icons.paste,
                                onTap: _paste,
                              ),
                              const SizedBox(width: 8),
                              _GlassIconButton(
                                icon: Icons.clear,
                                onTap: _clear,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _inputController,
                            onChanged: (_) => _onChanged(),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.06),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.15),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.15),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFF7C4DFF),
                                  width: 1.5,
                                ),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
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
                            context.t('asciiart_char'),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _chars.map((String c) {
                              final bool selected = _char == c;
                              return GestureDetector(
                                onTap: () {
                                  setState(() => _char = c);
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
                                        ? const Color(0xFF7C4DFF)
                                        .withOpacity(0.85)
                                        : Colors.white.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: selected
                                          ? const Color(0xFF7C4DFF)
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
                          const SizedBox(height: 16),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  context.t('asciiart_resolution'),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                _resolution.round().toString(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(0xFF7C4DFF),
                              inactiveTrackColor:
                              Colors.white.withOpacity(0.15),
                              thumbColor: const Color(0xFF00E5FF),
                              overlayColor:
                              const Color(0xFF7C4DFF).withOpacity(0.2),
                            ),
                            child: Slider(
                              value: _resolution,
                              min: 20,
                              max: 120,
                              divisions: 20,
                              onChanged: (double v) {
                                setState(() => _resolution = v);
                              },
                              onChangeEnd: (_) => _generate(),
                            ),
                          ),
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
                              Switch(
                                value: _bold,
                                activeColor: const Color(0xFF7C4DFF),
                                onChanged: (bool v) {
                                  setState(() => _bold = v);
                                  _generate();
                                },
                              ),
                            ],
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
                              _GlassIconButton(
                                icon: Icons.copy,
                                onTap: _copy,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: _output.isEmpty
                                ? Text(
                              context.t('asciiart_empty'),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                              ),
                            )
                                : SingleChildScrollView(
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

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
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