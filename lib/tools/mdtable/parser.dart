import 'dart:convert';

import 'models.dart';

class MdParseException implements Exception {
  MdParseException(this.errorKey, [this.detail]);

  final String errorKey;
  final String? detail;

  @override
  String toString() => detail == null ? errorKey : '$errorKey: $detail';
}

class MdTableParser {
  MdTableParser._();

  static MdTable parse(String input, ImportFormat format, ImportOptions options) {
    switch (format) {
      case ImportFormat.markdown:
        return parseMarkdown(input);
      case ImportFormat.csv:
        return parseCsv(input, delimiter: options.csvDelimiter ?? ',', hasHeader: options.csvHasHeader);
      case ImportFormat.tsv:
        return parseCsv(input, delimiter: '\t', hasHeader: options.csvHasHeader);
      case ImportFormat.json:
        return parseJson(input, flatten: options.flattenJson);
    }
  }

  static MdTable parseMarkdown(String input) {
    final String text = input.trim();
    if (text.isEmpty) {
      throw MdParseException(MdTableErrors.emptyInput);
    }

    final List<String> rawLines = const LineSplitter().convert(text);
    final List<String> lines = <String>[];
    for (final String line in rawLines) {
      if (line.trim().isEmpty) continue;
      if (!line.contains('|')) continue;
      lines.add(line);
    }

    if (lines.length < 2) {
      throw MdParseException(MdTableErrors.invalidMarkdown);
    }

    final List<String> headerCells = _splitRow(lines[0]);
    final List<String> separatorCells = _splitRow(lines[1]);

    if (separatorCells.length != headerCells.length) {
      throw MdParseException(
        MdTableErrors.invalidMarkdown,
        'Header has ${headerCells.length} columns, separator has ${separatorCells.length}',
      );
    }

    final bool separatorIsValid = separatorCells.every((String c) {
      final String t = c.trim();
      if (t.isEmpty) return false;
      final String stripped = t.replaceAll(':', '').replaceAll('-', '');
      return stripped.isEmpty;
    });
    if (!separatorIsValid) {
      throw MdParseException(MdTableErrors.invalidMarkdown, 'Invalid separator row');
    }

    final List<MdColumnAlign> aligns = separatorCells
        .map(MdColumnAlignX.fromMarker)
        .toList(growable: true);

    final List<List<String>> rows = <List<String>>[];
    for (int i = 2; i < lines.length; i++) {
      final List<String> cells = _splitRow(lines[i]);
      while (cells.length < headerCells.length) {
        cells.add('');
      }
      if (cells.length > headerCells.length) {
        cells.removeRange(headerCells.length, cells.length);
      }
      rows.add(cells);
    }

    final MdTable table = MdTable(
      headers: headerCells,
      rows: rows,
      aligns: aligns,
    );
    table.normalize();
    return table;
  }

