import 'analyzer.dart';
import 'models.dart';

class CodeGenerator {
  CodeGenerator({
    required this.result,
    required this.language,
    required this.options,
  });

  final AnalysisResult result;
  final CodeLanguage language;
  final GenerationOptions options;

  String generate() {
    if (result.isEmpty) return '';

    if (result.rootIsPrimitive) {
      return _generatePrimitiveRoot();
    }

    final StringBuffer sb = StringBuffer();
    _writeHeader(sb);

    if (result.rootIsArray && result.rootType?.itemType != null) {
      _writeArrayRoot(sb, result.rootType!.itemType!);
    }

    final List<ClassDef> ordered = _ordered();
    for (int i = 0; i < ordered.length; i++) {
      _writeClass(sb, ordered[i]);
      if (i < ordered.length - 1) sb.writeln();
    }

    return sb.toString().trimRight();
  }

  List<ClassDef> _ordered() {
    final List<ClassDef> list = List<ClassDef>.from(result.classes);
    list.sort((ClassDef a, ClassDef b) {
      if (a.isRoot == b.isRoot) {
        return a.name.compareTo(b.name);
      }
      return a.isRoot ? -1 : 1;
    });
    return list;
  }

  void _writeHeader(StringBuffer sb) {
    switch (language) {
      case CodeLanguage.dart:
        break;
      case CodeLanguage.typescript:
        break;
      case CodeLanguage.python:
        sb.writeln('from __future__ import annotations');
        sb.writeln('from dataclasses import dataclass');
        sb.writeln('from typing import Any, Dict, List, Optional');
        sb.writeln();
        break;
      case CodeLanguage.kotlin:
        if (language.supportsPackage) {
          sb.writeln('package ${options.packageName}');
          sb.writeln();
        }
        break;
      case CodeLanguage.swift:
        sb.writeln('import Foundation');
        sb.writeln();
        break;
      case CodeLanguage.java:
        if (language.supportsPackage) {
          sb.writeln('package ${options.packageName};');
          sb.writeln();
        }
        sb.writeln('import java.util.*;');
        sb.writeln();
        break;
      case CodeLanguage.csharp:
        sb.writeln('using System;');
        sb.writeln('using System.Collections.Generic;');
        if (language.supportsPackage) {
          sb.writeln();
          sb.writeln('namespace ${options.packageName}');
          sb.writeln('{');
        }
        sb.writeln();
        break;
      case CodeLanguage.go:
        if (language.supportsPackage) {
          final String pkg = _goPackageName(options.packageName);
          sb.writeln('package $pkg');
          sb.writeln();
        }
        break;
    }
  }

  String _goPackageName(String input) {
    final List<String> parts = NameConverter.splitWords(input);
    if (parts.isEmpty) return 'main';
    return parts.map((String p) => p.toLowerCase()).join();
  }

  String _generatePrimitiveRoot() {
    final JsonTypeInfo type = result.rootType!;
    switch (language) {
      case CodeLanguage.dart:
        return '// root type: ${_dartType(type)}${type.nullable ? "?" : ""}';
      case CodeLanguage.typescript:
        return '// root type: ${_tsType(type)}${type.nullable ? " | null" : ""}';
      case CodeLanguage.python:
        return '# root type: ${_pyType(type)}';
      case CodeLanguage.kotlin:
        return '// root type: ${_ktType(type)}${type.nullable ? "?" : ""}';
      case CodeLanguage.swift:
        return '// root type: ${_swiftType(type)}${type.nullable ? "?" : ""}';
      case CodeLanguage.java:
        return '// root type: ${_javaType(type)}';
      case CodeLanguage.csharp:
        return '// root type: ${_csType(type)}${type.nullable ? "?" : ""}';
      case CodeLanguage.go:
        return '// root type: ${_goType(type)}';
    }
  }

