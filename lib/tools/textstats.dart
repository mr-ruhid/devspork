import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class TextStats extends StatefulWidget {
  const TextStats({super.key});

  @override
  State<TextStats> createState() => _TextStatsState();
}

class _TextStatsState extends State<TextStats> {
  final TextEditingController _controller = TextEditingController();

  int _chars = 0;
  int _charsNoSpaces = 0;
  int _words = 0;
  int _sentences = 0;
  int _lines = 0;
  int _paragraphs = 0;
  int _readingSeconds = 0;
  int _speakingSeconds = 0;

  static const int _wordsPerMinuteReading = 200;
  static const int _wordsPerMinuteSpeaking = 130;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_recalculate);
  }

  @override
  void dispose() {
    _controller.removeListener(_recalculate);
    _controller.dispose();
    super.dispose();
  }

  void _recalculate() {
    final String text = _controller.text;
    final int chars = text.length;
    final int charsNoSpaces = text.replaceAll(RegExp(r'\s'), '').length;
    final List<String> wordList =
    text.trim().isEmpty ? <String>[] : text.trim().split(RegExp(r'\s+'));
    final int words = wordList.length;
    final int sentences = text
        .split(RegExp(r'[.!?]+'))
        .where((String s) => s.trim().isNotEmpty)
        .length;
    final int lines = text.isEmpty ? 0 : text.split('\n').length;
    final int paragraphs = text
        .split(RegExp(r'\n\s*\n'))
        .where((String p) => p.trim().isNotEmpty)
        .length;
    final int readingSeconds = words == 0
        ? 0
        : ((words / _wordsPerMinuteReading) * 60).round();
    final int speakingSeconds = words == 0
        ? 0
        : ((words / _wordsPerMinuteSpeaking) * 60).round();

    setState(() {
      _chars = chars;
      _charsNoSpaces = charsNoSpaces;
      _words = words;
      _sentences = sentences;
      _lines = lines;
      _paragraphs = paragraphs;
      _readingSeconds = readingSeconds;
      _speakingSeconds = speakingSeconds;
    });
  }

  void _clear() {
    _controller.clear();
  }

  Future<void> _paste() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null) return;
    _controller.text = data.text!;
  }

  Future<void> _copy() async {
    if (_controller.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _controller.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('textstats_copied'))),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return '0 ${context.t('textstats_sec')}';
    if (seconds < 60) return '$seconds ${context.t('textstats_sec')}';
    final int minutes = seconds ~/ 60;
    final int sec = seconds % 60;
    if (sec == 0) return '$minutes ${context.t('textstats_min')}';
    return '$minutes ${context.t('textstats_min')} $sec ${context.t('textstats_sec')}';
  }

  Widget _statCard(String labelKey, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              context.t(labelKey),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('textstats_title')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              flex: 3,
              child: TextField(
                controller: _controller,
                expands: true,
                maxLines: null,
                minLines: null,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  labelText: context.t('textstats_input_hint'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _paste,
                    icon: const Icon(Icons.paste),
                    label: Text(context.t('textstats_paste')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copy,
                    icon: const Icon(Icons.copy),
                    label: Text(context.t('textstats_copy')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clear,
                    icon: const Icon(Icons.clear),
                    label: Text(context.t('textstats_clear')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              flex: 4,
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 2.2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      children: <Widget>[
                        _statCard('textstats_chars', _chars.toString()),
                        _statCard(
                          'textstats_chars_no_spaces',
                          _charsNoSpaces.toString(),
                        ),
                        _statCard('textstats_words', _words.toString()),
                        _statCard(
                          'textstats_sentences',
                          _sentences.toString(),
                        ),
                        _statCard('textstats_lines', _lines.toString()),
                        _statCard(
                          'textstats_paragraphs',
                          _paragraphs.toString(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '${context.t('textstats_reading_time')}: ${_formatDuration(_readingSeconds)}',
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${context.t('textstats_speaking_time')}: ${_formatDuration(_speakingSeconds)}',
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
      ),
    );
  }
}