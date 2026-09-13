import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class RegexTest extends StatefulWidget {
  const RegexTest({super.key});

  @override
  State<RegexTest> createState() => _RegexTestState();
}

class _RegexTestState extends State<RegexTest>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _patternController = TextEditingController();
  final TextEditingController _textController = TextEditingController();

  bool _caseSensitive = true;
  bool _multiLine = false;
  bool _dotAll = false;
  bool _unicode = false;

  String? _errorKey;
  String? _errorDetail;
  List<_MatchResult> _matches = <_MatchResult>[];
  int _activeMatchIndex = -1;

  static const List<_CheatItem> _cheatSheet = <_CheatItem>[
    _CheatItem('regex_cheat_digit', r'\d', '0-9 arasında rəqəm'),
    _CheatItem('regex_cheat_nondigit', r'\D', 'Rəqəm olmayan'),
    _CheatItem('regex_cheat_word', r'\w', 'Hərf, rəqəm, _'),
    _CheatItem('regex_cheat_nonword', r'\W', 'Hərf/rəqəm olmayan'),
    _CheatItem('regex_cheat_space', r'\s', 'Boşluq, tab, yeni sətir'),
    _CheatItem('regex_cheat_nonspace', r'\S', 'Boşluq olmayan'),
    _CheatItem('regex_cheat_dot', r'.', 'İstənilən simvol (sətirdən başqa)'),
    _CheatItem('regex_cheat_anchor_start', r'^', 'Sətrin başlanğıcı'),
    _CheatItem('regex_cheat_anchor_end', r'$', 'Sətrin sonu'),
    _CheatItem('regex_cheat_word_boundary', r'\b', 'Söz sərhədi'),
    _CheatItem('regex_cheat_star', r'a*', '0 və ya daha çox'),
    _CheatItem('regex_cheat_plus', r'a+', '1 və ya daha çox'),
    _CheatItem('regex_cheat_question', r'a?', '0 və ya 1'),
    _CheatItem('regex_cheat_range', r'[abc]', 'a, b və ya c'),
    _CheatItem('regex_cheat_neg_range', r'[^abc]', 'a, b, c olmayan'),
    _CheatItem('regex_cheat_number_range', r'[0-9]', '0-9 arası'),
    _CheatItem('regex_cheat_quantifier', r'a{3}', 'Dəqiq 3 dəfə'),
    _CheatItem('regex_cheat_quantifier_range', r'a{2,5}', '2-5 dəfə'),
    _CheatItem('regex_cheat_quantifier_min', r'a{2,}', 'Ən azı 2 dəfə'),
    _CheatItem('regex_cheat_group', r'(abc)', 'Qrup'),
    _CheatItem('regex_cheat_non_capture', r'(?:abc)', 'Qrup (yadda saxlamadan)'),
    _CheatItem('regex_cheat_or', r'a|b', 'a və ya b'),
    _CheatItem('regex_cheat_lookahead', r'(?=abc)', 'Sonrası abc olan'),
    _CheatItem('regex_cheat_neg_lookahead', r'(?!abc)', 'Sonrası abc olmayan'),
  ];

  static const List<_PatternPreset> _presets = <_PatternPreset>[
    _PatternPreset('regex_preset_email', r'[\w.+-]+@[\w-]+\.[\w.-]+'),
    _PatternPreset('regex_preset_url',
        r'https?://[\w.-]+(?:\/[\w./?%&=-]*)?'),
    _PatternPreset('regex_preset_ipv4',
        r'\b(?:(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\b'),
    _PatternPreset('regex_preset_phone', r'\+?\d[\d\s\-()]{7,}\d'),
    _PatternPreset('regex_preset_date', r'\d{4}-\d{2}-\d{2}'),
    _PatternPreset('regex_preset_time', r'\d{2}:\d{2}(?::\d{2})?'),
    _PatternPreset('regex_preset_hex_color', r'#(?:[0-9a-fA-F]{3}){1,2}\b'),
    _PatternPreset('regex_preset_uuid',
        r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'),
    _PatternPreset('regex_preset_username', r'^[a-zA-Z0-9_]{3,16}$'),
    _PatternPreset('regex_preset_strong_pass',
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}$'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _patternController.text = r'\b\w+@\w+\.\w+\b';
    _textController.text =
    'Salam, əlaqə üçün: info@example.com və ya support@test.org yazın.';
    _run();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _patternController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _run() {
    final String pattern = _patternController.text;
    final String text = _textController.text;
    if (pattern.isEmpty) {
      setState(() {
        _matches = <_MatchResult>[];
        _errorKey = null;
        _errorDetail = null;
      });
      return;
    }
    try {
      final RegExp re = RegExp(
        pattern,
        caseSensitive: _caseSensitive,
        multiLine: _multiLine,
        dotAll: _dotAll,
        unicode: _unicode,
      );
      final List<_MatchResult> matches = <_MatchResult>[];
      int guard = 0;
      for (final RegExpMatch m in re.allMatches(text)) {
        matches.add(_MatchResult(
          start: m.start,
          end: m.end,
          value: m.group(0) ?? '',
          groups: List<String?>.generate(
            m.groupCount,
                (int i) => m.group(i + 1),
          ),
        ));
        guard++;
        if (guard > 5000) break;
      }
      setState(() {
        _matches = matches;
        _errorKey = null;
        _errorDetail = null;
        if (_activeMatchIndex >= matches.length) _activeMatchIndex = -1;
      });
    } catch (e) {
      setState(() {
        _matches = <_MatchResult>[];
        _errorKey = 'regextest_error_invalid';
        _errorDetail = e.toString();
      });
    }
  }

  void _clear() {
    setState(() {
      _patternController.clear();
      _textController.clear();
      _matches = <_MatchResult>[];
      _errorKey = null;
      _errorDetail = null;
      _activeMatchIndex = -1;
    });
  }

  Future<void> _pasteTo(TextEditingController c) async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null) return;
    c.text = data.text!;
    _run();
  }

  Future<void> _copy(String text) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('regextest_copied'))),
    );
  }

  List<TextSpan> _buildHighlightedText(ColorScheme colors) {
    final String text = _textController.text;
    if (_matches.isEmpty) {
      return <TextSpan>[
        TextSpan(
          text: text.isEmpty ? '' : text,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        ),
      ];
    }
    final List<TextSpan> spans = <TextSpan>[];
    int cursor = 0;
    for (int i = 0; i < _matches.length; i++) {
      final _MatchResult m = _matches[i];
      if (m.start > cursor) {
        spans.add(TextSpan(
          text: text.substring(cursor, m.start),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        ));
      }
      final bool isActive = i == _activeMatchIndex;
      spans.add(TextSpan(
        text: text.substring(m.start, m.end),
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          backgroundColor: isActive
              ? colors.primary.withValues(alpha: 0.4)
              : colors.primary.withValues(alpha: 0.18),
          fontWeight: FontWeight.bold,
        ),
      ));
      cursor = m.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(
        text: text.substring(cursor),
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      ));
    }
    return spans;
  }

  Widget _flagChip(String labelKey, bool value, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(context.t(labelKey), style: const TextStyle(fontSize: 12)),
      selected: value,
      onSelected: onChanged,
    );
  }

  Widget _buildTester(ColorScheme colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  context.t('regextest_pattern'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => _pasteTo(_patternController),
                icon: const Icon(Icons.paste, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _patternController,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            onChanged: (_) => _run(),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              hintText: r'\d+',
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _flagChip('regextest_flag_case', _caseSensitive, (bool v) {
                setState(() => _caseSensitive = v);
                _run();
              }),
              _flagChip('regextest_flag_multiline', _multiLine, (bool v) {
                setState(() => _multiLine = v);
                _run();
              }),
              _flagChip('regextest_flag_dotall', _dotAll, (bool v) {
                setState(() => _dotAll = v);
                _run();
              }),
              _flagChip('regextest_flag_unicode', _unicode, (bool v) {
                setState(() => _unicode = v);
                _run();
              }),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  context.t('regextest_test_text'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => _pasteTo(_textController),
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
            controller: _textController,
            maxLines: 5,
            minLines: 3,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            onChanged: (_) => _run(),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          if (_errorKey != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
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
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${context.t('regextest_matches')}: ${_matches.length}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (_matches.isNotEmpty)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    setState(() {
                      _activeMatchIndex = _activeMatchIndex <= 0
                          ? _matches.length - 1
                          : _activeMatchIndex - 1;
                    });
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
              if (_matches.isNotEmpty)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    setState(() {
                      _activeMatchIndex = _activeMatchIndex >=
                          _matches.length - 1
                          ? 0
                          : _activeMatchIndex + 1;
                    });
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: colors.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText.rich(
              TextSpan(children: _buildHighlightedText(colors)),
            ),
          ),
          if (_matches.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              context.t('regextest_results'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < _matches.length; i++)
              Card(
                color: i == _activeMatchIndex
                    ? colors.primary.withValues(alpha: 0.1)
                    : null,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _activeMatchIndex = i;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Text(
                              '#${i + 1}',
                              style: TextStyle(
                                color: colors.outline,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SelectableText(
                                _matches[i].value,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _copy(_matches[i].value),
                              icon: const Icon(Icons.copy, size: 16),
                            ),
                          ],
                        ),
                        Text(
                          '[${_matches[i].start}-${_matches[i].end}]',
                          style: TextStyle(
                            color: colors.outline,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                        if (_matches[i].groups.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List<Widget>.generate(
                                _matches[i].groups.length,
                                    (int gi) => Text(
                                  '  \$${gi + 1} = ${_matches[i].groups[gi] ?? '-'}',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
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
    );
  }

  Widget _buildCheatSheet(ColorScheme colors) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(
          context.t('regextest_presets'),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presets.map((_PatternPreset p) {
            return ActionChip(
              label: Text(
                context.t(p.labelKey),
                style: const TextStyle(fontSize: 12),
              ),
              onPressed: () {
                _patternController.text = p.pattern;
                _tabController.index = 0;
                _run();
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text(
          context.t('regextest_cheat_title'),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: <Widget>[
              for (int i = 0; i < _cheatSheet.length; i++) ...<Widget>[
                ListTile(
                  dense: true,
                  onTap: () {
                    _patternController.text = _cheatSheet[i].pattern;
                    _tabController.index = 0;
                    _run();
                  },
                  leading: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _cheatSheet[i].pattern,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    context.t(_cheatSheet[i].labelKey),
                    style: const TextStyle(fontSize: 13),
                  ),
                  subtitle: Text(
                    _cheatSheet[i].description,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                if (i < _cheatSheet.length - 1)
                  Divider(height: 1, color: colors.outlineVariant),
              ],
            ],
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
        title: Text(context.t('regextest_title')),
        bottom: TabBar(
          controller: _tabController,
          tabs: <Widget>[
            Tab(text: context.t('regextest_tab_tester')),
            Tab(text: context.t('regextest_tab_cheat')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          _buildTester(colors),
          _buildCheatSheet(colors),
        ],
      ),
    );
  }
}

class _MatchResult {
  final int start;
  final int end;
  final String value;
  final List<String?> groups;

  _MatchResult({
    required this.start,
    required this.end,
    required this.value,
    required this.groups,
  });
}

class _CheatItem {
  final String labelKey;
  final String pattern;
  final String description;

  const _CheatItem(this.labelKey, this.pattern, this.description);
}

class _PatternPreset {
  final String labelKey;
  final String pattern;

  const _PatternPreset(this.labelKey, this.pattern);
}