import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/app_localization.dart';
import 'analyzer.dart';
import 'generator.dart';
import 'models.dart';

const Color _accentA = Color(0xFF7C4DFF);
const Color _accentB = Color(0xFF00E5FF);
const Color _danger = Color(0xFFFF5C5C);
const Color _success = Color(0xFF4BD68B);
const Color _bgTop = Color(0xFF1B1035);
const Color _bgMid = Color(0xFF2A1550);
const Color _bgBot = Color(0xFF0F2A4A);

class JsonCodeGen extends StatefulWidget {
  const JsonCodeGen({super.key});

  @override
  State<JsonCodeGen> createState() => _JsonCodeGenState();
}

class _JsonCodeGenState extends State<JsonCodeGen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final TextEditingController _jsonCtrl = TextEditingController();
  final TextEditingController _classCtrl =
  TextEditingController(text: 'Root');
  final TextEditingController _packageCtrl =
  TextEditingController(text: 'com.example');

  CodeLanguage _language = CodeLanguage.dart;
  final GenerationOptions _options = GenerationOptions();

  String _output = '';
  String? _errorKey;
  String? _errorDetail;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _jsonCtrl.dispose();
    _classCtrl.dispose();
    _packageCtrl.dispose();
    super.dispose();
  }

  void _onLanguageChanged(CodeLanguage lang) {
    setState(() {
      _language = lang;
      _options.resetFor(lang);
    });
  }

  Future<void> _generate() async {
    FocusScope.of(context).unfocus();

    final String input = _jsonCtrl.text.trim();
    if (input.isEmpty) {
      setState(() {
        _errorKey = 'jsoncodegen_error_empty';
        _errorDetail = null;
        _output = '';
      });
      return;
    }

    try {
      jsonDecode(input);
    } catch (e) {
      setState(() {
        _errorKey = 'jsoncodegen_error_invalid';
        _errorDetail = e.toString();
        _output = '';
      });
      return;
    }

    final String className = _classCtrl.text.trim().isEmpty
        ? 'Root'
        : _classCtrl.text.trim();

    _options.rootClassName = className;
    _options.packageName = _packageCtrl.text.trim().isEmpty
        ? 'com.example'
        : _packageCtrl.text.trim();

    try {
      final Analyzer analyzer = Analyzer(
        rootClassName: className,
        caseStyle: NameCase.camel,
      );
      final AnalysisResult result = analyzer.analyze(input);

      if (result.isEmpty) {
        setState(() {
          _errorKey = 'jsoncodegen_error_empty_result';
          _errorDetail = null;
          _output = '';
        });
        return;
      }

      final CodeGenerator generator = CodeGenerator(
        result: result,
        language: _language,
        options: _options,
      );
      final String code = generator.generate();

      setState(() {
        _output = code;
        _errorKey = null;
        _errorDetail = null;
      });
      _tabController.animateTo(1);
    } catch (e) {
      setState(() {
        _errorKey = 'jsoncodegen_error_unknown';
        _errorDetail = e.toString();
        _output = '';
      });
    }
  }

  Future<void> _copyOutput() async {
    if (_output.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _output));
    if (!mounted) return;
    _showSnack(context.t('jsoncodegen_copied'));
  }

  Future<void> _pasteJson() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null || data.text!.isEmpty) return;
    setState(() {
      _jsonCtrl.text = data.text!;
      _errorKey = null;
      _errorDetail = null;
    });
  }

  void _clear() {
    setState(() {
      _jsonCtrl.clear();
      _output = '';
      _errorKey = null;
      _errorDetail = null;
    });
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
        title: Text(context.t('jsoncodegen_title')),
        actions: <Widget>[
          _glassIconButton(
            icon: Icons.content_paste_rounded,
            tooltip: context.t('jsoncodegen_paste'),
            onTap: _pasteJson,
          ),
          _glassIconButton(
            icon: Icons.cleaning_services_outlined,
            tooltip: context.t('jsoncodegen_clear'),
            onTap: _clear,
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
              Tab(text: context.t('jsoncodegen_tab_input')),
              Tab(text: context.t('jsoncodegen_tab_output')),
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
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.code_rounded,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.t('jsoncodegen_language'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.text_fields_rounded,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.t('jsoncodegen_root_class'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _glassTextField(
                  controller: _classCtrl,
                  hint: 'Root',
                ),
                if (_language.supportsPackage) ...<Widget>[
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.folder_outlined,
                        size: 16,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.t('jsoncodegen_package'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _glassTextField(
                    controller: _packageCtrl,
                    hint: 'com.example',
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
                    const Icon(
                      Icons.tune_rounded,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.t('jsoncodegen_options'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_language.supportsNullSafety)
                  _optionSwitch(
                    labelKey: 'jsoncodegen_opt_null_safety',
                    value: _options.nullSafety,
                    onChanged: (bool v) =>
                        setState(() => _options.nullSafety = v),
                  ),
                if (_language.supportsImmutable)
                  _optionSwitch(
                    labelKey: 'jsoncodegen_opt_immutable',
                    value: _options.immutable,
                    onChanged: (bool v) =>
                        setState(() => _options.immutable = v),
                  ),
                if (_language.supportsFromJson)
                  _optionSwitch(
                    labelKey: 'jsoncodegen_opt_from_json',
                    value: _options.generateFromJson,
                    onChanged: (bool v) =>
                        setState(() => _options.generateFromJson = v),
                  ),
                if (_language.supportsToJson)
                  _optionSwitch(
                    labelKey: 'jsoncodegen_opt_to_json',
                    value: _options.generateToJson,
                    onChanged: (bool v) =>
                        setState(() => _options.generateToJson = v),
                  ),
                if (_language.supportsCopyWith)
                  _optionSwitch(
                    labelKey: 'jsoncodegen_opt_copy_with',
                    value: _options.generateCopyWith,
                    onChanged: (bool v) =>
                        setState(() => _options.generateCopyWith = v),
                  ),
                if (_language.supportsEquatable)
                  _optionSwitch(
                    labelKey: 'jsoncodegen_opt_equatable',
                    value: _options.generateEquatable,
                    onChanged: (bool v) =>
                        setState(() => _options.generateEquatable = v),
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
                      Icons.data_object_rounded,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.t('jsoncodegen_json_input'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _glassTextField(
                  controller: _jsonCtrl,
                  hint: '{\n  "id": 1,\n  "name": "John"\n}',
                  maxLines: 14,
                  minLines: 8,
                  monospace: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _generateButton(),
          if (_errorKey != null) ...<Widget>[
            const SizedBox(height: 14),
            _errorBox(),
          ],
        ],
      ),
    );
  }

  Widget _languageSelector() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: CodeLanguage.values.map((CodeLanguage lang) {
        final bool selected = _language == lang;
        return GestureDetector(
          onTap: () => _onLanguageChanged(lang),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              lang.displayName,
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

  Widget _generateButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _generate,
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
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  context.t('jsoncodegen_generate'),
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

  Widget _errorBox() {
    return Container(
      width: double.infinity,
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
                  context.t(_errorKey!),
                  style: const TextStyle(
                    color: Color(0xFFFF8A8A),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          if (_errorDetail != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              _errorDetail!,
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
                context.t('jsoncodegen_no_output'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
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
              const Spacer(),
              TextButton.icon(
                onPressed: _copyOutput,
                icon: const Icon(
                  Icons.copy_rounded,
                  size: 16,
                  color: _accentB,
                ),
                label: Text(
                  context.t('jsoncodegen_copy'),
                  style: const TextStyle(color: _accentB, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: _GlassCard(
              padding: const EdgeInsets.all(14),
              child: SelectableText(
                _output,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  height: 1.55,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
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
        fontSize: 13,
        fontFamily: monospace ? 'monospace' : null,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.35),
          fontSize: 12,
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