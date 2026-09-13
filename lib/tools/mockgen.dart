import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class MockGen extends StatefulWidget {
  const MockGen({super.key});

  @override
  State<MockGen> createState() => _MockGenState();
}

class _MockGenState extends State<MockGen> {
  final TextEditingController _outputController = TextEditingController();
  final Random _random = Random();

  double _count = 20;
  String _format = 'json';
  String _nameLang = 'az';
  bool _includeId = true;
  bool _includeName = true;
  bool _includeEmail = true;
  bool _includePhone = true;
  bool _includeAge = true;
  bool _includeCity = true;
  bool _includeCountry = true;
  bool _includeCompany = true;
  bool _includeDate = true;
  bool _includeUuid = true;
  bool _includePrice = false;

  static const List<String> _formats = <String>[
    'json',
    'csv',
    'sql',
    'xml',
    'yaml',
    'markdown',
  ];

  static const List<String> _nameLangs = <String>['az', 'en', 'tr'];

  static const Map<String, List<String>> _firstNames = <String, List<String>>{
    'az': <String>[
      'Ali', 'Vəli', 'Həsən', 'Hüseyn', 'Rəşad', 'Elvin', 'Kamran',
      'Orxan', 'Fərid', 'Nihad', 'Ruslan', 'Tural', 'Anar', 'Emin',
      'Aysel', 'Leyla', 'Nigar', 'Günay', 'Səbinə', 'Aysu', 'Zeynəb',
      'Lalə', 'Ülviyyə', 'Könül', 'Nurlana', 'Şəbnəm', 'Aytac',
    ],
    'en': <String>[
      'John', 'Michael', 'David', 'James', 'Robert', 'William', 'Daniel',
      'Matthew', 'Christopher', 'Andrew', 'Emma', 'Olivia', 'Sophia',
      'Isabella', 'Mia', 'Charlotte', 'Amelia', 'Harper', 'Evelyn',
      'Abigail', 'Emily', 'Elizabeth', 'Sofia', 'Avery',
    ],
    'tr': <String>[
      'Ahmet', 'Mehmet', 'Mustafa', 'Ali', 'Hüseyin', 'Hasan', 'İbrahim',
      'Osman', 'Yusuf', 'Murat', 'Emre', 'Burak', 'Ayşe', 'Fatma',
      'Emine', 'Hatice', 'Zeynep', 'Elif', 'Meryem', 'Şerife',
      'Sultan', 'Zehra', 'Hanife',
    ],
  };

  static const Map<String, List<String>> _lastNames = <String, List<String>>{
    'az': <String>[
      'Məmmədov', 'Əliyev', 'Həsənov', 'Hüseynov', 'Quliyev', 'İsmayılov',
      'Rəhimov', 'Nəsirov', 'Abbasov', 'Sultanov', 'Məmmədova', 'Əliyeva',
      'Həsənova', 'Hüseynova', 'Quliyeva', 'İsmayılova', 'Rəhimova',
      'Nəsirova', 'Abbasova', 'Sultanova',
    ],
    'en': <String>[
      'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller',
      'Davis', 'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Gonzalez',
      'Wilson', 'Anderson', 'Thomas', 'Taylor', 'Moore', 'Jackson',
    ],
    'tr': <String>[
      'Yılmaz', 'Kaya', 'Demir', 'Şahin', 'Çelik', 'Yıldız', 'Yıldırım',
      'Öztürk', 'Aydın', 'Özdemir', 'Arslan', 'Doğan', 'Kılıç', 'Aslan',
      'Çetin', 'Kara', 'Koç', 'Kurt', 'Özkan',
    ],
  };

  static const List<String> _citiesAz = <String>[
    'Bakı', 'Gəncə', 'Sumqayıt', 'Mingəçevir', 'Şirvan', 'Naxçıvan',
    'Şəki', 'Yevlax', 'Lənkəran', 'Xankəndi', 'Şuşa', 'Quba', 'Qusar',
  ];

