import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class BinView extends StatefulWidget {
  const BinView({super.key});

  @override
  State<BinView> createState() => _BinViewState();
}

class _BinViewState extends State<BinView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();

  String? _errorKey;
  bool _useSpaces = true;

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

  bool get _isTextToBin => _tabController.index == 0;

  String _textToBinary(String input) {
    final List<int> bytes = utf8.encode(input);
    final List<String> parts = bytes
        .map((int b) => b.toRadixString(2).padLeft(8, '0'))
        .toList();
    return _useSpaces ? parts.join(' ') : parts.join();
  }

  String _binaryToText(String input) {
    String cleaned = input.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.isEmpty) return '';
    if (!RegExp(r'^[01]+$').hasMatch(cleaned)) {
      throw Exception('invalid');
    }
    if (cleaned.length % 8 != 0) {
      throw Exception('length');
    }
    final List<int> bytes = <int>[];
    for (int i = 0; i < cleaned.length; i += 8) {
      bytes.add(int.parse(cleaned.substring(i, i + 8), radix: 2));
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

  void _convert() {
    final String input = _inputController.text;
    if (input.isEmpty) {
      setState(() {
        _outputController.text = '';
        _errorKey = null;
      });
      return;
    }
    try {
      if (_isTextToBin) {
        final String result = _textToBinary(input);
        setState(() {
          _outputController.text = result;
          _errorKey = null;
        });
      } else {
        final String result = _binaryToText(input);
        setState(() {
          _outputController.text = result;
          _errorKey = null;
        });
      }
    } catch (e) {
      final String msg = e.toString();
      setState(() {
        _outputController.text = '';
        if (msg.contains('length')) {
          _errorKey = 'binview_error_length';
        } else {
          _errorKey = 'binview_error_invalid';
        }
      });
    }
  }

  void _clear() {
    setState(() {
      _inputController.clear();
      _outputController.clear();
      _errorKey = null;
    });
  }

  Future<void> _paste() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null) return;
    _inputController.text = data.text!;
    _convert();
  }

  Future<void> _copy() async {
    if (_outputController.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _outputController.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('binview_copied'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('binview_title')),
        bottom: TabBar(
          controller: _tabController,
          tabs: <Widget>[
            Tab(text: context.t('binview_tab_t2b')),
            Tab(text: context.t('binview_tab_b2t')),
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
                    _isTextToBin
                        ? context.t('binview_input_text')
                        : context.t('binview_input_binary'),
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
            if (_isTextToBin)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(context.t('binview_spaces')),
                value: _useSpaces,
                onChanged: (bool v) {
                  setState(() {
                    _useSpaces = v;
                  });
                  if (_outputController.text.isNotEmpty) _convert();
                },
              ),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton(
                    onPressed: _convert,
                    child: Text(context.t('binview_convert')),
                  ),
                ),
              ],
            ),
            if (_errorKey != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  context.t(_errorKey!),
                  style: TextStyle(color: colors.error),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _isTextToBin
                        ? context.t('binview_output_binary')
                        : context.t('binview_output_text'),
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
              minLines: 6,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}