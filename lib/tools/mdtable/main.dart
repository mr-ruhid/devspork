import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/app_localization.dart';
import 'generator.dart';
import 'models.dart';
import 'parser.dart';

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

class MdTableBuilder extends StatefulWidget {
  const MdTableBuilder({super.key});

  @override
  State<MdTableBuilder> createState() => _MdTableBuilderState();
}

class _MdTableBuilderState extends State<MdTableBuilder>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  final MdTable _table = MdTable.empty();
  TableOptions _opts = const TableOptions();
  ImportOptions _impOpts = const ImportOptions();
  ImportFormat _impFmt = ImportFormat.markdown;

  final Map<String, TextEditingController> _cellCtrls =
  <String, TextEditingController>{};
  final Map<int, TextEditingController> _headerCtrls =
  <int, TextEditingController>{};
  final TextEditingController _impCtrl = TextEditingController();

  Timer? _debounce;
  String _output = '';
  String? _errorKey;
  String? _errorDetail;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _rebuildControllers();
    _regenerate();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabs.dispose();
    for (final TextEditingController c in _cellCtrls.values) {
      c.dispose();
    }
    for (final TextEditingController c in _headerCtrls.values) {
      c.dispose();
    }
    _impCtrl.dispose();
    super.dispose();
  }

  void _rebuildControllers() {
    final Map<int, TextEditingController> newHeaders =
    <int, TextEditingController>{};
    final Map<String, TextEditingController> newCells =
    <String, TextEditingController>{};

    for (int c = 0; c < _table.columnCount; c++) {
      final TextEditingController ctrl =
      TextEditingController(text: _table.headers[c]);
      final int col = c;
      ctrl.addListener(() {
        _table.setHeader(col, ctrl.text);
        _scheduleRegen();
      });
      newHeaders[c] = ctrl;
    }

    for (int r = 0; r < _table.rowCount; r++) {
      for (int c = 0; c < _table.columnCount; c++) {
        final TextEditingController ctrl =
        TextEditingController(text: _table.rows[r][c]);
        final int row = r;
        final int col = c;
        ctrl.addListener(() {
          _table.setCell(row, col, ctrl.text);
          _scheduleRegen();
        });
        newCells['$r:$c'] = ctrl;
      }
    }

    for (final TextEditingController c in _headerCtrls.values) {
      c.dispose();
    }
    for (final TextEditingController c in _cellCtrls.values) {
      c.dispose();
    }

    _headerCtrls
      ..clear()
      ..addAll(newHeaders);
    _cellCtrls
      ..clear()
      ..addAll(newCells);
  }

  void _scheduleRegen() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), _regenerate);
  }

  void _regenerate() {
    final String out = MdTableGenerator.generate(_table, _opts);
    if (!mounted) return;
    setState(() => _output = out);
  }

  void _structural(VoidCallback change) {
    setState(() {
      change();
      _rebuildControllers();
      _regenerate();
    });
  }

  Future<void> _copyOutput() async {
    if (_output.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _output));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _copied = true);
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _pasteImport() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null || data.text!.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _impCtrl.text = data.text!);
  }

  void _clearImport() {
    HapticFeedback.selectionClick();
    setState(() {
      _impCtrl.clear();
      _errorKey = null;
      _errorDetail = null;
    });
  }

  void _import() {
    FocusScope.of(context).unfocus();
    final String input = _impCtrl.text;
    if (input.trim().isEmpty) {
      setState(() {
        _errorKey = MdTableErrors.emptyInput;
        _errorDetail = null;
      });
      return;
    }
    try {
      final MdTable parsed = MdTableParser.parse(input, _impFmt, _impOpts);
      setState(() {
        _table.replaceWith(parsed);
        _rebuildControllers();
        _regenerate();
        _errorKey = null;
        _errorDetail = null;
        _tabs.animateTo(0);
      });
    } on MdParseException catch (e) {
      setState(() {
        _errorKey = e.errorKey;
        _errorDetail = e.detail;
      });
    } catch (e) {
      setState(() {
        _errorKey = MdTableErrors.invalidMarkdown;
        _errorDetail = e.toString();
      });
    }
  }

  MdColumnAlign _nextAlign(MdColumnAlign current) {
    switch (current) {
      case MdColumnAlign.none:
        return MdColumnAlign.left;
      case MdColumnAlign.left:
        return MdColumnAlign.center;
      case MdColumnAlign.center:
        return MdColumnAlign.right;
      case MdColumnAlign.right:
        return MdColumnAlign.none;
    }
  }

  void _cycleAlign(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      final MdColumnAlign current = index < _table.aligns.length
          ? _table.aligns[index]
          : MdColumnAlign.none;
      _table.setAlign(index, _nextAlign(current));
      _regenerate();
    });
  }

  void _resetTable() {
    HapticFeedback.mediumImpact();
    _structural(() => _table.replaceWith(MdTable.empty()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0B0B12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.t('mdtable_title')),
        actions: <Widget>[
          _glassIconButton(
            icon: Icons.refresh_rounded,
            tooltip: _tr(context, 'mdtable_reset', 'Reset'),
            onTap: _resetTable,
          ),
          const SizedBox(width: 8),
        ],
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
                padding: const EdgeInsets.only(top: 60),
                child: TabBarView(
                  controller: _tabs,
                  children: <Widget>[
                    _buildBuilderTab(),
                    _buildImportTab(),
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
              Tab(text: context.t('mdtable_tab_builder')),
              Tab(text: context.t('mdtable_tab_import')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBuilderTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildOptionsCard(),
          const SizedBox(height: 14),
          _buildHeadersCard(),
          const SizedBox(height: 14),
          _buildRowsSection(),
          const SizedBox(height: 14),
          _buildOutputCard(),
        ],
      ),
    );
  }

  Widget _buildOptionsCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            Icons.tune_rounded,
            _tr(context, 'mdtable_options', 'Options'),
          ),
          const SizedBox(height: 6),
          _switchRow(
            label: _tr(context, 'mdtable_opt_pretty', 'Pretty print'),
            value: _opts.prettyPrint,
            onChanged: (bool v) => setState(() {
              _opts = _opts.copyWith(prettyPrint: v);
              _regenerate();
            }),
          ),
          _switchRow(
            label: _tr(context, 'mdtable_opt_escape', 'Escape pipes in cells'),
            value: _opts.escapePipes,
            onChanged: (bool v) => setState(() {
              _opts = _opts.copyWith(escapePipes: v);
              _regenerate();
            }),
          ),
          _switchRow(
            label: _tr(context, 'mdtable_opt_outer', 'Outer pipes'),
            value: _opts.outerPipes,
            onChanged: (bool v) => setState(() {
              _opts = _opts.copyWith(outerPipes: v);
              _regenerate();
            }),
          ),
          _switchRow(
            label: _tr(context, 'mdtable_opt_trim', 'Trim whitespace'),
            value: _opts.trimCells,
            onChanged: (bool v) => setState(() {
              _opts = _opts.copyWith(trimCells: v);
              _regenerate();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadersCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _sectionTitle(
                  Icons.view_column_rounded,
                  _tr(context, 'mdtable_headers', 'Columns'),
                ),
              ),
              Text(
                '${_table.columnCount}',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (int c = 0; c < _table.columnCount; c++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 22,
                    child: Text(
                      '${c + 1}',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  Expanded(
                    child: _inlineField(
                      controller: _headerCtrls[c]!,
                      hint: _tr(context, 'mdtable_header_hint', 'Column name'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _alignChip(c),
                  const SizedBox(width: 2),
                  _miniIconButton(
                    icon: Icons.close_rounded,
                    tooltip: _tr(context, 'mdtable_remove_col', 'Remove column'),
                    onTap: _table.columnCount <= 1
                        ? null
                        : () {
                      HapticFeedback.mediumImpact();
                      _structural(() => _table.removeColumn(c));
                    },
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          _dashedButton(
            label: _tr(context, 'mdtable_add_col', 'Add column'),
            icon: Icons.add_rounded,
            onTap: () {
              HapticFeedback.selectionClick();
              _structural(() {
                _table.addColumn(
                  header: 'Column ${_table.columnCount + 1}',
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _alignChip(int index) {
    final MdColumnAlign align = index < _table.aligns.length
        ? _table.aligns[index]
        : MdColumnAlign.none;
    return Tooltip(
      message: _tr(context, align.labelKey, 'Alignment'),
      child: GestureDetector(
        onTap: () => _cycleAlign(index),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: align == MdColumnAlign.none
                ? Colors.white.withOpacity(0.06)
                : _accentB.withOpacity(0.18),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: align == MdColumnAlign.none
                  ? Colors.white.withOpacity(0.15)
                  : _accentB.withOpacity(0.5),
            ),
          ),
          child: Text(
            align.glyph,
            style: TextStyle(
              fontSize: 14,
              color: align == MdColumnAlign.none ? Colors.white60 : _accentB,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRowsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int r = 0; r < _table.rowCount; r++) ...<Widget>[
          _buildRowCard(r),
          const SizedBox(height: 10),
        ],
        _dashedButton(
          label: _tr(context, 'mdtable_add_row', 'Add row'),
          icon: Icons.add_rounded,
          onTap: () {
            HapticFeedback.selectionClick();
            _structural(() => _table.addRow());
          },
        ),
      ],
    );
  }

  Widget _buildRowCard(int r) {
    return _GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _accentA.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#${r + 1}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              _miniIconButton(
                icon: Icons.arrow_upward_rounded,
                tooltip: _tr(context, 'mdtable_move_up', 'Move up'),
                onTap: r == 0
                    ? null
                    : () {
                  HapticFeedback.selectionClick();
                  _structural(() => _table.moveRow(r, r - 1));
                },
              ),
              _miniIconButton(
                icon: Icons.arrow_downward_rounded,
                tooltip: _tr(context, 'mdtable_move_down', 'Move down'),
                onTap: r == _table.rowCount - 1
                    ? null
                    : () {
                  HapticFeedback.selectionClick();
                  _structural(() => _table.moveRow(r, r + 1));
                },
              ),
              _miniIconButton(
                icon: Icons.copy_rounded,
                tooltip: _tr(context, 'mdtable_duplicate', 'Duplicate'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  _structural(() => _table.duplicateRow(r));
                },
              ),
              _miniIconButton(
                icon: Icons.close_rounded,
                tooltip: _tr(context, 'mdtable_remove_row', 'Remove'),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _structural(() => _table.removeRow(r));
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (int c = 0; c < _table.columnCount; c++)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _table.headers[c].isEmpty
                        ? 'Column ${c + 1}'
                        : _table.headers[c],
                    style: const TextStyle(
                      color: _accentB,
                      fontSize: 10,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _inlineField(
                    controller: _cellCtrls['$r:$c']!,
                    hint: _tr(context, 'mdtable_cell_hint', 'Value'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOutputCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _sectionTitle(
                  Icons.code_rounded,
                  _tr(context, 'mdtable_output', 'Markdown output'),
                ),
              ),
              _glassIconButton(
                icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
                tooltip: _copied
                    ? _tr(context, 'mdtable_copied', 'Copied')
                    : _tr(context, 'mdtable_copy', 'Copy'),
                onTap: _copyOutput,
                highlighted: _copied,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 120),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: SelectableText(
              _output.isEmpty
                  ? _tr(context, 'mdtable_output_empty', 'Add data to see markdown...')
                  : _output,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                height: 1.5,
                color: _output.isEmpty ? Colors.white38 : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _sectionTitle(
                  Icons.download_rounded,
                  _tr(context, 'mdtable_import_format', 'Input format'),
                ),
                const SizedBox(height: 10),
                _formatSelector(),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _sectionTitle(
                        Icons.content_paste_rounded,
                        _tr(context, 'mdtable_import_input', 'Paste data'),
                      ),
                    ),
                    _glassIconButton(
                      icon: Icons.content_paste_rounded,
                      tooltip: _tr(context, 'mdtable_paste', 'Paste'),
                      onTap: _pasteImport,
                    ),
                    const SizedBox(width: 6),
                    _glassIconButton(
                      icon: Icons.close_rounded,
                      tooltip: _tr(context, 'mdtable_clear', 'Clear'),
                      onTap: _clearImport,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _impCtrl,
                  maxLines: 12,
                  minLines: 6,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    hintText: _impFmt.placeholder,
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.28),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                      BorderSide(color: Colors.white.withOpacity(0.15)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                      BorderSide(color: Colors.white.withOpacity(0.15)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _accentB, width: 1.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_impFmt != ImportFormat.markdown) ...<Widget>[
            const SizedBox(height: 14),
            _buildImportOptionsCard(),
          ],
          if (_errorKey != null) ...<Widget>[
            const SizedBox(height: 14),
            _errorBox(_errorKey!, _errorDetail),
          ],
          const SizedBox(height: 14),
          _primaryButton(
            icon: Icons.file_download_done_rounded,
            label: _tr(context, 'mdtable_import_action', 'Import to builder'),
            onTap: _import,
          ),
        ],
      ),
    );
  }

  Widget _formatSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ImportFormat.values.map((ImportFormat f) {
        final bool selected = _impFmt == f;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _impFmt = f;
              _errorKey = null;
              _errorDetail = null;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(colors: <Color>[_accentA, _accentB])
                  : null,
              color: selected ? null : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : Colors.white.withOpacity(0.15),
              ),
            ),
            child: Text(
              _tr(context, f.labelKey, f.name.toUpperCase()),
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildImportOptionsCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            Icons.tune_rounded,
            _tr(context, 'mdtable_import_options', 'Parse options'),
          ),
          const SizedBox(height: 6),
          if (_impFmt == ImportFormat.csv || _impFmt == ImportFormat.tsv)
            _switchRow(
              label:
              _tr(context, 'mdtable_opt_has_header', 'First row is header'),
              value: _impOpts.csvHasHeader,
              onChanged: (bool v) =>
                  setState(() => _impOpts = _impOpts.copyWith(csvHasHeader: v)),
            ),
          if (_impFmt == ImportFormat.csv) _csvDelimiterRow(),
          if (_impFmt == ImportFormat.json)
            _switchRow(
              label: _tr(context, 'mdtable_opt_flatten', 'Flatten nested objects'),
              value: _impOpts.flattenJson,
              onChanged: (bool v) =>
                  setState(() => _impOpts = _impOpts.copyWith(flattenJson: v)),
            ),
        ],
      ),
    );
  }

  Widget _csvDelimiterRow() {
    const List<String> delims = <String>[',', ';', '\t', '|'];
    const List<String> labels = <String>[
      'Comma (,)',
      'Semicolon (;)',
      'Tab',
      'Pipe (|)',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'CSV delimiter',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List<Widget>.generate(delims.length, (int i) {
              final bool selected = _impOpts.csvDelimiter == delims[i];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _impOpts = _impOpts.copyWith(csvDelimiter: delims[i]);
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected
                        ? _accentB.withOpacity(0.2)
                        : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? _accentB.withOpacity(0.55)
                          : Colors.white.withOpacity(0.15),
                    ),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      color: selected ? _accentB : Colors.white70,
                      fontSize: 11,
                      fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String text) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
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

  Widget _inlineField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.35),
          fontSize: 12,
        ),
        isDense: true,
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

  Widget _primaryButton({
    required IconData icon,
    required String label,
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
              gradient: LinearGradient(colors: <Color>[_accentA, _accentB]),
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dashedButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
            Icon(icon, color: _accentB, size: 16),
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

  Widget _errorBox(String key, String? detail) {
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
                  _tr(context, key, key),
                  style: const TextStyle(
                    color: Color(0xFFFF8A8A),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          if (detail != null) ...<Widget>[
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