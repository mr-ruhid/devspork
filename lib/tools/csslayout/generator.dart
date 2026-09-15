import 'models.dart';

class CssLayoutGenerator {
  CssLayoutGenerator._();

  // ==========================================================================
  // FLEX
  // ==========================================================================

  static String flexCss(FlexConfig cfg, LayoutOptions opts) {
    final String nl = opts.minify ? '' : '\n';
    final String ind = opts.minify ? '' : '  ';
    final String sp = opts.minify ? '' : ' ';

    final StringBuffer b = StringBuffer();
    b.write('.${opts.containerClass}${sp}{$nl');
    b.write('$ind${_prop('display', 'flex', opts)}');
    b.write('$ind${_prop('flex-direction', cfg.direction.css, opts)}');
    b.write('$ind${_prop('flex-wrap', cfg.wrap.css, opts)}');
    b.write('$ind${_prop('justify-content', cfg.justify.css, opts)}');
    b.write('$ind${_prop('align-items', cfg.alignItems.css, opts)}');

    if (cfg.wrap != FlexWrap.nowrap) {
      b.write('$ind${_prop('align-content', cfg.alignContent.css, opts)}');
    }

    final String gap = _gapCss(cfg.gapRow, cfg.gapColumn, opts);
    if (gap.isNotEmpty) b.write('$ind$gap');

    b.write('}');

    if (cfg.hasCustomItems) {
      b.write(nl);
      b.write(nl);

      for (int i = 0; i < cfg.itemCount; i++) {
        final FlexItemOverride? o = cfg.items[i];
        if (o == null || !o.hasAnyNonDefault) continue;
        b.write('.${opts.itemClass}:nth-child(${i + 1})${sp}{$nl');
        b.write(_flexItemBody(o, opts, ind));
        b.write('}');
        if (i < cfg.itemCount - 1) {
          b.write(nl);
          b.write(nl);
        }
      }
    }

    return _trim(b.toString());
  }

  static String _flexItemBody(
      FlexItemOverride o,
      LayoutOptions opts,
      String ind,
      ) {
    final bool shorthand = opts.useShorthand;

    if (shorthand &&
        o.grow != 0 &&
        o.shrink == 1 &&
        o.basis != 'auto' &&
        o.alignSelf == AlignSelf.auto &&
        o.order == 0) {
      return '$ind${_prop('flex', '${o.grow} ${o.basis}', opts)}';
    }

    final StringBuffer b = StringBuffer();
    if (shorthand && o.grow != 0 && o.shrink != 1) {
      b.write('$ind${_prop('flex', '${o.grow} ${o.shrink} ${o.basis}', opts)}');
    } else {
      if (o.grow != 0) b.write('$ind${_prop('flex-grow', '${o.grow}', opts)}');
      if (o.shrink != 1) {
        b.write('$ind${_prop('flex-shrink', '${o.shrink}', opts)}');
      }
      if (o.basis != 'auto') {
        b.write('$ind${_prop('flex-basis', o.basis, opts)}');
      }
    }
    if (o.alignSelf != AlignSelf.auto) {
      b.write('$ind${_prop('align-self', o.alignSelf.css, opts)}');
    }
    if (o.order != 0) {
      b.write('$ind${_prop('order', '${o.order}', opts)}');
    }
    return b.toString();
  }

  // ==========================================================================
  // GRID
  // ==========================================================================

