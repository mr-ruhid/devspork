enum TotpAlgorithm { sha1, sha256, sha512 }

extension TotpAlgorithmX on TotpAlgorithm {
  String get id {
    switch (this) {
      case TotpAlgorithm.sha1:
        return 'SHA1';
      case TotpAlgorithm.sha256:
        return 'SHA256';
      case TotpAlgorithm.sha512:
        return 'SHA512';
    }
  }

  String get displayName => id;

  static TotpAlgorithm fromId(String id) {
    final String upper = id.trim().toUpperCase();
    for (final TotpAlgorithm a in TotpAlgorithm.values) {
      if (a.id == upper) return a;
    }
    return TotpAlgorithm.sha1;
  }
}

class TotpConfig {
  String secret;
  int digits;
  int period;
  TotpAlgorithm algorithm;

  TotpConfig({
    this.secret = '',
    this.digits = 6,
    this.period = 30,
    this.algorithm = TotpAlgorithm.sha1,
  });

  TotpConfig copy() => TotpConfig(
    secret: secret,
    digits: digits,
    period: period,
    algorithm: algorithm,
  );
}

class TotpCode {
  final String code;
  final int remainingSeconds;
  final int period;
  final DateTime generatedAt;
  final int counter;

  const TotpCode({
    required this.code,
    required this.remainingSeconds,
    required this.period,
    required this.generatedAt,
    required this.counter,
  });

  double get progress =>
      period == 0 ? 0 : remainingSeconds / period;
}

class TotpUriData {
  final String? issuer;
  final String? account;
  final String secret;
  final int digits;
  final int period;
  final TotpAlgorithm algorithm;

  const TotpUriData({
    this.issuer,
    this.account,
    required this.secret,
    this.digits = 6,
    this.period = 30,
    this.algorithm = TotpAlgorithm.sha1,
  });
}

class Base32Result {
  final List<int> bytes;
  final String? errorKey;

  const Base32Result({
    this.bytes = const <int>[],
    this.errorKey,
  });

  bool get isOk => errorKey == null;
}