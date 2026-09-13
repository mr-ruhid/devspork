import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/app_localization.dart';
import 'crypto_handler.dart';
import 'models.dart';

const Color _accentA = Color(0xFF7C4DFF);
const Color _accentB = Color(0xFF00E5FF);
const Color _danger = Color(0xFFFF5C5C);
const Color _warning = Color(0xFFFFC24B);
const Color _success = Color(0xFF4BD68B);
const Color _bgTop = Color(0xFF1B1035);
const Color _bgMid = Color(0xFF2A1550);
const Color _bgBot = Color(0xFF0F2A4A);

class JwtGen extends StatefulWidget {
  const JwtGen({super.key});

  @override
  State<JwtGen> createState() => _JwtGenState();
}

class _JwtGenState extends State<JwtGen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  JwtAlgorithm _algorithm = JwtAlgorithm.hs256;
  final TextEditingController _secretCtrl = TextEditingController();
  final TextEditingController _headerExtraCtrl = TextEditingController();
  final TextEditingController _payloadCtrl = TextEditingController();
  final TextEditingController _kidCtrl = TextEditingController();
  final TextEditingController _decodeCtrl = TextEditingController();
  final TextEditingController _verifySecretCtrl = TextEditingController();

  bool _showSecret = false;
  String? _generatedToken;
  String? _genErrorKey;
  String? _genErrorDetail;

  JwtDecoded? _decoded;
  String? _decodeErrorKey;
  String? _decodeErrorDetail;

  bool? _verifyResult;
  bool _verifyChecked = false;

  final Map<String, TextEditingController> _claimCtrls =
  <String, TextEditingController>{};

  static const List<String> _quickClaims = <String>[
    'iss',
    'sub',
    'aud',
    'jti',
  ];
  static const List<String> _timeClaims = <String>[
    'exp',
    'nbf',
    'iat',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    for (final String k in <String>[..._quickClaims, ..._timeClaims]) {
      _claimCtrls[k] = TextEditingController();
    }
    _payloadCtrl.text = '{\n  "name": "John Doe"\n}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _secretCtrl.dispose();
    _headerExtraCtrl.dispose();
    _payloadCtrl.dispose();
    _kidCtrl.dispose();
    _decodeCtrl.dispose();
    _verifySecretCtrl.dispose();
    for (final TextEditingController c in _claimCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _copy(String text) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    _showSnack(context.t('jwtgen_copied'));
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withOpacity(0.75),
        content: Text(message),
      ),
    );
  }

  void _generateRandomSecret() {
    final String s = JwtSampleSecrets.randomSecret(length: 32);
    setState(() {
      _secretCtrl.text = s;
      _showSecret = true;
    });
  }

  Map<String, dynamic> _buildPayload() {
    final String raw = _payloadCtrl.text.trim();
    Map<String, dynamic> base = <String, dynamic>{};
    if (raw.isNotEmpty) {
      final dynamic parsed = jsonDecode(raw);
      if (parsed is! Map<String, dynamic>) {
        throw const FormatException('Payload must be a JSON object');
      }
      base = parsed;
    }

    for (final String k in _quickClaims) {
      final String v = _claimCtrls[k]!.text.trim();
      if (v.isNotEmpty) base[k] = v;
    }

    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    for (final String k in _timeClaims) {
      final String v = _claimCtrls[k]!.text.trim();
      if (v.isEmpty) continue;
      final int? seconds = int.tryParse(v);
      if (seconds != null) {
        base[k] = seconds;
      } else {
        final DateTime? dt = DateTime.tryParse(v);
        if (dt != null) base[k] = dt.millisecondsSinceEpoch ~/ 1000;
      }
    }

    if (base['iat'] == null && _claimCtrls['iat']!.text.trim().isEmpty) {
      base['iat'] = now;
    }

    return base;
  }

  Future<void> _generate() async {
    FocusScope.of(context).unfocus();

    if (_algorithm.requiresSecret && _secretCtrl.text.isEmpty) {
      setState(() {
        _genErrorKey = 'jwtgen_error_secret_required';
        _genErrorDetail = null;
        _generatedToken = null;
      });
      return;
    }

    Map<String, dynamic> payload;
    try {
      payload = _buildPayload();
    } catch (e) {
      setState(() {
        _genErrorKey = 'jwtgen_error_payload_invalid';
        _genErrorDetail = e.toString();
        _generatedToken = null;
      });
      return;
    }

    Map<String, dynamic> extraHeader = <String, dynamic>{};
    final String rawExtra = _headerExtraCtrl.text.trim();
    if (rawExtra.isNotEmpty) {
      try {
        final dynamic parsed = jsonDecode(rawExtra);
        if (parsed is Map<String, dynamic>) {
          extraHeader = parsed;
        } else {
          throw const FormatException('Header must be a JSON object');
        }
      } catch (e) {
        setState(() {
          _genErrorKey = 'jwtgen_error_header_invalid';
          _genErrorDetail = e.toString();
          _generatedToken = null;
        });
        return;
      }
    }

    final JwtHeader header = JwtHeader(
      alg: _algorithm.id,
      typ: 'JWT',
      kid: _kidCtrl.text.trim().isEmpty ? null : _kidCtrl.text.trim(),
      extra: extraHeader,
    );

    try {
      final String token = JwtCrypto.generateToken(
        header: header,
        payload: payload,
        secret: _secretCtrl.text,
        algorithm: _algorithm,
      );

      setState(() {
        _generatedToken = token;
        _genErrorKey = null;
        _genErrorDetail = null;
      });
    } catch (e) {
      setState(() {
        _genErrorKey = 'jwtgen_error_unknown';
        _genErrorDetail = e.toString();
        _generatedToken = null;
      });
    }
  }

  Future<void> _decode() async {
    FocusScope.of(context).unfocus();
    final String input = _decodeCtrl.text.trim();
    if (input.isEmpty) {
      setState(() {
        _decodeErrorKey = 'jwtgen_error_empty_token';
        _decodeErrorDetail = null;
        _decoded = null;
        _verifyChecked = false;
        _verifyResult = null;
      });
      return;
    }

    try {
      final JwtDecoded d = JwtCrypto.decodeToken(input);
      setState(() {
        _decoded = d;
        _decodeErrorKey = null;
        _decodeErrorDetail = null;
        _verifyChecked = false;
        _verifyResult = null;
      });
    } catch (e) {
      setState(() {
        _decodeErrorKey = 'jwtgen_error_decode';
        _decodeErrorDetail = e.toString();
        _decoded = null;
        _verifyChecked = false;
        _verifyResult = null;
      });
    }
  }

  Future<void> _verify() async {
    final JwtDecoded? d = _decoded;
    if (d == null) return;

    FocusScope.of(context).unfocus();

    final JwtAlgorithm alg = JwtAlgorithmX.fromId(d.header.alg);
    if (alg.requiresSecret && _verifySecretCtrl.text.isEmpty) {
      setState(() {
        _verifyChecked = true;
        _verifyResult = false;
        _decodeErrorKey = 'jwtgen_error_secret_required';
        _decodeErrorDetail = null;
      });
      return;
    }

    final bool ok = JwtCrypto.verifyToken(
      d,
      _verifySecretCtrl.text,
      alg,
    );

    setState(() {
      _verifyChecked = true;
      _verifyResult = ok;
      if (ok) {
        _decodeErrorKey = null;
        _decodeErrorDetail = null;
      }
    });
  }

  void _loadDecodedToEditor() {
    final JwtDecoded? d = _decoded;
    if (d == null) return;

    setState(() {
      _algorithm = JwtAlgorithmX.fromId(d.header.alg);
      _kidCtrl.text = d.header.kid ?? '';
      _headerExtraCtrl.text = d.header.extra.isEmpty
          ? ''
          : const JsonEncoder.withIndent('  ').convert(d.header.extra);

      final Map<String, dynamic> payload =
      Map<String, dynamic>.from(d.payload);

      for (final String k in _quickClaims) {
        if (payload.containsKey(k)) {
          _claimCtrls[k]!.text = payload[k]?.toString() ?? '';
          payload.remove(k);
        } else {
          _claimCtrls[k]!.text = '';
        }
      }

      for (final String k in _timeClaims) {
        if (payload.containsKey(k)) {
          final dynamic v = payload[k];
          _claimCtrls[k]!.text = v?.toString() ?? '';
          payload.remove(k);
        } else {
          _claimCtrls[k]!.text = '';
        }
      }

      _payloadCtrl.text = payload.isEmpty
          ? '{}'
          : const JsonEncoder.withIndent('  ').convert(payload);

      if (d.header.alg.toUpperCase() != 'NONE') {
        _verifySecretCtrl.text = _secretCtrl.text;
      }

      _tabController.animateTo(0);
    });
  }

  void _clearGenerator() {
    setState(() {
      _secretCtrl.clear();
      _headerExtraCtrl.clear();
      _kidCtrl.clear();
      _payloadCtrl.text = '{\n  "name": "John Doe"\n}';
      for (final TextEditingController c in _claimCtrls.values) {
        c.clear();
      }
      _generatedToken = null;
      _genErrorKey = null;
      _genErrorDetail = null;
    });
  }

  void _clearDecoder() {
    setState(() {
      _decodeCtrl.clear();
      _verifySecretCtrl.clear();
      _decoded = null;
      _decodeErrorKey = null;
      _decodeErrorDetail = null;
      _verifyChecked = false;
      _verifyResult = null;
    });
  }

  String _prettyJson(Map<String, dynamic> data) {
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.t('jwtgen_title')),
        actions: <Widget>[
          _glassIconButton(
            icon: Icons.autorenew_rounded,
            tooltip: context.t('jwtgen_clear'),
            onTap: () {
              if (_tabController.index == 0) {
                _clearGenerator();
              } else {
                _clearDecoder();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: _glassTabBar(),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[_bgTop, _bgMid, _bgBot],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(top: -80, left: -60, child: _blurBlob(220, _accentA)),
            Positioned(
              bottom: -100,
              right: -60,
              child: _blurBlob(260, _accentB),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 60),
                child: TabBarView(
                  controller: _tabController,
                  children: <Widget>[
                    _buildGeneratorTab(),
                    _buildDecoderTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _glassTabBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(52),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: _GlassCard(
          padding: const EdgeInsets.all(4),
          radius: 16,
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: <Color>[_accentA, _accentB],
              ),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            tabs: <Widget>[
              Tab(text: context.t('jwtgen_tab_generate')),
              Tab(text: context.t('jwtgen_tab_decode')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneratorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.t('jwtgen_algorithm'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _algorithmSelector(),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _glassTextField(
                        controller: _secretCtrl,
                        hint: context.t('jwtgen_secret_hint'),
                        obscure: !_showSecret,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () =>
                          setState(() => _showSecret = !_showSecret),
                      icon: Icon(
                        _showSecret
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.white60,
                        size: 20,
                      ),
                    ),
                    IconButton(
                      onPressed: _generateRandomSecret,
                      icon: const Icon(
                        Icons.casino_outlined,
                        color: _accentB,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.tune_rounded,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.t('jwtgen_header'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _glassTextField(
                  controller: _kidCtrl,
                  hint: context.t('jwtgen_kid_hint'),
                ),
                const SizedBox(height: 10),
                _glassTextField(
                  controller: _headerExtraCtrl,
                  hint: '{\n  "cty": "JWT"\n}',
                  maxLines: 4,
                  minLines: 2,
                  monospace: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.badge_outlined,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.t('jwtgen_registered_claims'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final String k in _quickClaims) ...<Widget>[
                  _claimField(k),
                  const SizedBox(height: 8),
                ],
                for (final String k in _timeClaims) ...<Widget>[
                  _claimField(k, timeHint: true),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.data_object_rounded,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.t('jwtgen_payload'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _glassTextField(
                  controller: _payloadCtrl,
                  hint: '{\n  "name": "John"\n}',
                  maxLines: 10,
                  minLines: 5,
                  monospace: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _primaryButton(
            icon: Icons.vpn_key_rounded,
            labelKey: 'jwtgen_generate',
            onTap: _generate,
          ),
          if (_genErrorKey != null) ...<Widget>[
            const SizedBox(height: 14),
            _errorBox(_genErrorKey!, _genErrorDetail),
          ],
          if (_generatedToken != null) ...<Widget>[
            const SizedBox(height: 16),
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                        color: _success,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.t('jwtgen_result'),
                        style: const TextStyle(
                          color: _success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      _glassIconButton(
                        icon: Icons.copy_rounded,
                        tooltip: context.t('jwtgen_copy'),
                        onTap: () => _copy(_generatedToken!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _tokenView(_generatedToken!),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _claimField(String key, {bool timeHint = false}) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 60,
          child: Text(
            key,
            style: const TextStyle(
              color: _accentB,
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _glassTextField(
            controller: _claimCtrls[key]!,
            hint: timeHint
                ? context.t('jwtgen_claim_time_hint')
                : context.t('jwtgen_claim_hint'),
            dense: true,
          ),
        ),
      ],
    );
  }

  Widget _algorithmSelector() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: JwtAlgorithm.values.map((JwtAlgorithm a) {
        final bool selected = _algorithm == a;
        return GestureDetector(
          onTap: () => setState(() => _algorithm = a),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(
                colors: <Color>[_accentA, _accentB],
              )
                  : null,
              color: selected ? null : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : Colors.white.withOpacity(0.15),
              ),
            ),
            child: Text(
              a.displayName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDecoderTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.key_rounded,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.t('jwtgen_token_input'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _glassTextField(
                  controller: _decodeCtrl,
                  hint: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
                  maxLines: 6,
                  minLines: 3,
                  monospace: true,
                ),
                const SizedBox(height: 12),
                _primaryButton(
                  icon: Icons.search_rounded,
                  labelKey: 'jwtgen_decode',
                  onTap: _decode,
                ),
              ],
            ),
          ),
          if (_decodeErrorKey != null) ...<Widget>[
            const SizedBox(height: 14),
            _errorBox(_decodeErrorKey!, _decodeErrorDetail),
          ],
          if (_decoded != null) ...<Widget>[
            const SizedBox(height: 16),
            _decodedHeaderCard(_decoded!),
            const SizedBox(height: 16),
            _decodedPayloadCard(_decoded!),
            if (_decoded!.hasSignature) ...<Widget>[
              const SizedBox(height: 16),
              _decodedSignatureCard(_decoded!),
              const SizedBox(height: 16),
              _verifyCard(_decoded!),
            ],
            const SizedBox(height: 16),
            _primaryButton(
              icon: Icons.edit_rounded,
              labelKey: 'jwtgen_load_to_editor',
              onTap: _loadDecodedToEditor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _decodedHeaderCard(JwtDecoded d) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _accentA.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _accentA.withOpacity(0.5)),
                ),
                child: Text(
                  context.t('jwtgen_part_header'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              _glassIconButton(
                icon: Icons.copy_rounded,
                tooltip: context.t('jwtgen_copy'),
                onTap: () => _copy(_prettyJson(d.header.toMap())),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _codeBlock(_prettyJson(d.header.toMap())),
        ],
      ),
    );
  }

  Widget _decodedPayloadCard(JwtDecoded d) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _accentB.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _accentB.withOpacity(0.5)),
                ),
                child: Text(
                  context.t('jwtgen_part_payload'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              _glassIconButton(
                icon: Icons.copy_rounded,
                tooltip: context.t('jwtgen_copy'),
                onTap: () => _copy(_prettyJson(d.payload)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _codeBlock(_prettyJson(d.payload)),
          if (d.payload.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            _claimsExplanation(d.payload),
          ],
        ],
      ),
    );
  }

  Widget _claimsExplanation(Map<String, dynamic> payload) {
    final List<String> keys = payload.keys
        .where(ClaimExplanation.isRegistered)
        .toList();

    if (keys.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Divider(color: Colors.white24, height: 20),
        for (final String k in keys) ...<Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: 50,
                  child: Text(
                    k,
                    style: const TextStyle(
                      color: _accentB,
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        context.t(ClaimExplanation.descriptionKeyFor(k)!),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatValue(k, payload[k]),
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _formatValue(String key, dynamic value) {
    if (ClaimExplanation.isTimeClaim(key)) {
      final String formatted = JwtCrypto.formatClaimTime(value);
      return '$value  ($formatted)';
    }
    if (value is String) return '"$value"';
    if (value is Map || value is List) {
      return const JsonEncoder().convert(value);
    }
    return '$value';
  }

  Widget _decodedSignatureCard(JwtDecoded d) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _warning.withOpacity(0.5)),
                ),
                child: Text(
                  context.t('jwtgen_part_signature'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              _glassIconButton(
                icon: Icons.copy_rounded,
                tooltip: context.t('jwtgen_copy'),
                onTap: () => _copy(d.rawSignature),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _codeBlock(d.rawSignature),
        ],
      ),
    );
  }

  Widget _verifyCard(JwtDecoded d) {
    final JwtAlgorithm alg = JwtAlgorithmX.fromId(d.header.alg);
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.verified_user_outlined,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 8),
              Text(
                context.t('jwtgen_verify'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _glassTextField(
                  controller: _verifySecretCtrl,
                  hint: context.t('jwtgen_secret_hint'),
                  obscure: !_showSecret,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => setState(() => _showSecret = !_showSecret),
                icon: Icon(
                  _showSecret
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.white60,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _primaryButton(
            icon: Icons.security_rounded,
            labelKey: 'jwtgen_verify_action',
            onTap: _verify,
          ),
          if (_verifyChecked && _verifyResult != null) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (_verifyResult!
                    ? _success
                    : _danger)
                    .withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (_verifyResult!
                      ? _success
                      : _danger)
                      .withOpacity(0.5),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    _verifyResult!
                        ? Icons.verified_rounded
                        : Icons.gpp_bad_rounded,
                    color: _verifyResult! ? _success : _danger,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.t(
                        _verifyResult!
                            ? 'jwtgen_verify_ok'
                            : 'jwtgen_verify_fail',
                      ),
                      style: TextStyle(
                        color: _verifyResult! ? _success : _danger,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (alg == JwtAlgorithm.none) ...<Widget>[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _danger.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _danger.withOpacity(0.5)),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: _danger,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.t('jwtgen_warning_none_alg'),
                      style: const TextStyle(
                        color: Color(0xFFFFBFBF),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tokenView(String token) {
    final List<String> parts = token.split('.');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: SelectableText.rich(
            TextSpan(
              children: <InlineSpan>[
                if (parts.isNotEmpty)
                  TextSpan(
                    text: parts[0],
                    style: const TextStyle(color: _accentA),
                  ),
                if (parts.length > 1)
                  TextSpan(
                    text: '.${parts[1]}',
                    style: const TextStyle(color: _accentB),
                  ),
                if (parts.length > 2)
                  TextSpan(
                    text: '.${parts[2]}',
                    style: const TextStyle(color: _warning),
                  ),
                if (parts.length > 2 && parts[2].isEmpty)
                  const TextSpan(
                    text: '.',
                    style: TextStyle(color: _warning),
                  ),
              ],
            ),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _codeBlock(String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: SelectableText(
        code,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          height: 1.5,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _errorBox(String errorKey, String? detail) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _danger.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _danger.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.error_outline, size: 16, color: _danger),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.t(errorKey),
                  style: const TextStyle(
                    color: Color(0xFFFF8A8A),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          if (detail != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              detail,
              style: const TextStyle(
                color: Color(0xFFFFBFBF),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _primaryButton({
    required IconData icon,
    required String labelKey,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[_accentA, _accentB],
              ),
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text(
                  context.t(labelKey),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassTextField({
    required TextEditingController controller,
    required String hint,
    int? maxLines = 1,
    int? minLines,
    bool monospace = false,
    bool dense = false,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      maxLines: obscure ? 1 : maxLines,
      minLines: minLines,
      obscureText: obscure,
      style: TextStyle(
        color: Colors.white,
        fontSize: dense ? 12 : 13,
        fontFamily: monospace ? 'monospace' : null,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.35),
          fontSize: dense ? 12 : 12,
        ),
        isDense: true,
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: dense ? 8 : 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _accentB, width: 1.4),
        ),
      ),
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.white.withOpacity(0.08),
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(icon, size: 18, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _blurBlob(double size, Color color) {
    return IgnorePointer(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.35),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}