  void _writeArrayRoot(StringBuffer sb, JsonTypeInfo itemType) {
    switch (language) {
      case CodeLanguage.dart:
        sb.writeln(
          'typedef ${result.rootClassName} = List<${_dartType(itemType)}>;',
        );
        sb.writeln();
        break;
      case CodeLanguage.typescript:
        sb.writeln(
          'export type ${result.rootClassName} = ${_tsType(itemType)}[];',
        );
        sb.writeln();
        break;
      case CodeLanguage.python:
        sb.writeln(
          '${result.rootClassName} = List[${_pyType(itemType)}]',
        );
        sb.writeln();
        break;
      case CodeLanguage.kotlin:
        sb.writeln(
          'typealias ${result.rootClassName} = List<${_ktType(itemType)}>',
        );
        sb.writeln();
        break;
      case CodeLanguage.swift:
        sb.writeln(
          'typealias ${result.rootClassName} = [${_swiftType(itemType)}]',
        );
        sb.writeln();
        break;
      case CodeLanguage.java:
        break;
      case CodeLanguage.csharp:
        break;
      case CodeLanguage.go:
        break;
    }
  }

  void _writeClass(StringBuffer sb, ClassDef cls) {
    switch (language) {
      case CodeLanguage.dart:
        _dartClass(sb, cls);
        break;
      case CodeLanguage.typescript:
        _tsClass(sb, cls);
        break;
      case CodeLanguage.python:
        _pyClass(sb, cls);
        break;
      case CodeLanguage.kotlin:
        _ktClass(sb, cls);
        break;
      case CodeLanguage.swift:
        _swiftClass(sb, cls);
        break;
      case CodeLanguage.java:
        _javaClass(sb, cls);
        break;
      case CodeLanguage.csharp:
        _csClass(sb, cls);
        break;
      case CodeLanguage.go:
        _goClass(sb, cls);
        break;
    }
  }

  // ---------------- DART ----------------

  void _dartClass(StringBuffer sb, ClassDef cls) {
    sb.writeln('class ${cls.name} {');
    for (final FieldDef f in cls.fields) {
      sb.write('  ');
      if (options.immutable) sb.write('final ');
      sb.write('${_dartTypeForField(f)} ${f.name};');
      sb.writeln();
    }
    sb.writeln();

    _dartConstructor(sb, cls);
    if (options.generateFromJson) _dartFromJson(sb, cls);
    if (options.generateToJson) _dartToJson(sb, cls);
    if (options.generateCopyWith) _dartCopyWith(sb, cls);
    if (options.generateEquatable) _dartEquatable(sb, cls);

    sb.writeln('}');
  }

  void _dartConstructor(StringBuffer sb, ClassDef cls) {
    sb.writeln('  ${cls.name}({');
    for (final FieldDef f in cls.fields) {
      if (options.immutable || f.required) {
        sb.writeln('    required this.${f.name},');
      } else {
        sb.writeln('    this.${f.name},');
      }
    }
    sb.writeln('  });');
    sb.writeln();
  }

  void _dartFromJson(StringBuffer sb, ClassDef cls) {
    sb.writeln('  factory ${cls.name}.fromJson(Map<String, dynamic> json) {');
    sb.writeln('    return ${cls.name}(');
    for (final FieldDef f in cls.fields) {
      sb.write('      ${f.name}: ');
      sb.write(_dartFromJsonValue(f));
      sb.writeln(',');
    }
    sb.writeln('    );');
    sb.writeln('  }');
    sb.writeln();
  }

  String _dartFromJsonValue(FieldDef f) {
    final String access = "json['${f.rawName}']";
    final JsonTypeInfo t = f.type;
    if (t.kind == JsonKind.nullKind) return access;
    if (t.isPrimitive) return _dartCastPrimitive(t, access, f.nullable);
    if (t.isArray) {
      final JsonTypeInfo? item = t.itemType;
      if (item == null) return '$access as List';
      final String itemCast = _dartItemCast(item, 'e');
      final String list = '($access as List).map((e) => $itemCast).toList()';
      return f.nullable ? '$access == null ? null : $list' : list;
    }
    if (t.isObject) {
      if (t.className == null) return '$access as Map<String, dynamic>';
      final String c =
          '$access == null ? null : ${t.className}.fromJson($access as Map<String, dynamic>)';
      return f.nullable
          ? c
          : '${t.className}.fromJson($access as Map<String, dynamic>)';
    }
    return access;
  }

