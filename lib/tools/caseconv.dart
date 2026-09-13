import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class CaseConv extends StatefulWidget {
  const CaseConv({super.key});

  @override
  State<CaseConv> createState() => _CaseConvState();
}

class _CaseConvState extends State<CaseConv> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  String _mode = 'upper';

  static const List<String> _modes = <String>[
    'upper',
    'lower',
    'title',
    'sentence',
    'camel',
    'pascal',
    'snake',
    'kebab',
    'constant',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  List<String> _splitWords(String text) {
    final String normalized = text
        .replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'),
          (Match m) => '${m[1]} ${m[2]}',
    )
        .replaceAll(RegExp(r'[_\-\s]+'), ' ')
        .trim();
    if (normalized.isEmpty) return <String>[];
    return normalized.split(RegExp(r'\s+'));
  }

  String _applyMode(String text, String mode) {
    if (text.isEmpty) return '';
    switch (mode) {
      case 'upper':
        return text.toUpperCase();
      case 'lower':
        return text.toLowerCase();
      case 'title':
        return _splitWords(text)
            .map((String w) => w.isEmpty
            ? w
            : w[0].toUpperCase() + w.substring(1).toLowerCase())
            .join(' ');
      case 'sentence':
        final String lower = text.toLowerCase();
        return lower.isEmpty
            ? lower
            : lower[0].toUpperCase() + lower.substring(1);
      case 'camel':
        final List<String> words = _splitWords(text)
            .map((String w) => w.toLowerCase())
            .toList();
        if (words.isEmpty) return '';
        return words.first +
            words
                .skip(1)
                .map((String w) => w.isEmpty
                ? w
                : w[0].toUpperCase() + w.substring(1))
                .join();
      case 'pascal':
        return _splitWords(text)
            .map((String w) => w.isEmpty
            ? w
            : w[0].toUpperCase() + w.substring(1).toLowerCase())
            .join();
      case 'snake':
        return _splitWords(text)
            .map((String w) => w.toLowerCase())
            .join('_');
      case 'kebab':
        return _splitWords(text)
            .map((String w) => w.toLowerCase())
            .join('-');
      case 'constant':
        return _splitWords(text)
            .map((String w) => w.toUpperCase())
            .join('_');
      default:
        return text;
    }
  }

  void _convert() {
    setState(() {
      _outputController.text = _applyMode(_inputController.text, _mode);
    });
  }

  void _selectMode(String mode) {
    setState(() {
      _mode = mode;
      _outputController.text = _applyMode(_inputController.text, _mode);
    });
  }

  void _clear() {
    setState(() {
      _inputController.clear();
      _outputController.clear();
    });
  }

  Future<void> _copy() async {
    if (_outputController.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _outputController.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('caseconv_copied'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('caseconv_title')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _inputController,
                expands: true,
                maxLines: null,
                minLines: null,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  labelText: context.t('caseconv_input_hint'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _modes.map((String m) {
                final bool selected = _mode == m;
                return ChoiceChip(
                  label: Text(context.t('caseconv_mode_$m')),
                  selected: selected,
                  onSelected: (_) => _selectMode(m),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton(
                    onPressed: _convert,
                    child: Text(context.t('caseconv_convert')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _outputController,
                readOnly: true,
                expands: true,
                maxLines: null,
                minLines: null,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  labelText: context.t('caseconv_output_hint'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copy,
                    icon: const Icon(Icons.copy),
                    label: Text(context.t('caseconv_copy')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clear,
                    icon: const Icon(Icons.clear),
                    label: Text(context.t('caseconv_clear')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}