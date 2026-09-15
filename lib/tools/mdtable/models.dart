import 'dart:collection';

/// Column alignment options understood by GitHub Flavored Markdown
/// tables. `none` renders as `---` (browser default = left).
enum MdColumnAlign { none, left, center, right }

extension MdColumnAlignX on MdColumnAlign {
  /// The separator cell used in the alignment row of a markdown table.
  /// Uses GFM's minimum of 3 dashes; the generator pads this to the
  /// actual column width when pretty-printing.
  String get marker {
    switch (this) {
      case MdColumnAlign.none:
        return '---';
      case MdColumnAlign.left:
        return ':---';
      case MdColumnAlign.center:
        return ':---:';
      case MdColumnAlign.right:
        return '---:';
    }
  }

  /// Localization key for the label shown in the alignment picker.
  String get labelKey {
    switch (this) {
      case MdColumnAlign.none:
        return 'mdtable_align_none';
      case MdColumnAlign.left:
        return 'mdtable_align_left';
      case MdColumnAlign.center:
        return 'mdtable_align_center';
      case MdColumnAlign.right:
        return 'mdtable_align_right';
    }
  }

  /// A short unicode glyph for compact UI chips.
  String get glyph {
    switch (this) {
      case MdColumnAlign.none:
        return '—';
      case MdColumnAlign.left:
        return '⯇';
      case MdColumnAlign.center:
        return '↔';
      case MdColumnAlign.right:
        return '⯈';
    }
  }

  /// Parses a markdown separator cell (e.g. `:---:`) into an alignment.
  /// Tolerates missing dashes as long as a colon is present.
  static MdColumnAlign fromMarker(String marker) {
    final String t = marker.trim();
    final bool hasLeft = t.startsWith(':');
    final bool hasRight = t.endsWith(':');
    if (hasLeft && hasRight) return MdColumnAlign.center;
    if (hasLeft) return MdColumnAlign.left;
    if (hasRight) return MdColumnAlign.right;
    return MdColumnAlign.none;
  }
}

/// Which input syntax the "Import" tab should attempt to parse.
enum ImportFormat { markdown, csv, tsv, json }

extension ImportFormatX on ImportFormat {
  String get labelKey {
    switch (this) {
      case ImportFormat.markdown:
        return 'mdtable_import_md';
      case ImportFormat.csv:
        return 'mdtable_import_csv';
      case ImportFormat.tsv:
        return 'mdtable_import_tsv';
      case ImportFormat.json:
        return 'mdtable_import_json';
    }
  }

  /// Placeholder shown inside the empty input field so the user knows
  /// what syntax is expected.
  String get placeholder {
    switch (this) {
      case ImportFormat.markdown:
        return '| Name  | Age |\n| :---- | --: |\n| Alice | 30  |';
      case ImportFormat.csv:
        return 'Name,Age\nAlice,30\nBob,25';
      case ImportFormat.tsv:
        return 'Name\tAge\nAlice\t30\nBob\t25';
      case ImportFormat.json:
        return '[\n  {"name": "Alice", "age": 30},\n  {"name": "Bob", "age": 25}\n]';
    }
  }
}

/// The in-memory representation of a table. Mutable on purpose: the UI
/// mutates it inside `setState`, then asks the generator to render the
/// current state. Every mutation keeps [headers], [aligns] and each row
/// in sync so [normalize] rarely needs to trim anything.
class MdTable {
  MdTable({
    List<String>? headers,
    List<List<String>>? rows,
    List<MdColumnAlign>? aligns,
  })  : headers = List<String>.of(headers ?? const <String>[]),
        rows = (rows ?? const <List<String>>[])
            .map((List<String> r) => List<String>.of(r))
            .toList(growable: true),
        aligns = List<MdColumnAlign>.of(aligns ?? const <MdColumnAlign>[]);

  /// Creates a starter grid. Used by the "New table" button.
  factory MdTable.empty({int columns = 3, int rows = 3}) {
    final int cols = columns.clamp(1, 50);
    final int rws = rows.clamp(0, 500);
    return MdTable(
      headers: List<String>.generate(cols, (int i) => 'Column ${i + 1}'),
      rows: List<List<String>>.generate(
        rws,
            (_) => List<String>.filled(cols, ''),
      ),
      aligns: List<MdColumnAlign>.filled(cols, MdColumnAlign.none),
    );
  }

