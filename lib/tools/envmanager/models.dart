enum EnvFormat { dotenv, json, yaml }

extension EnvFormatX on EnvFormat {
  String get id => name;

  String get displayName {
    switch (this) {
      case EnvFormat.dotenv:
        return '.env';
      case EnvFormat.json:
        return 'JSON';
      case EnvFormat.yaml:
        return 'YAML';
    }
  }

  String get fileExtension {
    switch (this) {
      case EnvFormat.dotenv:
        return '.env';
      case EnvFormat.json:
        return '.json';
      case EnvFormat.yaml:
        return '.yaml';
    }
  }
}

enum EnvQuoteStyle { none, single, double }

extension EnvQuoteStyleX on EnvQuoteStyle {
  String get label {
    switch (this) {
      case EnvQuoteStyle.none:
        return 'none';
      case EnvQuoteStyle.single:
        return "'...'";
      case EnvQuoteStyle.double:
        return '"..."';
    }
  }

  String apply(String value) {
    switch (this) {
      case EnvQuoteStyle.none:
        return value;
      case EnvQuoteStyle.single:
        return "'${value.replaceAll("'", "\\'")}'";
      case EnvQuoteStyle.double:
        return '"${value.replaceAll('"', '\\"')}"';
    }
  }

  static EnvQuoteStyle detect(String rawValue) {
    if (rawValue.length >= 2) {
      if (rawValue.startsWith("'") && rawValue.endsWith("'")) {
        return EnvQuoteStyle.single;
      }
      if (rawValue.startsWith('"') && rawValue.endsWith('"')) {
        return EnvQuoteStyle.double;
      }
    }
    return EnvQuoteStyle.none;
  }
}

enum EnvErrorSeverity { error, warning }

class EnvValidationIssue {
  final int lineNumber;
  final String? key;
  final String messageKey;
  final String messageDetail;
  final EnvErrorSeverity severity;

  const EnvValidationIssue({
    required this.lineNumber,
    this.key,
    required this.messageKey,
    this.messageDetail = '',
    this.severity = EnvErrorSeverity.error,
  });
}

class EnvEntry {
  String key;
  String value;
  EnvQuoteStyle quote;
  bool enabled;
  String? comment;

  EnvEntry({
    required this.key,
    required this.value,
    this.quote = EnvQuoteStyle.none,
    this.enabled = true,
    this.comment,
  });

  EnvEntry copy() => EnvEntry(
    key: key,
    value: value,
    quote: quote,
    enabled: enabled,
    comment: comment,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'key': key,
    'value': value,
    'quote': quote.name,
    'enabled': enabled,
    'comment': comment,
  };

  factory EnvEntry.fromJson(Map<String, dynamic> j) => EnvEntry(
    key: j['key']?.toString() ?? '',
    value: j['value']?.toString() ?? '',
    quote: EnvQuoteStyle.values.firstWhere(
          (EnvQuoteStyle q) => q.name == j['quote'],
      orElse: () => EnvQuoteStyle.none,
    ),
    enabled: j['enabled'] as bool? ?? true,
    comment: j['comment']?.toString(),
  );

  bool get isSuspicious {
    if (value.isEmpty) return true;
    final String lowerKey = key.toLowerCase();
    final bool looksSecret = lowerKey.contains('secret') ||
        lowerKey.contains('token') ||
        lowerKey.contains('password') ||
        lowerKey.contains('api_key') ||
        lowerKey.contains('apikey') ||
        lowerKey.contains('private');
    return looksSecret && value.length < 8;
  }
}

class EnvDocument {
  final List<EnvEntry> entries;
  final List<EnvValidationIssue> issues;

  const EnvDocument({
    required this.entries,
    required this.issues,
  });

  bool get hasErrors => issues
      .any((EnvValidationIssue i) => i.severity == EnvErrorSeverity.error);

  int get errorCount => issues
      .where((EnvValidationIssue i) => i.severity == EnvErrorSeverity.error)
      .length;

  int get warningCount => issues
      .where((EnvValidationIssue i) => i.severity == EnvErrorSeverity.warning)
      .length;

  static const EnvDocument empty = EnvDocument(
    entries: <EnvEntry>[],
    issues: <EnvValidationIssue>[],
  );
}

class EnvConvertOptions {
  bool includeComments;
  bool sortKeys;
  bool uppercaseKeys;
  EnvQuoteStyle defaultQuote;

  EnvConvertOptions({
    this.includeComments = false,
    this.sortKeys = false,
    this.uppercaseKeys = false,
    this.defaultQuote = EnvQuoteStyle.none,
  });

  EnvConvertOptions copy() => EnvConvertOptions(
    includeComments: includeComments,
    sortKeys: sortKeys,
    uppercaseKeys: uppercaseKeys,
    defaultQuote: defaultQuote,
  );
}