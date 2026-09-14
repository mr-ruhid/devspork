import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'models.dart';

class Base32 {
  Base32._();

  static const String _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  static Base32Result decode(String input) {
    final String cleaned = input
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z2-7]'), '');

    if (cleaned.isEmpty) {
      return const Base32Result(errorKey: 'totpgen_error_secret_empty');
    }

    final List<int> output = <int>[];
    int buffer = 0;
    int bitsLeft = 0;

    for (int i = 0; i < cleaned.length; i++) {
      final int val = _alphabet.indexOf(cleaned[i]);
      if (val == -1) {
        return const Base32Result(errorKey: 'totpgen_error_secret_invalid');
      }
      buffer = (buffer << 5) | val;
      bitsLeft += 5;

      if (bitsLeft >= 8) {
        bitsLeft -= 8;
        output.add((buffer >> bitsLeft) & 0xFF);
      }
    }

    if (output.isEmpty) {
      return const Base32Result(errorKey: 'totpgen_error_secret_invalid');
    }

    return Base32Result(bytes: output);
  }

  static String encode(List<int> bytes) {
    final StringBuffer sb = StringBuffer();
    int buffer = 0;
    int bitsLeft = 0;

    for (final int b in bytes) {
      buffer = (buffer << 8) | (b & 0xFF);
      bitsLeft += 8;
      while (bitsLeft >= 5) {
        bitsLeft -= 5;
        sb.write(_alphabet[(buffer >> bitsLeft) & 0x1F]);
      }
    }

    if (bitsLeft > 0) {
      sb.write(_alphabet[(buffer << (5 - bitsLeft)) & 0x1F]);
    }

    return sb.toString();
  }

  static String generateSecret({int length = 20}) {
    final Random rng = Random.secure();
    final List<int> bytes = List<int>.generate(length, (_) => rng.nextInt(256));
    return encode(bytes);
  }
}

class TotpGenerator {
  TotpGenerator._();

  static TotpCode generate({
    required TotpConfig config,
    DateTime? now,
  }) {
    final DateTime current = now ?? DateTime.now().toUtc();
    final int unixSeconds = current.millisecondsSinceEpoch ~/ 1000;
    final int counter = unixSeconds ~/ config.period;

    final Base32Result decoded = Base32.decode(config.secret);
    if (!decoded.isOk) {
      return TotpCode(
        code: '',
        remainingSeconds: 0,
        period: config.period,
        generatedAt: current,
        counter: counter,
      );
    }

    final String code = _hotp(
      key: decoded.bytes,
      counter: counter,
      digits: config.digits,
      algorithm: config.algorithm,
    );

    final int elapsed = unixSeconds % config.period;
    final int remaining = config.period - elapsed;

    return TotpCode(
      code: code,
      remainingSeconds: remaining,
      period: config.period,
      generatedAt: current,
      counter: counter,
    );
  }

  static String _hotp({
    required List<int> key,
    required int counter,
    required int digits,
    required TotpAlgorithm algorithm,
  }) {
    final Uint8List counterBytes = Uint8List(8);
    int c = counter;
    for (int i = 7; i >= 0; i--) {
      counterBytes[i] = c & 0xFF;
      c >>= 8;
    }

    final Hash hash = _hashFor(algorithm);
    final Hmac hmac = Hmac(hash, key);
    final Digest digest = hmac.convert(counterBytes);
    final List<int> hashBytes = digest.bytes;

    final int offset = hashBytes[hashBytes.length - 1] & 0x0F;
    final int b0 = hashBytes[offset] & 0x7F;
    final int b1 = hashBytes[offset + 1] & 0xFF;
    final int b2 = hashBytes[offset + 2] & 0xFF;
    final int b3 = hashBytes[offset + 3] & 0xFF;

    final int binary = (b0 << 24) | (b1 << 16) | (b2 << 8) | b3;
    final int modulo = _pow10(digits);
    final int otp = binary % modulo;

    return otp.toString().padLeft(digits, '0');
  }