  String _dartItemCast(JsonTypeInfo t, String varName) {
    if (t.isPrimitive) return _dartCastPrimitive(t, varName, false);
    if (t.isObject && t.className != null) {
      return '${t.className}.fromJson($varName as Map<String, dynamic>)';
    }
    if (t.isArray && t.itemType != null) {
      return '($varName as List).map((x) => ${_dartItemCast(t.itemType!, "x")}).toList()';
    }
    return varName;
  }

  String _dartCastPrimitive(JsonTypeInfo t, String access, bool nullable) {
    switch (t.kind) {
      case JsonKind.string:
        return nullable ? '$access as String?' : '$access as String';
      case JsonKind.integer:
        return nullable
            ? '($access as num?)?.toInt()'
            : '($access as num).toInt()';
      case JsonKind.double:
        return nullable
            ? '($access as num?)?.toDouble()'
            : '($access as num).toDouble()';
      case JsonKind.boolean:
        return nullable ? '$access as bool?' : '$access as bool';
      default:
        return access;
    }
  }

  void _dartToJson(StringBuffer sb, ClassDef cls) {
    sb.writeln('  Map<String, dynamic> toJson() {');
    sb.writeln('    return <String, dynamic>{');
    for (final FieldDef f in cls.fields) {
      sb.write("      '${f.rawName}': ");
      sb.write(_dartToJsonValue(f));
      sb.writeln(',');
    }
    sb.writeln('    };');
    sb.writeln('  }');
    sb.writeln();
  }

  String _dartToJsonValue(FieldDef f) {
    final String access = f.name;
    final JsonTypeInfo t = f.type;
    if (t.isPrimitive || t.kind == JsonKind.nullKind) return access;
    if (t.isObject && t.className != null) {
      return f.nullable ? '$access?.toJson()' : '$access.toJson()';
    }
    if (t.isArray) {
      final JsonTypeInfo? item = t.itemType;
      if (item == null) return access;
      final String inner = _dartToJsonItem(item, 'e');
      if (inner == 'e') return access;
      return '$access.map((e) => $inner).toList()';
    }
    return access;
  }

  String _dartToJsonItem(JsonTypeInfo t, String v) {
    if (t.isObject && t.className != null) return '$v.toJson()';
    if (t.isArray && t.itemType != null) {
      return '$v.map((x) => ${_dartToJsonItem(t.itemType!, "x")}).toList()';
    }
    return v;
  }

  void _dartCopyWith(StringBuffer sb, ClassDef cls) {
    sb.writeln('  ${cls.name} copyWith({');
    for (final FieldDef f in cls.fields) {
      sb.writeln('    ${_dartTypeForField(f)}? ${f.name},');
    }
    sb.writeln('  }) {');
    sb.writeln('    return ${cls.name}(');
    for (final FieldDef f in cls.fields) {
      sb.writeln('      ${f.name}: ${f.name} ?? this.${f.name},');
    }
    sb.writeln('    );');
    sb.writeln('  }');
    sb.writeln();
  }

  void _dartEquatable(StringBuffer sb, ClassDef cls) {
    sb.writeln('  @override');
    sb.writeln('  bool operator ==(Object other) {');
    sb.writeln('    if (identical(this, other)) return true;');
    sb.writeln('    return other is ${cls.name}');
    if (cls.fields.isEmpty) {
      sb.writeln(';');
    } else {
      for (final FieldDef f in cls.fields) {
        sb.writeln('        && other.${f.name} == ${f.name}');
      }
      sb.writeln(';');
    }
    sb.writeln('  }');
    sb.writeln();
    sb.writeln('  @override');
    sb.writeln('  int get hashCode {');
    if (cls.fields.isEmpty) {
      sb.writeln('    return runtimeType.hashCode;');
    } else if (cls.fields.length == 1) {
      sb.writeln('    return ${cls.fields.first.name}.hashCode;');
    } else {
      sb.write('    return Object.hash(');
      sb.write(cls.fields.map((FieldDef f) => f.name).join(', '));
      sb.writeln(');');
    }
    sb.writeln('  }');
    sb.writeln();
  }

