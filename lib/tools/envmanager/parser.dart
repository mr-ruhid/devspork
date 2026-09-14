import 'dart:convert';

import 'package:yaml/yaml.dart';

import 'models.dart';

class EnvParser {
  EnvParser._();

  static EnvDocument parseDotenv(String input) {
    final List<EnvEntry> entries = <EnvEntry>[];
    final List<EnvValidationIssue> issues = <EnvValidationIssue>[];
    final List<String> lines = input.split('\n');

    final Set<String> seenKeys = <String>{};

    for (int i = 0; i < lines.length; i++) {
      final int lineNum = i + 1;
      final String raw = lines[i];
      final String line = raw.trim();

      if (line.isEmpty) continue;

      if (line.startsWith('#')) {
        continue;
      }

      String working = line;
      String? comment;

      final int commentIdx = _findCommentIndex(working);
      if (commentIdx != -1) {
        comment = working.substring(commentIdx + 1).trim();
        working = working.substring(0, commentIdx).trim();
      }

      String? key;
      if (working.startsWith('export ')) {
        working = working.substring(7).trim();
      }

      final int eqIdx = working.indexOf('=');
      if (eqIdx == -1) {
        issues.add(
          EnvValidationIssue(
            lineNumber: lineNum,
            messageKey: 'envmanager_issue_missing_eq',
            messageDetail: line,
          ),
        );
        continue;
      }

      key = working.substring(0, eqIdx).trim();
      String rawValue = working.substring(eqIdx + 1).trim();

      if (key.isEmpty) {
        issues.add(
          EnvValidationIssue(
            lineNumber: lineNum,
            messageKey: 'envmanager_issue_empty_key',
            messageDetail: line,
          ),
        );
        continue;
      }

      if (!RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(key)) {
        issues.add(
          EnvValidationIssue(
            lineNumber: lineNum,
            key: key,
            messageKey: 'envmanager_issue_invalid_key',
            messageDetail: key,
            severity: EnvErrorSeverity.warning,
          ),
        );
      }

      if (seenKeys.contains(key)) {
        issues.add(
          EnvValidationIssue(
            lineNumber: lineNum,
            key: key,
            messageKey: 'envmanager_issue_duplicate_key',
            messageDetail: key,
            severity: EnvErrorSeverity.warning,
          ),
        );
      }
      seenKeys.add(key);

      final EnvQuoteStyle quote = EnvQuoteStyleX.detect(rawValue);

      if (rawValue.length >= 2) {
        final String first = rawValue[0];
        final String last = rawValue[rawValue.length - 1];
        if (first == "'" && last == "'") {
          rawValue = rawValue
              .substring(1, rawValue.length - 1)
              .replaceAll("\\'", "'");
        } else if (first == '"' && last == '"') {
          rawValue = rawValue
              .substring(1, rawValue.length - 1)
              .replaceAll('\\"', '"')
              .replaceAll(r'\n', '\n')
              .replaceAll(r'\t', '\t')
              .replaceAll(r'\\', '\\');
        }
      }

      if (rawValue.isEmpty) {
        issues.add(
          EnvValidationIssue(
            lineNumber: lineNum,
            key: key,
            messageKey: 'envmanager_issue_empty_value',
            messageDetail: key,
            severity: EnvErrorSeverity.warning,
          ),
        );
      }

      entries.add(
        EnvEntry(
          key: key,
          value: rawValue,
          quote: quote,
          comment: comment,
        ),
      );
    }

    return EnvDocument(entries: entries, issues: issues);
  }

  static int _findCommentIndex(String line) {
    bool inSingle = false;
    bool inDouble = false;
    for (int i = 0; i < line.length; i++) {
      final String ch = line[i];
      if (ch == "'" && !inDouble) {
        inSingle = !inSingle;
      } else if (ch == '"' && !inSingle) {
        inDouble = !inDouble;
      } else if (ch == '#' && !inSingle && !inDouble) {
        if (i == 0) return i;
        final String prev = line[i - 1];
        if (prev == ' ' || prev == '\t') return i;
      }
    }
    return -1;
  }

