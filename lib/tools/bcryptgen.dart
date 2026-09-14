import 'dart:math';
import 'dart:ui' as ui;

import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class BcryptGen extends StatefulWidget {
  const BcryptGen({super.key});

  @override
  State<BcryptGen> createState() => _BcryptGenState();
}

class _HashJob {
  const _HashJob(this.password, this.cost);
  final String password;
  final int cost;
}

class _VerifyJob {
  const _VerifyJob(this.password, this.hash);
  final String password;
  final String hash;
}

String _hashWorker(_HashJob job) =>
    BCrypt.hashpw(job.password, BCrypt.gensalt(logRounds: job.cost));

bool _verifyWorker(_VerifyJob job) => BCrypt.checkpw(job.password, job.hash);

class _BcryptGenState extends State<BcryptGen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Generate
  final TextEditingController _genPassword = TextEditingController();
  final TextEditingController _genOutput = TextEditingController();
  bool _genShowPassword = false;
  int _cost = 10;
  bool _generating = false;
  String? _genError;
  Duration? _genElapsed;

  // Verify
  final TextEditingController _verifyPassword = TextEditingController();
  final TextEditingController _verifyHash = TextEditingController();
  bool _verifyShowPassword = false;
  bool _verifying = false;
  bool _verifyDone = false;
  bool _verifyMatch = false;
  String? _verifyError;

  final List<_HashHistoryItem> _history = <_HashHistoryItem>[];

  static const List<int> _costOptions = <int>[4, 6, 8, 10, 12, 14];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _genPassword.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _genPassword.dispose();
    _genOutput.dispose();
    _verifyPassword.dispose();
    _verifyHash.dispose();
    super.dispose();
  }

  String _costDescription(int cost) {
    if (cost <= 4) return context.t('bcryptgen_cost_fast');
    if (cost <= 8) return context.t('bcryptgen_cost_medium');
    if (cost <= 10) return context.t('bcryptgen_cost_default');
    if (cost <= 12) return context.t('bcryptgen_cost_slow');
    return context.t('bcryptgen_cost_veryslow');
  }

  // --- password strength (rough heuristic, local only) ---
  double _strengthScore(String pw) {
    if (pw.isEmpty) return 0;
    double score = 0;
    score += (pw.length.clamp(0, 20)) / 20 * 0.4;
    if (RegExp(r'[a-z]').hasMatch(pw)) score += 0.15;
    if (RegExp(r'[A-Z]').hasMatch(pw)) score += 0.15;
    if (RegExp(r'[0-9]').hasMatch(pw)) score += 0.15;
    if (RegExp(r'[^a-zA-Z0-9]').hasMatch(pw)) score += 0.15;
    return score.clamp(0, 1);
  }

  Color _strengthColor(double s) {
    if (s < 0.35) return const Color(0xFFFF5C7A);
    if (s < 0.65) return const Color(0xFFFFC24B);
    return const Color(0xFF4CD97B);
  }

  String _strengthLabel(double s) {
    if (s < 0.35) return context.t('bcryptgen_strength_weak');
    if (s < 0.65) return context.t('bcryptgen_strength_medium');
    return context.t('bcryptgen_strength_strong');
  }

  void _generateRandomPassword() {
    HapticFeedback.selectionClick();
    const String chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    final Random rnd = Random.secure();
    final String pw = List<String>.generate(16, (_) => chars[rnd.nextInt(chars.length)]).join();
    setState(() {
      _genPassword.text = pw;
      _genShowPassword = true;
    });
  }

  Future<void> _generate() async {
    final String pw = _genPassword.text;
    if (pw.isEmpty) {
      setState(() {
        _genError = 'bcryptgen_error_empty_password';
        _genOutput.text = '';
      });
      return;
    }
    setState(() {
      _generating = true;
      _genError = null;
      _genOutput.text = '';
      _genElapsed = null;
    });
    final Stopwatch sw = Stopwatch()..start();
    try {
      final String hash = await compute(_hashWorker, _HashJob(pw, _cost));
      sw.stop();
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _genOutput.text = hash;
        _generating = false;
        _genElapsed = sw.elapsed;
      });
      _history.insert(
        0,
        _HashHistoryItem(hash: hash, cost: _cost, at: DateTime.now(), elapsed: sw.elapsed),
      );
      if (_history.length > 6) _history.removeLast();
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() {
        _generating = false;
        _genError = e.toString();
      });
    }
  }

  Future<void> _verify() async {
    final String pw = _verifyPassword.text;
    final String hash = _verifyHash.text.trim();
    if (pw.isEmpty) {
      setState(() {
        _verifyError = 'bcryptgen_error_empty_password';
        _verifyDone = false;
      });
      return;
    }
    if (hash.isEmpty) {
      setState(() {
        _verifyError = 'bcryptgen_error_empty_hash';
        _verifyDone = false;
      });
      return;
    }
    setState(() {
      _verifying = true;
      _verifyError = null;
      _verifyDone = false;
    });
    try {
      final bool match = await compute(_verifyWorker, _VerifyJob(pw, hash));
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _verifying = false;
        _verifyDone = true;
        _verifyMatch = match;
      });
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() {
        _verifying = false;
        _verifyDone = false;
        _verifyError = e.toString();
      });
    }
  }

  Future<void> _copy(String text) async {
    if (text.isEmpty) return;
    HapticFeedback.mediumImpact();
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    _showToast(context.t('bcryptgen_copied'));
  }

  Future<void> _pasteTo(TextEditingController c) async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null) return;
    HapticFeedback.selectionClick();
    c.text = data.text!;
  }

  void _clearGen() {
    HapticFeedback.lightImpact();
    setState(() {
      _genPassword.clear();
      _genOutput.clear();
      _genError = null;
      _genElapsed = null;
    });
  }

  void _clearVerify() {
    HapticFeedback.lightImpact();
    setState(() {
      _verifyPassword.clear();
      _verifyHash.clear();
      _verifyError = null;
      _verifyDone = false;
    });
  }

  void _useInVerify() {
    HapticFeedback.selectionClick();
    _verifyHash.text = _genOutput.text;
    _tabController.animateTo(1);
    setState(() {});
  }

  void _showToast(String message) {
    final OverlayState overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (BuildContext ctx) => Positioned(
        bottom: 90,
        left: 40,
        right: 40,
        child: _ToastBubble(message: message),
      ),
    );
    overlay.insert(entry);
    Future<void>.delayed(const Duration(milliseconds: 1400), entry.remove);
  }

  // ---------------------------------------------------------
  // GENERATE TAB
  // ---------------------------------------------------------
  Widget _buildGenerate() {
    final double strength = _strengthScore(_genPassword.text);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        context.t('bcryptgen_password'),
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                    ),
                    _GlassIconButton(icon: CupertinoIcons.shuffle, onTap: _generateRandomPassword),
                  ],
                ),
                const SizedBox(height: 8),
                _PasswordField(
                  controller: _genPassword,
                  show: _genShowPassword,
                  onToggle: () => setState(() => _genShowPassword = !_genShowPassword),
                ),
                if (_genPassword.text.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: strength,
                      minHeight: 5,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(_strengthColor(strength)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _strengthLabel(strength),
                    style: TextStyle(color: _strengthColor(strength), fontSize: 11, fontWeight: FontWeight.w600),
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
                Row(
                  children: <Widget>[
                    Text(
                      '${context.t('bcryptgen_cost')}: $_cost',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                Text(
                  _costDescription(_cost),
                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5)),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _costOptions.map((int c) {
                    final bool selected = _cost == c;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _cost = c);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFF7C4DFF).withOpacity(0.85) : Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? const Color(0xFF7C4DFF) : Colors.white.withOpacity(0.15),
                          ),
                        ),
                        child: Text('$c', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _GlassActionButton(
                  label: _generating ? context.t('bcryptgen_generating') : context.t('bcryptgen_generate'),
                  icon: CupertinoIcons.lock_fill,
                  onTap: _generating ? null : _generate,
                  loading: _generating,
                ),
              ),
              const SizedBox(width: 8),
              _GlassIconButton(icon: CupertinoIcons.clear, onTap: _clearGen),
            ],
          ),
          if (_genError != null) ...<Widget>[
            const SizedBox(height: 12),
            _ErrorBanner(
              message: _genError!.startsWith('bcryptgen_') ? context.t(_genError!) : _genError!,
            ),
          ],
          const SizedBox(height: 16),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        context.t('bcryptgen_hash_output'),
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (_genElapsed != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          '${_genElapsed!.inMilliseconds}ms',
                          style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11),
                        ),
                      ),
                    _GlassIconButton(
                      icon: CupertinoIcons.doc_on_doc,
                      onTap: _genOutput.text.isEmpty ? null : () => _copy(_genOutput.text),
                    ),
                    const SizedBox(width: 6),
                    _GlassIconButton(
                      icon: CupertinoIcons.arrow_right_circle,
                      onTap: _genOutput.text.isEmpty ? null : _useInVerify,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _GlassTextField(controller: _genOutput, readOnly: true, maxLines: 4, minLines: 3),
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
                    const Icon(CupertinoIcons.info_circle, size: 15, color: Colors.white54),
                    const SizedBox(width: 6),
                    Text(
                      context.t('bcryptgen_info_title'),
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  context.t('bcryptgen_info_body'),
                  style: TextStyle(fontSize: 12, height: 1.4, color: Colors.white.withOpacity(0.6)),
                ),
              ],
            ),
          ),
          if (_history.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            _HistoryCard(history: _history, onCopy: _copy),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // VERIFY TAB
  // ---------------------------------------------------------
  Widget _buildVerify() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  context.t('bcryptgen_password'),
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _PasswordField(
                  controller: _verifyPassword,
                  show: _verifyShowPassword,
                  onToggle: () => setState(() => _verifyShowPassword = !_verifyShowPassword),
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
                    Expanded(
                      child: Text(
                        context.t('bcryptgen_hash_input'),
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                    ),
                    _GlassIconButton(icon: CupertinoIcons.doc_on_clipboard, onTap: () => _pasteTo(_verifyHash)),
                  ],
                ),
                const SizedBox(height: 8),
                _GlassTextField(
                  controller: _verifyHash,
                  maxLines: 4,
                  minLines: 3,
                  hint: r'$2a$10$...',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _GlassActionButton(
                  label: _verifying ? context.t('bcryptgen_verifying') : context.t('bcryptgen_verify'),
                  icon: CupertinoIcons.checkmark_shield,
                  onTap: _verifying ? null : _verify,
                  loading: _verifying,
                  tint: const Color(0xFF00E5FF),
                ),
              ),
              const SizedBox(width: 8),
              _GlassIconButton(icon: CupertinoIcons.clear, onTap: _clearVerify),
            ],
          ),
          if (_verifyError != null) ...<Widget>[
            const SizedBox(height: 12),
            _ErrorBanner(
              message: _verifyError!.startsWith('bcryptgen_') ? context.t(_verifyError!) : _verifyError!,
            ),
          ],
          if (_verifyDone) ...<Widget>[
            const SizedBox(height: 16),
            _ResultBanner(
              match: _verifyMatch,
              title: _verifyMatch ? context.t('bcryptgen_match') : context.t('bcryptgen_no_match'),
              subtitle: _verifyMatch ? context.t('bcryptgen_match_hint') : context.t('bcryptgen_no_match_hint'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.t('bcryptgen_title'),
          style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.4),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF1B1035),
              Color(0xFF2A1550),
              Color(0xFF0F2A4A),
            ],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(top: -80, left: -60, child: _blurBlob(220, const Color(0xFF7C4DFF))),
            Positioned(bottom: -100, right: -60, child: _blurBlob(260, const Color(0xFF00E5FF))),
            SafeArea(
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 56),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _GlassSegmentedTabs(
                      controller: _tabController,
                      labels: <String>[
                        context.t('bcryptgen_tab_generate'),
                        context.t('bcryptgen_tab_verify'),
                      ],
                      onChanged: (int i) {
                        HapticFeedback.selectionClick();
                        setState(() => _tabController.animateTo(i));
                      },
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: <Widget>[_buildGenerate(), _buildVerify()],
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.35)),
          ),
        ),
      ),
    );
  }
}