  static const List<String> _citiesEn = <String>[
    'New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix',
    'Philadelphia', 'San Antonio', 'San Diego', 'Dallas', 'San Jose',
    'Austin', 'Jacksonville', 'London', 'Manchester', 'Birmingham',
  ];

  static const List<String> _citiesTr = <String>[
    'İstanbul', 'Ankara', 'İzmir', 'Bursa', 'Antalya', 'Adana', 'Konya',
    'Gaziantep', 'Şanlıurfa', 'Mersin', 'Diyarbakır', 'Kayseri', 'Eskişehir',
  ];

  static const Map<String, String> _countries = <String, String>{
    'az': 'Azərbaycan',
    'en': 'United States',
    'tr': 'Türkiye',
  };

  static const List<String> _companiesAz = <String>[
    'Azercell', 'Bakcell', 'Nar', 'SOCAR', 'Azersu', 'Azerenerji',
    'Azpetrol', 'Bravo', 'Araz', 'Baku Steel',
  ];

  static const List<String> _companiesEn = <String>[
    'Google', 'Microsoft', 'Apple', 'Amazon', 'Meta', 'Tesla', 'Netflix',
    'Adobe', 'Oracle', 'IBM', 'Intel', 'NVIDIA',
  ];

  static const List<String> _companiesTr = <String>[
    'Turkcell', 'Vodafone', 'Türk Telekom', 'Arçelik', 'Vestel',
    'Koç Holding', 'Sabancı', 'Anadolu Efes', 'THY', 'Beko',
  ];

  static const List<String> _domains = <String>[
    'example.com',
    'test.com',
    'mail.com',
    'demo.org',
    'sample.net',
  ];

  @override
  void initState() {
    super.initState();
    _generate();
  }

  @override
  void dispose() {
    _outputController.dispose();
    super.dispose();
  }

  String _pick(List<String> list) {
    return list[_random.nextInt(list.length)];
  }

  int _intBetween(int min, int max) {
    return min + _random.nextInt(max - min + 1);
  }

  String _uuid() {
    const String hex = '0123456789abcdef';
    final StringBuffer b = StringBuffer();
    for (int i = 0; i < 32; i++) {
      if (i == 8 || i == 12 || i == 16 || i == 20) b.write('-');
      if (i == 12) {
        b.write('4');
      } else if (i == 16) {
        b.write(hex[8 + _random.nextInt(4)]);
      } else {
        b.write(hex[_random.nextInt(16)]);
      }
    }
    return b.toString();
  }

  String _date() {
    final int y = _intBetween(1990, 2024);
    final int m = _intBetween(1, 12);
    final int d = _intBetween(1, 28);
    return '$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> _makeRow(int index) {
    final String first = _pick(_firstNames[_nameLang]!);
    final String last = _pick(_lastNames[_nameLang]!);
    final String name = '$first $last';
    final String emailUser =
    '$first.$last'.toLowerCase().replaceAll(RegExp(r'[^a-z.]'), '');
    final Map<String, dynamic> row = <String, dynamic>{};
    if (_includeId) row['id'] = index + 1;
    if (_includeUuid) row['uuid'] = _uuid();
    if (_includeName) row['name'] = name;
    if (_includeEmail) {
      row['email'] = '$emailUser${index + 1}@${_pick(_domains)}';
    }
    if (_includePhone) {
      if (_nameLang == 'az') {
        row['phone'] = '+994 ${_intBetween(50, 77)} '
            '${_intBetween(100, 999)} '
            '${_intBetween(10, 99)} '
            '${_intBetween(10, 99)}';
      } else if (_nameLang == 'tr') {
        row['phone'] = '+90 5${_intBetween(30, 59)} '
            '${_intBetween(100, 999)} '
            '${_intBetween(10, 99)} '
            '${_intBetween(10, 99)}';
      } else {
        row['phone'] = '(${_intBetween(200, 999)}) '
            '${_intBetween(200, 999)}-'
            '${_intBetween(1000, 9999)}';
      }
    }
    if (_includeAge) row['age'] = _intBetween(18, 70);
    if (_includeCity) {
      if (_nameLang == 'az') {
        row['city'] = _pick(_citiesAz);
      } else if (_nameLang == 'tr') {
        row['city'] = _pick(_citiesTr);
      } else {
        row['city'] = _pick(_citiesEn);
      }
    }
    if (_includeCountry) row['country'] = _countries[_nameLang];
    if (_includeCompany) {
      if (_nameLang == 'az') {
        row['company'] = _pick(_companiesAz);
      } else if (_nameLang == 'tr') {
        row['company'] = _pick(_companiesTr);
      } else {
        row['company'] = _pick(_companiesEn);
      }
    }
    if (_includeDate) row['created_at'] = _date();
    if (_includePrice) {
      row['price'] = (_random.nextDouble() * 1000).toStringAsFixed(2);
    }
    return row;
  }

