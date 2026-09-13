import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'models.dart';

class JwtCrypto {
  JwtCrypto._();

  static String encodeSegment(Map<String, dynamic> data) {
    final String json = jsonEncode(data);
    final List<int> bytes = utf8.encode(json);
    return _base64UrlEncode(bytes);
  }

  static Map<String, dynamic> decodeSegment(String segment) {
    final List<int> bytes = _base64UrlDecode(segment);
    final String json = utf8.decode(bytes);
    final dynamic decoded = jsonDecode(json);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const FormatException('Segment is not a JSON object');
  }

  static String _base64UrlEncode(List<int> bytes) {
    final String b64 = base64Url.encode(bytes);
    return b64.replaceAll('=', '');
  }

  static List<int> _base64UrlDecode(String segment) {
    String normalized = segment.replaceAll('-', '+').replaceAll('_', '/');
    final int remainder = normalized.length % 4;
    if (remainder == 2) {
      normalized += '==';
    } else if (remainder == 3) {
      normalized += '=';
    } else if (remainder == 1) {
      throw const FormatException('Invalid base64url length');
    }
    return base64.decode(normalized);
  }

  static List<int> _hmacKey(String secret) => utf8.encode(secret);

  static Hash _hashFor(JwtAlgorithm alg) {
    switch (alg) {
      case JwtAlgorithm.hs256:
        return sha256;
      case JwtAlgorithm.hs384:
        return sha384;
      case JwtAlgorithm.hs512:
        return sha512;
      case JwtAlgorithm.none:
        throw const FormatException('none algorithm has no hash');
    }
  }

  static String sign(String data, String secret, JwtAlgorithm alg) {
    if (alg == JwtAlgorithm.none) return '';
    final Hmac hmac = Hmac(_hashFor(alg), _hmacKey(secret));
    final Digest digest = hmac.convert(utf8.encode(data));
    return _base64UrlEncode(digest.bytes);
  }

  static bool verify(
      String data,
      String signature,
      String secret,
      JwtAlgorithm alg,
      ) {
    if (alg == JwtAlgorithm.none) return signature.isEmpty;
    final String expected = sign(data, secret, alg);
    return _constantTimeEquals(expected, signature);
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  static String generateToken({
    required JwtHeader header,
    required Map<String, dynamic> payload,
    required String secret,
    required JwtAlgorithm algorithm,
  }) {
    final JwtHeader h = header.copy();
    h.alg = algorithm.id;

    final String headerB64 = encodeSegment(h.toMap());
    final String payloadB64 = encodeSegment(payload);
    final String signingInput = '$headerB64.$payloadB64';

    final String signature = sign(signingInput, secret, algorithm);
    if (algorithm == JwtAlgorithm.none) {
      return '$signingInput.';
    }
    return '$signingInput.$signature';
  }

  static JwtDecoded decodeToken(String token) {
    final String trimmed = token.trim();
    final List<String> parts = trimmed.split('.');

    if (parts.length < 2) {
      throw const FormatException('JWT must have at least 2 parts');
    }

    final String headerPart = parts[0];
    final String payloadPart = parts[1];
    final String signaturePart = parts.length >= 3 ? parts[2] : '';

    final Map<String, dynamic> headerMap = decodeSegment(headerPart);
    final Map<String, dynamic> payloadMap = decodeSegment(payloadPart);

    return JwtDecoded(
      rawHeader: headerPart,
      rawPayload: payloadPart,
      rawSignature: signaturePart,
      rawToken: trimmed,
      header: JwtHeader.fromMap(headerMap),
      payload: payloadMap,
    );
  }

  static bool verifyToken(
      JwtDecoded decoded,
      String secret,
      JwtAlgorithm algorithm,
      ) {
    if (algorithm == JwtAlgorithm.none) {
      return decoded.rawSignature.isEmpty;
    }
    final String signingInput = '${decoded.rawHeader}.${decoded.rawPayload}';
    return verify(
      signingInput,
      decoded.rawSignature,
      secret,
      algorithm,
    );
  }

  static bool isExpired(Map<String, dynamic> payload) {
    final dynamic exp = payload['exp'];
    if (exp == null) return false;
    final int? expSeconds = _toIntSeconds(exp);
    if (expSeconds == null) return false;
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 > expSeconds;
  }

  static bool isNotYetValid(Map<String, dynamic> payload) {
    final dynamic nbf = payload['nbf'];
    if (nbf == null) return false;
    final int? nbfSeconds = _toIntSeconds(nbf);
    if (nbfSeconds == null) return false;
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 < nbfSeconds;
  }

  static int? _toIntSeconds(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final int? parsed = int.tryParse(value);
      if (parsed != null) return parsed;
      final DateTime? dt = DateTime.tryParse(value);
      if (dt != null) return dt.millisecondsSinceEpoch ~/ 1000;
    }
    return null;
  }

  static DateTime? claimToDate(dynamic value) {
    final int? seconds = _toIntSeconds(value);
    if (seconds == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(
      seconds * 1000,
      isUtc: true,
    );
  }

  static String formatClaimTime(dynamic value) {
    final DateTime? dt = claimToDate(value);
    if (dt == null) return value?.toString() ?? '';
    final DateTime local = dt.toLocal();
    return '${_two(local.year)}-${_two(local.month)}-${_two(local.day)} '
        '${_two(local.hour)}:${_two(local.minute)}:${_two(local.second)}';
  }

  static String _two(int n) => n < 10 ? '0$n' : '$n';
}

class JwtSampleSecrets {
  JwtSampleSecrets._();

  static String randomSecret({int length = 32}) {
    const String chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final List<int> codes = List<int>.generate(
      length,
          (int i) => chars.codeUnitAt(
        DateTime.now().microsecondsSinceEpoch % chars.length,
      ),
    );
    return String.fromCharCodes(codes);
  }
}