  String _dartTypeForField(FieldDef f) {
    String type = _dartType(f.type);
    if (options.nullSafety && f.type.nullable) type = '$type?';
    return type;
  }

  String _dartType(JsonTypeInfo t) {
    switch (t.kind) {
      case JsonKind.string:
        return 'String';
      case JsonKind.integer:
        return 'int';
      case JsonKind.double:
        return 'double';
      case JsonKind.boolean:
        return 'bool';
      case JsonKind.nullKind:
        return 'dynamic';
      case JsonKind.object:
        return t.className ?? 'Map<String, dynamic>';
      case JsonKind.array:
        if (t.itemType == null) return 'List<dynamic>';
        return 'List<${_dartType(t.itemType!)}>';
    }
  }

  // ---------------- TYPESCRIPT ----------------

  void _tsClass(StringBuffer sb, ClassDef cls) {
    sb.writeln('export interface ${cls.name} {');
    for (final FieldDef f in cls.fields) {
      sb.write('  ');
      if (options.immutable) sb.write('readonly ');
      sb.write(_tsName(f.name));
      sb.write(options.nullSafety && f.type.nullable ? '?' : '');
      sb.write(': ');
      sb.write(_tsTypeForField(f));
      sb.writeln(';');
    }
    sb.writeln('}');
    sb.writeln();

    if (options.generateFromJson) _tsFromJson(sb, cls);
    if (options.generateToJson) _tsToJson(sb, cls);
  }

  String _tsName(String name) {
    if (NameConverter.isReserved(name, CodeLanguage.typescript)) {
      return '_$name';
    }
    return name;
  }

  String _tsTypeForField(FieldDef f) {
    String type = _tsType(f.type);
    if (options.nullSafety && f.type.nullable && !type.contains('null')) {
      type = '$type | null';
    }
    return type;
  }

  String _tsType(JsonTypeInfo t) {
    switch (t.kind) {
      case JsonKind.string:
        return 'string';
      case JsonKind.integer:
      case JsonKind.double:
        return 'number';
      case JsonKind.boolean:
        return 'boolean';
      case JsonKind.nullKind:
        return 'any';
      case JsonKind.object:
        return t.className ?? 'Record<string, any>';
      case JsonKind.array:
        if (t.itemType == null) return 'any[]';
        final String inner = _tsType(t.itemType!);
        if (inner.contains('|')) return '($inner)[]';
        return '$inner[]';
    }
  }

  void _tsFromJson(StringBuffer sb, ClassDef cls) {
    sb.writeln(
      'export function ${_lowerFirst(cls.name)}FromJson(json: any): ${cls.name} {',
    );
    sb.writeln('  return {');
    for (final FieldDef f in cls.fields) {
      sb.write('    ${_tsName(f.name)}: ');
      sb.write(_tsParseValue(f, 'json["${f.rawName}"]'));
      sb.writeln(',');
    }
    sb.writeln('  };');
    sb.writeln('}');
    sb.writeln();
  }

  String _tsParseValue(FieldDef f, String access) {
    final JsonTypeInfo t = f.type;
    if (t.isPrimitive || t.kind == JsonKind.nullKind) return access;
    if (t.isObject && t.className != null) {
      return '${_lowerFirst(t.className!)}FromJson($access)';
    }
    if (t.isArray && t.itemType != null) {
      final JsonTypeInfo item = t.itemType!;
      if (item.isObject && item.className != null) {
        return '$access.map((item: any) => ${_lowerFirst(item.className!)}FromJson(item))';
      }
      return access;
    }
    return access;
  }

  void _tsToJson(StringBuffer sb, ClassDef cls) {
    sb.writeln(
      'export function ${_lowerFirst(cls.name)}ToJson(value: ${cls.name}): any {',
    );
    sb.writeln('  return {');
    for (final FieldDef f in cls.fields) {
      sb.write('    "${f.rawName}": ');
      sb.write(_tsToJsonValue(f));
      sb.writeln(',');
    }
    sb.writeln('  };');
    sb.writeln('}');
    sb.writeln();
  }

  String _tsToJsonValue(FieldDef f) {
    final String access = 'value.${_tsName(f.name)}';
    final JsonTypeInfo t = f.type;
    if (t.isObject && t.className != null) {
      return '${_lowerFirst(t.className!)}ToJson($access)';
    }
    return access;
  }

