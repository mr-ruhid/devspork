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

  List<String> _splitLines(String text) {
    if (text.isEmpty) return <String>[];
    return text.replaceAll('\r\n', '\n').split('\n');
  }

  void _compare() {
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
          dp[i][j] = dp[i + 1][j] > dp[i][j + 1]
              ? dp[i + 1][j]
              : dp[i][j + 1];
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
    final String tmp = _leftController.text;
    _leftController.text = _rightController.text;
    _rightController.text = tmp;
    if (_compared) _compare();
  }

  Future<void> _pasteTo(TextEditingController c) async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null) return;
    c.text = data.text!;
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('diffcheck_copied'))),
    );
  }

  Color _lineBg(_DiffType type, ColorScheme colors) {
    switch (type) {
      case _DiffType.added:
        return Colors.green.withValues(alpha: 0.15);
      case _DiffType.removed:
        return colors.error.withValues(alpha: 0.15);
      case _DiffType.unchanged:
        return Colors.transparent;
    }
  }

  Color _lineFg(_DiffType type, ColorScheme colors) {
    switch (type) {
      case _DiffType.added:
        return Colors.green.shade800;
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

  Widget _inputBox({
    required TextEditingController controller,
    required String labelKey,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                context.t(labelKey),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => _pasteTo(controller),
              icon: const Icon(Icons.paste, size: 18),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () {
                controller.clear();
              },
              icon: const Icon(Icons.clear, size: 18),
            ),
          ],
        ),
        TextField(
          controller: controller,
          maxLines: 6,
          minLines: 4,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('diffcheck_title')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _inputBox(
              controller: _leftController,
              labelKey: 'diffcheck_left',
            ),
            const SizedBox(height: 8),
            _inputBox(
              controller: _rightController,
              labelKey: 'diffcheck_right',
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton(
                    onPressed: _compare,
                    child: Text(context.t('diffcheck_compare')),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _swap,
                  icon: const Icon(Icons.swap_horiz),
                  tooltip: context.t('diffcheck_swap'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _clear,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: context.t('diffcheck_clear'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _copyResult,
                  icon: const Icon(Icons.copy),
                  tooltip: context.t('diffcheck_copy'),
                ),
              ],
            ),
            if (_compared)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 12,
                  children: <Widget>[
                    Text(
                      '${context.t('diffcheck_added')}: $_addedCount',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${context.t('diffcheck_removed')}: $_removedCount',
                      style: TextStyle(
                        color: colors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: colors.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _lines.isEmpty
                    ? Center(
                  child: Text(
                    context.t('diffcheck_empty'),
                    style: TextStyle(color: colors.outline),
                  ),
                )
                    : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _lines.length,
                  itemBuilder: (BuildContext context, int index) {
                    final _DiffLine line = _lines[index];
                    return Container(
                      color: _lineBg(line.type, colors),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(
                            width: 36,
                            child: Text(
                              line.leftNum?.toString() ?? '',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: colors.outline,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 36,
                            child: Text(
                              line.rightNum?.toString() ?? '',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: colors.outline,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 16,
                            child: Text(
                              _sign(line.type),
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _lineFg(line.type, colors),
                              ),
                            ),
                          ),
                          Expanded(
                            child: SelectableText(
                              line.text.isEmpty ? ' ' : line.text,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                color: _lineFg(line.type, colors),
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