import 'package:flutter/material.dart';

// ============================================================================
// HMAC
// ============================================================================

enum HmacAlgorithm { md5, sha1, sha256, sha384, sha512 }

extension HmacAlgorithmX on HmacAlgorithm {
  String get display {
    switch (this) {
      case HmacAlgorithm.md5:
        return 'MD5';
      case HmacAlgorithm.sha1:
        return 'SHA-1';
      case HmacAlgorithm.sha256:
        return 'SHA-256';
      case HmacAlgorithm.sha384:
        return 'SHA-384';
      case HmacAlgorithm.sha512:
        return 'SHA-512';
    }
  }
}

enum KeyFormat { text, hex, base64 }

extension KeyFormatX on KeyFormat {
  String get display {
    switch (this) {
      case KeyFormat.text:
        return 'Text';
      case KeyFormat.hex:
        return 'Hex';
      case KeyFormat.base64:
        return 'Base64';
    }
  }
}

enum OutputFormat { hex, base64 }

extension OutputFormatX on OutputFormat {
  String get display {
    switch (this) {
      case OutputFormat.hex:
        return 'Hex';
      case OutputFormat.base64:
        return 'Base64';
    }
  }
}

// ============================================================================
// AES
// ============================================================================

enum AesMode { gcm, cbc }

extension AesModeX on AesMode {
  String get display {
    switch (this) {
      case AesMode.gcm:
        return 'GCM';
      case AesMode.cbc:
        return 'CBC';
    }
  }

  String get descriptionKey {
    switch (this) {
      case AesMode.gcm:
        return 'aes_mode_gcm_desc';
      case AesMode.cbc:
        return 'aes_mode_cbc_desc';
    }
  }

  bool get isAuthenticated => this == AesMode.gcm;
}

enum AesKeySize { bits128, bits192, bits256 }

extension AesKeySizeX on AesKeySize {
  int get bytes {
    switch (this) {
      case AesKeySize.bits128:
        return 16;
      case AesKeySize.bits192:
        return 24;
      case AesKeySize.bits256:
        return 32;
    }
  }

  int get bits {
    switch (this) {
      case AesKeySize.bits128:
        return 128;
      case AesKeySize.bits192:
        return 192;
      case AesKeySize.bits256:
        return 256;
    }
  }

  String get display => '$bits-bit';
}

enum AesOperation { encrypt, decrypt }

// ============================================================================
// SRI
// ============================================================================

enum SriAlgorithm { sha256, sha384, sha512 }

extension SriAlgorithmX on SriAlgorithm {
  String get display {
    switch (this) {
      case SriAlgorithm.sha256:
        return 'SHA-256';
      case SriAlgorithm.sha384:
        return 'SHA-384';
      case SriAlgorithm.sha512:
        return 'SHA-512';
    }
  }

  String get tag {
    switch (this) {
      case SriAlgorithm.sha256:
        return 'sha256';
      case SriAlgorithm.sha384:
        return 'sha384';
      case SriAlgorithm.sha512:
        return 'sha512';
    }
  }
}

enum SriSource { text, url }

extension SriSourceX on SriSource {
  String get display {
    switch (this) {
      case SriSource.text:
        return 'Text / Content';
      case SriSource.url:
        return 'URL';
    }
  }
}

enum SriTagType { script, link }

extension SriTagTypeX on SriTagType {
  String get display {
    switch (this) {
      case SriTagType.script:
        return '<script>';
      case SriTagType.link:
        return '<link>';
    }
  }
}

// ============================================================================
// OAUTH
// ============================================================================

class OAuthProvider {
  const OAuthProvider({
    required this.id,
    required this.displayName,
    required this.authEndpoint,
    required this.tokenEndpoint,
    this.defaultScopes = const <String>[],
    this.docsUrl,
  });

  final String id;
  final String displayName;
  final String authEndpoint;
  final String tokenEndpoint;
  final List<String> defaultScopes;
  final String? docsUrl;

