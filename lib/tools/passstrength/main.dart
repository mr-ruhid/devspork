import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/app_localization.dart';
import 'analyzer.dart';
import 'models.dart';

String _tr(BuildContext context, String key, String fallback) {
  try {
    final String value = context.t(key);
    if (value.isEmpty || value == key) return fallback;
    return value;
  } catch (_) {
    return fallback;
  }
}

const Color _accentA = Color(0xFF7C4DFF);
const Color _accentB = Color(0xFF00E5FF);
const Color _danger = Color(0xFFFF5C5C);
const Color _warning = Color(0xFFFFC24B);
const Color _success = Color(0xFF4BD68B);
const Color _bgTop = Color(0xFF1B1035);
const Color _bgMid = Color(0xFF2A1550);
const Color _bgBot = Color(0xFF0F2A4A);

class PassStrength extends StatefulWidget {
  const PassStrength({super.key});

  @override
  State<PassStrength> createState() => _PassStrengthState();
}

class _PassStrengthState extends State<PassStrength>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  final TextEditingController _passwordCtrl = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();

  StrengthResult? _result;
  String? _errorKey;
  String? _errorDetail;
  bool _showPassword = false;

  GeneratorOptions _genOpts = const GeneratorOptions();
  String _generated = '';

  String? _breachErrorKey;
  String? _breachErrorDetail;
  bool _breachLoading = false;
  BreachResult? _breachResult;

  Timer? _debounce;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _passwordCtrl.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabs.dispose();
    _passwordCtrl.removeListener(_onPasswordChanged);
    _passwordCtrl.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 220),
          () => _analyze(_passwordCtrl.text),
    );
  }

  void _analyze(String value) {
    if (value.isEmpty) {
      setState(() {
        _result = null;
        _errorKey = null;
        _errorDetail = null;
        _breachResult = null;
        _breachErrorKey = null;
        _breachErrorDetail = null;
      });
      return;
    }
    try {
      final StrengthResult r = PassStrengthAnalyzer.analyze(value);
      setState(() {
        _result = r;
        _errorKey = null;
        _errorDetail = null;
        _breachResult = null;
        _breachErrorKey = null;
        _breachErrorDetail = null;
      });
    } on PassStrengthException catch (e) {
      setState(() {
        _result = null;
        _errorKey = e.errorKey;
        _errorDetail = e.detail;
      });
    } catch (e) {
      setState(() {
        _result = null;
        _errorKey = 'passstrength_error_unknown';
        _errorDetail = e.toString();
      });
    }
  }

  Future<void> _copy(String text, String label) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withOpacity(0.8),
        content: Text(label),
        duration: const Duration(seconds: 1),
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _clearPassword() {
    HapticFeedback.selectionClick();
    _passwordCtrl.clear();
    _analyze('');
  }

  Future<void> _pastePassword() async {
    final ClipboardData? c = await Clipboard.getData(Clipboard.kTextPlain);
    if (c == null || c.text == null) return;
    HapticFeedback.selectionClick();
    _passwordCtrl.text = c.text!;
    _analyze(c.text!);
  }

  void _generate() {
    FocusScope.of(context).unfocus();
    try {
      final String p = PassStrengthAnalyzer.generatePassword(_genOpts);
      setState(() {
        _generated = p;
        _errorKey = null;
        _errorDetail = null;
      });
      HapticFeedback.mediumImpact();
    } on PassStrengthException catch (e) {
      setState(() {
        _generated = '';
        _errorKey = e.errorKey;
        _errorDetail = e.detail;
      });
    }
  }

  void _useGenerated() {
    if (_generated.isEmpty) return;
    HapticFeedback.selectionClick();
    _passwordCtrl.text = _generated;
    _analyze(_generated);
    _tabs.animateTo(0);
  }

  Future<void> _checkBreach() async {
    final String pw = _passwordCtrl.text;
    if (pw.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _breachLoading = true;
      _breachErrorKey = null;
      _breachErrorDetail = null;
      _breachResult = null;
    });
    try {
      final BreachResult r = await PassStrengthAnalyzer.checkBreach(pw);
      if (!mounted) return;
      setState(() {
        _breachLoading = false;
        _breachResult = r;
        if (_result != null) {
          _result = _result!.copyWith(
            isBreached: r.isBreached,
            breachCount: r.count,
          );
        }
      });
      HapticFeedback.lightImpact();
    } on PassStrengthException catch (e) {
      if (!mounted) return;
      setState(() {
        _breachLoading = false;
        _breachErrorKey = e.errorKey;
        _breachErrorDetail = e.detail;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _breachLoading = false;
        _breachErrorKey = 'passstrength_error_unknown';
        _breachErrorDetail = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0B0B12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.t('passstrength_title')),
        bottom: _buildTabBar(),
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
            Positioned(top: -80, left: -60, child: _blob(220, _accentA)),
            Positioned(bottom: -100, right: -60, child: _blob(260, _accentB)),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 56),
                child: TabBarView(
                  controller: _tabs,
                  children: <Widget>[
                    _buildAnalyzeTab(),
                    _buildGenerateTab(),
                    _buildBreachTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTabBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(52),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: _GlassCard(
          padding: const EdgeInsets.all(4),
          radius: 16,
          child: TabBar(
            controller: _tabs,
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
              Tab(text: _tr(context, 'passstrength_tab_analyze', 'Analyze')),
              Tab(text: _tr(context, 'passstrength_tab_generate', 'Generate')),
              Tab(text: _tr(context, 'passstrength_tab_breach', 'Breach')),
            ],
          ),
        ),
      ),
    );
  }

  // ==================================================================
  // ANALYZE TAB
  // ==================================================================

  Widget _buildAnalyzeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildPasswordInputCard(),
          if (_errorKey != null) ...<Widget>[
            const SizedBox(height: 14),
            _errorBox(_errorKey!, _errorDetail),
          ],
          if (_result != null) ...<Widget>[
            const SizedBox(height: 14),
            _buildScoreCard(_result!),
            const SizedBox(height: 14),
            _buildCrackTimeCard(_result!),
            if (_result!.hasFeedback) ...<Widget>[
              const SizedBox(height: 14),
              _buildFeedbackCard(_result!),
            ],
            if (_result!.patterns.isNotEmpty) ...<Widget>[
              const SizedBox(height: 14),
              _buildPatternsCard(_result!),
            ],
            if (_result!.isBreached != null) ...<Widget>[
              const SizedBox(height: 14),
              _buildBreachSummaryCard(_result!),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPasswordInputCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _sectionTitle(
                  Icons.lock_outline_rounded,
                  _tr(context, 'passstrength_password', 'Password'),
                ),
              ),
              _glassIconButton(
                icon: _showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                tooltip: _showPassword
                    ? _tr(context, 'passstrength_hide', 'Hide')
                    : _tr(context, 'passstrength_show', 'Show'),
                onTap: () => setState(() => _showPassword = !_showPassword),
              ),
              const SizedBox(width: 6),
              _glassIconButton(
                icon: Icons.content_paste_rounded,
                tooltip: _tr(context, 'passstrength_paste', 'Paste'),
                onTap: _pastePassword,
              ),
              const SizedBox(width: 6),
              _glassIconButton(
                icon: Icons.close_rounded,
                tooltip: _tr(context, 'passstrength_clear', 'Clear'),
                onTap: _clearPassword,
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _passwordCtrl,
            focusNode: _passwordFocus,
            obscureText: !_showPassword,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              hintText: _tr(
                context,
                'passstrength_password_hint',
                'Type a password to analyze…',
              ),
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 13,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _accentB, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _tr(
              context,
              'passstrength_local_hint',
              'Analysis is 100% offline. Nothing leaves your device.',
            ),
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(StrengthResult r) {
    final StrengthLevel level = r.level;
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _sectionTitle(
                  Icons.speed_rounded,
                  _tr(context, 'passstrength_strength', 'Strength'),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: level.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: level.color.withOpacity(0.6)),
                ),
                child: Text(
                  _tr(context, level.labelKey, level.name),
                  style: TextStyle(
                    color: level.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _scoreBar(level),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _metric(
                  _tr(context, 'passstrength_guesses', 'Guesses'),
                  _formatBigNumber(r.guesses),
                ),
              ),
              Expanded(
                child: _metric(
                  _tr(context, 'passstrength_entropy', 'Log10'),
                  r.guessesLog10.toStringAsFixed(2),
                ),
              ),
              Expanded(
                child: _metric(
                  _tr(context, 'passstrength_score', 'Score'),
                  '${r.score}/4',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreBar(StrengthLevel level) {
    return Row(
      children: List<Widget>.generate(5, (int i) {
        final bool filled = i <= level.index;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 4 ? 4 : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 8,
              decoration: BoxDecoration(
                color: filled ? level.color : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                boxShadow: filled
                    ? <BoxShadow>[
                  BoxShadow(
                    color: level.color.withOpacity(0.4),
                    blurRadius: 8,
                  ),
                ]
                    : null,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: _accentB,
            fontSize: 13,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildCrackTimeCard(StrengthResult r) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            Icons.schedule_rounded,
            _tr(context, 'passstrength_crack_time', 'Time to crack'),
          ),
          const SizedBox(height: 10),
          _crackRow(
            Icons.bolt_rounded,
            _tr(context, 'passstrength_crack_offline_fast',
                'Offline (fast hash, 10B/s)'),
            r.crackTimes.offlineFastHashing,
          ),
          _crackRow(
            Icons.memory_rounded,
            _tr(context, 'passstrength_crack_offline_slow',
                'Offline (slow hash, 10k/s)'),
            r.crackTimes.offlineSlowHashing,
          ),
          _crackRow(
            Icons.public_rounded,
            _tr(context, 'passstrength_crack_online_nothrottle',
                'Online (no throttle, 10/s)'),
            r.crackTimes.onlineNoThrottle,
          ),
          _crackRow(
            Icons.security_rounded,
            _tr(context, 'passstrength_crack_online_throttle',
                'Online (throttled, 100/h)'),
            r.crackTimes.onlineThrottle,
          ),
        ],
      ),
    );
  }

  Widget _crackRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: Colors.white60),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: _accentB,
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(StrengthResult r) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            Icons.tips_and_updates_outlined,
            _tr(context, 'passstrength_feedback', 'Feedback'),
          ),
          const SizedBox(height: 10),
          if (r.feedbackWarning != null) ...<Widget>[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _warning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _warning.withOpacity(0.5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: _warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r.feedbackWarning!,
                      style: const TextStyle(
                        color: Color(0xFFFFE0A3),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          for (final String s in r.feedbackSuggestions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(
                      Icons.circle,
                      size: 5,
                      color: _accentB,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPatternsCard(StrengthResult r) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            Icons.pattern_rounded,
            _tr(context, 'passstrength_patterns', 'Detected patterns'),
          ),
          const SizedBox(height: 10),
          for (final PatternMatch p in r.patterns)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _accentA.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _accentA.withOpacity(0.5)),
                    ),
                    child: Text(
                      p.pattern,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      p.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'monospace',
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBreachSummaryCard(StrengthResult r) {
    final bool breached = r.isBreached ?? false;
    final Color color = breached ? _danger : _success;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            breached
                ? Icons.gpp_bad_rounded
                : Icons.verified_user_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  breached
                      ? _tr(context, 'passstrength_breach_found',
                      'Found in data breaches')
                      : _tr(context, 'passstrength_breach_clean',
                      'Not found in known breaches'),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (breached && r.breachCount != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    '${r.breachCount} ${_tr(context, 'passstrength_breach_times', 'occurrences')}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================================
  // GENERATE TAB
  // ==================================================================

  Widget _buildGenerateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildGeneratorOptionsCard(),
          const SizedBox(height: 14),
          _buildGeneratorOutputCard(),
          if (_errorKey != null) ...<Widget>[
            const SizedBox(height: 14),
            _errorBox(_errorKey!, _errorDetail),
          ],
        ],
      ),
    );
  }

  Widget _buildGeneratorOptionsCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            Icons.tune_rounded,
            _tr(context, 'passstrength_gen_options', 'Options'),
          ),
          const SizedBox(height: 8),
          _sliderRow(
            label: _tr(context, 'passstrength_gen_length', 'Length'),
            value: _genOpts.length.toDouble(),
            min: 4,
            max: 64,
            onChanged: (double v) => setState(() {
              _genOpts = _genOpts.copyWith(length: v.round());
            }),
          ),
          _switchRow(
            label: _tr(context, 'passstrength_gen_upper', 'Uppercase (A-Z)'),
            value: _genOpts.includeUppercase,
            onChanged: (bool v) => setState(() {
              _genOpts = _genOpts.copyWith(includeUppercase: v);
            }),
          ),
          _switchRow(
            label: _tr(context, 'passstrength_gen_lower', 'Lowercase (a-z)'),
            value: _genOpts.includeLowercase,
            onChanged: (bool v) => setState(() {
              _genOpts = _genOpts.copyWith(includeLowercase: v);
            }),
          ),
          _switchRow(
            label: _tr(context, 'passstrength_gen_digits', 'Digits (0-9)'),
            value: _genOpts.includeDigits,
            onChanged: (bool v) => setState(() {
              _genOpts = _genOpts.copyWith(includeDigits: v);
            }),
          ),
          _switchRow(
            label: _tr(context, 'passstrength_gen_symbols', 'Symbols'),
            value: _genOpts.includeSymbols,
            onChanged: (bool v) => setState(() {
              _genOpts = _genOpts.copyWith(includeSymbols: v);
            }),
          ),
          _switchRow(
            label: _tr(context, 'passstrength_gen_ambiguous',
                'Exclude ambiguous (Il1O0o)'),
            value: _genOpts.excludeAmbiguous,
            onChanged: (bool v) => setState(() {
              _genOpts = _genOpts.copyWith(excludeAmbiguous: v);
            }),
          ),
          const SizedBox(height: 12),
          _primaryButton(
            icon: Icons.casino_rounded,
            label: _tr(context, 'passstrength_gen_generate', 'Generate'),
            onTap: _generate,
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratorOutputCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _sectionTitle(
                  Icons.password_rounded,
                  _tr(context, 'passstrength_gen_result', 'Generated password'),
                ),
              ),
              _glassIconButton(
                icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
                tooltip: _copied
                    ? _tr(context, 'passstrength_copied', 'Copied')
                    : _tr(context, 'passstrength_copy', 'Copy'),
                onTap: () => _copy(
                  _generated,
                  _tr(context, 'passstrength_copied', 'Copied'),
                ),
                highlighted: _copied,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 80),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: SelectableText(
              _generated.isEmpty
                  ? _tr(context, 'passstrength_gen_empty',
                  'Tap Generate to create a password')
                  : _generated,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                height: 1.5,
                color: _generated.isEmpty ? Colors.white38 : Colors.white,
              ),
            ),
          ),
          if (_generated.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            _primaryButton(
              icon: Icons.analytics_outlined,
              label: _tr(context, 'passstrength_gen_analyze', 'Analyze'),
              onTap: _useGenerated,
            ),
          ],
        ],
      ),
    );
  }

  // ==================================================================
  // BREACH TAB
  // ==================================================================

  Widget _buildBreachTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _sectionTitle(
                  Icons.shield_outlined,
                  _tr(context, 'passstrength_breach_title', 'Breach check'),
                ),
                const SizedBox(height: 8),
                Text(
                  _tr(
                    context,
                    'passstrength_breach_desc',
                    'Checks your password against the Have I Been Pwned database using k-anonymity. Only the first 5 characters of the SHA-1 hash leave your device.',
                  ),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Text(
                    _passwordCtrl.text.isEmpty
                        ? _tr(context, 'passstrength_breach_no_pw',
                        'No password set. Go to Analyze tab first.')
                        : '•' * _passwordCtrl.text.length.clamp(8, 40),
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _primaryButton(
                  icon: _breachLoading
                      ? Icons.hourglass_top_rounded
                      : Icons.cloud_download_outlined,
                  label: _breachLoading
                      ? _tr(context, 'passstrength_breach_checking', 'Checking…')
                      : _tr(context, 'passstrength_breach_check', 'Check now'),
                  onTap: _breachLoading || _passwordCtrl.text.isEmpty
                      ? null
                      : _checkBreach,
                ),
              ],
            ),
          ),
          if (_breachErrorKey != null) ...<Widget>[
            const SizedBox(height: 14),
            _errorBox(_breachErrorKey!, _breachErrorDetail),
          ],
          if (_breachResult != null) ...<Widget>[
            const SizedBox(height: 14),
            _buildBreachResultCard(_breachResult!),
          ],
        ],
      ),
    );
  }

  Widget _buildBreachResultCard(BreachResult r) {
    final bool breached = r.isBreached;
    final Color color = breached ? _danger : _success;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                breached
                    ? Icons.gpp_bad_rounded
                    : Icons.verified_user_rounded,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  breached
                      ? _tr(context, 'passstrength_breach_found',
                      'Found in data breaches')
                      : _tr(context, 'passstrength_breach_clean',
                      'Not found in known breaches'),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (breached) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              '${r.count} ${_tr(context, 'passstrength_breach_times', 'occurrences')}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _tr(
                context,
                'passstrength_breach_warning',
                'Do not use this password. Pick a different one.',
              ),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==================================================================
  // SHARED
  // ==================================================================

  Widget _sectionTitle(IconData icon, String text) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _switchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: (bool v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _sliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _accentB.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${value.round()}',
                  style: const TextStyle(
                    color: _accentB,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _accentA,
              inactiveTrackColor: Colors.white24,
              thumbColor: _accentB,
              trackHeight: 3,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: (max - min).round(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: onTap == null ? 0.5 : 1.0,
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
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorBox(String key, String? detail) {
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
                  _tr(context, key, key),
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

  Widget _glassIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool highlighted = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: highlighted
                ? _success.withOpacity(0.25)
                : Colors.white.withOpacity(0.08),
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  icon,
                  size: 18,
                  color: highlighted ? _success : Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) {
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

  static String _formatBigNumber(double n) {
    if (n < 1000) return n.toStringAsFixed(0);
    if (n < 1e6) return '${(n / 1e3).toStringAsFixed(1)}K';
    if (n < 1e9) return '${(n / 1e6).toStringAsFixed(1)}M';
    if (n < 1e12) return '${(n / 1e9).toStringAsFixed(1)}B';
    if (n < 1e15) return '${(n / 1e12).toStringAsFixed(1)}T';
    return n.toStringAsExponential(2);
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