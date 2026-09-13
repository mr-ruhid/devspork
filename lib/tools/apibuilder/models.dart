import 'dart:convert';

enum HttpMethod { get, post, put, patch, delete, head, options }

extension HttpMethodX on HttpMethod {
  String get value {
    switch (this) {
      case HttpMethod.get:
        return 'GET';
      case HttpMethod.post:
        return 'POST';
      case HttpMethod.put:
        return 'PUT';
      case HttpMethod.patch:
        return 'PATCH';
      case HttpMethod.delete:
        return 'DELETE';
      case HttpMethod.head:
        return 'HEAD';
      case HttpMethod.options:
        return 'OPTIONS';
    }
  }
}

enum BodyType { none, json, formUrlEncoded, raw }

class HeaderPair {
  String key;
  String value;
  bool enabled;

  HeaderPair({this.key = '', this.value = '', this.enabled = true});

  Map<String, dynamic> toJson() => {
    'key': key,
    'value': value,
    'enabled': enabled,
  };

  factory HeaderPair.fromJson(Map<String, dynamic> j) => HeaderPair(
    key: j['key']?.toString() ?? '',
    value: j['value']?.toString() ?? '',
    enabled: j['enabled'] as bool? ?? true,
  );
}

class ApiRequest {
  HttpMethod method;
  String url;
  List<HeaderPair> headers;
  BodyType bodyType;
  String body;

  ApiRequest({
    this.method = HttpMethod.get,
    this.url = '',
    List<HeaderPair>? headers,
    this.bodyType = BodyType.none,
    this.body = '',
  }) : headers = headers ?? [];

  Map<String, dynamic> toJson() => {
    'method': method.value,
    'url': url,
    'headers': headers.map((h) => h.toJson()).toList(),
    'bodyType': bodyType.name,
    'body': body,
  };

  factory ApiRequest.fromJson(Map<String, dynamic> j) => ApiRequest(
    method: HttpMethod.values.firstWhere(
          (m) => m.value == j['method'],
      orElse: () => HttpMethod.get,
    ),
    url: j['url']?.toString() ?? '',
    headers: (j['headers'] as List?)
        ?.map((e) => HeaderPair.fromJson(e as Map<String, dynamic>))
        .toList() ??
        [],
    bodyType: BodyType.values.firstWhere(
          (b) => b.name == j['bodyType'],
      orElse: () => BodyType.none,
    ),
    body: j['body']?.toString() ?? '',
  );

  ApiRequest copy() => ApiRequest.fromJson(toJson());
}

class ApiResponse {
  final int? statusCode;
  final String? statusMessage;
  final Map<String, String> headers;
  final String body;
  final int durationMs;
  final int sizeBytes;
  final String? error;

  ApiResponse({
    this.statusCode,
    this.statusMessage,
    this.headers = const {},
    this.body = '',
    this.durationMs = 0,
    this.sizeBytes = 0,
    this.error,
  });

  bool get isSuccess =>
      error == null &&
          statusCode != null &&
          statusCode! >= 200 &&
          statusCode! < 300;

  String get prettyBody {
    if (body.isEmpty) return '';
    try {
      final decoded = jsonDecode(body);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return body;
    }
  }
}

class HistoryEntry {
  final ApiRequest request;
  final int? statusCode;
  final int durationMs;
  final DateTime timestamp;

  HistoryEntry({
    required this.request,
    required this.statusCode,
    required this.durationMs,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'request': request.toJson(),
    'statusCode': statusCode,
    'durationMs': durationMs,
    'timestamp': timestamp.toIso8601String(),
  };

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
    request: ApiRequest.fromJson(j['request'] as Map<String, dynamic>),
    statusCode: j['statusCode'] as int?,
    durationMs: j['durationMs'] as int? ?? 0,
    timestamp: DateTime.parse(j['timestamp'] as String),
  );
}