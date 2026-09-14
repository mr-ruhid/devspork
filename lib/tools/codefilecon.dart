import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:xml/xml.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';
import '../core/localization/app_localization.dart';

enum ConvFormat {
  json,
  xml,
  yaml,
  csv,
  tsv,
  ini,
  properties,
  queryString,
  markdownTable,
  htmlTable,
}

class CodeFileCon extends StatefulWidget {
  const CodeFileCon({super.key});

  @override
  State<CodeFileCon> createState() => _CodeFileConState();
}

class _CodeFileConState extends State<CodeFileCon> {
  final TextEditingController _inputController = TextEditingController();

  static const Color _accentA = Color(0xFF7C4DFF);
  static const Color _accentB = Color(0xFF00E5FF);

  ConvFormat _from = ConvFormat.json;
  ConvFormat _to = ConvFormat.xml;
  bool _pretty = true;
  bool _justCopied = false;

  String _output = '';
  String? _errorKey;
  String? _errorDetail;

  Timer? _debounce;

  static const List<ConvFormat> _all = ConvFormat.values;

  @override
  void initState() {
    super.initState();
    _inputController.text = '''{
  "users": [
    {"id": 1, "name": "Ali", "email": "ali@example.com"},
    {"id": 2, "name": "Veli", "email": "veli@example.com"}
  ]
}''';
    _inputController.addListener(_onInputChanged);
    // Convert the seeded example immediately so the screen isn't empty.
    WidgetsBinding.instance.addPostFrameCallback((_) => _convert());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _inputController.removeListener(_onInputChanged);
    _inputController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (_inputController.text.trim().isEmpty) {
        if (_output.isNotEmpty || _errorKey != null) {
          setState(() {
            _output = '';
            _errorKey = null;
            _errorDetail = null;
          });
        }
        return;
      }
      _convert();
    });
  }

  String _fmtName(ConvFormat f) {
    return context.t('codefilecon_fmt_${f.name}');
  }

  void _convert() {
    final String input = _inputController.text;
    if (input.trim().isEmpty) {
      setState(() {
        _output = '';
        _errorKey = 'codefilecon_error_empty';
        _errorDetail = null;
      });
      return;
    }
    try {
      final dynamic data = _parseInput(input, _from);
      final String result = _serializeOutput(data, _to);
      setState(() {
        _output = result;
        _errorKey = null;
        _errorDetail = null;
      });
    } catch (e) {
      setState(() {
        _output = '';
        _errorKey = 'codefilecon_error_convert';
        _errorDetail = e.toString();
      });
    }
  }

  void _reconvertIfNeeded() {
    if (_output.isNotEmpty || _errorKey != null) {
      _convert();
    }
  }

  void _clear() {
    HapticFeedback.selectionClick();
    setState(() {
      _inputController.clear();
      _output = '';
      _errorKey = null;
      _errorDetail = null;
    });
  }

  void _swap() {
    if (_output.isEmpty) return;
    HapticFeedback.mediumImpact();
    final String tmp = _inputController.text;
    setState(() {
      _inputController.text = _output;
      _output = tmp;
      final ConvFormat t = _from;
      _from = _to;
      _to = t;
      _errorKey = null;
      _errorDetail = null;
    });
  }

  Future<void> _paste() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null || data.text!.isEmpty) return;
    HapticFeedback.selectionClick();
    _inputController.text = data.text!;
    setState(() {
      _errorKey = null;
      _errorDetail = null;
    });
    _convert();
  }

  Future<void> _copy() async {
    if (_output.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _output));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _justCopied = true);
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _justCopied = false);
    });
  }

  dynamic _parseInput(String input, ConvFormat format) {
    switch (format) {
      case ConvFormat.json:
        return json.decode(input);
      case ConvFormat.xml:
        return _parseXml(input);
      case ConvFormat.yaml:
        return _normalizeYaml(loadYaml(input));
      case ConvFormat.csv:
        return _parseDelimited(input, ',');
      case ConvFormat.tsv:
        return _parseDelimited(input, '\t');
      case ConvFormat.ini:
        return _parseIni(input);
      case ConvFormat.properties:
        return _parseProperties(input);
      case ConvFormat.queryString:
        return _parseQueryString(input);
      case ConvFormat.markdownTable:
        return _parseMdTable(input);
      case ConvFormat.htmlTable:
        return _parseHtmlTable(input);
    }
  }

  dynamic _parseXml(String input) {
    final XmlDocument doc = XmlDocument.parse(input);
    final dynamic map = _xmlToMap(doc.rootElement);
    return <String, dynamic>{doc.rootElement.name.local: map};
  }

  dynamic _xmlToMap(XmlElement element) {
    final Map<String, dynamic> result = <String, dynamic>{};
    for (final XmlAttribute a in element.attributes) {
      result['@${a.name.local}'] = a.value;
    }
    final List<XmlNode> children = element.children
        .where((XmlNode n) =>
    n is XmlElement || (n is XmlText && n.value.trim().isNotEmpty))
        .toList();
    if (children.isEmpty) {
      final String text = element.innerText.trim();
      if (result.isEmpty) return text;
      result['#text'] = text;
      return result;
    }
    final Map<String, List<dynamic>> grouped = <String, List<dynamic>>{};
    for (final XmlNode node in children) {
      if (node is XmlElement) {
        final String name = node.name.local;
        grouped.putIfAbsent(name, () => <dynamic>[]);
        grouped[name]!.add(_xmlToMap(node));
      }
    }
    grouped.forEach((String key, List<dynamic> list) {
      result[key] = list.length == 1 ? list.first : list;
    });
    final String directText = children
        .whereType<XmlText>()
        .map((XmlText t) => t.value.trim())
        .where((String s) => s.isNotEmpty)
        .join(' ');
    if (directText.isNotEmpty) result['#text'] = directText;
    return result;
  }

  dynamic _normalizeYaml(dynamic v) {
    if (v is YamlMap) {
      final Map<String, dynamic> map = <String, dynamic>{};
      v.nodes.forEach((dynamic k, dynamic node) {
        map[k.toString()] =
            _normalizeYaml(node is YamlNode ? node.value : node);
      });
      return map;
    }
    if (v is YamlList) {
      return v.nodes
          .map((dynamic n) => _normalizeYaml(n is YamlNode ? n.value : n))
          .toList();
    }
    if (v is YamlNode) return _normalizeYaml(v.value);
    if (v is Map) {
      final Map<String, dynamic> map = <String, dynamic>{};
      v.forEach((dynamic k, dynamic val) {
        map[k.toString()] = _normalizeYaml(val);
      });
      return map;
    }
    if (v is List) return v.map(_normalizeYaml).toList();
    return v;
  }

  dynamic _parseDelimited(String input, String sep) {
    final List<List<String>> rows = _parseDelimitedRows(input, sep);
    if (rows.isEmpty) return <dynamic>[];
    final List<String> headers = rows.first;
    final List<Map<String, String>> result = <Map<String, String>>[];
    for (int i = 1; i < rows.length; i++) {
      final List<String> row = rows[i];
      if (row.length == 1 && row.first.isEmpty) continue;
      final Map<String, String> m = <String, String>{};
      for (int j = 0; j < headers.length; j++) {
        m[headers[j]] = j < row.length ? row[j] : '';
      }
      result.add(m);
    }
    return result;
  }

  List<List<String>> _parseDelimitedRows(String s, String sep) {
    final List<List<String>> rows = <List<String>>[];
    List<String> current = <String>[];
    final StringBuffer field = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < s.length; i++) {
      final String ch = s[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < s.length && s[i + 1] == '"') {
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
        } else if (ch == sep) {
          current.add(field.toString());
          field.clear();
        } else if (ch == '\n') {
          current.add(field.toString());
          field.clear();
          rows.add(current);
          current = <String>[];
        } else if (ch == '\r') {
          continue;
        } else {
          field.write(ch);
        }
      }
    }
    if (field.isNotEmpty || current.isNotEmpty) {
      current.add(field.toString());
      rows.add(current);
    }
    return rows;
  }

  Map<String, dynamic> _parseIni(String input) {
    final Map<String, dynamic> result = <String, dynamic>{};
    Map<String, dynamic>? current;
    for (final String line in input.split('\n')) {
      final String t = line.trim();
      if (t.isEmpty || t.startsWith(';') || t.startsWith('#')) continue;
      if (t.startsWith('[') && t.endsWith(']')) {
        final String name = t.substring(1, t.length - 1).trim();
        final Map<String, dynamic> section = <String, dynamic>{};
        result[name] = section;
        current = section;
      } else {
        final int eq = t.indexOf('=');
        if (eq > 0) {
          final String k = t.substring(0, eq).trim();
          final String v = t.substring(eq + 1).trim();
          if (current != null) {
            current[k] = v;
          } else {
            result[k] = v;
          }
        }
      }
    }
    return result;
  }

  Map<String, dynamic> _parseProperties(String input) {
    final Map<String, dynamic> result = <String, dynamic>{};
    for (final String line in input.split('\n')) {
      final String t = line.trim();
      if (t.isEmpty || t.startsWith('#') || t.startsWith('!')) continue;
      final int eq = t.indexOf('=');
      if (eq > 0) {
        final String k = t.substring(0, eq).trim();
        final String v = t.substring(eq + 1).trim();
        result[k] = v;
      }
    }
    return result;
  }

  Map<String, String> _parseQueryString(String input) {
    String s = input.trim();
    if (s.startsWith('?')) s = s.substring(1);
    if (s.contains('://')) {
      s = Uri.parse(s).query;
    }
    return Uri.splitQueryString(s);
  }

  List<Map<String, String>> _parseMdTable(String input) {
    final List<String> lines = input
        .split('\n')
        .map((String l) => l.trim())
        .where((String l) => l.isNotEmpty)
        .toList();
    if (lines.length < 2) return <Map<String, String>>[];
    final List<String> headers = _mdSplitRow(lines.first);
    final List<Map<String, String>> result = <Map<String, String>>[];
    for (int i = 1; i < lines.length; i++) {
      final String l = lines[i];
      if (RegExp(r'^[\s\-:|]+$').hasMatch(l)) continue;
      final List<String> cells = _mdSplitRow(l);
      final Map<String, String> m = <String, String>{};
      for (int j = 0; j < headers.length; j++) {
        m[headers[j]] = j < cells.length ? cells[j] : '';
      }
      result.add(m);
    }
    return result;
  }

  List<String> _mdSplitRow(String line) {
    String s = line.trim();
    if (s.startsWith('|')) s = s.substring(1);
    if (s.endsWith('|')) s = s.substring(0, s.length - 1);
    return s.split('|').map((String c) => c.trim()).toList();
  }

  List<Map<String, String>> _parseHtmlTable(String input) {
    final dom.Document doc = html_parser.parse(input);
    final dom.Element? table = doc.querySelector('table');
    if (table == null) {
      throw Exception('No <table> element found');
    }
    final List<dom.Element> rows = table.querySelectorAll('tr');
    if (rows.isEmpty) return <Map<String, String>>[];
    List<String>? headers;
    final List<Map<String, String>> result = <Map<String, String>>[];
    for (int i = 0; i < rows.length; i++) {
      final List<String> cells = rows[i]
          .querySelectorAll('th, td')
          .map((dom.Element c) => c.text.trim())
          .toList();
      if (i == 0) {
        headers = cells;
      } else {
        final Map<String, String> m = <String, String>{};
        for (int j = 0; j < (headers?.length ?? 0); j++) {
          m[headers![j]] = j < cells.length ? cells[j] : '';
        }
        result.add(m);
      }
    }
    return result;
  }

  String _serializeOutput(dynamic data, ConvFormat format) {
    switch (format) {
      case ConvFormat.json:
        return _pretty
            ? const JsonEncoder.withIndent('  ').convert(data)
            : json.encode(data);
      case ConvFormat.xml:
        return _toXml(data);
      case ConvFormat.yaml:
        return YamlWriter().write(data).trimRight();
      case ConvFormat.csv:
        return _toDelimited(data, ',');
      case ConvFormat.tsv:
        return _toDelimited(data, '\t');
      case ConvFormat.ini:
        return _toIni(data);
      case ConvFormat.properties:
        return _toProperties(data);
      case ConvFormat.queryString:
        return _toQuery(data);
      case ConvFormat.markdownTable:
        return _toMdTable(data);
      case ConvFormat.htmlTable:
        return _toHtmlTable(data);
    }
  }

  String _toXml(dynamic data) {
    final XmlBuilder builder = XmlBuilder();
    if (data is Map && data.length == 1) {
      final String rootName = data.keys.first.toString();
      _buildXmlNode(builder, rootName, data[rootName]);
    } else if (data is Map) {
      builder.element(
        'root',
        nest: () {
          data.forEach((dynamic k, dynamic v) {
            _buildXmlNode(builder, k.toString(), v);
          });
        },
      );
    } else if (data is List) {
      builder.element(
        'root',
        nest: () {
          for (final dynamic item in data) {
            _buildXmlNode(builder, 'item', item);
          }
        },
      );
    } else {
      builder.element('root', nest: data?.toString() ?? '');
    }
    final XmlDocument doc = builder.buildDocument();
    return _pretty
        ? doc.toXmlString(pretty: true, indent: '  ')
        : doc.toXmlString();
  }

  void _buildXmlNode(XmlBuilder builder, String name, dynamic value) {
    final String safeName = _sanitizeXmlName(name);
    if (value is Map) {
      final Map<String, String> attributes = <String, String>{};
      final List<MapEntry<String, dynamic>> children =
      <MapEntry<String, dynamic>>[];
      value.forEach((dynamic k, dynamic v) {
        final String key = k.toString();
        if (key.startsWith('@')) {
          attributes[_sanitizeXmlName(key.substring(1))] = v.toString();
        } else {
          children.add(MapEntry<String, dynamic>(key, v));
        }
      });
      builder.element(
        safeName,
        attributes: attributes,
        nest: () {
          for (final MapEntry<String, dynamic> entry in children) {
            final String key = entry.key;
            final dynamic v = entry.value;
            if (key == '#text') {
              builder.text(v.toString());
            } else if (v is List) {
              for (final dynamic item in v) {
                _buildXmlNode(builder, key, item);
              }
            } else {
              _buildXmlNode(builder, key, v);
            }
          }
        },
      );
    } else if (value is List) {
      for (final dynamic item in value) {
        _buildXmlNode(builder, safeName, item);
      }
    } else {
      builder.element(safeName, nest: value?.toString() ?? '');
    }
  }

  String _sanitizeXmlName(String name) {
    String s = name.replaceAll(RegExp(r'[^A-Za-z0-9_\-.]'), '_');
    if (s.isEmpty) s = 'item';
    if (RegExp(r'^[0-9]').hasMatch(s)) s = 'x_$s';
    return s;
  }

  String _toDelimited(dynamic data, String sep) {
    final List<Map<String, dynamic>> rows = _asRows(data);
    if (rows.isEmpty) return '';
    final Set<String> headerSet = <String>{};
    for (final Map<String, dynamic> r in rows) {
      headerSet.addAll(r.keys);
    }
    final List<String> headers = headerSet.toList();
    final StringBuffer buffer = StringBuffer();
    buffer.writeln(headers.map(_escapeDelimited).join(sep));
    for (final Map<String, dynamic> r in rows) {
      buffer.writeln(
        headers
            .map((String h) => _escapeDelimited(r[h]?.toString() ?? ''))
            .join(sep),
      );
    }
    return buffer.toString().trimRight();
  }

  String _escapeDelimited(String s) {
    if (s.contains(',') ||
        s.contains('"') ||
        s.contains('\n') ||
        s.contains('\t')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  /// Serializes to INI using the same flatten strategy as [_toProperties],
  /// then groups by top-level key into `[section]` blocks. Unlike the
  /// previous implementation this never silently drops list values or
  /// data nested more than one level deep — every leaf value is written
  /// somewhere, using `key.sub = value` / `key.0 = value` dotted paths
  /// inside a section when the structure is deeper than INI natively
  /// supports.
  String _toIni(dynamic data) {
    if (data is! Map) {
      throw Exception('INI requires an object at root');
    }
    final Map<String, dynamic> flat = <String, dynamic>{};
    _flatten(data, '', flat);

    final Map<String, dynamic> globals = <String, dynamic>{};
    final Map<String, Map<String, dynamic>> sections =
    <String, Map<String, dynamic>>{};
    // Preserve top-level key order using the original map's key order.
    final List<String> topOrder =
    data.keys.map((dynamic k) => k.toString()).toList();

    flat.forEach((String key, dynamic value) {
      final int dot = key.indexOf('.');
      if (dot == -1) {
        globals[key] = value;
      } else {
        final String section = key.substring(0, dot);
        final String rest = key.substring(dot + 1);
        sections.putIfAbsent(section, () => <String, dynamic>{})[rest] =
            value;
      }
    });

    final StringBuffer buffer = StringBuffer();
    for (final String k in globals.keys) {
      buffer.writeln('$k = ${globals[k]}');
    }
    for (final String section in topOrder) {
      final Map<String, dynamic>? entries = sections[section];
      if (entries == null) continue;
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.writeln('[$section]');
      entries.forEach((String k, dynamic v) {
        buffer.writeln('$k = $v');
      });
    }
    return buffer.toString().trimRight();
  }

  String _toProperties(dynamic data) {
    final Map<String, dynamic> flat = <String, dynamic>{};
    _flatten(data, '', flat);
    final StringBuffer buffer = StringBuffer();
    flat.forEach((String k, dynamic v) {
      buffer.writeln('$k=$v');
    });
    return buffer.toString().trimRight();
  }

  void _flatten(dynamic data, String prefix, Map<String, dynamic> out) {
    if (data is Map) {
      data.forEach((dynamic k, dynamic v) {
        final String key = prefix.isEmpty ? k.toString() : '$prefix.$k';
        if (v is Map || v is List) {
          _flatten(v, key, out);
        } else {
          out[key] = v;
        }
      });
    } else if (data is List) {
      for (int i = 0; i < data.length; i++) {
        final String key = prefix.isEmpty ? '$i' : '$prefix.$i';
        final dynamic v = data[i];
        if (v is Map || v is List) {
          _flatten(v, key, out);
        } else {
          out[key] = v;
        }
      }
    } else {
      out[prefix] = data;
    }
  }

  String _toQuery(dynamic data) {
    if (data is! Map) {
      throw Exception('Query String requires an object at root');
    }
    final List<String> pairs = <String>[];
    data.forEach((dynamic k, dynamic v) {
      pairs.add(
        '${Uri.encodeQueryComponent(k.toString())}='
            '${Uri.encodeQueryComponent(v.toString())}',
      );
    });
    return pairs.join('&');
  }

  String _toMdTable(dynamic data) {
    final List<Map<String, dynamic>> rows = _asRows(data);
    if (rows.isEmpty) return '';
    final Set<String> headerSet = <String>{};
    for (final Map<String, dynamic> r in rows) {
      headerSet.addAll(r.keys);
    }
    final List<String> headers = headerSet.toList();
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('| ${headers.join(' | ')} |');
    buffer.writeln('| ${headers.map((String _) => '---').join(' | ')} |');
    for (final Map<String, dynamic> r in rows) {
      buffer.writeln(
        '| ${headers.map((String h) => r[h]?.toString() ?? '').join(' | ')} |',
      );
    }
    return buffer.toString().trimRight();
  }

  String _toHtmlTable(dynamic data) {
    final List<Map<String, dynamic>> rows = _asRows(data);
    final Set<String> headerSet = <String>{};
    for (final Map<String, dynamic> r in rows) {
      headerSet.addAll(r.keys);
    }
    final List<String> headers = headerSet.toList();
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('<table>');
    if (headers.isNotEmpty) {
      buffer.writeln('  <thead>');
      buffer.writeln('    <tr>');
      for (final String h in headers) {
        buffer.writeln('      <th>${_htmlEscape(h)}</th>');
      }
      buffer.writeln('    </tr>');
      buffer.writeln('  </thead>');
    }
    buffer.writeln('  <tbody>');
    for (final Map<String, dynamic> r in rows) {
      buffer.writeln('    <tr>');
      for (final String h in headers) {
        buffer.writeln('      <td>${_htmlEscape(r[h]?.toString() ?? '')}</td>');
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

  List<Map<String, dynamic>> _asRows(dynamic data) {
    if (data is List) {
      final List<Map<String, dynamic>> out = <Map<String, dynamic>>[];
      for (final dynamic item in data) {
        if (item is Map) {
          out.add(Map<String, dynamic>.from(item));
        } else {
          out.add(<String, dynamic>{'value': item});
        }
      }
      return out;
    }
    if (data is Map) {
      if (data.length == 1) {
        final dynamic v = data.values.first;
        if (v is List) {
          final List<Map<String, dynamic>> out = <Map<String, dynamic>>[];
          for (final dynamic item in v) {
            if (item is Map) {
              out.add(Map<String, dynamic>.from(item));
            } else {
              out.add(<String, dynamic>{'value': item});
            }
          }
          return out;
        }
      }
      return <Map<String, dynamic>>[Map<String, dynamic>.from(data)];
    }
    return <Map<String, dynamic>>[
      <String, dynamic>{'value': data},
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.t('codefilecon_title')),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF1B1035),
              Color(0xFF2A1550),
              Color(0xFF0F2A4A),
            ],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(top: -80, left: -60, child: _blurBlob(220, _accentA)),
            Positioned(bottom: -100, right: -60, child: _blurBlob(260, _accentB)),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _GlassCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                            child: _GlassDropdown(
                              label: context.t('codefilecon_from'),
                              value: _fmtName(_from),
                              onTap: () => _pickFormat(isFrom: true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: _output.isEmpty ? 0.35 : 1,
                            child: IgnorePointer(
                              ignoring: _output.isEmpty,
                              child: _GlassIconButton(
                                icon: Icons.swap_horiz,
                                onTap: _swap,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _GlassDropdown(
                              label: context.t('codefilecon_to'),
                              value: _fmtName(_to),
                              onTap: () => _pickFormat(isFrom: false),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  '${context.t('codefilecon_input')} · ${_fmtName(_from)}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              _GlassIconButton(icon: Icons.paste, onTap: _paste),
                              const SizedBox(width: 8),
                              _GlassIconButton(icon: Icons.clear, onTap: _clear),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _inputController,
                            maxLines: 10,
                            minLines: 6,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.black.withOpacity(0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: _accentA,
                                  width: 1.5,
                                ),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _inputController,
                              builder: (BuildContext context,
                                  TextEditingValue value, _) {
                                final String text = value.text;
                                return Text(
                                  '${text.length} · '
                                      '${text.isEmpty ? 0 : text.split('\n').length}'
                                      ' ${context.t('codefilecon_lines')}',
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _GlassCard(
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: _GlassPrimaryButton(
                              icon: Icons.sync_alt_rounded,
                              label: context.t('codefilecon_convert'),
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                _convert();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _pretty = !_pretty);
                              _reconvertIfNeeded();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: _pretty
                                    ? _accentA.withOpacity(0.25)
                                    : Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _pretty
                                      ? _accentA
                                      : Colors.white.withOpacity(0.15),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(
                                    _pretty
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    size: 16,
                                    color: _pretty ? _accentB : Colors.white54,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    context.t('codefilecon_pretty'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_errorKey != null) ...<Widget>[
                      const SizedBox(height: 16),
                      _GlassCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Icon(Icons.error_outline,
                                color: Color(0xFFFF8A8A), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    context.t(_errorKey!),
                                    style: const TextStyle(
                                      color: Color(0xFFFF8A8A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (_errorDetail != null) ...<Widget>[
                                    const SizedBox(height: 4),
                                    Text(
                                      _errorDetail!,
                                      style: const TextStyle(
                                        color: Color(0xFFFFBFBF),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  '${context.t('codefilecon_output')} · ${_fmtName(_to)}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              _GlassIconButton(
                                icon: _justCopied ? Icons.check : Icons.copy,
                                onTap: _copy,
                                highlighted: _justCopied,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(minHeight: 160),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: _output.isEmpty
                                ? Text(
                              context.t('codefilecon_output_empty'),
                              style:
                              const TextStyle(color: Colors.white38),
                            )
                                : SelectableText(
                              _output,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                height: 1.4,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
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

  Future<void> _pickFormat({required bool isFrom}) async {
    final ConvFormat? picked = await showModalBottomSheet<ConvFormat>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1035).withOpacity(0.9),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.15)),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _all.map((ConvFormat f) {
                    final bool selected = isFrom ? f == _from : f == _to;
                    return ListTile(
                      title: Text(
                        _fmtName(f),
                        style: TextStyle(
                          color: selected ? _accentB : Colors.white,
                          fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                      trailing: selected
                          ? const Icon(Icons.check, color: _accentB)
                          : null,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(ctx).pop(f);
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
      } else {
        _to = picked;
      }
    });
    _reconvertIfNeeded();
  }

  Widget _blurBlob(double size, Color color) {
    return IgnorePointer(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.35),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: highlighted
              ? Colors.greenAccent.withOpacity(0.25)
              : Colors.white.withOpacity(0.08),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                icon,
                size: 18,
                color: highlighted ? Colors.greenAccent : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassPrimaryButton extends StatelessWidget {
  const _GlassPrimaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[
                  _CodeFileConState._accentA,
                  _CodeFileConState._accentB,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassDropdown extends StatelessWidget {
  const _GlassDropdown({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
            const SizedBox(height: 2),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.expand_more, color: Colors.white54, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}