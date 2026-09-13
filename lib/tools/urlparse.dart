import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class UrlParse extends StatefulWidget {
  const UrlParse({super.key});

  @override
  State<UrlParse> createState() => _UrlParseState();
}

class _UrlParseState extends State<UrlParse> {
  final TextEditingController _inputController = TextEditingController();

  String? _errorKey;
  Map<String, String> _parts = <String, String>{};
  List<MapEntry<String, String>> _queryParams = <MapEntry<String, String>>[];
  bool _parsed = false;

  @override
  void initState() {
    super.initState();
    _inputController.text =
    'https://api.example.com:8443/v1/users/profile?id=42&lang=az&sort=desc#section';
    _parse();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _parse() {
    final String raw = _inputController.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _parts = <String, String>{};
        _queryParams = <MapEntry<String, String>>[];
        _parsed = false;
        _errorKey = null;
      });
      return;
    }
    try {
      final Uri uri = Uri.parse(raw);
      final Map<String, String> parts = <String, String>{};
      parts['urlparse_scheme'] = uri.scheme.isEmpty ? '-' : uri.scheme;
      parts['urlparse_host'] = uri.host.isEmpty ? '-' : uri.host;
      parts['urlparse_port'] =
      uri.hasPort ? uri.port.toString() : (uri.scheme == 'https' ? '443' : uri.scheme == 'http' ? '80' : '-');
      parts['urlparse_path'] = uri.path.isEmpty ? '/' : uri.path;
      parts['urlparse_query'] =
      uri.query.isEmpty ? '-' : uri.query;
      parts['urlparse_fragment'] =
      uri.fragment.isEmpty ? '-' : uri.fragment;
      parts['urlparse_userinfo'] =
      uri.userInfo.isEmpty ? '-' : uri.userInfo;
      parts['urlparse_origin'] =
      uri.hasScheme && uri.host.isNotEmpty
          ? '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}'
          : '-';

      final List<MapEntry<String, String>> qp = <MapEntry<String, String>>[];
      uri.queryParameters.forEach((String k, String v) {
        qp.add(MapEntry<String, String>(k, v));
      });

      setState(() {
        _parts = parts;
        _queryParams = qp;
        _parsed = true;
        _errorKey = null;
      });
    } catch (_) {
      setState(() {
        _parts = <String, String>{};
        _queryParams = <MapEntry<String, String>>[];
        _parsed = false;
        _errorKey = 'urlparse_error';
      });
    }
  }

  void _clear() {
    setState(() {
      _inputController.clear();
      _parts = <String, String>{};
      _queryParams = <MapEntry<String, String>>[];
      _parsed = false;
      _errorKey = null;
    });
  }

  Future<void> _paste() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null) return;
    _inputController.text = data.text!;
    _parse();
  }

  Future<void> _copy(String text) async {
    if (text.isEmpty || text == '-') return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('urlparse_copied'))),
    );
  }

  Widget _row(String labelKey, String value, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(
              context.t(labelKey),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => _copy(value),
            icon: const Icon(Icons.copy, size: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('urlparse_title')),
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
                    context.t('urlparse_input_hint'),
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
              maxLines: 3,
              minLines: 2,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              onChanged: (_) => _parse(),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _parse,
              child: Text(context.t('urlparse_parse')),
            ),
            if (_errorKey != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  context.t(_errorKey!),
                  style: TextStyle(color: colors.error),
                ),
              ),
            if (_parsed) ...<Widget>[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      for (final String key in _parts.keys)
                        _row(key, _parts[key] ?? '-', colors),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${context.t('urlparse_query_params')} (${_queryParams.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              if (_queryParams.isEmpty)
                Text(
                  context.t('urlparse_no_params'),
                  style: TextStyle(color: colors.outline),
                )
              else
                Card(
                  child: Column(
                    children: <Widget>[
                      for (int i = 0; i < _queryParams.length; i++) ...<Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                flex: 2,
                                child: Text(
                                  _queryParams[i].key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: SelectableText(
                                  _queryParams[i].value,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: () =>
                                    _copy(_queryParams[i].value),
                                icon: const Icon(Icons.copy, size: 16),
                              ),
                            ],
                          ),
                        ),
                        if (i < _queryParams.length - 1)
                          Divider(
                            height: 1,
                            color: colors.outlineVariant,
                          ),
                      ],
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