  static const List<OAuthProvider> presets = <OAuthProvider>[
    OAuthProvider(
      id: 'google',
      displayName: 'Google',
      authEndpoint: 'https://accounts.google.com/o/oauth2/v2/auth',
      tokenEndpoint: 'https://oauth2.googleapis.com/token',
      defaultScopes: <String>['openid', 'email', 'profile'],
      docsUrl: 'https://developers.google.com/identity/protocols/oauth2',
    ),
    OAuthProvider(
      id: 'github',
      displayName: 'GitHub',
      authEndpoint: 'https://github.com/login/oauth/authorize',
      tokenEndpoint: 'https://github.com/login/oauth/access_token',
      defaultScopes: <String>['read:user', 'user:email'],
      docsUrl: 'https://docs.github.com/en/apps/oauth-apps',
    ),
    OAuthProvider(
      id: 'microsoft',
      displayName: 'Microsoft',
      authEndpoint:
      'https://login.microsoftonline.com/common/oauth2/v2.0/authorize',
      tokenEndpoint:
      'https://login.microsoftonline.com/common/oauth2/v2.0/token',
      defaultScopes: <String>['openid', 'email', 'profile', 'offline_access'],
      docsUrl: 'https://learn.microsoft.com/en-us/entra/identity-platform',
    ),
    OAuthProvider(
      id: 'facebook',
      displayName: 'Facebook',
      authEndpoint: 'https://www.facebook.com/v18.0/dialog/oauth',
      tokenEndpoint: 'https://graph.facebook.com/v18.0/oauth/access_token',
      defaultScopes: <String>['public_profile', 'email'],
      docsUrl: 'https://developers.facebook.com/docs/facebook-login',
    ),
    OAuthProvider(
      id: 'discord',
      displayName: 'Discord',
      authEndpoint: 'https://discord.com/oauth2/authorize',
      tokenEndpoint: 'https://discord.com/api/oauth2/token',
      defaultScopes: <String>['identify', 'email'],
      docsUrl: 'https://discord.com/developers/docs/topics/oauth2',
    ),
    OAuthProvider(
      id: 'linkedin',
      displayName: 'LinkedIn',
      authEndpoint: 'https://www.linkedin.com/oauth/v2/authorization',
      tokenEndpoint: 'https://www.linkedin.com/oauth/v2/accessToken',
      defaultScopes: <String>['openid', 'profile', 'email'],
      docsUrl: 'https://learn.microsoft.com/en-us/linkedin/shared/authentication',
    ),
    OAuthProvider(
      id: 'slack',
      displayName: 'Slack',
      authEndpoint: 'https://slack.com/oauth/v2/authorize',
      tokenEndpoint: 'https://slack.com/api/oauth.v2.access',
      defaultScopes: <String>['identity.basic'],
      docsUrl: 'https://api.slack.com/authentication/oauth-v2',
    ),
    OAuthProvider(
      id: 'spotify',
      displayName: 'Spotify',
      authEndpoint: 'https://accounts.spotify.com/authorize',
      tokenEndpoint: 'https://accounts.spotify.com/api/token',
      defaultScopes: <String>['user-read-email', 'user-read-private'],
      docsUrl: 'https://developer.spotify.com/documentation/web-api/tutorials/code-flow',
    ),
    OAuthProvider(
      id: 'custom',
      displayName: 'Custom',
      authEndpoint: '',
      tokenEndpoint: '',
    ),
  ];
}

enum OAuthResponseType { code, token, idToken }

extension OAuthResponseTypeX on OAuthResponseType {
  String get value {
    switch (this) {
      case OAuthResponseType.code:
        return 'code';
      case OAuthResponseType.token:
        return 'token';
      case OAuthResponseType.idToken:
        return 'id_token';
    }
  }

  String get display {
    switch (this) {
      case OAuthResponseType.code:
        return 'Authorization Code';
      case OAuthResponseType.token:
        return 'Implicit (access token)';
      case OAuthResponseType.idToken:
        return 'OpenID (id_token)';
    }
  }

  bool get isDeprecated => this == OAuthResponseType.token;
}

enum PkceMethod { none, plain, s256 }

extension PkceMethodX on PkceMethod {
  String get display {
    switch (this) {
      case PkceMethod.none:
        return 'None';
      case PkceMethod.plain:
        return 'Plain';
      case PkceMethod.s256:
        return 'S256';
    }
  }

