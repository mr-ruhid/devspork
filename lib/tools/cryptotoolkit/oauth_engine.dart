import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'models.dart';

class OAuthException implements Exception {
  OAuthException(this.errorKey, [this.detail]);

  final String errorKey;
  final String? detail;

  @override
  String toString() => detail == null ? errorKey : '$errorKey: $detail';
}

class OAuthUrlResult {
  const OAuthUrlResult({
    required this.url,
    required this.params,
    this.pkce,
    required this.state,
  });

  final String url;
  final Map<String, String> params;
  final PkcePair? pkce;
  final String state;
}

class OAuthEngine {
  OAuthEngine._();

  static final Random _rng = Random.secure();

  static String generateState({int bytes = 16}) {
    return _randomBase64Url(bytes);
  }

  static PkcePair generatePkce({PkceMethod method = PkceMethod.s256}) {
    if (method == PkceMethod.none) {
      throw OAuthException(
        CryptoToolkitErrors.oauthMissingEndpoint,
        'PKCE disabled',
      );
    }

    final String verifier = _randomBase64Url(32);

    String challenge;
    if (method == PkceMethod.plain) {
      challenge = verifier;
    } else {
      final List<int> hash = sha256.convert(utf8.encode(verifier)).bytes;
      challenge = _base64UrlEncode(hash);
    }

    return PkcePair(
      verifier: verifier,
      challenge: challenge,
      method: method,
    );
  }

  static String _randomBase64Url(int byteCount) {
    final List<int> bytes =
    List<int>.generate(byteCount, (_) => _rng.nextInt(256));
    return _base64UrlEncode(bytes);
  }

  static String _base64UrlEncode(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static OAuthUrlResult buildAuthorizationUrl(OAuthConfig config) {
    final String endpoint = config.authEndpoint.trim();
    if (endpoint.isEmpty) {
      throw OAuthException(CryptoToolkitErrors.oauthMissingEndpoint);
    }
    if (config.clientId.trim().isEmpty) {
      throw OAuthException(CryptoToolkitErrors.oauthMissingClientId);
    }
    if (config.redirectUri.trim().isEmpty) {
      throw OAuthException(CryptoToolkitErrors.oauthMissingRedirect);
    }

    final Map<String, String> params = <String, String>{};
    params['response_type'] = config.responseType.value;
    params['client_id'] = config.clientId.trim();
    params['redirect_uri'] = config.redirectUri.trim();

    if (config.scope.trim().isNotEmpty) {
      params['scope'] = config.scope.trim();
    }

    String state = config.state.trim();
    if (state.isEmpty) {
      state = generateState();
    }
    params['state'] = state;

    PkcePair? pkce;
    if (config.pkce != PkceMethod.none &&
        config.responseType == OAuthResponseType.code) {
      pkce = generatePkce(method: config.pkce);
      params['code_challenge'] = pkce.challenge;
      params['code_challenge_method'] =
          config.pkce.codeChallengeMethodValue;
    }

    if (config.prompt.trim().isNotEmpty) {
      params['prompt'] = config.prompt.trim();
    }
    if (config.loginHint.trim().isNotEmpty) {
      params['login_hint'] = config.loginHint.trim();
    }
    if (config.accessType.trim().isNotEmpty) {
      params['access_type'] = config.accessType.trim();
    }
    if (config.audience.trim().isNotEmpty) {
      params['audience'] = config.audience.trim();
    }

    final String query = params.entries
        .map((MapEntry<String, String> e) =>
    '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    final String url = '$endpoint?$query';

    return OAuthUrlResult(
      url: url,
      params: params,
      pkce: pkce,
      state: state,
    );
  }

  static String buildTokenExchangeCurl({
    required OAuthConfig config,
    required String code,
    PkcePair? pkce,
    bool isPublicClient = false,
  }) {
    final String endpoint = config.tokenEndpoint.trim();
    if (endpoint.isEmpty) {
      throw OAuthException(CryptoToolkitErrors.oauthMissingEndpoint);
    }

    final Map<String, String> body = <String, String>{
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': config.redirectUri.trim(),
      'client_id': config.clientId.trim(),
    };

    if (pkce != null) {
      body['code_verifier'] = pkce.verifier;
    }

    final String bodyStr = body.entries
        .map((MapEntry<String, String> e) =>
    '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    final StringBuffer b = StringBuffer();
    b.writeln('curl -X POST "$endpoint" \\');
    b.writeln('  -H "Content-Type: application/x-www-form-urlencoded" \\');
    b.writeln('  -H "Accept: application/json" \\');
    if (!isPublicClient) {
      b.writeln('  -u "CLIENT_ID:CLIENT_SECRET" \\');
    }
    b.write('  -d "$bodyStr"');
    return b.toString();
  }

  static String buildTokenExchangeCurlJson({
    required OAuthConfig config,
    required String code,
    PkcePair? pkce,
  }) {
    final String endpoint = config.tokenEndpoint.trim();
    if (endpoint.isEmpty) {
      throw OAuthException(CryptoToolkitErrors.oauthMissingEndpoint);
    }

    final Map<String, dynamic> body = <String, dynamic>{
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': config.redirectUri.trim(),
      'client_id': config.clientId.trim(),
    };

    if (pkce != null) {
      body['code_verifier'] = pkce.verifier;
    }

    final String jsonBody = const JsonEncoder.withIndent('  ').convert(body);

    final StringBuffer b = StringBuffer();
    b.writeln('curl -X POST "$endpoint" \\');
    b.writeln('  -H "Content-Type: application/json" \\');
    b.writeln('  -H "Accept: application/json" \\');
    b.write("  -d '$jsonBody'");
    return b.toString();
  }

  static String buildAuthRequestBodyJson(OAuthConfig config) {
    return const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'client_id': config.clientId,
      'redirect_uri': config.redirectUri,
      'response_type': config.responseType.value,
      'scope': config.scope,
      if (config.state.isNotEmpty) 'state': config.state,
      if (config.loginHint.isNotEmpty) 'login_hint': config.loginHint,
      if (config.audience.isNotEmpty) 'audience': config.audience,
    });
  }

  static List<OAuthProvider> searchProviders(String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return OAuthProvider.presets;
    return OAuthProvider.presets
        .where((OAuthProvider p) =>
    p.displayName.toLowerCase().contains(q) ||
        p.id.toLowerCase().contains(q))
        .toList();
  }

  static OAuthProvider? findProvider(String id) {
    for (final OAuthProvider p in OAuthProvider.presets) {
      if (p.id == id) return p;
    }
    return null;
  }

  static Map<String, String> parseCallbackUrl(String callbackUrl) {
    final Uri? uri = Uri.tryParse(callbackUrl.trim());
    if (uri == null) {
      throw OAuthException(
        CryptoToolkitErrors.oauthMissingEndpoint,
        'Invalid callback URL',
      );
    }
    final Map<String, String> out = <String, String>{};
    uri.queryParameters.forEach((String k, String v) {
      out[k] = v;
    });
    if (uri.fragment.isNotEmpty) {
      final Map<String, String> frag = Uri.splitQueryString(uri.fragment);
      frag.forEach((String k, String v) {
        out[k] = v;
      });
    }
    return out;
  }

  static String maskSecret(String secret) {
    if (secret.isEmpty) return '';
    if (secret.length <= 8) return '•' * secret.length;
    return '${secret.substring(0, 4)}${'•' * (secret.length - 8)}${secret.substring(secret.length - 4)}';
  }
}