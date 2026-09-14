import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/app_localization.dart';
import 'models.dart';
import 'totp.dart';

const Color _accentA = Color(0xFF7C4DFF);
const Color _accentB = Color(0xFF00E5FF);
const Color _danger = Color(0xFFFF5C5C);
const Color _warning = Color(0xFFFFC24B);
const Color _success = Color(0xFF4BD68B);
const Color _bgTop = Color(0xFF1B1035);
const Color _bgMid = Color(0xFF2A1550);
const Color _bgBot = Color(0xFF0F2A4A);

class TotpGen extends StatefulWidget {
  const TotpGen({super.key});

  @override
  State<TotpGen> createState() => _TotpGenState();
}

class _TotpGenState extends State<TotpGen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final TextEditingController _secretCtrl = TextEditingController();
  final TextEditingController _verifyCodeCtrl = TextEditingController();
  final TextEditingController _issuerCtrl = TextEditingController();
  final TextEditingController _accountCtrl = TextEditingController();
  final TextEditingController _uriInputCtrl = TextEditingController();

  final TotpConfig _config = TotpConfig();

  TotpCode? _current;
  Timer? _timer;
  bool _showSecret = false;

  bool? _verifyResult;
  bool _verifyChecked = false;
  String? _verifyMessageKey;

  String? _uriOutput;
  String? _uriErrorKey;
  String? _uriErrorDetail;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _secretCtrl.text = Base32.generateSecret();
    _config.secret = _secretCtrl.text;
    _refresh();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    _secretCtrl.dispose();
    _verifyCodeCtrl.dispose();
    _issuerCtrl.dispose();
    _accountCtrl.dispose();
    _uriInputCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _refresh();
    });
  }

  void _refresh() {
    if (!mounted) return;
    final TotpCode code = TotpGenerator.generate(config: _config);
    setState(() => _current = code);
  }

  void _onSecretChanged(String value) {
    setState(() {
      _config.secret = value;
    });
    _refresh();
  }

  void _generateNewSecret() {
    setState(() {
      _secretCtrl.text = Base32.generateSecret();
      _config.secret = _secretCtrl.text;
      _showSecret = true;
    });
    _refresh();
  }

  Future<void> _copy(String text) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    _showSnack(context.t('totpgen_copied'));
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

  void _verify() {
    FocusScope.of(context).unfocus();
    final String code = _verifyCodeCtrl.text.trim();

    if (code.isEmpty) {
      setState(() {
        _verifyResult = false;
        _verifyChecked = true;
        _verifyMessageKey = 'totpgen_verify_empty';
      });
      return;
    }

    final Base32Result decoded = Base32.decode(_config.secret);
    if (!decoded.isOk) {
      setState(() {
        _verifyResult = false;
        _verifyChecked = true;
        _verifyMessageKey = decoded.errorKey;
      });
      return;
    }

    final bool ok = TotpGenerator.verify(
      config: _config,
      code: code,
      window: 1,
    );

    setState(() {
      _verifyResult = ok;
      _verifyChecked = true;
      _verifyMessageKey = ok ? 'totpgen_verify_ok' : 'totpgen_verify_fail';
    });
  }

  void _generateUri() {
    FocusScope.of(context).unfocus();
    final String secret = _secretCtrl.text.trim();
    if (secret.isEmpty) {
      setState(() {
        _uriErrorKey = 'totpgen_error_secret_empty';
        _uriErrorDetail = null;
        _uriOutput = null;
      });
      return;
    }

    final Base32Result decoded = Base32.decode(secret);
    if (!decoded.isOk) {
      setState(() {
        _uriErrorKey = decoded.errorKey;
        _uriErrorDetail = null;
        _uriOutput = null;
      });
      return;
    }

    final TotpUriData data = TotpUriData(
      issuer: _issuerCtrl.text.trim().isEmpty
          ? null
          : _issuerCtrl.text.trim(),
      account: _accountCtrl.text.trim().isEmpty
          ? null
          : _accountCtrl.text.trim(),
      secret: secret.toUpperCase().replaceAll(RegExp(r'[^A-Z2-7]'), ''),
      digits: _config.digits,
      period: _config.period,
      algorithm: _config.algorithm,
    );

    final String uri = TotpGenerator.buildOtpAuthUri(data);
    setState(() {
      _uriOutput = uri;
      _uriErrorKey = null;
      _uriErrorDetail = null;
    });
  }

  void _importUri() {
    FocusScope.of(context).unfocus();
    final String raw = _uriInputCtrl.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _uriErrorKey = 'totpgen_error_uri_empty';
        _uriErrorDetail = null;
      });
      return;
    }

    final TotpUriData? data = TotpGenerator.parseOtpAuthUri(raw);
    if (data == null) {
      setState(() {
        _uriErrorKey = 'totpgen_error_uri_invalid';
        _uriErrorDetail = null;
      });
      return;
    }

    setState(() {
      _secretCtrl.text = data.secret;
      _config
        ..secret = data.secret
        ..digits = data.digits
        ..period = data.period
        ..algorithm = data.algorithm;
      _issuerCtrl.text = data.issuer ?? '';
      _accountCtrl.text = data.account ?? '';
      _uriErrorKey = null;
      _uriErrorDetail = null;
      _uriOutput = raw;
    });
    _refresh();
    _showSnack(context.t('totpgen_uri_imported'));
    _tabController.animateTo(0);
  }

  String _formatCode(String code) {
    if (code.isEmpty) return '------';
    if (code.length == 6) {
      return '${code.substring(0, 3)} ${code.substring(3)}';
    }
    if (code.length == 8) {
      return '${code.substring(0, 4)} ${code.substring(4)}';
    }
    if (code.length == 7) {
      return '${code.substring(0, 4)} ${code.substring(4)}';
    }
    return code;
  }

  Color _progressColor(int remaining, int period) {
    if (period == 0) return _danger;
    final double ratio = remaining / period;
    if (ratio > 0.5) return _success;
    if (ratio > 0.2) return _warning;
    return _danger;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.t('totpgen_title')),
        actions: <Widget>[
          _glassIconButton(
            icon: Icons.casino_outlined,
            tooltip: context.t('totpgen_new_secret'),
            onTap: _generateNewSecret,
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
                    _buildCodeTab(),
                    _buildVerifyTab(),
                    _buildUriTab(),
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
              Tab(text: context.t('totpgen_tab_code')),
              Tab(text: context.t('totpgen_tab_verify')),
              Tab(text: context.t('totpgen_tab_uri')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeTab() {
    final TotpCode? code = _current;
    final int remaining = code?.remainingSeconds ?? 0;
    final int period = _config.period;
    final Color progressColor = _progressColor(remaining, period);
    final double progress = period == 0 ? 0 : remaining / period;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _GlassCard(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 22,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  context.t('totpgen_current_code'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => _copy(code?.code ?? ''),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        _formatCode(code?.code ?? ''),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _glassIconButton(
                        icon: Icons.copy_rounded,
                        tooltip: context.t('totpgen_copy_code'),
                        onTap: () => _copy(code?.code ?? ''),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    valueColor:
                    AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: progressColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$remaining s',
                      style: TextStyle(
                        color: progressColor,
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
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
                _sectionHeader(
                  icon: Icons.key_rounded,
                  labelKey: 'totpgen_secret',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
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
                        splashRadius: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      _glassIconButton(
                        icon: Icons.copy_rounded,
                        tooltip: context.t('totpgen_copy_secret'),
                        onTap: () => _copy(_secretCtrl.text),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _glassTextField(
                  controller: _secretCtrl,
                  hint: 'JBSWY3DPEHPK3PXP',
                  obscure: !_showSecret,
                  onChanged: _onSecretChanged,
                  monospace: true,
                ),
                const SizedBox(height: 8),
                Text(
                  context.t('totpgen_secret_hint'),
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _sectionHeader(
                  icon: Icons.tune_rounded,
                  labelKey: 'totpgen_config',
                ),
                const SizedBox(height: 12),
                _label('totpgen_algorithm'),
                const SizedBox(height: 6),
                _algorithmSelector(),
                const SizedBox(height: 12),
                _label('totpgen_digits'),
                const SizedBox(height: 6),
                _digitsSelector(),
                const SizedBox(height: 12),
                _label('totpgen_period'),
                const SizedBox(height: 6),
                _periodSelector(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _sectionHeader(
                  icon: Icons.verified_user_outlined,
                  labelKey: 'totpgen_verify_label',
                ),
                const SizedBox(height: 10),
                _glassTextField(
                  controller: _verifyCodeCtrl,
                  hint: '123456',
                  monospace: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],
                ),
                const SizedBox(height: 12),
                _primaryButton(
                  icon: Icons.check_circle_outline_rounded,
                  labelKey: 'totpgen_verify_action',
                  onTap: _verify,
                ),
                if (_verifyChecked) ...<Widget>[
                  const SizedBox(height: 14),
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
                              : Icons.cancel_rounded,
                          color: _verifyResult! ? _success : _danger,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.t(_verifyMessageKey ??
                                'totpgen_verify_fail'),
                            style: TextStyle(
                              color: _verifyResult!
                                  ? _success
                                  : _danger,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.white60,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.t('totpgen_verify_info_title'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  context.t('totpgen_verify_info_body'),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUriTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _sectionHeader(
                  icon: Icons.qr_code_rounded,
                  labelKey: 'totpgen_uri_generate',
                ),
                const SizedBox(height: 10),
                _glassTextField(
                  controller: _issuerCtrl,
                  hint: context.t('totpgen_issuer_hint'),
                ),
                const SizedBox(height: 10),
                _glassTextField(
                  controller: _accountCtrl,
                  hint: context.t('totpgen_account_hint'),
                ),
                const SizedBox(height: 12),
                _primaryButton(
                  icon: Icons.link_rounded,
                  labelKey: 'totpgen_generate_uri',
                  onTap: _generateUri,
                ),
                if (_uriOutput != null) ...<Widget>[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: SelectableText(
                      _uriOutput!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        height: 1.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _copy(_uriOutput!),
                      icon: const Icon(
                        Icons.copy_rounded,
                        size: 16,
                        color: _accentB,
                      ),
                      label: Text(
                        context.t('totpgen_copy'),
                        style: const TextStyle(
                          color: _accentB,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _sectionHeader(
                  icon: Icons.download_rounded,
                  labelKey: 'totpgen_uri_import',
                ),
                const SizedBox(height: 10),
                _glassTextField(
                  controller: _uriInputCtrl,
                  hint: 'otpauth://totp/Issuer:account?secret=...',
                  maxLines: 5,
                  minLines: 3,
                  monospace: true,
                ),
                const SizedBox(height: 12),
                _primaryButton(
                  icon: Icons.download_done_rounded,
                  labelKey: 'totpgen_import_uri',
                  onTap: _importUri,
                ),
              ],
            ),
          ),
          if (_uriErrorKey != null) ...<Widget>[
            const SizedBox(height: 14),
            _errorBox(_uriErrorKey!, _uriErrorDetail),
          ],
        ],
      ),
    );
  }

  Widget _label(String labelKey) {
    return Text(
      context.t(labelKey),
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _algorithmSelector() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: TotpAlgorithm.values.map((TotpAlgorithm a) {
        final bool selected = _config.algorithm == a;
        return GestureDetector(
          onTap: () {
            setState(() => _config.algorithm = a);
            _refresh();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
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

  Widget _digitsSelector() {
    const List<int> options = <int>[6, 7, 8];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: options.map((int d) {
        final bool selected = _config.digits == d;
        return GestureDetector(
          onTap: () {
            setState(() => _config.digits = d);
            _refresh();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 8,
            ),
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
              '$d',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _periodSelector() {
    const List<int> options = <int>[15, 30, 60, 90];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: options.map((int p) {
        final bool selected = _config.period == p;
        return GestureDetector(
          onTap: () {
            setState(() => _config.period = p);
            _refresh();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
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
              '${p}s',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String labelKey,
    Widget? trailing,
  }) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            context.t(labelKey),
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
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
          if (detail != null && detail.isNotEmpty) ...<Widget>[
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
    bool obscure = false,
    bool readOnly = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      maxLines: obscure ? 1 : maxLines,
      minLines: minLines,
      obscureText: obscure,
      readOnly: readOnly,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontFamily: monospace ? 'monospace' : null,
        letterSpacing: monospace ? 1.2 : 0,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.35),
          fontSize: 12,
          fontFamily: monospace ? 'monospace' : null,
        ),
        isDense: true,
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
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