import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class StatusException implements Exception {
  StatusException(this.errorKey, [this.detail]);

  final String errorKey;
  final String? detail;

  @override
  String toString() => detail == null ? errorKey : '$errorKey: $detail';
}

class StatusEngine {
  StatusEngine._();

  static const List<HttpStatusCode> allCodes = <HttpStatusCode>[
    // 1xx Informational
    HttpStatusCode(
      code: 100,
      title: 'Continue',
      description:
      'The server has received the request headers and the client should proceed to send the request body.',
      category: HttpStatusCategory.informational,
    ),
    HttpStatusCode(
      code: 101,
      title: 'Switching Protocols',
      description:
      'The requester has asked the server to switch protocols and the server has agreed to do so.',
      category: HttpStatusCategory.informational,
    ),
    HttpStatusCode(
      code: 102,
      title: 'Processing',
      description:
      'The server has received and is processing the request, but no response is available yet.',
      category: HttpStatusCategory.informational,
    ),
    HttpStatusCode(
      code: 103,
      title: 'Early Hints',
      description:
      'Used to return some response headers before the final HTTP message.',
      category: HttpStatusCategory.informational,
    ),

    // 2xx Success
    HttpStatusCode(
      code: 200,
      title: 'OK',
      description:
      'Standard response for successful HTTP requests. The actual response depends on the request method.',
      category: HttpStatusCategory.success,
    ),
    HttpStatusCode(
      code: 201,
      title: 'Created',
      description:
      'The request has been fulfilled and a new resource has been created.',
      category: HttpStatusCategory.success,
    ),
    HttpStatusCode(
      code: 202,
      title: 'Accepted',
      description:
      'The request has been accepted for processing, but the processing is not complete.',
      category: HttpStatusCategory.success,
    ),
    HttpStatusCode(
      code: 203,
      title: 'Non-Authoritative Information',
      description:
      'The server is a transforming proxy that received a 200 OK from its origin, but is returning a modified version.',
      category: HttpStatusCategory.success,
    ),
    HttpStatusCode(
      code: 204,
      title: 'No Content',
      description:
      'The server successfully processed the request, and is not returning any content.',
      category: HttpStatusCategory.success,
    ),
    HttpStatusCode(
      code: 205,
      title: 'Reset Content',
      description:
      'The server successfully processed the request, asks the requester to reset the document view.',
      category: HttpStatusCategory.success,
    ),
    HttpStatusCode(
      code: 206,
      title: 'Partial Content',
      description:
      'The server is delivering only part of the resource due to a range header sent by the client.',
      category: HttpStatusCategory.success,
    ),
    HttpStatusCode(
      code: 207,
      title: 'Multi-Status',
      description:
      'The message body that follows is by default an XML message with multiple separate response codes.',
      category: HttpStatusCategory.success,
    ),
    HttpStatusCode(
      code: 208,
      title: 'Already Reported',
      description:
      'Used inside a DAV: propstat response element to avoid enumerating the internal members of multiple bindings.',
      category: HttpStatusCategory.success,
    ),
    HttpStatusCode(
      code: 226,
      title: 'IM Used',
      description:
      'The server has fulfilled a request for the resource, and the response is a representation of the result.',
      category: HttpStatusCategory.success,
    ),

    // 3xx Redirection
    HttpStatusCode(
      code: 300,
      title: 'Multiple Choices',
      description:
      'Indicates multiple options for the resource from which the client may choose.',
      category: HttpStatusCategory.redirect,
    ),
    HttpStatusCode(
      code: 301,
      title: 'Moved Permanently',
      description:
      'This and all future requests should be directed to the given URI. Ranking passes to the new URL.',
      category: HttpStatusCategory.redirect,
    ),
    HttpStatusCode(
      code: 302,
      title: 'Found',
      description:
      'Tells the client to look at another URL temporarily. Method may change to GET.',
      category: HttpStatusCategory.redirect,
    ),
    HttpStatusCode(
      code: 303,
      title: 'See Other',
      description:
      'The response to the request can be found under another URI using the GET method.',
      category: HttpStatusCategory.redirect,
    ),
    HttpStatusCode(
      code: 304,
      title: 'Not Modified',
      description:
      'Indicates that the resource has not been modified since the version specified by the request headers.',
      category: HttpStatusCategory.redirect,
    ),
    HttpStatusCode(
      code: 305,
      title: 'Use Proxy',
      description:
      'The requested resource is available only through a proxy. Deprecated due to security concerns.',
      category: HttpStatusCategory.redirect,
    ),
    HttpStatusCode(
      code: 307,
      title: 'Temporary Redirect',
      description:
      'The request should be repeated with another URI. The method must not change.',
      category: HttpStatusCategory.redirect,
    ),
    HttpStatusCode(
      code: 308,
      title: 'Permanent Redirect',
      description:
      'The request and all future requests should be repeated using another URI. The method must not change.',
      category: HttpStatusCategory.redirect,
    ),

    // 4xx Client Error
    HttpStatusCode(
      code: 400,
      title: 'Bad Request',
      description:
      'The server cannot or will not process the request due to an apparent client error.',
      category: HttpStatusCategory.clientError,
    ),
    HttpStatusCode(
      code: 401,
      title: 'Unauthorized',
      description:
      'Authentication is required and has failed or has not yet been provided.',
      category: HttpStatusCategory.clientError,
    ),
    HttpStatusCode(
      code: 402,
      title: 'Payment Required',
      description:
      'Reserved for future use. Originally intended for digital payment systems.',
      category: HttpStatusCategory.clientError,
    ),
    HttpStatusCode(
      code: 403,
      title: 'Forbidden',
      description:
      'The request was valid, but the server is refusing action. The user might not have permissions.',
      category: HttpStatusCategory.clientError,
    ),
    HttpStatusCode(
      code: 404,
      title: 'Not Found',
      description:
      'The requested resource could not be found but may be available in the future.',
      category: HttpStatusCategory.clientError,
    ),
    HttpStatusCode(
      code: 405,
      title: 'Method Not Allowed',
      description:
      'A request method is not supported for the requested resource.',
      category: HttpStatusCategory.clientError,
    ),
    HttpStatusCode(
      code: 406,
      title: 'Not Acceptable',
      description:
      'The requested resource is capable of generating only content not acceptable per the Accept headers.',
      category: HttpStatusCategory.clientError,
    ),
    HttpStatusCode(
      code: 407,
      title: 'Proxy Authentication Required',
      description:
      'The client must first authenticate itself with the proxy.',
      category: HttpStatusCategory.clientError,
    ),
    HttpStatusCode(
      code: 408,
      title: 'Request Timeout',
      description:
      'The server timed out waiting for the request.',
      category: HttpStatusCategory.clientError,
    ),
    HttpStatusCode(
      code: 409,
      title: 'Conflict',
      description:
      'Indicates that the request could not be processed because of conflict in the current state of the resource.',
      category: HttpStatusCategory.clientError,
    ),
    HttpStatusCode(
      code: 410,
      title: 'Gone',
      description:
      'Indicates that the resource requested is no longer available and will not be available again.',
      category: HttpStatusCategory.clientError,
    ),
    HttpStatusCode(
      code: 411,
      title: 'Length Required',
      description:
      'The request did not specify the length of its content, which is required by the requested resource.',
      category: HttpStatusCategory.clientError,
    ),
    HttpStatusCode(
      code: 412,
      title: 'Precondition Failed',
      description:
      'The server does not meet one of the preconditions that the requester put on the request.',
      category: HttpStatusCategory.clientError,
    ),
    HttpStatusCode(
      code: 413,
      title: 'Payload Too Large',
      description:
      'The request is larger than the server is willing or able to process.',
      category: HttpStatusCategory.clientError,
    ),
    HttpStatusCode(
      code: 414,
      title: 'URI Too Long',
      description:
      'The URI provided was too long for the server to process.',
      category: HttpStatusCategory.clientError,
    ),
    HttpStatusCode(
      code: 415,
      title: 'Unsupported Media Type',
      description:
      'The request entity has a media type which the server or resource does not support.',
      category: HttpStatusCategory.clientError,
    ),
    HttpStatusCode(
      code: 416,
      title: 'Range Not Satisfiable',
      description:
      'The client has asked for a portion of the file, but the server cannot supply that portion.',
      category: HttpStatusCategory.clientError,
    ),
    HttpStatusCode(
      code: 417,
      title: 'Expectation Failed',
      description:
      'The server cannot meet the requirements of the Expect request-header field.',
      category: HttpStatusCategory.clientError,
    ),
    HttpStatusCode(
      code: 418,
      title: "I'm a teapot",
      description:
      'This code was defined in 1998 as an April Fools\' joke (RFC 2324).',
      category: HttpStatusCategory.clientError,
    ),
    HttpStatusCode(
      code: 421,
      title: 'Misdirected Request',
      description:
      'The request was directed at a server that is not able to produce a response.',
      category: HttpStatusCategory.clientError,
    ),
    HttpStatusCode(
      code: 422,
      title: 'Unprocessable Entity',
      description:
      'The request was well-formed but was unable to be followed due to semantic errors.',
      category: HttpStatusCategory.clientError,
    ),
    HttpStatusCode(
      code: 423,
      title: 'Locked',
      description:
      'The resource that is being accessed is locked.',
      category: HttpStatusCategory.clientError,
    ),
    HttpStatusCode(
      code: 424,
      title: 'Failed Dependency',
      description:
      'The request failed because it depended on another request and that request failed.',
      category: HttpStatusCategory.clientError,
    ),
    HttpStatusCode(
      code: 425,
      title: 'Too Early',
      description:
      'Indicates that the server is unwilling to risk processing a request that might be replayed.',
      category: HttpStatusCategory.clientError,
    ),
    HttpStatusCode(
      code: 426,
      title: 'Upgrade Required',
      description:
      'The client should switch to a different protocol such as TLS/1.0.',
      category: HttpStatusCategory.clientError,
    ),
    HttpStatusCode(
      code: 428,
      title: 'Precondition Required',
      description:
      'The origin server requires the request to be conditional.',
      category: HttpStatusCategory.clientError,
    ),
    HttpStatusCode(
      code: 429,
      title: 'Too Many Requests',
      description:
      'The user has sent too many requests in a given amount of time ("rate limiting").',
      category: HttpStatusCategory.clientError,
    ),
    HttpStatusCode(
      code: 431,
      title: 'Request Header Fields Too Large',
      description:
      'The server is unwilling to process the request because its header fields are too large.',
      category: HttpStatusCategory.clientError,
    ),
    HttpStatusCode(
      code: 451,
      title: 'Unavailable For Legal Reasons',
      description:
      'A server operator has received a legal demand to deny access to a resource.',
      category: HttpStatusCategory.clientError,
    ),

    // 5xx Server Error
    HttpStatusCode(
      code: 500,
      title: 'Internal Server Error',
      description:
      'A generic error message, given when an unexpected condition was encountered.',
      category: HttpStatusCategory.serverError,
    ),
    HttpStatusCode(
      code: 501,
      title: 'Not Implemented',
      description:
      'The server either does not recognize the request method, or it lacks the ability to fulfil the request.',
      category: HttpStatusCategory.serverError,
    ),
    HttpStatusCode(
      code: 502,
      title: 'Bad Gateway',
      description:
      'The server was acting as a gateway or proxy and received an invalid response from the upstream server.',
      category: HttpStatusCategory.serverError,
    ),
    HttpStatusCode(
      code: 503,
      title: 'Service Unavailable',
      description:
      'The server is currently unavailable (overloaded or down for maintenance).',
      category: HttpStatusCategory.serverError,
    ),
    HttpStatusCode(
      code: 504,
      title: 'Gateway Timeout',
      description:
      'The server was acting as a gateway or proxy and did not receive a timely response from the upstream server.',
      category: HttpStatusCategory.serverError,
    ),
    HttpStatusCode(
      code: 505,
      title: 'HTTP Version Not Supported',
      description:
      'The server does not support the HTTP protocol version used in the request.',
      category: HttpStatusCategory.serverError,
    ),
    HttpStatusCode(
      code: 506,
      title: 'Variant Also Negotiates',
      description:
      'Transparent content negotiation for the request results in a circular reference.',
      category: HttpStatusCategory.serverError,
    ),
    HttpStatusCode(
      code: 507,
      title: 'Insufficient Storage',
      description:
      'The server is unable to store the representation needed to complete the request.',
      category: HttpStatusCategory.serverError,
    ),
    HttpStatusCode(
      code: 508,
      title: 'Loop Detected',
      description:
      'The server detected an infinite loop while processing the request.',
      category: HttpStatusCategory.serverError,
    ),
    HttpStatusCode(
      code: 510,
      title: 'Not Extended',
      description:
      'Further extensions to the request are required for the server to fulfil it.',
      category: HttpStatusCategory.serverError,
    ),
    HttpStatusCode(
      code: 511,
      title: 'Network Authentication Required',
      description:
      'The client needs to authenticate to gain network access (used by captive portals).',
      category: HttpStatusCategory.serverError,
    ),
  ];