  static EnvDocument parseJson(String input) {
    final List<EnvEntry> entries = <EnvEntry>[];
    final List<EnvValidationIssue> issues = <EnvValidationIssue>[];

    final String trimmed = input.trim();
    if (trimmed.isEmpty) return EnvDocument.empty;

    dynamic decoded;
    try {
      decoded = jsonDecode(trimmed);
    } catch (e) {
      issues.add(
        EnvValidationIssue(
          lineNumber: 0,
          messageKey: 'envmanager_issue_json_invalid',
          messageDetail: e.toString(),
        ),
      );
      return EnvDocument(entries: entries, issues: issues);
    }

    if (decoded is! Map) {
      issues.add(
        const EnvValidationIssue(
          lineNumber: 0,
          messageKey: 'envmanager_issue_json_not_object',
        ),
      );
      return EnvDocument(entries: entries, issues: issues);
    }

    for (final MapEntry<dynamic, dynamic> e in decoded.entries) {
      final String key = e.key.toString();
      final dynamic rawValue = e.value;
      final String value = _valueToString(rawValue);
      entries.add(
        EnvEntry(
          key: key,
          value: value,
          quote: _shouldQuote(value, rawValue)
              ? EnvQuoteStyle.double
              : EnvQuoteStyle.none,
        ),
      );
    }

    return EnvDocument(entries: entries, issues: issues);
  }

  static EnvDocument parseYaml(String input) {
    final List<EnvEntry> entries = <EnvEntry>[];
    final List<EnvValidationIssue> issues = <EnvValidationIssue>[];

    final String trimmed = input.trim();
    if (trimmed.isEmpty) return EnvDocument.empty;

    dynamic decoded;
    try {
      decoded = loadYaml(trimmed);
    } catch (e) {
      issues.add(
        EnvValidationIssue(
          lineNumber: 0,
          messageKey: 'envmanager_issue_yaml_invalid',
          messageDetail: e.toString(),
        ),
      );
      return EnvDocument(entries: entries, issues: issues);
    }

    if (decoded is! Map) {
      issues.add(
        const EnvValidationIssue(
          lineNumber: 0,
          messageKey: 'envmanager_issue_yaml_not_object',
        ),
      );
      return EnvDocument(entries: entries, issues: issues);
    }

    for (final MapEntry<dynamic, dynamic> e in decoded.entries) {
      final String key = e.key.toString();
      final dynamic rawValue = e.value;
      final String value = _valueToString(rawValue);
      entries.add(
        EnvEntry(
          key: key,
          value: value,
          quote: _shouldQuote(value, rawValue)
              ? EnvQuoteStyle.double
              : EnvQuoteStyle.none,
        ),
      );
    }

    return EnvDocument(entries: entries, issues: issues);
  }

