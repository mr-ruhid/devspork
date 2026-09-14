import 'dart:convert';

import 'models.dart';

class JsonSchemaValidator {
  JsonSchemaValidator({
    required this.options,
    this.maxErrors = 200,
  });

  final ValidatorOptions options;
  final int maxErrors;

  final List<ValidationError> _errors = <ValidationError>[];
  final Map<String, dynamic> _rootSchema = <String, dynamic>{};
  int _checked = 0;
  bool _stop = false;

  ValidationResult validate(String schemaText, String jsonText) {
    _errors.clear();
    _rootSchema.clear();
    _checked = 0;
    _stop = false;

    final String schemaTrim = schemaText.trim();
    final String jsonTrim = jsonText.trim();

    if (schemaTrim.isEmpty) {
      return ValidationResult(
        valid: false,
        errors: <ValidationError>[
          const ValidationError(
            path: '',
            messageKey: 'jsonschemavalidator_error_schema_empty',
            messageDetail: '',
          ),
        ],
      );
    }

    if (jsonTrim.isEmpty) {
      return ValidationResult(
        valid: false,
        errors: <ValidationError>[
          const ValidationError(
            path: '',
            messageKey: 'jsonschemavalidator_error_json_empty',
            messageDetail: '',
          ),
        ],
      );
    }

    dynamic schema;
    dynamic data;

    try {
      schema = jsonDecode(schemaTrim);
    } catch (e) {
      return ValidationResult(
        valid: false,
        errors: <ValidationError>[
          ValidationError(
            path: '',
            messageKey: 'jsonschemavalidator_error_schema_invalid',
            messageDetail: e.toString(),
          ),
        ],
      );
    }

    try {
      data = jsonDecode(jsonTrim);
    } catch (e) {
      return ValidationResult(
        valid: false,
        errors: <ValidationError>[
          ValidationError(
            path: '',
            messageKey: 'jsonschemavalidator_error_json_invalid',
            messageDetail: e.toString(),
          ),
        ],
      );
    }

    if (schema is! Map<String, dynamic>) {
      return ValidationResult(
        valid: false,
        errors: <ValidationError>[
          const ValidationError(
            path: '',
            messageKey: 'jsonschemavalidator_error_schema_not_object',
            messageDetail: '',
          ),
        ],
      );
    }

    _rootSchema.addAll(schema);

    return ValidationResult(
      valid: _errors
          .where((ValidationError e) => e.severity == ValidationSeverity.error)
          .isEmpty,
      errors: List<ValidationError>.from(_errors),
      checkedNodes: _checked,
    );
  }

  void _validateNode(dynamic data, dynamic schema, String path) {
    if (_stop) return;
    _checked++;

    if (schema is bool) {
      if (!schema) {
        _addError(path, 'jsonschemavalidator_error_false_schema', '');
      }
      return;
    }

    if (schema is! Map<String, dynamic>) return;

    if (schema.containsKey(r'$ref')) {
      final dynamic ref = schema[r'$ref'];
      if (ref is String) {
        final dynamic resolved = _resolveRef(ref);
        if (resolved == null) {
          _addError(
            path,
            'jsonschemavalidator_error_ref_unresolved',
            ref,
          );
          return;
        }
        _validateNode(data, resolved, path);
        return;
      }
    }

    if (schema.containsKey('if')) {
      _validateConditional(data, schema, path);
    }

    if (schema.containsKey('allOf')) {
      final dynamic allOf = schema['allOf'];
      if (allOf is List) {
        for (int i = 0; i < allOf.length; i++) {
          _validateNode(data, allOf[i], path);
          if (_stop) return;
        }
      }
    }

    if (schema.containsKey('anyOf')) {
      _validateAnyOf(data, schema['anyOf'], path);
      if (_stop) return;
    }

    if (schema.containsKey('oneOf')) {
      _validateOneOf(data, schema['oneOf'], path);
      if (_stop) return;
    }

    if (schema.containsKey('not')) {
      _validateNot(data, schema['not'], path);
      if (_stop) return;
    }

    if (schema.containsKey('type')) {
      _validateType(data, schema['type'], path);
      if (_stop) return;
    }

    if (schema.containsKey('enum')) {
      _validateEnum(data, schema['enum'], path);
      if (_stop) return;
    }

    if (schema.containsKey('const')) {
      _validateConst(data, schema['const'], path);
      if (_stop) return;
    }

    if (data is String) {
      _validateString(data, schema, path);
    } else if (data is num) {
      _validateNumber(data, schema, path);
    } else if (data is List) {
      _validateArray(data, schema, path);
    } else if (data is Map<String, dynamic>) {
      _validateObject(data, schema, path);
    }

    if (_stop) return;
  }

