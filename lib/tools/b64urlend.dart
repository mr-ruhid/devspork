import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class B64UrlEnd extends StatefulWidget {
  const B64UrlEnd({super.key});

  @override
  State<B64UrlEnd> createState() => _B64UrlEndState();
}

class _B64UrlEndState extends State<B64UrlEnd>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  String? _errorKey;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
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

  bool get _isBase64 => _tabController.index == 0;

  void _encode() {
    final String input = _inputController.text;
    try {
      final String result = _isBase64
          ? base64.encode(utf8.encode(input))
          : Uri.encodeComponent(input);
      setState(() {
        _outputController.text = result;
        _errorKey = null;
      });
    } catch (_) {
      setState(() {
        _outputController.text = '';
        _errorKey = 'b64url_error';
      });
    }
  }

  void _decode() {
    final String input = _inputController.text;
    try {
      final String result = _isBase64
          ? utf8.decode(base64.decode(input))
          : Uri.decodeComponent(input);
      setState(() {
        _outputController.text = result;
        _errorKey = null;
      });
    } catch (_) {
      setState(() {
        _outputController.text = '';
        _errorKey = 'b64url_error';
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

  Future<void> _copy() async {
    if (_outputController.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _outputController.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('b64url_copied'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('b64url_title')),
        bottom: TabBar(
          controller: _tabController,
          tabs: <Widget>[
            Tab(text: context.t('b64url_tab_base64')),
            Tab(text: context.t('b64url_tab_url')),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _inputController,
                expands: true,
                maxLines: null,
                minLines: null,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  labelText: context.t('b64url_input_hint'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton(
                    onPressed: _encode,
                    child: Text(context.t('b64url_encode')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _decode,
                    child: Text(context.t('b64url_decode')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_errorKey != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  context.t(_errorKey!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Expanded(
              child: TextField(
                controller: _outputController,
                readOnly: true,
                expands: true,
                maxLines: null,
                minLines: null,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  labelText: context.t('b64url_output_hint'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copy,
                    icon: const Icon(Icons.copy),
                    label: Text(context.t('b64url_copy')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clear,
                    icon: const Icon(Icons.clear),
                    label: Text(context.t('b64url_clear')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}