class _HashHistoryItem {
  _HashHistoryItem({required this.hash, required this.cost, required this.at, required this.elapsed});
  final String hash;
  final int cost;
  final DateTime at;
  final Duration elapsed;
}

// ============================================================
// iOS "liquid glass" building blocks
// ============================================================

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: <BoxShadow>[
              BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 12)),
              BoxShadow(color: Colors.white.withOpacity(0.06), blurRadius: 1, offset: const Offset(0, 1)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({required this.controller, required this.show, required this.onToggle});
  final TextEditingController controller;
  final bool show;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: !show,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.black.withOpacity(0.25),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 1.5),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(show ? CupertinoIcons.eye_slash : CupertinoIcons.eye, size: 18, color: Colors.white60),
        ),
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  const _GlassTextField({
    required this.controller,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.hint,
  });

  final TextEditingController controller;
  final bool readOnly;
  final int maxLines;
  final int? minLines;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      minLines: minLines,
      style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11, fontFamily: 'monospace'),
        filled: true,
        fillColor: Colors.black.withOpacity(0.25),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 1.5),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white.withOpacity(0.08),
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.15)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: enabled ? Colors.white : Colors.white30),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassActionButton extends StatelessWidget {
  const _GlassActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.tint = const Color(0xFF7C4DFF),
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Color tint;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: tint.withOpacity(enabled ? 0.18 : 0.08),
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tint.withOpacity(enabled ? 0.5 : 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (loading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  else
                    Icon(icon, size: 16, color: enabled ? Colors.white : Colors.white30),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: enabled ? Colors.white : Colors.white30,
                      fontWeight: FontWeight.w600,
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
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5C7A).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF5C7A).withOpacity(0.4)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(CupertinoIcons.exclamationmark_triangle, size: 15, color: Color(0xFFFF5C7A)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFFF5C7A), fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.match, required this.title, required this.subtitle});
  final bool match;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final Color color = match ? const Color(0xFF4CD97B) : const Color(0xFFFF5C7A);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.14),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(
            children: <Widget>[
              Icon(match ? CupertinoIcons.checkmark_seal_fill : CupertinoIcons.xmark_seal_fill, color: color, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.history, required this.onCopy});
  final List<_HashHistoryItem> history;
  final ValueChanged<String> onCopy;

  String _formatTime(DateTime dt) {
    final String hh = dt.hour.toString().padLeft(2, '0');
    final String mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _truncate(String s) => s.length > 24 ? '${s.substring(0, 24)}…' : s;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(CupertinoIcons.clock, size: 14, color: Colors.white54),
              const SizedBox(width: 6),
              Text(
                context.t('bcryptgen_history'),
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...history.map(
                (_HashHistoryItem h) => InkWell(
              onTap: () => onCopy(h.hash),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: <Widget>[
                    const Icon(CupertinoIcons.lock_fill, size: 13, color: Color(0xFF7C4DFF)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _truncate(h.hash),
                        style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ),
                    Text(
                      'cost ${h.cost}',
                      style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 10),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(h.at),
                      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassSegmentedTabs extends StatelessWidget {
  const _GlassSegmentedTabs({required this.controller, required this.labels, required this.onChanged});
  final TabController controller;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: AnimatedBuilder(
          animation: controller,
          builder: (BuildContext context, _) {
            return Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: Row(
                children: List<Widget>.generate(labels.length, (int i) {
                  final bool selected = controller.index == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onChanged(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFF7C4DFF).withOpacity(0.85) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: selected
                              ? <BoxShadow>[
                            BoxShadow(
                              color: const Color(0xFF7C4DFF).withOpacity(0.45),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          labels[i],
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ToastBubble extends StatelessWidget {
  const _ToastBubble({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}