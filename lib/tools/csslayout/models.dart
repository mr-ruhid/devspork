enum LayoutTab { flex, grid }

// ============================================================================
// FLEX
// ============================================================================

enum FlexDirection { row, rowReverse, column, columnReverse }

extension FlexDirectionX on FlexDirection {
  String get css {
    switch (this) {
      case FlexDirection.row:
        return 'row';
      case FlexDirection.rowReverse:
        return 'row-reverse';
      case FlexDirection.column:
        return 'column';
      case FlexDirection.columnReverse:
        return 'column-reverse';
    }
  }

  String get labelKey {
    switch (this) {
      case FlexDirection.row:
        return 'csslayout_dir_row';
      case FlexDirection.rowReverse:
        return 'csslayout_dir_row_rev';
      case FlexDirection.column:
        return 'csslayout_dir_col';
      case FlexDirection.columnReverse:
        return 'csslayout_dir_col_rev';
    }
  }
}

enum FlexWrap { nowrap, wrap, wrapReverse }

extension FlexWrapX on FlexWrap {
  String get css {
    switch (this) {
      case FlexWrap.nowrap:
        return 'nowrap';
      case FlexWrap.wrap:
        return 'wrap';
      case FlexWrap.wrapReverse:
        return 'wrap-reverse';
    }
  }

  String get labelKey {
    switch (this) {
      case FlexWrap.nowrap:
        return 'csslayout_wrap_nowrap';
      case FlexWrap.wrap:
        return 'csslayout_wrap_wrap';
      case FlexWrap.wrapReverse:
        return 'csslayout_wrap_reverse';
    }
  }
}

enum JustifyContent { flexStart, flexEnd, center, spaceBetween, spaceAround, spaceEvenly }

extension JustifyContentX on JustifyContent {
  String get css {
    switch (this) {
      case JustifyContent.flexStart:
        return 'flex-start';
      case JustifyContent.flexEnd:
        return 'flex-end';
      case JustifyContent.center:
        return 'center';
      case JustifyContent.spaceBetween:
        return 'space-between';
      case JustifyContent.spaceAround:
        return 'space-around';
      case JustifyContent.spaceEvenly:
        return 'space-evenly';
    }
  }

  String get labelKey {
    switch (this) {
      case JustifyContent.flexStart:
        return 'csslayout_just_start';
      case JustifyContent.flexEnd:
        return 'csslayout_just_end';
      case JustifyContent.center:
        return 'csslayout_just_center';
      case JustifyContent.spaceBetween:
        return 'csslayout_just_between';
      case JustifyContent.spaceAround:
        return 'csslayout_just_around';
      case JustifyContent.spaceEvenly:
        return 'csslayout_just_evenly';
    }
  }
}

enum AlignItems { stretch, flexStart, flexEnd, center, baseline }

extension AlignItemsX on AlignItems {
  String get css {
    switch (this) {
      case AlignItems.stretch:
        return 'stretch';
      case AlignItems.flexStart:
        return 'flex-start';
      case AlignItems.flexEnd:
        return 'flex-end';
      case AlignItems.center:
        return 'center';
      case AlignItems.baseline:
        return 'baseline';
    }
  }

  String get labelKey {
    switch (this) {
      case AlignItems.stretch:
        return 'csslayout_align_stretch';
      case AlignItems.flexStart:
        return 'csslayout_align_start';
      case AlignItems.flexEnd:
        return 'csslayout_align_end';
      case AlignItems.center:
        return 'csslayout_align_center';
      case AlignItems.baseline:
        return 'csslayout_align_baseline';
    }
  }
}

enum AlignContent { stretch, flexStart, flexEnd, center, spaceBetween, spaceAround }

extension AlignContentX on AlignContent {
  String get css {
    switch (this) {
      case AlignContent.stretch:
        return 'stretch';
      case AlignContent.flexStart:
        return 'flex-start';
      case AlignContent.flexEnd:
        return 'flex-end';
      case AlignContent.center:
        return 'center';
      case AlignContent.spaceBetween:
        return 'space-between';
      case AlignContent.spaceAround:
        return 'space-around';
    }
  }

