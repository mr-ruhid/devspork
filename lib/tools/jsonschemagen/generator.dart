import 'dart:convert';

import 'models.dart';

class SchemaGenerator {
  SchemaGenerator({
    required this.options,
    required this.draft,
    this.rootTitle = 'Root',
  });

  final SchemaOptions options;
  final SchemaDraft draft;
  final String rootTitle;

  final Map<String, Map<String, dynamic>> _definitions =
  <String, Map<String, dynamic>>{};
  final Set<String> _usedNames = <String>{};

  String generate(String jsonText) {
    _definitions.clear();
    _usedNames.clear();

    final String trimmed = jsonText.trim();
    if (trimmed.isEmpty) return '';

    final dynamic decoded = jsonDecode(trimmed);

    if (decoded is Map<String, dynamic>) {
      final Map<String, dynamic> schema = _buildObjectSchema(
        decoded,
        _sanitizeName(rootTitle),
        isRoot: true,
      );
      return _finalize(schema);
    }

    if (decoded is List) {
      final Map<String, dynamic> schema = _buildArraySchema(
        decoded,
        _sanitizeName(rootTitle),
        isRoot: true,
      );
      return _finalize(schema);
    }

    final Map<String, dynamic> schema = _buildPrimitiveSchema(decoded);
    return _finalize(schema);
  }

  Map<String, dynamic> _buildObjectSchema(
      Map<String, dynamic> map,
      String name, {
        bool isRoot = false,
      }) {
    final Map<String, dynamic> schema = <String, dynamic>{
      'type': 'object',
    };

    if (options.addTitle) {
      schema['title'] = name;
    }

    final List<String> required = <String>[];
    final Map<String, dynamic> properties = <String, dynamic>{};

    for (final MapEntry<String, dynamic> e in map.entries) {
      final String key = e.key;
      final dynamic value = e.value;
      properties[key] = _buildPropertySchema(value, key, name);
      if (options.addRequired) {
        required.add(key);
      }
    }

    if (properties.isNotEmpty) {
      schema['properties'] = properties;
    }

    if (options.addRequired && required.isNotEmpty) {
      schema['required'] = required;
    }

    if (options.addAdditionalPropertiesFalse) {
      schema['additionalProperties'] = false;
    }

    return schema;
  }

  Map<String, dynamic> _buildArraySchema(
      List<dynamic> list,
      String name, {
        bool isRoot = false,
      }) {
    final Map<String, dynamic> schema = <String, dynamic>{
      'type': 'array',
    };

    if (options.addTitle) {
      schema['title'] = name;
    }

    if (list.isEmpty) {
      schema['items'] = <String, dynamic>{};
      return schema;
    }

    final dynamic first = list.first;
    final Map<String, dynamic> itemSchema = _buildItemSchema(first, name);

    bool allSame = true;
    for (int i = 1; i < list.length; i++) {
      if (!_deepEquals(list[i], first)) {
        allSame = false;
        break;
      }
    }

    if (!allSame) {
      final List<Map<String, dynamic>> variants = <Map<String, dynamic>>[];
      for (final dynamic item in list) {
        final Map<String, dynamic> s = _buildItemSchema(item, name);
        if (!_schemaInList(variants, s)) {
          variants.add(s);
        }
      }

      if (variants.length == 1) {
        schema['items'] = variants.first;
      } else if (variants.isNotEmpty && _allPrimitive(variants)) {
        final Set<String> types = <String>{};
        for (final Map<String, dynamic> v in variants) {
          final dynamic t = v['type'];
          if (t is String) types.add(t);
        }
        if (types.length == 1) {
          schema['items'] = <String, dynamic>{'type': types.first};
        } else {
          schema['items'] = <String, dynamic>{
            'anyOf': variants,
          };
        }
      } else {
        schema['items'] = <String, dynamic>{
          'anyOf': variants,
        };
      }
    } else {
      schema['items'] = itemSchema;
    }

    if (options.addExamples) {
      schema['examples'] = list.take(3).toList();
    }

    return schema;
  }

  Map<String, dynamic> _buildItemSchema(dynamic item, String nameHint) {
    if (item is Map<String, dynamic>) {
      final String defName = _reserveName(_sanitizeName(nameHint));
      if (options.useDefinitions) {
        if (!_definitions.containsKey(defName)) {
          _definitions[defName] = <String, dynamic>{};
          _definitions[defName] = _buildObjectSchema(item, defName);
        }
        return <String, dynamic>{
          r'$ref': '#/${_defsKey()}/$defName',
        };
      }
      return _buildObjectSchema(item, _sanitizeName(nameHint));
    }

    if (item is List) {
      return _buildArraySchema(item, _sanitizeName(nameHint));
    }

    return _buildPrimitiveSchema(item);
  }

  bool _allPrimitive(List<Map<String, dynamic>> list) {
    for (final Map<String, dynamic> s in list) {
      final dynamic t = s['type'];
      if (t != 'string' &&
          t != 'integer' &&
          t != 'number' &&
          t != 'boolean' &&
          t != 'null') {
        return false;
      }
    }
    return true;
  }

  bool _schemaInList(
      List<Map<String, dynamic>> list,
      Map<String, dynamic> s,
      ) {
    final String encoded = jsonEncode(s);
    for (final Map<String, dynamic> item in list) {
      if (jsonEncode(item) == encoded) return true;
    }
    return false;
  }

