import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class UuidGen extends StatefulWidget {
  const UuidGen({super.key});

  @override
  State<UuidGen> createState() => _UuidGenState();
}

class _UuidGenState extends State<UuidGen> {
  final TextEditingController _outputController = TextEditingController();
  final Random _random = Random.secure();

  double _count = 1;
  bool _uppercase = false;
  bool _hyphens = true;
  bool _braces = false;

  String _hex(int len) {
    const String chars = '0123456789abcdef';
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < len; i++) {
      buffer.write(chars[_random.nextInt(16)]);
    }
    return buffer.toString();
  }

  String _generateV4() {
    final String part1 = _hex(8);
    final String part2 = _hex(4);
    final String part3 = '4${_hex(3)}';
    final int variant = 8 + _random.nextInt(4);
    final String part4 = '${variant.toRadixString(16)}${_hex(3)}';
    final String part5 = _hex(12);

    String uuid = _hyphens
        ? '$part1-$part2-$part3-$part4-$part5'
        : '$part1$part2$part3$part4$part5';
    if (_uppercase) uuid = uuid.toUpperCase();
    if (_braces) uuid = '{$uuid}';
    return uuid;
  }

  void _generate() {
    final int n = _count.round();
    final List<String> list = <String>[];
    for (int i = 0; i < n; i++) {
      list.add(_generateV4());
    }
    setState(() {
      _outputController.text = list.join('\n');
    });
  }

  @override
  void initState() {
    super.initState();
    _generate();
  }

  @override
  void dispose() {
    _outputController.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    if (_outputController.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _outputController.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('uuidgen_copied'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('uuidgen_title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              '${context.t('uuidgen_count')}: ${_count.round()}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Slider(
              value: _count,
              min: 1,
              max: 100,
              divisions: 99,
              label: _count.round().toString(),
              onChanged: (double v) {
                setState(() {
                  _count = v;
                });
              },
              onChangeEnd: (_) => _generate(),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.t('uuidgen_uppercase')),
              value: _uppercase,
              onChanged: (bool v) {
                setState(() {
                  _uppercase = v;
                });
                _generate();
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.t('uuidgen_hyphens')),
              value: _hyphens,
              onChanged: (bool v) {
                setState(() {
                  _hyphens = v;
                });
                _generate();
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.t('uuidgen_braces')),
              value: _braces,
              onChanged: (bool v) {
                setState(() {
                  _braces = v;
                });
                _generate();
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _generate,
                    icon: const Icon(Icons.refresh),
                    label: Text(context.t('uuidgen_generate')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copy,
                    icon: const Icon(Icons.copy),
                    label: Text(context.t('uuidgen_copy')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _outputController,
              readOnly: true,
              maxLines: null,
              minLines: 6,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
              ),
              decoration: InputDecoration(
                labelText: context.t('uuidgen_output_hint'),
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}