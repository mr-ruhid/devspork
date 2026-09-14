
import 'package:flutter/material.dart';

enum RegexFlag { caseInsensitive, multiLine, dotAll, unicode }

extension RegexFlagX on RegexFlag {
  String get label {
    switch (this) {
      case RegexFlag.caseInsensitive:
        return 'i';
      case RegexFlag.multiLine:
        return 'm';
      case RegexFlag.dotAll:
        return 's';
      case RegexFlag.unicode:
        return 'u';
    }
  }

  String get labelKey {
    switch (this) {
      case RegexFlag.caseInsensitive:
        return 'regexbuilder_flag_i';
      case RegexFlag.multiLine:
        return 'regexbuilder_flag_m';
      case RegexFlag.dotAll:
        return 'regexbuilder_flag_s';
      case RegexFlag.unicode:
        return 'regexbuilder_flag_u';
    }
  }

  bool get defaultValue => false;
}

class PaletteItem {
  final String label;
  final String snippet;
  final String descriptionKey;
  final int cursorOffset;

  const PaletteItem({
    required this.label,
    required this.snippet,
    required this.descriptionKey,
    this.cursorOffset = -1,
  });
}

class PaletteCategory {
  final String labelKey;
  final IconData icon;
  final List<PaletteItem> items;

  const PaletteCategory({
    required this.labelKey,
    required this.icon,
    required this.items,
  });
}

class MatchGroupInfo {
  final int index;
  final String? value;
  final int? start;
  final int? end;
  final String? name;

  const MatchGroupInfo({
    required this.index,
    this.value,
    this.start,
    this.end,
    this.name,
  });

  bool get matched => value != null;
}

class RegexMatchInfo {
  final int index;
  final int start;
  final int end;
  final String value;
  final List<MatchGroupInfo> groups;
  final Map<String, MatchGroupInfo> namedGroups;

  const RegexMatchInfo({
    required this.index,
    required this.start,
    required this.end,
    required this.value,
    required this.groups,
    required this.namedGroups,
  });

  bool get hasGroups => groups.isNotEmpty || namedGroups.isNotEmpty;

  int get length => end - start;
}

class RegexTestResult {
  final List<RegexMatchInfo> matches;
  final String? errorKey;
  final String? errorDetail;
  final int durationMicros;
  final int totalGroups;

  const RegexTestResult({
    this.matches = const <RegexMatchInfo>[],
    this.errorKey,
    this.errorDetail,
    this.durationMicros = 0,
    this.totalGroups = 0,
  });

  bool get hasError => errorKey != null;

  bool get isEmpty => matches.isEmpty && !hasError;

  static const RegexTestResult empty = RegexTestResult();

  String get prettyDuration {
    if (durationMicros < 1000) return '${durationMicros}µs';
    return '${(durationMicros / 1000).toStringAsFixed(2)}ms';
  }
}

class ExplainLine {
  final String token;
  final String descriptionKey;
  final String? detail;
  final int depth;

  const ExplainLine({
    required this.token,
    required this.descriptionKey,
    this.detail,
    this.depth = 0,
  });
}

