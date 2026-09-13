import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class BcryptGen extends StatefulWidget {
  const BcryptGen({super.key});

  @override
  State<BcryptGen> createState() => _BcryptGenState();
}

class _BcryptGenState extends State<BcryptGen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Generate
  final TextEditingController _genPassword = TextEditingController();
  final TextEditingController _genOutput = TextEditingController();
  bool _genShowPassword = false;
  int _cost = 10;
  bool _generating = false;
  String? _genError;

  // Verify
  final TextEditingController _verifyPassword = TextEditingController();
  final TextEditingController _verifyHash = TextEditingController();
  bool _verifyShowPassword = false;
  bool _verifying = false;
  bool _verifyDone = false;
  bool _verifyMatch = false;
  String? _verifyError;

  static const List<int> _costOptions = <int>[4, 6, 8, 10, 12, 14];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    });
    try {
      final String hash = BCrypt.hashpw(pw, BCrypt.gensalt(logRounds: _cost));
      if (!mounted) return;
      setState(() {
        _genOutput.text = hash;
        _generating = false;
      });
    } catch (e) {
      if (!mounted) return;
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
      final bool match = BCrypt.checkpw(pw, hash);
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _verifyDone = true;
        _verifyMatch = match;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _verifyDone = false;
        _verifyError = e.toString();
      });
    }
  }

  Future<void> _copy(String text) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('bcryptgen_copied'))),
    );
  }

  Future<void> _pasteTo(TextEditingController c) async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null) return;
    c.text = data.text!;
  }

  void _clearGen() {
    setState(() {
      _genPassword.clear();
      _genOutput.clear();
      _genError = null;
    });
  }

  void _clearVerify() {
    setState(() {
      _verifyPassword.clear();
      _verifyHash.clear();
      _verifyError = null;
      _verifyDone = false;
    });
  }

  Widget _passwordField({
    required String labelKey,
    required TextEditingController controller,
    required bool show,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !show,
      decoration: InputDecoration(
        labelText: context.t(labelKey),
        border: const OutlineInputBorder(),
        isDense: true,
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            show ? Icons.visibility_off : Icons.visibility,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildGenerate() {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _passwordField(
            labelKey: 'bcryptgen_password',
            controller: _genPassword,
            show: _genShowPassword,
            onToggle: () {
              setState(() => _genShowPassword = !_genShowPassword);
            },
          ),
          const SizedBox(height: 16),
          Text(
            '${context.t('bcryptgen_cost')}: $_cost',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            _costDescription(_cost),
            style: TextStyle(
              fontSize: 11,
              color: colors.outline,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _costOptions.map((int c) {
              return ChoiceChip(
                label: Text('$c'),
                selected: _cost == c,
                onSelected: (_) {
                  setState(() {
                    _cost = c;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: _generating ? null : _generate,
                  icon: _generating
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.lock),
                  label: Text(
                    _generating
                        ? context.t('bcryptgen_generating')
                        : context.t('bcryptgen_generate'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _clearGen,
                icon: const Icon(Icons.clear),
              ),
            ],
          ),
          if (_genError != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _genError!.startsWith('bcryptgen_')
                    ? context.t(_genError!)
                    : _genError!,
                style: TextStyle(color: colors.error, fontSize: 12),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  context.t('bcryptgen_hash_output'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => _copy(_genOutput.text),
                icon: const Icon(Icons.copy, size: 18),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  _verifyHash.text = _genOutput.text;
                  _tabController.index = 1;
                },
                icon: const Icon(Icons.arrow_forward, size: 18),
                tooltip: context.t('bcryptgen_use_in_verify'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _genOutput,
            readOnly: true,
            maxLines: 4,
            minLines: 3,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    context.t('bcryptgen_info_title'),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.t('bcryptgen_info_body'),
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerify() {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _passwordField(
            labelKey: 'bcryptgen_password',
            controller: _verifyPassword,
            show: _verifyShowPassword,
            onToggle: () {
              setState(() => _verifyShowPassword = !_verifyShowPassword);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  context.t('bcryptgen_hash_input'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => _pasteTo(_verifyHash),
                icon: const Icon(Icons.paste, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _verifyHash,
            maxLines: 4,
            minLines: 3,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              isDense: true,
              hintText: '\$2a\$10\$...',
              hintStyle: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: _verifying ? null : _verify,
                  icon: _verifying
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.verified_user),
                  label: Text(
                    _verifying
                        ? context.t('bcryptgen_verifying')
                        : context.t('bcryptgen_verify'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _clearVerify,
                icon: const Icon(Icons.clear),
              ),
            ],
          ),
          if (_verifyError != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _verifyError!.startsWith('bcryptgen_')
                    ? context.t(_verifyError!)
                    : _verifyError!,
                style: TextStyle(color: colors.error, fontSize: 12),
              ),
            ),
          if (_verifyDone) ...<Widget>[
            const SizedBox(height: 16),
            Card(
              color: _verifyMatch
                  ? Colors.green.withValues(alpha: 0.15)
                  : colors.error.withValues(alpha: 0.15),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: <Widget>[
                    Icon(
                      _verifyMatch
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: _verifyMatch ? Colors.green : colors.error,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _verifyMatch
                                ? context.t('bcryptgen_match')
                                : context.t('bcryptgen_no_match'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _verifyMatch
                                  ? Colors.green
                                  : colors.error,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _verifyMatch
                                ? context.t('bcryptgen_match_hint')
                                : context.t('bcryptgen_no_match_hint'),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('bcryptgen_title')),
        bottom: TabBar(
          controller: _tabController,
          tabs: <Widget>[
            Tab(text: context.t('bcryptgen_tab_generate')),
            Tab(text: context.t('bcryptgen_tab_verify')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          _buildGenerate(),
          _buildVerify(),
        ],
      ),
    );
  }
}