import 'dart:convert';

enum MockServerStatus { stopped, starting, running, error }

class MockEndpoint {
  String id;
  String method;
  String path;
  int statusCode;
  String responseBody;
  Map<String, String> responseHeaders;
  int delayMs;
  bool enabled;
  String description;

  MockEndpoint({
    String? id,
    this.method = 'GET',
    this.path = '/',
    this.statusCode = 200,
    this.responseBody = '{}',
    Map<String, String>? responseHeaders,
    this.delayMs = 0,
    this.enabled = true,
    this.description = '',
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        responseHeaders = responseHeaders ?? <String, String>{
          'Content-Type': 'application/json',
        };

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'method': method,
    'path': path,
    'statusCode': statusCode,
    'responseBody': responseBody,
    'responseHeaders': responseHeaders,
    'delayMs': delayMs,
    'enabled': enabled,
    'description': description,
  };

  factory MockEndpoint.fromJson(Map<String, dynamic> j) => MockEndpoint(
    id: j['id']?.toString(),
    method: j['method']?.toString() ?? 'GET',
    path: j['path']?.toString() ?? '/',
    statusCode: (j['statusCode'] as num?)?.toInt() ?? 200,
    responseBody: j['responseBody']?.toString() ?? '{}',
    responseHeaders: (j['responseHeaders'] as Map?)
        ?.map((k, v) => MapEntry(k.toString(), v.toString())) ??
        <String, String>{'Content-Type': 'application/json'},
    delayMs: (j['delayMs'] as num?)?.toInt() ?? 0,
    enabled: j['enabled'] as bool? ?? true,
    description: j['description']?.toString() ?? '',
  );

  MockEndpoint copy() => MockEndpoint.fromJson(toJson());

  String get key => '${method.toUpperCase()} $path';

  String get prettyBody {
    try {
      final dynamic decoded = jsonDecode(responseBody);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return responseBody;
    }
  }
}

class MockServerConfig {
  int port;
  String host;
  bool corsEnabled;
  bool logRequests;
  int globalDelayMs;

  MockServerConfig({
    this.port = 8080,
    this.host = '0.0.0.0',
    this.corsEnabled = true,
    this.logRequests = true,
    this.globalDelayMs = 0,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'port': port,
    'host': host,
    'corsEnabled': corsEnabled,
    'logRequests': logRequests,
    'globalDelayMs': globalDelayMs,
  };

  factory MockServerConfig.fromJson(Map<String, dynamic> j) =>
      MockServerConfig(
        port: (j['port'] as num?)?.toInt() ?? 8080,
        host: j['host']?.toString() ?? '0.0.0.0',
        corsEnabled: j['corsEnabled'] as bool? ?? true,
        logRequests: j['logRequests'] as bool? ?? true,
        globalDelayMs: (j['globalDelayMs'] as num?)?.toInt() ?? 0,
      );
}

class ServerLogEntry {
  final DateTime timestamp;
  final String method;
  final String path;
  final String? query;
  final int statusCode;
  final int durationMs;
  final int requestSize;
  final int responseSize;
  final String? requestBody;

  ServerLogEntry({
    required this.timestamp,
    required this.method,
    required this.path,
    this.query,
    required this.statusCode,
    required this.durationMs,
    this.requestSize = 0,
    this.responseSize = 0,
    this.requestBody,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'timestamp': timestamp.toIso8601String(),
    'method': method,
    'path': path,
    'query': query,
    'statusCode': statusCode,
    'durationMs': durationMs,
    'requestSize': requestSize,
    'responseSize': responseSize,
    'requestBody': requestBody,
  };

  factory ServerLogEntry.fromJson(Map<String, dynamic> j) => ServerLogEntry(
    timestamp: DateTime.parse(j['timestamp'] as String),
    method: j['method']?.toString() ?? 'GET',
    path: j['path']?.toString() ?? '/',
    query: j['query']?.toString(),
    statusCode: (j['statusCode'] as num?)?.toInt() ?? 200,
    durationMs: (j['durationMs'] as num?)?.toInt() ?? 0,
    requestSize: (j['requestSize'] as num?)?.toInt() ?? 0,
    responseSize: (j['responseSize'] as num?)?.toInt() ?? 0,
    requestBody: j['requestBody']?.toString(),
  );
}

class OpenApiParseResult {
  final List<MockEndpoint> endpoints;
  final String? title;
  final String? version;
  final String? error;

  OpenApiParseResult({
    required this.endpoints,
    this.title,
    this.version,
    this.error,
  });

  bool get isSuccess => error == null && endpoints.isNotEmpty;
}

class MockServerSnapshot {
  final List<MockEndpoint> endpoints;
  final MockServerConfig config;

  MockServerSnapshot({
    required this.endpoints,
    required this.config,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'endpoints': endpoints.map((MockEndpoint e) => e.toJson()).toList(),
    'config': config.toJson(),
  };

  factory MockServerSnapshot.fromJson(Map<String, dynamic> j) =>
      MockServerSnapshot(
        endpoints: (j['endpoints'] as List?)
            ?.map((e) => MockEndpoint.fromJson(e as Map<String, dynamic>))
            .toList() ??
            <MockEndpoint>[],
        config: MockServerConfig.fromJson(
          (j['config'] as Map<String, dynamic>?) ?? <String, dynamic>{},
        ),
      );
}