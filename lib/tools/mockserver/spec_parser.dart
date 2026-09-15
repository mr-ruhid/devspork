import 'dart:convert';
import 'package:yaml/yaml.dart';
import 'models.dart';

class OpenApiParser {
  OpenApiParser._();

  static OpenApiParseResult parse(String input) {
    final String trimmed = input.trim();
    if (trimmed.isEmpty) {
      return OpenApiParseResult(
        endpoints: <MockEndpoint>[],
        error: 'mockserver_error_empty_input',
      );
    }

    dynamic decoded;
    try {
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        decoded = jsonDecode(trimmed);
      } else {
        decoded = loadYaml(trimmed);
      }
    } catch (e) {
      return OpenApiParseResult(
        endpoints: <MockEndpoint>[],
        error: 'mockserver_error_parse: $e',
      );
    }

    if (decoded is! Map) {
      return OpenApiParseResult(
        endpoints: <MockEndpoint>[],
        error: 'mockserver_error_not_object',
      );
    }

    final Map<dynamic, dynamic> root = decoded;

    final bool isSwagger2 = root['swagger'] != null;
    final bool isOpenApi3 = root['openapi'] != null;

    if (!isSwagger2 && !isOpenApi3) {
      return OpenApiParseResult(
        endpoints: <MockEndpoint>[],
        error: 'mockserver_error_not_openapi',
      );
    }

    final dynamic infoRaw = root['info'];
    String? title;
    String? version;
    if (infoRaw is Map) {
      title = infoRaw['title']?.toString();
      version = infoRaw['version']?.toString();
    }

    final dynamic pathsRaw = root['paths'];
    if (pathsRaw is! Map) {
      return OpenApiParseResult(
        endpoints: <MockEndpoint>[],
        title: title,
        version: version,
        error: 'mockserver_error_no_paths',
      );
    }

    final Map<dynamic, dynamic>? globalComponents =
    root['components'] is Map ? root['components'] as Map : null;
    final Map<dynamic, dynamic>? globalDefinitions =
    root['definitions'] is Map ? root['definitions'] as Map : null;

    final List<MockEndpoint> endpoints = <MockEndpoint>[];

    pathsRaw.forEach((dynamic pathKey, dynamic pathItem) {
      if (pathItem is! Map) return;
      final String path = pathKey.toString();

      for (final String method in <String>[
        'get',
        'post',
        'put',
        'patch',
        'delete',
        'head',
        'options',
      ]) {
        final dynamic op = pathItem[method];
        if (op is! Map) continue;

        final String description = op['summary']?.toString() ??
            op['description']?.toString() ??
            '';

        final String body = _buildMockBody(
          op,
          globalComponents,
          globalDefinitions,
          isOpenApi3,
        );

        final Map<String, String> headers = <String, String>{
          'Content-Type': 'application/json',
        };

        endpoints.add(
          MockEndpoint(
            method: method.toUpperCase(),
            path: path,
            statusCode: 200,
            responseBody: body,
            responseHeaders: headers,
            description: description,
          ),
        );
      }
    });

    if (endpoints.isEmpty) {
      return OpenApiParseResult(
        endpoints: <MockEndpoint>[],
        title: title,
        version: version,
        error: 'mockserver_error_no_endpoints',
      );
    }