  /// Creates a table from a list of headers with zero data rows.
  factory MdTable.fromHeaders(List<String> headers) {
    return MdTable(
      headers: headers,
      rows: const <List<String>>[],
      aligns: List<MdColumnAlign>.filled(
        headers.length,
        MdColumnAlign.none,
      ),
    );
  }

  final List<String> headers;
  final List<List<String>> rows;
  final List<MdColumnAlign> aligns;

  int get columnCount => headers.length;
  int get rowCount => rows.length;
  bool get isEmpty => headers.isEmpty && rows.isEmpty;
  bool get isNotEmpty => !isEmpty;

  /// Pads every row to [columnCount] cells and pads [aligns] to the same
  /// length. Called after bulk operations (import, paste, JSON) so the
  /// rest of the code can assume rectangular data.
  void normalize() {
    while (aligns.length < headers.length) {
      aligns.add(MdColumnAlign.none);
    }
    while (aligns.length > headers.length) {
      aligns.removeLast();
    }
    for (final List<String> row in rows) {
      while (row.length < headers.length) {
        row.add('');
      }
      while (row.length > headers.length) {
        row.removeLast();
      }
    }
  }

  // -----------------------------------------------------------------
  // Row operations
  // -----------------------------------------------------------------

  void addRow({int? index}) {
    final List<String> row = List<String>.filled(columnCount, '');
    final int at = (index ?? rows.length).clamp(0, rows.length);
    rows.insert(at, row);
  }

  void removeRow(int index) {
    if (index < 0 || index >= rows.length) return;
    rows.removeAt(index);
  }

  void moveRow(int from, int to) {
    if (from < 0 || from >= rows.length) return;
    if (to < 0 || to >= rows.length) return;
    if (from == to) return;
    final List<String> row = rows.removeAt(from);
    rows.insert(to, row);
  }

  void duplicateRow(int index) {
    if (index < 0 || index >= rows.length) return;
    rows.insert(index + 1, List<String>.of(rows[index]));
  }

  // -----------------------------------------------------------------
  // Column operations
  // -----------------------------------------------------------------

  void addColumn({
    int? index,
    String header = '',
    MdColumnAlign align = MdColumnAlign.none,
  }) {
    final int at = (index ?? headers.length).clamp(0, headers.length);
    headers.insert(at, header);
    aligns.insert(at.clamp(0, aligns.length), align);
    for (final List<String> row in rows) {
      row.insert(at.clamp(0, row.length), '');
    }
  }

  void removeColumn(int index) {
    if (index < 0 || index >= headers.length) return;
    headers.removeAt(index);
    if (index < aligns.length) aligns.removeAt(index);
    for (final List<String> row in rows) {
      if (index < row.length) row.removeAt(index);
    }
  }

  void moveColumn(int from, int to) {
    if (from < 0 || from >= headers.length) return;
    if (to < 0 || to >= headers.length) return;
    if (from == to) return;

    final String h = headers.removeAt(from);
    headers.insert(to, h);

    if (from < aligns.length) {
      final MdColumnAlign a = aligns.removeAt(from);
      aligns.insert(to.clamp(0, aligns.length), a);
    }

    for (final List<String> row in rows) {
      if (from < row.length) {
        final String c = row.removeAt(from);
        row.insert(to.clamp(0, row.length), c);
      }
    }
  }

  void duplicateColumn(int index) {
    if (index < 0 || index >= headers.length) return;
    addColumn(
      index: index + 1,
      header: headers[index],
      align: index < aligns.length ? aligns[index] : MdColumnAlign.none,
    );
    for (int r = 0; r < rows.length; r++) {
      rows[r][index + 1] = rows[r][index];
    }
  }

  // -----------------------------------------------------------------
  // Cell / header / align setters
  // -----------------------------------------------------------------

  void setHeader(int index, String value) {
    if (index < 0 || index >= headers.length) return;
    headers[index] = value;
  }

  void setAlign(int index, MdColumnAlign align) {
    if (index < 0) return;
    while (aligns.length <= index) {
      aligns.add(MdColumnAlign.none);
    }
    aligns[index] = align;
  }

