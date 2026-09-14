
enum SqlDialect { postgres, mysql, sqlite }

extension SqlDialectX on SqlDialect {
  String get displayName {
    switch (this) {
      case SqlDialect.postgres:
        return 'PostgreSQL';
      case SqlDialect.mysql:
        return 'MySQL';
      case SqlDialect.sqlite:
        return 'SQLite';
    }
  }

  String get quoteChar {
    switch (this) {
      case SqlDialect.postgres:
      case SqlDialect.sqlite:
        return '"';
      case SqlDialect.mysql:
        return '`';
    }
  }
}

enum SqlColumnType {
  integer,
  bigint,
  varchar,
  text,
  boolean,
  date,
  timestamp,
  decimal,
  uuid,
  json,
}

extension SqlColumnTypeX on SqlColumnType {
  String get displayName {
    switch (this) {
      case SqlColumnType.integer:
        return 'INTEGER';
      case SqlColumnType.bigint:
        return 'BIGINT';
      case SqlColumnType.varchar:
        return 'VARCHAR';
      case SqlColumnType.text:
        return 'TEXT';
      case SqlColumnType.boolean:
        return 'BOOLEAN';
      case SqlColumnType.date:
        return 'DATE';
      case SqlColumnType.timestamp:
        return 'TIMESTAMP';
      case SqlColumnType.decimal:
        return 'DECIMAL';
      case SqlColumnType.uuid:
        return 'UUID';
      case SqlColumnType.json:
        return 'JSON';
    }
  }

  bool get needsLength =>
      this == SqlColumnType.varchar || this == SqlColumnType.decimal;

  String toSql(SqlDialect dialect, {int? length, int? precision, int? scale}) {
    switch (dialect) {
      case SqlDialect.postgres:
        switch (this) {
          case SqlColumnType.integer:
            return 'INTEGER';
          case SqlColumnType.bigint:
            return 'BIGINT';
          case SqlColumnType.varchar:
            return 'VARCHAR(${length ?? 255})';
          case SqlColumnType.text:
            return 'TEXT';
          case SqlColumnType.boolean:
            return 'BOOLEAN';
          case SqlColumnType.date:
            return 'DATE';
          case SqlColumnType.timestamp:
            return 'TIMESTAMP';
          case SqlColumnType.decimal:
            return 'NUMERIC(${precision ?? 10}, ${scale ?? 2})';
          case SqlColumnType.uuid:
            return 'UUID';
          case SqlColumnType.json:
            return 'JSONB';
        }
      case SqlDialect.mysql:
        switch (this) {
          case SqlColumnType.integer:
            return 'INT';
          case SqlColumnType.bigint:
            return 'BIGINT';
          case SqlColumnType.varchar:
            return 'VARCHAR(${length ?? 255})';
          case SqlColumnType.text:
            return 'TEXT';
          case SqlColumnType.boolean:
            return 'TINYINT(1)';
          case SqlColumnType.date:
            return 'DATE';
          case SqlColumnType.timestamp:
            return 'DATETIME';
          case SqlColumnType.decimal:
            return 'DECIMAL(${precision ?? 10}, ${scale ?? 2})';
          case SqlColumnType.uuid:
            return 'CHAR(36)';
          case SqlColumnType.json:
            return 'JSON';
        }
      case SqlDialect.sqlite:
        switch (this) {
          case SqlColumnType.integer:
            return 'INTEGER';
          case SqlColumnType.bigint:
            return 'INTEGER';
          case SqlColumnType.varchar:
            return 'TEXT';
          case SqlColumnType.text:
            return 'TEXT';
          case SqlColumnType.boolean:
            return 'INTEGER';
          case SqlColumnType.date:
            return 'TEXT';
          case SqlColumnType.timestamp:
            return 'TEXT';
          case SqlColumnType.decimal:
            return 'REAL';
          case SqlColumnType.uuid:
            return 'TEXT';
          case SqlColumnType.json:
            return 'TEXT';
        }
    }
  }
}

class DdlColumn {
  final String id;
  String name;
  SqlColumnType type;
  int length;
  int precision;
  int scale;
  bool primaryKey;
  bool notNull;
  bool unique;
  bool autoIncrement;
  String? defaultValue;
  String? comment;

  DdlColumn({
    required this.id,
    required this.name,
    this.type = SqlColumnType.varchar,
    this.length = 255,
    this.precision = 10,
    this.scale = 2,
    this.primaryKey = false,
    this.notNull = false,
    this.unique = false,
    this.autoIncrement = false,
    this.defaultValue,
    this.comment,
  });

  DdlColumn copy() => DdlColumn(
    id: id,
    name: name,
    type: type,
    length: length,
    precision: precision,
    scale: scale,
    primaryKey: primaryKey,
    notNull: notNull,
    unique: unique,
    autoIncrement: autoIncrement,
    defaultValue: defaultValue,
    comment: comment,
  );
}

class DdlIndex {
  final String id;
  String name;
  List<String> columnIds;
  bool unique;

  DdlIndex({
    required this.id,
    required this.name,
    List<String>? columnIds,
    this.unique = false,
  }) : columnIds = columnIds ?? <String>[];

