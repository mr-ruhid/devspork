enum CodeLanguage {
  dart,
  typescript,
  python,
  kotlin,
  swift,
  java,
  csharp,
  go,
}

extension CodeLanguageX on CodeLanguage {
  String get id => name;

  String get displayName {
    switch (this) {
      case CodeLanguage.dart:
        return 'Dart';
      case CodeLanguage.typescript:
        return 'TypeScript';
      case CodeLanguage.python:
        return 'Python';
      case CodeLanguage.kotlin:
        return 'Kotlin';
      case CodeLanguage.swift:
        return 'Swift';
      case CodeLanguage.java:
        return 'Java';
      case CodeLanguage.csharp:
        return 'C#';
      case CodeLanguage.go:
        return 'Go';
    }
  }

  String get fileExtension {
    switch (this) {
      case CodeLanguage.dart:
        return '.dart';
      case CodeLanguage.typescript:
        return '.ts';
      case CodeLanguage.python:
        return '.py';
      case CodeLanguage.kotlin:
        return '.kt';
      case CodeLanguage.swift:
        return '.swift';
      case CodeLanguage.java:
        return '.java';
      case CodeLanguage.csharp:
        return '.cs';
      case CodeLanguage.go:
        return '.go';
    }
  }

  bool get supportsNullSafety {
    switch (this) {
      case CodeLanguage.dart:
      case CodeLanguage.typescript:
      case CodeLanguage.kotlin:
      case CodeLanguage.swift:
      case CodeLanguage.csharp:
        return true;
      case CodeLanguage.python:
      case CodeLanguage.java:
      case CodeLanguage.go:
        return false;
    }
  }

  bool get supportsImmutable {
    switch (this) {
      case CodeLanguage.dart:
      case CodeLanguage.typescript:
      case CodeLanguage.kotlin:
      case CodeLanguage.swift:
      case CodeLanguage.java:
      case CodeLanguage.csharp:
      case CodeLanguage.go:
        return true;
      case CodeLanguage.python:
        return false;
    }
  }

  bool get supportsFromJson {
    switch (this) {
      case CodeLanguage.dart:
      case CodeLanguage.typescript:
      case CodeLanguage.kotlin:
      case CodeLanguage.swift:
      case CodeLanguage.csharp:
      case CodeLanguage.go:
        return true;
      case CodeLanguage.python:
      case CodeLanguage.java:
        return false;
    }
  }

  bool get supportsToJson {
    switch (this) {
      case CodeLanguage.dart:
      case CodeLanguage.typescript:
      case CodeLanguage.kotlin:
      case CodeLanguage.swift:
      case CodeLanguage.csharp:
      case CodeLanguage.go:
        return true;
      case CodeLanguage.python:
      case CodeLanguage.java:
        return false;
    }
  }

  bool get supportsCopyWith {
    switch (this) {
      case CodeLanguage.dart:
      case CodeLanguage.kotlin:
      case CodeLanguage.swift:
      case CodeLanguage.java:
      case CodeLanguage.csharp:
        return true;
      case CodeLanguage.typescript:
      case CodeLanguage.python:
      case CodeLanguage.go:
        return false;
    }
  }

  bool get supportsEquatable {
    switch (this) {
      case CodeLanguage.dart:
      case CodeLanguage.kotlin:
      case CodeLanguage.swift:
      case CodeLanguage.java:
      case CodeLanguage.csharp:
      case CodeLanguage.python:
        return true;
      case CodeLanguage.typescript:
      case CodeLanguage.go:
        return false;
    }
  }

  bool get supportsPackage {
    switch (this) {
      case CodeLanguage.java:
      case CodeLanguage.kotlin:
      case CodeLanguage.csharp:
      case CodeLanguage.go:
        return true;
      default:
        return false;
    }
  }
}

enum JsonKind {
  string,
  integer,
  double,
  boolean,
  nullKind,
  object,
  array,
}

extension JsonKindX on JsonKind {
  String get displayName {
    switch (this) {
      case JsonKind.string:
        return 'string';
      case JsonKind.integer:
        return 'integer';
      case JsonKind.double:
        return 'double';
      case JsonKind.boolean:
        return 'boolean';
      case JsonKind.nullKind:
        return 'null';
      case JsonKind.object:
        return 'object';
      case JsonKind.array:
        return 'array';
    }
  }
}

class GenerationOptions {
  String rootClassName;
  bool nullSafety;
  bool immutable;
  bool generateFromJson;
  bool generateToJson;
  bool generateCopyWith;
  bool generateEquatable;
  String packageName;

  GenerationOptions({
    this.rootClassName = 'Root',
    this.nullSafety = true,
    this.immutable = true,
    this.generateFromJson = true,
    this.generateToJson = true,
    this.generateCopyWith = false,
    this.generateEquatable = false,
    this.packageName = 'com.example',
  });

  GenerationOptions copy() => GenerationOptions(
    rootClassName: rootClassName,
    nullSafety: nullSafety,
    immutable: immutable,
    generateFromJson: generateFromJson,
    generateToJson: generateToJson,
    generateCopyWith: generateCopyWith,
    generateEquatable: generateEquatable,
    packageName: packageName,
  );

  void resetFor(CodeLanguage lang) {
    if (!lang.supportsNullSafety) nullSafety = false;
    if (!lang.supportsImmutable) immutable = false;
    if (!lang.supportsFromJson) generateFromJson = false;
    if (!lang.supportsToJson) generateToJson = false;
    if (!lang.supportsCopyWith) generateCopyWith = false;
    if (!lang.supportsEquatable) generateEquatable = false;
  }
}