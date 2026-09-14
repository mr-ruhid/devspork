import 'models.dart';

class CronGenerator {
  CronGenerator._();

  static String build(Map<CronField, CronFieldConfig> configs) {
    final List<String> parts = <String>[];
    for (final CronField field in CronField.values) {
      final CronFieldConfig? c = configs[field];
      if (c == null) {
        parts.add('*');
      } else {
        parts.add(_fieldToString(c, field));
      }
    }
    return parts.join(' ');
  }

  static String _fieldToString(CronFieldConfig c, CronField field) {
    switch (c.mode) {
      case CronFieldMode.any:
        return '*';
      case CronFieldMode.specific:
        return '${c.specificValue}';
      case CronFieldMode.range:
        final int from = c.rangeFrom;
        final int to = c.rangeTo;
        final int lo = from <= to ? from : to;
        final int hi = from <= to ? to : from;
        return '$lo-$hi';
      case CronFieldMode.step:
        final String base = c.stepFrom == field.minValue
            ? '*'
            : '${c.stepFrom}-${field.maxValue}';
        return '$base/${c.stepEvery}';
      case CronFieldMode.list:
        if (c.listValues.isEmpty) return '*';
        final List<int> sorted = List<int>.from(c.listValues)..sort();
        return sorted.join(',');
    }
  }

  static Map<CronField, CronFieldConfig> parse(String expression) {
    final String trimmed = expression.trim();
    final List<String> parts = trimmed.split(RegExp(r'\s+'));

    final Map<CronField, CronFieldConfig> result =
    <CronField, CronFieldConfig>{};

    for (int i = 0; i < CronField.values.length; i++) {
      final CronField field = CronField.values[i];
      final String raw = i < parts.length ? parts[i] : '*';
      result[field] = _parseField(raw, field);
    }
    return result;
  }

  static CronFieldConfig _parseField(String raw, CronField field) {
    final CronFieldConfig config = CronFieldConfig(field: field);

    if (raw == '*' || raw.isEmpty) {
      config.mode = CronFieldMode.any;
      return config;
    }

    if (raw.contains('/')) {
      final List<String> pieces = raw.split('/');
      final int every = int.tryParse(pieces[1]) ?? 1;
      config.mode = CronFieldMode.step;
      config.stepEvery = every;
      if (pieces[0] == '*') {
        config.stepFrom = field.minValue;
      } else if (pieces[0].contains('-')) {
        final List<String> range = pieces[0].split('-');
        config.stepFrom = _tryInt(range[0]) ?? field.minValue;
        final int to = _tryInt(range[1]) ?? field.maxValue;
        config.rangeFrom = config.stepFrom;
        config.rangeTo = to;
      } else {
        config.stepFrom = _tryInt(pieces[0]) ?? field.minValue;
      }
      return config;
    }

    if (raw.contains(',')) {
      final List<String> pieces = raw.split(',');
      final List<int> values = <int>[];
      for (final String p in pieces) {
        final int? v = _tryInt(p);
        if (v != null) values.add(v);
      }
      config.mode = CronFieldMode.list;
      config.listValues = values.isEmpty ? <int>[field.minValue] : values;
      return config;
    }

    if (raw.contains('-')) {
      final List<String> pieces = raw.split('-');
      final int? from = _tryInt(pieces[0]);
      final int? to = _tryInt(pieces[1]);
      config.mode = CronFieldMode.range;
      config.rangeFrom = from ?? field.minValue;
      config.rangeTo = to ?? field.maxValue;
      return config;
    }

    final int? v = _tryInt(raw);
    if (v != null) {
      config.mode = CronFieldMode.specific;
      config.specificValue = v;
    } else {
      config.mode = CronFieldMode.any;
    }
    return config;
  }

  static int? _tryInt(String raw) {
    final String t = raw.trim().toUpperCase();
    final int? direct = int.tryParse(t);
    if (direct != null) return direct;

    const Map<String, int> monthAliases = <String, int>{
      'JAN': 1,
      'FEB': 2,
      'MAR': 3,
      'APR': 4,
      'MAY': 5,
      'JUN': 6,
      'JUL': 7,
      'AUG': 8,
      'SEP': 9,
      'OCT': 10,
      'NOV': 11,
      'DEC': 12,
    };
    const Map<String, int> dayAliases = <String, int>{
      'SUN': 0,
      'MON': 1,
      'TUE': 2,
      'WED': 3,
      'THU': 4,
      'FRI': 5,
      'SAT': 6,
    };

    if (monthAliases.containsKey(t)) return monthAliases[t];
    if (dayAliases.containsKey(t)) return dayAliases[t];
    return null;
  }

  static bool isValid(String expression) {
    final String trimmed = expression.trim();
    if (trimmed.isEmpty) return false;

    final List<String> parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length != 5) return false;