  static HttpStatusCode? findByCode(int code) {
    for (final HttpStatusCode s in allCodes) {
      if (s.code == code) return s;
    }
    return null;
  }

  static List<HttpStatusCode> search(String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return allCodes;
    return allCodes.where((HttpStatusCode s) {
      return s.code.toString().contains(q) ||
          s.title.toLowerCase().contains(q) ||
          s.description.toLowerCase().contains(q);
    }).toList();
  }

  static List<HttpStatusCode> byCategory(HttpStatusCategory? category) {
    if (category == null) return allCodes;
    return allCodes.where((HttpStatusCode s) => s.category == category).toList();
  }

  // ==========================================================================
  // LIVE URL PROBE
  // ==========================================================================

  static Future<HttpProbeResult> probe(
      String url, {
        String method = 'GET',
        Duration timeout = const Duration(seconds: 15),
        int maxRedirects = 10,
      }) async {
    final Uri initial = _parseUrl(url);

    final Stopwatch sw = Stopwatch()..start();
    final List<HttpRedirectStep> redirects = <HttpRedirectStep>[];
    Uri current = initial;
    int redirectCount = 0;

    while (true) {
      final http.Request req = http.Request(method, current);
      req.headers['User-Agent'] = 'MiniTools-NetPack/1.0';
      req.headers['Accept'] = '*/*';
      req.followRedirects = false;

      http.StreamedResponse streamed;
      try {
        streamed = await req.send().timeout(timeout);
      } on http.ClientException catch (e) {
        sw.stop();
        throw StatusException(NetErrors.statusOffline, e.message);
      } on TimeoutException {
        sw.stop();
        throw StatusException(NetErrors.statusTimeout);
      } catch (e) {
        sw.stop();
        final String msg = e.toString().toLowerCase();
        if (msg.contains('socketexception') ||
            msg.contains('failed host lookup') ||
            msg.contains('network')) {
          throw StatusException(NetErrors.statusOffline, e.toString());
        }
        throw StatusException(NetErrors.statusFailed, e.toString());
      }

      final int statusCode = streamed.statusCode;
      final String? location = streamed.headers['location'];

      redirects.add(HttpRedirectStep(
        url: current.toString(),
        statusCode: statusCode,
        location: location,
      ));

      final bool isRedirect = statusCode >= 300 && statusCode < 400;
      if (!isRedirect || location == null || location.isEmpty) {
        sw.stop();
        return HttpProbeResult(
          url: initial.toString(),
          finalUrl: current.toString(),
          statusCode: statusCode,
          statusText: _statusText(statusCode),
          headers: _headersFromStreamed(streamed),
          redirects: redirects,
          elapsedMs: sw.elapsedMilliseconds,
          contentType: streamed.headers['content-type'],
          contentLength: int.tryParse(streamed.headers['content-length'] ?? ''),
          method: method,
        );
      }

      redirectCount++;
      if (redirectCount > maxRedirects) {
        sw.stop();
        throw StatusException(
          NetErrors.statusFailed,
          'Too many redirects (>$maxRedirects)',
        );
      }

      current = current.resolve(location);
    }
  }