  static String _valueToString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    if (value is Map || value is List) {
      return jsonEncode(value);
    }
    return value.toString();
  }

  static bool _shouldQuote(String stringValue, dynamic rawValue) {
    if (rawValue is! String) return false;
    if (stringValue.isEmpty) return false;
    if (stringValue.contains('\n') ||
        stringValue.contains('"') ||
        stringValue.contains("'")) {
      return true;
    }
    if (stringValue.contains(' ') && stringValue.trim() != stringValue) {
      return true;
    }
    return false;
  }

  static String exportDotenv(
      List<EnvEntry> entries, {
        EnvConvertOptions? options,
      }) {
    final EnvConvertOptions opts = options ?? EnvConvertOptions();
    final List<EnvEntry> list = List<EnvEntry>.from(entries);

    if (opts.sortKeys) {
      list.sort(
            (EnvEntry a, EnvEntry b) =>
            a.key.toLowerCase().compareTo(b.key.toLowerCase()),
      );
    }

    final StringBuffer sb = StringBuffer();

    for (final EnvEntry e in list) {
      if (!e.enabled) continue;

      final String key = opts.uppercaseKeys ? e.key.toUpperCase() : e.key;
      final EnvQuoteStyle quoteStyle = e.quote == EnvQuoteStyle.none
          ? opts.defaultQuote
          : e.quote;
      final String value = quoteStyle == EnvQuoteStyle.none
          ? _needsQuoteForDotenv(e.value)
          ? '"${_escapeDouble(e.value)}"'
          : e.value
          : quoteStyle.apply(e.value);

      sb.write('$key=$value');

      if (opts.includeComments &&
          e.comment != null &&
          e.comment!.trim().isNotEmpty) {
        sb.write(' # ${e.comment}');
      }
      sb.writeln();
    }

    return sb.toString().trimRight();
  }

  static bool _needsQuoteForDotenv(String value) {
    if (value.isEmpty) return false;
    if (value.contains(' ') ||
        value.contains('#') ||
        value.contains('\n') ||
        value.contains('"') ||
        value.contains("'") ||
        value.contains(r'$')) {
      return true;
    }
    return false;
  }

  static String _escapeDouble(String s) => s
      .replaceAll(r'\', r'\\')
      .replaceAll('"', r'\"')
      .replaceAll('\n', r'\n')
      .replaceAll('\t', r'\t');

  static String exportJson(
      List<EnvEntry> entries, {
        EnvConvertOptions? options,
      }) {
    final EnvConvertOptions opts = options ?? EnvConvertOptions();
    final List<EnvEntry> list = List<EnvEntry>.from(entries);

    if (opts.sortKeys) {
      list.sort(
            (EnvEntry a, EnvEntry b) =>
            a.key.toLowerCase().compareTo(b.key.toLowerCase()),
      );
    }

    final Map<String, dynamic> map = <String, dynamic>{};
    for (final EnvEntry e in list) {
      if (!e.enabled) continue;
      final String key = opts.uppercaseKeys ? e.key.toUpperCase() : e.key;
      map[key] = _smartCoerce(e.value);
    }

    return const JsonEncoder.withIndent('  ').convert(map);
  }

  static String exportYaml(
      List<EnvEntry> entries, {
        EnvConvertOptions? options,
      }) {
    final EnvConvertOptions opts = options ?? EnvConvertOptions();
    final List<EnvEntry> list = List<EnvEntry>.from(entries);

    if (opts.sortKeys) {
      list.sort(
            (EnvEntry a, EnvEntry b) =>
            a.key.toLowerCase().compareTo(b.key.toLowerCase()),
      );
    }

    final StringBuffer sb = StringBuffer();
    for (final EnvEntry e in list) {
      if (!e.enabled) continue;
      final String key = opts.uppercaseKeys ? e.key.toUpperCase() : e.key;
      final dynamic value = _smartCoerce(e.value);
      sb.write('$key: ');
      sb.write(_yamlValue(value));
      sb.writeln();
    }
    return sb.toString().trimRight();
  }

  static String _yamlValue(dynamic value) {
    if (value == null) return 'null';
    if (value is bool || value is num) return value.toString();
    final String s = value.toString();
    if (s.isEmpty) return "''";
    final bool needsQuote = s.contains(':') ||
        s.contains('#') ||
        s.contains('\n') ||
        s.startsWith('-') ||
        s.startsWith('*') ||
        s.startsWith('&') ||
        s.startsWith('!') ||
        s.startsWith('|') ||
        s.startsWith('>') ||
        s.startsWith('%') ||
        s.startsWith('@') ||
        s.startsWith('`') ||
        s.toLowerCase() == 'true' ||
        s.toLowerCase() == 'false' ||
        s.toLowerCase() == 'null' ||
        s.toLowerCase() == 'yes' ||
        s.toLowerCase() == 'no' ||
        s.trim() != s;
    if (needsQuote) {
      return '"${s.replaceAll('"', r'\"')}"';
    }
    return s;
  }

  static dynamic _smartCoerce(String value) {
    if (value.isEmpty) return '';
    final String lower = value.toLowerCase();
    if (lower == 'true') return true;
    if (lower == 'false') return false;
    if (lower == 'null') return null;

    final int? intVal = int.tryParse(value);
    if (intVal != null && value == intVal.toString()) {
      return intVal;
    }

    final double? doubleVal = double.tryParse(value);
    if (doubleVal != null &&
        value.contains('.') &&
        RegExp(r'^-?\d+\.\d+$').hasMatch(value)) {
      return doubleVal;
    }

    return value;
  }

  static EnvDocument parse(
      String input,
      EnvFormat format,
      ) {
    switch (format) {
      case EnvFormat.dotenv:
        return parseDotenv(input);
      case EnvFormat.json:
        return parseJson(input);
      case EnvFormat.yaml:
        return parseYaml(input);
    }
  }

  static String export(
      List<EnvEntry> entries,
      EnvFormat format, {
        EnvConvertOptions? options,
      }) {
    switch (format) {
      case EnvFormat.dotenv:
        return exportDotenv(entries, options: options);
      case EnvFormat.json:
        return exportJson(entries, options: options);
      case EnvFormat.yaml:
        return exportYaml(entries, options: options);
    }
  }
}