  void setCell(int rowIndex, int colIndex, String value) {
    if (rowIndex < 0 || rowIndex >= rows.length) return;
    if (colIndex < 0) return;
    final List<String> row = rows[rowIndex];
    while (row.length <= colIndex) {
      row.add('');
    }
    row[colIndex] = value;
  }

  // -----------------------------------------------------------------
  // Bulk replace (used by the import tab)
  // -----------------------------------------------------------------

  /// Replaces the entire contents with [other]'s data.
  void replaceWith(MdTable other) {
    headers
      ..clear()
      ..addAll(other.headers);
    rows
      ..clear()
      ..addAll(other.rows.map(List<String>.of));
    aligns
      ..clear()
      ..addAll(other.aligns);
    normalize();
  }

  void clear() {
    headers.clear();
    rows.clear();
    aligns.clear();
  }

  MdTable clone() => MdTable(headers: headers, rows: rows, aligns: aligns);

  /// Read-only snapshot for equality-friendly comparisons in tests.
  List<List<String>> get matrix => <List<String>>[
    List<String>.of(headers),
    ...rows.map(List<String>.of),
  ];

  @override
  String toString() => 'MdTable(${columnCount}c × ${rowCount}r)';
}

/// Formatting options applied when rendering markdown output.
class TableOptions {
  const TableOptions({
    this.prettyPrint = true,
    this.escapePipes = true,
    this.outerPipes = true,
    this.trimCells = true,
  });

  /// Pad every cell so the raw markdown is visually aligned in a
  /// monospace editor. When false, cells are output as-is.
  final bool prettyPrint;

  /// Escape `|` characters inside cells as `\|` so the table doesn't
  /// break. Newlines inside cells are converted to `<br>`.
  final bool escapePipes;

  /// Wrap each row with leading/trailing `|`. When false the pipes are
  /// omitted (still valid GFM but less common).
  final bool outerPipes;

  /// Trim leading/trailing whitespace from each cell value.
  final bool trimCells;

  TableOptions copyWith({
    bool? prettyPrint,
    bool? escapePipes,
    bool? outerPipes,
    bool? trimCells,
  }) {
    return TableOptions(
      prettyPrint: prettyPrint ?? this.prettyPrint,
      escapePipes: escapePipes ?? this.escapePipes,
      outerPipes: outerPipes ?? this.outerPipes,
      trimCells: trimCells ?? this.trimCells,
    );
  }
}

/// Options that tweak how the Import tab parses the pasted text.
class ImportOptions {
  const ImportOptions({
    this.csvDelimiter,
    this.csvHasHeader = true,
    this.flattenJson = true,
  });

  /// Explicit CSV delimiter. When null, the parser auto-detects between
  /// `,`, `;`, `\t` and `|` by counting occurrences in the first line.
  final String? csvDelimiter;

  /// When false the first CSV/TSV row becomes data and headers are
  /// auto-generated as `Column 1`, `Column 2`, …
  final bool csvHasHeader;

  /// When importing JSON arrays of objects, flatten nested objects into
  /// dotted keys (`address.city`). When false, nested objects/arrays are
  /// stringified into the cell.
  final bool flattenJson;

  ImportOptions copyWith({
    String? csvDelimiter,
    bool? csvHasHeader,
    bool? flattenJson,
  }) {
    return ImportOptions(
      csvDelimiter: csvDelimiter ?? this.csvDelimiter,
      csvHasHeader: csvHasHeader ?? this.csvHasHeader,
      flattenJson: flattenJson ?? this.flattenJson,
    );
  }
}

/// Centralized localization keys for errors thrown by the parser so the
/// UI and parser stay in sync.
class MdTableErrors {
  MdTableErrors._();

  static const String emptyInput = 'mdtable_error_empty';
  static const String invalidMarkdown = 'mdtable_error_md_invalid';
  static const String invalidCsv = 'mdtable_error_csv_invalid';
  static const String invalidJson = 'mdtable_error_json_invalid';
  static const String jsonNotArray = 'mdtable_error_json_not_array';
  static const String jsonNoColumns = 'mdtable_error_json_no_columns';
  static const String noColumns = 'mdtable_error_no_columns';
  static const String mismatchedRow = 'mdtable_error_row_mismatch';
}