  static Hash _hashFor(TotpAlgorithm alg) {
    switch (alg) {
      case TotpAlgorithm.sha1:
        return sha1;
      case TotpAlgorithm.sha256:
        return sha256;
      case TotpAlgorithm.sha512:
        return sha512;
    }
  }

  static int _pow10(int exp) {
    int result = 1;
    for (int i = 0; i < exp; i++) {
      result *= 10;
    }
    return result;
  }

  static bool verify({
    required TotpConfig config,
    required String code,
    DateTime? now,
    int window = 1,
  }) {
    final String target = code.trim().replaceAll(RegExp(r'\s+'), '');
    if (target.isEmpty) return false;

    final DateTime current = now ?? DateTime.now().toUtc();
    final int unixSeconds = current.millisecondsSinceEpoch ~/ 1000;
    final int baseCounter = unixSeconds ~/ config.period;

    final Base32Result decoded = Base32.decode(config.secret);
    if (!decoded.isOk) return false;

    for (int delta = -window; delta <= window; delta++) {
      final String candidate = _hotp(
        key: decoded.bytes,
        counter: baseCounter + delta,
        digits: config.digits,
        algorithm: config.algorithm,
      );
      if (_constantTimeEquals(candidate, target)) return true;
    }
    return false;
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  static String buildOtpAuthUri(TotpUriData data) {
    final StringBuffer sb = StringBuffer();
    sb.write('otpauth://totp/');

    if (data.issuer != null && data.issuer!.isNotEmpty) {
      sb.write(Uri.encodeComponent(data.issuer!));
      sb.write(':');
    }
    if (data.account != null && data.account!.isNotEmpty) {
      sb.write(Uri.encodeComponent(data.account!));
    }

    final Map<String, String> params = <String, String>{
      'secret': data.secret,
      'digits': '${data.digits}',
      'period': '${data.period}',
      'algorithm': data.algorithm.id,
    };
    if (data.issuer != null && data.issuer!.isNotEmpty) {
      params['issuer'] = data.issuer!;
    }

    final List<String> pairs = params.entries
        .map((MapEntry<String, String> e) =>
    '${e.key}=${Uri.encodeComponent(e.value)}')
        .toList();

    sb.write('?');
    sb.write(pairs.join('&'));
    return sb.toString();
  }

  static TotpUriData? parseOtpAuthUri(String uri) {
    final String trimmed = uri.trim();
    if (!trimmed.toLowerCase().startsWith('otpauth://totp/')) return null;

    final Uri? parsed = Uri.tryParse(trimmed);
    if (parsed == null) return null;

    final String path = parsed.path.startsWith('/')
        ? parsed.path.substring(1)
        : parsed.path;

    String? issuer;
    String? account;
    if (path.isNotEmpty) {
      final int idx = path.indexOf(':');
      if (idx != -1) {
        issuer = Uri.decodeComponent(path.substring(0, idx));
        account = Uri.decodeComponent(path.substring(idx + 1));
      } else {
        account = Uri.decodeComponent(path);
      }
    }

    final Map<String, String> qp = parsed.queryParameters;
    final String? secret = qp['secret'];
    if (secret == null || secret.isEmpty) return null;

    final int digits = int.tryParse(qp['digits'] ?? '') ?? 6;
    final int period = int.tryParse(qp['period'] ?? '') ?? 30;
    final TotpAlgorithm algorithm =
    TotpAlgorithmX.fromId(qp['algorithm'] ?? 'SHA1');

    if (qp['issuer'] != null && qp['issuer']!.isNotEmpty) {
      issuer = qp['issuer'];
    }

    return TotpUriData(
      issuer: issuer,
      account: account,
      secret: secret.toUpperCase().replaceAll(RegExp(r'[^A-Z2-7]'), ''),
      digits: digits.clamp(6, 8),
      period: period.clamp(10, 120),
      algorithm: algorithm,
    );
  }
}