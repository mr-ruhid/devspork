import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'models.dart';

class MockServerController {
  HttpServer? _server;
  MockServerStatus _status = MockServerStatus.stopped;
  MockServerConfig _config = MockServerConfig();
  List<MockEndpoint> _endpoints = <MockEndpoint>[];
  final List<ServerLogEntry> _logs = <ServerLogEntry>[];
  static const int _maxLogs = 200;
  List<NetworkInterface> _interfacesCache = <NetworkInterface>[];

  MockServerStatus get status => _status;
  MockServerConfig get config => _config;
  List<ServerLogEntry> get logs => List<ServerLogEntry>.unmodifiable(_logs);
  HttpServer? get rawServer => _server;

  String get baseUrl {
    if (_server == null) return 'http://${_config.host}:${_config.port}';
    final String host =
    _config.host == '0.0.0.0' ? _localIp() : _config.host;
    return 'http://$host:${_server!.port}';
  }

  int? get activePort => _server?.port;

  String _localIp() {
    try {
      for (final NetworkInterface ni in _interfacesCache) {
        for (final InternetAddress addr in ni.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return '127.0.0.1';
  }

  Future<void> start({
    required MockServerConfig config,
    required List<MockEndpoint> endpoints,
    void Function()? onLog,
  }) async {
    if (_status == MockServerStatus.running ||
        _status == MockServerStatus.starting) {
      return;
    }

    _status = MockServerStatus.starting;
    _config = config;
    _endpoints = endpoints.map((MockEndpoint e) => e.copy()).toList();

    try {
      _interfacesCache = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
    } catch (_) {
      _interfacesCache = <NetworkInterface>[];
    }

    try {
      final shelf.Handler handler = _buildHandler(onLog);
      final InternetAddress address = config.host == '0.0.0.0'
          ? InternetAddress.anyIPv4
          : InternetAddress.tryParse(config.host) ??
          InternetAddress.anyIPv4;

      _server = await shelf_io.serve(
        handler,
        address,
        config.port,
      );
      _server!.autoCompress = true;
      _status = MockServerStatus.running;
    } catch (e) {
      _server = null;
      _status = MockServerStatus.error;
      rethrow;
    }
  }

  Future<void> stop() async {
    try {
      await _server?.close(force: true);
    } catch (_) {}
    _server = null;
    _status = MockServerStatus.stopped;
  }

  void updateEndpoints(List<MockEndpoint> endpoints) {
    _endpoints = endpoints.map((MockEndpoint e) => e.copy()).toList();
  }

  void clearLogs() {
    _logs.clear();
  }

  shelf.Handler _buildHandler(void Function()? onLog) {
    return (shelf.Request request) async {
      final Stopwatch sw = Stopwatch()..start();
      final String method = request.method.toUpperCase();
      final String path = '/${request.url.path}';
      final String? query = request.url.query;

      if (method == 'OPTIONS' && _config.corsEnabled) {
        sw.stop();
        return shelf.Response.ok(
          '',
          headers: _corsHeaders(),
        );
      }

      await Future<void>.delayed(
        Duration(milliseconds: _config.globalDelayMs),
      );

      final MockEndpoint? endpoint = _matchEndpoint(method, path);

      if (endpoint == null) {
        sw.stop();
        final Map<String, dynamic> notFoundBody = <String, dynamic>{
          'error': 'Not Found',
          'message': 'No mock endpoint matches $method $path',
          'availableEndpoints': _endpoints
              .where((MockEndpoint e) => e.enabled)
              .map((MockEndpoint e) => e.key)
              .toList(),
        };
        final String body =
        const JsonEncoder.withIndent('  ').convert(notFoundBody);

        _addLog(
          method: method,
          path: path,
          query: query,
          statusCode: 404,
          durationMs: sw.elapsedMilliseconds,
          responseSize: utf8.encode(body).length,
        );
        onLog?.call();

        return shelf.Response.notFound(
          body,
          headers: <String, String>{
            'Content-Type': 'application/json',
            ..._corsHeaders(),
          },
        );
      }

      if (endpoint.delayMs > 0) {
        await Future<void>.delayed(
          Duration(milliseconds: endpoint.delayMs),
        );
      }

      final String responseBody = endpoint.responseBody;

      sw.stop();

      final Map<String, String> headers = <String, String>{
        ...endpoint.responseHeaders,
        ..._corsHeaders(),
      };

      _addLog(
        method: method,
        path: path,
        query: query,
        statusCode: endpoint.statusCode,
        durationMs: sw.elapsedMilliseconds,
        responseSize: utf8.encode(responseBody).length,
      );
      onLog?.call();

      return shelf.Response(
        endpoint.statusCode,
        body: responseBody,
        headers: headers,
      );
    };
  }

  Map<String, String> _corsHeaders() {
    if (!_config.corsEnabled) return <String, String>{};
    return <String, String>{
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods':
      'GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS',
      'Access-Control-Allow-Headers': '*',
      'Access-Control-Max-Age': '86400',
    };
  }

  MockEndpoint? _matchEndpoint(String method, String path) {
    for (final MockEndpoint e in _endpoints) {
      if (!e.enabled) continue;
      if (e.method.toUpperCase() != method) continue;

      if (_pathMatches(e.path, path)) {
        return e;
      }
    }
    return null;
  }

  bool _pathMatches(String pattern, String path) {
    final String p = pattern.startsWith('/') ? pattern : '/$pattern';
    final String t = path.startsWith('/') ? path : '/$path';

    if (p == t) return true;

    if (p.endsWith('/') && p.length > 1) {
      if (p.substring(0, p.length - 1) == t) return true;
    }
    if (t.endsWith('/') && t.length > 1) {
      if (t.substring(0, t.length - 1) == p) return true;
    }

    if (p.contains('{')) {
      final RegExp regex = _pathToRegex(p);
      return regex.hasMatch(t);
    }

    if (p.contains('*')) {
      final String regexStr =
          '^${p.replaceAll('*', '.*').replaceAll('/', r'\/')}\$';
      try {
        return RegExp(regexStr).hasMatch(t);
      } catch (_) {
        return false;
      }
    }

    return false;
  }

  RegExp _pathToRegex(String pattern) {
    final StringBuffer sb = StringBuffer('^');
    int i = 0;
    while (i < pattern.length) {
      final String ch = pattern[i];
      if (ch == '{') {
        final int close = pattern.indexOf('}', i);
        if (close == -1) {
          sb.write(RegExp.escape(ch));
          i++;
          continue;
        }
        sb.write('[^/]+');
        i = close + 1;
      } else if (ch == '/') {
        sb.write(r'\/');
        i++;
      } else {
        sb.write(RegExp.escape(ch));
        i++;
      }
    }
    sb.write(r'\/?$');
    return RegExp(sb.toString());
  }

  void _addLog({
    required String method,
    required String path,
    String? query,
    required int statusCode,
    required int durationMs,
    int responseSize = 0,
  }) {
    _logs.insert(
      0,
      ServerLogEntry(
        timestamp: DateTime.now(),
        method: method,
        path: path,
        query: query,
        statusCode: statusCode,
        durationMs: durationMs,
        responseSize: responseSize,
      ),
    );
    if (_logs.length > _maxLogs) {
      _logs.removeRange(_maxLogs, _logs.length);
    }
  }

  Future<void> dispose() async {
    await stop();
  }
}