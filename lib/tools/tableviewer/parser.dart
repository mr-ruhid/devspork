import 'dart:convert';

import 'models.dart';

class TableParser {
  TableParser._();

  static int _rowCounter = 0;

  static String _newRowId() {
    _rowCounter++;
    return 'row_${DateTime.now().microsecondsSinceEpoch}_$_rowCounter';
  }

  static int _colCounter = 0;

  static String _newColId() {
    _colCounter++;
    return 'col_${DateTime.now().microsecondsSinceEpoch}_$_colCounter';
  }

  static TableParseResult parse(
      String input,
      TableFormat format, {
        TableViewOptions? options,
      }) {
    final TableViewOptions opts = options ?? TableViewOptions();
    final String trimmed = input.trim();

    if (trimmed.isEmpty) {
      return TableParseResult(
        data: TableData.empty(),
        errorKey: 'tableviewer_error_empty',
      );
    }

    switch (format) {
      case TableFormat.csv:
        return _parseCsv(trimmed, ',', opts);
      case TableFormat.tsv:
        return _parseCsv(trimmed, '\t', opts);
      case TableFormat.json:
        return _parseJson(trimmed, opts);
      case TableFormat.markdown:
        return _parseMarkdown(trimmed, opts);
    }
  }

  // ---------------- CSV / TSV ----------------

  static TableParseResult _parseCsv(
      String input,
      String delimiter,
      TableViewOptions opts,
      ) {
    try {
      final List<List<String>> parsed = _tokenizeCsv(input, delimiter);

      if (parsed.isEmpty) {
        return TableParseResult(
          data: TableData.empty(),
          errorKey: 'tableviewer_error_empty',
        );
      }

      final List<String> header = parsed.first;
      final List<List<String>> body =
      parsed.length > 1 ? parsed.sublist(1) : <List<String>>[];

      if (header.isEmpty) {
        return TableParseResult(
          data: TableData.empty(),
          errorKey: 'tableviewer_error_empty_header',
        );
      }

      final int columnCount = header.length;
      final List<TableColumn> columns = <TableColumn>[];

      for (int i = 0; i < columnCount; i++) {
        final String name =
        header[i].isEmpty ? 'Column ${i + 1}' : header[i];
        columns.add(
          TableColumn(
            id: _newColId(),
            name: name,
            type: CellType.string,
          ),
        );
      }

      final List<TableRow> rows = <TableRow>[];
      for (int r = 0; r < body.length; r++) {
        final List<String> rawRow = body[r];
        final List<TableCell> cells = <TableCell>[];

        for (int c = 0; c < columnCount; c++) {
          final String v = c < rawRow.length ? rawRow[c] : '';
          if (opts.autoDetectTypes) {
            cells.add(TableCell.fromDynamic(v));
          } else {
            cells.add(TableCell(value: v, type: CellType.string));
          }
        }

        rows.add(
          TableRow(
            id: _newRowId(),
            cells: cells,
          ),
        );
      }

      if (opts.autoDetectTypes) {
        _updateColumnTypes(columns, rows);
      }

      return TableParseResult(
        data: TableData(columns: columns, rows: rows),
        rowCount: rows.length,
        columnCount: columns.length,
      );
    } catch (e) {
      return TableParseResult(
        data: TableData.empty(),
        errorKey: 'tableviewer_error_csv_parse',
        errorDetail: e.toString(),
      );
    }
  }

