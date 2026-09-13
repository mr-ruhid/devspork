import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class PassGen extends StatefulWidget {
  const PassGen({super.key});

  @override
  State<PassGen> createState() => _PassGenState();
}

class _PassGenState extends State<PassGen> {
  final TextEditingController _outputController = TextEditingController();
  final Random _random = Random.secure();

  double _length = 16;
  bool _upper = true;
  bool _lower = true;
  bool _digits = true;
  bool _symbols = false;
  bool _excludeSimilar = false;

  static const String _upperChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _lowerChars = 'abcdefghijklmnopqrstuvwxyz';
  static const String _digitChars = '0123456789';
  static const String _symbolChars = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
  static const String _similarChars = 'Il1O0o';

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

  String _buildAlphabet() {
    String chars = '';
    if (_upper) chars += _upperChars;
    if (_lower) chars += _lowerChars;
    if (_digits) chars += _digitChars;
    if (_symbols) chars += _symbolChars;
    if (_excludeSimilar) {
      chars = chars
          .split('')
          .where((String c) => !_similarChars.contains(c))
          .join();
    }
    return chars;
  }

  void _generate() {
    final String alphabet = _buildAlphabet();
    if (alphabet.isEmpty) {
      setState(() {
        _outputController.text = '';
      });
      return;
    }
    final int len = _length.round();
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < len; i++) {
      buffer.write(alphabet[_random.nextInt(alphabet.length)]);
    }
    setState(() {
      _outputController.text = buffer.toString();
    });
  }

  Future<void> _copy() async {
    if (_outputController.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _outputController.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('passgen_copied'))),
    );
  }

  Widget _switchTile(String key, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(context.t(key)),
      value: value,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool noAlphabet = _buildAlphabet().isEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('passgen_title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _outputController,
              readOnly: true,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 18),
              decoration: InputDecoration(
                labelText: context.t('passgen_output_hint'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copy,
                    icon: const Icon(Icons.copy),
                    label: Text(context.t('passgen_copy')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: noAlphabet ? null : _generate,
                    icon: const Icon(Icons.refresh),
                    label: Text(context.t('passgen_generate')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Text(
                  '${context.t('passgen_length')}: ${_length.round()}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            Slider(
              value: _length,
              min: 4,
              max: 64,
              divisions: 60,
              label: _length.round().toString(),
              onChanged: (double v) {
                setState(() {
                  _length = v;
                });
              },
              onChangeEnd: (_) => _generate(),
            ),
            const SizedBox(height: 8),
            _switchTile('passgen_upper', _upper, (bool v) {
              setState(() => _upper = v);
              _generate();
            }),
            _switchTile('passgen_lower', _lower, (bool v) {
              setState(() => _lower = v);
              _generate();
            }),
            _switchTile('passgen_digits', _digits, (bool v) {
              setState(() => _digits = v);
              _generate();
            }),
            _switchTile('passgen_symbols', _symbols, (bool v) {
              setState(() => _symbols = v);
              _generate();
            }),
            _switchTile('passgen_exclude_similar', _excludeSimilar, (bool v) {
              setState(() => _excludeSimilar = v);
              _generate();
            }),
            if (noAlphabet)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  context.t('passgen_error_no_charset'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}