  Map<String, dynamic> _buildPropertySchema(
      dynamic value,
      String key,
      String parentName,
      ) {
    if (value is Map<String, dynamic>) {
      final String defName = _reserveName(_sanitizeName(key));
      if (options.useDefinitions) {
        if (!_definitions.containsKey(defName)) {
          _definitions[defName] = <String, dynamic>{};
          _definitions[defName] = _buildObjectSchema(
            value,
            defName,
          );
        }
        return <String, dynamic>{
          r'$ref': '#/${_defsKey()}/$defName',
        };
      }
      return _buildObjectSchema(value, _sanitizeName(key));
    }

    if (value is List) {
      return _buildArraySchema(value, _singularize(_sanitizeName(key)));
    }

    return _buildPrimitiveSchema(value);
  }

  Map<String, dynamic> _buildPrimitiveSchema(dynamic value) {
    if (value == null) {
      return <String, dynamic>{'type': 'null'};
    }
    if (value is bool) {
      final Map<String, dynamic> s = <String, dynamic>{'type': 'boolean'};
      if (options.addExamples) s['examples'] = <dynamic>[value];
      return s;
    }
    if (value is int) {
      final Map<String, dynamic> s = <String, dynamic>{'type': 'integer'};
      if (options.addExamples) s['examples'] = <dynamic>[value];
      return s;
    }
    if (value is double) {
      final Map<String, dynamic> s = <String, dynamic>{'type': 'number'};
      if (options.addExamples) s['examples'] = <dynamic>[value];
      return s;
    }
    if (value is String) {
      final Map<String, dynamic> s = <String, dynamic>{'type': 'string'};
      if (options.detectStringFormats) {
        final StringFormat fmt = _detectStringFormat(value);
        if (fmt != StringFormat.none) {
          s['format'] = fmt.value;
        }
      }
      if (options.addExamples && value.isNotEmpty) {
        s['examples'] = <dynamic>[value];
      }
      return s;
    }
    return <String, dynamic>{};
  }

  StringFormat _detectStringFormat(String value) {
    if (value.isEmpty) return StringFormat.none;

    if (RegExp(
      r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})?$',
    ).hasMatch(value)) {
      return StringFormat.dateTime;
    }

    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return StringFormat.date;
    }

    if (RegExp(r'^\d{2}:\d{2}:\d{2}(\.\d+)?$').hasMatch(value)) {
      return StringFormat.time;
    }

    if (RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(value)) {
      return StringFormat.email;
    }

    if (RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value)) {
      return StringFormat.uuid;
    }

    if (RegExp(
      r'^(25[0-5]|2[0-4]\d|[01]?\d\d?)\.(25[0-5]|2[0-4]\d|[01]?\d\d?)\.(25[0-5]|2[0-4]\d|[01]?\d\d?)\.(25[0-5]|2[0-4]\d|[01]?\d\d?)$',
    ).hasMatch(value)) {
      return StringFormat.ipv4;
    }

    if (RegExp(r'^https?://[^\s]+$').hasMatch(value)) {
      return StringFormat.uri;
    }

    if (RegExp(
      r'^(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)(?:\.(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?))*$',
    ).hasMatch(value) &&
        value.contains('.') &&
        !value.contains(' ')) {
      return StringFormat.hostname;
    }

    return StringFormat.none;
  }

  String _finalize(Map<String, dynamic> schema) {
    final Map<String, dynamic> root = <String, dynamic>{
      r'$schema': draft.id,
    };

    root.addAll(schema);

    if (_definitions.isNotEmpty) {
      final Map<String, Map<String, dynamic>> defs =
      Map<String, Map<String, dynamic>>.from(_definitions);
      final List<String> sortedKeys = defs.keys.toList()..sort();
      final Map<String, dynamic> ordered = <String, dynamic>{};
      for (final String k in sortedKeys) {
        ordered[k] = defs[k];
      }
      root[_defsKey()] = ordered;
    }

    return const JsonEncoder.withIndent('  ').convert(root);
  }

  String _defsKey() {
    switch (draft) {
      case SchemaDraft.draft07:
        return 'definitions';
      case SchemaDraft.draft2019:
        return r'$defs';
      case SchemaDraft.draft2020:
        return r'$defs';
    }
  }

  String _reserveName(String base) {
    String candidate = base.isEmpty ? 'Item' : base;
    String unique = candidate;
    int i = 2;
    while (_usedNames.contains(unique) &&
        !_definitions.containsKey(unique)) {
      unique = '$candidate$i';
      i++;
    }
    _usedNames.add(unique);
    return unique;
  }

  String _sanitizeName(String input) {
    final String cleaned = input
        .replaceAll(RegExp(r'[^A-Za-z0-9_]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (cleaned.isEmpty) return 'Item';
    return cleaned;
  }

  String _singularize(String input) {
    if (input.endsWith('ies') && input.length > 3) {
      return '${input.substring(0, input.length - 3)}y';
    }
    if (input.endsWith('ses') && input.length > 3) {
      return input.substring(0, input.length - 2);
    }
    if (input.endsWith('s') &&
        !input.endsWith('ss') &&
        input.length > 1) {
      return input.substring(0, input.length - 1);
    }
    return input;
  }

  bool _deepEquals(dynamic a, dynamic b) {
    if (identical(a, b)) return true;
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final dynamic k in a.keys) {
        if (!b.containsKey(k)) return false;
        if (!_deepEquals(a[k], b[k])) return false;
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (!_deepEquals(a[i], b[i])) return false;
      }
      return true;
    }
    return a == b;
  }
}