  static List<List<String>> _tokenizeCsv(
      String input,
      String delimiter,
      ) {
    final List<List<String>> rows = <List<String>>[];
    List<String> currentRow = <String>[];
    final StringBuffer currentField = StringBuffer();
    bool inQuotes = false;
    bool hasContent = false;

    int i = 0;
    while (i < input.length) {
      final String ch = input[i];

      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < input.length && input[i + 1] == '"') {
            currentField.write('"');
            i += 2;
            continue;
          }
          inQuotes = false;
          i++;
          continue;
        }
        currentField.write(ch);
        i++;
        continue;
      }

      if (ch == '"') {
        inQuotes = true;
        hasContent = true;
        i++;
        continue;
      }

      if (ch == delimiter) {
        currentRow.add(currentField.toString());
        currentField.clear();
        hasContent = false;
        i++;
        continue;
      }

      if (ch == '\r') {
        if (i + 1 < input.length && input[i + 1] == '\n') {
          i++;
        }
        currentRow.add(currentField.toString());
        currentField.clear();
        hasContent = false;
        if (currentRow.isNotEmpty ||
            (currentRow.length == 1 && currentRow[0].isNotEmpty)) {
          rows.add(currentRow);
        } else if (currentRow.length == 1 && currentRow[0].isEmpty) {
          rows.add(currentRow);
        }
        currentRow = <String>[];
        i++;
        continue;
      }

      if (ch == '\n') {
        currentRow.add(currentField.toString());
        currentField.clear();
        hasContent = false;
        if (currentRow.isNotEmpty) {
          rows.add(currentRow);
        }
        currentRow = <String>[];
        i++;
        continue;
      }

      currentField.write(ch);
      hasContent = true;
      i++;
    }

    if (hasContent || currentField.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentField.toString());
      rows.add(currentRow);
    }

    return rows.where((List<String> r) {
      if (r.length == 1 && r[0].isEmpty) return false;
      return true;
    }).toList();
  }

  // ---------------- JSON ----------------

  static TableParseResult _parseJson(
      String input,
      TableViewOptions opts,
      ) {
    dynamic decoded;
    try {
      decoded = jsonDecode(input);
    } catch (e) {
      return TableParseResult(
        data: TableData.empty(),
        errorKey: 'tableviewer_error_json_invalid',
        errorDetail: e.toString(),
      );
    }

    List<Map<String, dynamic>> objects = <Map<String, dynamic>>[];

    if (decoded is List) {
      for (final dynamic item in decoded) {
        if (item is Map<String, dynamic>) {
          objects.add(item);
        } else {
          objects.add(<String, dynamic>{'value': item});
        }
      }
    } else if (decoded is Map<String, dynamic>) {
      final Map<String, dynamic> map = decoded;

      final bool looksLikeWrapper = map.length == 1 &&
          map.values.first is List &&
          (map.keys.first == 'data' ||
              map.keys.first == 'items' ||
              map.keys.first == 'results' ||
              map.keys.first == 'rows');

      if (looksLikeWrapper) {
        final List<dynamic> list = map.values.first as List<dynamic>;
        for (final dynamic item in list) {
          if (item is Map<String, dynamic>) {
            objects.add(item);
          } else {
            objects.add(<String, dynamic>{'value': item});
          }
        }
      } else {
        objects.add(map);
      }
    } else {
      return TableParseResult(
        data: TableData.empty(),
        errorKey: 'tableviewer_error_json_root',
      );
    }

    if (objects.isEmpty) {
      return TableParseResult(
        data: TableData.empty(),
        errorKey: 'tableviewer_error_json_empty',
      );
    }

    Map<String, dynamic> flatSample = opts.flattenNested
        ? _flattenObject(objects.first, opts.flattenSeparator)
        : objects.first;

    final List<String> keys = <String>[];
    for (final Map<String, dynamic> obj in objects) {
      final Map<String, dynamic> flat = opts.flattenNested
          ? _flattenObject(obj, opts.flattenSeparator)
          : obj;
      for (final String k in flat.keys) {
        if (!keys.contains(k)) keys.add(k);
      }
    }

    if (keys.isEmpty) {
      return TableParseResult(
        data: TableData.empty(),
        errorKey: 'tableviewer_error_json_no_keys',
      );
    }

    final List<TableColumn> columns = keys
        .map(
          (String k) => TableColumn(
        id: _newColId(),
        name: k,
        type: _detectTypeFromSample(flatSample[k]),
      ),
    )
        .toList();

    final List<TableRow> rows = <TableRow>[];
    for (final Map<String, dynamic> obj in objects) {
      final Map<String, dynamic> flat = opts.flattenNested
          ? _flattenObject(obj, opts.flattenSeparator)
          : obj;

      final List<TableCell> cells = <TableCell>[];
      for (final TableColumn col in columns) {
        final dynamic v = flat[col.name];
        if (opts.autoDetectTypes) {
          cells.add(TableCell.fromDynamic(v));
        } else {
          cells.add(
            TableCell(
              value: v?.toString() ?? '',
              type: CellType.string,
            ),
          );
        }
      }

      rows.add(
        TableRow(
          id: _newRowId(),
          cells: cells,
        ),
      );
    }

    if (opts.autoDetectTypes) {
      _updateColumnTypes(columns, rows);
    }

    return TableParseResult(
      data: TableData(columns: columns, rows: rows),
      rowCount: rows.length,
      columnCount: columns.length,
    );
  }

  static Map<String, dynamic> _flattenObject(
      Map<String, dynamic> obj,
      String separator,
      ) {
    final Map<String, dynamic> result = <String, dynamic>{};

    void walk(String prefix, dynamic value) {
      if (value is Map<String, dynamic>) {
        for (final MapEntry<String, dynamic> e in value.entries) {
          final String key =
          prefix.isEmpty ? e.key : '$prefix$separator${e.key}';
          walk(key, e.value);
        }
      } else if (value is List) {
        result[prefix] = value;
      } else {
        result[prefix] = value;
      }
    }

    walk('', obj);
    return result;
  }

  static CellType _detectTypeFromSample(dynamic v) {
    if (v == null) return CellType.string;
    if (v is int) return CellType.integer;
    if (v is double) return CellType.double;
    if (v is bool) return CellType.boolean;
    if (v is Map) return CellType.object;
    if (v is List) return CellType.array;
    return CellType.string;
  }

  static void _updateColumnTypes(
      List<TableColumn> columns,
      List<TableRow> rows,
      ) {
    for (int c = 0; c < columns.length; c++) {
      final Set<CellType> types = <CellType>{};
      for (final TableRow r in rows) {
        if (c < r.cells.length) {
          types.add(r.cells[c].type);
        }
      }
      types.remove(CellType.nullValue);

      if (types.isEmpty) {
        columns[c].type = CellType.string;
      } else if (types.length == 1) {
        columns[c].type = types.first;
      } else if (types.contains(CellType.double) &&
          types.contains(CellType.integer) &&
          types.length == 2) {
        columns[c].type = CellType.double;
      } else {
        columns[c].type = CellType.string;
      }
    }
  }

  // ---------------- MARKDOWN ----------------

  static TableParseResult _parseMarkdown(
      String input,
      TableViewOptions opts,
      ) {
    final List<String> lines = input.split('\n');
    final List<List<String>> parsed = <List<String>>[];

    bool headerSeen = false;
    bool separatorSkipped = false;

    for (final String raw in lines) {
      final String line = raw.trim();
      if (line.isEmpty) continue;
      if (!line.contains('|')) continue;

      if (!headerSeen) {
        headerSeen = true;
        parsed.add(_splitMarkdownRow(line));
        continue;
      }

      if (!separatorSkipped) {
        separatorSkipped = true;
        if (RegExp(r'^\|?\s*:?-+:?\s*(\|\s*:?-+:?\s*)*\|?$')
            .hasMatch(line)) {
          continue;
        }
      }

      parsed.add(_splitMarkdownRow(line));
    }

    if (parsed.isEmpty) {
      return TableParseResult(
        data: TableData.empty(),
        errorKey: 'tableviewer_error_markdown_empty',
      );
    }

    final List<String> header = parsed.first;
    final List<List<String>> body =
    parsed.length > 1 ? parsed.sublist(1) : <List<String>>[];

    final List<TableColumn> columns = <TableColumn>[];
    for (int i = 0; i < header.length; i++) {
      columns.add(
        TableColumn(
          id: _newColId(),
          name: header[i].isEmpty ? 'Column ${i + 1}' : header[i],
          type: CellType.string,
        ),
      );
    }

    final List<TableRow> rows = <TableRow>[];
    for (final List<String> rawRow in body) {
      final List<TableCell> cells = <TableCell>[];
      for (int c = 0; c < columns.length; c++) {
        final String v = c < rawRow.length ? rawRow[c] : '';
        if (opts.autoDetectTypes) {
          cells.add(TableCell.fromDynamic(v));
        } else {
          cells.add(TableCell(value: v, type: CellType.string));
        }
      }
      rows.add(TableRow(id: _newRowId(), cells: cells));
    }

    if (opts.autoDetectTypes) {
      _updateColumnTypes(columns, rows);
    }

    return TableParseResult(
      data: TableData(columns: columns, rows: rows),
      rowCount: rows.length,
      columnCount: columns.length,
    );
  }

  static List<String> _splitMarkdownRow(String line) {
    String work = line.trim();
    if (work.startsWith('|')) work = work.substring(1);
    if (work.endsWith('|')) work = work.substring(0, work.length - 1);

    final List<String> cells = <String>[];
    final StringBuffer buf = StringBuffer();
    bool escaped = false;

    for (int i = 0; i < work.length; i++) {
      final String ch = work[i];
      if (escaped) {
        buf.write(ch);
        escaped = false;
        continue;
      }
      if (ch == '\\') {
        escaped = true;
        continue;
      }
      if (ch == '|') {
        cells.add(buf.toString().trim());
        buf.clear();
        continue;
      }
      buf.write(ch);
    }
    cells.add(buf.toString().trim());
    return cells;
  }

  // ---------------- EXPORT ----------------

  static String export(
      TableData data,
      TableFormat format, {
        TableViewOptions? options,
      }) {
    final TableViewOptions opts = options ?? TableViewOptions();
    switch (format) {
      case TableFormat.csv:
        return _exportCsv(data, ',', opts);
      case TableFormat.tsv:
        return _exportCsv(data, '\t', opts);
      case TableFormat.json:
        return _exportJson(data, opts);
      case TableFormat.markdown:
        return _exportMarkdown(data, opts);
    }
  }

  static String _exportCsv(
      TableData data,
      String delimiter,
      TableViewOptions opts,
      ) {
    final StringBuffer sb = StringBuffer();

    if (opts.includeHeaderInCsv) {
      final List<String> header =
      data.columns.map((TableColumn c) => _csvEscape(c.name, delimiter)).toList();
      sb.writeln(header.join(delimiter));
    }

    for (final TableRow row in data.rows) {
      final List<String> cells = <String>[];
      for (int i = 0; i < data.columns.length; i++) {
        final String v =
        i < row.cells.length ? row.cells[i].displayValue : '';
        cells.add(_csvEscape(v, delimiter));
      }
      sb.writeln(cells.join(delimiter));
    }

    return sb.toString().trimRight();
  }

  static String _csvEscape(String value, String delimiter) {
    if (value.isEmpty) return '';
    final bool needsQuote = value.contains(delimiter) ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    if (!needsQuote) return value;
    return '"${value.replaceAll('"', '""')}"';
  }

  static String _exportJson(
      TableData data,
      TableViewOptions opts,
      ) {
    final List<Map<String, dynamic>> list = <Map<String, dynamic>>[];

    for (final TableRow row in data.rows) {
      final Map<String, dynamic> obj = <String, dynamic>{};
      for (int i = 0; i < data.columns.length; i++) {
        final TableColumn col = data.columns[i];
        if (i < row.cells.length) {
          obj[col.name] = row.cells[i].value;
        } else {
          obj[col.name] = null;
        }
      }
      list.add(obj);
    }

    return const JsonEncoder.withIndent('  ').convert(list);
  }

  static String _exportMarkdown(
      TableData data,
      TableViewOptions opts,
      ) {
    if (data.columns.isEmpty) return '';

    final StringBuffer sb = StringBuffer();

    sb.write('| ');
    sb.write(
      data.columns.map((TableColumn c) => c.name).join(' | '),
    );
    sb.writeln(' |');

    final String align = _markdownAlign(opts.markdownAlignment);
    sb.write('|');
    for (int i = 0; i < data.columns.length; i++) {
      sb.write(align);
      sb.write('|');
    }
    sb.writeln();

    for (final TableRow row in data.rows) {
      sb.write('| ');
      final List<String> cells = <String>[];
      for (int i = 0; i < data.columns.length; i++) {
        final String v =
        i < row.cells.length ? row.cells[i].displayValue : '';
        cells.add(_mdEscape(v));
      }
      sb.write(cells.join(' | '));
      sb.writeln(' |');
    }

    return sb.toString().trimRight();
  }

  static String _markdownAlign(String align) {
    switch (align) {
      case 'center':
        return ' :---: ';
      case 'right':
        return ' ---: ';
      default:
        return ' :--- ';
    }
  }

  static String _mdEscape(String v) {
    return v
        .replaceAll('|', '\\|')
        .replaceAll('\n', ' ')
        .replaceAll('\r', '');
  }

  // ---------------- UTILITIES ----------------

  static String newColumnId() => _newColId();
  static String newRowId() => _newRowId();
}