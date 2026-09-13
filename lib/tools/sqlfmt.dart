import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class SqlFmt extends StatefulWidget {
  const SqlFmt({super.key});

  @override
  State<SqlFmt> createState() => _SqlFmtState();
}

class _SqlFmtState extends State<SqlFmt> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();

  bool _uppercase = true;
  bool _newlineBeforeMajor = true;
  bool _newlineBeforeAnd = true;
  bool _indentColumns = true;
  int _indentSize = 2;

  static const List<String> _majorKeywords = <String>[
    'SELECT', 'FROM', 'WHERE', 'GROUP BY', 'HAVING', 'ORDER BY',
    'LIMIT', 'OFFSET', 'UNION ALL', 'UNION', 'INSERT INTO',
    'VALUES', 'UPDATE', 'SET', 'DELETE FROM', 'CREATE TABLE',
    'ALTER TABLE', 'DROP TABLE', 'INNER JOIN', 'LEFT JOIN',
    'RIGHT JOIN', 'FULL JOIN', 'CROSS JOIN', 'JOIN', 'ON',
    'RETURNING', 'WITH',
  ];

  static const List<String> _allKeywords = <String>[
    'SELECT', 'FROM', 'WHERE', 'GROUP BY', 'HAVING', 'ORDER BY',
    'LIMIT', 'OFFSET', 'UNION ALL', 'UNION', 'INSERT INTO',
    'VALUES', 'UPDATE', 'SET', 'DELETE FROM', 'CREATE TABLE',
    'ALTER TABLE', 'DROP TABLE', 'INNER JOIN', 'LEFT JOIN',
    'RIGHT JOIN', 'FULL JOIN', 'CROSS JOIN', 'JOIN', 'ON',
    'RETURNING', 'WITH', 'AS', 'AND', 'OR', 'NOT', 'NULL',
    'IS', 'IN', 'LIKE', 'BETWEEN', 'EXISTS', 'CASE', 'WHEN',
    'THEN', 'ELSE', 'END', 'DISTINCT', 'ASC', 'DESC', 'INTO',
    'PRIMARY KEY', 'FOREIGN KEY', 'REFERENCES', 'DEFAULT',
    'CONSTRAINT', 'UNIQUE', 'CHECK', 'INDEX', 'COUNT', 'SUM',
    'AVG', 'MIN', 'MAX', 'TRUE', 'FALSE',
  ];

  @override
  void initState() {
    super.initState();
    _inputController.text =
    'select id, name, email from users where age > 18 and city = \'baku\' order by name asc limit 10';
    _format();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  String _applyCase(String sql) {
    String result = sql;
    for (final String kw in _allKeywords) {
      final RegExp re = RegExp(
        r'\b' + RegExp.escape(kw).replaceAll(r'\ ', r'\s+') + r'\b',
        caseSensitive: false,
      );
      result = result.replaceAllMapped(re, (Match m) {
        return _uppercase ? kw : kw.toLowerCase();
      });
    }
    return result;
  }

  String _normalizeSpaces(String sql) {
    return sql
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\s*\n\s*'), ' ')
        .trim();
  }

  String _insertNewlinesBeforeKeywords(String sql, List<String> keywords) {
    String result = sql;
    for (final String kw in keywords) {
      final RegExp re = RegExp(
        r'\s+\b' + RegExp.escape(kw).replaceAll(r'\ ', r'\s+') + r'\b',
        caseSensitive: false,
      );
      result = result.replaceAllMapped(re, (Match m) {
        final String matched = m.group(0)!.trimLeft();
        return '\n$matched';
      });
    }
    return result;
  }

  String _addIndent(String sql) {
    final List<String> lines = sql.split('\n');
    final String indent = ' ' * _indentSize;
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i].trim();
      if (line.isEmpty) continue;
      final String upper = line.toUpperCase();
      bool isMajor = false;
      for (final String kw in _majorKeywords) {
        if (upper.startsWith(kw)) {
          isMajor = true;
          break;
        }
      }
      if (isMajor) {
        buffer.writeln(line);
        if (i < lines.length - 1) {
          final String next = lines[i + 1].trim();
          final String nextUpper = next.toUpperCase();
          bool nextMajor = false;
          for (final String kw in _majorKeywords) {
            if (nextUpper.startsWith(kw)) {
              nextMajor = true;
              break;
            }
          }
          if (!nextMajor && _indentColumns) {
            buffer.writeln(indent + next);
            i++;
          }
        }
      } else {
        buffer.writeln(indent + line);
      }
    }
    return buffer.toString().trimRight();
  }

  String _wrapLongLines(String sql, int maxLen) {
    final List<String> lines = sql.split('\n');
    final StringBuffer buffer = StringBuffer();
    final String indent = ' ' * _indentSize;
    for (final String line in lines) {
      if (line.length <= maxLen) {
        buffer.writeln(line);
        continue;
      }
      final List<String> parts = line.split(', ');
      if (parts.length > 1) {
        for (int i = 0; i < parts.length; i++) {
          final String suffix = i < parts.length - 1 ? ',' : '';
          if (i == 0) {
            buffer.writeln('${parts[i]}$suffix');
          } else {
            buffer.writeln('$indent${parts[i]}$suffix');
          }
        }
      } else {
        buffer.writeln(line);
      }
    }
    return buffer.toString().trimRight();
  }

  void _format() {
    final String input = _inputController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _outputController.text = '';
      });
      return;
    }
    String sql = _normalizeSpaces(input);
    sql = _applyCase(sql);

    final List<String> newlineKeywords = <String>[];
    if (_newlineBeforeMajor) {
      newlineKeywords.addAll(_majorKeywords);
    }
    if (_newlineBeforeAnd) {
      newlineKeywords.add('AND');
      newlineKeywords.add('OR');
    }

    newlineKeywords.sort((String a, String b) => b.length.compareTo(a.length));
    sql = _insertNewlinesBeforeKeywords(sql, newlineKeywords);

    final List<String> lines = sql.split('\n');
    final StringBuffer buffer = StringBuffer();
    for (final String l in lines) {
      final String t = l.trim();
      if (t.isEmpty) continue;
      buffer.writeln(t);
    }
    sql = buffer.toString().trim();

    if (_indentColumns) {
      sql = _addIndent(sql);
    }
    sql = _wrapLongLines(sql, 80);
    setState(() {
      _outputController.text = sql;
    });
  }

  void _minify() {
    final String input = _inputController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _outputController.text = '';
      });
      return;
    }
    String sql = _normalizeSpaces(input);
    sql = _applyCase(sql);
    sql = sql.replaceAll(RegExp(r'\s*([(),=<>+\-*/])\s*'), r'$1');
    sql = sql.replaceAll(RegExp(r',\s*'), ', ');
    sql = sql.replaceAll(RegExp(r'\s+'), ' ').trim();
    setState(() {
      _outputController.text = sql;
    });
  }

  void _clear() {
    setState(() {
      _inputController.clear();
      _outputController.clear();
    });
  }

  Future<void> _paste() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null) return;
    _inputController.text = data.text!;
  }

  Future<void> _copy() async {
    if (_outputController.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _outputController.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('sqlfmt_copied'))),
    );
  }

  void _swap() {
    final String tmp = _inputController.text;
    _inputController.text = _outputController.text;
    _outputController.text = tmp;
  }

  Widget _optSwitch(
      String key,
      bool value,
      ValueChanged<bool> onChanged,
      ) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(context.t(key)),
      value: value,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('sqlfmt_title')),
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
                    context.t('sqlfmt_input_hint'),
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
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton(
                    onPressed: _format,
                    child: Text(context.t('sqlfmt_format')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _minify,
                    child: Text(context.t('sqlfmt_minify')),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _swap,
                  icon: const Icon(Icons.swap_vert),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _optSwitch('sqlfmt_uppercase', _uppercase, (bool v) {
              setState(() => _uppercase = v);
            }),
            _optSwitch(
              'sqlfmt_newline_major',
              _newlineBeforeMajor,
                  (bool v) {
                setState(() => _newlineBeforeMajor = v);
              },
            ),
            _optSwitch(
              'sqlfmt_newline_and',
              _newlineBeforeAnd,
                  (bool v) {
                setState(() => _newlineBeforeAnd = v);
              },
            ),
            _optSwitch('sqlfmt_indent', _indentColumns, (bool v) {
              setState(() => _indentColumns = v);
            }),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    context.t('sqlfmt_output_hint'),
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
              minLines: 8,
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