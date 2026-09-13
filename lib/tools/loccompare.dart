import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class LocCompare extends StatefulWidget {
  const LocCompare({super.key});

  @override
  State<LocCompare> createState() => _LocCompareState();
}

class _LocCompareState extends State<LocCompare> {
  final TextEditingController _leftController = TextEditingController();
  final TextEditingController _rightController = TextEditingController();
  final TextEditingController _leftNameController = TextEditingController();
  final TextEditingController _rightNameController = TextEditingController();

  bool _useNested = true;
  bool _compareValues = false;
  bool _compared = false;

  String? _errorKey;
  String? _errorDetail;

  List<String> _onlyInLeft = <String>[];
  List<String> _onlyInRight = <String>[];
  List<String> _common = <String>[];
  List<_ValueMismatch> _mismatches = <_ValueMismatch>[];

  @override
  void initState() {
    super.initState();
    _leftNameController.text = 'az.json';
    _rightNameController.text = 'en.json';
    _leftController.text = '''{
  "app_title": "DevSpork",
  "loading_text": "Yüklənir...",
  "save": "Yadda saxla",
  "cancel": "Ləğv et",
  "welcome": "Xoş gəldiniz"
}''';
    _rightController.text = '''{
  "app_title": "DevSpork",
  "loading_text": "Loading...",
  "save": "Save",
  "welcome": "Welcome",
  "logout": "Logout"
}''';
  }

  @override
  void dispose() {
    _leftController.dispose();
    _rightController.dispose();
    _leftNameController.dispose();
    _rightNameController.dispose();
    super.dispose();
  }

  Map<String, String> _flatten(dynamic data, [String prefix = '']) {
    final Map<String, String> result = <String, String>{};
    if (data is Map) {
      data.forEach((dynamic k, dynamic v) {
        final String key = prefix.isEmpty ? k.toString() : '$prefix.$k';
        if (_useNested && (v is Map)) {
          result.addAll(_flatten(v, key));
        } else if (_useNested && (v is List)) {
          for (int i = 0; i < v.length; i++) {
            final dynamic item = v[i];
            final String kk = '$key[$i]';
            if (item is Map || item is List) {
              result.addAll(_flatten(item, kk));
            } else {
              result[kk] = item.toString();
            }
          }
        } else {
          result[key] = v?.toString() ?? '';
        }
      });
    }
    return result;
  }

  void _compare() {
    final String leftRaw = _leftController.text.trim();
    final String rightRaw = _rightController.text.trim();

    if (leftRaw.isEmpty || rightRaw.isEmpty) {
      setState(() {
        _errorKey = 'loccompare_error_empty';
        _errorDetail = null;
        _compared = false;
        _onlyInLeft = <String>[];
        _onlyInRight = <String>[];
        _common = <String>[];
        _mismatches = <_ValueMismatch>[];
      });
      return;
    }

    try {
      final dynamic leftData = json.decode(leftRaw);
      final dynamic rightData = json.decode(rightRaw);

      if (leftData is! Map || rightData is! Map) {
        setState(() {
          _errorKey = 'loccompare_error_not_object';
          _errorDetail = null;
          _compared = false;
        });
        return;
      }

      final Map<String, String> left = _flatten(leftData);
      final Map<String, String> right = _flatten(rightData);

      final List<String> onlyLeft = <String>[];
      final List<String> onlyRight = <String>[];
      final List<String> common = <String>[];
      final List<_ValueMismatch> mismatches = <_ValueMismatch>[];

      for (final String k in left.keys) {
        if (right.containsKey(k)) {
          common.add(k);
          if (_compareValues && left[k] != right[k]) {
            mismatches.add(_ValueMismatch(k, left[k] ?? '', right[k] ?? ''));
          }
        } else {
          onlyLeft.add(k);
        }
      }
      for (final String k in right.keys) {
        if (!left.containsKey(k)) {
          onlyRight.add(k);
        }
      }

      onlyLeft.sort();
      onlyRight.sort();
      common.sort();
      mismatches.sort((_ValueMismatch a, _ValueMismatch b) =>
          a.key.compareTo(b.key));

      setState(() {
        _onlyInLeft = onlyLeft;
        _onlyInRight = onlyRight;
        _common = common;
        _mismatches = mismatches;
        _compared = true;
        _errorKey = null;
        _errorDetail = null;
      });
    } catch (e) {
      setState(() {
        _errorKey = 'loccompare_error_invalid';
        _errorDetail = e.toString();
        _compared = false;
        _onlyInLeft = <String>[];
        _onlyInRight = <String>[];
        _common = <String>[];
        _mismatches = <_ValueMismatch>[];
      });
    }
  }

  void _clear() {
    setState(() {
      _leftController.clear();
      _rightController.clear();
      _onlyInLeft = <String>[];
      _onlyInRight = <String>[];
      _common = <String>[];
      _mismatches = <_ValueMismatch>[];
      _compared = false;
      _errorKey = null;
      _errorDetail = null;
    });
  }

