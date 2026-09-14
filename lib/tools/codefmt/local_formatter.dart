import 'dart:convert';

import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;
import 'package:xml/xml.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';

import 'models.dart';

class LocalFormatter {
  LocalFormatter._();

  static FormatResult format(
      String input,
      CodeLanguage language,
      FormatOptions options,
      ) {
    final String trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const FormatResult(errorKey: 'codefmt_error_empty');
    }

    final Stopwatch sw = Stopwatch()..start();

    try {
      String output;
      switch (language) {
        case CodeLanguage.json:
          output = _formatJson(trimmed, options);
          break;
        case CodeLanguage.xml:
          output = _formatXml(trimmed, options);
          break;
        case CodeLanguage.html:
          output = _formatHtml(trimmed, options);
          break;
        case CodeLanguage.yaml:
          output = _formatYaml(trimmed, options);
          break;
        case CodeLanguage.sql:
          output = _formatSql(trimmed, options);
          break;
        case CodeLanguage.css:
          output = _formatCss(trimmed, options);
          break;
        case CodeLanguage.javascript:
        case CodeLanguage.typescript:
          return const FormatResult(
            errorKey: 'codefmt_error_remote_not_supported',
          );
      }
      sw.stop();
      return FormatResult(output: output, durationMs: sw.elapsedMilliseconds);
    } on FormatException catch (e) {
      sw.stop();
      return FormatResult(
        errorKey: 'codefmt_error_format',
        errorDetail: e.message,
        durationMs: sw.elapsedMilliseconds,
      );
    } catch (e) {
      sw.stop();
      return FormatResult(
        errorKey: 'codefmt_error_unknown',
        errorDetail: e.toString(),
        durationMs: sw.elapsedMilliseconds,
      );
    }
  }

  // ---------------- JSON ----------------

  static String _formatJson(String input, FormatOptions opts) {
    final dynamic decoded = jsonDecode(input);

    if (opts.minify) {
      return jsonEncode(decoded);
    }

    final dynamic prepared = opts.sortKeys ? _sortJsonKeys(decoded) : decoded;
    return _encodeJson(prepared, opts.indentUnit);
  }

  static dynamic _sortJsonKeys(dynamic value) {
    if (value is Map) {
      final List<String> keys = value.keys.map((dynamic k) => '$k').toList()
        ..sort();
      final Map<String, dynamic> sorted = <String, dynamic>{};
      for (final String k in keys) {
        sorted[k] = _sortJsonKeys(value[k]);
      }
      return sorted;
    }
    if (value is List) {
      return value.map(_sortJsonKeys).toList();
    }
    return value;
  }

  static String _encodeJson(dynamic value, String indentUnit) {
    final StringBuffer sb = StringBuffer();
    _writeJsonValue(sb, value, 0, indentUnit);
    return sb.toString();
  }

  static void _writeJsonValue(
      StringBuffer sb,
      dynamic value,
      int depth,
      String indentUnit,
      ) {
    if (value == null) {
      sb.write('null');
      return;
    }
    if (value is bool || value is num) {
      sb.write(value.toString());
      return;
    }
    if (value is String) {
      sb.write(jsonEncode(value));
      return;
    }
    if (value is List) {
      if (value.isEmpty) {
        sb.write('[]');
        return;
      }
      sb.write('[\n');
      for (int i = 0; i < value.length; i++) {
        sb.write(indentUnit * (depth + 1));
        _writeJsonValue(sb, value[i], depth + 1, indentUnit);
        if (i < value.length - 1) sb.write(',');
        sb.write('\n');
      }
      sb.write(indentUnit * depth);
      sb.write(']');
      return;
    }
    if (value is Map) {
      if (value.isEmpty) {
        sb.write('{}');
        return;
      }
      sb.write('{\n');
      final List<dynamic> keys = value.keys.toList();
      for (int i = 0; i < keys.length; i++) {
        final dynamic k = keys[i];
        sb.write(indentUnit * (depth + 1));
        sb.write(jsonEncode('$k'));
        sb.write(': ');
        _writeJsonValue(sb, value[k], depth + 1, indentUnit);
        if (i < keys.length - 1) sb.write(',');
        sb.write('\n');
      }
      sb.write(indentUnit * depth);
      sb.write('}');
      return;
    }
    sb.write(jsonEncode('$value'));
  }

  // ---------------- XML ----------------

  static String _formatXml(String input, FormatOptions opts) {
    final XmlDocument doc = XmlDocument.parse(input);
    final String raw = doc.toXmlString(
      pretty: !opts.minify,
      indent: opts.indentUnit,
    );
    return raw;
  }

  // ---------------- HTML ----------------

  static String _formatHtml(String input, FormatOptions opts) {
    final html_dom.Document doc = html_parser.parse(input);

    if (opts.minify) {
      return _minifyHtml(doc);
    }

    final StringBuffer sb = StringBuffer();
    for (final html_dom.Node node in doc.nodes) {
      _writeHtmlNode(sb, node, 0, opts);
    }
    return sb.toString().trim();
  }

  static void _writeHtmlNode(
      StringBuffer sb,
      html_dom.Node node,
      int depth,
      FormatOptions opts,
      ) {
    final String indent = opts.indentUnit * depth;

    if (node is html_dom.Text) {
      final String t = node.text.trim();
      if (t.isEmpty) return;
      sb.write(indent);
      sb.write(t);
      sb.write('\n');
      return;
    }

    if (node is html_dom.Comment) {
      sb.write(indent);
      sb.write('<!--');
      sb.write(node.data);
      sb.write('-->\n');
      return;
    }

    if (node is html_dom.Element) {
      sb.write(indent);
      sb.write('<');
      sb.write(node.localName);

      for (final MapEntry<Object, String> a in node.attributes.entries) {
        sb.write(' ');
        sb.write(a.key.toString());
        sb.write('="');
        sb.write(a.value.replaceAll('"', '&quot;'));
        sb.write('"');
      }

      final List<html_dom.Node> children = node.nodes
          .where((html_dom.Node n) {
        if (n is html_dom.Text) return n.text.trim().isNotEmpty;
        return true;
      })
          .toList();

      if (children.isEmpty) {
        sb.write('></');
        sb.write(node.localName);
        sb.write('>\n');
        return;
      }

      final bool singleTextChild =
          children.length == 1 && children.first is html_dom.Text;

      if (singleTextChild) {
        sb.write('>');
        sb.write((children.first as html_dom.Text).text.trim());
        sb.write('</');
        sb.write(node.localName);
        sb.write('>\n');
        return;
      }

      sb.write('>\n');
      for (final html_dom.Node child in children) {
        _writeHtmlNode(sb, child, depth + 1, opts);
      }
      sb.write(indent);
      sb.write('</');
      sb.write(node.localName);
      sb.write('>\n');
    }
  }

  static String _minifyHtml(html_dom.Document doc) {
    final StringBuffer sb = StringBuffer();
    for (final html_dom.Node node in doc.nodes) {
      _writeMinifiedNode(sb, node);
    }
    return sb.toString();
  }

  static void _writeMinifiedNode(StringBuffer sb, html_dom.Node node) {
    if (node is html_dom.Text) {
      final String t = node.text.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (t.isEmpty) return;
      sb.write(t);
      return;
    }
    if (node is html_dom.Comment) return;
    if (node is html_dom.Element) {
      sb.write('<');
      sb.write(node.localName);
      for (final MapEntry<Object, String> a in node.attributes.entries) {
        sb.write(' ');
        sb.write(a.key.toString());
        sb.write('="');
        sb.write(a.value.replaceAll('"', '&quot;'));
        sb.write('"');
      }
      sb.write('>');
      for (final html_dom.Node child in node.nodes) {
        _writeMinifiedNode(sb, child);
      }
      sb.write('</');
      sb.write(node.localName);
      sb.write('>');
    }
  }

  // ---------------- YAML ----------------

  static String _formatYaml(String input, FormatOptions opts) {
    final dynamic decoded = loadYaml(input);
    if (decoded == null) return '';

    if (opts.minify) {
      return jsonEncode(_yamlToPlain(decoded));
    }

    final YamlWriter writer = YamlWriter();
    return writer.write(_yamlToPlain(decoded));
  }

  static dynamic _yamlToPlain(dynamic value) {
    if (value is YamlMap) {
      final Map<String, dynamic> map = <String, dynamic>{};
      for (final dynamic k in value.keys) {
        map['$k'] = _yamlToPlain(value[k]);
      }
      return map;
    }
    if (value is YamlList) {
      return value.map(_yamlToPlain).toList();
    }
    return value;
  }

  // ---------------- SQL ----------------

  static String _formatSql(String input, FormatOptions opts) {
    if (opts.minify) {
      return input
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(RegExp(r'\s*,\s*'), ',')
          .replaceAll(RegExp(r'\s*\(\s*'), '(')
          .replaceAll(RegExp(r'\s*\)\s*'), ')')
          .trim();
    }

    final List<String> tokens = _tokenizeSql(input);
    final StringBuffer sb = StringBuffer();
    int indent = 0;
    final String u = opts.indentUnit;

    const Set<String> newlineBefore = <String>{
      'select', 'from', 'where', 'group', 'having', 'order', 'limit',
      'offset', 'union', 'insert', 'update', 'delete', 'values', 'set',
      'join', 'inner', 'left', 'right', 'full', 'cross', 'on', 'and', 'or',
    };

    const Set<String> selectClauses = <String>{
      'from', 'where', 'group', 'having', 'order', 'limit', 'offset',
      'union',
    };

    for (int i = 0; i < tokens.length; i++) {
      final String tok = tokens[i];
      final String lower = tok.toLowerCase();

      if (lower == '(') {
        sb.write('(');
        indent++;
        continue;
      }
      if (lower == ')') {
        indent--;
        sb.write(')');
        continue;
      }
      if (lower == ',') {
        sb.write(',');
        sb.write('\n');
        sb.write(u * indent);
        continue;
      }

      if (newlineBefore.contains(lower)) {
        if (sb.isNotEmpty && !sb.toString().endsWith('\n')) {
          sb.write('\n');
        }
        if (selectClauses.contains(lower) || lower == 'union') {
          indent = 0;
        } else if (lower == 'on' || lower == 'and' || lower == 'or') {
          indent = 1;
        } else {
          indent = 1;
        }
        sb.write(u * indent);
        sb.write(tok.toUpperCase());
        continue;
      }

      if (sb.isNotEmpty && !sb.toString().endsWith('\n') &&
          !sb.toString().endsWith('(') && !sb.toString().endsWith(' ')) {
        sb.write(' ');
      }
      sb.write(tok);
    }

    return sb.toString().trim();
  }

  static List<String> _tokenizeSql(String input) {
    final List<String> tokens = <String>[];
    final StringBuffer cur = StringBuffer();
    bool inSingle = false;
    bool inDouble = false;

    for (int i = 0; i < input.length; i++) {
      final String ch = input[i];

      if (inSingle) {
        cur.write(ch);
        if (ch == "'") inSingle = false;
        continue;
      }
      if (inDouble) {
        cur.write(ch);
        if (ch == '"') inDouble = false;
        continue;
      }

      if (ch == "'") {
        inSingle = true;
        cur.write(ch);
        continue;
      }
      if (ch == '"') {
        inDouble = true;
        cur.write(ch);
        continue;
      }
      if (ch == '(' || ch == ')' || ch == ',') {
        if (cur.isNotEmpty) {
          tokens.add(cur.toString());
          cur.clear();
        }
        tokens.add(ch);
        continue;
      }
      if (RegExp(r'\s').hasMatch(ch)) {
        if (cur.isNotEmpty) {
          tokens.add(cur.toString());
          cur.clear();
        }
        continue;
      }
      cur.write(ch);
    }
    if (cur.isNotEmpty) tokens.add(cur.toString());
    return tokens;
  }

  // ---------------- CSS ----------------

  static String _formatCss(String input, FormatOptions opts) {
    if (opts.minify) {
      return input
          .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(RegExp(r'\s*{\s*'), '{')
          .replaceAll(RegExp(r'\s*}\s*'), '}')
          .replaceAll(RegExp(r'\s*:\s*'), ':')
          .replaceAll(RegExp(r'\s*;\s*'), ';')
          .replaceAll(RegExp(r'\s*,\s*'), ',')
          .replaceAll(RegExp(r';}'), '}')
          .trim();
    }

    final StringBuffer sb = StringBuffer();
    int depth = 0;
    final String u = opts.indentUnit;
    final StringBuffer cur = StringBuffer();
    bool inComment = false;
    bool inString = false;
    String stringChar = '';

    void flush() {
      final String t = cur.toString().trim();
      cur.clear();
      if (t.isEmpty) return;
      sb.write(u * depth);
      sb.write(t);
      sb.write('\n');
    }

    for (int i = 0; i < input.length; i++) {
      final String ch = input[i];

      if (inComment) {
        if (ch == '*' && i + 1 < input.length && input[i + 1] == '/') {
          cur.write('*/');
          i++;
          inComment = false;
          sb.write(u * depth);
          sb.write(cur.toString().trim());
          sb.write('\n');
          cur.clear();
        } else {
          cur.write(ch);
        }
        continue;
      }

      if (inString) {
        cur.write(ch);
        if (ch == stringChar) inString = false;
        continue;
      }

      if (ch == '/' && i + 1 < input.length && input[i + 1] == '*') {
        flush();
        cur.write('/*');
        i++;
        inComment = true;
        continue;
      }

      if (ch == '"' || ch == "'") {
        inString = true;
        stringChar = ch;
        cur.write(ch);
        continue;
      }

      if (ch == '{') {
        flush();
        sb.write(u * depth);
        sb.write('{\n');
        depth++;
        continue;
      }

      if (ch == '}') {
        flush();
        if (depth > 0) depth--;
        sb.write(u * depth);
        sb.write('}\n');
        continue;
      }

      if (ch == ';') {
        cur.write(';');
        flush();
        continue;
      }

      cur.write(ch);
    }
    flush();

    return sb.toString().trim();
  }
}