  static List<String> _splitRow(String line) {
    String s = line.trim();
    if (s.startsWith('|')) s = s.substring(1);
    if (s.endsWith('|') && !s.endsWith('\\|')) s = s.substring(0, s.length - 1);

    final List<String> cells = <String>[];
    final StringBuffer buf = StringBuffer();
    bool escaped = false;

    for (int i = 0; i < s.length; i++) {
      final String ch = s[i];
      if (escaped) {
        if (ch == '|' || ch == '\\') {
          buf.write(ch);
        } else {
          buf.write('\\');
          buf.write(ch);
        }
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

    return cells.map(_unescapeCell).toList(growable: true);
  }

  static String _unescapeCell(String value) {
    return value
        .replaceAll('<br>', '\n')
        .replaceAll('<br/>', '\n')
        .replaceAll('<br />', '\n');
  }

  static MdTable parseCsv(
      String input, {
        required String delimiter,
        required bool hasHeader,
      }) {
    final String text = input.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    if (text.trim().isEmpty) {
      throw MdParseException(MdTableErrors.emptyInput);
    }

    final List<List<String>> matrix = _parseDelimited(text, delimiter);
    if (matrix.isEmpty) {
      throw MdParseException(MdTableErrors.invalidCsv);
    }

    final int colCount = matrix.map((List<String> r) => r.length).reduce((int a, int b) => a > b ? a : b);
    if (colCount == 0) {
      throw MdParseException(MdTableErrors.invalidCsv);
    }

    List<String> headers;
    List<List<String>> rows;

    if (hasHeader) {
      headers = List<String>.of(matrix.first);
      while (headers.length < colCount) {
        headers.add('Column ${headers.length + 1}');
      }
      rows = matrix.skip(1).map((List<String> r) {
        final List<String> row = List<String>.of(r);
        while (row.length < colCount) {
          row.add('');
        }
        return row;
      }).toList(growable: true);
    } else {
      headers = List<String>.generate(colCount, (int i) => 'Column ${i + 1}');
      rows = matrix.map((List<String> r) {
        final List<String> row = List<String>.of(r);
        while (row.length < colCount) {
          row.add('');
        }
        return row;
      }).toList(growable: true);
    }

    final MdTable table = MdTable(
      headers: headers,
      rows: rows,
      aligns: List<MdColumnAlign>.filled(headers.length, MdColumnAlign.none),
    );
    table.normalize();
    return table;
  }

  static List<List<String>> _parseDelimited(String text, String delimiter) {
    final List<List<String>> result = <List<String>>[];
    final List<String> currentRow = <String>[];
    final StringBuffer field = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < text.length; i++) {
      final String ch = text[i];

      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(ch);
        }
        continue;
      }

      if (ch == '"' && field.isEmpty) {
        inQuotes = true;
        continue;
      }

      if (ch == delimiter) {
        currentRow.add(field.toString());
        field.clear();
        continue;
      }

      if (ch == '\n') {
        currentRow.add(field.toString());
        field.clear();
        result.add(List<String>.of(currentRow));
        currentRow.clear();
        continue;
      }

      field.write(ch);
    }

    if (field.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(field.toString());
      result.add(List<String>.of(currentRow));
    }

    while (result.isNotEmpty && result.last.every((String c) => c.trim().isEmpty)) {
      result.removeLast();
    }

    return result;
  }

  static MdTable parseJson(String input, {required bool flatten}) {
    final String text = input.trim();
    if (text.isEmpty) {
      throw MdParseException(MdTableErrors.emptyInput);
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(text);
    } catch (e) {
      throw MdParseException(MdTableErrors.invalidJson, e.toString());
    }

    if (decoded is! List) {
      throw MdParseException(MdTableErrors.jsonNotArray);
    }
    if (decoded.isEmpty) {
      throw MdParseException(MdTableErrors.emptyInput);
    }

    final List<Map<String, dynamic>> objects = <Map<String, dynamic>>[];
    for (final dynamic item in decoded) {
      if (item is Map<String, dynamic>) {
        objects.add(item);
      } else if (item is Map) {
        objects.add(item.map((dynamic k, dynamic v) => MapEntry<String, dynamic>(k.toString(), v)));
      } else {
        objects.add(<String, dynamic>{'value': item});
      }
    }

    final List<String> columns = <String>[];
    final Set<String> seen = <String>{};
    for (final Map<String, dynamic> obj in objects) {
      final Map<String, dynamic> flat = flatten ? _flatten(obj) : obj;
      for (final String key in flat.keys) {
        if (seen.add(key)) columns.add(key);
      }
    }

    if (columns.isEmpty) {
      throw MdParseException(MdTableErrors.jsonNoColumns);
    }

    final List<List<String>> rows = objects.map((Map<String, dynamic> obj) {
      final Map<String, dynamic> flat = flatten ? _flatten(obj) : obj;
      return columns.map((String col) => _stringify(flat[col])).toList(growable: true);
    }).toList(growable: true);

    final MdTable table = MdTable(
      headers: columns,
      rows: rows,
      aligns: List<MdColumnAlign>.filled(columns.length, MdColumnAlign.none),
    );
    table.normalize();
    return table;
  }

  static Map<String, dynamic> _flatten(Map<String, dynamic> obj, [String prefix = '']) {
    final Map<String, dynamic> out = <String, dynamic>{};
    obj.forEach((String key, dynamic value) {
      final String path = prefix.isEmpty ? key : '$prefix.$key';
      if (value is Map) {
        out.addAll(_flatten(
          value.map((dynamic k, dynamic v) => MapEntry<String, dynamic>(k.toString(), v)),
          path,
        ));
      } else if (value is List) {
        out[path] = jsonEncode(value);
      } else {
        out[path] = value;
      }
    });
    return out;
  }

  static String _stringify(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    if (value is Map || value is List) return jsonEncode(value);
    return value.toString();
  }
}