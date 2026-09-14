import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class DiffCheck extends StatefulWidget {
  const DiffCheck({super.key});

  @override
  State<DiffCheck> createState() => _DiffCheckState();
}

class _DiffCheckState extends State<DiffCheck> {
  final TextEditingController _leftController = TextEditingController();
  final TextEditingController _rightController = TextEditingController();

  List<_DiffLine> _lines = <_DiffLine>[];
  int _addedCount = 0;
  int _removedCount = 0;
  bool _compared = false;

  @override
  void dispose() {
    _leftController.dispose();
    _rightController.dispose();
    super.dispose();
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  List<String> _splitLines(String text) {
    if (text.isEmpty) return <String>[];
    return text.replaceAll('\r\n', '\n').split('\n');
  }

  void _compare() {
    HapticFeedback.selectionClick();
    final List<String> a = _splitLines(_leftController.text);
    final List<String> b = _splitLines(_rightController.text);
    final List<_DiffLine> result = _computeDiff(a, b);
    int added = 0;
    int removed = 0;
    for (final _DiffLine line in result) {
      if (line.type == _DiffType.added) added++;
      if (line.type == _DiffType.removed) removed++;
    }
    setState(() {
      _lines = result;
      _addedCount = added;
      _removedCount = removed;
      _compared = true;
    });
  }

  List<_DiffLine> _computeDiff(List<String> a, List<String> b) {
    final int n = a.length;
    final int m = b.length;
    final List<List<int>> dp = List<List<int>>.generate(
      n + 1,
          (_) => List<int>.filled(m + 1, 0),
    );
    for (int i = n - 1; i >= 0; i--) {
      for (int j = m - 1; j >= 0; j--) {
        if (a[i] == b[j]) {
          dp[i][j] = dp[i + 1][j + 1] + 1;
        } else {
          dp[i][j] =
          dp[i + 1][j] > dp[i][j + 1] ? dp[i + 1][j] : dp[i][j + 1];
        }
      }
    }
    final List<_DiffLine> result = <_DiffLine>[];
    int i = 0;
    int j = 0;
    while (i < n && j < m) {
      if (a[i] == b[j]) {
        result.add(_DiffLine(
          type: _DiffType.unchanged,
          text: a[i],
          leftNum: i + 1,
          rightNum: j + 1,
        ));
        i++;
        j++;
      } else if (dp[i + 1][j] >= dp[i][j + 1]) {
        result.add(_DiffLine(
          type: _DiffType.removed,
          text: a[i],
          leftNum: i + 1,
          rightNum: null,
        ));
        i++;
      } else {
        result.add(_DiffLine(
          type: _DiffType.added,
          text: b[j],
          leftNum: null,
          rightNum: j + 1,
        ));
        j++;
      }
    }
    while (i < n) {
      result.add(_DiffLine(
        type: _DiffType.removed,
        text: a[i],
        leftNum: i + 1,
        rightNum: null,
      ));
      i++;
    }
    while (j < m) {
      result.add(_DiffLine(
        type: _DiffType.added,
        text: b[j],
        leftNum: null,
        rightNum: j + 1,
      ));
      j++;
    }
    return result;
  }

  void _clear() {
    HapticFeedback.selectionClick();
    setState(() {
      _leftController.clear();
      _rightController.clear();
      _lines = <_DiffLine>[];
      _addedCount = 0;
      _removedCount = 0;
      _compared = false;
    });
  }

  void _swap() {
    HapticFeedback.selectionClick();
    final String tmp = _leftController.text;
    _leftController.text = _rightController.text;
    _rightController.text = tmp;
    if (_compared) _compare();
  }

  Future<void> _pasteTo(TextEditingController c) async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null) return;
    HapticFeedback.selectionClick();
    setState(() => c.text = data.text!);
  }

  Future<void> _copyResult() async {
    if (_lines.isEmpty) return;
    final StringBuffer buffer = StringBuffer();
    for (final _DiffLine line in _lines) {
      final String sign = line.type == _DiffType.added
          ? '+ '
          : line.type == _DiffType.removed
          ? '- '
          : '  ';
      buffer.writeln('$sign${line.text}');
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withOpacity(0.75),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(context.t('diffcheck_copied')),
      ),
    );
  }

  Color _lineBg(_DiffType type, ColorScheme colors) {
    switch (type) {
      case _DiffType.added:
        return Colors.green.withOpacity(_isDark ? 0.18 : 0.14);
      case _DiffType.removed:
        return colors.error.withOpacity(_isDark ? 0.18 : 0.14);
      case _DiffType.unchanged:
        return Colors.transparent;
    }
  }

  Color _lineFg(_DiffType type, ColorScheme colors) {
    switch (type) {
      case _DiffType.added:
        return _isDark ? Colors.greenAccent.shade100 : Colors.green.shade800;
      case _DiffType.removed:
        return colors.error;
      case _DiffType.unchanged:
        return colors.onSurface;
    }
  }

  String _sign(_DiffType type) {
    switch (type) {
      case _DiffType.added:
        return '+';
      case _DiffType.removed:
        return '-';
      case _DiffType.unchanged:
        return ' ';
    }
  }

  // ---------- Glass helpers ----------

  Widget _glassCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    double radius = 22,
  }) {
    final bool isDark = _isDark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding ?? const EdgeInsets.all(14),
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
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required VoidCallback? onTap,
    String? tooltip,
  }) {
    final bool isDark = _isDark;
    final Widget btn = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.white.withOpacity(0.5),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 38,
              height: 38,
              child: Icon(
                icon,
                size: 18,
                color: onTap == null
                    ? (isDark ? Colors.white24 : Colors.black26)
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip, child: btn);
  }

  Widget _inputBox({
    required TextEditingController controller,
    required String labelKey,
  }) {
    final bool isDark = _isDark;
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  context.t(labelKey),
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              _glassIconButton(
                icon: Icons.content_paste_rounded,
                onTap: () => _pasteTo(controller),
                tooltip: context.t('diffcheck_paste'),
              ),
              const SizedBox(width: 6),
              _glassIconButton(
                icon: Icons.close_rounded,
                onTap: () => setState(controller.clear),
                tooltip: context.t('diffcheck_clear'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isDark
                      ? Colors.black.withOpacity(0.18)
                      : Colors.white.withOpacity(0.45),
                  border: Border.all(
                    color: Colors.white.withOpacity(isDark ? 0.1 : 0.5),
                  ),
                ),
                child: TextField(
                  controller: controller,
                  maxLines: 6,
                  minLines: 4,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                    isDense: true,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }

  Widget _blob(Color color, double size) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
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
          context.t('diffcheck_title'),
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
            left: -80,
            child: _blob(
              (isDark ? Colors.green : Colors.lightGreen).withOpacity(0.20),
              240,
            ),
          ),
          Positioned(
            bottom: -90,
            right: -60,
            child: _blob(colors.error.withOpacity(0.16), 220),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                MediaQuery.of(context).padding.top > 0 ? 8 : 96,
                12,
                12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _inputBox(
                            controller: _leftController,
                            labelKey: 'diffcheck_left',
                          ),
                          const SizedBox(height: 10),
                          _inputBox(
                            controller: _rightController,
                            labelKey: 'diffcheck_right',
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: SizedBox(
                                  height: 46,
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor:
                                      colors.primary.withOpacity(0.9),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: _compare,
                                    icon: const Icon(
                                        Icons.compare_arrows_rounded,
                                        size: 18),
                                    label: Text(context.t('diffcheck_compare')),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _glassIconButton(
                                icon: Icons.swap_horiz_rounded,
                                onTap: _swap,
                                tooltip: context.t('diffcheck_swap'),
                              ),
                              const SizedBox(width: 8),
                              _glassIconButton(
                                icon: Icons.delete_outline_rounded,
                                onTap: _clear,
                                tooltip: context.t('diffcheck_clear'),
                              ),
                              const SizedBox(width: 8),
                              _glassIconButton(
                                icon: Icons.copy_rounded,
                                onTap: _lines.isEmpty ? null : _copyResult,
                                tooltip: context.t('diffcheck_copy'),
                              ),
                            ],
                          ),
                          if (_compared)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Wrap(
                                spacing: 10,
                                children: <Widget>[
                                  _statBadge(
                                    context.t('diffcheck_added'),
                                    _addedCount,
                                    isDark
                                        ? Colors.greenAccent.shade100
                                        : Colors.green.shade700,
                                  ),
                                  _statBadge(
                                    context.t('diffcheck_removed'),
                                    _removedCount,
                                    colors.error,
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 10),
                          _glassCard(
                            padding: EdgeInsets.zero,
                            child: _lines.isEmpty
                                ? Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 40),
                              child: Center(
                                child: Text(
                                  context.t('diffcheck_empty'),
                                  style:
                                  TextStyle(color: colors.outline),
                                ),
                              ),
                            )
                                : ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics:
                                const NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,
                                itemCount: _lines.length,
                                itemBuilder:
                                    (BuildContext context, int index) {
                                  final _DiffLine line = _lines[index];
                                  return Container(
                                    color: _lineBg(line.type, colors),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: <Widget>[
                                        SizedBox(
                                          width: 32,
                                          child: Text(
                                            line.leftNum?.toString() ??
                                                '',
                                            style: TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 11,
                                              color: colors.outline,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 32,
                                          child: Text(
                                            line.rightNum?.toString() ??
                                                '',
                                            style: TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 11,
                                              color: colors.outline,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 14,
                                          child: Text(
                                            _sign(line.type),
                                            style: TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 13,
                                              fontWeight:
                                              FontWeight.bold,
                                              color: _lineFg(
                                                  line.type, colors),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: SelectableText(
                                            line.text.isEmpty
                                                ? ' '
                                                : line.text,
                                            style: TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 13,
                                              color: _lineFg(
                                                  line.type, colors),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

enum _DiffType { unchanged, added, removed }

class _DiffLine {
  final _DiffType type;
  final String text;
  final int? leftNum;
  final int? rightNum;

  _DiffLine({
    required this.type,
    required this.text,
    required this.leftNum,
    required this.rightNum,
  });
}