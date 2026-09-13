import 'dart:convert';

import 'models.dart';

class FieldDef {
  final String rawName;
  final String name;
  final JsonTypeInfo type;
  final bool nullable;
  final bool required;

  FieldDef({
    required this.rawName,
    required this.name,
    required this.type,
    required this.nullable,
    required this.required,
  });

  FieldDef copyWith({
    String? name,
    JsonTypeInfo? type,
    bool? nullable,
    bool? required,
  }) =>
      FieldDef(
        rawName: rawName,
        name: name ?? this.name,
        type: type ?? this.type,
        nullable: nullable ?? this.nullable,
        required: required ?? this.required,
      );
}

class JsonTypeInfo {
  final JsonKind kind;
  final bool nullable;
  String? className;
  JsonTypeInfo? itemType;

  JsonTypeInfo({
    required this.kind,
    this.nullable = false,
    this.className,
    this.itemType,
  });

  JsonTypeInfo copy() => JsonTypeInfo(
    kind: kind,
    nullable: nullable,
    className: className,
    itemType: itemType?.copy(),
  );

  bool get isPrimitive =>
      kind == JsonKind.string ||
          kind == JsonKind.integer ||
          kind == JsonKind.double ||
          kind == JsonKind.boolean;

  bool get isObject => kind == JsonKind.object;

  bool get isArray => kind == JsonKind.array;

  bool get isDynamic =>
      kind == JsonKind.nullKind || kind == JsonKind.object && className == null;
}

class ClassDef {
  final String name;
  final List<FieldDef> fields;
  bool isRoot;

  ClassDef({
    required this.name,
    required this.fields,
    this.isRoot = false,
  });
}

class AnalysisResult {
  final List<ClassDef> classes;
  final String rootClassName;
  final bool rootIsArray;
  final bool rootIsPrimitive;
  final JsonTypeInfo? rootType;

  AnalysisResult({
    required this.classes,
    required this.rootClassName,
    this.rootIsArray = false,
    this.rootIsPrimitive = false,
    this.rootType,
  });

  bool get isEmpty => classes.isEmpty && rootType == null;
}

class Analyzer {
  Analyzer({
    required this.rootClassName,
    this.caseStyle = NameCase.camel,
  });

  final String rootClassName;
  final NameCase caseStyle;

  final Map<String, ClassDef> _classes = <String, ClassDef>{};
  final Set<String> _usedClassNames = <String>{};

  AnalysisResult analyze(String jsonText) {
    _classes.clear();
    _usedClassNames.clear();

    final String trimmed = jsonText.trim();
    if (trimmed.isEmpty) {
      return AnalysisResult(classes: <ClassDef>[], rootClassName: rootClassName);
    }

    final dynamic decoded = jsonDecode(trimmed);

    if (decoded == null) {
      return AnalysisResult(
        classes: <ClassDef>[],
        rootClassName: rootClassName,
        rootType: JsonTypeInfo(kind: JsonKind.nullKind, nullable: true),
        rootIsPrimitive: true,
      );
    }

    if (decoded is Map<String, dynamic>) {
      final String cls = _reserveClassName(rootClassName);
      _buildClass(cls, decoded);
      _classes[cls]!.isRoot = true;
      return AnalysisResult(
        classes: _orderedClasses(),
        rootClassName: cls,
        rootType: JsonTypeInfo(kind: JsonKind.object, className: cls),
      );
    }

    if (decoded is List) {
      final JsonTypeInfo itemType = _analyzeArray(
        decoded,
        _singularize(rootClassName),
      );
      return AnalysisResult(
        classes: _orderedClasses(),
        rootClassName: rootClassName,
        rootIsArray: true,
        rootType: JsonTypeInfo(
          kind: JsonKind.array,
          itemType: itemType,
        ),
      );
    }

    final JsonTypeInfo primitive = _detectKind(decoded);
    return AnalysisResult(
      classes: <ClassDef>[],
      rootClassName: rootClassName,
      rootIsPrimitive: true,
      rootType: primitive,
    );
  }

  void _buildClass(String className, Map<String, dynamic> map) {
    final List<FieldDef> fields = <FieldDef>[];

    for (final MapEntry<String, dynamic> e in map.entries) {
      final String rawKey = e.key;
      final String fieldName = NameConverter.convert(rawKey, caseStyle);
      final JsonTypeInfo type = _analyzeValue(e.value, rawKey, className);
      fields.add(
        FieldDef(
          rawName: rawKey,
          name: fieldName,
          type: type,
          nullable: type.nullable,
          required: !type.nullable,
        ),
      );
    }

    _classes[className] = ClassDef(name: className, fields: fields);
  }