  String _lowerFirst(String s) {
    if (s.isEmpty) return s;
    return s[0].toLowerCase() + s.substring(1);
  }

  // ---------------- PYTHON ----------------

  void _pyClass(StringBuffer sb, ClassDef cls) {
    if (options.immutable) {
      sb.writeln('@dataclass(frozen=True)');
    } else {
      sb.writeln('@dataclass');
    }
    sb.writeln('class ${cls.name}:');
    if (cls.fields.isEmpty) {
      sb.writeln('    pass');
      sb.writeln();
      return;
    }
    for (final FieldDef f in cls.fields) {
      sb.write('    ${f.name}: ');
      sb.write(_pyTypeForField(f));
      sb.writeln();
    }
    sb.writeln();

    if (options.generateFromJson) _pyFromJson(sb, cls);
    if (options.generateToJson) _pyToJson(sb, cls);
  }

  String _pyTypeForField(FieldDef f) {
    String type = _pyType(f.type);
    if (f.type.nullable) {
      return 'Optional[$type]';
    }
    return type;
  }

  String _pyType(JsonTypeInfo t) {
    switch (t.kind) {
      case JsonKind.string:
        return 'str';
      case JsonKind.integer:
        return 'int';
      case JsonKind.double:
        return 'float';
      case JsonKind.boolean:
        return 'bool';
      case JsonKind.nullKind:
        return 'Any';
      case JsonKind.object:
        return t.className ?? 'Dict[str, Any]';
      case JsonKind.array:
        if (t.itemType == null) return 'List[Any]';
        return 'List[${_pyType(t.itemType!)}]';
    }
  }

  void _pyFromJson(StringBuffer sb, ClassDef cls) {
    sb.writeln('    @staticmethod');
    sb.writeln('    def from_json(data: Dict[str, Any]) -> "${cls.name}":');
    sb.writeln('        return ${cls.name}(');
    for (final FieldDef f in cls.fields) {
      sb.write('            ${f.name}=');
      sb.write(_pyParseValue(f, 'data.get("${f.rawName}")'));
      sb.writeln(',');
    }
    sb.writeln('        )');
    sb.writeln();
  }

  String _pyParseValue(FieldDef f, String access) {
    final JsonTypeInfo t = f.type;
    if (t.isPrimitive || t.kind == JsonKind.nullKind) return access;
    if (t.isObject && t.className != null) {
      return '$access and ${t.className}.from_json($access)';
    }
    if (t.isArray && t.itemType != null) {
      final JsonTypeInfo item = t.itemType!;
      if (item.isObject && item.className != null) {
        return '[$access and ${item.className}.from_json(x) for x in $access]';
      }
      return access;
    }
    return access;
  }

  void _pyToJson(StringBuffer sb, ClassDef cls) {
    sb.writeln('    def to_json(self) -> Dict[str, Any]:');
    sb.writeln('        return {');
    for (final FieldDef f in cls.fields) {
      sb.write('            "${f.rawName}": ');
      sb.write(_pyToJsonValue(f));
      sb.writeln(',');
    }
    sb.writeln('        }');
    sb.writeln();
  }

  String _pyToJsonValue(FieldDef f) {
    final String access = 'self.${f.name}';
    final JsonTypeInfo t = f.type;
    if (t.isObject && t.className != null) {
      return '$access.to_json() if $access else None';
    }
    return access;
  }

  // ---------------- KOTLIN ----------------

  void _ktClass(StringBuffer sb, ClassDef cls) {
    sb.write('data class ${cls.name}(');
    sb.writeln();
    final int n = cls.fields.length;
    for (int i = 0; i < n; i++) {
      final FieldDef f = cls.fields[i];
      sb.write('    val ${_ktName(f.name)}: ${_ktTypeForField(f)}');
      if (!f.required) {
        sb.write(' = null');
      }
      if (i < n - 1) sb.write(',');
      sb.writeln();
    }
    sb.writeln(')');
    if (options.generateFromJson || options.generateToJson) {
      sb.writeln('{');
      if (options.generateFromJson) _ktFromJson(sb, cls);
      if (options.generateToJson) _ktToJson(sb, cls);
      sb.writeln('}');
    }
    sb.writeln();
  }

