import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'oauth_engine.dart';
import 'ui_kit.dart';

class OAuthTab extends StatefulWidget {
  const OAuthTab({super.key});

  @override
  State<OAuthTab> createState() => _OAuthTabState();
}

class _OAuthTabState extends State<OAuthTab> {
  final OAuthConfig _config = OAuthConfig();

  final TextEditingController _customAuthCtrl = TextEditingController();
  final TextEditingController _customTokenCtrl = TextEditingController();
  final TextEditingController _clientIdCtrl = TextEditingController();
  final TextEditingController _redirectCtrl =
  TextEditingController(text: 'https://example.com/callback');
  final TextEditingController _scopeCtrl =
  TextEditingController(text: 'openid email profile');
  final TextEditingController _stateCtrl = TextEditingController();
  final TextEditingController _promptCtrl = TextEditingController();
  final TextEditingController _loginHintCtrl = TextEditingController();
  final TextEditingController _audienceCtrl = TextEditingController();
  final TextEditingController _codeCtrl = TextEditingController();

  OAuthUrlResult? _urlResult;
  PkcePair? _pkce;
  String? _errorKey;
  String? _errorDetail;

  bool _copiedUrl = false;
  bool _copiedVerifier = false;
  bool _copiedChallenge = false;
  bool _copiedState = false;
  bool _copiedCurl = false;

  bool _showAdvanced = false;
  bool _showCallback = false;