  JsonTypeInfo _analyzeValue(dynamic value, String keyHint, String parentClass) {
    if (value == null) {
      return JsonTypeInfo(kind: JsonKind.nullKind, nullable: true);
    }
    if (value is Map<String, dynamic>) {
      final String child = _reserveClassName(
        _pascalCase(_singularize(keyHint)),
        parentHint: parentClass,
      );
      _buildClass(child, value);
      return JsonTypeInfo(kind: JsonKind.object, className: child);
    }
    if (value is List) {
      final JsonTypeInfo item = _analyzeArray(value, _singularize(keyHint));
      return JsonTypeInfo(kind: JsonKind.array, itemType: item);
    }
    return _detectKind(value);
  }

  JsonTypeInfo _analyzeArray(List<dynamic> list, String itemNameHint) {
    if (list.isEmpty) {
      return JsonTypeInfo(kind: JsonKind.object, nullable: true);
    }

    JsonTypeInfo? merged;
    bool allNull = true;

    for (final dynamic item in list) {
      if (item != null) allNull = false;
      final JsonTypeInfo current = _analyzeArrayItem(item, itemNameHint);
      merged = merged == null ? current : _mergeTypes(merged, current);
    }

    if (allNull) {
      return JsonTypeInfo(kind: JsonKind.nullKind, nullable: true);
    }

    return merged ?? JsonTypeInfo(kind: JsonKind.object, nullable: true);
  }

  JsonTypeInfo _analyzeArrayItem(dynamic item, String nameHint) {
    if (item == null) {
      return JsonTypeInfo(kind: JsonKind.nullKind, nullable: true);
    }
    if (item is Map<String, dynamic>) {
      final String child = _reserveClassName(_pascalCase(nameHint));
      _buildClass(child, item);
      return JsonTypeInfo(kind: JsonKind.object, className: child);
    }
    if (item is List) {
      final JsonTypeInfo nested = _analyzeArray(item, nameHint);
      return JsonTypeInfo(kind: JsonKind.array, itemType: nested);
    }
    return _detectKind(item);
  }

  JsonTypeInfo _detectKind(dynamic value) {
    if (value == null) {
      return JsonTypeInfo(kind: JsonKind.nullKind, nullable: true);
    }
    if (value is String) return JsonTypeInfo(kind: JsonKind.string);
    if (value is bool) return JsonTypeInfo(kind: JsonKind.boolean);
    if (value is int) return JsonTypeInfo(kind: JsonKind.integer);
    if (value is double) return JsonTypeInfo(kind: JsonKind.double);
    if (value is num) {
      return JsonTypeInfo(
        kind: value is int ? JsonKind.integer : JsonKind.double,
      );
    }
    return JsonTypeInfo(kind: JsonKind.string);
  }

  JsonTypeInfo _mergeTypes(JsonTypeInfo a, JsonTypeInfo b) {
    if (a.kind == JsonKind.nullKind && b.kind == JsonKind.nullKind) {
      return JsonTypeInfo(kind: JsonKind.nullKind, nullable: true);
    }

    final bool nullable = a.nullable || b.nullable;

    if (a.kind == JsonKind.nullKind) {
      return JsonTypeInfo(
        kind: b.kind,
        nullable: true,
        className: b.className,
        itemType: b.itemType,
      );
    }
    if (b.kind == JsonKind.nullKind) {
      return JsonTypeInfo(
        kind: a.kind,
        nullable: true,
        className: a.className,
        itemType: a.itemType,
      );
    }

    if (a.kind == b.kind) {
      if (a.kind == JsonKind.object) {
        if (a.className == b.className) {
          return JsonTypeInfo(
            kind: JsonKind.object,
            nullable: nullable,
            className: a.className,
          );
        }
        return JsonTypeInfo(kind: JsonKind.object, nullable: nullable);
      }
      if (a.kind == JsonKind.array) {
        final JsonTypeInfo? itemA = a.itemType;
        final JsonTypeInfo? itemB = b.itemType;
        if (itemA == null || itemB == null) {
          return JsonTypeInfo(kind: JsonKind.array, nullable: nullable);
        }
        return JsonTypeInfo(
          kind: JsonKind.array,
          nullable: nullable,
          itemType: _mergeTypes(itemA, itemB),
        );
      }
      return JsonTypeInfo(kind: a.kind, nullable: nullable);
    }

    if ((a.kind == JsonKind.integer && b.kind == JsonKind.double) ||
        (a.kind == JsonKind.double && b.kind == JsonKind.integer)) {
      return JsonTypeInfo(kind: JsonKind.double, nullable: nullable);
    }

    return JsonTypeInfo(kind: JsonKind.string, nullable: nullable);
  }

