import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class ListConv extends StatefulWidget {
  const ListConv({super.key});

  @override
  State<ListConv> createState() => _ListConvState();
}

class _ListConvState extends State<ListConv> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();

  String _inputSep = 'newline';
  String _outputFormat = 'json';
  bool _trim = true;
  bool _removeEmpty = true;
  bool _quoteSql = true;

  static const List<String> _inputSeps = <String>[
    'newline',
    'comma',
    'semicolon',
    'pipe',
    'space',
  ];

  static const List<String> _formats = <String>[
    'json',
    'sql',
    'csv',
    'newline',
    'semicolon',
    'pipe',
    'dart',
    'python',
  ];

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_convert);
  }

  @override
  void dispose() {
    _inputController.removeListener(_convert);
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  RegExp _sepRegex(String sep) {
    switch (sep) {
      case 'comma':
        return RegExp(r',');
      case 'semicolon':
        return RegExp(r';');
      case 'pipe':
        return RegExp(r'\|');
      case 'space':
        return RegExp(r'\s+');
      case 'newline':
      default:
        return RegExp(r'\r?\n');
    }
  }

  List<String> _parseItems() {
    final String raw = _inputController.text;
    if (raw.isEmpty) return <String>[];
    final List<String> parts = raw.split(_sepRegex(_inputSep));
    final List<String> result = <String>[];
    for (String p in parts) {
      String v = p;
      if (_trim) v = v.trim();
      if (_removeEmpty && v.isEmpty) continue;
      result.add(v);
    }
    return result;
  }

  String _escapeJson(String s) {
    return s
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }

  String _escapeSql(String s) {
    return s.replaceAll("'", "''");
  }

  String _escapeCsv(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  String _build(List<String> items) {
    if (items.isEmpty) return '';
    switch (_outputFormat) {
      case 'json':
        return '[\n  ${items.map((String s) => '"${_escapeJson(s)}"').join(',\n  ')}\n]';
      case 'sql':
        if (_quoteSql) {
          return '(${items.map((String s) => "'${_escapeSql(s)}'").join(', ')})';
        }
        return '(${items.join(', ')})';
      case 'csv':
        return items.map(_escapeCsv).join(',');
      case 'newline':
        return items.join('\n');
      case 'semicolon':
        return items.join('; ');
      case 'pipe':
        return items.join(' | ');
      case 'dart':
        return '[\n  ${items.map((String s) => "'${s.replaceAll("'", "\\'").replaceAll('\\', '\\\\')}'").join(',\n  ')}\n]';
      case 'python':
        return '[\n    ${items.map((String s) => "'${s.replaceAll("'", "\\'")}'").join(',\n    ')}\n]';
      default:
        return items.join('\n');
    }
  }

  void _convert() {
    final List<String> items = _parseItems();
    setState(() {
      _outputController.text = _build(items);
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
      SnackBar(content: Text(context.t('listconv_copied'))),
    );
  }

  Future<void> _paste() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null) return;
    _inputController.text = data.text!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('listconv_title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              context.t('listconv_input_sep'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _inputSeps.map((String s) {
                return ChoiceChip(
                  label: Text(context.t('listconv_sep_$s')),
                  selected: _inputSep == s,
                  onSelected: (_) {
                    setState(() {
                      _inputSep = s;
                    });
                    _convert();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    context.t('listconv_input_hint'),
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
              maxLines: 6,
              minLines: 4,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.t('listconv_output_format'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _formats.map((String f) {
                return ChoiceChip(
                  label: Text(context.t('listconv_fmt_$f')),
                  selected: _outputFormat == f,
                  onSelected: (_) {
                    setState(() {
                      _outputFormat = f;
                    });
                    _convert();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.t('listconv_trim')),
              value: _trim,
              onChanged: (bool v) {
                setState(() {
                  _trim = v;
                });
                _convert();
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.t('listconv_remove_empty')),
              value: _removeEmpty,
              onChanged: (bool v) {
                setState(() {
                  _removeEmpty = v;
                });
                _convert();
              },
            ),
            if (_outputFormat == 'sql')
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.t('listconv_quote_sql')),
                value: _quoteSql,
                onChanged: (bool v) {
                  setState(() {
                    _quoteSql = v;
                  });
                  _convert();
                },
              ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    context.t('listconv_output_hint'),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: _copy,
                  icon: const Icon(Icons.copy, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _outputController,
              readOnly: true,
              maxLines: null,
              minLines: 6,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}