  Future<void> _pasteTo(TextEditingController c) async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null) return;
    c.text = data.text!;
  }

  Future<void> _copy(String text) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('loccompare_copied'))),
    );
  }

  void _copyAllResults() {
    final StringBuffer buffer = StringBuffer();
    final String leftName = _leftNameController.text.isEmpty
        ? 'left'
        : _leftNameController.text;
    final String rightName = _rightNameController.text.isEmpty
        ? 'right'
        : _rightNameController.text;

    buffer.writeln('=== Only in $leftName (${_onlyInLeft.length}) ===');
    for (final String k in _onlyInLeft) {
      buffer.writeln(k);
    }
    buffer.writeln();
    buffer.writeln('=== Only in $rightName (${_onlyInRight.length}) ===');
    for (final String k in _onlyInRight) {
      buffer.writeln(k);
    }
    buffer.writeln();
    buffer.writeln('=== Common keys: ${_common.length} ===');
    if (_compareValues) {
      buffer.writeln();
      buffer.writeln('=== Value mismatches (${_mismatches.length}) ===');
      for (final _ValueMismatch m in _mismatches) {
        buffer.writeln('${m.key}');
        buffer.writeln('  $leftName: ${m.leftValue}');
        buffer.writeln('  $rightName: ${m.rightValue}');
      }
    }
    _copy(buffer.toString());
  }

  Widget _inputBox({
    required TextEditingController nameController,
    required TextEditingController controller,
    required String defaultName,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              flex: 2,
              child: TextField(
                controller: nameController,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
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
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: 8,
          minLines: 6,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _resultCard({
    required String title,
    required int count,
    required List<Widget> children,
    required Color accent,
  }) {
    if (count == 0) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _keyRow(String key, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: SelectableText(
              key,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => _copy(key),
            icon: const Icon(Icons.copy, size: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String leftName = _leftNameController.text.isEmpty
        ? 'Left'
        : _leftNameController.text;
    final String rightName = _rightNameController.text.isEmpty
        ? 'Right'
        : _rightNameController.text;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('loccompare_title')),
        actions: <Widget>[
          IconButton(
            onPressed: _clear,
            icon: const Icon(Icons.delete_outline),
            tooltip: context.t('loccompare_clear'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _inputBox(
              nameController: _leftNameController,
              controller: _leftController,
              defaultName: 'az.json',
            ),
            const SizedBox(height: 12),
            _inputBox(
              nameController: _rightNameController,
              controller: _rightController,
              defaultName: 'en.json',
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(context.t('loccompare_nested')),
              value: _useNested,
              onChanged: (bool v) {
                setState(() {
                  _useNested = v;
                });
                if (_compared) _compare();
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(context.t('loccompare_values')),
              value: _compareValues,
              onChanged: (bool v) {
                setState(() {
                  _compareValues = v;
                });
                if (_compared) _compare();
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _compare,
                    icon: const Icon(Icons.compare_arrows),
                    label: Text(context.t('loccompare_compare')),
                  ),
                ),
                if (_compared) ...<Widget>[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _copyAllResults,
                    icon: const Icon(Icons.copy_all),
                    tooltip: context.t('loccompare_copy_all'),
                  ),
                ],
              ],
            ),
            if (_errorKey != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      context.t(_errorKey!),
                      style: TextStyle(color: colors.error),
                    ),
                    if (_errorDetail != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _errorDetail!,
                          style: TextStyle(
                            color: colors.error,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            if (_compared) ...<Widget>[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: _stat(
                        leftName,
                        _onlyInLeft.length,
                        colors.error,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: colors.outlineVariant,
                    ),
                    Expanded(
                      child: _stat(
                        'Common',
                        _common.length,
                        Colors.green,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: colors.outlineVariant,
                    ),
                    Expanded(
                      child: _stat(
                        rightName,
                        _onlyInRight.length,
                        colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_compareValues)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${context.t('loccompare_mismatches')}: ${_mismatches.length}',
                    style: TextStyle(
                      color: colors.outline,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _resultCard(
                title: '${context.t('loccompare_only_in')} $leftName',
                count: _onlyInLeft.length,
                accent: colors.error,
                children: _onlyInLeft
                    .map((String k) => _keyRow(k, colors))
                    .toList(),
              ),
              _resultCard(
                title: '${context.t('loccompare_only_in')} $rightName',
                count: _onlyInRight.length,
                accent: colors.primary,
                children: _onlyInRight
                    .map((String k) => _keyRow(k, colors))
                    .toList(),
              ),
              if (_compareValues && _mismatches.isNotEmpty)
                _resultCard(
                  title: context.t('loccompare_value_mismatches'),
                  count: _mismatches.length,
                  accent: Colors.orange,
                  children: _mismatches.map((_ValueMismatch m) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: SelectableText(
                                  m.key,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _copy(m.key),
                                icon: const Icon(Icons.copy, size: 14),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8, top: 2),
                            child: Text(
                              '$leftName: ${m.leftValue}',
                              style: TextStyle(
                                color: colors.error,
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8, top: 2),
                            child: Text(
                              '$rightName: ${m.rightValue}',
                              style: TextStyle(
                                color: colors.primary,
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          Divider(
                            height: 12,
                            color: colors.outlineVariant,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              if (_onlyInLeft.isEmpty &&
                  _onlyInRight.isEmpty &&
                  (!_compareValues || _mismatches.isEmpty))
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Card(
                    color: Colors.green.withValues(alpha: 0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              context.t('loccompare_all_match'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, int count, Color color) {
    return Column(
      children: <Widget>[
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ValueMismatch {
  final String key;
  final String leftValue;
  final String rightValue;

  _ValueMismatch(this.key, this.leftValue, this.rightValue);
}