  String _ktName(String name) {
    if (NameConverter.isReserved(name, CodeLanguage.kotlin)) {
      return '`$name`';
    }
    return name;
  }

  String _ktTypeForField(FieldDef f) {
    String type = _ktType(f.type);
    if (f.type.nullable) return '$type?';
    return type;
  }

  String _ktType(JsonTypeInfo t) {
    switch (t.kind) {
      case JsonKind.string:
        return 'String';
      case JsonKind.integer:
        return 'Int';
      case JsonKind.double:
        return 'Double';
      case JsonKind.boolean:
        return 'Boolean';
      case JsonKind.nullKind:
        return 'Any';
      case JsonKind.object:
        return t.className ?? 'Map<String, Any>';
      case JsonKind.array:
        if (t.itemType == null) return 'List<Any>';
        return 'List<${_ktType(t.itemType!)}>';
    }
  }

  void _ktFromJson(StringBuffer sb, ClassDef cls) {
    sb.writeln('    companion object {');
    sb.writeln('        fun fromJson(map: Map<String, Any?>): ${cls.name} {');
    sb.writeln('            return ${cls.name}(');
    for (final FieldDef f in cls.fields) {
      sb.write('                ${_ktName(f.name)} = ');
      sb.write(_ktParseValue(f, 'map["${f.rawName}"]'));
      sb.writeln(',');
    }
    sb.writeln('            )');
    sb.writeln('        }');
    sb.writeln('    }');
    sb.writeln();
  }

  String _ktParseValue(FieldDef f, String access) {
    final JsonTypeInfo t = f.type;
    if (t.kind == JsonKind.nullKind) return access;
    if (t.isPrimitive) {
      switch (t.kind) {
        case JsonKind.integer:
          return '($access as Number).toInt()';
        case JsonKind.double:
          return '($access as Number).toDouble()';
        case JsonKind.string:
          return access;
        case JsonKind.boolean:
          return access;
        default:
          return access;
      }
    }
    if (t.isObject && t.className != null) {
      return '${t.className}.fromJson($access as Map<String, Any?>)';
    }
    if (t.isArray && t.itemType != null) {
      return '($access as List<Any?>).map { it as ${_ktType(t.itemType!)} }.toList()';
    }
    return access;
  }

  void _ktToJson(StringBuffer sb, ClassDef cls) {
    sb.writeln('    fun toJson(): Map<String, Any?> {');
    sb.writeln('        return mapOf(');
    for (final FieldDef f in cls.fields) {
      sb.write('            "${f.rawName}" to ');
      sb.write(_ktToJsonValue(f));
      sb.writeln(',');
    }
    sb.writeln('        )');
    sb.writeln('    }');
    sb.writeln();
  }

  String _ktToJsonValue(FieldDef f) {
    final String access = _ktName(f.name);
    final JsonTypeInfo t = f.type;
    if (t.isObject && t.className != null) {
      return '$access?.toJson()';
    }
    return access;
  }

  // ---------------- SWIFT ----------------

  void _swiftClass(StringBuffer sb, ClassDef cls) {
    sb.writeln('struct ${cls.name}: Codable {');
    for (final FieldDef f in cls.fields) {
      sb.writeln('    let ${_swiftName(f.name)}: ${_swiftTypeForField(f)}');
    }
    if (options.generateEquatable && cls.fields.isNotEmpty) {
      sb.writeln();
      sb.writeln(
        '    static func == (lhs: ${cls.name}, rhs: ${cls.name}) -> Bool {',
      );
      final List<String> conds = cls.fields
          .map(
            (FieldDef f) =>
        'lhs.${_swiftName(f.name)} == rhs.${_swiftName(f.name)}',
      )
          .toList();
      sb.writeln('        return ${conds.join(' && ')}');
      sb.writeln('    }');
    }
    sb.writeln();
    sb.writeln('    enum CodingKeys: String, CodingKey {');
    for (final FieldDef f in cls.fields) {
      sb.writeln('        case ${_swiftName(f.name)} = "${f.rawName}"');
    }
    sb.writeln('    }');
    sb.writeln('}');
    sb.writeln();
  }

