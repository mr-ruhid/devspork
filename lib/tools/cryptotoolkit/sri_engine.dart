import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'models.dart';

class SriException implements Exception {
  SriException(this.errorKey, [this.detail]);

  final String errorKey;
  final String? detail;

  @override
  String toString() => detail == null ? errorKey : '$errorKey: $detail';
}

class SriResult {
  const SriResult({
    required this.integrity,
    required this.hashBase64,
    required this.byteLength,
    required this.algorithm,
  });

  final String integrity;
  final String hashBase64;
  final int byteLength;
  final SriAlgorithm algorithm;
}

class SriEngine {
  SriEngine._();

  static Hash _hashFor(SriAlgorithm algo) {
    switch (algo) {
      case SriAlgorithm.sha256:
        return sha256;
      case SriAlgorithm.sha384:
        return sha384;
      case SriAlgorithm.sha512:
        return sha512;
    }
  }

  static SriResult fromBytes(Uint8List bytes, SriAlgorithm algorithm) {
    if (bytes.isEmpty) {
      throw SriException(CryptoToolkitErrors.sriEmptyInput);
    }

    final Digest digest = _hashFor(algorithm).convert(bytes);
    final String b64 = base64Encode(digest.bytes);
    final String integrity = '${algorithm.tag}-$b64';

    return SriResult(
      integrity: integrity,
      hashBase64: b64,
      byteLength: bytes.length,
      algorithm: algorithm,
    );
  }

  static SriResult fromText(String text, SriAlgorithm algorithm) {
    if (text.isEmpty) {
      throw SriException(CryptoToolkitErrors.sriEmptyInput);
    }
    return fromBytes(
      Uint8List.fromList(utf8.encode(text)),
      algorithm,
    );
  }

  static Future<SriResult> fromUrl(
      String url,
      SriAlgorithm algorithm, {
        Duration timeout = const Duration(seconds: 15),
      }) async {
    final Uri uri = _parseUrl(url);

    http.Response response;
    try {
      response = await http.get(
        uri,
        headers: <String, String>{
          'User-Agent': 'MiniTools-SRI-Generator/1.0',
        },
      ).timeout(timeout);
    } on http.ClientException catch (e) {
      throw SriException(CryptoToolkitErrors.sriOffline, e.message);
    } on Exception catch (e) {
      final String msg = e.toString().toLowerCase();
      if (msg.contains('timeout') || msg.contains('timed out')) {
        throw SriException(CryptoToolkitErrors.sriTimeout);
      }
      throw SriException(CryptoToolkitErrors.sriOffline, e.toString());
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SriException(
        CryptoToolkitErrors.sriFetchFailed,
        'HTTP ${response.statusCode}',
      );
    }

    final Uint8List bytes = response.bodyBytes;
    if (bytes.isEmpty) {
      throw SriException(CryptoToolkitErrors.sriEmptyInput);
    }

    return fromBytes(bytes, algorithm);
  }

  static Uri _parseUrl(String raw) {
    final String t = raw.trim();
    if (t.isEmpty) {
      throw SriException(CryptoToolkitErrors.sriBadUrl, 'Empty URL');
    }
    Uri? uri = Uri.tryParse(t);
    if (uri == null) {
      throw SriException(CryptoToolkitErrors.sriBadUrl, 'Malformed URL');
    }
    if (!uri.hasScheme) {
      uri = Uri.tryParse('https://$t');
      if (uri == null) {
        throw SriException(CryptoToolkitErrors.sriBadUrl, 'Malformed URL');
      }
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw SriException(
        CryptoToolkitErrors.sriBadUrl,
        'Only http/https URLs are supported',
      );
    }
    return uri;
  }

  static String buildScriptTag({
    required SriResult result,
    required String src,
    bool crossOrigin = true,
    bool defer = false,
    bool async = false,
  }) {
    final StringBuffer b = StringBuffer();
    b.write('<script');
    b.write(' src="$src"');
    b.write(' integrity="${result.integrity}"');
    if (crossOrigin) b.write(' crossorigin="anonymous"');
    if (defer) b.write(' defer');
    if (async) b.write(' async');
    b.write('></script>');
    return b.toString();
  }

  static String buildLinkTag({
    required SriResult result,
    required String href,
    String rel = 'stylesheet',
    String type = 'text/css',
    bool crossOrigin = true,
  }) {
    final StringBuffer b = StringBuffer();
    b.write('<link');
    b.write(' rel="$rel"');
    b.write(' href="$href"');
    b.write(' type="$type"');
    b.write(' integrity="${result.integrity}"');
    if (crossOrigin) b.write(' crossorigin="anonymous"');
    b.write('>');
    return b.toString();
  }

  static String buildTag({
    required SriResult result,
    required SriTagType tagType,
    required String target,
    bool crossOrigin = true,
    bool defer = false,
    bool async = false,
  }) {
    switch (tagType) {
      case SriTagType.script:
        return buildScriptTag(
          result: result,
          src: target,
          crossOrigin: crossOrigin,
          defer: defer,
          async: async,
        );
      case SriTagType.link:
        return buildLinkTag(
          result: result,
          href: target,
          crossOrigin: crossOrigin,
        );
    }
  }

  static String buildCspHeader(SriResult result) {
    return "require-sri-for script style;";
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
}