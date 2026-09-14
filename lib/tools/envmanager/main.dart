import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/app_localization.dart';
import 'models.dart';
import 'parser.dart';

const Color _accentA = Color(0xFF7C4DFF);
const Color _accentB = Color(0xFF00E5FF);
const Color _danger = Color(0xFFFF5C5C);
const Color _warning = Color(0xFFFFC24B);
const Color _success = Color(0xFF4BD68B);
const Color _bgTop = Color(0xFF1B1035);
const Color _bgMid = Color(0xFF2A1550);
const Color _bgBot = Color(0xFF0F2A4A);

class EnvManager extends StatefulWidget {
  const EnvManager({super.key});

  @override
  State<EnvManager> createState() => _EnvManagerState();
}

class _EnvManagerState extends State<EnvManager>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final TextEditingController _inputCtrl = TextEditingController();

  EnvFormat _inputFormat = EnvFormat.dotenv;
  EnvFormat _outputFormat = EnvFormat.json;
  final EnvConvertOptions _options = EnvConvertOptions();

  EnvDocument _doc = EnvDocument.empty;
  String _output = '';
  String? _parseErrorKey;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inputCtrl.dispose();
    super.dispose();
  }

  void _reparse() {
    final String input = _inputCtrl.text;
    if (input.trim().isEmpty) {
      setState(() {
        _doc = EnvDocument.empty;
        _parseErrorKey = null;
        _output = '';
      });
      return;
    }

    final EnvDocument doc = EnvParser.parse(input, _inputFormat);

    final bool hasFatal = doc.issues.any(
          (EnvValidationIssue i) =>
      i.severity == EnvErrorSeverity.error && i.lineNumber == 0,
    );

    setState(() {
      _doc = doc;
      _parseErrorKey = hasFatal ? doc.issues.first.messageKey : null;
      _output = doc.entries.isEmpty
          ? ''
          : EnvParser.export(doc.entries, _outputFormat, options: _options);
    });
  }

  void _convert() {
    FocusScope.of(context).unfocus();
    _reparse();
    if (!_doc.hasErrors && _doc.entries.isNotEmpty) {
      _tabController.animateTo(2);
    }
  }

  Future<void> _pasteInput() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null || data.text!.isEmpty) return;
    setState(() {
      _inputCtrl.text = data.text!;
    });
    _reparse();
  }

  void _clearAll() {
    setState(() {
      _inputCtrl.clear();
      _doc = EnvDocument.empty;
      _output = '';
      _parseErrorKey = null;
    });
  }

  Future<void> _copyOutput() async {
    if (_output.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _output));
    if (!mounted) return;
    _showSnack(context.t('envmanager_copied'));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.t('envmanager_title')),
        actions: <Widget>[
          _glassIconButton(
            icon: Icons.content_paste_rounded,
            tooltip: context.t('envmanager_paste'),
            onTap: _pasteInput,
          ),
          _glassIconButton(
            icon: Icons.cleaning_services_outlined,
            tooltip: context.t('envmanager_clear'),
            onTap: _clearAll,
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
                    _buildInputTab(),
                    _buildOptionsTab(),
                    _buildOutputTab(),
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
              Tab(text: context.t('envmanager_tab_input')),
              Tab(text: context.t('envmanager_tab_options')),
              Tab(text: context.t('envmanager_tab_output')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputTab() {
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
                  icon: Icons.input_rounded,
                  labelKey: 'envmanager_input_format',
                ),
                const SizedBox(height: 10),
                _formatSelector(
                  current: _inputFormat,
                  onChanged: (EnvFormat f) {
                    setState(() => _inputFormat = f);
                    _reparse();
                  },
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
                  icon: Icons.edit_note_rounded,
                  labelKey: 'envmanager_input_label',
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _inputCtrl,
                  onChanged: (_) => _reparse(),
                  maxLines: 16,
                  minLines: 10,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'monospace',
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: _inputHint(),
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.06),
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: _accentB,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_doc.entries.isNotEmpty || _parseErrorKey != null) ...<Widget>[
            const SizedBox(height: 16),
            _validationCard(),
          ],
          const SizedBox(height: 16),
          _primaryButton(
            icon: Icons.arrow_forward_rounded,
            labelKey: 'envmanager_next',
            onTap: () => _tabController.animateTo(1),
          ),
        ],
      ),
    );
  }

  String _inputHint() {
    switch (_inputFormat) {
      case EnvFormat.dotenv:
        return '# Database\n'
            'DB_HOST=localhost\n'
            'DB_PORT=5432\n'
            'DB_USER=admin\n'
            'DB_PASSWORD="s3cr3t pass"\n'
            'API_KEY=abc123';
      case EnvFormat.json:
        return '{\n'
            '  "DB_HOST": "localhost",\n'
            '  "DB_PORT": 5432,\n'
            '  "API_KEY": "abc123"\n'
            '}';
      case EnvFormat.yaml:
        return 'DB_HOST: localhost\n'
            'DB_PORT: 5432\n'
            'API_KEY: abc123';
    }
  }

  Widget _validationCard() {
    final int errCount = _doc.errorCount;
    final int warnCount = _doc.warningCount;
    final bool hasIssues = _doc.issues.isNotEmpty;

    final Color statusColor = errCount > 0
        ? _danger
        : warnCount > 0
        ? _warning
        : _success;

    final IconData statusIcon = errCount > 0
        ? Icons.error_outline_rounded
        : warnCount > 0
        ? Icons.warning_amber_rounded
        : Icons.check_circle_outline_rounded;

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(statusIcon, size: 18, color: statusColor),
              const SizedBox(width: 8),
              Text(
                context.t('envmanager_validation'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${_doc.entries.length} ${context.t('envmanager_vars')}',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (_parseErrorKey != null) ...<Widget>[
            const SizedBox(height: 10),
            _issueRow(
              color: _danger,
              icon: Icons.error_outline,
              text: context.t(_parseErrorKey!),
              detail: _doc.issues.first.messageDetail,
            ),
          ] else if (!hasIssues) ...<Widget>[
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                const Icon(
                  Icons.check_circle_outline,
                  size: 14,
                  color: _success,
                ),
                const SizedBox(width: 6),
                Text(
                  context.t('envmanager_no_issues'),
                  style: const TextStyle(
                    color: _success,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ] else ...<Widget>[
            const SizedBox(height: 10),
            for (final EnvValidationIssue issue in _doc.issues)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _issueRow(
                  color: issue.severity == EnvErrorSeverity.error
                      ? _danger
                      : _warning,
                  icon: issue.severity == EnvErrorSeverity.error
                      ? Icons.error_outline
                      : Icons.warning_amber_rounded,
                  text: '${issue.lineNumber > 0 ? "L${issue.lineNumber}: " : ""}'
                      '${context.t(issue.messageKey)}',
                  detail: issue.messageDetail,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _issueRow({
    required Color color,
    required IconData icon,
    required String text,
    String? detail,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          if (detail != null && detail.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: Text(
                detail,
                style: const TextStyle(
                  color: Colors.white54,
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionsTab() {
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
                  icon: Icons.output_rounded,
                  labelKey: 'envmanager_output_format',
                ),
                const SizedBox(height: 10),
                _formatSelector(
                  current: _outputFormat,
                  onChanged: (EnvFormat f) {
                    setState(() => _outputFormat = f);
                    _reparse();
                  },
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
                  labelKey: 'envmanager_options',
                ),
                const SizedBox(height: 8),
                _optionSwitch(
                  labelKey: 'envmanager_opt_sort',
                  value: _options.sortKeys,
                  onChanged: (bool v) {
                    setState(() => _options.sortKeys = v);
                    _reparse();
                  },
                ),
                _optionSwitch(
                  labelKey: 'envmanager_opt_uppercase',
                  value: _options.uppercaseKeys,
                  onChanged: (bool v) {
                    setState(() => _options.uppercaseKeys = v);
                    _reparse();
                  },
                ),
                _optionSwitch(
                  labelKey: 'envmanager_opt_comments',
                  value: _options.includeComments,
                  onChanged: (bool v) {
                    setState(() => _options.includeComments = v);
                    _reparse();
                  },
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
                  icon: Icons.format_quote_rounded,
                  labelKey: 'envmanager_default_quote',
                ),
                const SizedBox(height: 10),
                _quoteSelector(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _primaryButton(
            icon: Icons.sync_alt_rounded,
            labelKey: 'envmanager_convert',
            onTap: _convert,
          ),
        ],
      ),
    );
  }

  Widget _quoteSelector() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: EnvQuoteStyle.values.map((EnvQuoteStyle q) {
        final bool selected = _options.defaultQuote == q;
        return GestureDetector(
          onTap: () {
            setState(() => _options.defaultQuote = q);
            _reparse();
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
              q.label,
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

  Widget _formatSelector({
    required EnvFormat current,
    required ValueChanged<EnvFormat> onChanged,
  }) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: EnvFormat.values.map((EnvFormat f) {
        final bool selected = current == f;
        return GestureDetector(
          onTap: () => onChanged(f),
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
              f.displayName,
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

  Widget _buildOutputTab() {
    if (_output.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.code_off_rounded,
                size: 48,
                color: Colors.white.withOpacity(0.25),
              ),
              const SizedBox(height: 12),
              Text(
                context.t('envmanager_no_output'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
                  color: _success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _success.withOpacity(0.4)),
                ),
                child: Text(
                  '${_inputFormat.displayName} → '
                      '${_outputFormat.displayName}',
                  style: const TextStyle(
                    color: _success,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _copyOutput,
                icon: const Icon(
                  Icons.copy_rounded,
                  size: 16,
                  color: _accentB,
                ),
                label: Text(
                  context.t('envmanager_copy'),
                  style: const TextStyle(color: _accentB, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _GlassCard(
            padding: const EdgeInsets.all(14),
            child: SelectableText(
              _output,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.55,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String labelKey,
  }) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 8),
        Text(
          context.t(labelKey),
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _optionSwitch({
    required String labelKey,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              context.t(labelKey),
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: _accentB,
            activeTrackColor: _accentB.withOpacity(0.4),
            inactiveThumbColor: Colors.white54,
            inactiveTrackColor: Colors.white.withOpacity(0.1),
          ),
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