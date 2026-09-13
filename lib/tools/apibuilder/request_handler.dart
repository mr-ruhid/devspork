import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'models.dart';

class RequestHandler {
  RequestHandler._();

  static final http.Client _client = http.Client();

  static const Duration _timeout = Duration(seconds: 30);

  static bool _canHaveBody(ApiRequest r) =>
      r.method != HttpMethod.get && r.method != HttpMethod.head;

  static bool _hasBody(ApiRequest r) =>
      r.bodyType != BodyType.none && r.body.isNotEmpty;

  static List<HeaderPair> _activeHeaders(ApiRequest r) {
    final List<HeaderPair> list = <HeaderPair>[];
    for (final HeaderPair h in r.headers) {
      if (h.enabled && h.key.trim().isNotEmpty) {
        list.add(h);
      }
    }
    return list;
  }

  static Map<String, String> _activeHeadersMap(ApiRequest r) {
    final Map<String, String> map = <String, String>{};
    for (final HeaderPair h in _activeHeaders(r)) {
      map[h.key.trim()] = h.value;
    }
    return map;
  }

  static bool _hasHeaderKey(Map<String, String> headers, String name) {
    final String lower = name.toLowerCase();
    for (final String k in headers.keys) {
      if (k.toLowerCase() == lower) return true;
    }
    return false;
  }

  static String? _contentTypeFor(BodyType t) {
    switch (t) {
      case BodyType.none:
        return null;
      case BodyType.json:
        return 'application/json';
      case BodyType.formUrlEncoded:
        return 'application/x-www-form-urlencoded';
      case BodyType.raw:
        return 'text/plain';
    }
  }

  static HttpMethod _methodFromValue(String v) {
    final String upper = v.trim().toUpperCase();
    for (final HttpMethod m in HttpMethod.values) {
      if (m.value == upper) return m;
    }
    return HttpMethod.get;
  }

  static Future<ApiResponse> send(ApiRequest request) async {
    if (request.url.trim().isEmpty) {
      return ApiResponse(error: 'apibuilder_error_url_empty');
    }

    final Uri? uri = Uri.tryParse(request.url.trim());
    if (uri == null || !uri.hasScheme) {
      return ApiResponse(error: 'apibuilder_error_url_invalid');
    }

    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return ApiResponse(error: 'apibuilder_error_scheme');
    }

    final Stopwatch stopwatch = Stopwatch()..start();