    for (int i = 0; i < 5; i++) {
      final CronField field = CronField.values[i];
      if (!_validateField(parts[i], field)) return false;
    }
    return true;
  }

  static bool _validateField(String raw, CronField field) {
    if (raw.isEmpty) return false;

    if (raw.contains('/')) {
      final List<String> pieces = raw.split('/');
      if (pieces.length != 2) return false;
      final int? every = int.tryParse(pieces[1]);
      if (every == null || every <= 0) return false;
      if (pieces[0] == '*') return true;
      if (pieces[0].contains('-')) {
        final List<String> range = pieces[0].split('-');
        if (range.length != 2) return false;
        final int? from = _tryInt(range[0]);
        final int? to = _tryInt(range[1]);
        if (from == null || to == null) return false;
        return _inRange(from, field) && _inRange(to, field);
      }
      final int? v = _tryInt(pieces[0]);
      return v != null && _inRange(v, field);
    }

    if (raw.contains(',')) {
      final List<String> pieces = raw.split(',');
      if (pieces.isEmpty) return false;
      for (final String p in pieces) {
        final int? v = _tryInt(p);
        if (v == null || !_inRange(v, field)) return false;
      }
      return true;
    }

    if (raw.contains('-')) {
      final List<String> pieces = raw.split('-');
      if (pieces.length != 2) return false;
      final int? from = _tryInt(pieces[0]);
      final int? to = _tryInt(pieces[1]);
      if (from == null || to == null) return false;
      return _inRange(from, field) && _inRange(to, field);
    }

    if (raw == '*') return true;
    final int? v = _tryInt(raw);
    return v != null && _inRange(v, field);
  }

  static bool _inRange(int v, CronField field) =>
      v >= field.minValue && v <= field.maxValue;

  static String describe(Map<CronField, CronFieldConfig> configs) {
    final StringBuffer sb = StringBuffer();

    final CronFieldConfig? min = configs[CronField.minute];
    final CronFieldConfig? hr = configs[CronField.hour];
    final CronFieldConfig? dom = configs[CronField.dayOfMonth];
    final CronFieldConfig? mon = configs[CronField.month];
    final CronFieldConfig? dow = configs[CronField.dayOfWeek];

    final String timePart = _describeTime(min, hr);
    final String dayPart = _describeDay(dom, dow);
    final String monthPart = _describeMonth(mon);

    sb.write(timePart);
    if (dayPart.isNotEmpty) {
      sb.write(', ');
      sb.write(dayPart);
    }
    if (monthPart.isNotEmpty) {
      sb.write(', ');
      sb.write(monthPart);
    }
    return sb.toString();
  }

  static String _describeTime(CronFieldConfig? min, CronFieldConfig? hr) {
    if (min == null || hr == null) return 'at *:*';

    final bool minAny = min.mode == CronFieldMode.any;
    final bool hrAny = hr.mode == CronFieldMode.any;

    if (minAny && hrAny) return 'every minute';
    if (!minAny && hrAny) {
      if (min.mode == CronFieldMode.specific) {
        return 'at minute ${min.specificValue}';
      }
      if (min.mode == CronFieldMode.step) {
        return 'every ${min.stepEvery} minutes';
      }
      return 'at minutes ${_listOf(min)}';
    }

    if (minAny && !hrAny) {
      if (hr.mode == CronFieldMode.specific) {
        return 'every minute during hour ${hr.specificValue}';
      }
      if (hr.mode == CronFieldMode.step) {
        return 'every minute, every ${hr.stepEvery} hours';
      }
      return 'every minute during hours ${_listOf(hr)}';
    }

    if (min.mode == CronFieldMode.step && hr.mode == CronFieldMode.step) {
      return 'every ${min.stepEvery} minutes, every ${hr.stepEvery} hours';
    }

    if (min.mode == CronFieldMode.specific && hr.mode == CronFieldMode.specific) {
      final String h = hr.specificValue.toString().padLeft(2, '0');
      final String m = min.specificValue.toString().padLeft(2, '0');
      return 'at $h:$m';
    }

    if (hr.mode == CronFieldMode.specific && min.mode == CronFieldMode.step) {
      final String h = hr.specificValue.toString().padLeft(2, '0');
      return 'every ${min.stepEvery} minutes during hour $h';
    }

    if (hr.mode == CronFieldMode.specific && min.mode == CronFieldMode.list) {
      final String h = hr.specificValue.toString().padLeft(2, '0');
      return 'at minutes ${_listOf(min)} of hour $h';
    }

    return 'at ${_describeField(min, CronField.minute)} '
        '${_describeField(hr, CronField.hour)}';
  }

  static String _describeDay(CronFieldConfig? dom, CronFieldConfig? dow) {
    if (dom == null || dow == null) return '';
    final bool domAny = dom.mode == CronFieldMode.any;
    final bool dowAny = dow.mode == CronFieldMode.any;

    if (domAny && dowAny) return '';

    if (!dowAny) {
      if (dow.mode == CronFieldMode.specific) {
        final String? name = kDayNames[dow.specificValue];
        if (name != null) return 'on $name';
      }
      if (dow.mode == CronFieldMode.range) {
        final String? a = kDayNames[dow.rangeFrom];
        final String? b = kDayNames[dow.rangeTo];
        if (a != null && b != null) return 'on $a-$b';
      }
      if (dow.mode == CronFieldMode.list) {
        final List<String> names = dow.listValues
            .map((int v) => kDayNames[v] ?? '$v')
            .toList();
        if (names.isNotEmpty) return 'on ${names.join(', ')}';
      }
      return 'on ${_describeField(dow, CronField.dayOfWeek)}';
    }

    if (dom.mode == CronFieldMode.specific) {
      return 'on day ${dom.specificValue}';
    }
    if (dom.mode == CronFieldMode.range) {
      return 'on days ${dom.rangeFrom}-${dom.rangeTo}';
    }
    if (dom.mode == CronFieldMode.list) {
      return 'on days ${_listOf(dom)}';
    }
    return 'on ${_describeField(dom, CronField.dayOfMonth)}';
  }

  static String _describeMonth(CronFieldConfig? mon) {
    if (mon == null || mon.mode == CronFieldMode.any) return '';
    if (mon.mode == CronFieldMode.specific) {
      final String? name = kMonthNames[mon.specificValue];
      if (name != null) return 'in $name';
    }
    if (mon.mode == CronFieldMode.range) {
      final String? a = kMonthNames[mon.rangeFrom];
      final String? b = kMonthNames[mon.rangeTo];
      if (a != null && b != null) return 'from $a to $b';
    }
    if (mon.mode == CronFieldMode.list) {
      final List<String> names = mon.listValues
          .map((int v) => kMonthNames[v] ?? '$v')
          .toList();
      if (names.isNotEmpty) return 'in ${names.join(', ')}';
    }
    return 'in ${_describeField(mon, CronField.month)}';
  }

  static String _listOf(CronFieldConfig c) {
    final List<int> sorted = List<int>.from(c.listValues)..sort();
    return sorted.join(', ');
  }

  static String _describeField(CronFieldConfig c, CronField field) {
    switch (c.mode) {
      case CronFieldMode.any:
        return '*';
      case CronFieldMode.specific:
        return '${c.specificValue}';
      case CronFieldMode.range:
        return '${c.rangeFrom}-${c.rangeTo}';
      case CronFieldMode.step:
        return 'every ${c.stepEvery}';
      case CronFieldMode.list:
        return _listOf(c);
    }
  }

  static List<DateTime> nextRuns(
      Map<CronField, CronFieldConfig> configs,
      DateTime from, {
        int count = 10,
      }) {
    final List<DateTime> results = <DateTime>[];
    DateTime cursor = from.add(const Duration(minutes: 1));
    cursor = DateTime(
      cursor.year,
      cursor.month,
      cursor.day,
      cursor.hour,
      cursor.minute,
    );

    final int hardLimit = 366 * 24 * 60 * 5;
    int iterations = 0;

    while (results.length < count && iterations < hardLimit) {
      iterations++;
      if (_matches(cursor, configs)) {
        results.add(cursor);
      }
      cursor = cursor.add(const Duration(minutes: 1));
    }
    return results;
  }

  static bool _matches(
      DateTime dt,
      Map<CronField, CronFieldConfig> configs,
      ) {
    final CronFieldConfig? min = configs[CronField.minute];
    final CronFieldConfig? hr = configs[CronField.hour];
    final CronFieldConfig? dom = configs[CronField.dayOfMonth];
    final CronFieldConfig? mon = configs[CronField.month];
    final CronFieldConfig? dow = configs[CronField.dayOfWeek];

    if (min != null && !_matchesField(dt.minute, min, CronField.minute)) {
      return false;
    }
    if (hr != null && !_matchesField(dt.hour, hr, CronField.hour)) {
      return false;
    }
    if (mon != null && !_matchesField(dt.month, mon, CronField.month)) {
      return false;
    }

    final bool dowRestricted = dow != null && dow.mode != CronFieldMode.any;
    final bool domRestricted = dom != null && dom.mode != CronFieldMode.any;

    final bool domOk =
        dom == null || !domRestricted || _matchesField(dt.day, dom, CronField.dayOfMonth);

    final int wd = dt.weekday == 7 ? 0 : dt.weekday;
    final bool dowOk =
        dow == null || !dowRestricted || _matchesField(wd, dow, CronField.dayOfWeek);

    if (dowRestricted && domRestricted) {
      return domOk || dowOk;
    }
    if (dowRestricted) return dowOk;
    if (domRestricted) return domOk;
    return true;
  }

  static bool _matchesField(int value, CronFieldConfig c, CronField field) {
    switch (c.mode) {
      case CronFieldMode.any:
        return true;
      case CronFieldMode.specific:
        return value == c.specificValue;
      case CronFieldMode.range:
        final int lo = c.rangeFrom <= c.rangeTo ? c.rangeFrom : c.rangeTo;
        final int hi = c.rangeFrom <= c.rangeTo ? c.rangeTo : c.rangeFrom;
        return value >= lo && value <= hi;
      case CronFieldMode.step:
        if (value < c.stepFrom) return false;
        final int delta = value - c.stepFrom;
        return c.stepEvery > 0 && delta % c.stepEvery == 0;
      case CronFieldMode.list:
        return c.listValues.contains(value);
    }
  }
}