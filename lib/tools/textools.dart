import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class TexTools extends StatefulWidget {
  const TexTools({super.key});

  @override
  State<TexTools> createState() => _TexToolsState();
}

class _TexToolsState extends State<TexTools>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Duplicate remover
  final TextEditingController _dupInput = TextEditingController();
  final TextEditingController _dupOutput = TextEditingController();
  bool _dupCaseSensitive = false;
  bool _dupTrim = true;
  bool _dupKeepFirst = true;
  bool _dupRemoveEmpty = false;
  int _dupRemoved = 0;
  int _dupKept = 0;

  // Sorter
  final TextEditingController _sortInput = TextEditingController();
  final TextEditingController _sortOutput = TextEditingController();
  String _sortMode = 'az';
  bool _sortCaseSensitive = false;
  bool _sortNumeric = false;
  bool _sortTrim = true;
  bool _sortReverse = false;
  bool _sortRemoveEmpty = false;

  // Extractor
  final TextEditingController _extractInput = TextEditingController();
  final TextEditingController _extractOutput = TextEditingController();
  bool _extractEmail = true;
  bool _extractUrl = true;
  bool _extractPhone = true;
  bool _extractIp = false;
  bool _extractHashtag = false;
  bool _extractMention = false;
  bool _extractUnique = true;
  List<_ExtractResult> _extractResults = <_ExtractResult>[];
  int _extractTotalCount = 0;

  static final RegExp _emailRegex = RegExp(
    r"[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}",
  );

  static final RegExp _urlRegex = RegExp(
    r"https?://[\w\-._~:/?#\[\]@!$&'()*+,;=%]+",
    caseSensitive: false,
  );

  static final RegExp _phoneRegex = RegExp(
    r"(?<!\d)(\+?\d{1,3}[\s.\-]?)?(\(?\d{2,4}\)?[\s.\-]?){2,4}\d{2,4}(?!\d)",
  );

  static final RegExp _ipRegex = RegExp(
    r"\b(?:\d{1,3}\.){3}\d{1,3}\b",
  );

  static final RegExp _hashtagRegex = RegExp(
    r"(?<![\w#])#[\w\u0600-\u06FF]+",
    unicode: true,
  );

  static final RegExp _mentionRegex = RegExp(
    r"(?<![\w@])@[\w._\-]+",
    unicode: true,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _dupInput.text = 'apple\nbanana\napple\ncherry\nBanana\ncherry\ndate';
    _sortInput.text = 'zebra\napple\nmango\nbanana\ncherry';
    _extractInput.text =
    'Əlaqə: info@example.com və support@test.org.\n'
        'Sayt: https://flutter.dev və http://dart.dev\n'
        'Telefon: +994 50 123 45 67, (012) 345-67-89\n'
        'Server: 192.168.1.1, 10.0.0.5\n'
        '#flutter #dart @flutterdev @dart_lang';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dupInput.dispose();
    _dupOutput.dispose();
    _sortInput.dispose();
    _sortOutput.dispose();
    _extractInput.dispose();
    _extractOutput.dispose();
    super.dispose();
  }

  Future<void> _copy(String text) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('textools_copied'))),
    );
  }

  Future<void> _pasteTo(TextEditingController c) async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null) return;
    c.text = data.text!;
  }

  // -------- Duplicate Remover --------

  void _removeDuplicates() {
    final String raw = _dupInput.text;
    if (raw.isEmpty) {
      setState(() {
        _dupOutput.text = '';
        _dupRemoved = 0;
        _dupKept = 0;
      });
      return;
    }
    final List<String> lines = raw.split('\n');
    final Set<String> seen = <String>{};
    final List<String> kept = <String>[];
    int removed = 0;

    final List<String> source = _dupKeepFirst ? lines : lines.reversed.toList();

    for (String line in source) {
      String key = line;
      if (_dupTrim) key = key.trim();
      if (_dupRemoveEmpty && key.isEmpty) {
        removed++;
        continue;
      }
      final String compareKey =
      _dupCaseSensitive ? key : key.toLowerCase();
      if (seen.contains(compareKey)) {
        removed++;
      } else {
        seen.add(compareKey);
        kept.add(_dupTrim ? line.trim() : line);
      }
    }

    final List<String> finalList =
    _dupKeepFirst ? kept : kept.reversed.toList();

    setState(() {
      _dupOutput.text = finalList.join('\n');
      _dupRemoved = removed;
      _dupKept = finalList.length;
    });
  }

  // -------- Sorter --------

  int _compareStrings(String a, String b) {
    if (_sortNumeric) {
      final double? na = double.tryParse(a.trim());
      final double? nb = double.tryParse(b.trim());
      if (na != null && nb != null) return na.compareTo(nb);
      if (na != null) return -1;
      if (nb != null) return 1;
    }
    final String x = _sortCaseSensitive ? a : a.toLowerCase();
    final String y = _sortCaseSensitive ? b : b.toLowerCase();
    return x.compareTo(y);
  }

  void _sortLines() {
    final String raw = _sortInput.text;
    if (raw.isEmpty) {
      setState(() {
        _sortOutput.text = '';
      });
      return;
    }
    List<String> lines = raw.split('\n');
    if (_sortTrim) lines = lines.map((String l) => l.trim()).toList();
    if (_sortRemoveEmpty) {
      lines = lines.where((String l) => l.isNotEmpty).toList();
    }
    lines.sort(_compareStrings);
    if (_sortReverse) lines = lines.reversed.toList();
    setState(() {
      _sortOutput.text = lines.join('\n');
    });
  }

  // -------- Extractor --------

  void _extract() {
    final String raw = _extractInput.text;
    if (raw.isEmpty) {
      setState(() {
        _extractResults = <_ExtractResult>[];
        _extractOutput.text = '';
        _extractTotalCount = 0;
      });
      return;
    }

    final List<_ExtractResult> results = <_ExtractResult>[];

    void addMatches(String typeKey, RegExp re) {
      final Set<String> seen = <String>{};
      for (final RegExpMatch m in re.allMatches(raw)) {
        final String value = m.group(0) ?? '';
        if (value.isEmpty) continue;
        if (_extractUnique) {
          if (seen.contains(value)) continue;
          seen.add(value);
        }
        results.add(_ExtractResult(typeKey, value, m.start, m.end));
      }
    }

    if (_extractEmail) addMatches('textools_extract_email', _emailRegex);
    if (_extractUrl) addMatches('textools_extract_url', _urlRegex);
    if (_extractIp) addMatches('textools_extract_ip', _ipRegex);
    if (_extractHashtag) addMatches('textools_extract_hashtag', _hashtagRegex);
    if (_extractMention) addMatches('textools_extract_mention', _mentionRegex);
    if (_extractPhone) {
      final List<RegExpMatch> phoneMatches =
      _phoneRegex.allMatches(raw).toList();
      final Set<String> seen = <String>{};
      for (final RegExpMatch m in phoneMatches) {
        final String value = m.group(0) ?? '';
        if (value.isEmpty) continue;
        final int digitCount = value.replaceAll(RegExp(r'\D'), '').length;
        if (digitCount < 7) continue;
        if (value.contains('@')) continue;
        if (RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(value.trim())) {
          continue;
        }
        if (_extractUnique) {
          if (seen.contains(value)) continue;
          seen.add(value);
        }
        results.add(_ExtractResult('textools_extract_phone', value,
            m.start, m.end));
      }
    }

    results.sort((_ExtractResult a, _ExtractResult b) {
      final int cmp = a.start.compareTo(b.start);
      if (cmp != 0) return cmp;
      return a.end.compareTo(b.end);
    });

    final StringBuffer plain = StringBuffer();
    for (final _ExtractResult r in results) {
      plain.writeln(r.value);
    }

    setState(() {
      _extractResults = results;
      _extractOutput.text = plain.toString().trimRight();
      _extractTotalCount = results.length;
    });
  }

  // -------- UI helpers --------

  Widget _inputBox({
    required String labelKey,
    required TextEditingController controller,
    ValueChanged<String>? onChanged,
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
              onPressed: () async {
                await _pasteTo(controller);
                if (onChanged != null) onChanged(controller.text);
              },
              icon: const Icon(Icons.paste, size: 18),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () {
                controller.clear();
                if (onChanged != null) onChanged('');
              },
              icon: const Icon(Icons.clear, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: 8,
          minLines: 5,
          onChanged: onChanged,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _outputBox({
    required String labelKey,
    required TextEditingController controller,
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
              onPressed: () => _copy(controller.text),
              icon: const Icon(Icons.copy, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          readOnly: true,
          maxLines: null,
          minLines: 8,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDuplicate() {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _inputBox(
            labelKey: 'textools_dup_input',
            controller: _dupInput,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(context.t('textools_dup_case')),
            value: _dupCaseSensitive,
            onChanged: (bool v) {
              setState(() => _dupCaseSensitive = v);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(context.t('textools_dup_trim')),
            value: _dupTrim,
            onChanged: (bool v) {
              setState(() => _dupTrim = v);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(context.t('textools_dup_keep_first')),
            value: _dupKeepFirst,
            onChanged: (bool v) {
              setState(() => _dupKeepFirst = v);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(context.t('textools_dup_remove_empty')),
            value: _dupRemoveEmpty,
            onChanged: (bool v) {
              setState(() => _dupRemoveEmpty = v);
            },
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _removeDuplicates,
            icon: const Icon(Icons.cleaning_services),
            label: Text(context.t('textools_dup_run')),
          ),
          if (_dupOutput.text.isNotEmpty || _dupKept > 0 || _dupRemoved > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _stat(
                      context.t('textools_dup_kept'),
                      _dupKept,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _stat(
                      context.t('textools_dup_removed'),
                      _dupRemoved,
                      colors.error,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          _outputBox(
            labelKey: 'textools_dup_output',
            controller: _dupOutput,
          ),
        ],
      ),
    );
  }

  Widget _buildSorter() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _inputBox(
            labelKey: 'textools_sort_input',
            controller: _sortInput,
          ),
          const SizedBox(height: 8),
          Text(
            context.t('textools_sort_mode'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ChoiceChip(
                label: Text(context.t('textools_sort_az')),
                selected: _sortMode == 'az' && !_sortReverse,
                onSelected: (_) {
                  setState(() {
                    _sortMode = 'az';
                    _sortReverse = false;
                  });
                  _sortLines();
                },
              ),
              ChoiceChip(
                label: Text(context.t('textools_sort_za')),
                selected: _sortMode == 'az' && _sortReverse,
                onSelected: (_) {
                  setState(() {
                    _sortMode = 'az';
                    _sortReverse = true;
                  });
                  _sortLines();
                },
              ),
              ChoiceChip(
                label: Text(context.t('textools_sort_by_len')),
                selected: _sortMode == 'len' && !_sortReverse,
                onSelected: (_) {
                  setState(() {
                    _sortMode = 'len';
                    _sortReverse = false;
                  });
                  _sortLines();
                },
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(context.t('textools_sort_case')),
            value: _sortCaseSensitive,
            onChanged: (bool v) {
              setState(() => _sortCaseSensitive = v);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(context.t('textools_sort_numeric')),
            value: _sortNumeric,
            onChanged: (bool v) {
              setState(() => _sortNumeric = v);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(context.t('textools_sort_trim')),
            value: _sortTrim,
            onChanged: (bool v) {
              setState(() => _sortTrim = v);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(context.t('textools_sort_remove_empty')),
            value: _sortRemoveEmpty,
            onChanged: (bool v) {
              setState(() => _sortRemoveEmpty = v);
            },
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () {
              if (_sortMode == 'len') {
                List<String> lines = _sortInput.text.split('\n');
                if (_sortTrim) {
                  lines = lines.map((String l) => l.trim()).toList();
                }
                if (_sortRemoveEmpty) {
                  lines = lines.where((String l) => l.isNotEmpty).toList();
                }
                lines.sort((String a, String b) {
                  final int cmp = a.length.compareTo(b.length);
                  if (cmp != 0) return cmp;
                  return _compareStrings(a, b);
                });
                if (_sortReverse) lines = lines.reversed.toList();
                setState(() {
                  _sortOutput.text = lines.join('\n');
                });
              } else {
                _sortLines();
              }
            },
            icon: const Icon(Icons.sort),
            label: Text(context.t('textools_sort_run')),
          ),
          const SizedBox(height: 16),
          _outputBox(
            labelKey: 'textools_sort_output',
            controller: _sortOutput,
          ),
        ],
      ),
    );
  }

  Widget _buildExtractor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _inputBox(
            labelKey: 'textools_extract_input',
            controller: _extractInput,
          ),
          const SizedBox(height: 8),
          Text(
            context.t('textools_extract_types'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilterChip(
                label: Text(context.t('textools_extract_email')),
                selected: _extractEmail,
                onSelected: (bool v) {
                  setState(() => _extractEmail = v);
                },
              ),
              FilterChip(
                label: Text(context.t('textools_extract_url')),
                selected: _extractUrl,
                onSelected: (bool v) {
                  setState(() => _extractUrl = v);
                },
              ),
              FilterChip(
                label: Text(context.t('textools_extract_phone')),
                selected: _extractPhone,
                onSelected: (bool v) {
                  setState(() => _extractPhone = v);
                },
              ),
              FilterChip(
                label: Text(context.t('textools_extract_ip')),
                selected: _extractIp,
                onSelected: (bool v) {
                  setState(() => _extractIp = v);
                },
              ),
              FilterChip(
                label: Text(context.t('textools_extract_hashtag')),
                selected: _extractHashtag,
                onSelected: (bool v) {
                  setState(() => _extractHashtag = v);
                },
              ),
              FilterChip(
                label: Text(context.t('textools_extract_mention')),
                selected: _extractMention,
                onSelected: (bool v) {
                  setState(() => _extractMention = v);
                },
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(context.t('textools_extract_unique')),
            value: _extractUnique,
            onChanged: (bool v) {
              setState(() => _extractUnique = v);
            },
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _extract,
            icon: const Icon(Icons.search),
            label: Text(context.t('textools_extract_run')),
          ),
          if (_extractTotalCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '${context.t('textools_extract_found')}: $_extractTotalCount',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          if (_extractResults.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            for (int i = 0; i < _extractResults.length; i++)
              Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  dense: true,
                  leading: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      context.t(_extractResults[i].typeKey),
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer,
                      ),
                    ),
                  ),
                  title: SelectableText(
                    _extractResults[i].value,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                  trailing: IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _copy(_extractResults[i].value),
                    icon: const Icon(Icons.copy, size: 16),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 16),
          _outputBox(
            labelKey: 'textools_extract_output',
            controller: _extractOutput,
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, int count, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11),
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
        title: Text(context.t('textools_title')),
        bottom: TabBar(
          controller: _tabController,
          tabs: <Widget>[
            Tab(text: context.t('textools_tab_dup')),
            Tab(text: context.t('textools_tab_sort')),
            Tab(text: context.t('textools_tab_extract')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          _buildDuplicate(),
          _buildSorter(),
          _buildExtractor(),
        ],
      ),
    );
  }
}

class _ExtractResult {
  final String typeKey;
  final String value;
  final int start;
  final int end;

  _ExtractResult(this.typeKey, this.value, this.start, this.end);
}