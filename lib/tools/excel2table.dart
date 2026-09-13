import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class Excel2Table extends StatefulWidget {
  const Excel2Table({super.key});

  @override
  State<Excel2Table> createState() => _Excel2TableState();
}

class _Excel2TableState extends State<Excel2Table> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();

  String _inputSep = 'tab';
  String _outputFormat = 'markdown';
  String _alignment = 'left';

  bool _firstRowHeader = true;
  bool _trimCells = true;
  bool _removeEmptyRows = true;
  bool _removeEmptyCols = false;
  bool _padColumns = true;
  bool _htmlBorder = true;
  bool _htmlClass = false;

  String? _errorKey;

  static const List<String> _seps = <String>[
    'tab',
    'comma',
    'semicolon',
    'pipe',
    'space',
  ];

  static const List<String> _alignments = <String>[
    'left',
    'center',
    'right',
  ];

  @override
  void initState() {
    super.initState();
    _inputController.text =
    'Ad\tSoyad\tYaş\tŞəhər\n'
        'Ali\tMəmmədov\t28\tBakı\n'
        'Vəli\tƏliyev\t34\tGəncə\n'
        'Aysel\tHüseynova\t22\tSumqayıt';
    _convert();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  String _sepChar() {
    switch (_inputSep) {
      case 'comma':
        return ',';
      case 'semicolon':
        return ';';
      case 'pipe':
        return '|';
      case 'space':
        return ' ';
      case 'tab':
      default:
        return '\t';
    }
  }

  List<List<String>> _parseRows(String input) {
    final String sep = _sepChar();
    final List<List<String>> rows = <List<String>>[];
    for (final String line in input.split('\n')) {
      if (line.isEmpty) {
        if (!_removeEmptyRows) rows.add(<String>['']);
        continue;
      }
      final List<String> cells = _splitLine(line, sep);
      List<String> processed = cells;
      if (_trimCells) {
        processed = cells.map((String c) => c.trim()).toList();
      }
      if (_removeEmptyRows &&
          processed.every((String c) => c.isEmpty)) {
        continue;
      }
      rows.add(processed);
    }
    if (_removeEmptyCols && rows.isNotEmpty) {
      final int maxCols =
      rows.map((List<String> r) => r.length).reduce((int a, int b) => a > b ? a : b);
      final List<int> keep = <int>[];
      for (int c = 0; c < maxCols; c++) {
        final bool allEmpty = rows.every((List<String> r) =>
        c >= r.length || r[c].isEmpty);
        if (!allEmpty) keep.add(c);
      }
      for (int i = 0; i < rows.length; i++) {
        rows[i] = keep.map((int c) =>
        c < rows[i].length ? rows[i][c] : '').toList();
      }
    }
    final int maxCols = rows.isEmpty
        ? 0
        : rows.map((List<String> r) => r.length).reduce((int a, int b) => a > b ? a : b);
    for (int i = 0; i < rows.length; i++) {
      while (rows[i].length < maxCols) {
        rows[i].add('');
      }
    }
    return rows;
  }

  List<String> _splitLine(String line, String sep) {
    final List<String> result = <String>[];
    final StringBuffer field = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < line.length; i++) {
      final String ch = line[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < line.length && line[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(ch);
        }
      } else {
        if (ch == '"') {
          inQuotes = true;
        } else if (ch == sep && sep != ' ') {
          result.add(field.toString());
          field.clear();
        } else if (sep == ' ' && (ch == ' ' || ch == '\t')) {
          result.add(field.toString());
          field.clear();
        } else {
          field.write(ch);
        }
      }
    }
    result.add(field.toString());
    return result;
  }

  String _buildMarkdown(List<List<String>> rows) {
    if (rows.isEmpty) return '';
    final int cols = rows.first.length;
    final List<int> widths = List<int>.filled(cols, 3);
    for (final List<String> r in rows) {
      for (int i = 0; i < cols && i < r.length; i++) {
        if (r[i].length > widths[i]) widths[i] = r[i].length;
      }
    }
    final StringBuffer buffer = StringBuffer();
    final List<String> headers =
    _firstRowHeader ? rows.first : List<String>.generate(cols, (int i) => 'Col ${i + 1}');
    final int dataStart = _firstRowHeader ? 1 : 0;

    buffer.writeln(_mdRow(headers, widths, isHeader: true));
    buffer.writeln(_mdSeparator(widths));

    for (int i = dataStart; i < rows.length; i++) {
      buffer.writeln(_mdRow(rows[i], widths));
    }
    return buffer.toString().trimRight();
  }

  String _mdRow(List<String> cells, List<int> widths,
      {bool isHeader = false}) {
    final List<String> parts = <String>[];
    for (int i = 0; i < widths.length; i++) {
      final String v = i < cells.length ? cells[i] : '';
      parts.add(_pad(v, widths[i], _alignment));
    }
    return '| ${parts.join(' | ')} |';
  }

  String _mdSeparator(List<int> widths) {
    final List<String> parts = <String>[];
    for (final int w in widths) {
      final String dashes = '-' * (w < 3 ? 3 : w);
      switch (_alignment) {
        case 'center':
          parts.add(':$dashes:');
          break;
        case 'right':
          parts.add('$dashes:');
          break;
        case 'left':
        default:
          parts.add(':$dashes');
          break;
      }
    }
    return '| ${parts.join(' | ')} |';
  }

  String _pad(String s, int width, String align) {
    if (!_padColumns) return s;
    if (s.length >= width) return s;
    final int diff = width - s.length;
    switch (align) {
      case 'center':
        final int l = diff ~/ 2;
        final int r = diff - l;
        return '${' ' * l}$s${' ' * r}';
      case 'right':
        return '${' ' * diff}$s';
      case 'left':
      default:
        return '$s${' ' * diff}';
    }
  }

  String _buildHtml(List<List<String>> rows) {
    if (rows.isEmpty) return '';
    final int cols = rows.first.length;
    final StringBuffer buffer = StringBuffer();
    final String alignAttr = _alignment == 'left' ? '' : ' align="$_alignment"';
    final String borderAttr = _htmlBorder ? ' border="1"' : '';
    final String classAttr =
    _htmlClass ? ' class="data-table"' : '';
    buffer.writeln('<table$borderAttr$classAttr>');

    final List<String> headers = _firstRowHeader
        ? rows.first
        : List<String>.generate(cols, (int i) => 'Col ${i + 1}');
    final int dataStart = _firstRowHeader ? 1 : 0;

    buffer.writeln('  <thead>');
    buffer.writeln('    <tr>');
    for (final String h in headers) {
      buffer.writeln('      <th$alignAttr>${_htmlEscape(h)}</th>');
    }
    buffer.writeln('    </tr>');
    buffer.writeln('  </thead>');
    buffer.writeln('  <tbody>');
    for (int i = dataStart; i < rows.length; i++) {
      buffer.writeln('    <tr>');
      for (int j = 0; j < cols; j++) {
        final String v = j < rows[i].length ? rows[i][j] : '';
        buffer.writeln('      <td$alignAttr>${_htmlEscape(v)}</td>');
      }
      buffer.writeln('    </tr>');
    }
    buffer.writeln('  </tbody>');
    buffer.writeln('</table>');
    return buffer.toString().trimRight();
  }

  String _htmlEscape(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }

  void _convert() {
    final String input = _inputController.text;
    if (input.trim().isEmpty) {
      setState(() {
        _outputController.text = '';
        _errorKey = 'excel2table_error_empty';
      });
      return;
    }
    try {
      final List<List<String>> rows = _parseRows(input);
      if (rows.isEmpty) {
        setState(() {
          _outputController.text = '';
          _errorKey = 'excel2table_error_no_data';
        });
        return;
      }
      final String result = _outputFormat == 'markdown'
          ? _buildMarkdown(rows)
          : _buildHtml(rows);
      setState(() {
        _outputController.text = result;
        _errorKey = null;
      });
    } catch (e) {
      setState(() {
        _outputController.text = '';
        _errorKey = 'excel2table_error_convert';
      });
    }
  }

  void _clear() {
    setState(() {
      _inputController.clear();
      _outputController.clear();
      _errorKey = null;
    });
  }

  Future<void> _paste() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null) return;
    _inputController.text = data.text!;
    _convert();
  }

  Future<void> _copy() async {
    if (_outputController.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _outputController.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('excel2table_copied'))),
    );
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
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('excel2table_title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              context.t('excel2table_input_sep'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _seps.map((String s) {
                return ChoiceChip(
                  label: Text(context.t('excel2table_sep_$s')),
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
                    context.t('excel2table_input_hint'),
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
              maxLines: 8,
              minLines: 5,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              onChanged: (_) => _convert(),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.t('excel2table_output_format'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: <ButtonSegment<String>>[
                ButtonSegment<String>(
                  value: 'markdown',
                  label: Text(context.t('excel2table_fmt_md')),
                  icon: const Icon(Icons.code),
                ),
                ButtonSegment<String>(
                  value: 'html',
                  label: Text(context.t('excel2table_fmt_html')),
                  icon: const Icon(Icons.html),
                ),
              ],
              selected: <String>{_outputFormat},
              onSelectionChanged: (Set<String> s) {
                setState(() {
                  _outputFormat = s.first;
                });
                _convert();
              },
            ),
            const SizedBox(height: 12),
            Text(
              context.t('excel2table_alignment'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: _alignments.map((String a) {
                return ButtonSegment<String>(
                  value: a,
                  label: Text(context.t('excel2table_align_$a')),
                );
              }).toList(),
              selected: <String>{_alignment},
              onSelectionChanged: (Set<String> s) {
                setState(() {
                  _alignment = s.first;
                });
                _convert();
              },
            ),
            const SizedBox(height: 12),
            _optSwitch('excel2table_first_header', _firstRowHeader, (bool v) {
              setState(() => _firstRowHeader = v);
              _convert();
            }),
            _optSwitch('excel2table_trim', _trimCells, (bool v) {
              setState(() => _trimCells = v);
              _convert();
            }),
            _optSwitch('excel2table_remove_rows', _removeEmptyRows, (bool v) {
              setState(() => _removeEmptyRows = v);
              _convert();
            }),
            _optSwitch('excel2table_remove_cols', _removeEmptyCols, (bool v) {
              setState(() => _removeEmptyCols = v);
              _convert();
            }),
            if (_outputFormat == 'markdown')
              _optSwitch('excel2table_pad', _padColumns, (bool v) {
                setState(() => _padColumns = v);
                _convert();
              }),
            if (_outputFormat == 'html') ...<Widget>[
              _optSwitch('excel2table_html_border', _htmlBorder, (bool v) {
                setState(() => _htmlBorder = v);
                _convert();
              }),
              _optSwitch('excel2table_html_class', _htmlClass, (bool v) {
                setState(() => _htmlClass = v);
                _convert();
              }),
            ],
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    context.t('excel2table_output_hint'),
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
              minLines: 10,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            if (_errorKey != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  context.t(_errorKey!),
                  style: TextStyle(color: colors.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}