  String get labelKey {
    switch (this) {
      case AlignContent.stretch:
        return 'csslayout_acontent_stretch';
      case AlignContent.flexStart:
        return 'csslayout_acontent_start';
      case AlignContent.flexEnd:
        return 'csslayout_acontent_end';
      case AlignContent.center:
        return 'csslayout_acontent_center';
      case AlignContent.spaceBetween:
        return 'csslayout_acontent_between';
      case AlignContent.spaceAround:
        return 'csslayout_acontent_around';
    }
  }
}

enum AlignSelf { auto, flexStart, flexEnd, center, baseline, stretch }

extension AlignSelfX on AlignSelf {
  String get css {
    switch (this) {
      case AlignSelf.auto:
        return 'auto';
      case AlignSelf.flexStart:
        return 'flex-start';
      case AlignSelf.flexEnd:
        return 'flex-end';
      case AlignSelf.center:
        return 'center';
      case AlignSelf.baseline:
        return 'baseline';
      case AlignSelf.stretch:
        return 'stretch';
    }
  }

  String get labelKey {
    switch (this) {
      case AlignSelf.auto:
        return 'csslayout_self_auto';
      case AlignSelf.flexStart:
        return 'csslayout_self_start';
      case AlignSelf.flexEnd:
        return 'csslayout_self_end';
      case AlignSelf.center:
        return 'csslayout_self_center';
      case AlignSelf.baseline:
        return 'csslayout_self_baseline';
      case AlignSelf.stretch:
        return 'csslayout_self_stretch';
    }
  }
}

class FlexItemOverride {
  FlexItemOverride({
    this.grow = 0,
    this.shrink = 1,
    this.basis = 'auto',
    this.alignSelf = AlignSelf.auto,
    this.order = 0,
    this.enabled = false,
  });

  int grow;
  int shrink;
  String basis;
  AlignSelf alignSelf;
  int order;
  bool enabled;

  FlexItemOverride clone() => FlexItemOverride(
    grow: grow,
    shrink: shrink,
    basis: basis,
    alignSelf: alignSelf,
    order: order,
    enabled: enabled,
  );

  bool get hasAnyNonDefault {
    if (!enabled) return false;
    return grow != 0 ||
        shrink != 1 ||
        basis != 'auto' ||
        alignSelf != AlignSelf.auto ||
        order != 0;
  }

  String toCss(int index) {
    final StringBuffer b = StringBuffer();
    if (grow != 0) b.writeln('  flex-grow: $grow;');
    if (shrink != 1) b.writeln('  flex-shrink: $shrink;');
    if (basis != 'auto') b.writeln('  flex-basis: $basis;');
    if (alignSelf != AlignSelf.auto) b.writeln('  align-self: ${alignSelf.css};');
    if (order != 0) b.writeln('  order: $order;');
    return b.toString();
  }
}

class FlexConfig {
  FlexConfig({
    this.direction = FlexDirection.row,
    this.wrap = FlexWrap.nowrap,
    this.justify = JustifyContent.flexStart,
    this.alignItems = AlignItems.stretch,
    this.alignContent = AlignContent.stretch,
    this.gapRow = 8,
    this.gapColumn = 8,
    this.itemCount = 6,
  }) : items = <int, FlexItemOverride>{};

  FlexDirection direction;
  FlexWrap wrap;
  JustifyContent justify;
  AlignItems alignItems;
  AlignContent alignContent;
  int gapRow;
  int gapColumn;
  int itemCount;
  final Map<int, FlexItemOverride> items;

  FlexItemOverride itemAt(int index) {
    return items.putIfAbsent(index, () => FlexItemOverride());
  }

  bool get hasCustomItems =>
      items.values.any((FlexItemOverride o) => o.hasAnyNonDefault);

  void resetAllItems() => items.clear();
}

// ============================================================================
// GRID
// ============================================================================

enum GridAutoFlow { row, column, rowDense, columnDense }

extension GridAutoFlowX on GridAutoFlow {
  String get css {
    switch (this) {
      case GridAutoFlow.row:
        return 'row';
      case GridAutoFlow.column:
        return 'column';
      case GridAutoFlow.rowDense:
        return 'row dense';
      case GridAutoFlow.columnDense:
        return 'column dense';
    }
  }

