import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class JsonFmt extends StatefulWidget {
  const JsonFmt({super.key});

  @override
  State<JsonFmt> createState() => _JsonFmtState();
}

class _JsonFmtState extends State<JsonFmt> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  String? _errorKey;
  String? _errorDetail;
  bool _isValid = false;

  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  void _format() {
    final String input = _inputController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _errorKey = 'jsonfmt_error_empty';
        _errorDetail = null;
        _isValid = false;
        _outputController.text = '';
      });
      return;
    }
    try {
      final dynamic decoded = json.decode(input);
      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      setState(() {
        _outputController.text = encoder.convert(decoded);
        _errorKey = null;
        _errorDetail = null;
        _isValid = true;
      });
    } catch (e) {
      setState(() {
        _outputController.text = '';
        _errorKey = 'jsonfmt_error_invalid';
        _errorDetail = e.toString();
        _isValid = false;
      });
    }
  }

  void _minify() {
    final String input = _inputController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _errorKey = 'jsonfmt_error_empty';
        _errorDetail = null;
        _isValid = false;
        _outputController.text = '';
      });
      return;
    }
    try {
      final dynamic decoded = json.decode(input);
      setState(() {
        _outputController.text = json.encode(decoded);
        _errorKey = null;
        _errorDetail = null;
        _isValid = true;
      });
    } catch (e) {
      setState(() {
        _outputController.text = '';
        _errorKey = 'jsonfmt_error_invalid';
        _errorDetail = e.toString();
        _isValid = false;
      });
    }
  }

  void _validate() {
    final String input = _inputController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _errorKey = 'jsonfmt_error_empty';
        _errorDetail = null;
        _isValid = false;
      });
      return;
    }
    try {
      json.decode(input);
      setState(() {
        _errorKey = null;
        _errorDetail = null;
        _isValid = true;
      });
    } catch (e) {
      setState(() {
        _errorKey = 'jsonfmt_error_invalid';
        _errorDetail = e.toString();
        _isValid = false;
      });
    }
  }

  void _clear() {
    setState(() {
      _inputController.clear();
      _outputController.clear();
      _errorKey = null;
      _errorDetail = null;
      _isValid = false;
    });
  }

  Future<void> _copy() async {
    if (_outputController.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _outputController.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('jsonfmt_copied'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('jsonfmt_title')),
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
                  labelText: context.t('jsonfmt_input_hint'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton(
                    onPressed: _format,
                    child: Text(context.t('jsonfmt_format')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _minify,
                    child: Text(context.t('jsonfmt_minify')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _validate,
                    child: Text(context.t('jsonfmt_validate')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_errorKey != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
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
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            if (_errorKey == null && _isValid)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  context.t('jsonfmt_valid'),
                  style: const TextStyle(color: Colors.green),
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
                  labelText: context.t('jsonfmt_output_hint'),
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
                    label: Text(context.t('jsonfmt_copy')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clear,
                    icon: const Icon(Icons.clear),
                    label: Text(context.t('jsonfmt_clear')),
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