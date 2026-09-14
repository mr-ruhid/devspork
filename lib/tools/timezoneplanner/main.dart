import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/app_localization.dart';
import 'models.dart';
import 'timezones.dart';

const Color _accentA = Color(0xFF7C4DFF);
const Color _accentB = Color(0xFF00E5FF);
const Color _danger = Color(0xFFFF5C5C);
const Color _warning = Color(0xFFFFC24B);
const Color _success = Color(0xFF4BD68B);
const Color _bgTop = Color(0xFF1B1035);
const Color _bgMid = Color(0xFF2A1550);
const Color _bgBot = Color(0xFF0F2A4A);

class TimezonePlanner extends StatefulWidget {
  const TimezonePlanner({super.key});

  @override
  State<TimezonePlanner> createState() => _TimezonePlannerState();
}

class _TimezonePlannerState extends State<TimezonePlanner>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final List<TimezoneEntry> _selected = <TimezoneEntry>[];
  final PlannerOptions _options = PlannerOptions();

  int _selectedUtcHour = 12;
  bool _showPicker = false;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    for (final String id in TimezoneData.defaults) {
      final TimezoneEntry? t = TimezoneData.findById(id);
      if (t != null) _selected.add(t);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _selected.isNotEmpty && _options.workEnd > _options.workStart;

  int _localHour(int utcHour, TimezoneEntry tz) {
    final int offsetMin = TimezoneData.currentOffsetMinutes(tz.id);
    final int totalMinutes = utcHour * 60 + offsetMin;
    final int hour = (totalMinutes ~/ 60) % 24;
    return hour < 0 ? hour + 24 : hour;
  }

  bool _isWorking(int localHour) =>
      localHour >= _options.workStart && localHour < _options.workEnd;

  MeetingHour _computeMeeting(int utcHour) {
    final List<int> localHours = <int>[];
    final List<bool> inWorking = <bool>[];
    int workingCount = 0;

    for (final TimezoneEntry tz in _selected) {
      final int h = _localHour(utcHour, tz);
      final bool w = _isWorking(h);
      localHours.add(h);
      inWorking.add(w);
      if (w) workingCount++;
    }

    return MeetingHour(
      utcHour: utcHour,
      localHours: localHours,
      inWorking: inWorking,
      workingCount: workingCount,
    );
  }

  List<MeetingHour> get _allHours {
    return List<MeetingHour>.generate(
      24,
          (int i) => _computeMeeting(i),
    );
  }

  MeetingHour? get _bestHour {
    if (_selected.isEmpty) return null;
    final List<MeetingHour> hours = _allHours;
    final int total = _selected.length;

    final List<MeetingHour> allWorking = hours
        .where((MeetingHour h) => h.workingCount == total)
        .toList();
    if (allWorking.isNotEmpty) {
      return allWorking.reduce((MeetingHour a, MeetingHour b) =>
      a.utcHour <= b.utcHour ? a : b);
    }

    final List<MeetingHour> best = hours
        .where((MeetingHour h) => h.workingCount > 0)
        .toList();
    if (best.isEmpty) return null;

    final int max = best
        .map((MeetingHour h) => h.workingCount)
        .reduce((int a, int b) => a > b ? a : b);
    final List<MeetingHour> top =
    best.where((MeetingHour h) => h.workingCount == max).toList();
    return top.first;
  }

  List<MeetingHour> get _overlapHours {
    if (_selected.isEmpty) return <MeetingHour>[];
    final int total = _selected.length;
    return _allHours
        .where((MeetingHour h) => h.workingCount == total)
        .toList();
  }

  void _addTimezone(TimezoneEntry tz) {
    if (_selected.any((TimezoneEntry t) => t.id == tz.id)) {
      _showSnack(context.t('timezoneplanner_already_added'));
      return;
    }
    if (_selected.length >= 8) {
      _showSnack(context.t('timezoneplanner_max_reached'));
      return;
    }
    setState(() {
      _selected.add(tz);
      _showPicker = false;
      _searchQuery = '';
      _searchCtrl.clear();
    });
  }

  void _removeTimezone(TimezoneEntry tz) {
    setState(() {
      _selected.removeWhere((TimezoneEntry t) => t.id == tz.id);
    });
  }

  void _jumpToBest() {
    final MeetingHour? best = _bestHour;
    if (best == null) return;
    setState(() => _selectedUtcHour = best.utcHour);
  }

  Future<void> _copySummary() async {
    final StringBuffer sb = StringBuffer();
    sb.writeln(context.t('timezoneplanner_title'));
    sb.writeln('UTC ${_two(_selectedUtcHour)}:00');
    sb.writeln();
    for (final TimezoneEntry tz in _selected) {
      final int h = _localHour(_selectedUtcHour, tz);
      final String flag = _isWorking(h) ? '✓' : '✗';
      sb.writeln('$flag ${tz.city} (${tz.country}): ${_two(h)}:00');
    }
    final MeetingHour? best = _bestHour;
    if (best != null) {
      sb.writeln();
      sb.writeln(
        '${context.t('timezoneplanner_best')}: UTC ${_two(best.utcHour)}:00',
      );
    }
    await Clipboard.setData(ClipboardData(text: sb.toString()));
    if (!mounted) return;
    _showSnack(context.t('timezoneplanner_copied'));
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

  String _two(int n) => n < 10 ? '0$n' : '$n';

  String _formatOffset(TimezoneEntry tz) {
    final int min = TimezoneData.currentOffsetMinutes(tz.id);
    final bool neg = min < 0;
    final int abs = min.abs();
    final int h = abs ~/ 60;
    final int m = abs % 60;
    final String sign = neg ? '-' : '+';
    if (m == 0) return 'UTC$sign$h';
    return 'UTC$sign$h:${_two(m)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.t('timezoneplanner_title')),
        actions: <Widget>[
          _glassIconButton(
            icon: Icons.bolt_rounded,
            tooltip: context.t('timezoneplanner_jump_best'),
            onTap: _jumpToBest,
          ),
          _glassIconButton(
            icon: Icons.copy_rounded,
            tooltip: context.t('timezoneplanner_copy'),
            onTap: _copySummary,
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
                    _buildPlannerTab(),
                    _buildSettingsTab(),
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
              Tab(text: context.t('timezoneplanner_tab_planner')),
              Tab(text: context.t('timezoneplanner_tab_settings')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlannerTab() {
    if (_selected.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.public_rounded,
                size: 48,
                color: Colors.white.withOpacity(0.25),
              ),
              const SizedBox(height: 12),
              Text(
                context.t('timezoneplanner_empty'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 16),
              _primaryButton(
                icon: Icons.add_rounded,
                labelKey: 'timezoneplanner_add',
                onTap: () => setState(() => _showPicker = true),
              ),
            ],
          ),
        ),
      );
    }

    final MeetingHour current = _computeMeeting(_selectedUtcHour);
    final MeetingHour? best = _bestHour;
    final List<MeetingHour> overlap = _overlapHours;
    final List<MeetingHour> all = _allHours;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _utcSliderCard(current, best),
          const SizedBox(height: 16),
          _timezoneListCard(current),
          const SizedBox(height: 16),
          _overlapCard(overlap, best),
          const SizedBox(height: 16),
          _heatmapCard(all),
          const SizedBox(height: 16),
          _primaryButton(
            icon: Icons.add_rounded,
            labelKey: 'timezoneplanner_add',
            onTap: () => setState(() => _showPicker = true),
          ),
        ],
      ),
    );
  }

  Widget _utcSliderCard(MeetingHour current, MeetingHour? best) {
    final bool allWork = current.workingCount == _selected.length;
    final Color statusColor =
    allWork ? _success : current.workingCount > 0 ? _warning : _danger;

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.access_time_rounded,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 8),
              Text(
                context.t('timezoneplanner_selected_utc'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _accentB.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _accentB.withOpacity(0.5)),
                ),
                child: Text(
                  'UTC ${_two(_selectedUtcHour)}:00',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _accentB,
              inactiveTrackColor: Colors.white.withOpacity(0.1),
              thumbColor: Colors.white,
              overlayColor: _accentB.withOpacity(0.2),
              trackHeight: 6,
            ),
            child: Slider(
              value: _selectedUtcHour.toDouble(),
              min: 0,
              max: 23,
              divisions: 23,
              onChanged: (double v) =>
                  setState(() => _selectedUtcHour = v.round()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                '00:00',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                '12:00',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                '23:00',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Icon(
                allWork
                    ? Icons.check_circle_rounded
                    : current.workingCount > 0
                    ? Icons.info_rounded
                    : Icons.cancel_rounded,
                size: 16,
                color: statusColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${current.workingCount}/${_selected.length} '
                      '${context.t('timezoneplanner_working')}',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (best != null && best.utcHour != _selectedUtcHour)
                TextButton.icon(
                  onPressed: _jumpToBest,
                  icon: const Icon(
                    Icons.bolt_rounded,
                    size: 14,
                    color: _accentB,
                  ),
                  label: Text(
                    '${context.t('timezoneplanner_best')} '
                        '${_two(best.utcHour)}:00',
                    style: const TextStyle(
                      color: _accentB,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timezoneListCard(MeetingHour current) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.public_rounded,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.t('timezoneplanner_zones'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${_selected.length}/8',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < _selected.length; i++) ...<Widget>[
            _timezoneRow(_selected[i], i, current),
            if (i < _selected.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _timezoneRow(TimezoneEntry tz, int index, MeetingHour current) {
    final int localHour = current.localHours[index];
    final bool working = current.inWorking[index];
    final Color statusColor = working ? _success : _danger;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: working
              ? _success.withOpacity(0.4)
              : _danger.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        tz.city,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatOffset(tz),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  tz.country,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '${_two(localHour)}:00',
                style: TextStyle(
                  color: statusColor,
                  fontFamily: 'monospace',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                working
                    ? context.t('timezoneplanner_status_work')
                    : context.t('timezoneplanner_status_off'),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () => _removeTimezone(tz),
            icon: const Icon(
              Icons.close_rounded,
              size: 16,
              color: Colors.white38,
            ),
            splashRadius: 14,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _overlapCard(List<MeetingHour> overlap, MeetingHour? best) {
    if (overlap.isEmpty) {
      return _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: _warning,
                ),
                const SizedBox(width: 8),
                Text(
                  context.t('timezoneplanner_no_overlap'),
                  style: const TextStyle(
                    color: _warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              context.t('timezoneplanner_no_overlap_hint'),
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                height: 1.4,
              ),
            ),
            if (best != null) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                '${context.t('timezoneplanner_partial')}: '
                    'UTC ${_two(best.utcHour)}:00 '
                    '(${best.workingCount}/${_selected.length})',
                style: const TextStyle(
                  color: _accentB,
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      );
    }

    final int startHour = overlap.first.utcHour;
    final int endHour = overlap.last.utcHour;

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: _success,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.t('timezoneplanner_common_window'),
                  style: const TextStyle(
                    color: _success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _success.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'UTC ${_two(startHour)}:00 – '
                      '${_two((endHour + 1) % 24)}:00',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${overlap.length} ${context.t('timezoneplanner_hours')}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heatmapCard(List<MeetingHour> all) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.grid_on_rounded,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 8),
              Text(
                context.t('timezoneplanner_heatmap'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              const SizedBox(width: 32),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      '0',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      '6',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      '12',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      '18',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      '23',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (int i = 0; i < _selected.length; i++) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 32,
                    child: Text(
                      _selected[i].city.length > 6
                          ? '${_selected[i].city.substring(0, 5)}.'
                          : _selected[i].city,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 9,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: List<Widget>.generate(24, (int h) {
                        final int localHour = _localHour(h, _selected[i]);
                        final bool work = _isWorking(localHour);
                        final bool selected = h == _selectedUtcHour;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedUtcHour = h),
                            child: Container(
                              height: 20,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 0.5,
                              ),
                              decoration: BoxDecoration(
                                color: work
                                    ? _success.withOpacity(0.7)
                                    : Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(2),
                                border: selected
                                    ? Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                )
                                    : null,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              _legendDot(_success, 'timezoneplanner_legend_work'),
              const SizedBox(width: 12),
              _legendDot(Colors.white24, 'timezoneplanner_legend_off'),
              const Spacer(),
              Text(
                context.t('timezoneplanner_legend_hint'),
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String labelKey) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          context.t(labelKey),
          style: const TextStyle(color: Colors.white60, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildSettingsTab() {
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
                      Icons.schedule_rounded,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.t('timezoneplanner_work_hours'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '${context.t('timezoneplanner_start')}: '
                                '${_two(_options.workStart)}:00',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Slider(
                            value: _options.workStart.toDouble(),
                            min: 0,
                            max: 23,
                            divisions: 23,
                            activeColor: _accentB,
                            inactiveColor:
                            Colors.white.withOpacity(0.1),
                            label: '${_options.workStart}:00',
                            onChanged: (double v) {
                              setState(() {
                                _options.workStart = v.round();
                                if (_options.workEnd <=
                                    _options.workStart) {
                                  _options.workEnd =
                                      _options.workStart + 1;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '${context.t('timezoneplanner_end')}: '
                                '${_two(_options.workEnd)}:00',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Slider(
                            value: _options.workEnd.toDouble(),
                            min: 1,
                            max: 24,
                            divisions: 23,
                            activeColor: _accentA,
                            inactiveColor:
                            Colors.white.withOpacity(0.1),
                            label: '${_options.workEnd}:00',
                            onChanged: (double v) {
                              setState(() {
                                _options.workEnd = v.round();
                                if (_options.workEnd <=
                                    _options.workStart) {
                                  _options.workStart =
                                      _options.workEnd - 1;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${context.t('timezoneplanner_range')}: '
                      '${_options.workEnd - _options.workStart}h',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
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
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.public_rounded,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.t('timezoneplanner_zones'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${_selected.length}/8',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_selected.isEmpty)
                  Text(
                    context.t('timezoneplanner_empty'),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  )
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _selected.map((TimezoneEntry tz) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              tz.city,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _removeTimezone(tz),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 12),
                _primaryButton(
                  icon: Icons.add_rounded,
                  labelKey: 'timezoneplanner_add',
                  onTap: () => setState(() => _showPicker = true),
                ),
              ],
            ),
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_showPicker) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openPickerDialog();
      });
    }
  }

  void _openPickerDialog() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setModalState) {
            final List<TimezoneEntry> results =
            TimezoneData.search(_searchQuery);

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              expand: false,
              builder: (BuildContext ctx2, ScrollController scrollCtrl) {
                return ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F1245).withOpacity(0.95),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18),
                        ),
                      ),
                      child: Column(
                        children: <Widget>[
                          const SizedBox(height: 10),
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                            ),
                            child: Row(
                              children: <Widget>[
                                const Icon(
                                  Icons.search_rounded,
                                  size: 18,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  context.t('timezoneplanner_add'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                            ),
                            child: TextField(
                              controller: _searchCtrl,
                              autofocus: false,
                              onChanged: (String v) {
                                setModalState(() => _searchQuery = v);
                                setState(() => _searchQuery = v);
                              },
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              decoration: InputDecoration(
                                hintText: context
                                    .t('timezoneplanner_search_hint'),
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.35),
                                  fontSize: 13,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  color: Colors.white54,
                                  size: 18,
                                ),
                                isDense: true,
                                filled: true,
                                fillColor:
                                Colors.white.withOpacity(0.06),
                                contentPadding:
                                const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color:
                                    Colors.white.withOpacity(0.15),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color:
                                    Colors.white.withOpacity(0.15),
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
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: results.isEmpty
                                ? Center(
                              child: Text(
                                context.t(
                                  'timezoneplanner_no_results',
                                ),
                                style: const TextStyle(
                                  color: Colors.white54,
                                ),
                              ),
                            )
                                : ListView.builder(
                              controller: scrollCtrl,
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                0,
                                20,
                                20,
                              ),
                              itemCount: results.length,
                              itemBuilder:
                                  (BuildContext c, int i) {
                                final TimezoneEntry tz =
                                results[i];
                                final bool added = _selected.any(
                                      (TimezoneEntry t) =>
                                  t.id == tz.id,
                                );
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 8,
                                  ),
                                  child: Material(
                                    color: Colors.white
                                        .withOpacity(
                                      added ? 0.03 : 0.06,
                                    ),
                                    borderRadius:
                                    BorderRadius.circular(
                                      12,
                                    ),
                                    child: InkWell(
                                      borderRadius:
                                      BorderRadius.circular(
                                        12,
                                      ),
                                      onTap: added
                                          ? null
                                          : () {
                                        _addTimezone(
                                          tz,
                                        );
                                        Navigator.of(ctx)
                                            .pop();
                                      },
                                      child: Padding(
                                        padding:
                                        const EdgeInsets.all(
                                          12,
                                        ),
                                        child: Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,
                                                children: <Widget>[
                                                  Text(
                                                    tz.city,
                                                    style:
                                                    TextStyle(
                                                      color: added
                                                          ? Colors
                                                          .white38
                                                          : Colors
                                                          .white,
                                                      fontWeight:
                                                      FontWeight
                                                          .w600,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    height: 2,
                                                  ),
                                                  Text(
                                                    '${tz.country} • ${_formatOffset(tz)}',
                                                    style:
                                                    const TextStyle(
                                                      color: Colors
                                                          .white54,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (added)
                                              const Icon(
                                                Icons.check_circle_rounded,
                                                size: 18,
                                                color: _success,
                                              )
                                            else
                                              const Icon(
                                                Icons.add_circle_outline_rounded,
                                                size: 18,
                                                color: _accentB,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _showPicker = false;
          _searchQuery = '';
          _searchCtrl.clear();
        });
      }
    });
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