  String get labelKey {
    switch (this) {
      case GridAutoFlow.row:
        return 'csslayout_flow_row';
      case GridAutoFlow.column:
        return 'csslayout_flow_col';
      case GridAutoFlow.rowDense:
        return 'csslayout_flow_row_dense';
      case GridAutoFlow.columnDense:
        return 'csslayout_flow_col_dense';
    }
  }
}

enum GridJustifyItems { stretch, start, end, center }

extension GridJustifyItemsX on GridJustifyItems {
  String get css {
    switch (this) {
      case GridJustifyItems.stretch:
        return 'stretch';
      case GridJustifyItems.start:
        return 'start';
      case GridJustifyItems.end:
        return 'end';
      case GridJustifyItems.center:
        return 'center';
    }
  }

  String get labelKey {
    switch (this) {
      case GridJustifyItems.stretch:
        return 'csslayout_align_stretch';
      case GridJustifyItems.start:
        return 'csslayout_align_start';
      case GridJustifyItems.end:
        return 'csslayout_align_end';
      case GridJustifyItems.center:
        return 'csslayout_align_center';
    }
  }
}

enum GridAlignItems { stretch, start, end, center }

extension GridAlignItemsX on GridAlignItems {
  String get css {
    switch (this) {
      case GridAlignItems.stretch:
        return 'stretch';
      case GridAlignItems.start:
        return 'start';
      case GridAlignItems.end:
        return 'end';
      case GridAlignItems.center:
        return 'center';
    }
  }

  String get labelKey {
    switch (this) {
      case GridAlignItems.stretch:
        return 'csslayout_align_stretch';
      case GridAlignItems.start:
        return 'csslayout_align_start';
      case GridAlignItems.end:
        return 'csslayout_align_end';
      case GridAlignItems.center:
        return 'csslayout_align_center';
    }
  }
}

class GridTrack {
  GridTrack({required this.value});

  GridTrack.fr(num n) : value = '${_fmt(n)}fr';
  GridTrack.px(num n) : value = '${_fmt(n)}px';
  GridTrack.percent(num n) : value = '${_fmt(n)}%';
  GridTrack.auto() : value = 'auto';
  GridTrack.minContent() : value = 'min-content';
  GridTrack.maxContent() : value = 'max-content';

  String value;

  static String _fmt(num n) {
    if (n == n.roundToDouble()) return n.toInt().toString();
    return n.toString();
  }

  GridTrack clone() => GridTrack(value: value);

  @override
  String toString() => value;
}

class GridAreaCell {
  GridAreaCell({required this.name});

  String name;

  GridAreaCell clone() => GridAreaCell(name: name);
}

class GridConfig {
  GridConfig({
    List<GridTrack>? columns,
    List<GridTrack>? rows,
    List<List<GridAreaCell>>? areas,
    this.useAreas = false,
    this.autoFlow = GridAutoFlow.row,
    this.justifyItems = GridJustifyItems.stretch,
    this.alignItems = GridAlignItems.stretch,
    this.justifyContent = JustifyContent.flexStart,
    this.alignContent = AlignContent.stretch,
    this.gapRow = 8,
    this.gapColumn = 8,
    this.itemCount = 6,
  })  : columns = columns ?? <GridTrack>[
    GridTrack.fr(1),
    GridTrack.fr(1),
    GridTrack.fr(1),
  ],
        rows = rows ?? <GridTrack>[
          GridTrack.auto(),
          GridTrack.auto(),
        ],
        areas = areas ?? <List<GridAreaCell>>[
          <GridAreaCell>[
            GridAreaCell(name: 'a'),
            GridAreaCell(name: 'b'),
            GridAreaCell(name: 'c'),
          ],
          <GridAreaCell>[
            GridAreaCell(name: 'd'),
            GridAreaCell(name: 'e'),
            GridAreaCell(name: 'f'),
          ],
        ];

  List<GridTrack> columns;
  List<GridTrack> rows;
  List<List<GridAreaCell>> areas;
  bool useAreas;
  GridAutoFlow autoFlow;
  GridJustifyItems justifyItems;
  GridAlignItems alignItems;
  JustifyContent justifyContent;
  AlignContent alignContent;
  int gapRow;
  int gapColumn;
  int itemCount;