    try {
      final http.BaseRequest baseRequest = _buildBaseRequest(request, uri);
      _applyHeaders(baseRequest, request);

      final http.StreamedResponse streamed =
      await _client.send(baseRequest).timeout(_timeout);

      final String responseBody =
      await streamed.stream.bytesToString().timeout(_timeout);

      stopwatch.stop();

      final Map<String, String> responseHeaders = <String, String>{};
      streamed.headers.forEach((String k, String v) {
        responseHeaders[k.toLowerCase()] = v;
      });

      return ApiResponse(
        statusCode: streamed.statusCode,
        statusMessage: streamed.reasonPhrase,
        headers: responseHeaders,
        body: responseBody,
        durationMs: stopwatch.elapsedMilliseconds,
        sizeBytes: utf8.encode(responseBody).length,
      );
    } on TimeoutException {
      stopwatch.stop();
      return ApiResponse(
        error: 'apibuilder_error_timeout',
        durationMs: stopwatch.elapsedMilliseconds,
      );
    } on SocketException catch (e) {
      stopwatch.stop();
      return ApiResponse(
        error: 'apibuilder_error_socket',
        statusMessage: e.message,
        durationMs: stopwatch.elapsedMilliseconds,
      );
    } on http.ClientException catch (e) {
      stopwatch.stop();
      return ApiResponse(
        error: 'apibuilder_error_client',
        statusMessage: e.message,
        durationMs: stopwatch.elapsedMilliseconds,
      );
    } on HandshakeException catch (e) {
      stopwatch.stop();
      return ApiResponse(
        error: 'apibuilder_error_ssl',
        statusMessage: e.message,
        durationMs: stopwatch.elapsedMilliseconds,
      );
    } on FormatException catch (e) {
      stopwatch.stop();
      return ApiResponse(
        error: 'apibuilder_error_format',
        statusMessage: e.message,
        durationMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();
      return ApiResponse(
        error: 'apibuilder_error_unknown',
        statusMessage: e.toString(),
        durationMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  static http.BaseRequest _buildBaseRequest(ApiRequest request, Uri uri) {
    final String method = request.method.value;
    final bool hasBody = _canHaveBody(request) && _hasBody(request);

    if (!hasBody) {
      return http.Request(method, uri);
    }

    final http.Request req = http.Request(method, uri);
    switch (request.bodyType) {
      case BodyType.json:
        req.body = request.body;
        break;
      case BodyType.formUrlEncoded:
        req.bodyFields = _parseFormBody(request.body);
        break;
      case BodyType.raw:
        req.body = request.body;
        break;
      case BodyType.none:
        break;
    }
    return req;
  }

  static void _applyHeaders(http.BaseRequest baseRequest, ApiRequest request) {
    final Map<String, String> active = _activeHeadersMap(request);

    for (final MapEntry<String, String> e in active.entries) {
      baseRequest.headers[e.key] = e.value;
    }

    final String? autoContentType = _contentTypeFor(request.bodyType);
    if (autoContentType != null &&
        _canHaveBody(request) &&
        _hasBody(request)) {
      if (!_hasHeaderKey(active, 'content-type')) {
        baseRequest.headers['Content-Type'] = autoContentType;
      }
    }

    if (!_hasHeaderKey(active, 'user-agent')) {
      baseRequest.headers['User-Agent'] = 'DevSpork/1.0 (API Builder)';
    }

    if (!_hasHeaderKey(active, 'accept')) {
      baseRequest.headers['Accept'] = '*/*';
    }
  }

  static Map<String, String> _parseFormBody(String body) {
    final Map<String, String> result = <String, String>{};
    if (body.trim().isEmpty) return result;

    final List<String> pairs = body.split('&');
    for (final String pair in pairs) {
      if (pair.isEmpty) continue;
      final int idx = pair.indexOf('=');
      if (idx == -1) {
        result[Uri.decodeComponent(pair)] = '';
      } else {
        final String k = pair.substring(0, idx);
        final String v = pair.substring(idx + 1);
        result[Uri.decodeComponent(k)] = Uri.decodeComponent(v);
      }
    }
    return result;
  }

  static void dispose() {
    _client.close();
  }
}

class CurlExporter {
  CurlExporter._();

  static String export(ApiRequest request) {
    final StringBuffer sb = StringBuffer();
    sb.write('curl -X ${request.method.value}');

    final String url = request.url.trim();
    if (url.isEmpty) {
      sb.write(" ''");
      return sb.toString();
    }

    sb.write(" '${_escapeSingle(url)}'");

    for (final HeaderPair h in RequestHandler._activeHeaders(request)) {
      sb.write(
        ' \\\n  -H \'${_escapeSingle(h.key.trim())}: ${_escapeSingle(h.value)}\'',
      );
    }

    final String? autoContentType =
    RequestHandler._contentTypeFor(request.bodyType);
    final Map<String, String> active =
    RequestHandler._activeHeadersMap(request);

    if (autoContentType != null &&
        RequestHandler._canHaveBody(request) &&
        RequestHandler._hasBody(request)) {
      if (!RequestHandler._hasHeaderKey(active, 'content-type')) {
        sb.write(' \\\n  -H \'Content-Type: $autoContentType\'');
      }
    }

    if (RequestHandler._canHaveBody(request) &&
        RequestHandler._hasBody(request)) {
      sb.write(' \\\n  --data-raw \'${_escapeSingle(request.body)}\'');
    }

    return sb.toString();
  }

  static String _escapeSingle(String s) => s.replaceAll("'", "'\\''");
}

class CurlParser {
  CurlParser._();

  static ApiRequest? parse(String input) {
    final String trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final String normalized = trimmed
        .replaceAll('\\\r\n', ' ')
        .replaceAll('\\\n', ' ')
        .replaceAll('\r\n', ' ')
        .replaceAll('\n', ' ');

    final List<String> tokens = _tokenize(normalized);
    if (tokens.isEmpty) return null;
    if (tokens.first.toLowerCase() != 'curl' &&
        !tokens.first.toLowerCase().endsWith('curl')) {
      return null;
    }

    HttpMethod method = HttpMethod.get;
    String url = '';
    final List<HeaderPair> headers = <HeaderPair>[];
    String body = '';
    BodyType bodyType = BodyType.none;

    int i = 1;
    while (i < tokens.length) {
      final String tok = tokens[i];
      final String lower = tok.toLowerCase();

      if (lower == '-x' || lower == '--request') {
        if (i + 1 < tokens.length) {
          method = RequestHandler._methodFromValue(tokens[i + 1]);
          i += 2;
          continue;
        }
      } else if (lower == '-h' || lower == '--header') {
        if (i + 1 < tokens.length) {
          final String raw = tokens[i + 1];
          final int idx = raw.indexOf(':');
          if (idx != -1) {
            final String k = raw.substring(0, idx).trim();
            final String v = raw.substring(idx + 1).trim();
            headers.add(HeaderPair(key: k, value: v));
            if (k.toLowerCase() == 'content-type') {
              final String vLower = v.toLowerCase();
              if (vLower.contains('json')) {
                bodyType = BodyType.json;
              } else if (vLower.contains('x-www-form-urlencoded')) {
                bodyType = BodyType.formUrlEncoded;
              } else {
                bodyType = BodyType.raw;
              }
            }
          }
          i += 2;
          continue;
        }
      } else if (lower == '-d' ||
          lower == '--data' ||
          lower == '--data-raw' ||
          lower == '--data-binary' ||
          lower == '--data-ascii') {
        if (i + 1 < tokens.length) {
          body = tokens[i + 1];
          if (method == HttpMethod.get) {
            method = HttpMethod.post;
          }
          if (bodyType == BodyType.none) {
            bodyType = _guessBodyType(body);
          }
          i += 2;
          continue;
        }
      } else if (lower == '--url') {
        if (i + 1 < tokens.length) {
          url = tokens[i + 1];
          i += 2;
          continue;
        }
      } else if (lower == '-f' ||
          lower == '--fail' ||
          lower == '-s' ||
          lower == '--silent' ||
          lower == '-k' ||
          lower == '--insecure' ||
          lower == '-l' ||
          lower == '--location' ||
          lower == '-v' ||
          lower == '--verbose' ||
          lower == '-i' ||
          lower == '--include') {
        i += 1;
        continue;
      } else if (lower == '-u' || lower == '--user') {
        if (i + 1 < tokens.length) {
          final String cred = tokens[i + 1];
          final String encoded = base64Encode(utf8.encode(cred));
          headers.add(
            HeaderPair(key: 'Authorization', value: 'Basic $encoded'),
          );
          i += 2;
          continue;
        }
      }

      if (tok.startsWith('-')) {
        i += 1;
        continue;
      }

      if (url.isEmpty) {
        url = tok;
      }
      i += 1;
    }

    if (url.isEmpty) return null;

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    return ApiRequest(
      method: method,
      url: url,
      headers: headers,
      bodyType: bodyType,
      body: body,
    );
  }

  static BodyType _guessBodyType(String body) {
    final String trimmed = body.trim();
    if (trimmed.isEmpty) return BodyType.none;
    if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
        (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
      try {
        jsonDecode(trimmed);
        return BodyType.json;
      } catch (_) {}
    }
    if (trimmed.contains('=') && !trimmed.contains('\n')) {
      return BodyType.formUrlEncoded;
    }
    return BodyType.raw;
  }

  static List<String> _tokenize(String s) {
    final List<String> tokens = <String>[];
    final StringBuffer current = StringBuffer();
    bool inSingle = false;
    bool inDouble = false;
    bool hasContent = false;

    for (int i = 0; i < s.length; i++) {
      final String ch = s[i];

      if (inSingle) {
        if (ch == "'") {
          inSingle = false;
        } else {
          current.write(ch);
        }
        continue;
      }

      if (inDouble) {
        if (ch == '"') {
          inDouble = false;
        } else if (ch == '\\' && i + 1 < s.length) {
          final String next = s[i + 1];
          if (next == '"' || next == '\\' || next == '\$' || next == '`') {
            current.write(next);
            i++;
          } else {
            current.write(ch);
          }
        } else {
          current.write(ch);
        }
        continue;
      }

      if (ch == "'") {
        inSingle = true;
        hasContent = true;
        continue;
      }
      if (ch == '"') {
        inDouble = true;
        hasContent = true;
        continue;
      }
      if (ch == ' ' || ch == '\t') {
        if (hasContent) {
          tokens.add(current.toString());
          current.clear();
          hasContent = false;
        }
        continue;
      }

      current.write(ch);
      hasContent = true;
    }

    if (hasContent) {
      tokens.add(current.toString());
    }

    return tokens;
  }
}