  static Uri _parseUrl(String raw) {
    final String t = raw.trim();
    if (t.isEmpty) {
      throw StatusException(NetErrors.statusEmptyUrl);
    }
    Uri? uri = Uri.tryParse(t);
    if (uri == null) {
      throw StatusException(NetErrors.statusInvalidUrl, 'Malformed URL');
    }
    if (!uri.hasScheme) {
      uri = Uri.tryParse('https://$t');
      if (uri == null) {
        throw StatusException(NetErrors.statusInvalidUrl, 'Malformed URL');
      }
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw StatusException(
        NetErrors.statusInvalidUrl,
        'Only http/https URLs are supported',
      );
    }
    if (uri.host.isEmpty) {
      throw StatusException(NetErrors.statusInvalidUrl, 'URL has no host');
    }
    return uri;
  }

  static List<HttpHeader> _headersFromStreamed(http.StreamedResponse s) {
    final List<HttpHeader> out = <HttpHeader>[];
    s.headers.forEach((String k, String v) {
      out.add(HttpHeader(name: k, value: v));
    });
    out.sort((HttpHeader a, HttpHeader b) =>
        a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return out;
  }

  static String _statusText(int code) {
    final HttpStatusCode? found = findByCode(code);
    return found?.title ?? 'Unknown';
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static String formatDuration(int ms) {
    if (ms < 1000) return '${ms}ms';
    return '${(ms / 1000).toStringAsFixed(2)}s';
  }

  static String headersToText(List<HttpHeader> headers) {
    final StringBuffer b = StringBuffer();
    for (final HttpHeader h in headers) {
      b.writeln('${h.name}: ${h.value}');
    }
    return b.toString().trimRight();
  }

  static String redirectsToText(List<HttpRedirectStep> steps) {
    final StringBuffer b = StringBuffer();
    for (int i = 0; i < steps.length; i++) {
      final HttpRedirectStep s = steps[i];
      b.write('${s.statusCode}  ${s.url}');
      if (s.location != null && s.location!.isNotEmpty) {
        b.write('\n  → ${s.location}');
      }
      if (i < steps.length - 1) b.write('\n');
    }
    return b.toString();
  }

  static String probeToJson(HttpProbeResult r) {
    final Map<String, dynamic> out = <String, dynamic>{
      'url': r.url,
      'finalUrl': r.finalUrl,
      'method': r.method,
      'status': r.statusCode,
      'statusText': r.statusText,
      'category': r.category.display,
      'elapsedMs': r.elapsedMs,
      'contentType': r.contentType,
      'contentLength': r.contentLength,
      'redirects': r.redirects
          .map((HttpRedirectStep s) => <String, dynamic>{
        'url': s.url,
        'status': s.statusCode,
        'location': s.location,
      })
          .toList(),
      'headers': <String, String>{
        for (final HttpHeader h in r.headers) h.name: h.value,
      },
    };
    return const JsonEncoder.withIndent('  ').convert(out);
  }
}