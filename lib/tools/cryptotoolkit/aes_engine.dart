import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;

import 'models.dart';

class AesException implements Exception {
  AesException(this.errorKey, [this.detail]);

  final String errorKey;
  final String? detail;

  @override
  String toString() => detail == null ? errorKey : '$errorKey: $detail';
}

class AesEncryptedResult {
  const AesEncryptedResult({
    required this.cipherBase64,
    required this.ivBase64,
    required this.keyBase64,
    required this.keyHex,
    required this.ivHex,
    required this.mode,
    required this.plaintextBytes,
    required this.cipherBytes,
  });

  final String cipherBase64;
  final String ivBase64;
  final String keyBase64;
  final String keyHex;
  final String ivHex;
  final AesMode mode;
  final int plaintextBytes;
  final int cipherBytes;

  String get combinedBase64 {
    final Uint8List iv = base64Decode(ivBase64);
    final Uint8List ct = base64Decode(cipherBase64);
    final Uint8List out = Uint8List(iv.length + ct.length);
    out.setRange(0, iv.length, iv);
    out.setRange(iv.length, out.length, ct);
    return base64Encode(out);
  }
}

class AesDecryptedResult {
  const AesDecryptedResult({
    required this.plaintext,
    required this.plaintextBytes,
  });

  final String plaintext;
  final int plaintextBytes;
}

class AesEngine {
  AesEngine._();

  static final Random _rng = Random.secure();

  static int ivLengthFor(AesMode mode) {
    switch (mode) {
      case AesMode.gcm:
        return 12;
      case AesMode.cbc:
        return 16;
    }
  }

  static enc.AESMode _encryptMode(AesMode mode) {
    switch (mode) {
      case AesMode.gcm:
        return enc.AESMode.gcm;
      case AesMode.cbc:
        return enc.AESMode.cbc;
    }
  }

  static Uint8List generateKeyBytes(AesKeySize size) {
    return Uint8List.fromList(
      List<int>.generate(size.bytes, (_) => _rng.nextInt(256)),
    );
  }

  static Uint8List generateIvBytes(AesMode mode) {
    final int len = ivLengthFor(mode);
    return Uint8List.fromList(
      List<int>.generate(len, (_) => _rng.nextInt(256)),
    );
  }

  static Uint8List parseKeyInput(String raw, AesKeySize expected) {
    final String t = raw.trim();
    if (t.isEmpty) {
      throw AesException(CryptoToolkitErrors.aesInvalidKey, 'Empty key');
    }

    final String cleaned = t.replaceAll(RegExp(r'\s+'), '');

    if (RegExp(r'^[0-9a-fA-F]+$').hasMatch(cleaned) &&
        cleaned.length == expected.bytes * 2) {
      return _hexToBytes(cleaned);
    }

    if (_looksLikeBase64(cleaned)) {
      try {
        final Uint8List bytes = base64Decode(cleaned);
        if (bytes.length == expected.bytes) return bytes;
      } catch (_) {}
    }

    final Uint8List utf8Bytes = Uint8List.fromList(utf8.encode(t));
    if (utf8Bytes.length == expected.bytes) return utf8Bytes;

    throw AesException(
      CryptoToolkitErrors.aesInvalidKey,
      'Key must be ${expected.bytes} bytes (hex: ${expected.bytes * 2} chars, or ${expected.bytes} UTF-8 bytes). Got ${utf8Bytes.length} bytes.',
    );
  }

  static Uint8List parseIvInput(String raw, AesMode mode) {
    final String t = raw.trim();
    if (t.isEmpty) {
      throw AesException(CryptoToolkitErrors.aesInvalidIv, 'Empty IV');
    }

    final int expected = ivLengthFor(mode);
    final String cleaned = t.replaceAll(RegExp(r'\s+'), '');

    if (RegExp(r'^[0-9a-fA-F]+$').hasMatch(cleaned) &&
        cleaned.length == expected * 2) {
      return _hexToBytes(cleaned);
    }

    if (_looksLikeBase64(cleaned)) {
      try {
        final Uint8List bytes = base64Decode(cleaned);
        if (bytes.length == expected) return bytes;
      } catch (_) {}
    }

    throw AesException(
      CryptoToolkitErrors.aesInvalidIv,
      'IV must be $expected bytes (hex: ${expected * 2} chars, or $expected UTF-8 bytes)',
    );
  }

  static bool _looksLikeBase64(String s) {
    if (s.isEmpty) return false;
    if (s.length % 4 != 0) return false;
    return RegExp(r'^[A-Za-z0-9+/]+={0,2}$').hasMatch(s);
  }