    return OpenApiParseResult(
      endpoints: endpoints,
      title: title,
      version: version,
    );
  }

  static String _buildMockBody(
      Map<dynamic, dynamic> operation,
      Map<dynamic, dynamic>? components,
      Map<dynamic, dynamic>? definitions,
      bool isOpenApi3,
      ) {
    final dynamic responsesRaw = operation['responses'];
    if (responsesRaw is! Map) {
      return '{}';
    }

    dynamic successResponse;
    for (final dynamic key in <dynamic>['200', '201', 200, 201]) {
      if (responsesRaw.containsKey(key)) {
        successResponse = responsesRaw[key];
        break;
      }
    }
    successResponse ??= responsesRaw.values.isNotEmpty
        ? responsesRaw.values.first
        : null;

    if (successResponse is! Map) return '{}';

    final dynamic contentRaw = successResponse['content'];
    dynamic schemaRaw;

    if (contentRaw is Map && contentRaw.isNotEmpty) {
      for (final String mime in <String>[
        'application/json',
        'application/*+json',
        '*/*',
      ]) {
        if (contentRaw.containsKey(mime)) {
          final dynamic media = contentRaw[mime];
          if (media is Map && media['schema'] != null) {
            schemaRaw = media['schema'];
            break;
          }
        }
      }
      if (schemaRaw == null) {
        final dynamic firstMedia = contentRaw.values.first;
        if (firstMedia is Map && firstMedia['schema'] != null) {
          schemaRaw = firstMedia['schema'];
        }
      }
    }

    if (schemaRaw == null && successResponse['schema'] != null) {
      schemaRaw = successResponse['schema'];
    }

    if (schemaRaw == null) return '{}';

    final dynamic mockValue = _generateFromSchema(
      schemaRaw,
      components,
      definitions,
      isOpenApi3,
      0,
    );

    try {
      return const JsonEncoder.withIndent('  ').convert(mockValue);
    } catch (_) {
      return '{}';
    }
  }

  static dynamic _generateFromSchema(
      dynamic schema,
      Map<dynamic, dynamic>? components,
      Map<dynamic, dynamic>? definitions,
      bool isOpenApi3,
      int depth,
      ) {
    if (depth > 8) return null;
    if (schema is! Map) return null;

    if (schema[r'$ref'] != null) {
      final String ref = schema[r'$ref'].toString();
      final dynamic resolved = _resolveRef(
        ref,
        components,
        definitions,
        isOpenApi3,
      );
      if (resolved != null) {
        return _generateFromSchema(
          resolved,
          components,
          definitions,
          isOpenApi3,
          depth + 1,
        );
      }
      return null;
    }

    if (schema['example'] != null) return schema['example'];

    final dynamic examplesRaw = schema['examples'];
    if (examplesRaw is Map && examplesRaw.isNotEmpty) {
      return examplesRaw.values.first;
    }
    if (examplesRaw is List && examplesRaw.isNotEmpty) {
      return examplesRaw.first;
    }

    final dynamic defaultVal = schema['default'];
    if (defaultVal != null) return defaultVal;

    final dynamic enumRaw = schema['enum'];
    if (enumRaw is List && enumRaw.isNotEmpty) {
      return enumRaw.first;
    }

    final String type = _inferType(schema);

    switch (type) {
      case 'object':
        return _buildObject(
          schema,
          components,
          definitions,
          isOpenApi3,
          depth,
        );
      case 'array':
        final dynamic items = schema['items'];
        if (items == null) return <dynamic>[];
        final dynamic item = _generateFromSchema(
          items,
          components,
          definitions,
          isOpenApi3,
          depth + 1,
        );
        return <dynamic>[item];
      case 'string':
        return _mockString(schema);
      case 'integer':
        return _mockInt(schema);
      case 'number':
        return _mockNumber(schema);
      case 'boolean':
        return true;
      case 'null':
        return null;
      default:
        if (schema['properties'] is Map) {
          return _buildObject(
            schema,
            components,
            definitions,
            isOpenApi3,
            depth,
          );
        }
        if (schema['items'] != null) {
          final dynamic item = _generateFromSchema(
            schema['items'],
            components,
            definitions,
            isOpenApi3,
            depth + 1,
          );
          return <dynamic>[item];
        }
        return <String, dynamic>{};
    }
  }

  static Map<String, dynamic> _buildObject(
      Map<dynamic, dynamic> schema,
      Map<dynamic, dynamic>? components,
      Map<dynamic, dynamic>? definitions,
      bool isOpenApi3,
      int depth,
      ) {
    final Map<String, dynamic> result = <String, dynamic>{};

    final dynamic propertiesRaw = schema['properties'];
    if (propertiesRaw is Map) {
      for (final dynamic entry in propertiesRaw.entries) {
        final String key = entry.key.toString();
        final dynamic value = _generateFromSchema(
          entry.value,
          components,
          definitions,
          isOpenApi3,
          depth + 1,
        );
        result[key] = value;
      }
    }

    final dynamic allOf = schema['allOf'];
    if (allOf is List) {
      for (final dynamic part in allOf) {
        final dynamic resolved = _generateFromSchema(
          part,
          components,
          definitions,
          isOpenApi3,
          depth + 1,
        );
        if (resolved is Map) {
          resolved.forEach((dynamic k, dynamic v) {
            result[k.toString()] = v;
          });
        }
      }
    }

    final dynamic additional = schema['additionalProperties'];
    if (additional is Map && result.isEmpty) {
      result['key1'] = _generateFromSchema(
        additional,
        components,
        definitions,
        isOpenApi3,
        depth + 1,
      );
      result['key2'] = _generateFromSchema(
        additional,
        components,
        definitions,
        isOpenApi3,
        depth + 1,
      );
    }

    return result;
  }

  static dynamic _resolveRef(
      String ref,
      Map<dynamic, dynamic>? components,
      Map<dynamic, dynamic>? definitions,
      bool isOpenApi3,
      ) {
    if (!ref.startsWith('#/')) return null;
    final List<String> parts = ref.substring(2).split('/');
    dynamic current;

    if (isOpenApi3) {
      if (parts.isEmpty || parts.first != 'components') return null;
      current = components;
      for (int i = 1; i < parts.length; i++) {
        if (current is! Map) return null;
        current = current[parts[i]];
      }
    } else {
      if (parts.isEmpty || parts.first != 'definitions') return null;
      current = definitions;
      for (int i = 1; i < parts.length; i++) {
        if (current is! Map) return null;
        current = current[parts[i]];
      }
    }

    return current;
  }

  static String _inferType(Map<dynamic, dynamic> schema) {
    final dynamic typeRaw = schema['type'];
    if (typeRaw != null) return typeRaw.toString();
    if (schema['properties'] != null) return 'object';
    if (schema['items'] != null) return 'array';
    if (schema['allOf'] != null) return 'object';
    return 'object';
  }

  static String _mockString(Map<dynamic, dynamic> schema) {
    final dynamic format = schema['format'];
    if (format != null) {
      switch (format.toString()) {
        case 'date':
          return '2024-01-15';
        case 'date-time':
          return '2024-01-15T10:30:00Z';
        case 'email':
          return 'user@example.com';
        case 'uri':
        case 'url':
          return 'https://example.com';
        case 'uuid':
          return '550e8400-e29b-41d4-a716-446655440000';
        case 'password':
          return '********';
        case 'byte':
          return 'SGVsbG8=';
        case 'binary':
          return 'binary';
        case 'hostname':
          return 'example.com';
        case 'ipv4':
          return '192.168.1.1';
        case 'ipv6':
          return '2001:0db8:85a3:0000:0000:8a2e:0370:7334';
      }
    }

    final dynamic pattern = schema['pattern'];
    if (pattern != null) {
      final String p = pattern.toString();
      if (p.contains('@')) return 'user@example.com';
      if (p.contains('^\\d')) return '12345';
    }

    final dynamic minLenRaw = schema['minLength'];
    final dynamic maxLenRaw = schema['maxLength'];
    final int minLen = (minLenRaw as num?)?.toInt() ?? 5;
    final int maxLen = (maxLenRaw as num?)?.toInt() ?? 20;
    int len = minLen.clamp(1, 20);
    if (len > maxLen) len = maxLen;

    const String sample = 'sample_text_value';
    if (len <= sample.length) return sample.substring(0, len);
    return sample + '_' * (len - sample.length);
  }

  static int _mockInt(Map<dynamic, dynamic> schema) {
    final dynamic minRaw = schema['minimum'];
    final dynamic maxRaw = schema['maximum'];
    final int min = (minRaw as num?)?.toInt() ?? 1;
    final int max = (maxRaw as num?)?.toInt() ?? 100;
    return min.clamp(0, max);
  }

  static num _mockNumber(Map<dynamic, dynamic> schema) {
    final dynamic minRaw = schema['minimum'];
    final dynamic maxRaw = schema['maximum'];
    final num min = (minRaw as num?) ?? 0.0;
    final num max = (maxRaw as num?) ?? 100.0;
    return (min + (max - min) / 2).toDouble();
  }
}