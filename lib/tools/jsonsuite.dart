import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_schema/json_schema.dart';
import '../core/localization/app_localization.dart';

class JsonSuite extends StatefulWidget {
  const JsonSuite({super.key});

  @override
  State<JsonSuite> createState() => _JsonSuiteState();
}

class _JsonSuiteState extends State<JsonSuite>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final TextEditingController _schemaInputController = TextEditingController();
  final TextEditingController _schemaOutputController = TextEditingController();
  final TextEditingController _codeInputController = TextEditingController();
  final TextEditingController _codeOutputController = TextEditingController();
  final TextEditingController _validJsonController = TextEditingController();
  final TextEditingController _validSchemaController = TextEditingController();
  final TextEditingController _classNameController =
  TextEditingController(text: 'MyModel');

  String get _className {
    final String t = _classNameController.text.trim();
    return t.isEmpty ? 'MyModel' : t;
  }

  static const Color _accentA = Color(0xFF7C4DFF);
  static const Color _accentB = Color(0xFF00E5FF);

  String _codeLang = 'dart';
  bool _nullSafety = true;
  bool _fromJsonMethod = true;
  bool _toJsonMethod = true;

  List<String> _validationErrors = <String>[];
  bool _validated = false;
  bool _validResult = false;
  String? _validationFatalError;

  String? _schemaErrorKey;
  String? _schemaErrorDetail;
  String? _codeErrorKey;
  String? _codeErrorDetail;

  static const List<String> _langs = <String>[
    'dart',
    'typescript',
    'python',
    'kotlin',
    'swift',
    'java',
    'csharp',
    'go',
  ];

  static const String _sampleJson = '''{
  "id": 1,
  "name": "Ali",
  "email": "ali@example.com",
  "isActive": true,
  "age": 28,
  "score": 95.5,
  "tags": ["flutter", "dart"],
  "address": {
    "city": "Bakı",
    "zip": "1000"
  }
}''';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _schemaInputController.text = _sampleJson;
    _codeInputController.text = _sampleJson;
    _validJsonController.text = _sampleJson;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _schemaInputController.dispose();
    _schemaOutputController.dispose();
    _codeInputController.dispose();
    _codeOutputController.dispose();
    _validJsonController.dispose();
    _validSchemaController.dispose();
    _classNameController.dispose();
    super.dispose();
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String _snakeToCamel(String s) {
    final List<String> parts = s.split(RegExp(r'[_\-\s]+'));
    if (parts.isEmpty) return s;
    return parts.first.toLowerCase() +
        parts
            .skip(1)
            .map((String p) => p.isEmpty
            ? p
            : p[0].toUpperCase() + p.substring(1).toLowerCase())
            .join();
  }

  Map<String, dynamic> _inferSchema(dynamic value) {
    if (value == null) {
      return <String, dynamic>{'type': 'null'};
    }
    if (value is bool) {
      return <String, dynamic>{'type': 'boolean'};
    }
    if (value is int) {
      return <String, dynamic>{'type': 'integer'};
    }
    if (value is double) {
      return <String, dynamic>{'type': 'number'};
    }
    if (value is String) {
      final Map<String, dynamic> s = <String, dynamic>{'type': 'string'};
      if (RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
        s['format'] = 'email';
      } else if (RegExp(r'^https?://').hasMatch(value)) {
        s['format'] = 'uri';
      } else if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
        s['format'] = 'date';
      } else if (RegExp(r'^\d{4}-\d{2}-\d{2}T').hasMatch(value)) {
        s['format'] = 'date-time';
      }
      return s;
    }
    if (value is List) {
      if (value.isEmpty) {
        return <String, dynamic>{
          'type': 'array',
          'items': <String, dynamic>{},
        };
      }
      final List<Map<String, dynamic>> schemas =
      value.map(_inferSchema).toList();
      final Map<String, dynamic> merged = _mergeSchemas(schemas);
      return <String, dynamic>{
        'type': 'array',
        'items': merged,
      };
    }
    if (value is Map) {
      final Map<String, dynamic> properties = <String, dynamic>{};
      final List<String> required = <String>[];
      value.forEach((dynamic k, dynamic v) {
        properties[k.toString()] = _inferSchema(v);
        if (v != null) required.add(k.toString());
      });
      return <String, dynamic>{
        'type': 'object',
        'properties': properties,
        if (required.isNotEmpty) 'required': required,
      };
    }
    return <String, dynamic>{'type': 'string'};
  }

  Map<String, dynamic> _mergeSchemas(List<Map<String, dynamic>> schemas) {
    if (schemas.isEmpty) return <String, dynamic>{};
    if (schemas.length == 1) return schemas.first;
    final Set<String> types = schemas
        .map((Map<String, dynamic> s) => s['type']?.toString() ?? '')
        .toSet();
    if (types.length == 1 && types.first == 'object') {
      final Map<String, dynamic> properties = <String, dynamic>{};
      final Set<String> required = <String>{};
      for (final Map<String, dynamic> s in schemas) {
        final Map<String, dynamic>? props =
        s['properties'] as Map<String, dynamic>?;
        if (props != null) {
          props.forEach((String k, dynamic v) {
            if (properties.containsKey(k)) {
              properties[k] = _mergeSchemas(<Map<String, dynamic>>[
                properties[k] as Map<String, dynamic>,
                v as Map<String, dynamic>,
              ]);
            } else {
              properties[k] = v;
            }
          });
        }
        final List<dynamic>? req = s['required'] as List<dynamic>?;
        if (req != null) required.addAll(req.map((dynamic e) => e.toString()));
      }
      return <String, dynamic>{
        'type': 'object',
        'properties': properties,
        if (required.isNotEmpty) 'required': required.toList(),
      };
    }
    if (types.length == 1 && types.first == 'array') {
      final List<Map<String, dynamic>> items = schemas
          .map((Map<String, dynamic> s) =>
      s['items'] as Map<String, dynamic>? ?? <String, dynamic>{})
          .toList();
      return <String, dynamic>{
        'type': 'array',
        'items': _mergeSchemas(items),
      };
    }
    return <String, dynamic>{
      'oneOf': schemas,
    };
  }

  void _generateSchema() {
    final String input = _schemaInputController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _schemaErrorKey = 'jsonsuite_error_empty';
        _schemaErrorDetail = null;
        _schemaOutputController.text = '';
      });
      return;
    }
    try {
      final dynamic data = json.decode(input);
      final Map<String, dynamic> schema = <String, dynamic>{
        r'$schema': 'http://json-schema.org/draft-07/schema#',
        'title': _className,
      };
      final Map<String, dynamic> rootSchema = _inferSchema(data);
      schema.addAll(rootSchema);
      setState(() {
        _schemaOutputController.text =
            const JsonEncoder.withIndent('  ').convert(schema);
        _schemaErrorKey = null;
        _schemaErrorDetail = null;
      });
    } catch (e) {
      setState(() {
        _schemaErrorKey = 'jsonsuite_error_invalid_json';
        _schemaErrorDetail = e.toString();
        _schemaOutputController.text = '';
      });
    }
  }

  String _dartType(dynamic value) {
    if (value == null) return 'dynamic';
    if (value is bool) return 'bool';
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is String) return 'String';
    if (value is List) {
      if (value.isEmpty) return 'List<dynamic>';
      final Set<String> types = value.map(_dartType).toSet();
      if (types.length == 1) return 'List<${types.first}>';
      return 'List<dynamic>';
    }
    if (value is Map) return 'Map<String, dynamic>';
    return 'dynamic';
  }

  String _tsType(dynamic value) {
    if (value == null) return 'any';
    if (value is bool) return 'boolean';
    if (value is int || value is double) return 'number';
    if (value is String) return 'string';
    if (value is List) {
      if (value.isEmpty) return 'any[]';
      final Set<String> types = value.map(_tsType).toSet();
      if (types.length == 1) return '${types.first}[]';
      return 'any[]';
    }
    if (value is Map) return 'Record<string, any>';
    return 'any';
  }

  String _pythonType(dynamic value) {
    if (value == null) return 'Optional[Any]';
    if (value is bool) return 'bool';
    if (value is int) return 'int';
    if (value is double) return 'float';
    if (value is String) return 'str';
    if (value is List) {
      if (value.isEmpty) return 'List[Any]';
      final Set<String> types = value.map(_pythonType).toSet();
      if (types.length == 1) return 'List[${types.first}]';
      return 'List[Any]';
    }
    if (value is Map) return 'Dict[str, Any]';
    return 'Any';
  }

  String _kotlinType(dynamic value) {
    if (value == null) return 'Any?';
    if (value is bool) return 'Boolean';
    if (value is int) return 'Int';
    if (value is double) return 'Double';
    if (value is String) return 'String';
    if (value is List) {
      if (value.isEmpty) return 'List<Any>';
      final Set<String> types = value.map(_kotlinType).toSet();
      if (types.length == 1) return 'List<${types.first}>';
      return 'List<Any>';
    }
    if (value is Map) return 'Map<String, Any>';
    return 'Any';
  }

  String _swiftType(dynamic value) {
    if (value == null) return 'Any?';
    if (value is bool) return 'Bool';
    if (value is int) return 'Int';
    if (value is double) return 'Double';
    if (value is String) return 'String';
    if (value is List) {
      if (value.isEmpty) return '[Any]';
      final Set<String> types = value.map(_swiftType).toSet();
      if (types.length == 1) return '[${types.first}]';
      return '[Any]';
    }
    if (value is Map) return '[String: Any]';
    return 'Any';
  }

  String _javaType(dynamic value) {
    if (value == null) return 'Object';
    if (value is bool) return 'Boolean';
    if (value is int) return 'Integer';
    if (value is double) return 'Double';
    if (value is String) return 'String';
    if (value is List) return 'List<Object>';
    if (value is Map) return 'Map<String, Object>';
    return 'Object';
  }

  String _csharpType(dynamic value) {
    if (value == null) return 'object?';
    if (value is bool) return 'bool';
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is String) return 'string';
    if (value is List) return 'List<object>';
    if (value is Map) return 'Dictionary<string, object>';
    return 'object';
  }

  String _goType(dynamic value) {
    if (value == null) return 'interface{}';
    if (value is bool) return 'bool';
    if (value is int) return 'int';
    if (value is double) return 'float64';
    if (value is String) return 'string';
    if (value is List) return '[]interface{}';
    if (value is Map) return 'map[string]interface{}';
    return 'interface{}';
  }

  void _generateCode() {
    final String input = _codeInputController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _codeErrorKey = 'jsonsuite_error_empty';
        _codeErrorDetail = null;
        _codeOutputController.text = '';
      });
      return;
    }
    try {
      final dynamic data = json.decode(input);
      if (data is! Map) {
        setState(() {
          _codeErrorKey = 'jsonsuite_error_not_object';
          _codeErrorDetail = null;
          _codeOutputController.text = '';
        });
        return;
      }
      final String code = _buildCode(data as Map<String, dynamic>);
      setState(() {
        _codeOutputController.text = code;
        _codeErrorKey = null;
        _codeErrorDetail = null;
      });
    } catch (e) {
      setState(() {
        _codeErrorKey = 'jsonsuite_error_invalid_json';
        _codeErrorDetail = e.toString();
        _codeOutputController.text = '';
      });
    }
  }

  String _buildCode(Map<String, dynamic> data) {
    switch (_codeLang) {
      case 'dart':
        return _dartCode(data);
      case 'typescript':
        return _tsCode(data);
      case 'python':
        return _pythonCode(data);
      case 'kotlin':
        return _kotlinCode(data);
      case 'swift':
        return _swiftCode(data);
      case 'java':
        return _javaCode(data);
      case 'csharp':
        return _csharpCode(data);
      case 'go':
        return _goCode(data);
      default:
        return '';
    }
  }

  String _dartCode(Map<String, dynamic> data) {
    final StringBuffer b = StringBuffer();
    b.writeln('class $_className {');
    data.forEach((String k, dynamic v) {
      final String type = _nullSafety
          ? '${_dartType(v)}${v == null ? '?' : ''}'
          : _dartType(v);
      b.writeln('  final $type ${_snakeToCamel(k)};');
    });
    b.writeln();
    b.writeln('  $_className({');
    data.forEach((String k, dynamic v) {
      final String field = _snakeToCamel(k);
      final String param =
      _nullSafety && v == null ? 'this.$field' : 'required this.$field';
      b.writeln('    $param,');
    });
    b.writeln('  });');
    if (_fromJsonMethod) {
      b.writeln();
      b.writeln('  factory $_className.fromJson(Map<String, dynamic> json) {');
      b.writeln('    return $_className(');
      data.forEach((String k, dynamic v) {
        final String field = _snakeToCamel(k);
        b.writeln("      $field: json['$k'],");
      });
      b.writeln('    );');
      b.writeln('  }');
    }
    if (_toJsonMethod) {
      b.writeln();
      b.writeln('  Map<String, dynamic> toJson() {');
      b.writeln('    return <String, dynamic>{');
      data.forEach((String k, dynamic v) {
        b.writeln("      '$k': ${_snakeToCamel(k)},");
      });
      b.writeln('    };');
      b.writeln('  }');
    }
    b.writeln('}');
    return b.toString();
  }

  String _tsCode(Map<String, dynamic> data) {
    final StringBuffer b = StringBuffer();
    b.writeln('export interface $_className {');
    data.forEach((String k, dynamic v) {
      b.writeln('  $k: ${_tsType(v)};');
    });
    b.writeln('}');
    return b.toString();
  }

  String _pythonCode(Map<String, dynamic> data) {
    final StringBuffer b = StringBuffer();
    b.writeln('from typing import Any, Dict, List, Optional');
    b.writeln('from dataclasses import dataclass, field');
    b.writeln();
    b.writeln('@dataclass');
    b.writeln('class $_className:');
    if (data.isEmpty) {
      b.writeln('    pass');
    } else {
      data.forEach((String k, dynamic v) {
        final String type = _pythonType(v);
        final String def = v == null ? 'None' : _pyDefault(v);
        b.writeln('    $k: $type = $def');
      });
    }
    return b.toString();
  }

  String _pyDefault(dynamic v) {
    if (v is bool) return v ? 'True' : 'False';
    if (v is int) return v.toString();
    if (v is double) return v.toString();
    if (v is String) return "'${v.replaceAll("'", "\\'")}'";
    if (v is List) return 'field(default_factory=list)';
    if (v is Map) return 'field(default_factory=dict)';
    return 'None';
  }

  String _kotlinCode(Map<String, dynamic> data) {
    final StringBuffer b = StringBuffer();
    b.writeln('data class $_className(');
    final List<String> params = <String>[];
    data.forEach((String k, dynamic v) {
      final String type = _kotlinType(v);
      params.add('    val $k: $type');
    });
    b.writeln(params.join(',\n'));
    b.writeln(')');
    return b.toString();
  }

  String _swiftCode(Map<String, dynamic> data) {
    final StringBuffer b = StringBuffer();
    b.writeln('struct $_className: Codable {');
    data.forEach((String k, dynamic v) {
      b.writeln('    let $k: ${_swiftType(v)}');
    });
    b.writeln('}');
    return b.toString();
  }

  String _javaCode(Map<String, dynamic> data) {
    final StringBuffer b = StringBuffer();
    b.writeln('public class $_className {');
    data.forEach((String k, dynamic v) {
      b.writeln('    private ${_javaType(v)} $k;');
    });
    b.writeln();
    data.forEach((String k, dynamic v) {
      final String cap = _capitalize(k);
      b.writeln('    public ${_javaType(v)} get$cap() { return $k; }');
      b.writeln('    public void set$cap(${_javaType(v)} $k) { this.$k = $k; }');
    });
    b.writeln('}');
    return b.toString();
  }

  String _csharpCode(Map<String, dynamic> data) {
    final StringBuffer b = StringBuffer();
    b.writeln('public class $_className');
    b.writeln('{');
    data.forEach((String k, dynamic v) {
      b.writeln('    public ${_csharpType(v)} ${_capitalize(k)} { get; set; }');
    });
    b.writeln('}');
    return b.toString();
  }

  String _goCode(Map<String, dynamic> data) {
    final StringBuffer b = StringBuffer();
    b.writeln('type $_className struct {');
    data.forEach((String k, dynamic v) {
      b.writeln('    ${_capitalize(k)} ${_goType(v)} `json:"$k"`');
    });
    b.writeln('}');
    return b.toString();
  }

  void _validate() {
    final String jsonInput = _validJsonController.text.trim();
    final String schemaInput = _validSchemaController.text.trim();
    if (jsonInput.isEmpty || schemaInput.isEmpty) {
      setState(() {
        _validationFatalError = context.t('jsonsuite_error_both_required');
        _validationErrors = <String>[];
        _validated = false;
      });
      return;
    }
    try {
      final dynamic jsonData = json.decode(jsonInput);
      final dynamic schemaData = json.decode(schemaInput);
      final JsonSchema schema = JsonSchema.create(schemaData);
      final ValidationResults results = schema.validate(jsonData);
      final List<String> errs = <String>[];
      if (!results.isValid) {
        for (final ValidationError e in results.errors) {
          errs.add(e.message);
        }
      }
      setState(() {
        _validationErrors = errs;
        _validated = true;
        _validResult = results.isValid;
        _validationFatalError = null;
      });
    } catch (e) {
      setState(() {
        _validationFatalError = e.toString();
        _validationErrors = <String>[];
        _validated = false;
      });
    }
  }

  Future<void> _copy(String text) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withOpacity(0.75),
        content: Text(context.t('jsonsuite_copied')),
      ),
    );
  }

  Future<void> _pasteTo(TextEditingController c) async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null) return;
    c.text = data.text!;
  }

  Widget _errorBox(String? key, String? detail) {
    if (key == null && detail == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFF5C5C).withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFF5C5C).withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (key != null)
              Text(
                context.t(key),
                style: const TextStyle(
                  color: Color(0xFFFF8A8A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (detail != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  detail,
                  style: const TextStyle(
                    color: Color(0xFFFFBFBF),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _glassField({
    required TextEditingController controller,
    bool readOnly = false,
    int? maxLines = 6,
    int minLines = 4,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      minLines: minLines,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 12,
        color: readOnly ? Colors.white70 : Colors.white,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30),
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _accentA, width: 1.5),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _labeledInput({
    required String labelKey,
    required TextEditingController controller,
    int maxLines = 6,
    int minLines = 4,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                context.t(labelKey),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _GlassIconButton(icon: Icons.paste, onTap: () => _pasteTo(controller)),
            const SizedBox(width: 8),
            _GlassIconButton(icon: Icons.clear, onTap: () => setState(controller.clear)),
          ],
        ),
        const SizedBox(height: 8),
        _glassField(controller: controller, maxLines: maxLines, minLines: minLines),
      ],
    );
  }

  Widget _outputArea(TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                context.t('jsonsuite_output'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _GlassIconButton(icon: Icons.copy, onTap: () => _copy(controller.text)),
          ],
        ),
        const SizedBox(height: 8),
        _glassField(
          controller: controller,
          readOnly: true,
          maxLines: null,
          minLines: 10,
        ),
      ],
    );
  }

  Widget _buildSchemaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _GlassCard(
            child: _labeledInput(
              labelKey: 'jsonsuite_json_input',
              controller: _schemaInputController,
            ),
          ),
          const SizedBox(height: 16),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _glassField(
                  controller: _classNameController,
                  maxLines: 1,
                  minLines: 1,
                  hint: context.t('jsonsuite_title_hint'),
                ),
                const SizedBox(height: 12),
                _GlassPrimaryButton(
                  icon: Icons.schema,
                  label: context.t('jsonsuite_generate_schema'),
                  onTap: _generateSchema,
                ),
                _errorBox(_schemaErrorKey, _schemaErrorDetail),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _GlassCard(child: _outputArea(_schemaOutputController)),
        ],
      ),
    );
  }

  Widget _buildCodeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _GlassCard(
            child: _labeledInput(
              labelKey: 'jsonsuite_json_input',
              controller: _codeInputController,
            ),
          ),
          const SizedBox(height: 16),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _glassField(
                  controller: _classNameController,
                  maxLines: 1,
                  minLines: 1,
                  hint: context.t('jsonsuite_classname_hint'),
                ),
                const SizedBox(height: 14),
                Text(
                  context.t('jsonsuite_language'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _langs.map((String l) {
                    final bool selected = _codeLang == l;
                    return GestureDetector(
                      onTap: () => setState(() => _codeLang = l),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? _accentA.withOpacity(0.85)
                              : Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? _accentA
                                : Colors.white.withOpacity(0.15),
                          ),
                        ),
                        child: Text(
                          l.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (_codeLang == 'dart') ...<Widget>[
                  const SizedBox(height: 14),
                  _glassSwitchRow(
                    label: context.t('jsonsuite_null_safety'),
                    value: _nullSafety,
                    onChanged: (bool v) => setState(() => _nullSafety = v),
                  ),
                  _glassSwitchRow(
                    label: context.t('jsonsuite_from_json'),
                    value: _fromJsonMethod,
                    onChanged: (bool v) => setState(() => _fromJsonMethod = v),
                  ),
                  _glassSwitchRow(
                    label: context.t('jsonsuite_to_json'),
                    value: _toJsonMethod,
                    onChanged: (bool v) => setState(() => _toJsonMethod = v),
                  ),
                ],
                const SizedBox(height: 14),
                _GlassPrimaryButton(
                  icon: Icons.code,
                  label: context.t('jsonsuite_generate_code'),
                  onTap: _generateCode,
                ),
                _errorBox(_codeErrorKey, _codeErrorDetail),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _GlassCard(child: _outputArea(_codeOutputController)),
        ],
      ),
    );
  }

  Widget _glassSwitchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          Switch(value: value, activeColor: _accentA, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildValidatorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _GlassCard(
            child: _labeledInput(
              labelKey: 'jsonsuite_validator_json',
              controller: _validJsonController,
            ),
          ),
          const SizedBox(height: 16),
          _GlassCard(
            child: _labeledInput(
              labelKey: 'jsonsuite_validator_schema',
              controller: _validSchemaController,
            ),
          ),
          const SizedBox(height: 16),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _GlassPrimaryButton(
                  icon: Icons.verified,
                  label: context.t('jsonsuite_validate'),
                  onTap: _validate,
                ),
                if (_validationFatalError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _validationFatalError!,
                      style: const TextStyle(
                        color: Color(0xFFFF8A8A),
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (_validated) ...<Widget>[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _validResult
                          ? const Color(0xFF4BD68B).withOpacity(0.15)
                          : const Color(0xFFFF5C5C).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _validResult
                            ? const Color(0xFF4BD68B).withOpacity(0.4)
                            : const Color(0xFFFF5C5C).withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          _validResult ? Icons.check_circle : Icons.error_outline,
                          color: _validResult
                              ? const Color(0xFF4BD68B)
                              : const Color(0xFFFF8A8A),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _validResult
                                ? context.t('jsonsuite_valid')
                                : context.t('jsonsuite_invalid'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _validResult
                                  ? const Color(0xFF4BD68B)
                                  : const Color(0xFFFF8A8A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_validationErrors.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 14),
                    Text(
                      '${context.t('jsonsuite_errors')}: ${_validationErrors.length}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (int i = 0; i < _validationErrors.length; i++)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '${i + 1}.',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SelectableText(
                                _validationErrors[i],
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _glassTabBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(52),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: _GlassCard(
          padding: const EdgeInsets.all(4),
          radius: 16,
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(colors: <Color>[_accentA, _accentB]),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            tabs: <Widget>[
              Tab(text: context.t('jsonsuite_tab_schema')),
              Tab(text: context.t('jsonsuite_tab_code')),
              Tab(text: context.t('jsonsuite_tab_validator')),
            ],
          ),
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.t('jsonsuite_title')),
        bottom: _glassTabBar(),
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
              child: Padding(
                padding: const EdgeInsets.only(top: 64),
                child: TabBarView(
                  controller: _tabController,
                  children: <Widget>[
                    _buildSchemaTab(),
                    _buildCodeTab(),
                    _buildValidatorTab(),
                  ],
                ),
              ),
            ),
          ],
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
  const _GlassIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white.withOpacity(0.08),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(icon, size: 18, color: Colors.white),
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
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[
                  _JsonSuiteState._accentA,
                  _JsonSuiteState._accentB,
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