  void _validateType(dynamic data, dynamic typeSpec, String path) {
    if (typeSpec is List) {
      for (final dynamic t in typeSpec) {
        if (_matchesType(data, t)) return;
      }
      _addError(
        path,
        'jsonschemavalidator_error_type',
        typeSpec.map((dynamic e) => e.toString()).join(', '),
      );
      return;
    }
    if (typeSpec is String) {
      if (!_matchesType(data, typeSpec)) {
        _addError(path, 'jsonschemavalidator_error_type', typeSpec);
      }
    }
  }

  bool _matchesType(dynamic data, dynamic type) {
    if (type is! String) return false;
    switch (type) {
      case 'string':
        return data is String;
      case 'integer':
        if (data is int) return true;
        if (data is double && data == data.toInt()) return true;
        return false;
      case 'number':
        return data is num;
      case 'boolean':
        return data is bool;
      case 'object':
        return data is Map;
      case 'array':
        return data is List;
      case 'null':
        return data == null;
      default:
        return true;
    }
  }

  String _actualTypeName(dynamic data) {
    if (data == null) return 'null';
    if (data is bool) return 'boolean';
    if (data is int) return 'integer';
    if (data is double) return 'number';
    if (data is String) return 'string';
    if (data is List) return 'array';
    if (data is Map) return 'object';
    return 'unknown';
  }

  void _validateEnum(dynamic data, dynamic enumSpec, String path) {
    if (enumSpec is! List) return;
    for (final dynamic item in enumSpec) {
      if (_deepEquals(data, item)) return;
    }
    _addError(
      path,
      'jsonschemavalidator_error_enum',
      enumSpec.map((dynamic e) => jsonEncode(e)).join(', '),
    );
  }

  void _validateConst(dynamic data, dynamic constValue, String path) {
    if (!_deepEquals(data, constValue)) {
      _addError(
        path,
        'jsonschemavalidator_error_const',
        jsonEncode(constValue),
      );
    }
  }

  void _validateString(String data, Map<String, dynamic> schema, String path) {
    final dynamic minLength = schema['minLength'];
    if (minLength is int && data.length < minLength) {
      _addError(
        path,
        'jsonschemavalidator_error_min_length',
        '$minLength',
      );
    }

    final dynamic maxLength = schema['maxLength'];
    if (maxLength is int && data.length > maxLength) {
      _addError(
        path,
        'jsonschemavalidator_error_max_length',
        '$maxLength',
      );
    }

    final dynamic pattern = schema['pattern'];
    if (pattern is String && pattern.isNotEmpty) {
      try {
        final RegExp re = RegExp(pattern);
        if (!re.hasMatch(data)) {
          _addError(
            path,
            'jsonschemavalidator_error_pattern',
            pattern,
          );
        }
      } catch (_) {}
    }

    if (options.checkFormat) {
      final dynamic format = schema['format'];
      if (format is String) {
        _checkFormat(data, format, path);
      }
    }
  }