  @override
  void initState() {
    super.initState();
    _clientIdCtrl.addListener(_invalidate);
    _redirectCtrl.addListener(_invalidate);
    _scopeCtrl.addListener(_invalidate);
    _stateCtrl.addListener(_invalidate);
    _customAuthCtrl.addListener(_invalidate);
    _customTokenCtrl.addListener(_invalidate);
    _promptCtrl.addListener(_invalidate);
    _loginHintCtrl.addListener(_invalidate);
    _audienceCtrl.addListener(_invalidate);
    _codeCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _customAuthCtrl.dispose();
    _customTokenCtrl.dispose();
    _clientIdCtrl.dispose();
    _redirectCtrl.dispose();
    _scopeCtrl.dispose();
    _stateCtrl.dispose();
    _promptCtrl.dispose();
    _loginHintCtrl.dispose();
    _audienceCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _invalidate() {
    if (_urlResult != null || _errorKey != null) {
      setState(() {
        _urlResult = null;
        _errorKey = null;
        _errorDetail = null;
      });
    }
  }

  void _syncConfig() {
    _config.customAuthEndpoint = _customAuthCtrl.text;
    _config.customTokenEndpoint = _customTokenCtrl.text;
    _config.clientId = _clientIdCtrl.text;
    _config.redirectUri = _redirectCtrl.text;
    _config.scope = _scopeCtrl.text;
    _config.state = _stateCtrl.text;
    _config.prompt = _promptCtrl.text;
    _config.loginHint = _loginHintCtrl.text;
    _config.audience = _audienceCtrl.text;
  }

  void _selectProvider(String id) {
    if (_config.provider == id) return;
    HapticFeedback.selectionClick();

    final OAuthProvider? p = OAuthEngine.findProvider(id);
    setState(() {
      _config.provider = id;
      _urlResult = null;
      _pkce = null;
      _errorKey = null;
      _errorDetail = null;

      if (p != null && p.defaultScopes.isNotEmpty) {
        _scopeCtrl.text = p.defaultScopes.join(' ');
      }
      if (id == 'google') {
        _promptCtrl.text = '';
        _audienceCtrl.text = '';
      }
      _showAdvanced = false;
    });
  }

  void _setResponseType(OAuthResponseType t) {
    setState(() {
      _config.responseType = t;
      _urlResult = null;
      _pkce = null;
      _errorKey = null;
      _errorDetail = null;
    });
  }

  void _setPkce(PkceMethod m) {
    setState(() {
      _config.pkce = m;
      _urlResult = null;
      _pkce = null;
      _errorKey = null;
      _errorDetail = null;
    });
  }

  void _generate() {
    FocusScope.of(context).unfocus();
    _syncConfig();

    try {
      final OAuthUrlResult r =
      OAuthEngine.buildAuthorizationUrl(_config);
      setState(() {
        _urlResult = r;
        _pkce = r.pkce;
        _errorKey = null;
        _errorDetail = null;
      });
      HapticFeedback.lightImpact();
    } on OAuthException catch (e) {
      setState(() {
        _urlResult = null;
        _pkce = null;
        _errorKey = e.errorKey;
        _errorDetail = e.detail;
      });
    } catch (e) {
      setState(() {
        _urlResult = null;
        _pkce = null;
        _errorKey = CryptoToolkitErrors.oauthMissingEndpoint;
        _errorDetail = e.toString();
      });
    }
  }

  void _regenerateState() {
    HapticFeedback.selectionClick();
    setState(() => _stateCtrl.text = OAuthEngine.generateState());
  }

  void _regeneratePkce() {
    if (_config.pkce == PkceMethod.none) return;
    HapticFeedback.selectionClick();
    try {
      final PkcePair p = OAuthEngine.generatePkce(method: _config.pkce);
      setState(() {
        _pkce = p;
        _urlResult = null;
      });
    } catch (_) {}
  }

  Future<void> _copy(String text, {required String flag}) async {
    if (text.isEmpty) return;
    await ctkCopy(context, text);
    if (!mounted) return;
    setState(() {
      switch (flag) {
        case 'url':
          _copiedUrl = true;
          break;
        case 'verifier':
          _copiedVerifier = true;
          break;
        case 'challenge':
          _copiedChallenge = true;
          break;
        case 'state':
          _copiedState = true;
          break;
        case 'curl':
          _copiedCurl = true;
          break;
      }
    });
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        switch (flag) {
          case 'url':
            _copiedUrl = false;
            break;
          case 'verifier':
            _copiedVerifier = false;
            break;
          case 'challenge':
            _copiedChallenge = false;
            break;
          case 'state':
            _copiedState = false;
            break;
          case 'curl':
            _copiedCurl = false;
            break;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildProviderCard(),
          const SizedBox(height: 14),
          _buildClientCard(),
          const SizedBox(height: 14),
          _buildResponseTypeCard(),
          if (_config.responseType == OAuthResponseType.code) ...<Widget>[
            const SizedBox(height: 14),
            _buildPkceCard(),
          ],
          const SizedBox(height: 14),
          _buildAdvancedCard(),
          if (_errorKey != null) ...<Widget>[
            const SizedBox(height: 14),
            GlassErrorBox(errorKey: _errorKey!, detail: _errorDetail),
          ],
          const SizedBox(height: 14),
          _buildGenerateCard(),
          if (_urlResult != null) ...<Widget>[
            const SizedBox(height: 14),
            _buildUrlOutputCard(_urlResult!),
            if (_pkce != null) ...<Widget>[
              const SizedBox(height: 14),
              _buildPkceOutputCard(_pkce!),
            ],
            const SizedBox(height: 14),
            _buildCurlCard(_urlResult!),
            const SizedBox(height: 14),
            _buildCallbackParserCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildProviderCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GlassSectionTitle(
            Icons.apps_rounded,
            ctkTr(context, 'ctk_oauth_provider', 'Provider'),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: OAuthProvider.presets.map((OAuthProvider p) {
              final bool selected = _config.provider == p.id;
              return GestureDetector(
                onTap: () => _selectProvider(p.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(
                      colors: <Color>[
                        CtkColors.accentA,
                        CtkColors.accentB,
                      ],
                    )
                        : null,
                    color:
                    selected ? null : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : Colors.white.withOpacity(0.15),
                    ),
                  ),
                  child: Text(
                    p.displayName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_config.provider == 'custom') ...<Widget>[
            const SizedBox(height: 14),
            GlassTextField(
              controller: _customAuthCtrl,
              hint: 'https://idp.example.com/oauth2/authorize',
              maxLines: 1,
            ),
            const SizedBox(height: 8),
            GlassTextField(
              controller: _customTokenCtrl,
              hint: 'https://idp.example.com/oauth2/token',
              maxLines: 1,
            ),
          ] else ...<Widget>[
            const SizedBox(height: 10),
            _endpointInfo(
              ctkTr(context, 'ctk_oauth_auth_endpoint', 'Auth'),
              _config.authEndpoint,
            ),
            const SizedBox(height: 4),
            _endpointInfo(
              ctkTr(context, 'ctk_oauth_token_endpoint', 'Token'),
              _config.tokenEndpoint,
            ),
          ],
        ],
      ),
    );
  }

  Widget _endpointInfo(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: CtkColors.accentB.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: CtkColors.accentB,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SelectableText(
            value.isEmpty ? '—' : value,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontFamily: 'monospace',
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClientCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GlassSectionTitle(
            Icons.badge_outlined,
            ctkTr(context, 'ctk_oauth_client', 'Client'),
          ),
          const SizedBox(height: 10),
          _fieldLabel(ctkTr(context, 'ctk_oauth_client_id', 'Client ID')),
          const SizedBox(height: 6),
          GlassTextField(
            controller: _clientIdCtrl,
            hint: 'your-client-id.apps.googleusercontent.com',
            maxLines: 1,
          ),
          const SizedBox(height: 12),
          _fieldLabel(
            ctkTr(context, 'ctk_oauth_redirect_uri', 'Redirect URI'),
          ),
          const SizedBox(height: 6),
          GlassTextField(
            controller: _redirectCtrl,
            hint: 'https://example.com/callback',
            maxLines: 1,
          ),
          const SizedBox(height: 12),
          _fieldLabel(ctkTr(context, 'ctk_oauth_scope', 'Scope')),
          const SizedBox(height: 6),
          GlassTextField(
            controller: _scopeCtrl,
            hint: 'openid email profile',
            maxLines: 2,
            minLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildResponseTypeCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GlassSectionTitle(
            Icons.swap_horiz_rounded,
            ctkTr(context, 'ctk_oauth_response_type', 'Response type'),
          ),
          const SizedBox(height: 10),
          GlassChipPicker<OAuthResponseType>(
            values: OAuthResponseType.values,
            current: _config.responseType,
            labelOf: (OAuthResponseType v) => v.display,
            onChanged: _setResponseType,
          ),
          if (_config.responseType.isDeprecated) ...<Widget>[
            const SizedBox(height: 10),
            GlassInfoBanner(
              icon: Icons.warning_amber_rounded,
              text: ctkTr(
                context,
                'ctk_oauth_implicit_warning',
                'Implicit flow is deprecated. Use Authorization Code with PKCE instead.',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPkceCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: GlassSectionTitle(
                  Icons.enhanced_encryption_outlined,
                  'PKCE',
                ),
              ),
              if (_pkce != null)
                GlassIconButton(
                  icon: Icons.refresh_rounded,
                  tooltip: ctkTr(context, 'ctk_oauth_regen_pkce', 'Regenerate'),
                  onTap: _regeneratePkce,
                ),
            ],
          ),
          const SizedBox(height: 10),
          GlassChipPicker<PkceMethod>(
            values: PkceMethod.values,
            current: _config.pkce,
            labelOf: (PkceMethod v) => v.display,
            onChanged: _setPkce,
          ),
          if (_config.pkce == PkceMethod.s256) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              ctkTr(
                context,
                'ctk_oauth_pkce_s256_hint',
                'SHA-256 challenge (recommended).',
              ),
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
          ],
          if (_config.pkce == PkceMethod.plain) ...<Widget>[
            const SizedBox(height: 10),
            GlassInfoBanner(
              icon: Icons.warning_amber_rounded,
              text: ctkTr(
                context,
                'ctk_oauth_pkce_plain_warning',
                'Plain PKCE sends the verifier as-is. Use S256 if the provider supports it.',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvancedCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GestureDetector(
            onTap: () => setState(() => _showAdvanced = !_showAdvanced),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: GlassSectionTitle(
                    Icons.tune_rounded,
                    ctkTr(context, 'ctk_oauth_advanced', 'Advanced (optional)'),
                  ),
                ),
                Icon(
                  _showAdvanced
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: Colors.white60,
                  size: 20,
                ),
              ],
            ),
          ),
          if (_showAdvanced) ...<Widget>[
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _fieldLabel(
                    ctkTr(context, 'ctk_oauth_state', 'state (CSRF)'),
                  ),
                ),
                GlassIconButton(
                  icon: Icons.casino_outlined,
                  tooltip: ctkTr(context, 'ctk_oauth_regen_state',
                      'Random state'),
                  onTap: _regenerateState,
                ),
              ],
            ),
            const SizedBox(height: 6),
            GlassTextField(
              controller: _stateCtrl,
              hint: ctkTr(context, 'ctk_oauth_state_hint',
                  'auto-generated if empty'),
              maxLines: 1,
            ),
            const SizedBox(height: 12),
            _fieldLabel('prompt'),
            const SizedBox(height: 6),
            GlassTextField(
              controller: _promptCtrl,
              hint: 'consent select_account login none',
              maxLines: 1,
            ),
            const SizedBox(height: 12),
            _fieldLabel('login_hint'),
            const SizedBox(height: 6),
            GlassTextField(
              controller: _loginHintCtrl,
              hint: 'user@example.com',
              maxLines: 1,
            ),
            const SizedBox(height: 12),
            _fieldLabel('audience'),
            const SizedBox(height: 6),
            GlassTextField(
              controller: _audienceCtrl,
              hint: 'https://api.example.com',
              maxLines: 1,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGenerateCard() {
    return GlassPrimaryButton(
      icon: Icons.build_rounded,
      label: ctkTr(context, 'ctk_oauth_generate', 'Generate URL'),
      onTap: _generate,
    );
  }

  Widget _buildUrlOutputCard(OAuthUrlResult r) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: GlassSectionTitle(
                  Icons.link_rounded,
                  ctkTr(context, 'ctk_oauth_auth_url', 'Authorization URL'),
                ),
              ),
              GlassIconButton(
                icon: Icons.open_in_new_rounded,
                tooltip: ctkTr(context, 'ctk_oauth_open', 'Open'),
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 10),
          GlassOutputBlock(
            label: 'URL',
            value: r.url,
            copied: _copiedUrl,
            onCopy: () => _copy(r.url, flag: 'url'),
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Text(
            ctkTr(context, 'ctk_oauth_params', 'Parameters'),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ..._paramRows(r.params),
        ],
      ),
    );
  }

  List<Widget> _paramRows(Map<String, String> params) {
    final List<Widget> out = <Widget>[];
    params.forEach((String k, String v) {
      out.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 120,
                child: Text(
                  k,
                  style: const TextStyle(
                    color: CtkColors.accentB,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: SelectableText(
                  v,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
    return out;
  }

  Widget _buildPkceOutputCard(PkcePair pair) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GlassSectionTitle(
            Icons.vpn_key_rounded,
            ctkTr(context, 'ctk_oauth_pkce_pair', 'PKCE pair'),
          ),
          const SizedBox(height: 12),
          GlassOutputBlock(
            label: 'CODE_VERIFIER',
            value: pair.verifier,
            copied: _copiedVerifier,
            onCopy: () => _copy(pair.verifier, flag: 'verifier'),
          ),
          const SizedBox(height: 12),
          GlassOutputBlock(
            label: 'CODE_CHALLENGE (${pair.method.display})',
            value: pair.challenge,
            copied: _copiedChallenge,
            onCopy: () => _copy(pair.challenge, flag: 'challenge'),
          ),
          const SizedBox(height: 10),
          GlassInfoBanner(
            icon: Icons.info_outline,
            color: CtkColors.accentB,
            text: ctkTr(
              context,
              'ctk_oauth_verifier_keep',
              'Keep the code_verifier secret until the token exchange. Send only the challenge in the auth URL.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurlCard(OAuthUrlResult r) {
    final String code = _codeCtrl.text.trim();
    final bool canBuildCurl = code.isNotEmpty && _pkce != null;

    String curl = '';
    if (canBuildCurl) {
      try {
        curl = OAuthEngine.buildTokenExchangeCurl(
          config: _config,
          code: code,
          pkce: _pkce,
        );
      } catch (_) {
        curl = '';
      }
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GlassSectionTitle(
            Icons.terminal_rounded,
            ctkTr(context, 'ctk_oauth_curl', 'Token exchange cURL'),
          ),
          const SizedBox(height: 10),
          _fieldLabel(ctkTr(context, 'ctk_oauth_code', 'Authorization code')),
          const SizedBox(height: 6),
          GlassTextField(
            controller: _codeCtrl,
            hint: 'paste the code from callback',
            maxLines: 2,
            minLines: 1,
          ),
          if (canBuildCurl) ...<Widget>[
            const SizedBox(height: 12),
            GlassOutputBlock(
              label: 'CURL',
              value: curl,
              copied: _copiedCurl,
              onCopy: () => _copy(curl, flag: 'curl'),
            ),
          ] else ...<Widget>[
            const SizedBox(height: 10),
            Text(
              ctkTr(
                context,
                'ctk_oauth_curl_hint',
                'Paste the authorization code to build the token exchange command.',
              ),
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCallbackParserCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GestureDetector(
            onTap: () => setState(() => _showCallback = !_showCallback),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: GlassSectionTitle(
                    Icons.rule_rounded,
                    ctkTr(context, 'ctk_oauth_callback_parser',
                        'Parse callback URL'),
                  ),
                ),
                Icon(
                  _showCallback
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: Colors.white60,
                  size: 20,
                ),
              ],
            ),
          ),
          if (_showCallback) ...<Widget>[
            const SizedBox(height: 12),
            _callbackParserBody(),
          ],
        ],
      ),
    );
  }

  Widget _callbackParserBody() {
    final TextEditingController ctrl = TextEditingController();
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setLocal) {
        final String raw = ctrl.text.trim();
        Map<String, String>? parsed;
        String? parseError;

        if (raw.isNotEmpty) {
          try {
            parsed = OAuthEngine.parseCallbackUrl(raw);
          } catch (e) {
            parseError = e.toString();
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _fieldLabel('Callback URL'),
            const SizedBox(height: 6),
            GlassTextField(
              controller: ctrl,
              hint: 'https://example.com/callback?code=...&state=...',
              maxLines: 2,
              minLines: 1,
              onChanged: (_) => setLocal(() {}),
            ),
            if (parseError != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                parseError,
                style: const TextStyle(
                  color: CtkColors.danger,
                  fontSize: 11,
                ),
              ),
            ],
            if (parsed != null && parsed.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              ..._paramRows(parsed),
              const SizedBox(height: 8),
              if (parsed.containsKey('code'))
                GlassPrimaryButton(
                  icon: Icons.arrow_downward_rounded,
                  label: ctkTr(context, 'ctk_oauth_use_code',
                      'Use this code above'),
                  onTap: () {
                    _codeCtrl.text = parsed!['code']!;
                    HapticFeedback.selectionClick();
                    setLocal(() {});
                    setState(() {});
                  },
                ),
            ],
          ],
        );
      },
    );
  }
}