  static Uint8List _hexToBytes(String hex) {
    final Uint8List out = Uint8List(hex.length ~/ 2);
    for (int i = 0; i < out.length; i++) {
      out[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }

  static AesEncryptedResult encrypt({
    required String plaintext,
    required Uint8List keyBytes,
    required Uint8List ivBytes,
    required AesMode mode,
  }) {
    if (plaintext.isEmpty) {
      throw AesException(CryptoToolkitErrors.aesEmptyInput);
    }

    try {
      final enc.Key key = enc.Key(keyBytes);
      final enc.IV iv = enc.IV(ivBytes);
      final enc.Encrypter encrypter = enc.Encrypter(
        enc.AES(key, mode: _encryptMode(mode)),
      );

      final enc.Encrypted encrypted = encrypter.encrypt(plaintext, iv: iv);
      final Uint8List cipherBytes = encrypted.bytes;

      return AesEncryptedResult(
        cipherBase64: base64Encode(cipherBytes),
        ivBase64: base64Encode(ivBytes),
        keyBase64: base64Encode(keyBytes),
        keyHex: _bytesToHex(keyBytes),
        ivHex: _bytesToHex(ivBytes),
        mode: mode,
        plaintextBytes: utf8.encode(plaintext).length,
        cipherBytes: cipherBytes.length,
      );
    } catch (e) {
      if (e is AesException) rethrow;
      throw AesException(
        CryptoToolkitErrors.aesInvalidKey,
        'Encryption failed: $e',
      );
    }
  }

  static AesDecryptedResult decrypt({
    required String cipherBase64,
    required Uint8List keyBytes,
    required Uint8List ivBytes,
    required AesMode mode,
  }) {
    final String t = cipherBase64.trim().replaceAll(RegExp(r'\s+'), '');
    if (t.isEmpty) {
      throw AesException(CryptoToolkitErrors.aesEmptyInput);
    }

    Uint8List cipherBytes;
    try {
      cipherBytes = base64Decode(t);
    } catch (_) {
      throw AesException(
        CryptoToolkitErrors.aesInvalidBase64,
        'Cipher is not valid base64',
      );
    }

    try {
      final enc.Key key = enc.Key(keyBytes);
      final enc.IV iv = enc.IV(ivBytes);
      final enc.Encrypter encrypter = enc.Encrypter(
        enc.AES(key, mode: _encryptMode(mode)),
      );

      final enc.Encrypted encrypted = enc.Encrypted(cipherBytes);
      final String plaintext = encrypter.decrypt(encrypted, iv: iv);

      return AesDecryptedResult(
        plaintext: plaintext,
        plaintextBytes: utf8.encode(plaintext).length,
      );
    } catch (e) {
      final String msg = e.toString().toLowerCase();
      if (mode == AesMode.gcm && msg.contains('tag')) {
        throw AesException(
          CryptoToolkitErrors.aesTagMismatch,
          'Authentication tag mismatch — ciphertext or key is wrong',
        );
      }
      throw AesException(
        CryptoToolkitErrors.aesDecryptFailed,
        'Decryption failed: $e',
      );
    }
  }

  static Uint8List splitCombined(String combinedBase64, AesMode mode) {
    final String t = combinedBase64.trim().replaceAll(RegExp(r'\s+'), '');
    if (t.isEmpty) {
      throw AesException(CryptoToolkitErrors.aesEmptyInput);
    }
    Uint8List raw;
    try {
      raw = base64Decode(t);
    } catch (_) {
      throw AesException(
        CryptoToolkitErrors.aesInvalidBase64,
        'Combined payload is not valid base64',
      );
    }

    final int ivLen = ivLengthFor(mode);
    if (raw.length <= ivLen) {
      throw AesException(
        CryptoToolkitErrors.aesInvalidBase64,
        'Combined payload too short (need > $ivLen bytes)',
      );
    }

    final Uint8List iv = Uint8List.fromList(raw.sublist(0, ivLen));
    final Uint8List ct = Uint8List.fromList(raw.sublist(ivLen));
    final Uint8List out = Uint8List(iv.length + ct.length);
    out.setRange(0, iv.length, iv);
    out.setRange(iv.length, out.length, ct);
    return out;
  }

  static (Uint8List iv, Uint8List ct) parseCombined(
      String combinedBase64,
      AesMode mode,
      ) {
    final Uint8List raw = splitCombined(combinedBase64, mode);
    final int ivLen = ivLengthFor(mode);
    return (
    Uint8List.fromList(raw.sublist(0, ivLen)),
    Uint8List.fromList(raw.sublist(ivLen)),
    );
  }

  static String _bytesToHex(Uint8List bytes) {
    return bytes
        .map((int b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  static String generateRandomKeyBase64(AesKeySize size) {
    return base64Encode(generateKeyBytes(size));
  }

  static String generateRandomKeyHex(AesKeySize size) {
    return _bytesToHex(generateKeyBytes(size));
  }

  static String generateRandomIvBase64(AesMode mode) {
    return base64Encode(generateIvBytes(mode));
  }

  static String generateRandomIvHex(AesMode mode) {
    return _bytesToHex(generateIvBytes(mode));
  }
}