import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide TableRow, TableCell;
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

const double _rowHeight = 42.0;
const double _rowNumWidth = 46.0;
const double _rowActionsWidth = 40.0;
const double _minColWidth = 100.0;

class TableViewer extends StatefulWidget {
  const TableViewer({super.key});

  @override
  State<TableViewer> createState() => _TableViewerState();
}

class _TableViewerState extends State<TableViewer>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final TextEditingController _inputCtrl = TextEditingController();
  final TextEditingController _filterCtrl = TextEditingController();
  final ScrollController _hCtrl = ScrollController();
  final ScrollController _vCtrl = ScrollController();

  TableFormat _inputFormat = TableFormat.csv;
  TableFormat _outputFormat = TableFormat.json;
  final TableViewOptions _options = TableViewOptions();

  TableData _table = TableData.empty();
  String? _parseErrorKey;
  String? _parseErrorDetail;
  bool _parsed = false;

  String? _sortColumnId;
  bool _sortAsc = true;
  String _globalFilter = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _filterCtrl.addListener(() {
      setState(() => _globalFilter = _filterCtrl.text);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inputCtrl.dispose();
    _filterCtrl.dispose();
    _hCtrl.dispose();
    _vCtrl.dispose();
    super.dispose();
  }

  List<TableRow> get _displayRows {
    List<TableRow> rows = List<TableRow>.from(_table.rows);

    if (_globalFilter.trim().isNotEmpty) {
      final String q = _globalFilter.trim().toLowerCase();
      rows = rows.where((TableRow r) {
        for (final TableCell c in r.cells) {
          if (c.displayValue.toLowerCase().contains(q)) return true;
        }
        return false;
      }).toList();
    }

    if (_sortColumnId != null) {
      final int colIdx =
      _table.columns.indexWhere((TableColumn c) => c.id == _sortColumnId);
      if (colIdx != -1) {
        rows.sort((TableRow a, TableRow b) {
          final dynamic av =
          colIdx < a.cells.length ? a.cells[colIdx].value : null;
          final dynamic bv =
          colIdx < b.cells.length ? b.cells[colIdx].value : null;
          final int cmp = _compareValues(av, bv);
          return _sortAsc ? cmp : -cmp;
        });
      }
    }

    return rows;
  }

  int _compareValues(dynamic a, dynamic b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;

    if (a is num && b is num) return a.compareTo(b);
    if (a is bool && b is bool) {
      return (a ? 1 : 0).compareTo(b ? 1 : 0);
    }
    return a.toString().toLowerCase().compareTo(b.toString().toLowerCase());
  }

  double get _totalWidth {
    double w = 0;
    for (final TableColumn c in _table.columns) {
      w += c.width;
    }
    return _rowNumWidth + w + _rowActionsWidth;
  }

  void _parse() {
    FocusScope.of(context).unfocus();

    final TableParseResult result = TableParser.parse(
      _inputCtrl.text,
      _inputFormat,
      options: _options,
    );

    if (result.hasError) {
      setState(() {
        _parsed = false;
        _parseErrorKey = result.errorKey;
        _parseErrorDetail = result.errorDetail;
        _table = TableData.empty();
        _sortColumnId = null;
      });
      return;
    }

    setState(() {
      _parsed = true;
      _table = result.data;
      _parseErrorKey = null;
      _parseErrorDetail = null;
      _sortColumnId = null;
      _filterCtrl.clear();
      _globalFilter = '';
    });

    _tabController.animateTo(1);
  }

  void _clearAll() {
    setState(() {
      _inputCtrl.clear();
      _table = TableData.empty();
      _parsed = false;
      _parseErrorKey = null;
      _parseErrorDetail = null;
      _sortColumnId = null;
      _globalFilter = '';
      _filterCtrl.clear();
    });
  }

  Future<void> _pasteInput() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null || data.text!.isEmpty) return;
    setState(() {
      _inputCtrl.text = data.text!;
    });
  }

  void _toggleSort(String columnId) {
    setState(() {
      if (_sortColumnId == columnId) {
        if (_sortAsc) {
          _sortAsc = false;
        } else {
          _sortColumnId = null;
          _sortAsc = true;
        }
      } else {
        _sortColumnId = columnId;
        _sortAsc = true;
      }
    });
  }

  void _showColumnMenu(TableColumn col, Offset position) async {
    final RenderBox overlay =
    Overlay.of(context).context.findRenderObject() as RenderBox;

    final String? action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        overlay.size.width - position.dx,
        overlay.size.height - position.dy,
      ),
      color: const Color(0xFF2A1550),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.15)),
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'sort_asc',
          child: _menuItem(
            icon: Icons.arrow_upward_rounded,
            label: context.t('tableviewer_sort_asc'),
          ),
        ),
        PopupMenuItem<String>(
          value: 'sort_desc',
          child: _menuItem(
            icon: Icons.arrow_downward_rounded,
            label: context.t('tableviewer_sort_desc'),
          ),
        ),
        PopupMenuItem<String>(
          value: 'rename',
          child: _menuItem(
            icon: Icons.edit_rounded,
            label: context.t('tableviewer_rename'),
          ),
        ),
        PopupMenuItem<String>(
          value: 'resize',
          child: _menuItem(
            icon: Icons.open_in_full_rounded,
            label: context.t('tableviewer_resize'),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'delete',
          child: _menuItem(
            icon: Icons.delete_outline_rounded,
            label: context.t('tableviewer_delete_column'),
            color: _danger,
          ),
        ),
      ],
    );

    if (!mounted || action == null) return;

    switch (action) {
      case 'sort_asc':
        setState(() {
          _sortColumnId = col.id;
          _sortAsc = true;
        });
        break;
      case 'sort_desc':
        setState(() {
          _sortColumnId = col.id;
          _sortAsc = false;
        });
        break;
      case 'rename':
        await _renameColumn(col);
        break;
      case 'resize':
        await _resizeColumn(col);
        break;
      case 'delete':
        _deleteColumn(col);
        break;
    }
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    Color color = Colors.white,
  }) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 13),
        ),
      ],
    );
  }

  Future<void> _renameColumn(TableColumn col) async {
    final TextEditingController ctrl =
    TextEditingController(text: col.name);
    final String? result = await _showInputDialog(
      title: context.t('tableviewer_rename'),
      hint: context.t('tableviewer_column_name'),
      controller: ctrl,
    );
    ctrl.dispose();
    if (result == null || result.trim().isEmpty) return;
    setState(() {
      col.name = result.trim();
    });
  }

  Future<void> _resizeColumn(TableColumn col) async {
    final double? result = await showDialog<double>(
      context: context,
      builder: (BuildContext ctx) {
        double value = col.width.toDouble();
        return StatefulBuilder(
          builder: (BuildContext c, StateSetter setModalState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: _glassDialog(
                title: context.t('tableviewer_resize'),
                children: <Widget>[
                  Text(
                    '${value.round()} px',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                  Slider(
                    value: value,
                    min: 60,
                    max: 400,
                    divisions: 34,
                    activeColor: _accentB,
                    inactiveColor: Colors.white.withOpacity(0.1),
                    onChanged: (double v) =>
                        setModalState(() => value = v),
                  ),
                  _dialogActions(
                    ctx: ctx,
                    onConfirm: () => Navigator.pop(ctx, value),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (result == null) return;
    setState(() {
      // NOTE: models.dart-da TableColumn.width sahəsi 'double' olmalıdır.
      // Əgər hələ 'int' kimi təyin olunubsa, aşağıdakı sətri
      // `col.width = result.round();` ilə əvəz et.
      col.width = result;
    });
  }

  void _deleteColumn(TableColumn col) {
    setState(() {
      final int idx =
      _table.columns.indexWhere((TableColumn c) => c.id == col.id);
      if (idx == -1) return;
      _table.columns.removeAt(idx);
      for (final TableRow r in _table.rows) {
        if (idx < r.cells.length) {
          r.cells.removeAt(idx);
        }
      }
      if (_sortColumnId == col.id) _sortColumnId = null;
    });
  }

  void _addColumn() async {
    final TextEditingController ctrl = TextEditingController(
      text: 'Column ${_table.columns.length + 1}',
    );
    final String? result = await _showInputDialog(
      title: context.t('tableviewer_add_column'),
      hint: context.t('tableviewer_column_name'),
      controller: ctrl,
    );
    ctrl.dispose();
    if (result == null || result.trim().isEmpty) return;
    setState(() {
      _table.columns.add(
        TableColumn(
          id: TableParser.newColumnId(),
          name: result.trim(),
        ),
      );
      for (final TableRow r in _table.rows) {
        r.cells.add(TableCell());
      }
    });
  }

  void _addRow() {
    setState(() {
      final List<TableCell> cells = List<TableCell>.generate(
        _table.columns.length,
            (_) => TableCell(),
      );
      _table.rows.add(
        TableRow(id: TableParser.newRowId(), cells: cells),
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_vCtrl.hasClients) {
        _vCtrl.animateTo(
          _vCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _duplicateRow(String rowId) {
    final int idx =
    _table.rows.indexWhere((TableRow r) => r.id == rowId);
    if (idx == -1) return;
    setState(() {
      final TableRow copy = _table.rows[idx].copy();
      _table.rows.insert(
        idx + 1,
        TableRow(id: TableParser.newRowId(), cells: copy.cells),
      );
    });
  }

  void _deleteRow(String rowId) {
    setState(() {
      _table.rows.removeWhere((TableRow r) => r.id == rowId);
    });
  }

  Future<void> _editCell(String rowId, int colIndex) async {
    final int rowIdx =
    _table.rows.indexWhere((TableRow r) => r.id == rowId);
    if (rowIdx == -1) return;

    final TableRow row = _table.rows[rowIdx];
    if (colIndex >= row.cells.length) return;

    final TableCell cell = row.cells[colIndex];
    final TextEditingController ctrl =
    TextEditingController(text: cell.displayValue);

    final String? result = await _showInputDialog(
      title:
      '${_table.columns[colIndex].name} • ${context.t('tableviewer_edit_cell')}',
      hint: context.t('tableviewer_value'),
      controller: ctrl,
      multiline: true,
    );
    ctrl.dispose();

    if (result == null) return;

    setState(() {
      final TableCell updated = _options.autoDetectTypes
          ? TableCell.fromDynamic(result)
          : TableCell(value: result, type: CellType.string);
      row.cells[colIndex] = updated;
    });
  }

  Future<String?> _showInputDialog({
    required String title,
    required String hint,
    required TextEditingController controller,
    bool multiline = false,
  }) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: _glassDialog(
          title: title,
          children: <Widget>[
            _glassTextField(
              controller: controller,
              hint: hint,
              maxLines: multiline ? 5 : 1,
              minLines: multiline ? 2 : 1,
            ),
            const SizedBox(height: 16),
            _dialogActions(
              ctx: ctx,
              onConfirm: () => Navigator.pop(ctx, controller.text),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogActions({
    required BuildContext ctx,
    required VoidCallback onConfirm,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            context.t('tableviewer_cancel'),
            style: const TextStyle(color: Colors.white60),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onConfirm,
          child: Text(
            context.t('tableviewer_confirm'),
            style: const TextStyle(
              color: _accentB,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _glassDialog({
    required String title,
    required List<Widget> children,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2A1550).withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 14),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copyOutput() async {
    final String output = TableParser.export(
      _table,
      _outputFormat,
      options: _options,
    );
    if (output.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: output));
    if (!mounted) return;
    _showSnack(context.t('tableviewer_copied'));
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
        title: Text(context.t('tableviewer_title')),
        actions: <Widget>[
          if (_tabController.index == 0)
            _glassIconButton(
              icon: Icons.content_paste_rounded,
              tooltip: context.t('tableviewer_paste'),
              onTap: _pasteInput,
            ),
          _glassIconButton(
            icon: Icons.cleaning_services_outlined,
            tooltip: context.t('tableviewer_clear'),
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
                    _buildTableTab(),
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
            onTap: (int i) => setState(() {}),
            tabs: <Widget>[
              Tab(text: context.t('tableviewer_tab_input')),
              Tab(text: context.t('tableviewer_tab_table')),
              Tab(text: context.t('tableviewer_tab_output')),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- INPUT TAB ----------------

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
                  labelKey: 'tableviewer_input_format',
                ),
                const SizedBox(height: 10),
                _formatSelector(
                  current: _inputFormat,
                  onChanged: (TableFormat f) =>
                      setState(() => _inputFormat = f),
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
                  labelKey: 'tableviewer_options',
                ),
                const SizedBox(height: 8),
                _optionSwitch(
                  labelKey: 'tableviewer_opt_auto_types',
                  value: _options.autoDetectTypes,
                  onChanged: (bool v) =>
                      setState(() => _options.autoDetectTypes = v),
                ),
                _optionSwitch(
                  labelKey: 'tableviewer_opt_flatten',
                  value: _options.flattenNested,
                  onChanged: (bool v) =>
                      setState(() => _options.flattenNested = v),
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
                  icon: Icons.data_object_rounded,
                  labelKey: 'tableviewer_input_label',
                ),
                const SizedBox(height: 10),
                _glassTextField(
                  controller: _inputCtrl,
                  hint: _inputHint(),
                  maxLines: 14,
                  minLines: 8,
                  monospace: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _primaryButton(
            icon: Icons.table_chart_rounded,
            labelKey: 'tableviewer_parse',
            onTap: _parse,
          ),
          if (_parseErrorKey != null) ...<Widget>[
            const SizedBox(height: 14),
            _errorBox(_parseErrorKey!, _parseErrorDetail),
          ],
        ],
      ),
    );
  }

  String _inputHint() {
    switch (_inputFormat) {
      case TableFormat.csv:
        return 'id,name,email\n1,John,john@example.com\n2,Jane,jane@example.com';
      case TableFormat.tsv:
        return 'id\tname\temail\n1\tJohn\tjohn@example.com';
      case TableFormat.json:
        return '[\n  { "id": 1, "name": "John" },\n  { "id": 2, "name": "Jane" }\n]';
      case TableFormat.markdown:
        return '| id | name |\n|----|------|\n| 1  | John |\n| 2  | Jane |';
    }
  }

  // ---------------- TABLE TAB ----------------

  Widget _buildTableTab() {
    if (!_parsed || _table.columns.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.table_chart_outlined,
                size: 48,
                color: Colors.white.withOpacity(0.25),
              ),
              const SizedBox(height: 12),
              Text(
                context.t('tableviewer_no_data'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      );
    }

    final List<TableRow> display = _displayRows;

    return Column(
      children: <Widget>[
        _tableToolbar(display.length),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: _GlassCard(
              padding: EdgeInsets.zero,
              radius: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Scrollbar(
                  controller: _hCtrl,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _hCtrl,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: _totalWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _headerRow(),
                          Expanded(
                            child: Scrollbar(
                              controller: _vCtrl,
                              child: ListView.builder(
                                controller: _vCtrl,
                                itemExtent: _rowHeight,
                                itemCount: display.length,
                                itemBuilder: (BuildContext ctx, int i) {
                                  return _dataRow(display[i], i);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tableToolbar(int displayCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: _GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        radius: 14,
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _accentA.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _accentA.withOpacity(0.5)),
                  ),
                  child: Text(
                    '${_table.rows.length} × ${_table.columns.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (_globalFilter.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(width: 8),
                  Text(
                    '$displayCount ${context.t('tableviewer_filtered')}',
                    style: const TextStyle(
                      color: _warning,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const Spacer(),
                _smallButton(
                  icon: Icons.add_rounded,
                  labelKey: 'tableviewer_add_row',
                  onTap: _addRow,
                ),
                const SizedBox(width: 6),
                _smallButton(
                  icon: Icons.view_column_rounded,
                  labelKey: 'tableviewer_add_col',
                  onTap: _addColumn,
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _filterCtrl,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
              decoration: InputDecoration(
                hintText: context.t('tableviewer_filter_hint'),
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 12,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 16,
                  color: Colors.white54,
                ),
                suffixIcon: _globalFilter.isEmpty
                    ? null
                    : IconButton(
                  onPressed: () => _filterCtrl.clear(),
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Colors.white54,
                  ),
                  splashRadius: 14,
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
      ),
    );
  }

  Widget _smallButton({
    required IconData icon,
    required String labelKey,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: _accentB.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _accentB.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 14, color: _accentB),
              const SizedBox(width: 6),
              Text(
                context.t(labelKey),
                style: const TextStyle(
                  color: _accentB,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerRow() {
    return Container(
      height: _rowHeight,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: _rowNumWidth,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            child: Text(
              '#',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (final TableColumn col in _table.columns)
            _headerCell(col),
          SizedBox(
            width: _rowActionsWidth,
            child: Center(
              child: Icon(
                Icons.more_horiz_rounded,
                size: 16,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(TableColumn col) {
    final bool sorted = _sortColumnId == col.id;
    final IconData? sortIcon = !sorted
        ? null
        : _sortAsc
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;

    return GestureDetector(
      onSecondaryTapDown: (TapDownDetails d) =>
          _showColumnMenu(col, d.globalPosition),
      onLongPressStart: (LongPressStartDetails d) =>
          _showColumnMenu(col, d.globalPosition),
      onTap: () => _toggleSort(col.id),
      child: Container(
        width: col.width,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    col.name,
                    style: TextStyle(
                      color: sorted ? _accentB : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    context.t(col.type.labelKey),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 9,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            if (sortIcon != null)
              Icon(sortIcon, size: 14, color: _accentB)
            else
              Icon(
                Icons.unfold_more_rounded,
                size: 14,
                color: Colors.white.withOpacity(0.2),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dataRow(TableRow row, int displayIndex) {
    return Container(
      height: _rowHeight,
      decoration: BoxDecoration(
        color: displayIndex.isEven
            ? Colors.white.withOpacity(0.02)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: _rowNumWidth,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            child: Text(
              '${displayIndex + 1}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (int i = 0; i < _table.columns.length; i++)
            _dataCell(row, i),
          SizedBox(
            width: _rowActionsWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                GestureDetector(
                  onTap: () => _duplicateRow(row.id),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color: Colors.white38,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _deleteRow(row.id),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Colors.white38,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataCell(TableRow row, int colIndex) {
    if (colIndex >= row.cells.length) {
      return SizedBox(width: _table.columns[colIndex].width);
    }

    final TableCell cell = row.cells[colIndex];
    final TableColumn col = _table.columns[colIndex];
    final Color textColor = _typeColor(cell.type);

    return GestureDetector(
      onTap: () => _editCell(row.id, colIndex),
      child: Container(
        width: col.width,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: Colors.white.withOpacity(0.08),
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Align(
          alignment: _typeAlignment(cell.type),
          child: Text(
            cell.displayValue,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontFamily: cell.type == CellType.string ? null : 'monospace',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Alignment _typeAlignment(CellType type) {
    if (type == CellType.integer || type == CellType.double) {
      return Alignment.centerRight;
    }
    if (type == CellType.boolean) {
      return Alignment.center;
    }
    return Alignment.centerLeft;
  }

  Color _typeColor(CellType type) {
    switch (type) {
      case CellType.string:
        return Colors.white;
      case CellType.integer:
      case CellType.double:
        return _accentB;
      case CellType.boolean:
        return _warning;
      case CellType.nullValue:
        return Colors.white38;
      case CellType.object:
      case CellType.array:
        return _accentA;
    }
  }

  // ---------------- OUTPUT TAB ----------------

  Widget _buildOutputTab() {
    if (!_parsed || _table.columns.isEmpty) {
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
                context.t('tableviewer_no_output'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      );
    }

    final String output = TableParser.export(
      _table,
      _outputFormat,
      options: _options,
    );

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
                  labelKey: 'tableviewer_output_format',
                ),
                const SizedBox(height: 10),
                _formatSelector(
                  current: _outputFormat,
                  onChanged: (TableFormat f) =>
                      setState(() => _outputFormat = f),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
                  '${_table.rows.length} rows × ${_table.columns.length} cols',
                  style: const TextStyle(
                    color: _success,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
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
                  context.t('tableviewer_copy'),
                  style: const TextStyle(color: _accentB, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _GlassCard(
            padding: const EdgeInsets.all(14),
            child: SelectableText(
              output,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                height: 1.55,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- SHARED WIDGETS ----------------

  Widget _formatSelector({
    required TableFormat current,
    required ValueChanged<TableFormat> onChanged,
  }) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: TableFormat.values.map((TableFormat f) {
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
        height: 1.4,
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