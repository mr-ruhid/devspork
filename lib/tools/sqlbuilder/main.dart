import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/app_localization.dart';
import 'generator.dart';
import 'models.dart';

const Color _accentA = Color(0xFF7C4DFF);
const Color _accentB = Color(0xFF00E5FF);
const Color _danger = Color(0xFFFF5C5C);
const Color _warning = Color(0xFFFFC24B);
const Color _success = Color(0xFF4BD68B);
const Color _bgTop = Color(0xFF1B1035);
const Color _bgMid = Color(0xFF2A1550);
const Color _bgBot = Color(0xFF0F2A4A);

class SqlBuilder extends StatefulWidget {
  const SqlBuilder({super.key});

  @override
  State<SqlBuilder> createState() => _SqlBuilderState();
}

class _SqlBuilderState extends State<SqlBuilder>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  SqlDialect _dialect = SqlDialect.postgres;

  final DdlTable _ddlTable = DdlTable(
    name: 'users',
    columns: <DdlColumn>[],
    indexes: <DdlIndex>[],
  );

  final QueryConfig _query = QueryConfig(
    table: 'users',
    columns: <SelectColumn>[],
    where: <WhereCondition>[],
    orderBy: <OrderByClause>[],
    groupBy: <String>[],
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));

    _addColumn(
      name: 'id',
      type: SqlColumnType.bigint,
      primaryKey: true,
      notNull: true,
      autoIncrement: true,
    );
    _addColumn(
      name: 'email',
      type: SqlColumnType.varchar,
      notNull: true,
      unique: true,
      length: 255,
    );
    _addColumn(
      name: 'name',
      type: SqlColumnType.varchar,
      length: 100,
    );
    _addColumn(
      name: 'created_at',
      type: SqlColumnType.timestamp,
      notNull: true,
      defaultValue: 'CURRENT_TIMESTAMP',
    );

    _query.columns.add(
      SelectColumn(id: IdGenerator.next('sc'), column: 'id'),
    );
    _query.columns.add(
      SelectColumn(id: IdGenerator.next('sc'), column: 'email'),
    );
    _query.columns.add(
      SelectColumn(id: IdGenerator.next('sc'), column: 'name'),
    );

    _query.where.add(
      WhereCondition(
        id: IdGenerator.next('w'),
        column: 'active',
        operator: SqlOperator.eq,
        value: 'true',
      ),
    );

    _query.orderBy.add(
      OrderByClause(id: IdGenerator.next('o'), column: 'created_at'),
    );

    _query.limit = 50;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ---------------- DDL helpers ----------------

  void _addColumn({
    String name = '',
    SqlColumnType type = SqlColumnType.varchar,
    bool primaryKey = false,
    bool notNull = false,
    bool unique = false,
    bool autoIncrement = false,
    int length = 255,
    String? defaultValue,
  }) {
    setState(() {
      _ddlTable.columns.add(
        DdlColumn(
          id: IdGenerator.next('col'),
          name: name,
          type: type,
          length: length,
          primaryKey: primaryKey,
          notNull: notNull,
          unique: unique,
          autoIncrement: autoIncrement,
          defaultValue: defaultValue,
        ),
      );
    });
  }

  void _removeColumn(String id) {
    setState(() {
      _ddlTable.columns.removeWhere((DdlColumn c) => c.id == id);
      for (final DdlIndex i in _ddlTable.indexes) {
        i.columnIds.removeWhere((String cid) => cid == id);
      }
    });
  }

  void _addIndex() {
    setState(() {
      _ddlTable.indexes.add(
        DdlIndex(
          id: IdGenerator.next('idx'),
          name: 'idx_${_ddlTable.name}_${_ddlTable.indexes.length + 1}',
        ),
      );
    });
  }

  void _removeIndex(String id) {
    setState(() {
      _ddlTable.indexes.removeWhere((DdlIndex i) => i.id == id);
    });
  }

  // ---------------- Query helpers ----------------

  void _addQueryColumn() {
    setState(() {
      _query.columns.add(
        SelectColumn(id: IdGenerator.next('sc')),
      );
    });
  }

  void _removeQueryColumn(String id) {
    setState(() {
      _query.columns.removeWhere((SelectColumn c) => c.id == id);
    });
  }

  void _addWhereCondition() {
    setState(() {
      _query.where.add(
        WhereCondition(id: IdGenerator.next('w')),
      );
    });
  }

  void _removeWhereCondition(String id) {
    setState(() {
      _query.where.removeWhere((WhereCondition w) => w.id == id);
    });
  }

  void _addOrderBy() {
    setState(() {
      _query.orderBy.add(
        OrderByClause(id: IdGenerator.next('o')),
      );
    });
  }

  void _removeOrderBy(String id) {
    setState(() {
      _query.orderBy.removeWhere((OrderByClause o) => o.id == id);
    });
  }

  void _addGroupBy() {
    setState(() {
      _query.groupBy.add('');
    });
  }

  void _removeGroupBy(int index) {
    setState(() {
      _query.groupBy.removeAt(index);
    });
  }

  // ---------------- Output ----------------

  String get _currentOutput {
    if (_tabController.index == 0) {
      return DdlGenerator.generate(_ddlTable, _dialect);
    }
    return QueryGenerator.generate(_query, _dialect);
  }

  Future<void> _copyOutput() async {
    final String out = _currentOutput;
    if (out.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: out));
    if (!mounted) return;
    _showSnack(context.t('sqlbuilder_copied'));
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
        title: Text(context.t('sqlbuilder_title')),
        actions: <Widget>[
          _glassIconButton(
            icon: Icons.copy_rounded,
            tooltip: context.t('sqlbuilder_copy'),
            onTap: _copyOutput,
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
                    _buildDdlTab(),
                    _buildQueryTab(),
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
              Tab(text: context.t('sqlbuilder_tab_ddl')),
              Tab(text: context.t('sqlbuilder_tab_query')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialectSelector() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: SqlDialect.values.map((SqlDialect d) {
        final bool selected = _dialect == d;
        return GestureDetector(
          onTap: () => setState(() => _dialect = d),
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
              d.displayName,
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

  Widget _outputCard() {
    final String output = _currentOutput;
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
                context.t('sqlbuilder_output'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
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
                  context.t('sqlbuilder_copy'),
                  style: const TextStyle(
                    color: _accentB,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: output.isEmpty
                ? Text(
              context.t('sqlbuilder_empty'),
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            )
                : SelectableText(
              output,
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

  // ---------------- DDL TAB ----------------

  Widget _buildDdlTab() {
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
                  icon: Icons.storage_rounded,
                  labelKey: 'sqlbuilder_dialect',
                ),
                const SizedBox(height: 10),
                _dialectSelector(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _sectionHeader(
                  icon: Icons.table_chart_rounded,
                  labelKey: 'sqlbuilder_table',
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _glassTextField(
                        controller: TextEditingController(
                          text: _ddlTable.name,
                        ),
                        hint: 'users',
                        onChanged: (String v) {
                          setState(() => _ddlTable.name = v.trim());
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => setState(
                            () => _ddlTable.ifNotExists = !_ddlTable.ifNotExists,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _ddlTable.ifNotExists
                              ? _accentB.withOpacity(0.15)
                              : Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _ddlTable.ifNotExists
                                ? _accentB.withOpacity(0.5)
                                : Colors.white.withOpacity(0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              _ddlTable.ifNotExists
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              size: 16,
                              color: _ddlTable.ifNotExists
                                  ? _accentB
                                  : Colors.white54,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              context.t('sqlbuilder_if_not_exists'),
                              style: TextStyle(
                                color: _ddlTable.ifNotExists
                                    ? _accentB
                                    : Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
                      Icons.view_column_rounded,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.t('sqlbuilder_columns'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_ddlTable.columns.length}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 8),
                    _smallButton(
                      icon: Icons.add_rounded,
                      onTap: _addColumn,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (int i = 0; i < _ddlTable.columns.length; i++) ...<Widget>[
                  _ddlColumnRow(_ddlTable.columns[i], i),
                  if (i < _ddlTable.columns.length - 1)
                    const SizedBox(height: 10),
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
                      Icons.speed_rounded,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.t('sqlbuilder_indexes'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    _smallButton(
                      icon: Icons.add_rounded,
                      onTap: _addIndex,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_ddlTable.indexes.isEmpty)
                  Text(
                    context.t('sqlbuilder_no_indexes'),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  )
                else
                  for (int i = 0; i < _ddlTable.indexes.length; i++) ...<Widget>[
                    _indexRow(_ddlTable.indexes[i]),
                    if (i < _ddlTable.indexes.length - 1)
                      const SizedBox(height: 10),
                  ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _outputCard(),
        ],
      ),
    );
  }

  Widget _ddlColumnRow(DdlColumn col, int index) {
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
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _accentA.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _glassTextField(
                  controller: TextEditingController(text: col.name),
                  hint: context.t('sqlbuilder_col_name'),
                  dense: true,
                  monospace: true,
                  onChanged: (String v) => setState(() => col.name = v.trim()),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _removeColumn(col.id),
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
          const SizedBox(height: 8),
          _typeSelector(col),
          if (col.type.needsLength) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: _numberField(
                    labelKey: col.type == SqlColumnType.decimal
                        ? 'sqlbuilder_precision'
                        : 'sqlbuilder_length',
                    value: col.type == SqlColumnType.decimal
                        ? col.precision
                        : col.length,
                    onChanged: (int v) => setState(() {
                      if (col.type == SqlColumnType.decimal) {
                        col.precision = v;
                      } else {
                        col.length = v;
                      }
                    }),
                  ),
                ),
                if (col.type == SqlColumnType.decimal) ...<Widget>[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _numberField(
                      labelKey: 'sqlbuilder_scale',
                      value: col.scale,
                      onChanged: (int v) => setState(() => col.scale = v),
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              _toggleChip(
                labelKey: 'sqlbuilder_pk',
                value: col.primaryKey,
                onToggle: () => setState(() {
                  col.primaryKey = !col.primaryKey;
                  if (col.primaryKey) col.notNull = true;
                }),
              ),
              _toggleChip(
                labelKey: 'sqlbuilder_not_null',
                value: col.notNull,
                onToggle: () => setState(() => col.notNull = !col.notNull),
              ),
              _toggleChip(
                labelKey: 'sqlbuilder_unique',
                value: col.unique,
                onToggle: () => setState(() => col.unique = !col.unique),
              ),
              _toggleChip(
                labelKey: 'sqlbuilder_auto_increment',
                value: col.autoIncrement,
                onToggle: () => setState(
                      () => col.autoIncrement = !col.autoIncrement,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _glassTextField(
            controller: TextEditingController(text: col.defaultValue ?? ''),
            hint: context.t('sqlbuilder_default_hint'),
            dense: true,
            monospace: true,
            onChanged: (String v) {
              col.defaultValue = v.trim().isEmpty ? null : v.trim();
            },
          ),
        ],
      ),
    );
  }

  Widget _typeSelector(DdlColumn col) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: SqlColumnType.values.map((SqlColumnType t) {
        final bool selected = col.type == t;
        return GestureDetector(
          onTap: () => setState(() {
            col.type = t;
            if (t == SqlColumnType.varchar && col.length == 0) {
              col.length = 255;
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
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
              t.displayName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontFamily: 'monospace',
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _numberField({
    required String labelKey,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            context.t(labelKey),
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ),
        SizedBox(
          width: 70,
          child: TextField(
            controller: TextEditingController(text: '$value'),
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            onChanged: (String v) {
              final int? n = int.tryParse(v);
              if (n != null && n > 0) onChanged(n);
            },
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                BorderSide(color: Colors.white.withOpacity(0.15)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                BorderSide(color: Colors.white.withOpacity(0.15)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                const BorderSide(color: _accentB, width: 1.2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _indexRow(DdlIndex idx) {
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
              Expanded(
                child: _glassTextField(
                  controller: TextEditingController(text: idx.name),
                  hint: context.t('sqlbuilder_index_name'),
                  dense: true,
                  monospace: true,
                  onChanged: (String v) =>
                      setState(() => idx.name = v.trim()),
                ),
              ),
              const SizedBox(width: 8),
              _toggleChip(
                labelKey: 'sqlbuilder_unique',
                value: idx.unique,
                onToggle: () => setState(() => idx.unique = !idx.unique),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => _removeIndex(idx.id),
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
          const SizedBox(height: 8),
          Text(
            context.t('sqlbuilder_index_columns'),
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
          const SizedBox(height: 6),
          if (_ddlTable.columns.isEmpty)
            Text(
              context.t('sqlbuilder_no_columns'),
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _ddlTable.columns.map((DdlColumn c) {
                final bool selected = idx.columnIds.contains(c.id);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      idx.columnIds.remove(c.id);
                    } else {
                      idx.columnIds.add(c.id);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
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
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? Colors.transparent
                            : Colors.white.withOpacity(0.15),
                      ),
                    ),
                    child: Text(
                      c.name.isEmpty ? '?' : c.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w400,
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

  // ---------------- QUERY TAB ----------------

  Widget _buildQueryTab() {
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
                  icon: Icons.storage_rounded,
                  labelKey: 'sqlbuilder_dialect',
                ),
                const SizedBox(height: 10),
                _dialectSelector(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _sectionHeader(
                  icon: Icons.table_chart_rounded,
                  labelKey: 'sqlbuilder_from_table',
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _glassTextField(
                        controller: TextEditingController(
                          text: _query.table,
                        ),
                        hint: 'users',
                        onChanged: (String v) =>
                            setState(() => _query.table = v.trim()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _toggleChip(
                      labelKey: 'sqlbuilder_distinct',
                      value: _query.distinct,
                      onToggle: () =>
                          setState(() => _query.distinct = !_query.distinct),
                    ),
                  ],
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
                      Icons.checklist_rounded,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.t('sqlbuilder_select_columns'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _smallButton(
                      icon: Icons.add_rounded,
                      onTap: _addQueryColumn,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_query.columns.isEmpty)
                  Text(
                    context.t('sqlbuilder_select_all_hint'),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  )
                else
                  for (int i = 0; i < _query.columns.length; i++) ...<Widget>[
                    _selectColumnRow(_query.columns[i]),
                    if (i < _query.columns.length - 1)
                      const SizedBox(height: 6),
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
                      Icons.filter_alt_rounded,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.t('sqlbuilder_where'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _smallButton(
                      icon: Icons.add_rounded,
                      onTap: _addWhereCondition,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_query.where.isEmpty)
                  Text(
                    context.t('sqlbuilder_no_where'),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  )
                else
                  for (int i = 0; i < _query.where.length; i++) ...<Widget>[
                    _whereRow(_query.where[i], i),
                    if (i < _query.where.length - 1)
                      const SizedBox(height: 8),
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
                      Icons.group_work_rounded,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.t('sqlbuilder_group_by'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _smallButton(
                      icon: Icons.add_rounded,
                      onTap: _addGroupBy,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (int i = 0; i < _query.groupBy.length; i++) ...<Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _glassTextField(
                          controller: TextEditingController(
                            text: _query.groupBy[i],
                          ),
                          hint: 'column',
                          dense: true,
                          monospace: true,
                          onChanged: (String v) =>
                          _query.groupBy[i] = v.trim(),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: () => _removeGroupBy(i),
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
                  if (i < _query.groupBy.length - 1)
                    const SizedBox(height: 6),
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
                      Icons.sort_rounded,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.t('sqlbuilder_order_by'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _smallButton(
                      icon: Icons.add_rounded,
                      onTap: _addOrderBy,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_query.orderBy.isEmpty)
                  Text(
                    context.t('sqlbuilder_no_order'),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  )
                else
                  for (int i = 0; i < _query.orderBy.length; i++) ...<Widget>[
                    _orderByRow(_query.orderBy[i]),
                    if (i < _query.orderBy.length - 1)
                      const SizedBox(height: 8),
                  ],
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
                  labelKey: 'sqlbuilder_limit_offset',
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _numberField(
                        labelKey: 'sqlbuilder_limit',
                        value: _query.limit ?? 0,
                        onChanged: (int v) => setState(
                              () => _query.limit = v == 0 ? null : v,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _numberField(
                        labelKey: 'sqlbuilder_offset',
                        value: _query.offset ?? 0,
                        onChanged: (int v) => setState(
                              () => _query.offset = v == 0 ? null : v,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _outputCard(),
        ],
      ),
    );
  }

  Widget _selectColumnRow(SelectColumn col) {
    return Row(
      children: <Widget>[
        GestureDetector(
          onTap: () => setState(() => col.enabled = !col.enabled),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: col.enabled
                  ? _accentB.withOpacity(0.25)
                  : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: col.enabled
                    ? _accentB
                    : Colors.white.withOpacity(0.2),
              ),
            ),
            child: col.enabled
                ? const Icon(Icons.check, size: 14, color: _accentB)
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: _glassTextField(
            controller: TextEditingController(text: col.column),
            hint: 'column',
            dense: true,
            monospace: true,
            onChanged: (String v) => col.column = v.trim(),
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          'AS',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: _glassTextField(
            controller: TextEditingController(text: col.alias),
            hint: 'alias',
            dense: true,
            monospace: true,
            onChanged: (String v) => col.alias = v.trim(),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: () => _removeQueryColumn(col.id),
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
    );
  }

  Widget _whereRow(WhereCondition w, int index) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (index > 0) ...<Widget>[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: LogicalOperator.values.map((LogicalOperator op) {
                final bool selected = w.connector == op;
                return GestureDetector(
                  onTap: () => setState(() => w.connector = op),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? _accentA.withOpacity(0.3)
                          : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: selected
                            ? _accentA
                            : Colors.white.withOpacity(0.15),
                      ),
                    ),
                    child: Text(
                      op.upper,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: <Widget>[
              GestureDetector(
                onTap: () => setState(() => w.enabled = !w.enabled),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: w.enabled
                        ? _accentB.withOpacity(0.25)
                        : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: w.enabled
                          ? _accentB
                          : Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: w.enabled
                      ? const Icon(Icons.check, size: 14, color: _accentB)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: _glassTextField(
                  controller: TextEditingController(text: w.column),
                  hint: 'column',
                  dense: true,
                  monospace: true,
                  onChanged: (String v) => w.column = v.trim(),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => _removeWhereCondition(w.id),
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
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: SqlOperator.values.map((SqlOperator op) {
              final bool selected = w.operator == op;
              return GestureDetector(
                onTap: () => setState(() => w.operator = op),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
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
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : Colors.white.withOpacity(0.15),
                    ),
                  ),
                  child: Text(
                    op.symbol,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (w.operator.hasValue) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: _glassTextField(
                    controller: TextEditingController(text: w.value),
                    hint: w.operator.isList
                        ? context.t('sqlbuilder_values_list_hint')
                        : context.t('sqlbuilder_value_hint'),
                    dense: true,
                    monospace: true,
                    onChanged: (String v) => w.value = v,
                  ),
                ),
                if (w.operator.needsTwoValues) ...<Widget>[
                  const SizedBox(width: 6),
                  Expanded(
                    child: _glassTextField(
                      controller: TextEditingController(text: w.value2),
                      hint: context.t('sqlbuilder_value_hint'),
                      dense: true,
                      monospace: true,
                      onChanged: (String v) => w.value2 = v,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _orderByRow(OrderByClause o) {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 3,
          child: _glassTextField(
            controller: TextEditingController(text: o.column),
            hint: 'column',
            dense: true,
            monospace: true,
            onChanged: (String v) => o.column = v.trim(),
          ),
        ),
        const SizedBox(width: 6),
        Wrap(
          spacing: 4,
          children: SortDirection.values.map((SortDirection d) {
            final bool selected = o.direction == d;
            return GestureDetector(
              onTap: () => setState(() => o.direction = d),
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
                  color: selected
                      ? null
                      : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: selected
                        ? Colors.transparent
                        : Colors.white.withOpacity(0.15),
                  ),
                ),
                child: Text(
                  d.upper,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: () => _removeOrderBy(o.id),
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
    );
  }

  // ---------------- SHARED WIDGETS ----------------

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

  Widget _toggleChip({
    required String labelKey,
    required bool value,
    required VoidCallback onToggle,
  }) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: value
              ? _accentB.withOpacity(0.15)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value
                ? _accentB.withOpacity(0.5)
                : Colors.white.withOpacity(0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              value
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 14,
              color: value ? _accentB : Colors.white54,
            ),
            const SizedBox(width: 6),
            Text(
              context.t(labelKey),
              style: TextStyle(
                color: value ? _accentB : Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _accentB.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _accentB.withOpacity(0.4)),
          ),
          child: Icon(icon, size: 16, color: _accentB),
        ),
      ),
    );
  }

  Widget _glassTextField({
    required TextEditingController controller,
    required String hint,
    bool dense = false,
    bool monospace = false,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(
        color: Colors.white,
        fontSize: dense ? 12 : 13,
        fontFamily: monospace ? 'monospace' : null,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: dense ? 11 : 12,
          fontFamily: monospace ? 'monospace' : null,
        ),
        isDense: true,
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: dense ? 8 : 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _accentB, width: 1.2),
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