  void _checkFormat(String data, String format, String path) {
    bool ok = true;
    switch (format) {
      case 'email':
        ok = RegExp(
          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
        ).hasMatch(data);
        break;
      case 'uri':
        ok = RegExp(r'^[a-zA-Z][a-zA-Z0-9+\-.]*:').hasMatch(data);
        break;
      case 'uuid':
        ok = RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        ).hasMatch(data);
        break;
      case 'date':
        ok = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(data) &&
            DateTime.tryParse(data) != null;
        break;
      case 'time':
        ok = RegExp(
          r'^\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})?$',
        ).hasMatch(data);
        break;
      case 'date-time':
        ok = RegExp(
          r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})?$',
        ).hasMatch(data) &&
            DateTime.tryParse(data) != null;
        break;
      case 'ipv4':
        ok = RegExp(
          r'^(25[0-5]|2[0-4]\d|[01]?\d\d?)\.(25[0-5]|2[0-4]\d|[01]?\d\d?)\.(25[0-5]|2[0-4]\d|[01]?\d\d?)\.(25[0-5]|2[0-4]\d|[01]?\d\d?)$',
        ).hasMatch(data);
        break;
      case 'ipv6':
        ok = RegExp(
          r'^((?=.*::)(?!.*::.+::)(::)?([\dA-Fa-f]{1,4}:(:|\b)|){5}|([\dA-Fa-f]{1,4}:){6})((([\dA-Fa-f]{1,4}((?!\3)::|:\b|$))|(?!\2\3)){2}|(((2[0-4]|1\d|[1-9])?\d|25[0-5])\.?\b){4})$',
        ).hasMatch(data);
        break;
      case 'hostname':
        ok = RegExp(
          r'^(?=.{1,253}$)(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]{0,61}[A-Za-z0-9])$',
        ).hasMatch(data);
        break;
      default:
        if (!options.allowUnknownFormats) {
          _addError(
            path,
            'jsonschemavalidator_warning_unknown_format',
            format,
            severity: ValidationSeverity.warning,
          );
        }
        return;
    }
    if (!ok) {
      _addError(
        path,
        'jsonschemavalidator_error_format',
        format,
      );
    }
  }

  void _validateNumber(num data, Map<String, dynamic> schema, String path) {
    final dynamic minimum = schema['minimum'];
    if (minimum is num && data < minimum) {
      _addError(
        path,
        'jsonschemavalidator_error_minimum',
        '$minimum',
      );
    }

    final dynamic maximum = schema['maximum'];
    if (maximum is num && data > maximum) {
      _addError(
        path,
        'jsonschemavalidator_error_maximum',
        '$maximum',
      );
    }

    final dynamic exclusiveMinimum = schema['exclusiveMinimum'];
    if (exclusiveMinimum is num && data <= exclusiveMinimum) {
      _addError(
        path,
        'jsonschemavalidator_error_exclusive_minimum',
        '$exclusiveMinimum',
      );
    }

    final dynamic exclusiveMaximum = schema['exclusiveMaximum'];
    if (exclusiveMaximum is num && data >= exclusiveMaximum) {
      _addError(
        path,
        'jsonschemavalidator_error_exclusive_maximum',
        '$exclusiveMaximum',
      );
    }

    final dynamic multipleOf = schema['multipleOf'];
    if (multipleOf is num && multipleOf > 0) {
      final double q = data / multipleOf;
      if ((q - q.roundToDouble()).abs() > 1e-9) {
        _addError(
          path,
          'jsonschemavalidator_error_multiple_of',
          '$multipleOf',
        );
      }
    }
  }

  void _validateArray(List<dynamic> data, Map<String, dynamic> schema, String path) {
    final dynamic minItems = schema['minItems'];
    if (minItems is int && data.length < minItems) {
      _addError(
        path,
        'jsonschemavalidator_error_min_items',
        '$minItems',
      );
    }

    final dynamic maxItems = schema['maxItems'];
    if (maxItems is int && data.length > maxItems) {
      _addError(
        path,
        'jsonschemavalidator_error_max_items',
        '$maxItems',
      );
    }

    final dynamic uniqueItems = schema['uniqueItems'];
    if (uniqueItems == true) {
      final Set<String> seen = <String>{};
      for (int i = 0; i < data.length; i++) {
        final String enc = jsonEncode(data[i]);
        if (seen.contains(enc)) {
          _addError(
            '$path[$i]',
            'jsonschemavalidator_error_unique_items',
            '',
          );
          break;
        }
        seen.add(enc);
      }
    }

    final dynamic items = schema['items'];
    if (items is Map<String, dynamic>) {
      for (int i = 0; i < data.length; i++) {
        _validateNode(data[i], items, '$path[$i]');
        if (_stop) return;
      }
    } else if (items is List) {
      for (int i = 0; i < data.length && i < items.length; i++) {
        _validateNode(data[i], items[i], '$path[$i]');
        if (_stop) return;
      }
      final dynamic additionalItems = schema['additionalItems'];
      if (additionalItems != null && data.length > items.length) {
        for (int i = items.length; i < data.length; i++) {
          _validateNode(data[i], additionalItems, '$path[$i]');
          if (_stop) return;
        }
      }
    }

    final dynamic contains = schema['contains'];
    if (contains is Map<String, dynamic> || contains is bool) {
      bool found = false;
      for (final dynamic item in data) {
        if (_subValidate(item, contains)) {
          found = true;
          break;
        }
      }
      if (!found) {
        _addError(
          path,
          'jsonschemavalidator_error_contains',
          '',
        );
      }
    }
  }

  void _validateObject(
      Map<String, dynamic> data,
      Map<String, dynamic> schema,
      String path,
      ) {
    final dynamic minProperties = schema['minProperties'];
    if (minProperties is int && data.length < minProperties) {
      _addError(
        path,
        'jsonschemavalidator_error_min_properties',
        '$minProperties',
      );
    }

    final dynamic maxProperties = schema['maxProperties'];
    if (maxProperties is int && data.length > maxProperties) {
      _addError(
        path,
        'jsonschemavalidator_error_max_properties',
        '$maxProperties',
      );
    }

    final dynamic required = schema['required'];
    if (required is List) {
      for (final dynamic r in required) {
        if (r is String && !data.containsKey(r)) {
          _addError(
            path.isEmpty ? r : '$path.$r',
            'jsonschemavalidator_error_required',
            r,
          );
        }
      }
    }

    final dynamic properties = schema['properties'];
    final Map<String, dynamic> propsMap =
    properties is Map<String, dynamic> ? properties : <String, dynamic>{};

    final Set<String> matchedKeys = <String>{};

    for (final MapEntry<String, dynamic> e in data.entries) {
      final String key = e.key;
      final String childPath = '$path.$key';

      if (propsMap.containsKey(key)) {
        matchedKeys.add(key);
        _validateNode(e.value, propsMap[key], childPath);
        if (_stop) return;
      }

      final dynamic patternProperties = schema['patternProperties'];
      if (patternProperties is Map<String, dynamic>) {
        for (final MapEntry<String, dynamic> p in patternProperties.entries) {
          try {
            if (RegExp(p.key).hasMatch(key)) {
              matchedKeys.add(key);
              _validateNode(e.value, p.value, childPath);
              if (_stop) return;
            }
          } catch (_) {}
        }
      }
    }

    final dynamic additionalProperties = schema['additionalProperties'];
    if (additionalProperties != null) {
      for (final MapEntry<String, dynamic> e in data.entries) {
        if (!matchedKeys.contains(e.key) && !propsMap.containsKey(e.key)) {
          if (additionalProperties == false) {
            _addError(
              '$path.${e.key}',
              'jsonschemavalidator_error_additional_properties',
              e.key,
            );
          } else if (additionalProperties is Map<String, dynamic>) {
            _validateNode(e.value, additionalProperties, '$path.${e.key}');
            if (_stop) return;
          }
        }
      }
    }

    final dynamic propertyNames = schema['propertyNames'];
    if (propertyNames is Map<String, dynamic>) {
      for (final String key in data.keys) {
        _validateNode(key, propertyNames, '$path.$key');
        if (_stop) return;
      }
    }

    final dynamic deps = schema['dependencies'];
    if (deps is Map<String, dynamic>) {
      for (final MapEntry<String, dynamic> d in deps.entries) {
        if (!data.containsKey(d.key)) continue;
        if (d.value is List) {
          for (final dynamic dep in d.value as List) {
            if (dep is String && !data.containsKey(dep)) {
              _addError(
                path,
                'jsonschemavalidator_error_dependency',
                '${d.key} -> $dep',
              );
            }
          }
        } else if (d.value is Map<String, dynamic>) {
          _validateNode(data, d.value, path);
          if (_stop) return;
        }
      }
    }
  }

  void _validateConditional(
      dynamic data,
      Map<String, dynamic> schema,
      String path,
      ) {
    final dynamic ifSchema = schema['if'];
    final bool matches = _subValidate(data, ifSchema);
    if (matches) {
      final dynamic thenSchema = schema['then'];
      if (thenSchema != null) {
        _validateNode(data, thenSchema, path);
      }
    } else {
      final dynamic elseSchema = schema['else'];
      if (elseSchema != null) {
        _validateNode(data, elseSchema, path);
      }
    }
  }

  void _validateAnyOf(dynamic data, dynamic anyOf, String path) {
    if (anyOf is! List || anyOf.isEmpty) return;
    for (final dynamic sub in anyOf) {
      if (_subValidate(data, sub)) return;
    }
    _addError(path, 'jsonschemavalidator_error_any_of', '');
  }

  void _validateOneOf(dynamic data, dynamic oneOf, String path) {
    if (oneOf is! List || oneOf.isEmpty) return;
    int matched = 0;
    for (final dynamic sub in oneOf) {
      if (_subValidate(data, sub)) matched++;
    }
    if (matched != 1) {
      _addError(
        path,
        'jsonschemavalidator_error_one_of',
        '$matched',
      );
    }
  }

  void _validateNot(dynamic data, dynamic notSchema, String path) {
    if (_subValidate(data, notSchema)) {
      _addError(path, 'jsonschemavalidator_error_not', '');
    }
  }

  bool _subValidate(dynamic data, dynamic schema) {
    final List<ValidationError> savedErrors =
    List<ValidationError>.from(_errors);
    final int savedChecked = _checked;
    final bool savedStop = _stop;

    _errors.clear();
    _stop = false;

    _validateNode(data, schema, '');

    final bool ok = _errors
        .where((ValidationError e) => e.severity == ValidationSeverity.error)
        .isEmpty;

    _errors
      ..clear()
      ..addAll(savedErrors);
    _checked = savedChecked;
    _stop = savedStop;

    return ok;
  }

  dynamic _resolveRef(String ref) {
    if (!ref.startsWith('#')) return null;

    String path = ref.substring(1);
    if (path.startsWith('/')) path = path.substring(1);

    final List<String> parts = path.split('/');
    dynamic current = _rootSchema;

    for (final String raw in parts) {
      if (raw.isEmpty) continue;
      final String key = raw
          .replaceAll('~1', '/')
          .replaceAll('~0', '~');
      if (current is Map<String, dynamic>) {
        if (!current.containsKey(key)) return null;
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
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
    if (a is num && b is num) {
      return a == b;
    }
    return a == b;
  }

  void _addError(
      String path,
      String messageKey,
      String detail, {
        ValidationSeverity severity = ValidationSeverity.error,
      }) {
    if (_errors.length >= maxErrors) {
      _stop = true;
      return;
    }
    _errors.add(
      ValidationError(
        path: path,
        messageKey: messageKey,
        messageDetail: detail,
        severity: severity,
      ),
    );
  }
}