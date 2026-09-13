import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class HashGen extends StatefulWidget {
  const HashGen({super.key});

  @override
  State<HashGen> createState() => _HashGenState();
}

class _HashGenState extends State<HashGen> {
  final TextEditingController _inputController = TextEditingController();

  final Map<String, String> _results = <String, String>{
    'md5': '',
    'sha1': '',
    'sha256': '',
    'sha512': '',
  };

  bool _uppercase = false;

  static const List<String> _algos = <String>[
    'md5',
    'sha1',
    'sha256',
    'sha512',
  ];

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_compute);
  }

  @override
  void dispose() {
    _inputController.removeListener(_compute);
    _inputController.dispose();
    super.dispose();
  }

  String _applyCase(String s) {
    return _uppercase ? s.toUpperCase() : s.toLowerCase();
  }

  void _compute() {
    final List<int> bytes = utf8.encode(_inputController.text);
    setState(() {
      _results['md5'] = _applyCase(md5.convert(bytes).toString());
      _results['sha1'] = _applyCase(sha1.convert(bytes).toString());
      _results['sha256'] = _applyCase(sha256.convert(bytes).toString());
      _results['sha512'] = _applyCase(sha512.convert(bytes).toString());
    });
  }

  void _clear() {
    _inputController.clear();
  }

  Future<void> _paste() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null) return;
    _inputController.text = data.text!;
  }

  Future<void> _copy(String text) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('hashgen_copied'))),
    );
  }

  Widget _resultCard(String algo) {
    final String value = _results[algo] ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  context.t('hashgen_$algo'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => _copy(value),
                icon: const Icon(Icons.copy, size: 18),
              ),
            ],
          ),
          SelectableText(
            value.isEmpty ? '-' : value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasInput = _inputController.text.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('hashgen_title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    context.t('hashgen_input_hint'),
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
              controller: _inputController,
              maxLines: 5,
              minLines: 3,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.t('hashgen_uppercase')),
              value: _uppercase,
              onChanged: (bool v) {
                setState(() {
                  _uppercase = v;
                });
                _compute();
              },
            ),
            const SizedBox(height: 8),
            for (final String algo in _algos) _resultCard(algo),
            if (!hasInput)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  context.t('hashgen_empty'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}