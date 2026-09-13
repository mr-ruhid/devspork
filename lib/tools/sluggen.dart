
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class SlugGen extends StatefulWidget {
  const SlugGen({super.key});

  @override
  State<SlugGen> createState() => _SlugGenState();
}

class _SlugGenState extends State<SlugGen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();

  bool _lowercase = true;
  bool _removeStopWords = false;
  String _separator = '-';

  static const Map<String, String> _azMap = <String, String>{
    'ə': 'e',
    'ı': 'i',
    'ö': 'o',
    'ü': 'u',
    'ç': 'c',
    'ş': 's',
    'ğ': 'g',
    'İ': 'i',
    'Ə': 'e',
    'I': 'i',
    'Ö': 'o',
    'Ü': 'u',
    'Ç': 'c',
    'Ş': 's',
    'Ğ': 'g',
  };

  static const Set<String> _stopWords = <String>{
    've', 'ile', 'bir', 'bu', 'o', 'ki', 'da', 'de', 'the', 'a', 'an',
    'and', 'or', 'of', 'to', 'in', 'on', 'for', 'is', 'are',
  };

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_generate);
  }

  @override
  void dispose() {
    _inputController.removeListener(_generate);
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  String _transliterate(String text) {
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final String ch = text[i];
      buffer.write(_azMap[ch] ?? ch);
    }
    return buffer.toString();
  }

  String _buildSlug(String input) {
    String s = _transliterate(input);
    if (_lowercase) s = s.toLowerCase();
    s = s.replaceAll(RegExp(r'[^\w\s-]'), '');
    s = s.replaceAll(RegExp(r'[\s_-]+'), ' ');
    s = s.trim();
    if (s.isEmpty) return '';
    List<String> words = s.split(RegExp(r'\s+'));
    if (_removeStopWords) {
      final List<String> filtered = words
          .where((String w) => !_stopWords.contains(w.toLowerCase()))
          .toList();
      if (filtered.isNotEmpty) words = filtered;
    }
    return words.join(_separator);
  }

  void _generate() {
    setState(() {
      _outputController.text = _buildSlug(_inputController.text);
    });
  }

  void _clear() {
    _inputController.clear();
  }

  Future<void> _copy() async {
    if (_outputController.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _outputController.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('sluggen_copied'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('sluggen_title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _inputController,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                labelText: context.t('sluggen_input_hint'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _outputController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: context.t('sluggen_output_hint'),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: _copy,
                  icon: const Icon(Icons.copy),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.t('sluggen_separator'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: <ButtonSegment<String>>[
                ButtonSegment<String>(
                  value: '-',
                  label: Text(context.t('sluggen_sep_dash')),
                ),
                ButtonSegment<String>(
                  value: '_',
                  label: Text(context.t('sluggen_sep_underscore')),
                ),
              ],
              selected: <String>{_separator},
              onSelectionChanged: (Set<String> s) {
                setState(() {
                  _separator = s.first;
                });
                _generate();
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.t('sluggen_lowercase')),
              value: _lowercase,
              onChanged: (bool v) {
                setState(() {
                  _lowercase = v;
                });
                _generate();
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.t('sluggen_remove_stopwords')),
              value: _removeStopWords,
              onChanged: (bool v) {
                setState(() {
                  _removeStopWords = v;
                });
                _generate();
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _clear,
              icon: const Icon(Icons.clear),
              label: Text(context.t('sluggen_clear')),
            ),
          ],
        ),
      ),
    );
  }
}