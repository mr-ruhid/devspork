import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/app_localization.dart';
import 'generator.dart';
import 'models.dart';

const Color _accentA = Color(0xFF7C4DFF);
const Color _accentB = Color(0xFF00E5FF);
const Color _danger = Color(0xFFFF5C5C);
const Color _success = Color(0xFF4BD68B);
const Color _warning = Color(0xFFFFC24B);
const Color _bgTop = Color(0xFF1B1035);
const Color _bgMid = Color(0xFF2A1550);
const Color _bgBot = Color(0xFF0F2A4A);

class CronBuilder extends StatefulWidget {
  const CronBuilder({super.key});

  @override
  State<CronBuilder> createState() => _CronBuilderState();
}

class _CronBuilderState extends State<CronBuilder>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final TextEditingController _exprCtrl =
  TextEditingController(text: '* * * * *');

  final Map<CronField, CronFieldConfig> _configs =
  <CronField, CronFieldConfig>{};

  String _expression = '* * * * *';
  String _description = '';
  bool _valid = true;
  String? _exprErrorKey;

  List<DateTime> _nextRuns = <DateTime>[];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    for (final CronField f in CronField.values) {
      _configs[f] = CronFieldConfig(field: f);
    }

    _rebuild();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _exprCtrl.dispose();
    super.dispose();
  }

  void _rebuild() {
    final String expr = CronGenerator.build(_configs);
    final bool valid = CronGenerator.isValid(expr);
    final List<DateTime> runs = valid
        ? CronGenerator.nextRuns(_configs, DateTime.now(), count: 10)
        : <DateTime>[];

    setState(() {
      _expression = expr;
      _exprCtrl.text = expr;
      _description = valid ? CronGenerator.describe(_configs) : '';
      _valid = valid;
      _exprErrorKey = valid ? null : 'cronbuilder_error_invalid';
      _nextRuns = runs;
    });
  }

  void _applyExpression(String raw) {
    final String trimmed = raw.trim();
    if (!CronGenerator.isValid(trimmed)) {
      setState(() {
        _expression = trimmed;
        _exprErrorKey = 'cronbuilder_error_invalid';
        _valid = false;
        _description = '';
        _nextRuns = <DateTime>[];
      });
      return;
    }

    final Map<CronField, CronFieldConfig> parsed =
    CronGenerator.parse(trimmed);

    setState(() {
      _configs.clear();
      _configs.addAll(parsed);
      _expression = trimmed;
      _exprCtrl.text = trimmed;
      _description = CronGenerator.describe(_configs);
      _valid = true;
      _exprErrorKey = null;
      _nextRuns = CronGenerator.nextRuns(
        _configs,
        DateTime.now(),
        count: 10,
      );
    });
  }

  void _applyPreset(CronPreset preset) {
    _applyExpression(preset.expression);
    _tabController.animateTo(0);
  }

  void _setMode(CronField field, CronFieldMode mode) {
    final CronFieldConfig c = _configs[field]!;
    if (c.mode == mode) return;
    c.mode = mode;
    if (mode == CronFieldMode.list && c.listValues.isEmpty) {
      c.listValues = <int>[field.minValue];
    }
    _rebuild();
  }

  void _setSpecific(CronField field, int value) {
    _configs[field]!.specificValue = value;
    _rebuild();
  }

  void _setRangeFrom(CronField field, int value) {
    final CronFieldConfig c = _configs[field]!;
    c.rangeFrom = value;
    if (c.rangeTo < value) c.rangeTo = value;
    _rebuild();
  }

  void _setRangeTo(CronField field, int value) {
    final CronFieldConfig c = _configs[field]!;
    c.rangeTo = value;
    if (c.rangeFrom > value) c.rangeFrom = value;
    _rebuild();
  }

  void _setStepEvery(CronField field, int value) {
    _configs[field]!.stepEvery = value < 1 ? 1 : value;
    _rebuild();
  }

  void _setStepFrom(CronField field, int value) {
    _configs[field]!.stepFrom = value;
    _rebuild();
  }

  void _toggleListValue(CronField field, int value) {
    final CronFieldConfig c = _configs[field]!;
    final List<int> list = List<int>.from(c.listValues);
    if (list.contains(value)) {
      if (list.length <= 1) return;
      list.remove(value);
    } else {
      list.add(value);
    }
    c.listValues = list;
    _rebuild();
  }

  void _resetAll() {
    setState(() {
      _configs.clear();
      for (final CronField f in CronField.values) {
        _configs[f] = CronFieldConfig(field: f);
      }
    });
    _rebuild();
  }

  Future<void> _copy(String text) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    _showSnack(context.t('cronbuilder_copied'));
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

  String _formatDateTime(DateTime dt) {
    final String day = _two(dt.day);
    final String month = _two(dt.month);
    final String year = dt.year.toString();
    final String h = _two(dt.hour);
    final String m = _two(dt.minute);
    final String wd = kDayNames[
    dt.weekday == 7 ? 0 : dt.weekday] ??
        '';
    return '$year-$month-$day ($wd) $h:$m';
  }

  String _two(int n) => n < 10 ? '0$n' : '$n';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.t('cronbuilder_title')),
        actions: <Widget>[
          _glassIconButton(
            icon: Icons.refresh_rounded,
            tooltip: context.t('cronbuilder_reset'),
            onTap: _resetAll,
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
                    _buildPresetsTab(),
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
              Tab(text: context.t('cronbuilder_tab_builder')),
              Tab(text: context.t('cronbuilder_tab_presets')),
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
          _expressionCard(),
          const SizedBox(height: 16),
          for (final CronField f in CronField.values) ...<Widget>[
            _fieldCard(f),
            const SizedBox(height: 12),
          ],
          _nextRunsCard(),
        ],
      ),
    );
  }

  Widget _expressionCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                _valid
                    ? Icons.check_circle_outline_rounded
                    : Icons.error_outline_rounded,
                size: 18,
                color: _valid ? _success : _danger,
              ),
              const SizedBox(width: 8),
              Text(
                context.t('cronbuilder_expression'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _glassIconButton(
                icon: Icons.copy_rounded,
                tooltip: context.t('cronbuilder_copy'),
                onTap: () => _copy(_expression),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _exprCtrl,
            onSubmitted: _applyExpression,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Colors.black.withOpacity(0.35),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                BorderSide(color: Colors.white.withOpacity(0.15)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _valid
                      ? _accentB.withOpacity(0.4)
                      : _danger.withOpacity(0.6),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _valid ? _accentB : _danger,
                  width: 1.5,
                ),
              ),
            ),
          ),
          if (_description.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _accentB.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _accentB.withOpacity(0.3)),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.translate_rounded,
                    size: 14,
                    color: _accentB,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_exprErrorKey != null) ...<Widget>[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _danger.withOpacity(0.4)),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.error_outline,
                    size: 14,
                    color: _danger,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.t(_exprErrorKey!),
                      style: const TextStyle(
                        color: Color(0xFFFFBFBF),
                        fontSize: 12,
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

  Widget _fieldCard(CronField field) {
    final CronFieldConfig c = _configs[field]!;
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
                  field.shortLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.t(field.labelKey),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                CronGenerator.build(<CronField, CronFieldConfig>{
                  field: c,
                }).split(' ')[0],
                style: const TextStyle(
                  color: _accentB,
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _modeSelector(field, c),
          const SizedBox(height: 10),
          _modeContent(field, c),
        ],
      ),
    );
  }

  Widget _modeSelector(CronField field, CronFieldConfig c) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: CronFieldMode.values.map((CronFieldMode mode) {
        final bool selected = c.mode == mode;
        return GestureDetector(
          onTap: () => _setMode(field, mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
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
              context.t(mode.labelKey),
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _modeContent(CronField field, CronFieldConfig c) {
    switch (c.mode) {
      case CronFieldMode.any:
        return const SizedBox.shrink();
      case CronFieldMode.specific:
        return _numericSelector(
          field: field,
          value: c.specificValue,
          onChanged: (int v) => _setSpecific(field, v),
          labelled: field == CronField.month || field == CronField.dayOfWeek,
        );
      case CronFieldMode.range:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${context.t('cronbuilder_from')}: ${c.rangeFrom}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${context.t('cronbuilder_to')}: ${c.rangeTo}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _rangeSlider(
              field: field,
              from: c.rangeFrom,
              to: c.rangeTo,
              onChanged: (RangeValues r) {
                _configs[field]!
                  ..rangeFrom = r.start.round()
                  ..rangeTo = r.end.round();
                _rebuild();
              },
            ),
          ],
        );
      case CronFieldMode.step:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${context.t('cronbuilder_every')} ${c.stepEvery}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${context.t('cronbuilder_start')}: ${c.stepFrom}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Slider(
              value: c.stepEvery.toDouble().clamp(
                field.minValue.toDouble(),
                field.maxValue.toDouble(),
              ),
              min: 1,
              max: field.maxValue.toDouble(),
              divisions: field.maxValue - 1,
              activeColor: _accentB,
              inactiveColor: Colors.white.withOpacity(0.1),
              onChanged: (double v) => _setStepEvery(field, v.round()),
            ),
            Slider(
              value: c.stepFrom.toDouble().clamp(
                field.minValue.toDouble(),
                field.maxValue.toDouble(),
              ),
              min: field.minValue.toDouble(),
              max: field.maxValue.toDouble(),
              divisions:
              field.maxValue - field.minValue > 0
                  ? field.maxValue - field.minValue
                  : null,
              activeColor: _accentA,
              inactiveColor: Colors.white.withOpacity(0.1),
              onChanged: (double v) => _setStepFrom(field, v.round()),
            ),
          ],
        );
      case CronFieldMode.list:
        return _multiSelector(
          field: field,
          selected: c.listValues,
          onToggle: (int v) => _toggleListValue(field, v),
        );
    }
  }

  Widget _rangeSlider({
    required CronField field,
    required int from,
    required int to,
    required ValueChanged<RangeValues> onChanged,
  }) {
    final double min = field.minValue.toDouble();
    final double max = field.maxValue.toDouble();
    final int divisions = field.maxValue - field.minValue;
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: _accentB,
        inactiveTrackColor: Colors.white.withOpacity(0.1),
        rangeThumbShape: const RoundRangeSliderThumbShape(
          enabledThumbRadius: 10,
        ),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
      ),
      child: RangeSlider(
        values: RangeValues(
          from.toDouble().clamp(min, max),
          to.toDouble().clamp(min, max),
        ),
        min: min,
        max: max,
        divisions: divisions > 0 ? divisions : null,
        onChanged: onChanged,
      ),
    );
  }

  Widget _numericSelector({
    required CronField field,
    required int value,
    required ValueChanged<int> onChanged,
    bool labelled = false,
  }) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: field.maxValue - field.minValue + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (BuildContext context, int i) {
          final int v = field.minValue + i;
          final bool selected = v == value;
          final String label = labelled
              ? _labelFor(field, v)
              : v.toString();
          return GestureDetector(
            onTap: () => onChanged(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                  colors: <Color>[_accentA, _accentB],
                )
                    : null,
                color: selected
                    ? null
                    : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected
                      ? Colors.transparent
                      : Colors.white.withOpacity(0.15),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _multiSelector({
    required CronField field,
    required List<int> selected,
    required ValueChanged<int> onToggle,
  }) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List<Widget>.generate(
        field.maxValue - field.minValue + 1,
            (int i) {
          final int v = field.minValue + i;
          final bool isOn = selected.contains(v);
          final String label =
          field == CronField.month || field == CronField.dayOfWeek
              ? _labelFor(field, v)
              : v.toString();
          return GestureDetector(
            onTap: () => onToggle(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                gradient: isOn
                    ? const LinearGradient(
                  colors: <Color>[_accentA, _accentB],
                )
                    : null,
                color:
                isOn ? null : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isOn
                      ? Colors.transparent
                      : Colors.white.withOpacity(0.15),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight:
                  isOn ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _labelFor(CronField field, int v) {
    if (field == CronField.month) return kMonthNames[v] ?? '$v';
    if (field == CronField.dayOfWeek) return kDayNames[v] ?? '$v';
    return '$v';
  }

  Widget _nextRunsCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.schedule_rounded,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 8),
              Text(
                context.t('cronbuilder_next_runs'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_nextRuns.isEmpty)
            Text(
              context.t('cronbuilder_no_runs'),
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            )
          else
            for (int i = 0; i < _nextRuns.length; i++) ...<Widget>[
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${i + 1}.',
                        style: const TextStyle(
                          color: _accentB,
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _formatDateTime(_nextRuns[i]),
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 12,
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

  Widget _buildPresetsTab() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: kCronPresets.length,
      itemBuilder: (BuildContext context, int i) {
        final CronPreset p = kCronPresets[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _GlassCard(
            padding: const EdgeInsets.all(14),
            radius: 14,
            child: InkWell(
              onTap: () => _applyPreset(p),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          context.t(p.nameKey),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.expression,
                          style: const TextStyle(
                            color: _accentB,
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.white38,
                  ),
                ],
              ),
            ),
          ),
        );
      },
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