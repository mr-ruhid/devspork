
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/app_localization.dart';
import 'local_formatter.dart';
import 'models.dart';
import 'remote_formatter.dart';

const Color _accentA = Color(0xFF7C4DFF);
const Color _accentB = Color(0xFF00E5FF);
const Color _danger = Color(0xFFFF5C5C);
const Color _warning = Color(0xFFFFC24B);
const Color _success = Color(0xFF4BD68B);
const Color _bgTop = Color(0xFF1B1035);
const Color _bgMid = Color(0xFF2A1550);
const Color _bgBot = Color(0xFF0F2A4A);

class CodeFmt extends StatefulWidget {
  const CodeFmt({super.key});

  @override
  State<CodeFmt> createState() => _CodeFmtState();
}

class _CodeFmtState extends State<CodeFmt>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final TextEditingController _inputCtrl = TextEditingController();
  final FormatOptions _options = FormatOptions();

  CodeLanguage _language = CodeLanguage.json;
  FormatResult _result = FormatResult.empty;
  bool _loading = false;
  bool? _remoteOnline;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkRemote();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inputCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkRemote() async {
    final bool online = await RemoteFormatter.ping();
    if (!mounted) return;
    setState(() => _remoteOnline = online);
  }

  Future<void> _format() async {
    FocusScope.of(context).unfocus();

    final String input = _inputCtrl.text;
    if (input.trim().isEmpty) {
      setState(() {
        _result = const FormatResult(errorKey: 'codefmt_error_empty');
      });
      return;
    }

    setState(() {
      _loading = true;
      _result = FormatResult.empty;
    });

    FormatResult result;
    if (_language.isRemote) {
      result = await RemoteFormatter.format(input, _language, _options);
    } else {
      result = LocalFormatter.format(input, _language, _options);
    }

    if (!mounted) return;

    setState(() {
      _result = result;
      _loading = false;
    });

    if (!result.hasError) {
      _tabController.animateTo(1);
    }
  }

  void _onLanguageChanged(CodeLanguage lang) {
    setState(() {
      _language = lang;
      _result = FormatResult.empty;
    });
  }

  Future<void> _pasteInput() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null || data.text!.isEmpty) return;
    setState(() {
      _inputCtrl.text = data.text!;
      _result = FormatResult.empty;
    });
  }

  void _clearAll() {
    setState(() {
      _inputCtrl.clear();
      _result = FormatResult.empty;
    });
  }

  Future<void> _copyOutput() async {
    if (_result.output.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _result.output));
    if (!mounted) return;
    _showSnack(context.t('codefmt_copied'));
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
        title: Text(context.t('codefmt_title')),
        actions: <Widget>[
          _glassIconButton(
            icon: Icons.content_paste_rounded,
            tooltip: context.t('codefmt_paste'),
            onTap: _pasteInput,
          ),
          _glassIconButton(
            icon: Icons.cleaning_services_outlined,
            tooltip: context.t('codefmt_clear'),
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
              Tab(text: context.t('codefmt_tab_input')),
              Tab(text: context.t('codefmt_tab_output')),
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
                  icon: Icons.code_rounded,
                  labelKey: 'codefmt_language',
                  trailing: _language.isRemote ? _remoteStatus() : null,
                ),
                const SizedBox(height: 12),
                _languageSelector(),
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
                  labelKey: 'codefmt_options',
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.space_bar_rounded,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.t('codefmt_indent_size'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    _chipGroup<int>(
                      values: const <int>[2, 4, 8],
                      current: _options.indentSize,
                      labelFor: (int v) => '$v',
                      onChanged: (int v) => setState(
                            () => _options.indentSize = v,
                      ),
                    ),
                  ],
                ),
                _optionSwitch(
                  labelKey: 'codefmt_use_tabs',
                  value: _options.useTabs,
                  onChanged: (bool v) =>
                      setState(() => _options.useTabs = v),
                ),
                if (_language == CodeLanguage.json)
                  _optionSwitch(
                    labelKey: 'codefmt_sort_keys',
                    value: _options.sortKeys,
                    onChanged: (bool v) =>
                        setState(() => _options.sortKeys = v),
                  ),
                if (_language != CodeLanguage.yaml)
                  _optionSwitch(
                    labelKey: 'codefmt_minify',
                    value: _options.minify,
                    onChanged: (bool v) =>
                        setState(() => _options.minify = v),
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
                  labelKey: 'codefmt_input',
                ),
                const SizedBox(height: 10),
                _glassTextField(
                  controller: _inputCtrl,
                  hint: _language.hint,
                  maxLines: 14,
                  minLines: 8,
                  monospace: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _formatButton(),
          if (_result.hasError) ...<Widget>[
            const SizedBox(height: 14),
            _errorBox(_result.errorKey!, _result.errorDetail),
          ],
        ],
      ),
    );
  }

  Widget _remoteStatus() {
    final bool? online = _remoteOnline;
    if (online == null) {
      return const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white54,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (online ? _success : _danger).withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: (online ? _success : _danger).withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: online ? _success : _danger,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            context.t(online ? 'codefmt_remote_online' : 'codefmt_remote_offline'),
            style: TextStyle(
              color: online ? _success : _danger,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _languageSelector() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: CodeLanguage.values.map((CodeLanguage l) {
        final bool selected = _language == l;
        return GestureDetector(
          onTap: () => _onLanguageChanged(l),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (l.isRemote) ...<Widget>[
                  Icon(
                    Icons.cloud_outlined,
                    size: 12,
                    color: selected ? Colors.white : _accentB,
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  l.displayName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _formatButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _loading ? null : _format,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: _loading
                  ? LinearGradient(
                colors: <Color>[
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.1),
                ],
              )
                  : const LinearGradient(
                colors: <Color>[_accentA, _accentB],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (_loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  const Icon(
                    Icons.auto_fix_high_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                const SizedBox(width: 10),
                Text(
                  _loading
                      ? context.t('codefmt_formatting')
                      : context.t('codefmt_format'),
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

  Widget _buildOutputTab() {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            color: _accentB,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (_result.hasError) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        child: _errorBox(_result.errorKey!, _result.errorDetail),
      );
    }

    if (_result.isEmpty) {
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
                context.t('codefmt_no_output'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      );
    }

    final int inLines = _inputCtrl.text.split('\n').length;
    final int outLines = _result.output.split('\n').length;
    final int delta = outLines - inLines;

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
                  _language.displayName,
                  style: const TextStyle(
                    color: _success,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$inLines → $outLines '
                    '${context.t('codefmt_lines')}',
                style: TextStyle(
                  color: delta == 0
                      ? Colors.white54
                      : (delta > 0 ? _accentB : _warning),
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 8),
              if (_result.durationMs > 0)
                Text(
                  '${_result.durationMs}ms',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontFamily: 'monospace',
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
                  context.t('codefmt_copy'),
                  style: const TextStyle(color: _accentB, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _GlassCard(
            padding: const EdgeInsets.all(14),
            child: SelectableText(
              _result.output,
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

  Widget _chipGroup<T>({
    required List<T> values,
    required T current,
    required String Function(T) labelFor,
    required ValueChanged<T> onChanged,
  }) {
    return Wrap(
      spacing: 4,
      children: values.map((T v) {
        final bool selected = v == current;
        return GestureDetector(
          onTap: () => onChanged(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(
                colors: <Color>[_accentA, _accentB],
              )
                  : null,
              color: selected ? null : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : Colors.white.withOpacity(0.15),
              ),
            ),
            child: Text(
              labelFor(v),
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 11,
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

  Widget _glassTextField({
    required TextEditingController controller,
    required String hint,
    int? maxLines = 1,
    int? minLines,
    bool monospace = false,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      style: TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontFamily: monospace ? 'monospace' : null,
        height: 1.5,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 11,
          fontFamily: monospace ? 'monospace' : null,
        ),
        isDense: true,
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        contentPadding: const EdgeInsets.all(12),
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