  static String gridCss(GridConfig cfg, LayoutOptions opts) {
    final String nl = opts.minify ? '' : '\n';
    final String ind = opts.minify ? '' : '  ';
    final String sp = opts.minify ? '' : ' ';

    final StringBuffer b = StringBuffer();
    b.write('.${opts.containerClass}${sp}{$nl');
    b.write('$ind${_prop('display', 'grid', opts)}');

    if (cfg.useAreas) {
      b.write('$ind${_prop(
        'grid-template-columns',
        _areasColumns(cfg),
        opts,
      )}');
      b.write('$ind${_prop(
        'grid-template-rows',
        _areasRows(cfg),
        opts,
      )}');
      final String areas = _areasBlock(cfg, opts);
      b.write('$ind$areas');
    } else {
      b.write('$ind${_prop(
        'grid-template-columns',
        _tracks(cfg.columns),
        opts,
      )}');
      b.write('$ind${_prop(
        'grid-template-rows',
        _tracks(cfg.rows),
        opts,
      )}');
    }

    b.write('$ind${_prop('justify-items', cfg.justifyItems.css, opts)}');
    b.write('$ind${_prop('align-items', cfg.alignItems.css, opts)}');
    b.write('$ind${_prop('justify-content', cfg.justifyContent.css, opts)}');

    if (cfg.useAreas || cfg.autoFlow != GridAutoFlow.row) {
      b.write('$ind${_prop('grid-auto-flow', cfg.autoFlow.css, opts)}');
    }

    if (cfg.useAreas) {
      final String areaNames = _areaNamesCss(cfg, opts);
      if (areaNames.isNotEmpty) b.write('$ind$areaNames');
    }

    final String gap = _gapCss(cfg.gapRow, cfg.gapColumn, opts);
    if (gap.isNotEmpty) b.write('$ind$gap');

    b.write('}');

    return _trim(b.toString());
  }

  static String _tracks(List<GridTrack> tracks) {
    return tracks.map((GridTrack t) => t.value.trim()).join(' ');
  }

  static String _areasColumns(GridConfig cfg) {
    final int cols = cfg.colCount;
    if (cols == cfg.columns.length) return _tracks(cfg.columns);
    return List<String>.generate(cols, (_) => '1fr').join(' ');
  }

  static String _areasRows(GridConfig cfg) {
    final int rows = cfg.rowCount;
    if (rows == cfg.rows.length) return _tracks(cfg.rows);
    return List<String>.generate(rows, (_) => 'auto').join(' ');
  }

  static String _areasBlock(GridConfig cfg, LayoutOptions opts) {
    final String nl = opts.minify ? '' : '\n';
    final String ind = opts.minify ? '' : '    ';
    final String sp = opts.minify ? '' : ' ';

    final List<String> lines = <String>[];
    for (final List<GridAreaCell> row in cfg.areas) {
      final List<String> cells = row.map((GridAreaCell c) {
        final String n = c.name.trim();
        return n.isEmpty ? '.' : n;
      }).toList();
      lines.add('"${cells.join(' ')}"');
    }

    final String joined = lines.join(opts.minify ? '' : '$nl$ind');
    return 'grid-template-areas:${sp}$joined;';
  }

  static String _areaNamesCss(GridConfig cfg, LayoutOptions opts) {
    final String nl = opts.minify ? '' : '\n';
    final String ind = opts.minify ? '' : '  ';
    final String sp = opts.minify ? '' : ' ';

    final Set<String> names = cfg.areaNames;
    if (names.isEmpty) return '';

    final StringBuffer b = StringBuffer();
    int i = 0;
    for (final String name in names) {
      b.write('$ind.grid-area-$name${sp}{$nl');
      b.write('$ind${ind}grid-area: $name;');
      if (opts.minify) {
        b.write('}');
      } else {
        b.write('$nl$ind}');
      }
      if (i < names.length - 1) b.write(nl);
      i++;
    }
    b.write(nl);
    return b.toString();
  }

  // ==========================================================================
  // HTML PREVIEW
  // ==========================================================================

  static String flexHtml(FlexConfig cfg, LayoutOptions opts) {
    final StringBuffer b = StringBuffer();
    b.write('<div class="${opts.containerClass}">');
    for (int i = 0; i < cfg.itemCount; i++) {
      b.write('\n  <div class="${opts.itemClass}">${i + 1}</div>');
    }
    b.write('\n</div>');
    return b.toString();
  }

  static String gridHtml(GridConfig cfg, LayoutOptions opts) {
    final StringBuffer b = StringBuffer();
    b.write('<div class="${opts.containerClass}">');

    if (cfg.useAreas) {
      final Set<String> names = cfg.areaNames;
      for (final String name in names) {
        b.write('\n  <div class="area-$name">$name</div>');
      }
    } else {
      for (int i = 0; i < cfg.itemCount; i++) {
        b.write('\n  <div class="${opts.itemClass}">${i + 1}</div>');
      }
    }

    b.write('\n</div>');
    return b.toString();
  }

  // ==========================================================================
  // FULL SNIPPET
  // ==========================================================================

  static String fullSnippet({
    required LayoutTab tab,
    required FlexConfig flex,
    required GridConfig grid,
    required LayoutOptions opts,
  }) {
    final String nl = opts.minify ? '' : '\n';
    final StringBuffer b = StringBuffer();

    final String css =
    tab == LayoutTab.flex ? flexCss(flex, opts) : gridCss(grid, opts);
    final String html =
    tab == LayoutTab.flex ? flexHtml(flex, opts) : gridHtml(grid, opts);

    if (opts.includeHtml) {
      b.write('<style>$nl');
      b.write(css);
      b.write('$nl</style>$nl$nl');
      b.write(html);
    } else {
      b.write(css);
    }

    return b.toString();
  }

  // ==========================================================================
  // HELPERS
  // ==========================================================================

  static String _prop(String name, String value, LayoutOptions opts) {
    if (opts.minify) return '$name:$value;';
    return '$name: $value;\n';
  }

  static String _gapCss(int row, int col, LayoutOptions opts) {
    if (row == 0 && col == 0) return '';
    if (row == col) return _prop('gap', '${row}px', opts);
    return _prop('gap', '${row}px ${col}px', opts);
  }

  static String _trim(String s) {
    String out = s;
    while (out.endsWith('\n') || out.endsWith(' ')) {
      out = out.substring(0, out.length - 1);
    }
    return out;
  }
}