  String _swiftName(String name) {
    if (NameConverter.isReserved(name, CodeLanguage.swift)) {
      return '`$name`';
    }
    return name;
  }

  String _swiftTypeForField(FieldDef f) {
    String type = _swiftType(f.type);
    if (f.type.nullable) return '$type?';
    return type;
  }

  String _swiftType(JsonTypeInfo t) {
    switch (t.kind) {
      case JsonKind.string:
        return 'String';
      case JsonKind.integer:
        return 'Int';
      case JsonKind.double:
        return 'Double';
      case JsonKind.boolean:
        return 'Bool';
      case JsonKind.nullKind:
        return 'AnyCodable';
      case JsonKind.object:
        return t.className ?? 'AnyCodable';
      case JsonKind.array:
        if (t.itemType == null) return '[AnyCodable]';
        return '[${_swiftType(t.itemType!)}]';
    }
  }

  // ---------------- JAVA ----------------

  void _javaClass(StringBuffer sb, ClassDef cls) {
    sb.writeln('public class ${cls.name} {');
    for (final FieldDef f in cls.fields) {
      sb.write('    ');
      if (options.immutable) {
        sb.write('private final ');
      } else {
        sb.write('private ');
      }
      sb.write(_javaTypeForField(f));
      sb.write(' ');
      sb.write(_javaName(f.name));
      sb.writeln(';');
    }
    sb.writeln();

    _javaConstructor(sb, cls);
    for (final FieldDef f in cls.fields) {
      _javaGetter(sb, f);
    }
    if (options.generateEquatable) _javaEquals(sb, cls);
    sb.writeln('}');
    sb.writeln();
  }

  String _javaName(String name) {
    if (NameConverter.isReserved(name, CodeLanguage.java)) {
      return '${name}_';
    }
    return name;
  }

  void _javaConstructor(StringBuffer sb, ClassDef cls) {
    sb.write('    public ${cls.name}(');
    if (cls.fields.isEmpty) {
      sb.writeln(') {}');
      sb.writeln();
      return;
    }
    sb.writeln();
    for (int i = 0; i < cls.fields.length; i++) {
      final FieldDef f = cls.fields[i];
      sb.write('        ${_javaTypeForField(f)} ${_javaName(f.name)}');
      if (i < cls.fields.length - 1) sb.write(',');
      sb.writeln();
    }
    sb.writeln('    ) {');
    for (final FieldDef f in cls.fields) {
      sb.writeln(
        '        this.${_javaName(f.name)} = ${_javaName(f.name)};',
      );
    }
    sb.writeln('    }');
    sb.writeln();
  }

  void _javaGetter(StringBuffer sb, FieldDef f) {
    final String cap = NameConverter.capitalize(f.name);
    sb.write('    public ');
    sb.write(_javaTypeForField(f));
    sb.write(' get$cap() { return ');
    sb.write(_javaName(f.name));
    sb.writeln('; }');
    sb.writeln();
  }

  void _javaEquals(StringBuffer sb, ClassDef cls) {
    sb.writeln('    @Override');
    sb.writeln('    public boolean equals(Object o) {');
    sb.writeln('        if (this == o) return true;');
    sb.writeln(
      '        if (o == null || getClass() != o.getClass()) return false;',
    );
    sb.writeln('        ${cls.name} that = (${cls.name}) o;');
    if (cls.fields.isEmpty) {
      sb.writeln('        return true;');
    } else {
      final List<String> conds = cls.fields
          .map(
            (FieldDef f) =>
        'Objects.equals(${_javaName(f.name)}, that.${_javaName(f.name)})',
      )
          .toList();
      sb.writeln('        return ${conds.join(' && ')};');
    }
    sb.writeln('    }');
    sb.writeln();
  }

  String _javaTypeForField(FieldDef f) {
    String type = _javaType(f.type);
    if (f.type.nullable && _javaIsPrimitive(f.type)) {
      return _javaBoxed(f.type);
    }
    return type;
  }