const List<PaletteCategory> kRegexPalette = <PaletteCategory>[
  PaletteCategory(
    labelKey: 'regexbuilder_cat_anchors',
    icon: Icons.vertical_align_top_rounded,
    items: <PaletteItem>[
      PaletteItem(
        label: '^',
        snippet: '^',
        descriptionKey: 'regexbuilder_desc_anchor_start',
      ),
      PaletteItem(
        label: r'$',
        snippet: r'$',
        descriptionKey: 'regexbuilder_desc_anchor_end',
      ),
      PaletteItem(
        label: r'\b',
        snippet: r'\b',
        descriptionKey: 'regexbuilder_desc_word_boundary',
      ),
      PaletteItem(
        label: r'\B',
        snippet: r'\B',
        descriptionKey: 'regexbuilder_desc_non_word_boundary',
      ),
      PaletteItem(
        label: r'\A',
        snippet: r'\A',
        descriptionKey: 'regexbuilder_desc_anchor_start_input',
      ),
      PaletteItem(
        label: r'\z',
        snippet: r'\z',
        descriptionKey: 'regexbuilder_desc_anchor_end_input',
      ),
    ],
  ),
  PaletteCategory(
    labelKey: 'regexbuilder_cat_chars',
    icon: Icons.text_fields_rounded,
    items: <PaletteItem>[
      PaletteItem(
        label: r'\d',
        snippet: r'\d',
        descriptionKey: 'regexbuilder_desc_digit',
      ),
      PaletteItem(
        label: r'\D',
        snippet: r'\D',
        descriptionKey: 'regexbuilder_desc_non_digit',
      ),
      PaletteItem(
        label: r'\w',
        snippet: r'\w',
        descriptionKey: 'regexbuilder_desc_word',
      ),
      PaletteItem(
        label: r'\W',
        snippet: r'\W',
        descriptionKey: 'regexbuilder_desc_non_word',
      ),
      PaletteItem(
        label: r'\s',
        snippet: r'\s',
        descriptionKey: 'regexbuilder_desc_space',
      ),
      PaletteItem(
        label: r'\S',
        snippet: r'\S',
        descriptionKey: 'regexbuilder_desc_non_space',
      ),
      PaletteItem(
        label: '.',
        snippet: '.',
        descriptionKey: 'regexbuilder_desc_any',
      ),
      PaletteItem(
        label: '[a-z]',
        snippet: '[a-z]',
        descriptionKey: 'regexbuilder_desc_lower',
      ),
      PaletteItem(
        label: '[A-Z]',
        snippet: '[A-Z]',
        descriptionKey: 'regexbuilder_desc_upper',
      ),
      PaletteItem(
        label: '[0-9]',
        snippet: '[0-9]',
        descriptionKey: 'regexbuilder_desc_digits',
      ),
      PaletteItem(
        label: '[a-zA-Z]',
        snippet: '[a-zA-Z]',
        descriptionKey: 'regexbuilder_desc_letters',
      ),
      PaletteItem(
        label: '[a-zA-Z0-9]',
        snippet: '[a-zA-Z0-9]',
        descriptionKey: 'regexbuilder_desc_alnum',
      ),
      PaletteItem(
        label: '[^…]',
        snippet: '[^]',
        descriptionKey: 'regexbuilder_desc_negated_class',
        cursorOffset: 2,
      ),
      PaletteItem(
        label: '[…]',
        snippet: '[]',
        descriptionKey: 'regexbuilder_desc_char_class',
        cursorOffset: 1,
      ),
      PaletteItem(
        label: r'[\w\s]',
        snippet: r'[\w\s]',
        descriptionKey: 'regexbuilder_desc_word_or_space',
      ),
    ],
  ),
  PaletteCategory(
    labelKey: 'regexbuilder_cat_quantifiers',
    icon: Icons.repeat_rounded,
    items: <PaletteItem>[
      PaletteItem(
        label: '*',
        snippet: '*',
        descriptionKey: 'regexbuilder_desc_star',
      ),
      PaletteItem(
        label: '+',
        snippet: '+',
        descriptionKey: 'regexbuilder_desc_plus',
      ),
      PaletteItem(
        label: '?',
        snippet: '?',
        descriptionKey: 'regexbuilder_desc_question',
      ),
      PaletteItem(
        label: '{n}',
        snippet: '{}',
        descriptionKey: 'regexbuilder_desc_exact',
        cursorOffset: 1,
      ),
      PaletteItem(
        label: '{n,}',
        snippet: '{,}',
        descriptionKey: 'regexbuilder_desc_at_least',
        cursorOffset: 1,
      ),
      PaletteItem(
        label: '{n,m}',
        snippet: '{,}',
        descriptionKey: 'regexbuilder_desc_between',
        cursorOffset: 1,
      ),
      PaletteItem(
        label: '*?',
        snippet: '*?',
        descriptionKey: 'regexbuilder_desc_lazy_star',
      ),
      PaletteItem(
        label: '+?',
        snippet: '+?',
        descriptionKey: 'regexbuilder_desc_lazy_plus',
      ),
      PaletteItem(
        label: '??',
        snippet: '??',
        descriptionKey: 'regexbuilder_desc_lazy_question',
      ),
    ],
  ),
  PaletteCategory(
    labelKey: 'regexbuilder_cat_groups',
    icon: Icons.account_tree_rounded,
    items: <PaletteItem>[
      PaletteItem(
        label: '(…)',
        snippet: '()',
        descriptionKey: 'regexbuilder_desc_capturing_group',
        cursorOffset: 1,
      ),
      PaletteItem(
        label: '(?:…)',
        snippet: '(?:)',
        descriptionKey: 'regexbuilder_desc_non_capturing',
        cursorOffset: 3,
      ),
      PaletteItem(
        label: '(?<name>…)',
        snippet: '(?<>)',
        descriptionKey: 'regexbuilder_desc_named_group',
        cursorOffset: 3,
      ),
      PaletteItem(
        label: '|',
        snippet: '|',
        descriptionKey: 'regexbuilder_desc_alternation',
      ),
      PaletteItem(
        label: '(?=…)',
        snippet: '(?=)',
        descriptionKey: 'regexbuilder_desc_lookahead_pos',
        cursorOffset: 3,
      ),
      PaletteItem(
        label: '(?!…)',
        snippet: '(?!)',
        descriptionKey: 'regexbuilder_desc_lookahead_neg',
        cursorOffset: 3,
      ),
      PaletteItem(
        label: '(?<=…)',
        snippet: '(?<=)',
        descriptionKey: 'regexbuilder_desc_lookbehind_pos',
        cursorOffset: 4,
      ),
      PaletteItem(
        label: '(?<!…)',
        snippet: '(?<!)',
        descriptionKey: 'regexbuilder_desc_lookbehind_neg',
        cursorOffset: 4,
      ),
    ],
  ),
  PaletteCategory(
    labelKey: 'regexbuilder_cat_presets',
    icon: Icons.auto_awesome_rounded,
    items: <PaletteItem>[
      PaletteItem(
        label: 'Email',
        snippet: r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
        descriptionKey: 'regexbuilder_preset_email',
      ),
      PaletteItem(
        label: 'URL',
        snippet: r'https?://[^\s/$.?#].[^\s]*',
        descriptionKey: 'regexbuilder_preset_url',
      ),
      PaletteItem(
        label: 'IPv4',
        snippet:
        r'((25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(25[0-5]|2[0-4]\d|[01]?\d\d?)',
        descriptionKey: 'regexbuilder_preset_ipv4',
      ),
      PaletteItem(
        label: 'UUID',
        snippet:
        r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
        descriptionKey: 'regexbuilder_preset_uuid',
      ),
      PaletteItem(
        label: 'Hex Color',
        snippet: r'#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})\b',
        descriptionKey: 'regexbuilder_preset_hexcolor',
      ),
      PaletteItem(
        label: 'Date YYYY-MM-DD',
        snippet: r'\d{4}-\d{2}-\d{2}',
        descriptionKey: 'regexbuilder_preset_date',
      ),
      PaletteItem(
        label: 'Time HH:MM',
        snippet: r'([01]\d|2[0-3]):[0-5]\d',
        descriptionKey: 'regexbuilder_preset_time',
      ),
      PaletteItem(
        label: 'Phone (+CC)',
        snippet: r'\+?\d[\d\s\-()]{7,}\d',
        descriptionKey: 'regexbuilder_preset_phone',
      ),
      PaletteItem(
        label: 'Numbers',
        snippet: r'-?\d+(\.\d+)?',
        descriptionKey: 'regexbuilder_preset_numbers',
      ),
      PaletteItem(
        label: 'Username',
        snippet: r'^[a-zA-Z0-9_]{3,16}$',
        descriptionKey: 'regexbuilder_preset_username',
      ),
      PaletteItem(
        label: 'Strong Password',
        snippet:
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
        descriptionKey: 'regexbuilder_preset_password',
      ),
      PaletteItem(
        label: 'Hex Bytes',
        snippet: r'\b[0-9a-fA-F]{2}\b',
        descriptionKey: 'regexbuilder_preset_hexbytes',
      ),
      PaletteItem(
        label: 'HTML Tag',
        snippet: r'<([a-zA-Z][a-zA-Z0-9]*)\b[^>]*>(.*?)</\1>',
        descriptionKey: 'regexbuilder_preset_htmltag',
      ),
      PaletteItem(
        label: 'Quoted Text',
        snippet: r'"[^"]*"',
        descriptionKey: 'regexbuilder_preset_quoted',
      ),
      PaletteItem(
        label: 'Slug',
        snippet: r'^[a-z0-9]+(?:-[a-z0-9]+)*$',
        descriptionKey: 'regexbuilder_preset_slug',
      ),
    ],
  ),
];