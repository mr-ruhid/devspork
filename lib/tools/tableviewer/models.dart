enum CellType { string, integer, double, boolean, nullValue, object, array }

extension CellTypeX on CellType {
  String get labelKey {
    switch (this) {
      case CellType.string:
        return 'tableviewer_type_string';
      case CellType.integer:
        return 'tableviewer_type_integer';
      case CellType.double:
        return 'tableviewer_type_double';
      case CellType.boolean:
        return 'tableviewer_type_boolean';
      case CellType.nullValue:
        return 'tableviewer_type_null';
      case CellType.object:
        return 'tableviewer_type_object';
      case CellType.array:
        return 'tableviewer_type_array';
    }
  }
}

class TableColumn {
  final String id;
  String name;
  CellType type;
  double width;

  TableColumn({
    required this.id,
    required this.name,
    this.type = CellType.string,
    this.width = 140.0,
  });

  TableColumn copy() => TableColumn(
    id: id,
    name: name,
    type: type,
    width: width,
  );
}

class TableCell {
  dynamic value;
  CellType type;

  TableCell({
    this.value,
    this.type = CellType.string,
  });

  String get displayValue {
    if (value == null) return '';
    if (value is String) return value;
    if (value is bool) return value.toString();
    if (value is num) return value.toString();
    return value.toString();
  }

  TableCell copy() => TableCell(value: value, type: type);

  static TableCell fromDynamic(dynamic v) {
    if (v == null) return TableCell(value: null, type: CellType.nullValue);
    if (v is String) {
      final int? i = int.tryParse(v);
      if (i != null && v == i.toString()) {
        return TableCell(value: i, type: CellType.integer);
      }
      final double? d = double.tryParse(v);
      if (d != null &&
          v.contains('.') &&
          RegExp(r'^-?\d+(\.\d+)?$').hasMatch(v)) {
        return TableCell(value: d, type: CellType.double);
      }
      if (v.toLowerCase() == 'true') {
        return TableCell(value: true, type: CellType.boolean);
      }
      if (v.toLowerCase() == 'false') {
        return TableCell(value: false, type: CellType.boolean);
      }
      return TableCell(value: v, type: CellType.string);
    }
    if (v is int) return TableCell(value: v, type: CellType.integer);
    if (v is double) return TableCell(value: v, type: CellType.double);
    if (v is bool) return TableCell(value: v, type: CellType.boolean);
    if (v is Map) return TableCell(value: v, type: CellType.object);
    if (v is List) return TableCell(value: v, type: CellType.array);
    return TableCell(value: v.toString(), type: CellType.string);
  }
}

class TableRow {
  final String id;
  final List<TableCell> cells;

  TableRow({
    required this.id,
    required this.cells,
  });

  TableRow copy() => TableRow(
    id: id,
    cells: cells.map((TableCell c) => c.copy()).toList(),
  );

  void ensureLength(int length) {
    while (cells.length < length) {
      cells.add(TableCell());
    }
    while (cells.length > length) {
      cells.removeLast();
    }
  }
}

class TableData {
  final List<TableColumn> columns;
  final List<TableRow> rows;

  TableData({
    required this.columns,
    required this.rows,
  });

  bool get isEmpty => columns.isEmpty && rows.isEmpty;

  static TableData empty() => TableData(
    columns: <TableColumn>[],
    rows: <TableRow>[],
  );

  TableData copy() => TableData(
    columns: columns.map((TableColumn c) => c.copy()).toList(),
    rows: rows.map((TableRow r) => r.copy()).toList(),
  );
}

enum TableFormat { csv, json, markdown, tsv }

extension TableFormatX on TableFormat {
  String get displayName {
    switch (this) {
      case TableFormat.csv:
        return 'CSV';
      case TableFormat.json:
        return 'JSON';
      case TableFormat.markdown:
        return 'Markdown';
      case TableFormat.tsv:
        return 'TSV';
    }
  }

  String get fileExtension {
    switch (this) {
      case TableFormat.csv:
        return '.csv';
      case TableFormat.json:
        return '.json';
      case TableFormat.markdown:
        return '.md';
      case TableFormat.tsv:
        return '.tsv';
    }
  }
}

class TableParseResult {
  final TableData data;
  final String? errorKey;
  final String? errorDetail;
  final int rowCount;
  final int columnCount;

  const TableParseResult({
    required this.data,
    this.errorKey,
    this.errorDetail,
    this.rowCount = 0,
    this.columnCount = 0,
  });

  bool get hasError => errorKey != null;

  bool get isEmpty => !hasError && data.isEmpty;

  static TableParseResult empty() => TableParseResult(
    data: TableData.empty(),
  );
}

class TableViewOptions {
  bool showRowNumbers;
  bool autoDetectTypes;
  bool flattenNested;
  String flattenSeparator;
  bool includeHeaderInCsv;
  String markdownAlignment;

  TableViewOptions({
    this.showRowNumbers = true,
    this.autoDetectTypes = true,
    this.flattenNested = true,
    this.flattenSeparator = '.',
    this.includeHeaderInCsv = true,
    this.markdownAlignment = 'left',
  });

  TableViewOptions copy() => TableViewOptions(
    showRowNumbers: showRowNumbers,
    autoDetectTypes: autoDetectTypes,
    flattenNested: flattenNested,
    flattenSeparator: flattenSeparator,
    includeHeaderInCsv: includeHeaderInCsv,
    markdownAlignment: markdownAlignment,
  );
}