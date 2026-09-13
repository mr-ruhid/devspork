import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class CronParse extends StatefulWidget {
  const CronParse({super.key});

  @override
  State<CronParse> createState() => _CronParseState();
}

class _CronParseState extends State<CronParse> {
  final TextEditingController _inputController = TextEditingController();

  String? _errorKey;
  String? _errorDetail;
  List<_CronField> _fields = <_CronField>[];
  List<DateTime> _nextRuns = <DateTime>[];
  String? _humanReadable;

  static const List<String> _monthNames = <String>[
    'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'İyun',
    'İyul', 'Avqust', 'Sentyabr', 'Oktyabr', 'Noyabr', 'Dekabr',
  ];

  static const List<String> _dayNames = <String>[
    'Bazar', 'Bazar ertəsi', 'Çərşənbə axşamı', 'Çərşənbə',
    'Cümə axşamı', 'Cümə', 'Şənbə',
  ];

  @override
  void initState() {
    super.initState();
    _inputController.text = '*/5 * * * *';
    _parse();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _fmt(DateTime dt) {
    return '${dt.year}-${_two(dt.month)}-${_two(dt.day)} '
        '${_two(dt.hour)}:${_two(dt.minute)}:${_two(dt.second)}';
  }

  void _parse() {
    final String input = _inputController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _errorKey = 'cronparse_error_empty';
        _errorDetail = null;
        _fields = <_CronField>[];
        _nextRuns = <DateTime>[];
        _humanReadable = null;
      });
      return;
    }
    final List<String> parts =
    input.split(RegExp(r'\s+')).where((String s) => s.isNotEmpty).toList();
    if (parts.length != 5 && parts.length != 6) {
      setState(() {
        _errorKey = 'cronparse_error_fields';
        _errorDetail = null;
        _fields = <_CronField>[];
        _nextRuns = <DateTime>[];
        _humanReadable = null;
      });
      return;
    }

    final bool hasSeconds = parts.length == 6;
    final List<_CronField> fields = <_CronField>[];
    try {
      fields.add(_CronField(
        nameKey: 'cronparse_field_minute',
        range: '0-59',
        value: hasSeconds ? parts[1] : parts[0],
        min: 0,
        max: 59,
        values: _expand(hasSeconds ? parts[1] : parts[0], 0, 59),
      ));
      fields.insert(0, _CronField(
        nameKey: 'cronparse_field_second',
        range: '0-59',
        value: hasSeconds ? parts[0] : '0',
        min: 0,
        max: 59,
        values: hasSeconds ? _expand(parts[0], 0, 59) : <int>[0],
      ));
      fields.add(_CronField(
        nameKey: 'cronparse_field_hour',
        range: '0-23',
        value: hasSeconds ? parts[2] : parts[1],
        min: 0,
        max: 23,
        values: _expand(hasSeconds ? parts[2] : parts[1], 0, 23),
      ));
      fields.add(_CronField(
        nameKey: 'cronparse_field_dom',
        range: '1-31',
        value: hasSeconds ? parts[3] : parts[2],
        min: 1,
        max: 31,
        values: _expand(hasSeconds ? parts[3] : parts[2], 1, 31),
      ));
      fields.add(_CronField(
        nameKey: 'cronparse_field_month',
        range: '1-12',
        value: hasSeconds ? parts[4] : parts[3],
        min: 1,
        max: 12,
        values: _expand(hasSeconds ? parts[4] : parts[3], 1, 12),
      ));
      fields.add(_CronField(
        nameKey: 'cronparse_field_dow',
        range: '0-6',
        value: hasSeconds ? parts[5] : parts[4],
        min: 0,
        max: 6,
        values: _expand(hasSeconds ? parts[5] : parts[4], 0, 6, dow: true),
      ));
    } catch (e) {
      setState(() {
        _errorKey = 'cronparse_error_invalid';
        _errorDetail = e.toString();
        _fields = <_CronField>[];
        _nextRuns = <DateTime>[];
        _humanReadable = null;
      });
      return;
    }

    final List<DateTime> next = _computeNext(fields, hasSeconds);
    setState(() {
      _fields = fields;
      _nextRuns = next;
      _humanReadable = _humanize(fields, hasSeconds);
      _errorKey = null;
      _errorDetail = null;
    });
  }

  List<int> _expand(String expr, int min, int max, {bool dow = false}) {
    final Set<int> result = <int>{};
    final List<String> parts = expr.split(',');
    for (final String part in parts) {
      if (part.isEmpty) throw Exception('empty');
      int step = 1;
      String range = part;
      if (part.contains('/')) {
        final List<String> sp = part.split('/');
        if (sp.length != 2) throw Exception('bad step');
        range = sp[0];
        step = int.parse(sp[1]);
        if (step <= 0) throw Exception('bad step');
      }
      int lo;
      int hi;
      if (range == '*' || range.isEmpty) {
        lo = min;
        hi = max;
      } else if (range.contains('-')) {
        final List<String> rp = range.split('-');
        lo = _num(rp[0], dow);
        hi = _num(rp[1], dow);
      } else {
        lo = _num(range, dow);
        hi = lo;
      }
      if (lo < min || hi > max || lo > hi) throw Exception('range');
      for (int v = lo; v <= hi; v += step) {
        int val = v;
        if (dow && val == 7) val = 0;
        result.add(val);
      }
    }
    final List<int> list = result.toList()..sort();
    return list;
  }

  int _num(String s, bool dow) {
    final int? n = int.tryParse(s);
    if (n != null) return n;
    final Map<String, int> months = <String, int>{
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    final Map<String, int> days = <String, int>{
      'sun': 0, 'mon': 1, 'tue': 2, 'wed': 3, 'thu': 4, 'fri': 5, 'sat': 6,
    };
    final String lower = s.toLowerCase();
    if (dow && days.containsKey(lower)) return days[lower]!;
    if (!dow && months.containsKey(lower)) return months[lower]!;
    throw Exception('name');
  }

  List<DateTime> _computeNext(List<_CronField> fields, bool hasSeconds) {
    final _CronField sec = fields[0];
    final _CronField min = fields[1];
    final _CronField hour = fields[2];
    final _CronField dom = fields[3];
    final _CronField mon = fields[4];
    final _CronField dow = fields[5];

    final List<DateTime> runs = <DateTime>[];
    DateTime cur = DateTime.now().add(const Duration(seconds: 1));
    cur = DateTime(cur.year, cur.month, cur.day, cur.hour, cur.minute,
        hasSeconds ? cur.second : 0);

    final int maxIter = 200000;
    int iter = 0;
    while (runs.length < 10 && iter < maxIter) {
      iter++;
      if (!mon.values.contains(cur.month)) {
        cur = DateTime(cur.year, cur.month + 1, 1, 0, 0, 0);
        continue;
      }
      final bool domRestricted =
          dom.value != '*' && !dom.value.contains('*');
      final bool dowRestricted =
          dow.value != '*' && !dow.value.contains('*');
      final bool domMatch = dom.values.contains(cur.day);
      final bool dowMatch = dow.values.contains(cur.weekday % 7);
      bool dayMatch;
      if (domRestricted && dowRestricted) {
        dayMatch = domMatch || dowMatch;
      } else if (domRestricted) {
        dayMatch = domMatch;
      } else if (dowRestricted) {
        dayMatch = dowMatch;
      } else {
        dayMatch = true;
      }
      if (!dayMatch) {
        cur = DateTime(cur.year, cur.month, cur.day + 1, 0, 0, 0);
        continue;
      }
      if (!hour.values.contains(cur.hour)) {
        cur = cur.add(const Duration(hours: 1));
        cur = DateTime(
            cur.year, cur.month, cur.day, cur.hour, 0, 0);
        continue;
      }
      if (!min.values.contains(cur.minute)) {
        cur = cur.add(const Duration(minutes: 1));
        cur = DateTime(cur.year, cur.month, cur.day, cur.hour, cur.minute, 0);
        continue;
      }
      if (hasSeconds) {
        if (!sec.values.contains(cur.second)) {
          cur = cur.add(const Duration(seconds: 1));
          continue;
        }
      }
      runs.add(cur);
      if (hasSeconds) {
        cur = cur.add(const Duration(seconds: 1));
      } else {
        cur = cur.add(const Duration(minutes: 1));
      }
    }
    return runs;
  }

  String _humanize(List<_CronField> fields, bool hasSeconds) {
    final _CronField min = fields[1];
    final _CronField hour = fields[2];
    final _CronField dom = fields[3];
    final _CronField mon = fields[4];
    final _CronField dow = fields[5];

    final StringBuffer buffer = StringBuffer();
    final bool everyMinute = min.value == '*';
    final bool everyHour = hour.value == '*';

    if (everyMinute && everyHour) {
      buffer.write(context.t('cronparse_human_every_minute'));
    } else if (min.value.startsWith('*/') && everyHour) {
      buffer.write(
          '${context.t('cronparse_human_every')} ${min.value.substring(2)} ${context.t('cronparse_human_minutes')}');
    } else if (hour.value.startsWith('*/') && min.values.length == 1) {
      buffer.write(
          '${context.t('cronparse_human_every')} ${hour.value.substring(2)} ${context.t('cronparse_human_hours')}');
    } else {
      buffer.write('${context.t('cronparse_human_at')} ');
      final List<String> times = <String>[];
      for (final int h in hour.values) {
        for (final int m in min.values) {
          times.add('${_two(h)}:${_two(m)}');
        }
      }
      buffer.write(times.take(6).join(', '));
      if (times.length > 6) buffer.write(' ...');
    }

    if (dom.value != '*') {
      buffer.write(
          ' ${context.t('cronparse_human_on_day')} ${dom.values.join(', ')}');
    }
    if (mon.value != '*') {
      final List<String> months = mon.values
          .map((int m) => _monthNames[m - 1])
          .toList();
      buffer.write(
          ' ${context.t('cronparse_human_in_month')} ${months.join(', ')}');
    }
    if (dow.value != '*') {
      final List<String> days =
      dow.values.map((int d) => _dayNames[d]).toList();
      buffer.write(
          ' ${context.t('cronparse_human_on')} ${days.join(', ')}');
    }
    return buffer.toString();
  }

  void _clear() {
    _inputController.clear();
    setState(() {
      _fields = <_CronField>[];
      _nextRuns = <DateTime>[];
      _humanReadable = null;
      _errorKey = null;
      _errorDetail = null;
    });
  }

  Future<void> _paste() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null) return;
    _inputController.text = data.text!;
    _parse();
  }

  Future<void> _copy(String text) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('cronparse_copied'))),
    );
  }

  Widget _preset(String expr) {
    return ActionChip(
      label: Text(expr, style: const TextStyle(fontSize: 12)),
      onPressed: () {
        _inputController.text = expr;
        _parse();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('cronparse_title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _inputController,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                letterSpacing: 1.2,
              ),
              decoration: InputDecoration(
                labelText: context.t('cronparse_input_hint'),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: _paste,
                  icon: const Icon(Icons.paste),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton(
                    onPressed: _parse,
                    child: Text(context.t('cronparse_parse')),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _clear,
                  icon: const Icon(Icons.clear),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _preset('* * * * *'),
                _preset('*/5 * * * *'),
                _preset('0 * * * *'),
                _preset('0 0 * * *'),
                _preset('0 9 * * 1-5'),
                _preset('0 0 1 * *'),
                _preset('0 0 1 1 *'),
              ],
            ),
            if (_errorKey != null) ...<Widget>[
              const SizedBox(height: 16),
              Text(
                context.t(_errorKey!),
                style: TextStyle(color: colors.error),
              ),
              if (_errorDetail != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _errorDetail!,
                    style: TextStyle(color: colors.error, fontSize: 12),
                  ),
                ),
            ],
            if (_fields.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              Text(
                context.t('cronparse_breakdown'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              for (final _CronField f in _fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                        width: 110,
                        child: Text(
                          context.t(f.nameKey),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${f.value}   (${f.range})   →   ${f.values.join(', ')}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_humanReadable != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  context.t('cronparse_human'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(_humanReadable!),
              ],
              const SizedBox(height: 16),
              Text(
                context.t('cronparse_next_runs'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              if (_nextRuns.isEmpty)
                Text(
                  context.t('cronparse_no_runs'),
                  style: TextStyle(color: colors.outline),
                )
              else
                for (int i = 0; i < _nextRuns.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: <Widget>[
                        SizedBox(
                          width: 24,
                          child: Text(
                            '${i + 1}.',
                            style: TextStyle(color: colors.outline),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _fmt(_nextRuns[i]),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _copy(_fmt(_nextRuns[i])),
                          icon: const Icon(Icons.copy, size: 16),
                        ),
                      ],
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CronField {
  final String nameKey;
  final String range;
  final String value;
  final int min;
  final int max;
  final List<int> values;

  _CronField({
    required this.nameKey,
    required this.range,
    required this.value,
    required this.min,
    required this.max,
    required this.values,
  });
}