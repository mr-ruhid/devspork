import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'models.dart';

class HmacException implements Exception {
  HmacException(this.errorKey, [this.detail]);

  final String errorKey;
  final String? detail;

  @override
  String toString() => detail == null ? errorKey : '$errorKey: $detail';
}

class HmacOutput {
  const HmacOutput({
    required this.hex,
    required this.base64,
    required this.bytes,
  });

  final String hex;
  final String base64;
  final List<int> bytes;

  int get length => bytes.length;
  int get bitLength => bytes.length * 8;
}

class HmacVerifyResult {
  const HmacVerifyResult({
    required this.matches,
    required this.expected,
    required this.actual,
  });

  final bool matches;
  final String expected;
  final String actual;
}

class HmacEngine {
  HmacEngine._();

  static Hash _hashFor(HmacAlgorithm algo) {
    switch (algo) {
      case HmacAlgorithm.md5:
        return md5;
      case HmacAlgorithm.sha1:
        return sha1;
      case HmacAlgorithm.sha256:
        return sha256;
      case HmacAlgorithm.sha384:
        return sha384;
      case HmacAlgorithm.sha512:
        return sha512;
    }
  }

  static List<int> decodeKey(String raw, KeyFormat format) {
    switch (format) {
      case KeyFormat.text:
        if (raw.isEmpty) {
          throw HmacException(CryptoToolkitErrors.hmacEmptyKey);
        }
        return utf8.encode(raw);

      case KeyFormat.hex:
        final String cleaned = raw.replaceAll(RegExp(r'\s+'), '');
        if (cleaned.isEmpty) {
          throw HmacException(CryptoToolkitErrors.hmacEmptyKey);
        }
        if (cleaned.length.isOdd) {
          throw HmacException(
            CryptoToolkitErrors.hmacInvalidKey,
            'Hex length must be even (got ${cleaned.length})',
          );
        }
        if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(cleaned)) {
          throw HmacException(
            CryptoToolkitErrors.hmacInvalidKey,
            'Non-hex characters found',
          );
        }
        final List<int> out = <int>[];
        for (int i = 0; i < cleaned.length; i += 2) {
          out.add(int.parse(cleaned.substring(i, i + 2), radix: 16));
        }
        return out;

      case KeyFormat.base64:
        final String cleaned = raw.replaceAll(RegExp(r'\s+'), '');
        if (cleaned.isEmpty) {
          throw HmacException(CryptoToolkitErrors.hmacEmptyKey);
        }
        try {
          return base64Decode(cleaned);
        } catch (_) {
          throw HmacException(
            CryptoToolkitErrors.hmacInvalidKey,
            'Invalid base64 key',
          );
        }
    }
  }

  static HmacOutput compute({
    required String message,
    required String key,
    required KeyFormat keyFormat,
    required HmacAlgorithm algorithm,
  }) {
    if (message.isEmpty) {
      throw HmacException(CryptoToolkitErrors.hmacEmptyMessage);
    }
    if (key.isEmpty) {
      throw HmacException(CryptoToolkitErrors.hmacEmptyKey);
    }

    final List<int> keyBytes = decodeKey(key, keyFormat);
    final List<int> msgBytes = utf8.encode(message);

    final Hmac hmac = Hmac(_hashFor(algorithm), keyBytes);
    final Digest digest = hmac.convert(msgBytes);

    return HmacOutput(
      hex: digest.toString(),
      base64: base64Encode(digest.bytes),
      bytes: digest.bytes,
    );
  }

  static HmacVerifyResult verify({
    required String expected,
    required HmacOutput actual,
  }) {
    final String normalizedExpected = _normalizeSignature(expected);
    final String normalizedActual = actual.hex.toLowerCase();

    final bool ok = _constantTimeEquals(normalizedExpected, normalizedActual);

    return HmacVerifyResult(
      matches: ok,
      expected: normalizedExpected,
      actual: normalizedActual,
    );
  }

  static String _normalizeSignature(String raw) {
    String s = raw.trim().replaceAll(RegExp(r'\s+'), '');
    s = s.replaceAll('-', '').replaceAll(':', '');
    return s.toLowerCase();
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  static String generateRandomKey({
    int bytes = 32,
    KeyFormat format = KeyFormat.hex,
  }) {
    final Random rng = Random.secure();
    final List<int> raw = List<int>.generate(bytes, (_) => rng.nextInt(256));

    switch (format) {
      case KeyFormat.hex:
        return raw
            .map((int b) => b.toRadixString(16).padLeft(2, '0'))
            .join();
      case KeyFormat.base64:
        return base64Encode(raw);
      case KeyFormat.text:
        return base64Url.encode(raw);
    }
  }

  static String formatHex(String hex, {int groupSize = 4}) {
    final StringBuffer b = StringBuffer();
    for (int i = 0; i < hex.length; i += groupSize) {
      if (i > 0) b.write(' ');
      final int end = (i + groupSize).clamp(0, hex.length);
      b.write(hex.substring(i, end));
    }
    return b.toString();
  }
}