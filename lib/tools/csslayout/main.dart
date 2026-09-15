import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/app_localization.dart';
import 'generator.dart';
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
const Color _success = Color(0xFF4BD68B);
const Color _bgTop = Color(0xFF1B1035);
const Color _bgMid = Color(0xFF2A1550);
const Color _bgBot = Color(0xFF0F2A4A);

class CssLayoutGen extends StatefulWidget {
  const CssLayoutGen({super.key});

  @override
  State<CssLayoutGen> createState() => _CssLayoutGenState();
}

class _CssLayoutGenState extends State<CssLayoutGen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  final FlexConfig _flex = FlexConfig();
  final GridConfig _grid = GridConfig();
  LayoutOptions _opts = const LayoutOptions();

  Timer? _debounce;
  String _output = '';
  bool _copied = false;
  int? _expandedFlexItem;

  final List<TextEditingController> _colTrackCtrls =
  <TextEditingController>[];
  final List<TextEditingController> _rowTrackCtrls =
  <TextEditingController>[];
  final Map<String, TextEditingController> _areaCtrls =
  <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) return;
      _scheduleRegen();
    });
    _syncGridControllers();
    _scheduleRegen();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabs.dispose();
    for (final TextEditingController c in _colTrackCtrls) {
      c.dispose();
    }
    for (final TextEditingController c in _rowTrackCtrls) {
      c.dispose();
    }
    for (final TextEditingController c in _areaCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncGridControllers() {
    for (final TextEditingController c in _colTrackCtrls) {
      c.dispose();
    }
    for (final TextEditingController c in _rowTrackCtrls) {
      c.dispose();
    }
    for (final TextEditingController c in _areaCtrls.values) {
      c.dispose();
    }
    _colTrackCtrls.clear();
    _rowTrackCtrls.clear();
    _areaCtrls.clear();

    for (int i = 0; i < _grid.columns.length; i++) {
      final TextEditingController c =
      TextEditingController(text: _grid.columns[i].value);
      final int idx = i;
      c.addListener(() {
        _grid.columns[idx].value = c.text;
        _scheduleRegen();
      });
      _colTrackCtrls.add(c);
    }

    for (int i = 0; i < _grid.rows.length; i++) {
      final TextEditingController c =
      TextEditingController(text: _grid.rows[i].value);
      final int idx = i;
      c.addListener(() {
        _grid.rows[idx].value = c.text;
        _scheduleRegen();
      });
      _rowTrackCtrls.add(c);
    }

    for (int r = 0; r < _grid.areas.length; r++) {
      for (int col = 0; col < _grid.areas[r].length; col++) {
        final TextEditingController c =
        TextEditingController(text: _grid.areas[r][col].name);
        final int rr = r;
        final int cc = col;
        c.addListener(() {
          _grid.areas[rr][cc].name = c.text;
          _scheduleRegen();
        });
        _areaCtrls['$r:$col'] = c;
      }
    }
  }

  void _scheduleRegen() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), _regenerate);
  }

  void _regenerate() {
    final LayoutTab tab =
    _tabs.index == 0 ? LayoutTab.flex : LayoutTab.grid;
    final String out = CssLayoutGenerator.fullSnippet(
      tab: tab,
      flex: _flex,
      grid: _grid,
      opts: _opts,
    );
    if (!mounted) return;
    setState(() => _output = out);
  }

  Future<void> _copy() async {
    if (_output.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _output));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _copied = true);
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _mutateFlex(VoidCallback fn) {
    setState(() {
      fn();
      _regenerate();
    });
  }

  void _mutateGrid(VoidCallback fn) {
    setState(() {
      fn();
      _regenerate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0B0B12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.t('csslayout_title')),
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
                    _buildFlexTab(),
                    _buildGridTab(),
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
              Tab(text: _tr(context, 'csslayout_tab_flex', 'Flexbox')),
              Tab(text: _tr(context, 'csslayout_tab_grid', 'Grid')),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // FLEX TAB
  // ==========================================================================

  Widget _buildFlexTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildFlexPreview(),
          const SizedBox(height: 14),
          _buildFlexSettings(),
          const SizedBox(height: 14),
          _buildFlexItems(),
          const SizedBox(height: 14),
          _buildOutputOptions(),
          const SizedBox(height: 14),
          _buildOutput(),
        ],
      ),
    );
  }

  Widget _buildFlexPreview() {
    final List<Widget> boxes = List<Widget>.generate(
      _flex.itemCount,
          (int i) => _previewBox('${i + 1}', i),
    );

    Widget content;

    if (_flex.wrap == FlexWrap.nowrap) {
      content = _buildFlexNoWrap(boxes);
    } else {
      content = _buildFlexWrap(boxes);
    }

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            Icons.preview_rounded,
            _tr(context, 'csslayout_preview', 'Live preview'),
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(minHeight: 180),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildFlexNoWrap(List<Widget> boxes) {
    final bool isRow = _flex.direction == FlexDirection.row ||
        _flex.direction == FlexDirection.rowReverse;
    final bool reversed = _flex.direction == FlexDirection.rowReverse ||
        _flex.direction == FlexDirection.columnReverse;

    final List<Widget> children = <Widget>[];
    final List<Widget> ordered = reversed ? boxes.reversed.toList() : boxes;
    for (int i = 0; i < ordered.length; i++) {
      children.add(ordered[i]);
      if (i < ordered.length - 1) {
        children.add(SizedBox(
          width: isRow ? _flex.gapColumn.toDouble() : 0,
          height: isRow ? 0 : _flex.gapRow.toDouble(),
        ));
      }
    }

    if (isRow) {
      return Row(
        mainAxisAlignment: _flexMainAlign(),
        crossAxisAlignment: _flexCrossAlign(),
        children: children,
      );
    }
    return Column(
      mainAxisAlignment: _flexMainAlign(),
      crossAxisAlignment: _flexCrossAlign(),
      children: children,
    );
  }

  Widget _buildFlexWrap(List<Widget> boxes) {
    final Axis axis = _flex.direction == FlexDirection.row ||
        _flex.direction == FlexDirection.rowReverse
        ? Axis.horizontal
        : Axis.vertical;
    final bool reversed = _flex.direction == FlexDirection.rowReverse ||
        _flex.direction == FlexDirection.columnReverse;
    final List<Widget> ordered = reversed ? boxes.reversed.toList() : boxes;

    return Align(
      alignment: Alignment.topLeft,
      child: Wrap(
        direction: axis,
        spacing: _flex.gapColumn.toDouble(),
        runSpacing: _flex.gapRow.toDouble(),
        alignment: _flexWrapAlign(),
        runAlignment: _flexWrapRunAlign(),
        crossAxisAlignment:
        _flex.wrap == FlexWrap.wrapReverse
            ? WrapCrossAlignment.end
            : WrapCrossAlignment.start,
        children: ordered,
      ),
    );
  }

  MainAxisAlignment _flexMainAlign() {
    switch (_flex.justify) {
      case JustifyContent.flexStart:
        return MainAxisAlignment.start;
      case JustifyContent.flexEnd:
        return MainAxisAlignment.end;
      case JustifyContent.center:
        return MainAxisAlignment.center;
      case JustifyContent.spaceBetween:
        return MainAxisAlignment.spaceBetween;
      case JustifyContent.spaceAround:
        return MainAxisAlignment.spaceAround;
      case JustifyContent.spaceEvenly:
        return MainAxisAlignment.spaceEvenly;
    }
  }

  CrossAxisAlignment _flexCrossAlign() {
    switch (_flex.alignItems) {
      case AlignItems.stretch:
        return CrossAxisAlignment.stretch;
      case AlignItems.flexStart:
        return CrossAxisAlignment.start;
      case AlignItems.flexEnd:
        return CrossAxisAlignment.end;
      case AlignItems.center:
        return CrossAxisAlignment.center;
      case AlignItems.baseline:
        return CrossAxisAlignment.baseline;
    }
  }

  WrapAlignment _flexWrapAlign() {
    switch (_flex.justify) {
      case JustifyContent.flexStart:
        return WrapAlignment.start;
      case JustifyContent.flexEnd:
        return WrapAlignment.end;
      case JustifyContent.center:
        return WrapAlignment.center;
      case JustifyContent.spaceBetween:
        return WrapAlignment.spaceBetween;
      case JustifyContent.spaceAround:
        return WrapAlignment.spaceAround;
      case JustifyContent.spaceEvenly:
        return WrapAlignment.spaceEvenly;
    }
  }

  WrapAlignment _flexWrapRunAlign() {
    switch (_flex.alignContent) {
      case AlignContent.flexStart:
        return WrapAlignment.start;
      case AlignContent.flexEnd:
        return WrapAlignment.end;
      case AlignContent.center:
        return WrapAlignment.center;
      case AlignContent.spaceBetween:
        return WrapAlignment.spaceBetween;
      case AlignContent.spaceAround:
        return WrapAlignment.spaceAround;
      case AlignContent.stretch:
        return WrapAlignment.start;
    }
  }

  Widget _buildFlexSettings() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            Icons.tune_rounded,
            _tr(context, 'csslayout_container', 'Container'),
          ),
          const SizedBox(height: 12),
          _enumPicker<FlexDirection>(
            label: _tr(context, 'csslayout_direction', 'Direction'),
            values: FlexDirection.values,
            current: _flex.direction,
            labelOf: (FlexDirection v) => _tr(context, v.labelKey, v.css),
            onChanged: (FlexDirection v) =>
                _mutateFlex(() => _flex.direction = v),
          ),
          const SizedBox(height: 10),
          _enumPicker<FlexWrap>(
            label: _tr(context, 'csslayout_wrap', 'Wrap'),
            values: FlexWrap.values,
            current: _flex.wrap,
            labelOf: (FlexWrap v) => _tr(context, v.labelKey, v.css),
            onChanged: (FlexWrap v) =>
                _mutateFlex(() => _flex.wrap = v),
          ),
          const SizedBox(height: 10),
          _enumPicker<JustifyContent>(
            label: _tr(context, 'csslayout_justify', 'Justify content'),
            values: JustifyContent.values,
            current: _flex.justify,
            labelOf: (JustifyContent v) => _tr(context, v.labelKey, v.css),
            onChanged: (JustifyContent v) =>
                _mutateFlex(() => _flex.justify = v),
          ),
          const SizedBox(height: 10),
          _enumPicker<AlignItems>(
            label: _tr(context, 'csslayout_align_items', 'Align items'),
            values: AlignItems.values,
            current: _flex.alignItems,
            labelOf: (AlignItems v) => _tr(context, v.labelKey, v.css),
            onChanged: (AlignItems v) =>
                _mutateFlex(() => _flex.alignItems = v),
          ),
          if (_flex.wrap != FlexWrap.nowrap) ...<Widget>[
            const SizedBox(height: 10),
            _enumPicker<AlignContent>(
              label: _tr(context, 'csslayout_align_content', 'Align content'),
              values: AlignContent.values,
              current: _flex.alignContent,
              labelOf: (AlignContent v) => _tr(context, v.labelKey, v.css),
              onChanged: (AlignContent v) =>
                  _mutateFlex(() => _flex.alignContent = v),
            ),
          ],
          const SizedBox(height: 14),
          _sliderRow(
            label: _tr(context, 'csslayout_gap_row', 'Row gap'),
            value: _flex.gapRow,
            min: 0,
            max: 64,
            suffix: 'px',
            onChanged: (int v) => _mutateFlex(() => _flex.gapRow = v),
          ),
          _sliderRow(
            label: _tr(context, 'csslayout_gap_col', 'Column gap'),
            value: _flex.gapColumn,
            min: 0,
            max: 64,
            suffix: 'px',
            onChanged: (int v) => _mutateFlex(() => _flex.gapColumn = v),
          ),
          _sliderRow(
            label: _tr(context, 'csslayout_item_count', 'Item count'),
            value: _flex.itemCount,
            min: 1,
            max: 12,
            onChanged: (int v) => _mutateFlex(() => _flex.itemCount = v),
          ),
        ],
      ),
    );
  }

  Widget _buildFlexItems() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _sectionTitle(
                  Icons.view_list_rounded,
                  _tr(context, 'csslayout_items', 'Per-item overrides'),
                ),
              ),
              if (_flex.hasCustomItems)
                _miniTextButton(
                  label: _tr(context, 'csslayout_reset_items', 'Reset'),
                  onTap: () => _mutateFlex(() => _flex.resetAllItems()),
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < _flex.itemCount; i++) _buildFlexItemRow(i),
        ],
      ),
    );
  }

  Widget _buildFlexItemRow(int index) {
    final FlexItemOverride item = _flex.itemAt(index);
    final bool expanded = _expandedFlexItem == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          InkWell(
            onTap: () => setState(() {
              _expandedFlexItem = expanded ? null : index;
            }),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: <Color>[_accentA, _accentB],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _flexItemSummary(item),
                      style: TextStyle(
                        color: item.hasAnyNonDefault
                            ? _accentB
                            : Colors.white54,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                    color: Colors.white60,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.only(left: 36, bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _switchRow(
                    label: _tr(context, 'csslayout_item_enable',
                        'Enable override'),
                    value: item.enabled,
                    onChanged: (bool v) => _mutateFlex(() {
                      item.enabled = v;
                      _flex.items[index] = item;
                    }),
                  ),
                  if (item.enabled) ...<Widget>[
                    _sliderRow(
                      label: _tr(context, 'csslayout_grow', 'flex-grow'),
                      value: item.grow,
                      min: 0,
                      max: 5,
                      onChanged: (int v) => _mutateFlex(() => item.grow = v),
                    ),
                    _sliderRow(
                      label: _tr(context, 'csslayout_shrink', 'flex-shrink'),
                      value: item.shrink,
                      min: 0,
                      max: 5,
                      onChanged: (int v) =>
                          _mutateFlex(() => item.shrink = v),
                    ),
                    const SizedBox(height: 6),
                    _textFieldRow(
                      label: _tr(context, 'csslayout_basis', 'flex-basis'),
                      controller: TextEditingController(text: item.basis),
                      hint: 'auto',
                      onChanged: (String v) =>
                          _mutateFlex(() => item.basis = v),
                    ),
                    const SizedBox(height: 10),
                    _enumPicker<AlignSelf>(
                      label: _tr(context, 'csslayout_self', 'align-self'),
                      values: AlignSelf.values,
                      current: item.alignSelf,
                      labelOf: (AlignSelf v) => _tr(context, v.labelKey, v.css),
                      onChanged: (AlignSelf v) =>
                          _mutateFlex(() => item.alignSelf = v),
                    ),
                    const SizedBox(height: 10),
                    _sliderRow(
                      label: _tr(context, 'csslayout_order', 'order'),
                      value: item.order,
                      min: -5,
                      max: 5,
                      onChanged: (int v) => _mutateFlex(() => item.order = v),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _flexItemSummary(FlexItemOverride o) {
    if (!o.enabled) return '—';
    final List<String> parts = <String>[];
    if (o.grow != 0) parts.add('grow:${o.grow}');
    if (o.shrink != 1) parts.add('shrink:${o.shrink}');
    if (o.basis != 'auto') parts.add('basis:${o.basis}');
    if (o.alignSelf != AlignSelf.auto) parts.add('self:${o.alignSelf.css}');
    if (o.order != 0) parts.add('order:${o.order}');
    return parts.isEmpty ? '—' : parts.join(' · ');
  }

  // ==========================================================================
  // GRID TAB
  // ==========================================================================

  Widget _buildGridTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildGridPreview(),
          const SizedBox(height: 14),
          _buildGridTrackSettings(),
          const SizedBox(height: 14),
          _buildGridAreasEditor(),
          const SizedBox(height: 14),
          _buildGridSettings(),
          const SizedBox(height: 14),
          _buildOutputOptions(),
          const SizedBox(height: 14),
          _buildOutput(),
        ],
      ),
    );
  }

  Widget _buildGridPreview() {
    final Widget content;
    if (_grid.useAreas) {
      content = _buildGridAreaPreview();
    } else {
      content = _buildGridTrackPreview();
    }

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            Icons.preview_rounded,
            _tr(context, 'csslayout_preview', 'Live preview'),
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(minHeight: 180),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildGridAreaPreview() {
    final int cols = _grid.colCount;
    final int rows = _grid.rowCount;
    final List<TableRow> tableRows = <TableRow>[];

    for (int r = 0; r < rows; r++) {
      final List<TableCell> cells = <TableCell>[];
      for (int c = 0; c < cols; c++) {
        final String name = (r < _grid.areas.length &&
            c < _grid.areas[r].length)
            ? _grid.areas[r][c].name.trim()
            : '';
        final Color color = _areaColor(name);
        cells.add(TableCell(
          child: Container(
            margin: const EdgeInsets.all(1),
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.35),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.7)),
            ),
            child: Text(
              name.isEmpty ? '.' : name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ));
      }
      tableRows.add(TableRow(children: cells));
    }

    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: tableRows,
    );
  }

  Widget _buildGridTrackPreview() {
    final int cols = _grid.columns.length;
    final int rows = _grid.rows.length;
    final int total = _grid.itemCount;

    final List<List<int>> grid = <List<int>>[];
    int counter = 1;
    for (int r = 0; r < rows; r++) {
      final List<int> row = <int>[];
      for (int c = 0; c < cols; c++) {
        row.add(counter <= total ? counter : 0);
        counter++;
      }
      grid.add(row);
    }

    return Column(
      children: grid.map((List<int> row) {
        final List<Widget> cells = <Widget>[];
        for (int i = 0; i < row.length; i++) {
          final int n = row[i];
          final Widget cell = Container(
            margin: EdgeInsets.only(
              right: i < row.length - 1 ? _grid.gapColumn.toDouble() : 0,
            ),
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: n == 0
                  ? Colors.white.withOpacity(0.03)
                  : _accentA.withOpacity(0.25),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: n == 0
                    ? Colors.white.withOpacity(0.08)
                    : _accentA.withOpacity(0.5),
              ),
            ),
            child: n == 0
                ? null
                : Text(
              '$n',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          );

          final String track = i < _grid.columns.length
              ? _grid.columns[i].value
              : '1fr';
          cells.add(Expanded(
            flex: _trackFlex(track),
            child: cell,
          ));
        }
        return Padding(
          padding: EdgeInsets.only(bottom: _grid.gapRow.toDouble()),
          child: Row(children: cells),
        );
      }).toList(),
    );
  }

  int _trackFlex(String track) {
    final String t = track.trim();
    if (t.endsWith('fr')) {
      final double? f = double.tryParse(t.substring(0, t.length - 2));
      if (f != null && f > 0) return (f * 100).toInt();
    }
    return 100;
  }

  Color _areaColor(String name) {
    if (name.isEmpty) return Colors.white24;
    const List<Color> palette = <Color>[
      Color(0xFF7C4DFF),
      Color(0xFF00E5FF),
      Color(0xFFFF5C5C),
      Color(0xFF4BD68B),
      Color(0xFFFFC24B),
      Color(0xFFEC4899),
      Color(0xFF8B5CF6),
      Color(0xFF06B6D4),
    ];
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = (hash * 31 + name.codeUnitAt(i)) & 0x7fffffff;
    }
    return palette[hash % palette.length];
  }

  Widget _buildGridTrackSettings() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            Icons.view_column_rounded,
            _tr(context, 'csslayout_columns', 'Columns'),
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < _grid.columns.length; i++)
            _trackRow(
              index: i,
              controller: _colTrackCtrls[i],
              onRemove: _grid.columns.length <= 1
                  ? null
                  : () => _mutateGrid(() {
                _grid.removeColumn(i);
                _syncGridControllers();
              }),
              presets: true,
            ),
          const SizedBox(height: 6),
          _dashedButton(
            label: _tr(context, 'csslayout_add_col', 'Add column'),
            onTap: () => _mutateGrid(() {
              _grid.addColumn();
              _syncGridControllers();
            }),
          ),
          const SizedBox(height: 16),
          _sectionTitle(
            Icons.view_stream_rounded,
            _tr(context, 'csslayout_rows', 'Rows'),
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < _grid.rows.length; i++)
            _trackRow(
              index: i,
              controller: _rowTrackCtrls[i],
              onRemove: _grid.rows.length <= 1
                  ? null
                  : () => _mutateGrid(() {
                _grid.removeRow(i);
                _syncGridControllers();
              }),
              presets: false,
            ),
          const SizedBox(height: 6),
          _dashedButton(
            label: _tr(context, 'csslayout_add_row', 'Add row'),
            onTap: () => _mutateGrid(() {
              _grid.addRow();
              _syncGridControllers();
            }),
          ),
        ],
      ),
    );
  }

  Widget _trackRow({
    required int index,
    required TextEditingController controller,
    required VoidCallback? onRemove,
    required bool presets,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 22,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
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
                  borderSide: const BorderSide(color: _accentB, width: 1.4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          if (presets) _trackPresetButton(controller),
          _miniIconButton(
            icon: Icons.close_rounded,
            tooltip: _tr(context, 'csslayout_remove', 'Remove'),
            onTap: onRemove,
          ),
        ],
      ),
    );
  }

  Widget _trackPresetButton(TextEditingController controller) {
    return PopupMenuButton<String>(
      tooltip: _tr(context, 'csslayout_preset', 'Preset'),
      color: const Color(0xFF1E1B33),
      icon: const Icon(
        Icons.auto_awesome_rounded,
        size: 16,
        color: _accentB,
      ),
      onSelected: (String v) {
        controller.text = v;
        HapticFeedback.selectionClick();
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        _presetItem('1fr', '1fr'),
        _presetItem('2fr', '2fr'),
        _presetItem('3fr', '3fr'),
        _presetItem('100px', '100px'),
        _presetItem('200px', '200px'),
        _presetItem('25%', '25%'),
        _presetItem('50%', '50%'),
        _presetItem('auto', 'auto'),
        _presetItem('min-content', 'min-content'),
        _presetItem('max-content', 'max-content'),
        _presetItem('minmax(100px, 1fr)', 'minmax(100px, 1fr)'),
        _presetItem('repeat(3, 1fr)', 'repeat(3, 1fr)'),
      ],
    );
  }

  PopupMenuItem<String> _presetItem(String label, String value) {
    return PopupMenuItem<String>(
      value: value,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildGridAreasEditor() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _sectionTitle(
                  Icons.grid_view_rounded,
                  _tr(context, 'csslayout_areas', 'Grid areas'),
                ),
              ),
              Switch.adaptive(
                value: _grid.useAreas,
                onChanged: (bool v) => _mutateGrid(() {
                  _grid.useAreas = v;
                  if (v) {
                    _grid.syncAreaSize();
                    _syncGridControllers();
                  }
                }),
              ),
            ],
          ),
          if (_grid.useAreas) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              _tr(
                context,
                'csslayout_areas_hint',
                'Type a name in each cell. Same name = same area. "." = empty.',
              ),
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildAreaEditorRows(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildAreaEditorRows() {
    final List<Widget> rows = <Widget>[];
    for (int r = 0; r < _grid.areas.length; r++) {
      final List<Widget> cells = <Widget>[];
      for (int c = 0; c < _grid.areas[r].length; c++) {
        cells.add(Container(
          width: 76,
          margin: const EdgeInsets.only(right: 6),
          child: TextField(
            controller: _areaCtrls['$r:$c'],
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: _areaColor(_grid.areas[r][c].name.trim())
                  .withOpacity(0.15),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _areaColor(_grid.areas[r][c].name.trim())
                      .withOpacity(0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _areaColor(_grid.areas[r][c].name.trim())
                      .withOpacity(0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _areaColor(_grid.areas[r][c].name.trim()),
                  width: 1.4,
                ),
              ),
            ),
          ),
        ));
      }
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: cells),
      ));
    }
    return rows;
  }

  Widget _buildGridSettings() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            Icons.tune_rounded,
            _tr(context, 'csslayout_container', 'Container'),
          ),
          const SizedBox(height: 12),
          _enumPicker<GridAutoFlow>(
            label: _tr(context, 'csslayout_flow', 'grid-auto-flow'),
            values: GridAutoFlow.values,
            current: _grid.autoFlow,
            labelOf: (GridAutoFlow v) => _tr(context, v.labelKey, v.css),
            onChanged: (GridAutoFlow v) =>
                _mutateGrid(() => _grid.autoFlow = v),
          ),
          const SizedBox(height: 10),
          _enumPicker<GridJustifyItems>(
            label: _tr(context, 'csslayout_justify_items', 'justify-items'),
            values: GridJustifyItems.values,
            current: _grid.justifyItems,
            labelOf: (GridJustifyItems v) => _tr(context, v.labelKey, v.css),
            onChanged: (GridJustifyItems v) =>
                _mutateGrid(() => _grid.justifyItems = v),
          ),
          const SizedBox(height: 10),
          _enumPicker<GridAlignItems>(
            label: _tr(context, 'csslayout_align_items', 'align-items'),
            values: GridAlignItems.values,
            current: _grid.alignItems,
            labelOf: (GridAlignItems v) => _tr(context, v.labelKey, v.css),
            onChanged: (GridAlignItems v) =>
                _mutateGrid(() => _grid.alignItems = v),
          ),
          const SizedBox(height: 10),
          _enumPicker<JustifyContent>(
            label: _tr(context, 'csslayout_justify_content', 'justify-content'),
            values: JustifyContent.values,
            current: _grid.justifyContent,
            labelOf: (JustifyContent v) => _tr(context, v.labelKey, v.css),
            onChanged: (JustifyContent v) =>
                _mutateGrid(() => _grid.justifyContent = v),
          ),
          const SizedBox(height: 14),
          _sliderRow(
            label: _tr(context, 'csslayout_gap_row', 'Row gap'),
            value: _grid.gapRow,
            min: 0,
            max: 64,
            suffix: 'px',
            onChanged: (int v) => _mutateGrid(() => _grid.gapRow = v),
          ),
          _sliderRow(
            label: _tr(context, 'csslayout_gap_col', 'Column gap'),
            value: _grid.gapColumn,
            min: 0,
            max: 64,
            suffix: 'px',
            onChanged: (int v) => _mutateGrid(() => _grid.gapColumn = v),
          ),
          if (!_grid.useAreas)
            _sliderRow(
              label: _tr(context, 'csslayout_item_count', 'Item count'),
              value: _grid.itemCount,
              min: 1,
              max: 24,
              onChanged: (int v) => _mutateGrid(() => _grid.itemCount = v),
            ),
        ],
      ),
    );
  }

  // ==========================================================================
  // SHARED
  // ==========================================================================

  Widget _buildOutputOptions() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            Icons.settings_rounded,
            _tr(context, 'csslayout_output_opts', 'Output options'),
          ),
          const SizedBox(height: 6),
          _switchRow(
            label: _tr(context, 'csslayout_opt_html', 'Include HTML'),
            value: _opts.includeHtml,
            onChanged: (bool v) => setState(() {
              _opts = _opts.copyWith(includeHtml: v);
              _regenerate();
            }),
          ),
          _switchRow(
            label: _tr(context, 'csslayout_opt_shorthand', 'Use shorthand'),
            value: _opts.useShorthand,
            onChanged: (bool v) => setState(() {
              _opts = _opts.copyWith(useShorthand: v);
              _regenerate();
            }),
          ),
          _switchRow(
            label: _tr(context, 'csslayout_opt_minify', 'Minify output'),
            value: _opts.minify,
            onChanged: (bool v) => setState(() {
              _opts = _opts.copyWith(minify: v);
              _regenerate();
            }),
          ),
          const SizedBox(height: 8),
          _textFieldRow(
            label: _tr(context, 'csslayout_container_class', 'Container class'),
            controller: TextEditingController(text: _opts.containerClass),
            hint: 'container',
            onChanged: (String v) =>
                setState(() => _opts = _opts.copyWith(containerClass: v)),
          ),
          const SizedBox(height: 8),
          _textFieldRow(
            label: _tr(context, 'csslayout_item_class', 'Item class'),
            controller: TextEditingController(text: _opts.itemClass),
            hint: 'item',
            onChanged: (String v) =>
                setState(() => _opts = _opts.copyWith(itemClass: v)),
          ),
        ],
      ),
    );
  }

  Widget _buildOutput() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _sectionTitle(
                  Icons.code_rounded,
                  _tr(context, 'csslayout_output', 'Generated code'),
                ),
              ),
              _glassIconButton(
                icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
                tooltip: _copied
                    ? _tr(context, 'csslayout_copied', 'Copied')
                    : _tr(context, 'csslayout_copy', 'Copy'),
                onTap: _copy,
                highlighted: _copied,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 140),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: SelectableText(
              _output,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                height: 1.5,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewBox(String label, int index) {
    final FlexItemOverride item = _flex.itemAt(index);
    final bool overridden = item.hasAnyNonDefault;

    Widget box = Container(
      width: item.basis.endsWith('px')
          ? (double.tryParse(item.basis.replaceAll('px', '')) ?? 48)
          : 48,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: overridden
              ? <Color>[_accentA, _accentB]
              : <Color>[
            _accentA.withOpacity(0.6),
            _accentB.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: overridden ? Colors.white : Colors.white.withOpacity(0.3),
          width: overridden ? 1.4 : 1,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    if (item.enabled && item.grow > 0) {
      box = Expanded(
        flex: item.grow,
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: <Color>[_accentA, _accentB],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white, width: 1.4),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return box;
  }

  Widget _enumPicker<T>({
    required String label,
    required List<T> values,
    required T current,
    required String Function(T) labelOf,
    required ValueChanged<T> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: values.map((T v) {
            final bool selected = v == current;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(v);
              },
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
                child: Text(
                  labelOf(v),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _sliderRow({
    required String label,
    required int value,
    required int min,
    required int max,
    String? suffix,
    required ValueChanged<int> onChanged,
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
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
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
                  '$value${suffix ?? ''}',
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
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: max - min,
              onChanged: (double v) => onChanged(v.round()),
            ),
          ),
        ],
      ),
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

  Widget _textFieldRow({
    required String label,
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 12,
              fontFamily: 'monospace',
            ),
            isDense: true,
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
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
        ),
      ],
    );
  }

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

  Widget _miniIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              size: 16,
              color: onTap == null ? Colors.white24 : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniTextButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _accentB,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
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
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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

  Widget _dashedButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _accentB.withOpacity(0.4), width: 1),
          color: _accentB.withOpacity(0.06),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.add_rounded, color: _accentB, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: _accentB,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return IgnorePointer(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
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
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
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