  String _reserveClassName(String base, {String? parentHint}) {
    String candidate = _pascalCase(base);
    if (candidate.isEmpty) candidate = 'Item';

    if (parentHint != null &&
        candidate == _pascalCase(parentHint)) {
      candidate = '${candidate}Item';
    }

    String unique = candidate;
    int i = 2;
    while (_usedClassNames.contains(unique)) {
      unique = '$candidate$i';
      i++;
    }
    _usedClassNames.add(unique);
    return unique;
  }

  List<ClassDef> _orderedClasses() {
    final List<ClassDef> ordered = _classes.values.toList();
    ordered.sort((ClassDef a, ClassDef b) {
      if (a.isRoot) return -1;
      if (b.isRoot) return 1;
      return a.name.compareTo(b.name);
    });
    return ordered;
  }

  static String _pascalCase(String input) {
    if (input.isEmpty) return '';
    final List<String> parts = NameConverter.splitWords(input);
    return parts.map(NameConverter.capitalize).join();
  }

  static String _singularize(String input) {
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
}

enum NameCase {
  camel,
  snake,
  pascal,
  kebab,
  original,
}

class NameConverter {
  NameConverter._();

  static String convert(String input, NameCase style) {
    switch (style) {
      case NameCase.original:
        return input;
      case NameCase.camel:
        return toCamel(input);
      case NameCase.snake:
        return toSnake(input);
      case NameCase.pascal:
        return toPascal(input);
      case NameCase.kebab:
        return toKebab(input);
    }
  }

  static String toCamel(String input) {
    final List<String> parts = splitWords(input);
    if (parts.isEmpty) return '';
    final StringBuffer sb = StringBuffer(parts.first.toLowerCase());
    for (int i = 1; i < parts.length; i++) {
      sb.write(capitalize(parts[i].toLowerCase()));
    }
    return _sanitize(sb.toString());
  }

  static String toPascal(String input) {
    final List<String> parts = splitWords(input);
    return _sanitize(parts.map((String p) => capitalize(p.toLowerCase())).join());
  }

  static String toSnake(String input) {
    final List<String> parts = splitWords(input);
    return _sanitize(parts.map((String p) => p.toLowerCase()).join('_'));
  }

  static String toKebab(String input) {
    final List<String> parts = splitWords(input);
    return _sanitize(parts.map((String p) => p.toLowerCase()).join('-'));
  }

