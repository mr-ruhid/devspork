import 'models.dart';

class MdTableGenerator {
  MdTableGenerator._();

  static String generate(MdTable table, TableOptions options) {
    if (table.headers.isEmpty) return '';

    final int cols = table.columnCount;
    final List<List<String>> matrix = <List<String>>[
      table.headers,
      ...table.rows,
    ];

    final List<List<String>> prepared = matrix.map((List<String> row) {
      final List<String> out = <String>[];
      for (int i = 0; i < cols; i++) {
        final String raw = i < row.length ? row[i] : '';
        out.add(_prepareCell(raw, options));
      }
      return out;
    }).toList(growable: false);

    final List<int> widths = List<int>.generate(cols, (int i) {
      int max = 3;
      for (final List<String> row in prepared) {
        final int len = _visualLength(row[i]);
        if (len > max) max = len;
      }
      return max;
    });

    final StringBuffer buffer = StringBuffer();

    buffer.writeln(_renderRow(prepared[0], widths, options));
    buffer.writeln(_renderSeparator(table.aligns, widths, cols, options));

    for (int r = 1; r < prepared.length; r++) {
      buffer.writeln(_renderRow(prepared[r], widths, options));
    }

    return buffer.toString().trimRight();
  }

  static String _prepareCell(String raw, TableOptions options) {
    String v = raw;
    if (options.trimCells) v = v.trim();
    v = v.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    v = v.replaceAll('\n', '<br>');
    if (options.escapePipes) {
      v = v.replaceAll('\\|', '\u0000');
      v = v.replaceAll('|', '\\|');
      v = v.replaceAll('\u0000', '\\|');
    }
    return v;
  }

  static int _visualLength(String cell) {
    int length = 0;
    for (int i = 0; i < cell.length; i++) {
      if (cell[i] == '\\' && i + 1 < cell.length && cell[i + 1] == '|') {
        length++;
        i++;
        continue;
      }
      length++;
    }
    return length;
  }

  static String _renderRow(
      List<String> cells,
      List<int> widths,
      TableOptions options,
      ) {
    final List<String> rendered = <String>[];
    for (int i = 0; i < cells.length; i++) {
      final String cell = cells[i];
      if (options.prettyPrint) {
        final int pad = widths[i] - _visualLength(cell);
        rendered.add('$cell${' ' * (pad < 0 ? 0 : pad)}');
      } else {
        rendered.add(cell);
      }
    }
    final String joined = rendered.join(' | ');
    if (options.outerPipes) {
      return '| $joined |';
    }
    return joined;
  }

  static String _renderSeparator(
      List<MdColumnAlign> aligns,
      List<int> widths,
      int cols,
      TableOptions options,
      ) {
    final List<String> cells = <String>[];
    for (int i = 0; i < cols; i++) {
      final MdColumnAlign align = i < aligns.length ? aligns[i] : MdColumnAlign.none;
      final int width = options.prettyPrint ? widths[i] : 3;
      cells.add(_alignMarker(align, width));
    }
    final String joined = cells.join(' | ');
    if (options.outerPipes) {
      return '| $joined |';
    }
    return joined;
  }

  static String _alignMarker(MdColumnAlign align, int width) {
    final int w = width < 3 ? 3 : width;
    switch (align) {
      case MdColumnAlign.none:
        return '-' * w;
      case MdColumnAlign.left:
        return ':${'-' * (w - 1)}';
      case MdColumnAlign.center:
        if (w < 5) return ':${'-' * (w - 2)}:';
        return ':${'-' * (w - 2)}:';
      case MdColumnAlign.right:
        return '${'-' * (w - 1)}:';
    }
  }

  static String generateCsv(MdTable table, {String delimiter = ','}) {
    if (table.headers.isEmpty) return '';
    final StringBuffer buffer = StringBuffer();
    buffer.writeln(table.headers.map((String c) => _csvCell(c, delimiter)).join(delimiter));
    for (final List<String> row in table.rows) {
      final List<String> cells = List<String>.generate(
        table.columnCount,
            (int i) => i < row.length ? row[i] : '',
      );
      buffer.writeln(cells.map((String c) => _csvCell(c, delimiter)).join(delimiter));
    }
    return buffer.toString().trimRight();
  }

  static String _csvCell(String value, String delimiter) {
    final bool needsQuote = value.contains(delimiter) ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    if (!needsQuote) return value;
    final String escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  static String generateJson(MdTable table, {bool pretty = true}) {
    if (table.headers.isEmpty) return '[]';
    final List<Map<String, String>> out = <Map<String, String>>[];
    for (final List<String> row in table.rows) {
      final Map<String, String> obj = <String, String>{};
      for (int i = 0; i < table.columnCount; i++) {
        obj[table.headers[i]] = i < row.length ? row[i] : '';
      }
      out.add(obj);
    }
    if (pretty) {
      return _prettyJson(out);
    }
    return _compactJson(out);
  }

  static String _compactJson(List<Map<String, String>> data) {
    final StringBuffer buffer = StringBuffer('[');
    for (int i = 0; i < data.length; i++) {
      if (i > 0) buffer.write(',');
      buffer.write('{');
      int j = 0;
      data[i].forEach((String k, String v) {
        if (j > 0) buffer.write(',');
        buffer.write('${_jsonString(k)}:${_jsonString(v)}');
        j++;
      });
      buffer.write('}');
    }
    buffer.write(']');
    return buffer.toString();
  }

  static String _prettyJson(List<Map<String, String>> data) {
    if (data.isEmpty) return '[]';
    final StringBuffer buffer = StringBuffer('[\n');
    for (int i = 0; i < data.length; i++) {
      buffer.write('  {\n');
      int j = 0;
      data[i].forEach((String k, String v) {
        buffer.write('    ${_jsonString(k)}: ${_jsonString(v)}');
        if (j < data[i].length - 1) buffer.write(',');
        buffer.write('\n');
        j++;
      });
      buffer.write('  }');
      if (i < data.length - 1) buffer.write(',');
      buffer.write('\n');
    }
    buffer.write(']');
    return buffer.toString();
  }

  static String _jsonString(String value) {
    final StringBuffer buffer = StringBuffer('"');
    for (int i = 0; i < value.length; i++) {
      final String ch = value[i];
      final int code = ch.codeUnitAt(0);
      switch (ch) {
        case '"':
          buffer.write('\\"');
          break;
        case '\\':
          buffer.write('\\\\');
          break;
        case '\n':
          buffer.write('\\n');
          break;
        case '\r':
          buffer.write('\\r');
          break;
        case '\t':
          buffer.write('\\t');
          break;
        case '\b':
          buffer.write('\\b');
          break;
        case '\f':
          buffer.write('\\f');
          break;
        default:
          if (code < 0x20) {
            buffer.write('\\u${code.toRadixString(16).padLeft(4, '0')}');
          } else {
            buffer.write(ch);
          }
      }
    }
    buffer.write('"');
    return buffer.toString();
  }
}