  String _escapeJson(String s) {
    return s
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n');
  }

  String _escapeXml(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }

  String _buildJson(List<Map<String, dynamic>> rows) {
    return const JsonEncoder.withIndent('  ').convert(rows);
  }

  String _buildCsv(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return '';
    final List<String> headers = rows.first.keys.toList();
    final StringBuffer b = StringBuffer();
    b.writeln(headers.join(','));
    for (final Map<String, dynamic> r in rows) {
      b.writeln(headers
          .map((String h) {
        final String v = r[h]?.toString() ?? '';
        if (v.contains(',') || v.contains('"')) {
          return '"${v.replaceAll('"', '""')}"';
        }
        return v;
      })
          .join(','));
    }
    return b.toString().trimRight();
  }

  String _buildSql(List<Map<String, dynamic>> rows, String tableName) {
    if (rows.isEmpty) return '';
    final List<String> headers = rows.first.keys.toList();
    final StringBuffer b = StringBuffer();
    for (final Map<String, dynamic> r in rows) {
      final List<String> values = headers.map((String h) {
        final dynamic v = r[h];
        if (v is num) return v.toString();
        return "'${v.toString().replaceAll("'", "''")}'";
      }).toList();
      b.writeln(
        'INSERT INTO $tableName (${headers.join(', ')}) '
            'VALUES (${values.join(', ')});',
      );
    }
    return b.toString().trimRight();
  }

  String _buildXml(List<Map<String, dynamic>> rows) {
    final StringBuffer b = StringBuffer();
    b.writeln('<items>');
    for (final Map<String, dynamic> r in rows) {
      b.writeln('  <item>');
      r.forEach((String k, dynamic v) {
        b.writeln('    <$k>${_escapeXml(v.toString())}</$k>');
      });
      b.writeln('  </item>');
    }
    b.writeln('</items>');
    return b.toString().trimRight();
  }

  String _buildYaml(List<Map<String, dynamic>> rows) {
    final StringBuffer b = StringBuffer();
    for (final Map<String, dynamic> r in rows) {
      b.writeln('-');
      r.forEach((String k, dynamic v) {
        final String value = v is num ? v.toString() : '"${v.toString()}"';
        b.writeln('  $k: $value');
      });
    }
    return b.toString().trimRight();
  }

  String _buildMarkdown(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return '';
    final List<String> headers = rows.first.keys.toList();
    final StringBuffer b = StringBuffer();
    b.writeln('| ${headers.join(' | ')} |');
    b.writeln('| ${headers.map((String _) => '---').join(' | ')} |');
    for (final Map<String, dynamic> r in rows) {
      b.writeln(
        '| ${headers.map((String h) => r[h]?.toString() ?? '').join(' | ')} |',
      );
    }
    return b.toString().trimRight();
  }

  void _generate() {
    final int n = _count.round();
    final List<Map<String, dynamic>> rows =
    List<Map<String, dynamic>>.generate(n, (int i) => _makeRow(i));
    String result;
    switch (_format) {
      case 'json':
        result = _buildJson(rows);
        break;
      case 'csv':
        result = _buildCsv(rows);
        break;
      case 'sql':
        result = _buildSql(rows, 'users');
        break;
      case 'xml':
        result = _buildXml(rows);
        break;
      case 'yaml':
        result = _buildYaml(rows);
        break;
      case 'markdown':
        result = _buildMarkdown(rows);
        break;
      default:
        result = _buildJson(rows);
    }
    setState(() {
      _outputController.text = result;
    });
  }

