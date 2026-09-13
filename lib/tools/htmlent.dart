import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class HtmlEnt extends StatefulWidget {
  const HtmlEnt({super.key});

  @override
  State<HtmlEnt> createState() => _HtmlEntState();
}

class _HtmlEntState extends State<HtmlEnt>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();

  bool _encodeAll = false;
  bool _encodeQuotes = true;
  bool _encodeApostrophe = true;
  bool _encodeLtGt = true;
  bool _encodeAmp = true;
  String? _errorKey;

  static const Map<String, String> _basicEntities = <String, String>{
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#39;',
  };

  static const Map<String, String> _commonNamed = <String, String>{
    ' ': '&nbsp;',
    '©': '&copy;',
    '®': '&reg;',
    '™': '&trade;',
    '€': '&euro;',
    '£': '&pound;',
    '¥': '&yen;',
    '¢': '&cent;',
    '§': '&sect;',
    '¶': '&para;',
    '°': '&deg;',
    '±': '&plusmn;',
    '×': '&times;',
    '÷': '&divide;',
    '→': '&rarr;',
    '←': '&larr;',
    '↑': '&uarr;',
    '↓': '&darr;',
    '—': '&mdash;',
    '–': '&ndash;',
    '…': '&hellip;',
    '“': '&ldquo;',
    '”': '&rdquo;',
    '‘': '&lsquo;',
    '’': '&rsquo;',
    '«': '&laquo;',
    '»': '&raquo;',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _run();
    });
    _inputController.addListener(_run);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inputController.removeListener(_run);
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  String _encode(String input) {
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final String ch = input[i];
      String? entity;
      if (ch == '&' && _encodeAmp) {
        entity = '&amp;';
      } else if (ch == '<' && _encodeLtGt) {
        entity = '&lt;';
      } else if (ch == '>' && _encodeLtGt) {
        entity = '&gt;';
      } else if (ch == '"' && _encodeQuotes) {
        entity = '&quot;';
      } else if (ch == "'" && _encodeApostrophe) {
        entity = '&#39;';
      } else if (_encodeAll) {
        entity = _commonNamed[ch];
        if (entity == null) {
          final int code = ch.codeUnitAt(0);
          if (code > 126) {
            entity = '&#$code;';
          }
        }
      }
      buffer.write(entity ?? ch);
    }
    return buffer.toString();
  }

  String _decode(String input) {
    final RegExp namedRegex = RegExp(r'&([a-zA-Z]+);');
    final RegExp numericRegex = RegExp(r'&#(\d+);');
    final RegExp hexRegex = RegExp(r'&#x([0-9a-fA-F]+);');

    final Map<String, String> reverseNamed = <String, String>{};
    _basicEntities.forEach((String k, String v) {
      reverseNamed[v] = k;
    });
    _commonNamed.forEach((String k, String v) {
      reverseNamed[v] = k;
    });

    String out = input;
    out = out.replaceAllMapped(hexRegex, (Match m) {
      final int? code = int.tryParse(m.group(1)!, radix: 16);
      return code == null ? m.group(0)! : String.fromCharCode(code);
    });
    out = out.replaceAllMapped(numericRegex, (Match m) {
      final int? code = int.tryParse(m.group(1)!);
      return code == null ? m.group(0)! : String.fromCharCode(code);
    });
    out = out.replaceAllMapped(namedRegex, (Match m) {
      final String full = m.group(0)!;
      return reverseNamed[full] ?? full;
    });
    return out;
  }

  void _run() {
    final String input = _inputController.text;
    if (input.isEmpty) {
      setState(() {
        _outputController.text = '';
        _errorKey = null;
      });
      return;
    }
    try {
      final String result =
      _tabController.index == 0 ? _encode(input) : _decode(input);
      setState(() {
        _outputController.text = result;
        _errorKey = null;
      });
    } catch (e) {
      setState(() {
        _outputController.text = '';
        _errorKey = 'htmlent_error';
      });
    }
  }

  void _clear() {
    _inputController.clear();
  }

  Future<void> _paste() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null) return;
    _inputController.text = data.text!;
  }

  Future<void> _copy() async {
    if (_outputController.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _outputController.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('htmlent_copied'))),
    );
  }

  void _swap() {
    final String tmp = _inputController.text;
    _inputController.text = _outputController.text;
    _outputController.text = tmp;
  }

  Widget _optionSwitch(
      String key,
      bool value,
      ValueChanged<bool> onChanged,
      ) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(context.t(key)),
      value: value,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEncode = _tabController.index == 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('htmlent_title')),
        bottom: TabBar(
          controller: _tabController,
          tabs: <Widget>[
            Tab(text: context.t('htmlent_tab_encode')),
            Tab(text: context.t('htmlent_tab_decode')),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    context.t('htmlent_input_hint'),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: _paste,
                  icon: const Icon(Icons.paste, size: 18),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: _clear,
                  icon: const Icon(Icons.clear, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _inputController,
              maxLines: 6,
              minLines: 4,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    context.t('htmlent_output_hint'),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: _swap,
                  icon: const Icon(Icons.swap_vert, size: 18),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: _copy,
                  icon: const Icon(Icons.copy, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _outputController,
              readOnly: true,
              maxLines: 6,
              minLines: 4,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            if (_errorKey != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  context.t(_errorKey!),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            if (isEncode) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                context.t('htmlent_options'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              _optionSwitch('htmlent_amp', _encodeAmp, (bool v) {
                setState(() => _encodeAmp = v);
                _run();
              }),
              _optionSwitch('htmlent_ltgt', _encodeLtGt, (bool v) {
                setState(() => _encodeLtGt = v);
                _run();
              }),
              _optionSwitch('htmlent_quotes', _encodeQuotes, (bool v) {
                setState(() => _encodeQuotes = v);
                _run();
              }),
              _optionSwitch('htmlent_apostrophe', _encodeApostrophe, (bool v) {
                setState(() => _encodeApostrophe = v);
                _run();
              }),
              _optionSwitch('htmlent_encode_all', _encodeAll, (bool v) {
                setState(() => _encodeAll = v);
                _run();
              }),
            ],
          ],
        ),
      ),
    );
  }
}