  int get colCount => useAreas ? areas.first.length : columns.length;
  int get rowCount => useAreas ? areas.length : rows.length;

  void addColumn({GridTrack? track}) {
    columns.add(track ?? GridTrack.fr(1));
    if (areas.isEmpty) return;
    for (final List<GridAreaCell> row in areas) {
      row.add(GridAreaCell(name: _nextAreaName()));
    }
  }

  void removeColumn(int index) {
    if (columns.length <= 1) return;
    if (index < 0 || index >= columns.length) return;
    columns.removeAt(index);
    for (final List<GridAreaCell> row in areas) {
      if (index < row.length) row.removeAt(index);
    }
  }

  void addRow({GridTrack? track}) {
    rows.add(track ?? GridTrack.auto());
    final int cols = columns.length;
    areas.add(List<GridAreaCell>.generate(
      cols,
          (_) => GridAreaCell(name: _nextAreaName()),
    ));
  }

  void removeRow(int index) {
    if (rows.length <= 1) return;
    if (index < 0 || index >= rows.length) return;
    rows.removeAt(index);
    if (index < areas.length) areas.removeAt(index);
  }

  void syncAreaSize() {
    final int cols = columns.length;
    while (areas.length < rows.length) {
      areas.add(List<GridAreaCell>.generate(
        cols,
            (_) => GridAreaCell(name: _nextAreaName()),
      ));
    }
    while (areas.length > rows.length) {
      areas.removeLast();
    }
    for (final List<GridAreaCell> row in areas) {
      while (row.length < cols) {
        row.add(GridAreaCell(name: _nextAreaName()));
      }
      while (row.length > cols) {
        row.removeLast();
      }
    }
  }

  String _nextAreaName() {
    const String alphabet = 'abcdefghijklmnopqrstuvwxyz';
    int counter = areas.length * 3;
    return alphabet[counter % alphabet.length];
  }

  Set<String> get areaNames {
    final Set<String> out = <String>{};
    for (final List<GridAreaCell> row in areas) {
      for (final GridAreaCell cell in row) {
        final String n = cell.name.trim();
        if (n.isNotEmpty && n != '.') out.add(n);
      }
    }
    return out;
  }

  GridConfig clone() => GridConfig(
    columns: columns.map((GridTrack t) => t.clone()).toList(),
    rows: rows.map((GridTrack t) => t.clone()).toList(),
    areas: areas
        .map((List<GridAreaCell> r) =>
        r.map((GridAreaCell c) => c.clone()).toList())
        .toList(),
    useAreas: useAreas,
    autoFlow: autoFlow,
    justifyItems: justifyItems,
    alignItems: alignItems,
    justifyContent: justifyContent,
    alignContent: alignContent,
    gapRow: gapRow,
    gapColumn: gapColumn,
    itemCount: itemCount,
  );
}

// ============================================================================
// OUTPUT OPTIONS
// ============================================================================

class LayoutOptions {
  const LayoutOptions({
    this.includeHtml = true,
    this.includeComments = false,
    this.containerClass = 'container',
    this.itemClass = 'item',
    this.useShorthand = true,
    this.minify = false,
  });

  final bool includeHtml;
  final bool includeComments;
  final String containerClass;
  final String itemClass;
  final bool useShorthand;
  final bool minify;

  LayoutOptions copyWith({
    bool? includeHtml,
    bool? includeComments,
    String? containerClass,
    String? itemClass,
    bool? useShorthand,
    bool? minify,
  }) {
    return LayoutOptions(
      includeHtml: includeHtml ?? this.includeHtml,
      includeComments: includeComments ?? this.includeComments,
      containerClass: containerClass ?? this.containerClass,
      itemClass: itemClass ?? this.itemClass,
      useShorthand: useShorthand ?? this.useShorthand,
      minify: minify ?? this.minify,
    );
  }
}

class LayoutErrors {
  LayoutErrors._();

  static const String noColumns = 'csslayout_error_no_columns';
  static const String noRows = 'csslayout_error_no_rows';
  static const String invalidTrack = 'csslayout_error_invalid_track';
  static const String areaMismatch = 'csslayout_error_area_mismatch';
}