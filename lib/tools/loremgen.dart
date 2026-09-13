import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class LoremGen extends StatefulWidget {
  const LoremGen({super.key});

  @override
  State<LoremGen> createState() => _LoremGenState();
}

class _LoremGenState extends State<LoremGen> {
  final TextEditingController _outputController = TextEditingController();
  final Random _random = Random();

  double _paragraphs = 3;
  double _sentencesPerParagraph = 4;
  bool _startWithLorem = true;

  static const List<String> _words = <String>[
    'lorem', 'ipsum', 'dolor', 'sit', 'amet', 'consectetur', 'adipiscing',
    'elit', 'sed', 'do', 'eiusmod', 'tempor', 'incididunt', 'ut', 'labore',
    'et', 'dolore', 'magna', 'aliqua', 'enim', 'ad', 'minim', 'veniam',
    'quis', 'nostrud', 'exercitation', 'ullamco', 'laboris', 'nisi',
    'aliquip', 'ex', 'ea', 'commodo', 'consequat', 'duis', 'aute', 'irure',
    'in', 'reprehenderit', 'voluptate', 'velit', 'esse', 'cillum', 'eu',
    'fugiat', 'nulla', 'pariatur', 'excepteur', 'sint', 'occaecat',
    'cupidatat', 'non', 'proident', 'sunt', 'culpa', 'qui', 'officia',
    'deserunt', 'mollit', 'anim', 'id', 'est', 'laborum', 'curabitur',
    'pretium', 'tincidunt', 'lacus', 'nulla', 'gravida', 'orci', 'a',
    'odio', 'nullam', 'varius', 'turpis', 'commodo', 'condimentum', 'lobortis',
    'feugiat', 'vivamus', 'elementum', 'semper', 'nisi', 'aenean', 'vulputate',
    'eleifend', 'tellus', 'integer', 'feugiat', 'scelerisque', 'varius',
    'morbi', 'enim', 'nunc', 'faucibus', 'a', 'pellentesque', 'sit',
    'amet', 'porttitor', 'eget', 'dolor', 'morbi', 'non', 'arcu', 'risus',
    'quis', 'varius', 'quam', 'quisque', 'id', 'diam', 'vel', 'quam',
    'elementum', 'pulvinar', 'etiam', 'non', 'quam', 'lacus', 'suspendisse',
    'faucibus', 'interdum', 'posuere', 'lorem', 'ipsum', 'dolor', 'sit',
  ];

  static const List<String> _loremStart = <String>[
    'Lorem', 'ipsum', 'dolor', 'sit', 'amet', 'consectetur', 'adipiscing',
    'elit',
  ];

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

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String _generateSentence({bool first = false}) {
    final int wordCount = 8 + _random.nextInt(10);
    final List<String> sentenceWords = <String>[];
    for (int i = 0; i < wordCount; i++) {
      sentenceWords.add(_words[_random.nextInt(_words.length)]);
    }
    String sentence = sentenceWords.join(' ');
    if (first && _startWithLorem) {
      sentence = '${_loremStart.join(' ')} ${sentenceWords.sublist(
        0,
        sentenceWords.length > 4 ? 4 : sentenceWords.length,
      ).join(' ')}';
    } else {
      sentence = _capitalize(sentence);
    }
    return '$sentence.';
  }

  String _generateParagraph({bool first = false}) {
    final int count = _sentencesPerParagraph.round();
    final List<String> sentences = <String>[];
    for (int i = 0; i < count; i++) {
      sentences.add(_generateSentence(first: first && i == 0));
    }
    return sentences.join(' ');
  }

  void _generate() {
    final int pCount = _paragraphs.round();
    final List<String> paragraphs = <String>[];
    for (int i = 0; i < pCount; i++) {
      paragraphs.add(_generateParagraph(first: i == 0));
    }
    setState(() {
      _outputController.text = paragraphs.join('\n\n');
    });
  }

  Future<void> _copy() async {
    if (_outputController.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _outputController.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('loremgen_copied'))),
    );
  }

  Widget _slider({
    required String labelKey,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required VoidCallback onChangeEnd,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '${context.t(labelKey)}: ${value.round()}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: value.round().toString(),
          onChanged: onChanged,
          onChangeEnd: (_) => onChangeEnd(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('loremgen_title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _slider(
              labelKey: 'loremgen_paragraphs',
              value: _paragraphs,
              min: 1,
              max: 20,
              divisions: 19,
              onChanged: (double v) {
                setState(() {
                  _paragraphs = v;
                });
              },
              onChangeEnd: _generate,
            ),
            _slider(
              labelKey: 'loremgen_sentences',
              value: _sentencesPerParagraph,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (double v) {
                setState(() {
                  _sentencesPerParagraph = v;
                });
              },
              onChangeEnd: _generate,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.t('loremgen_start_with_lorem')),
              value: _startWithLorem,
              onChanged: (bool v) {
                setState(() {
                  _startWithLorem = v;
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
                    label: Text(context.t('loremgen_generate')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copy,
                    icon: const Icon(Icons.copy),
                    label: Text(context.t('loremgen_copy')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _outputController,
              readOnly: true,
              maxLines: null,
              minLines: 10,
              decoration: InputDecoration(
                labelText: context.t('loremgen_output_hint'),
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