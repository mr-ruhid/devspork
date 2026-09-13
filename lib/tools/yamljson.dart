import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';
import '../core/localization/app_localization.dart';

class YamlJson extends StatefulWidget {
  const YamlJson({super.key});

  @override
  State<YamlJson> createState() => _YamlJsonState();
}

class _YamlJsonState extends State<YamlJson>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();

  String? _errorKey;
  String? _errorDetail;
  bool _prettyPrint = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _inputController.clear();
        _outputController.clear();
        _errorKey = null;
        _errorDetail = null;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  bool get _isYamlToJson => _tabController.index == 0;

  dynamic _normalize(dynamic value) {
    if (value is YamlMap) {
      final Map<String, dynamic> result = <String, dynamic>{};
      value.nodes.forEach((dynamic k, dynamic v) {
        result[k.toString()] = _normalize(v is YamlNode ? v.value : v);
      });
      return result;
    }
    if (value is YamlList) {
      return value.nodes
          .map((dynamic v) => _normalize(v is YamlNode ? v.value : v))
          .toList();
    }
    if (value is YamlNode) return _normalize(value.value);
    if (value is Map) {
      final Map<String, dynamic> result = <String, dynamic>{};
      value.forEach((dynamic k, dynamic v) {
        result[k.toString()] = _normalize(v);
      });
      return result;
    }
    if (value is List) {
      return value.map(_normalize).toList();
    }
    return value;
  }

  void _convert() {
    final String input = _inputController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _outputController.text = '';
        _errorKey = 'yamljson_error_empty';
        _errorDetail = null;
      });
      return;
    }
    try {
      if (_isYamlToJson) {
        final dynamic yaml = loadYaml(input);
        final dynamic normalized = _normalize(yaml);
        final String result = _prettyPrint
            ? const JsonEncoder.withIndent('  ').convert(normalized)
            : json.encode(normalized);
        setState(() {
          _outputController.text = result;
          _errorKey = null;
          _errorDetail = null;
        });
      } else {
        final dynamic decoded = json.decode(input);
        // `YamlWriter()` const konstruktor deyil, ona görə `const` olmadan
        // çağırılmalıdır.
        final String result = YamlWriter().write(decoded);
        setState(() {
          _outputController.text = result.trimRight();
          _errorKey = null;
          _errorDetail = null;
        });
      }
    } catch (e) {
      setState(() {
        _outputController.text = '';
        _errorKey = _isYamlToJson
            ? 'yamljson_error_yaml'
            : 'yamljson_error_json';
        _errorDetail = e.toString();
      });
    }
  }

  void _clear() {
    setState(() {
      _inputController.clear();
      _outputController.clear();
      _errorKey = null;
      _errorDetail = null;
    });
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
      SnackBar(content: Text(context.t('yamljson_copied'))),
    );
  }

  void _swap() {
    final String tmp = _inputController.text;
    _inputController.text = _outputController.text;
    _outputController.text = tmp;
    _tabController.index = _tabController.index == 0 ? 1 : 0;
  }

  void _loadSample() {
    if (_isYamlToJson) {
      _inputController.text = '''version: "3.9"
services:
  web:
    image: nginx:latest
    ports:
      - "80:80"
      - "443:443"
    environment:
      NODE_ENV: production
      DEBUG: false''';
    } else {
      _inputController.text = '''{
  "version": "3.9",
  "services": {
    "web": {
      "image": "nginx:latest",
      "ports": ["80:80", "443:443"],
      "environment": {
        "NODE_ENV": "production",
        "DEBUG": false
      }
    }
  }
}''';
    }
    _convert();
  }

  /// Şüşə effektli (frosted glass) kart — arxa fonu bulanıqlaşdırır,
  /// üzərinə yarımşəffaf rəng və incə sərhəd qoyur.
  Widget _glassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color tint = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.white.withOpacity(0.55);
    final Color borderColor = isDark
        ? Colors.white.withOpacity(0.15)
        : Colors.white.withOpacity(0.6);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  InputDecoration _glassInputDecoration(bool isDark) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(isDark ? 0.06 : 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      isDense: true,
      contentPadding: const EdgeInsets.all(12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(context.t('yamljson_title')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: <Widget>[
            Tab(text: context.t('yamljson_tab_y2j')),
            Tab(text: context.t('yamljson_tab_j2y')),
          ],
        ),
        actions: <Widget>[
          IconButton(
            onPressed: _loadSample,
            icon: const Icon(Icons.auto_awesome),
            tooltip: context.t('yamljson_sample'),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? <Color>[
              const Color(0xFF1B1035),
              const Color(0xFF0F1C3F),
              const Color(0xFF091626),
            ]
                : <Color>[
              const Color(0xFFDCE9FF),
              const Color(0xFFE9E2FF),
              const Color(0xFFF3F6FF),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top > 0 ? 8 : 16,
              16,
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _glassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              _isYamlToJson
                                  ? context.t('yamljson_input_yaml')
                                  : context.t('yamljson_input_json'),
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
                        maxLines: 8,
                        minLines: 6,
                        style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        decoration: _glassInputDecoration(isDark),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _glassCard(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: FilledButton(
                          onPressed: _convert,
                          child: Text(context.t('yamljson_convert')),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_isYamlToJson)
                        FilterChip(
                          label: Text(context.t('yamljson_pretty')),
                          selected: _prettyPrint,
                          backgroundColor: Colors.white.withOpacity(
                            isDark ? 0.06 : 0.4,
                          ),
                          onSelected: (bool v) {
                            setState(() {
                              _prettyPrint = v;
                            });
                            if (_outputController.text.isNotEmpty) _convert();
                          },
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _swap,
                        icon: const Icon(Icons.swap_vert),
                        tooltip: context.t('yamljson_swap'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _glassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              _isYamlToJson
                                  ? context.t('yamljson_output_json')
                                  : context.t('yamljson_output_yaml'),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
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
                        maxLines: null,
                        minLines: 8,
                        style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        decoration: _glassInputDecoration(isDark),
                      ),
                    ],
                  ),
                ),
                if (_errorKey != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _glassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            context.t(_errorKey!),
                            style: TextStyle(color: colors.error),
                          ),
                          if (_errorDetail != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _errorDetail!,
                                style: TextStyle(
                                  color: colors.error,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}