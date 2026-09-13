enum JwtAlgorithm { hs256, hs384, hs512, none }

extension JwtAlgorithmX on JwtAlgorithm {
  String get id {
    switch (this) {
      case JwtAlgorithm.hs256:
        return 'HS256';
      case JwtAlgorithm.hs384:
        return 'HS384';
      case JwtAlgorithm.hs512:
        return 'HS512';
      case JwtAlgorithm.none:
        return 'none';
    }
  }

  String get displayName => id;

  bool get requiresSecret => this != JwtAlgorithm.none;

  bool get isSupported => this != JwtAlgorithm.none;

  static JwtAlgorithm fromId(String id) {
    final String upper = id.trim().toUpperCase();
    for (final JwtAlgorithm a in JwtAlgorithm.values) {
      if (a.id == upper) return a;
    }
    return JwtAlgorithm.hs256;
  }
}

class JwtHeader {
  String alg;
  String typ;
  String? kid;
  Map<String, dynamic> extra;

  JwtHeader({
    this.alg = 'HS256',
    this.typ = 'JWT',
    this.kid,
    Map<String, dynamic>? extra,
  }) : extra = extra ?? <String, dynamic>{};

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{
      'alg': alg,
      'typ': typ,
    };
    if (kid != null && kid!.isNotEmpty) {
      map['kid'] = kid;
    }
    map.addAll(extra);
    return map;
  }

  factory JwtHeader.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic> extra = Map<String, dynamic>.from(map);
    final String alg = map['alg']?.toString() ?? 'HS256';
    final String typ = map['typ']?.toString() ?? 'JWT';
    final String? kid = map['kid']?.toString();
    extra.remove('alg');
    extra.remove('typ');
    extra.remove('kid');
    return JwtHeader(
      alg: alg,
      typ: typ,
      kid: kid,
      extra: extra,
    );
  }

  JwtHeader copy() => JwtHeader(
    alg: alg,
    typ: typ,
    kid: kid,
    extra: Map<String, dynamic>.from(extra),
  );
}

class JwtClaim {
  final String key;
  final dynamic value;
  final bool isRegistered;
  final String? descriptionKey;

  const JwtClaim({
    required this.key,
    required this.value,
    this.isRegistered = false,
    this.descriptionKey,
  });
}

class JwtDecoded {
  final String rawHeader;
  final String rawPayload;
  final String rawSignature;
  final String rawToken;
  final JwtHeader header;
  final Map<String, dynamic> payload;
  final String? signatureError;

  JwtDecoded({
    required this.rawHeader,
    required this.rawPayload,
    required this.rawSignature,
    required this.rawToken,
    required this.header,
    required this.payload,
    this.signatureError,
  });

  bool get hasSignature => rawSignature.isNotEmpty;

  JwtAlgorithm get algorithm =>
      JwtAlgorithmX.fromId(header.alg);
}

class ClaimExplanation {
  static const Map<String, String> descriptions = <String, String>{
    'iss': 'jwtgen_claim_iss',
    'sub': 'jwtgen_claim_sub',
    'aud': 'jwtgen_claim_aud',
    'exp': 'jwtgen_claim_exp',
    'nbf': 'jwtgen_claim_nbf',
    'iat': 'jwtgen_claim_iat',
    'jti': 'jwtgen_claim_jti',
  };

  static bool isRegistered(String key) => descriptions.containsKey(key);

  static String? descriptionKeyFor(String key) => descriptions[key];

  static const List<String> timeClaims = <String>['exp', 'nbf', 'iat'];

  static bool isTimeClaim(String key) => timeClaims.contains(key);
}