  bool _javaIsPrimitive(JsonTypeInfo t) {
    return t.kind == JsonKind.integer ||
        t.kind == JsonKind.double ||
        t.kind == JsonKind.boolean;
  }

  String _javaBoxed(JsonTypeInfo t) {
    switch (t.kind) {
      case JsonKind.integer:
        return 'Integer';
      case JsonKind.double:
        return 'Double';
      case JsonKind.boolean:
        return 'Boolean';
      default:
        return _javaType(t);
    }
  }

  String _javaType(JsonTypeInfo t) {
    switch (t.kind) {
      case JsonKind.string:
        return 'String';
      case JsonKind.integer:
        return 'int';
      case JsonKind.double:
        return 'double';
      case JsonKind.boolean:
        return 'boolean';
      case JsonKind.nullKind:
        return 'Object';
      case JsonKind.object:
        return t.className ?? 'Map<String, Object>';
      case JsonKind.array:
        if (t.itemType == null) return 'List<Object>';
        return 'List<${_javaType(t.itemType!)}>';
    }
  }

  // ---------------- C# ----------------

  void _csClass(StringBuffer sb, ClassDef cls) {
    final String indent = language.supportsPackage ? '    ' : '';
    sb.writeln('${indent}public class ${cls.name}');
    sb.writeln('$indent{');
    for (final FieldDef f in cls.fields) {
      sb.write('$indent    public ');
      if (options.immutable) sb.write('required ');
      sb.write(_csTypeForField(f));
      sb.write(' ');
      sb.write(_csName(f.name));
      sb.write(' { get; ');
      if (options.immutable) {
        sb.write('init; ');
      } else {
        sb.write('set; ');
      }
      sb.writeln('}');
    }
    sb.writeln('$indent}');
    sb.writeln();
  }

  String _csName(String name) {
    if (NameConverter.isReserved(name, CodeLanguage.csharp)) {
      return '@$name';
    }
    return NameConverter.capitalize(name);
  }

  String _csTypeForField(FieldDef f) {
    String type = _csType(f.type);
    if (f.type.nullable && !_csIsReference(f.type)) {
      type = '$type?';
    }
    return type;
  }

  bool _csIsReference(JsonTypeInfo t) {
    return t.kind == JsonKind.string ||
        t.kind == JsonKind.object ||
        t.kind == JsonKind.array ||
        t.kind == JsonKind.nullKind;
  }

  String _csType(JsonTypeInfo t) {
    switch (t.kind) {
      case JsonKind.string:
        return 'string';
      case JsonKind.integer:
        return 'int';
      case JsonKind.double:
        return 'double';
      case JsonKind.boolean:
        return 'bool';
      case JsonKind.nullKind:
        return 'object';
      case JsonKind.object:
        return t.className ?? 'Dictionary<string, object>';
      case JsonKind.array:
        if (t.itemType == null) return 'List<object>';
        return 'List<${_csType(t.itemType!)}>';
    }
  }

  // ---------------- GO ----------------

  void _goClass(StringBuffer sb, ClassDef cls) {
    sb.writeln('type ${cls.name} struct {');
    for (final FieldDef f in cls.fields) {
      final String goName = NameConverter.toPascal(f.rawName);
      sb.write('    $goName ');
      sb.write(_goTypeForField(f));
      sb.write(' `json:"${f.rawName}"`');
      sb.writeln();
    }
    sb.writeln('}');
    sb.writeln();
  }

  String _goTypeForField(FieldDef f) {
    if (f.type.nullable) {
      return '*${_goType(f.type)}';
    }
    return _goType(f.type);
  }

  String _goType(JsonTypeInfo t) {
    switch (t.kind) {
      case JsonKind.string:
        return 'string';
      case JsonKind.integer:
        return 'int';
      case JsonKind.double:
        return 'float64';
      case JsonKind.boolean:
        return 'bool';
      case JsonKind.nullKind:
        return 'interface{}';
      case JsonKind.object:
        return t.className ?? 'map[string]interface{}';
      case JsonKind.array:
        if (t.itemType == null) return '[]interface{}';
        return '[]${_goType(t.itemType!)}';
    }
  }
}