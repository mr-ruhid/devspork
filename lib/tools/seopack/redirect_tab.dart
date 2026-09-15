import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'redirect_engine.dart';
import 'ui_kit.dart';

class RedirectTab extends StatefulWidget {
  const RedirectTab({super.key});

  @override
  State<RedirectTab> createState() => _RedirectTabState();
}

class _RedirectTabState extends State<RedirectTab> {
  final RedirectConfig _config = RedirectConfig();

  final Map<int, TextEditingController> _fromCtrls =
  <int, TextEditingController>{};
  final Map<int, TextEditingController> _toCtrls =
  <int, TextEditingController>{};

  String _output = '';
  String? _errorKey;
  String? _errorDetail;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _config.rules.add(RedirectRule(
      from: '/old-page',
      to: '/new-page',
      status: RedirectStatus.s301,
    ));
    _config.rules.add(RedirectRule(
      from: '/blog/*',
      to: '/articles/\$1',
      status: RedirectStatus.s301,
    ));
    _rebuildControllers();
    _regenerate();
  }

  @override
  void dispose() {
    _disposeAll();
    super.dispose();
  }

  void _disposeAll() {
    for (final c in _fromCtrls.values) {
      c.dispose();
    }
    for (final c in _toCtrls.values) {
      c.dispose();
    }
    _fromCtrls.clear();
    _toCtrls.clear();
  }

  void _rebuildControllers() {
    _disposeAll();
    for (int i = 0; i < _config.rules.length; i++) {
      final RedirectRule r = _config.rules[i];
      final TextEditingController from =
      TextEditingController(text: r.from);
      final TextEditingController to =
      TextEditingController(text: r.to);
      final int idx = i;
      from.addListener(() {
        _config.rules[idx].from = from.text;
        _regenerate();
      });
      to.addListener(() {
        _config.rules[idx].to = to.text;
        _regenerate();
      });
      _fromCtrls[i] = from;
      _toCtrls[i] = to;
    }
  }

  void _changeFormat(RedirectFormat f) {
    if (_config.format == f) return;
    setState(() {
      _config.format = f;
      _regenerate();
    });
  }

  void _addRule() {
    HapticFeedback.selectionClick();
    setState(() {
      _config.rules.add(RedirectRule(from: '', to: ''));
      _rebuildControllers();
      _regenerate();
    });
  }

  void _removeRule(int i) {
    HapticFeedback.mediumImpact();
    setState(() {
      _config.rules.removeAt(i);
      _rebuildControllers();
      _regenerate();
    });
  }

  void _duplicateRule(int i) {
    HapticFeedback.selectionClick();
    setState(() {
      _config.rules.insert(i + 1, _config.rules[i].clone());
      _rebuildControllers();
      _regenerate();
    });
  }

  void _moveRule(int from, int to) {
    if (to < 0 || to >= _config.rules.length) return;
    HapticFeedback.selectionClick();
    setState(() {
      final RedirectRule r = _config.rules.removeAt(from);
      _config.rules.insert(to, r);
      _rebuildControllers();
      _regenerate();
    });
  }

  void _setStatus(int i, RedirectStatus s) {
    setState(() {
      _config.rules[i].status = s;
      _regenerate();
    });
  }

  void _togglePreserveQuery(int i) {
    setState(() {
      _config.rules[i].preserveQuery =
      !_config.rules[i].preserveQuery;
      _regenerate();
    });
  }

  void _regenerate() {
    try {
      final String out = RedirectEngine.build(_config);
      if (!mounted) return;
      setState(() {
        _output = out;
        _errorKey = null;
        _errorDetail = null;
      });
    } on RedirectException catch (e) {
      if (!mounted) return;
      setState(() {
        _output = '';
        _errorKey = e.errorKey;
        _errorDetail = e.detail;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _output = '';
        _errorKey = SeoErrors.redirectEmpty;
        _errorDetail = e.toString();
      });
    }
  }

  Future<void> _copy() async {
    if (_output.isEmpty) return;
    await seoCopy(context, _output);
    if (!mounted) return;
    setState(() => _copied = true);
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildFormatCard(),
          const SizedBox(height: 14),
          _buildRulesCard(),
          const SizedBox(height: 14),
          _buildPresetsCard(),
          if (_errorKey != null) ...<Widget>[
            const SizedBox(height: 14),
            SeoErrorBox(errorKey: _errorKey!, detail: _errorDetail),
          ],
          const SizedBox(height: 14),
          _buildOutputCard(),
        ],
      ),
    );
  }

  Widget _buildFormatCard() {
    return SeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SeoSectionTitle(
            Icons.description_outlined,
            seoTr(context, 'seo_redirect_format', 'Output format'),
          ),
          const SizedBox(height: 10),
          SeoChipPicker<RedirectFormat>(
            values: RedirectFormat.values,
            current: _config.format,
            labelOf: (RedirectFormat v) => v.display,
            onChanged: _changeFormat,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: SeoColors.accentB.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.insert_drive_file_outlined,
                  size: 14,
                  color: SeoColors.accentB,
                ),
                const SizedBox(width: 6),
                Text(
                  seoTr(context, 'seo_redirect_filename', 'Output file'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Text(
                  _config.format.filename,
                  style: const TextStyle(
                    color: SeoColors.accentB,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesCard() {
    return SeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: SeoSectionTitle(
                  Icons.rule_rounded,
                  seoTr(context, 'seo_redirect_rules', 'Redirect rules'),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: SeoColors.accentB.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_config.rules.length}',
                  style: const TextStyle(
                    color: SeoColors.accentB,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < _config.rules.length; i++) ...<Widget>[
            _buildRule(i),
            if (i < _config.rules.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
          SeoPrimaryButton(
            icon: Icons.add_rounded,
            label: seoTr(context, 'seo_redirect_add', 'Add rule'),
            onTap: _addRule,
          ),
        ],
      ),
    );
  }

  Widget _buildRule(int i) {
    final RedirectRule r = _config.rules[i];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: SeoColors.accentA.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '#${i + 1}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              SeoIconButton(
                icon: Icons.arrow_upward_rounded,
                tooltip: seoTr(context, 'seo_move_up', 'Move up'),
                onTap: i == 0 ? null : () => _moveRule(i, i - 1),
              ),
              const SizedBox(width: 2),
              SeoIconButton(
                icon: Icons.arrow_downward_rounded,
                tooltip: seoTr(context, 'seo_move_down', 'Move down'),
                onTap: i == _config.rules.length - 1
                    ? null
                    : () => _moveRule(i, i + 1),
              ),
              const SizedBox(width: 2),
              SeoIconButton(
                icon: Icons.copy_rounded,
                tooltip: seoTr(context, 'seo_duplicate', 'Duplicate'),
                onTap: () => _duplicateRule(i),
              ),
              const SizedBox(width: 2),
              SeoIconButton(
                icon: Icons.close_rounded,
                tooltip: seoTr(context, 'seo_remove', 'Remove'),
                onTap: () => _removeRule(i),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _fieldLabel(seoTr(context, 'seo_redirect_from', 'From')),
          const SizedBox(height: 6),
          SeoTextField(
            controller: _fromCtrls[i]!,
            hint: '/old-path or /blog/* or full URL',
            monospace: true,
          ),
          const SizedBox(height: 8),
          _fieldLabel(seoTr(context, 'seo_redirect_to', 'To')),
          const SizedBox(height: 6),
          SeoTextField(
            controller: _toCtrls[i]!,
            hint: '/new-path or https://example.com/\$1',
            monospace: true,
          ),
          const SizedBox(height: 10),
          _statusPicker(i, r),
          const SizedBox(height: 8),
          SeoSwitchRow(
            label: seoTr(
              context,
              'seo_redirect_preserve_query',
              'Preserve query string',
            ),
            value: r.preserveQuery,
            onChanged: (_) => _togglePreserveQuery(i),
          ),
          const SizedBox(height: 8),
          Text(
            RedirectEngine.describeStatus(r.status),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              height: 1.4,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPicker(int i, RedirectRule r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _fieldLabel('Status'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: RedirectStatus.values.map((RedirectStatus s) {
            final bool selected = r.status == s;
            final Color c = _statusColor(s);
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _setStatus(i, s);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? c.withOpacity(0.3)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected
                        ? c
                        : Colors.white.withOpacity(0.15),
                  ),
                ),
                child: Text(
                  '${s.code}',
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontSize: 11,
                    fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _statusColor(RedirectStatus s) {
    switch (s) {
      case RedirectStatus.s301:
      case RedirectStatus.s308:
        return SeoColors.success;
      case RedirectStatus.s302:
      case RedirectStatus.s307:
        return SeoColors.accentB;
      case RedirectStatus.s303:
        return SeoColors.warning;
    }
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

  Widget _buildPresetsCard() {
    return SeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SeoSectionTitle(
            Icons.auto_awesome_rounded,
            seoTr(context, 'seo_redirect_presets', 'Common presets'),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              _presetChip(
                icon: Icons.lock_outline_rounded,
                label: seoTr(context, 'seo_redirect_force_https',
                    'Force HTTPS'),
                onTap: () => _addSpecialRule(forceHttps: true),
              ),
              _presetChip(
                icon: Icons.language_rounded,
                label: seoTr(context, 'seo_redirect_remove_www',
                    'Remove www'),
                onTap: () => _addSpecialRule(removeWww: true),
              ),
              _presetChip(
                icon: Icons.public_rounded,
                label: seoTr(context, 'seo_redirect_add_www', 'Add www'),
                onTap: () => _addSpecialRule(addWww: true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _presetChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: SeoColors.accentA.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: SeoColors.accentA.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 14, color: SeoColors.accentA),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addSpecialRule({
    bool forceHttps = false,
    bool removeWww = false,
    bool addWww = false,
  }) {
    setState(() {
      if (forceHttps) {
        _config.rules.add(RedirectRule(
          from: '*',
          to: '*',
          forceHttps: true,
        ));
      } else if (removeWww) {
        _config.rules.add(RedirectRule(
          from: '*',
          to: '*',
          removeWww: true,
        ));
      } else if (addWww) {
        _config.rules.add(RedirectRule(
          from: '*',
          to: '*',
          addWww: true,
        ));
      }
      _rebuildControllers();
      _regenerate();
    });
  }

  Widget _buildOutputCard() {
    return SeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: SeoSectionTitle(
                  Icons.code_rounded,
                  seoTr(context, 'seo_redirect_output', 'Configuration'),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: SeoColors.accentB.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _config.format.filename,
                  style: const TextStyle(
                    color: SeoColors.accentB,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SeoOutputBlock(
            label: _config.format.display.toUpperCase(),
            value: _output,
            copied: _copied,
            onCopy: _copy,
            emptyHint: seoTr(
              context,
              'seo_redirect_output_empty',
              'Add at least one rule to generate the configuration.',
            ),
            maxHeight: 360,
          ),
        ],
      ),
    );
  }
}