enum CodeLanguage {
  json,
  xml,
  html,
  yaml,
  sql,
  css,
  javascript,
  typescript,
}

extension CodeLanguageX on CodeLanguage {
  String get id => name;

  String get displayName {
    switch (this) {
      case CodeLanguage.json:
        return 'JSON';
      case CodeLanguage.xml:
        return 'XML';
      case CodeLanguage.html:
        return 'HTML';
      case CodeLanguage.yaml:
        return 'YAML';
      case CodeLanguage.sql:
        return 'SQL';
      case CodeLanguage.css:
        return 'CSS';
      case CodeLanguage.javascript:
        return 'JavaScript';
      case CodeLanguage.typescript:
        return 'TypeScript';
    }
  }

  bool get isRemote {
    switch (this) {
      case CodeLanguage.javascript:
      case CodeLanguage.typescript:
        return true;
      default:
        return false;
    }
  }

  bool get isLocal => !isRemote;

  String get hint {
    switch (this) {
      case CodeLanguage.json:
        return '{"name":"John","age":30}';
      case CodeLanguage.xml:
        return '<root><item id="1">Hello</item></root>';
      case CodeLanguage.html:
        return '<div class="card"><h1>Title</h1></div>';
      case CodeLanguage.yaml:
        return 'name: John\nage: 30';
      case CodeLanguage.sql:
        return 'select id,name from users where active=1 order by name';
      case CodeLanguage.css:
        return '.card{color:#fff;padding:10px 20px}';
      case CodeLanguage.javascript:
        return 'const x=1;function foo(){return x+1}';
      case CodeLanguage.typescript:
        return 'const x: number = 1;\nfunction foo(): number { return x + 1 }';
    }
  }
}

class FormatResult {
  final String output;
  final String? errorKey;
  final String? errorDetail;
  final int durationMs;

  const FormatResult({
    this.output = '',
    this.errorKey,
    this.errorDetail,
    this.durationMs = 0,
  });

  bool get hasError => errorKey != null;

  bool get isEmpty => output.isEmpty && !hasError;

  static const FormatResult empty = FormatResult();
}

class FormatOptions {
  int indentSize;
  bool useTabs;
  bool sortKeys;
  bool minify;

  FormatOptions({
    this.indentSize = 2,
    this.useTabs = false,
    this.sortKeys = false,
    this.minify = false,
  });

  String get indentUnit => useTabs ? '\t' : ' ' * indentSize;

  FormatOptions copy() => FormatOptions(
    indentSize: indentSize,
    useTabs: useTabs,
    sortKeys: sortKeys,
    minify: minify,
  );
}

class RemoteConfig {
  static const String endpoint =
      'https://mrruhid--ff951656b05511f191b81607ee4eb77e.web.val.run';
  static const Duration timeout = Duration(seconds: 15);
}