  Future<void> _copy() async {
    if (_outputController.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _outputController.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('mockgen_copied'))),
    );
  }

  void _clear() {
    setState(() {
      _outputController.clear();
    });
  }

  Widget _fieldSwitch(
      String key,
      bool value,
      ValueChanged<bool> onChanged,
      ) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(context.t(key), style: const TextStyle(fontSize: 13)),
      value: value,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool hasOutput = _outputController.text.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('mockgen_title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              '${context.t('mockgen_count')}: ${_count.round()}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Slider(
              value: _count,
              min: 1,
              max: 500,
              divisions: 499,
              label: _count.round().toString(),
              onChanged: (double v) {
                setState(() {
                  _count = v;
                });
              },
              onChangeEnd: (_) => _generate(),
            ),
            const SizedBox(height: 4),
            Text(
              context.t('mockgen_lang'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: _nameLangs
                  .map((String l) => ButtonSegment<String>(
                value: l,
                label: Text(l.toUpperCase()),
              ))
                  .toList(),
              selected: <String>{_nameLang},
              onSelectionChanged: (Set<String> s) {
                setState(() {
                  _nameLang = s.first;
                });
                _generate();
              },
            ),
            const SizedBox(height: 12),
            Text(
              context.t('mockgen_format'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _formats.map((String f) {
                return ChoiceChip(
                  label: Text(context.t('mockgen_fmt_$f')),
                  selected: _format == f,
                  onSelected: (_) {
                    setState(() {
                      _format = f;
                    });
                    _generate();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              context.t('mockgen_fields'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            _fieldSwitch('mockgen_field_id', _includeId, (bool v) {
              setState(() => _includeId = v);
              _generate();
            }),
            _fieldSwitch('mockgen_field_uuid', _includeUuid, (bool v) {
              setState(() => _includeUuid = v);
              _generate();
            }),
            _fieldSwitch('mockgen_field_name', _includeName, (bool v) {
              setState(() => _includeName = v);
              _generate();
            }),
            _fieldSwitch('mockgen_field_email', _includeEmail, (bool v) {
              setState(() => _includeEmail = v);
              _generate();
            }),
            _fieldSwitch('mockgen_field_phone', _includePhone, (bool v) {
              setState(() => _includePhone = v);
              _generate();
            }),
            _fieldSwitch('mockgen_field_age', _includeAge, (bool v) {
              setState(() => _includeAge = v);
              _generate();
            }),
            _fieldSwitch('mockgen_field_city', _includeCity, (bool v) {
              setState(() => _includeCity = v);
              _generate();
            }),
            _fieldSwitch('mockgen_field_country', _includeCountry, (bool v) {
              setState(() => _includeCountry = v);
              _generate();
            }),
            _fieldSwitch('mockgen_field_company', _includeCompany, (bool v) {
              setState(() => _includeCompany = v);
              _generate();
            }),
            _fieldSwitch('mockgen_field_date', _includeDate, (bool v) {
              setState(() => _includeDate = v);
              _generate();
            }),
            _fieldSwitch('mockgen_field_price', _includePrice, (bool v) {
              setState(() => _includePrice = v);
              _generate();
            }),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _generate,
                    icon: const Icon(Icons.refresh),
                    label: Text(context.t('mockgen_generate')),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: hasOutput ? _copy : null,
                  icon: const Icon(Icons.copy),
                  tooltip: context.t('mockgen_copy'),
                ),
                IconButton(
                  onPressed: _clear,
                  icon: const Icon(Icons.clear),
                  tooltip: context.t('mockgen_clear'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _outputController,
              readOnly: true,
              maxLines: null,
              minLines: 12,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              decoration: InputDecoration(
                labelText: context.t('mockgen_output_hint'),
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
                filled: true,
                fillColor: colors.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}