  DdlIndex copy() => DdlIndex(
    id: id,
    name: name,
    columnIds: List<String>.from(columnIds),
    unique: unique,
  );
}

class DdlTable {
  String name;
  bool ifNotExists;
  List<DdlColumn> columns;
  List<DdlIndex> indexes;

  DdlTable({
    this.name = 'users',
    this.ifNotExists = true,
    List<DdlColumn>? columns,
    List<DdlIndex>? indexes,
  })  : columns = columns ?? <DdlColumn>[],
        indexes = indexes ?? <DdlIndex>[];

  DdlTable copy() => DdlTable(
    name: name,
    ifNotExists: ifNotExists,
    columns: columns.map((DdlColumn c) => c.copy()).toList(),
    indexes: indexes.map((DdlIndex i) => i.copy()).toList(),
  );
}

enum SqlOperator {
  eq,
  neq,
  gt,
  gte,
  lt,
  lte,
  like,
  ilike,
  inList,
  notInList,
  isNull,
  isNotNull,
  between,
}

extension SqlOperatorX on SqlOperator {
  String get symbol {
    switch (this) {
      case SqlOperator.eq:
        return '=';
      case SqlOperator.neq:
        return '!=';
      case SqlOperator.gt:
        return '>';
      case SqlOperator.gte:
        return '>=';
      case SqlOperator.lt:
        return '<';
      case SqlOperator.lte:
        return '<=';
      case SqlOperator.like:
        return 'LIKE';
      case SqlOperator.ilike:
        return 'ILIKE';
      case SqlOperator.inList:
        return 'IN';
      case SqlOperator.notInList:
        return 'NOT IN';
      case SqlOperator.isNull:
        return 'IS NULL';
      case SqlOperator.isNotNull:
        return 'IS NOT NULL';
      case SqlOperator.between:
        return 'BETWEEN';
    }
  }

  bool get hasValue {
    switch (this) {
      case SqlOperator.isNull:
      case SqlOperator.isNotNull:
        return false;
      default:
        return true;
    }
  }

  bool get needsTwoValues => this == SqlOperator.between;

  bool get isList => this == SqlOperator.inList || this == SqlOperator.notInList;

  String get displayName => symbol;
}

enum LogicalOperator { and, or }

extension LogicalOperatorX on LogicalOperator {
  String get upper {
    switch (this) {
      case LogicalOperator.and:
        return 'AND';
      case LogicalOperator.or:
        return 'OR';
    }
  }
}

enum SortDirection { asc, desc }

extension SortDirectionX on SortDirection {
  String get upper {
    switch (this) {
      case SortDirection.asc:
        return 'ASC';
      case SortDirection.desc:
        return 'DESC';
    }
  }
}

class WhereCondition {
  final String id;
  String column;
  SqlOperator operator;
  String value;
  String value2;
  LogicalOperator connector;
  bool enabled;

  WhereCondition({
    required this.id,
    this.column = '',
    this.operator = SqlOperator.eq,
    this.value = '',
    this.value2 = '',
    this.connector = LogicalOperator.and,
    this.enabled = true,
  });

  WhereCondition copy() => WhereCondition(
    id: id,
    column: column,
    operator: operator,
    value: value,
    value2: value2,
    connector: connector,
    enabled: enabled,
  );
}

class OrderByClause {
  final String id;
  String column;
  SortDirection direction;

  OrderByClause({
    required this.id,
    this.column = '',
    this.direction = SortDirection.asc,
  });

  OrderByClause copy() => OrderByClause(
    id: id,
    column: column,
    direction: direction,
  );
}

class SelectColumn {
  final String id;
  String column;
  String alias;
  bool enabled;

  SelectColumn({
    required this.id,
    this.column = '',
    this.alias = '',
    this.enabled = true,
  });

  SelectColumn copy() => SelectColumn(
    id: id,
    column: column,
    alias: alias,
    enabled: enabled,
  );
}

class QueryConfig {
  String table;
  bool distinct;
  List<SelectColumn> columns;
  List<WhereCondition> where;
  List<String> groupBy;
  List<OrderByClause> orderBy;
  int? limit;
  int? offset;

  QueryConfig({
    this.table = 'users',
    this.distinct = false,
    List<SelectColumn>? columns,
    List<WhereCondition>? where,
    List<String>? groupBy,
    List<OrderByClause>? orderBy,
    this.limit,
    this.offset,
  })  : columns = columns ?? <SelectColumn>[],
        where = where ?? <WhereCondition>[],
        groupBy = groupBy ?? <String>[],
        orderBy = orderBy ?? <OrderByClause>[];

  QueryConfig copy() => QueryConfig(
    table: table,
    distinct: distinct,
    columns: columns.map((SelectColumn c) => c.copy()).toList(),
    where: where.map((WhereCondition w) => w.copy()).toList(),
    groupBy: List<String>.from(groupBy),
    orderBy: orderBy.map((OrderByClause o) => o.copy()).toList(),
    limit: limit,
    offset: offset,
  );
}

enum SqlBuilderTab { ddl, query }

class IdGenerator {
  static int _counter = 0;
  static String next(String prefix) {
    _counter++;
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$_counter';
  }
}