  String get codeChallengeMethodValue {
    switch (this) {
      case PkceMethod.none:
        return '';
      case PkceMethod.plain:
        return 'plain';
      case PkceMethod.s256:
        return 'S256';
    }
  }
}

class PkcePair {
  const PkcePair({
    required this.verifier,
    required this.challenge,
    required this.method,
  });

  final String verifier;
  final String challenge;
  final PkceMethod method;
}

class OAuthConfig {
  OAuthConfig({
    this.provider = 'google',
    this.customAuthEndpoint = '',
    this.customTokenEndpoint = '',
    this.responseType = OAuthResponseType.code,
    this.clientId = '',
    this.redirectUri = 'https://example.com/callback',
    this.scope = 'openid email profile',
    this.state = '',
    this.pkce = PkceMethod.s256,
    this.prompt = '',
    this.loginHint = '',
    this.accessType = '',
    this.audience = '',
  });

  String provider;
  String customAuthEndpoint;
  String customTokenEndpoint;
  OAuthResponseType responseType;
  String clientId;
  String redirectUri;
  String scope;
  String state;
  PkceMethod pkce;
  String prompt;
  String loginHint;
  String accessType;
  String audience;

  OAuthProvider get providerData {
    return OAuthProvider.presets.firstWhere(
          (OAuthProvider p) => p.id == provider,
      orElse: () => OAuthProvider.presets.last,
    );
  }

  String get authEndpoint {
    if (provider == 'custom') return customAuthEndpoint;
    return providerData.authEndpoint;
  }

  String get tokenEndpoint {
    if (provider == 'custom') return customTokenEndpoint;
    return providerData.tokenEndpoint;
  }

  OAuthConfig clone() => OAuthConfig(
    provider: provider,
    customAuthEndpoint: customAuthEndpoint,
    customTokenEndpoint: customTokenEndpoint,
    responseType: responseType,
    clientId: clientId,
    redirectUri: redirectUri,
    scope: scope,
    state: state,
    pkce: pkce,
    prompt: prompt,
    loginHint: loginHint,
    accessType: accessType,
    audience: audience,
  );
}

// ============================================================================
// ERRORS
// ============================================================================

class CryptoToolkitErrors {
  CryptoToolkitErrors._();

  static const String hmacEmptyMessage = 'ctk_hmac_error_empty_msg';
  static const String hmacEmptyKey = 'ctk_hmac_error_empty_key';
  static const String hmacInvalidKey = 'ctk_hmac_error_invalid_key';

  static const String aesEmptyInput = 'ctk_aes_error_empty';
  static const String aesInvalidKey = 'ctk_aes_error_invalid_key';
  static const String aesInvalidIv = 'ctk_aes_error_invalid_iv';
  static const String aesInvalidBase64 = 'ctk_aes_error_invalid_b64';
  static const String aesDecryptFailed = 'ctk_aes_error_decrypt_failed';
  static const String aesTagMismatch = 'ctk_aes_error_tag';

  static const String sriEmptyInput = 'ctk_sri_error_empty';
  static const String sriFetchFailed = 'ctk_sri_error_fetch';
  static const String sriTimeout = 'ctk_sri_error_timeout';
  static const String sriOffline = 'ctk_sri_error_offline';
  static const String sriBadUrl = 'ctk_sri_error_bad_url';

  static const String oauthMissingEndpoint = 'ctk_oauth_error_endpoint';
  static const String oauthMissingClientId = 'ctk_oauth_error_client_id';
  static const String oauthMissingRedirect = 'ctk_oauth_error_redirect';
}

// ============================================================================
// THEME
// ============================================================================

class CtkColors {
  CtkColors._();

  static const Color accentA = Color(0xFF7C4DFF);
  static const Color accentB = Color(0xFF00E5FF);
  static const Color danger = Color(0xFFFF5C5C);
  static const Color warning = Color(0xFFFFC24B);
  static const Color success = Color(0xFF4BD68B);
  static const Color bgTop = Color(0xFF1B1035);
  static const Color bgMid = Color(0xFF2A1550);
  static const Color bgBot = Color(0xFF0F2A4A);
}