  static List<String> splitWords(String input) {
    if (input.isEmpty) return <String>[];

    final String normalized = input
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), ' ')
        .replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'),
          (Match m) => '${m[1]} ${m[2]}',
    )
        .replaceAllMapped(
      RegExp(r'([A-Z]+)([A-Z][a-z])'),
          (Match m) => '${m[1]} ${m[2]}',
    );

    return normalized
        .split(RegExp(r'\s+'))
        .where((String s) => s.isNotEmpty)
        .toList();
  }

  static String capitalize(String input) {
    if (input.isEmpty) return '';
    return input[0].toUpperCase() + input.substring(1);
  }

  static String _sanitize(String input) {
    if (input.isEmpty) return input;
    if (RegExp(r'^[0-9]').hasMatch(input)) {
      return 'n$input';
    }
    return input;
  }

  static bool isReserved(String word, CodeLanguage lang) {
    final String lower = word.toLowerCase();
    switch (lang) {
      case CodeLanguage.dart:
        return _dartReserved.contains(lower);
      case CodeLanguage.typescript:
        return _tsReserved.contains(lower);
      case CodeLanguage.python:
        return _pyReserved.contains(lower);
      case CodeLanguage.kotlin:
        return _ktReserved.contains(lower);
      case CodeLanguage.swift:
        return _swiftReserved.contains(lower);
      case CodeLanguage.java:
        return _javaReserved.contains(lower);
      case CodeLanguage.csharp:
        return _csReserved.contains(lower);
      case CodeLanguage.go:
        return _goReserved.contains(lower);
    }
  }

  static const Set<String> _dartReserved = <String>{
    'abstract', 'as', 'assert', 'async', 'await', 'break', 'case', 'catch',
    'class', 'const', 'continue', 'covariant', 'default', 'deferred', 'do',
    'dynamic', 'else', 'enum', 'export', 'extends', 'extension', 'external',
    'factory', 'false', 'final', 'finally', 'for', 'function', 'get', 'hide',
    'if', 'implements', 'import', 'in', 'interface', 'is', 'late', 'library',
    'mixin', 'new', 'null', 'on', 'operator', 'part', 'required', 'rethrow',
    'return', 'set', 'show', 'static', 'super', 'switch', 'sync', 'this',
    'throw', 'true', 'try', 'typedef', 'var', 'void', 'while', 'with', 'yield',
  };

  static const Set<String> _tsReserved = <String>{
    'break', 'case', 'catch', 'class', 'const', 'continue', 'debugger',
    'default', 'delete', 'do', 'else', 'enum', 'export', 'extends', 'false',
    'finally', 'for', 'function', 'if', 'import', 'in', 'instanceof', 'new',
    'null', 'return', 'super', 'switch', 'this', 'throw', 'true', 'try',
    'typeof', 'var', 'void', 'while', 'with', 'as', 'implements', 'interface',
    'let', 'package', 'private', 'protected', 'public', 'static', 'yield',
  };

  static const Set<String> _pyReserved = <String>{
    'false', 'none', 'true', 'and', 'as', 'assert', 'async', 'await', 'break',
    'class', 'continue', 'def', 'del', 'elif', 'else', 'except', 'finally',
    'for', 'from', 'global', 'if', 'import', 'in', 'is', 'lambda', 'nonlocal',
    'not', 'or', 'pass', 'raise', 'return', 'try', 'while', 'with', 'yield',
  };

  static const Set<String> _ktReserved = <String>{
    'as', 'break', 'class', 'continue', 'do', 'else', 'false', 'for', 'fun',
    'if', 'in', 'interface', 'is', 'null', 'object', 'package', 'return',
    'super', 'this', 'throw', 'true', 'try', 'typealias', 'typeof', 'val',
    'var', 'when', 'while', 'by', 'catch', 'constructor', 'delegate', 'dynamic',
    'field', 'file', 'finally', 'get', 'import', 'init', 'param', 'property',
    'receiver', 'set', 'setparam', 'where', 'actual', 'abstract', 'annotation',
    'companion', 'const', 'crossinline', 'data', 'enum', 'expect', 'external',
    'final', 'infix', 'inline', 'inner', 'internal', 'lateinit', 'noinline',
    'open', 'operator', 'out', 'override', 'private', 'protected', 'public',
    'reified', 'sealed', 'suspend', 'tailrec', 'vararg',
  };

  static const Set<String> _swiftReserved = <String>{
    'associatedtype', 'class', 'deinit', 'enum', 'extension', 'fileprivate',
    'func', 'import', 'init', 'inout', 'internal', 'let', 'open', 'operator',
    'private', 'protocol', 'public', 'static', 'struct', 'subscript', 'typealias',
    'var', 'break', 'case', 'continue', 'default', 'defer', 'do', 'else',
    'fallthrough', 'for', 'guard', 'if', 'in', 'repeat', 'return', 'switch',
    'where', 'while', 'as', 'any', 'catch', 'false', 'is', 'nil', 'rethrows',
    'super', 'self', 'throw', 'throws', 'true', 'try',
  };

  static const Set<String> _javaReserved = <String>{
    'abstract', 'assert', 'boolean', 'break', 'byte', 'case', 'catch', 'char',
    'class', 'const', 'continue', 'default', 'do', 'double', 'else', 'enum',
    'extends', 'final', 'finally', 'float', 'for', 'goto', 'if', 'implements',
    'import', 'instanceof', 'int', 'interface', 'long', 'native', 'new',
    'package', 'private', 'protected', 'public', 'return', 'short', 'static',
    'strictfp', 'super', 'switch', 'synchronized', 'this', 'throw', 'throws',
    'transient', 'try', 'void', 'volatile', 'while', 'true', 'false', 'null',
  };

  static const Set<String> _csReserved = <String>{
    'abstract', 'as', 'base', 'bool', 'break', 'byte', 'case', 'catch', 'char',
    'checked', 'class', 'const', 'continue', 'decimal', 'default', 'delegate',
    'do', 'double', 'else', 'enum', 'event', 'explicit', 'extern', 'false',
    'finally', 'fixed', 'float', 'for', 'foreach', 'goto', 'if', 'implicit',
    'in', 'int', 'interface', 'internal', 'is', 'lock', 'long', 'namespace',
    'new', 'null', 'object', 'operator', 'out', 'override', 'params', 'private',
    'protected', 'public', 'readonly', 'ref', 'return', 'sbyte', 'sealed',
    'short', 'sizeof', 'stackalloc', 'static', 'string', 'struct', 'switch',
    'this', 'throw', 'true', 'try', 'typeof', 'uint', 'ulong', 'unchecked',
    'unsafe', 'ushort', 'using', 'virtual', 'void', 'volatile', 'while',
  };

  static const Set<String> _goReserved = <String>{
    'break', 'case', 'chan', 'const', 'continue', 'default', 'defer', 'else',
    'fallthrough', 'for', 'func', 'go', 'goto', 'if', 'import', 'interface',
    'map', 'package', 'range', 'return', 'select', 'struct', 'switch', 'type',
    'var', 'true', 'false', 'nil', 'int', 'string', 'bool', 'byte', 'rune',
    'float32', 'float64', 'complex64', 'complex128', 'uint', 'uint8', 'uint16',
    'uint32', 'uint64', 'int8', 'int16', 'int32', 'int64', 'error', 'any',
  };
}