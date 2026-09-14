import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/app_localization.dart';
import 'explainer.dart';
import 'models.dart';

const Color _accentA = Color(0xFF7C4DFF);
const Color _accentB = Color(0xFF00E5FF);
const Color _danger = Color(0xFFFF5C5C);
const Color _warning = Color(0xFFFFC24B);
const Color _success = Color(0xFF4BD68B);
const Color _bgTop = Color(0xFF1B1035);
const Color _bgMid = Color(0xFF2A1550);
const Color _bgBot = Color(0xFF0F2A4A);

class RegexBuilder extends StatefulWidget {
  const RegexBuilder({super.key});

  @override
  State<RegexBuilder> createState() => _RegexBuilderState();
}

class _RegexBuilderState extends State<RegexBuilder>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final TextEditingController _patternCtrl = TextEditingController();
  final TextEditingController _testCtrl = TextEditingController();
  final FocusNode _patternFocus = FocusNode();

  final Set<RegexFlag> _flags = <RegexFlag>{};
  RegexTestResult _result = RegexTestResult.empty;

  String _pattern = '';
  int _selectedMatchIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _patternCtrl.addListener(_onPatternChanged);
    _testCtrl.addListener(_runTest);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _patternCtrl.removeListener(_onPatternChanged);
    _testCtrl.removeListener(_runTest);
    _patternCtrl.dispose();
    _testCtrl.dispose();
    _patternFocus.dispose();
    super.dispose();
  }

  void _onPatternChanged() {
    setState(() => _pattern = _patternCtrl.text);
    _runTest();
  }

  void _runTest() {
    final String pattern = _patternCtrl.text;
    final String input = _testCtrl.text;

    if (pattern.isEmpty) {
      setState(() {
        _result = RegexTestResult.empty;
        _selectedMatchIndex = 0;
      });
      return;
    }

    if (input.isEmpty) {
      setState(() {
        _result = RegexTestResult.empty;
        _selectedMatchIndex = 0;
      });
      return;
    }

    final String flags = _flags.map((RegexFlag f) => f.label).join();

    final Stopwatch sw = Stopwatch()..start();

    try {
      final RegExp re = RegExp(pattern, multiLine: flags.contains('m'));

      final List<RegexMatchInfo> matches = <RegexMatchInfo>[];
      int groupTotal = 0;

      for (final RegExpMatch m in re.allMatches(input)) {
        final List<MatchGroupInfo> groups = <MatchGroupInfo>[];
        final Map<String, MatchGroupInfo> named = <String, MatchGroupInfo>{};

        for (int i = 0; i < m.groupCount + 1; i++) {
          final String? value = m.group(i);
          final int? start = value == null ? null : m.start;
          final int? end = value == null ? null : m.end;
          groups.add(
            MatchGroupInfo(
              index: i,
              value: value,
              start: i == 0 ? m.start : null,
              end: i == 0 ? m.end : null,
            ),
          );
          if (start != null && end != null) {
            groupTotal = groupTotal > i ? groupTotal : i;
          }
        }

        for (final String name in m.groupNames) {
          final String? value = m.namedGroup(name);
          named[name] = MatchGroupInfo(
            index: -1,
            value: value,
            name: name,
          );
        }

        matches.add(
          RegexMatchInfo(
            index: matches.length,
            start: m.start,
            end: m.end,
            value: m.group(0) ?? '',
            groups: groups,
            namedGroups: named,
          ),
        );
      }

      sw.stop();

      setState(() {
        _result = RegexTestResult(
          matches: matches,
          durationMicros: sw.elapsedMicroseconds,
          totalGroups: groupTotal,
        );
        if (_selectedMatchIndex >= matches.length) {
          _selectedMatchIndex = 0;
        }
      });
    } on FormatException catch (e) {
      sw.stop();
      setState(() {
        _result = RegexTestResult(
          errorKey: 'regexbuilder_error_invalid_pattern',
          errorDetail: e.message,
          durationMicros: sw.elapsedMicroseconds,
        );
      });
    } catch (e) {
      sw.stop();
      setState(() {
        _result = RegexTestResult(
          errorKey: 'regexbuilder_error_unknown',
          errorDetail: e.toString(),
          durationMicros: sw.elapsedMicroseconds,
        );
      });
    }
  }

  void _insertSnippet(PaletteItem item) {
    final TextEditingValue value = _patternCtrl.value;
    final TextSelection sel = value.selection;

    final String text = value.text;
    final int start = sel.start >= 0 ? sel.start : text.length;
    final int end = sel.end >= 0 ? sel.end : text.length;

    final String newText =
        text.substring(0, start) + item.snippet + text.substring(end);

    int newCursor;
    if (item.cursorOffset > 0) {
      newCursor = start + item.cursorOffset;
    } else {
      newCursor = start + item.snippet.length;
    }

    _patternCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
    _patternFocus.requestFocus();
  }

  void _toggleFlag(RegexFlag flag) {
    setState(() {
      if (_flags.contains(flag)) {
        _flags.remove(flag);
      } else {
        _flags.add(flag);
      }
    });
    _runTest();
  }

  void _clearAll() {
    setState(() {
      _patternCtrl.clear();
      _testCtrl.clear();
      _flags.clear();
      _result = RegexTestResult.empty;
      _selectedMatchIndex = 0;
    });
  }

  Future<void> _copy(String text) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    _showSnack(context.t('regexbuilder_copied'));
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
        title: Text(context.t('regexbuilder_title')),
        actions: <Widget>[
          _glassIconButton(
            icon: Icons.copy_rounded,
            tooltip: context.t('regexbuilder_copy_pattern'),
            onTap: () => _copy(_patternCtrl.text),
          ),
          _glassIconButton(
            icon: Icons.cleaning_services_outlined,
            tooltip: context.t('regexbuilder_clear'),
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
                    _buildBuilderTab(),
                    _buildMatchesTab(),
                    _buildExplainTab(),
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
              Tab(text: context.t('regexbuilder_tab_builder')),
              Tab(text: context.t('regexbuilder_tab_matches')),
              Tab(text: context.t('regexbuilder_tab_explain')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBuilderTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _patternCard(),
          const SizedBox(height: 16),
          _flagsCard(),
          const SizedBox(height: 16),
          _testInputCard(),
          const SizedBox(height: 16),
          _statusCard(),
          const SizedBox(height: 16),
          for (final PaletteCategory cat in kRegexPalette) ...<Widget>[
            _paletteCategoryCard(cat),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _patternCard() {
    final bool hasError = _result.hasError;

    return _GlassCard(
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
                context.t('regexbuilder_pattern'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${_pattern.length}',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasError
                    ? _danger.withOpacity(0.6)
                    : _accentB.withOpacity(0.35),
              ),
            ),
            child: Row(
              children: <Widget>[
                Text(
                  '/',
                  style: TextStyle(
                    color: _accentB,
                    fontFamily: 'monospace',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: _patternCtrl,
                    focusNode: _patternFocus,
                    maxLines: 3,
                    minLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                    decoration: InputDecoration(
                      hintText: context.t('regexbuilder_pattern_hint'),
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '/${_flags.map((RegexFlag f) => f.label).join()}',
                  style: TextStyle(
                    color: _accentB,
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _flagsCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.flag_outlined,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 8),
              Text(
                context.t('regexbuilder_flags'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: RegexFlag.values.map((RegexFlag f) {
              final bool selected = _flags.contains(f);
              return GestureDetector(
                onTap: () => _toggleFlag(f),
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
                    color: selected
                        ? null
                        : Colors.white.withOpacity(0.06),
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
                      Text(
                        f.label,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        context.t(f.labelKey),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _testInputCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.article_outlined,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 8),
              Text(
                context.t('regexbuilder_test_text'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${_testCtrl.text.length}',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _testCtrl,
            maxLines: 6,
            minLines: 4,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: 12,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: context.t('regexbuilder_test_hint'),
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontFamily: 'monospace',
                fontSize: 12,
              ),
              isDense: true,
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                BorderSide(color: Colors.white.withOpacity(0.15)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                BorderSide(color: Colors.white.withOpacity(0.15)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                const BorderSide(color: _accentB, width: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard() {
    if (_result.hasError) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _danger.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _danger.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.error_outline,
                  size: 16,
                  color: _danger,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.t(_result.errorKey!),
                    style: const TextStyle(
                      color: Color(0xFFFF8A8A),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            if (_result.errorDetail != null &&
                _result.errorDetail!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                _result.errorDetail!,
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

    if (_patternCtrl.text.isEmpty) {
      return const SizedBox.shrink();
    }

    final int count = _result.matches.length;
    final Color color = count > 0 ? _success : _warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            count > 0
                ? Icons.check_circle_rounded
                : Icons.info_outline_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              count == 0
                  ? context.t('regexbuilder_no_matches')
                  : '$count ${context.t('regexbuilder_matches')}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            _result.prettyDuration,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _paletteCategoryCard(PaletteCategory cat) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(cat.icon, size: 16, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                context.t(cat.labelKey),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: cat.items.map((PaletteItem item) {
              return Tooltip(
                message: context.t(item.descriptionKey),
                child: GestureDetector(
                  onTap: () => _insertSnippet(item),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesTab() {
    if (_result.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: _danger,
              ),
              const SizedBox(height: 12),
              Text(
                context.t(_result.errorKey!),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    if (_result.matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.search_off_rounded,
                size: 48,
                color: Colors.white.withOpacity(0.25),
              ),
              const SizedBox(height: 12),
              Text(
                context.t('regexbuilder_no_matches_hint'),
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
          _highlightedPreview(),
          const SizedBox(height: 16),
          _matchListCard(),
          if (_selectedMatchIndex < _result.matches.length) ...<Widget>[
            const SizedBox(height: 16),
            _matchDetailCard(_result.matches[_selectedMatchIndex]),
          ],
        ],
      ),
    );
  }

  Widget _highlightedPreview() {
    final String input = _testCtrl.text;
    if (input.isEmpty) return const SizedBox.shrink();

    final List<TextSpan> spans = <TextSpan>[];
    int cursor = 0;

    for (int i = 0; i < _result.matches.length; i++) {
      final RegexMatchInfo m = _result.matches[i];
      if (m.start > cursor) {
        spans.add(
          TextSpan(
            text: input.substring(cursor, m.start),
            style: const TextStyle(color: Colors.white70),
          ),
        );
      }
      final bool selected = i == _selectedMatchIndex;
      final Color bg = selected
          ? _accentB.withOpacity(0.5)
          : _accentA.withOpacity(0.35);
      spans.add(
        TextSpan(
          text: input.substring(m.start, m.end),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            backgroundColor: bg,
          ),
        ),
      );
      cursor = m.end;
    }
    if (cursor < input.length) {
      spans.add(
        TextSpan(
          text: input.substring(cursor),
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.visibility_rounded,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 8),
              Text(
                context.t('regexbuilder_highlighted'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SelectableText.rich(
              TextSpan(
                children: spans,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _matchListCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.list_alt_rounded,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 8),
              Text(
                context.t('regexbuilder_match_list'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${_result.matches.length}',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < _result.matches.length; i++) ...<Widget>[
            _matchRow(_result.matches[i], i),
            if (i < _result.matches.length - 1)
              const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Widget _matchRow(RegexMatchInfo m, int index) {
    final bool selected = index == _selectedMatchIndex;
    return GestureDetector(
      onTap: () => setState(() => _selectedMatchIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? _accentB.withOpacity(0.15)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? _accentB.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: _accentA.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '#${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                m.value,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '[${m.start}..${m.end}]',
              style: const TextStyle(
                color: Colors.white54,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _matchDetailCard(RegexMatchInfo m) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 8),
              Text(
                '#${m.index + 1} ${context.t('regexbuilder_match_detail')}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${m.length} ${context.t('regexbuilder_chars')}',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _detailRow(
            label: context.t('regexbuilder_full_match'),
            value: m.value,
            highlight: true,
          ),
          if (m.groups.length > 1) ...<Widget>[
            const SizedBox(height: 8),
            for (int i = 1; i < m.groups.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _detailRow(
                  label: '${context.t('regexbuilder_group')} $i',
                  value: m.groups[i].value ?? '(no match)',
                  muted: m.groups[i].value == null,
                ),
              ),
          ],
          if (m.namedGroups.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            for (final MapEntry<String, MatchGroupInfo> e
            in m.namedGroups.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _detailRow(
                  label: '${context.t('regexbuilder_named')}: ${e.key}',
                  value: e.value.value ?? '(no match)',
                  muted: e.value.value == null,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow({
    required String label,
    required String value,
    bool highlight = false,
    bool muted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: _accentB,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                color: muted
                    ? Colors.white38
                    : highlight
                    ? _success
                    : Colors.white,
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight:
                highlight ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplainTab() {
    final String pattern = _patternCtrl.text;
    if (pattern.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.menu_book_rounded,
                size: 48,
                color: Colors.white.withOpacity(0.25),
              ),
              const SizedBox(height: 12),
              Text(
                context.t('regexbuilder_explain_empty'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      );
    }

    final List<ExplainLine> lines = RegexExplainer.explain(pattern);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.menu_book_rounded,
                  size: 16,
                  color: Colors.white70,
                ),
                const SizedBox(width: 8),
                Text(
                  context.t('regexbuilder_explain'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${lines.length}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final ExplainLine line in lines) _explainRow(line),
          ],
        ),
      ),
    );
  }

  Widget _explainRow(ExplainLine line) {
    return Padding(
      padding: EdgeInsets.only(
        left: line.depth * 16.0,
        bottom: 6,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: _accentA.withOpacity(0.25),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _accentA.withOpacity(0.5),
                ),
              ),
              child: Text(
                line.token,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    context.t(line.descriptionKey),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  if (line.detail != null) ...<Widget>[
                    const SizedBox(height: 3),
                    Text(
                      line.detail!,
                      style: const TextStyle(
                        color: _accentB,
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
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