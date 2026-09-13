import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class JwtDec extends StatefulWidget {
  const JwtDec({super.key});

  @override
  State<JwtDec> createState() => _JwtDecState();
}

class _JwtDecState extends State<JwtDec> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _headerController = TextEditingController();
  final TextEditingController _payloadController = TextEditingController();
  final TextEditingController _signatureController = TextEditingController();

  String? _errorKey;
  String? _errorDetail;
  bool _isExpired = false;
  bool _hasExp = false;
  int? _expEpoch;
  int? _iatEpoch;
  int? _nbfEpoch;

  @override
  void dispose() {
    _inputController.dispose();
    _headerController.dispose();
    _payloadController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  String _normalizeBase64(String input) {
    String out = input.replaceAll('-', '+').replaceAll('_', '/');
    final int pad = out.length % 4;
    if (pad == 2) {
      out += '==';
    } else if (pad == 3) {
      out += '=';
    } else if (pad == 1) {
      out += '===';
    }
    return out;
  }

  String _decodePart(String part) {
    final String normalized = _normalizeBase64(part);
    final List<int> bytes = base64.decode(normalized);
    final String text = utf8.decode(bytes);
    final dynamic decoded = json.decode(text);
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(decoded);
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _formatEpoch(int epoch) {
    final DateTime dt = DateTime.fromMillisecondsSinceEpoch(
      epoch * 1000,
    ).toLocal();
    return '${dt.year}-${_two(dt.month)}-${_two(dt.day)} '
        '${_two(dt.hour)}:${_two(dt.minute)}:${_two(dt.second)}';
  }

  void _decode() {
    final String token = _inputController.text.trim();
    _headerController.text = '';
    _payloadController.text = '';
    _signatureController.text = '';
    _isExpired = false;
    _hasExp = false;
    _expEpoch = null;
    _iatEpoch = null;
    _nbfEpoch = null;

    if (token.isEmpty) {
      setState(() {
        _errorKey = 'jwtdec_error_empty';
        _errorDetail = null;
      });
      return;
    }

    final List<String> parts = token.split('.');
    if (parts.length != 3) {
      setState(() {
        _errorKey = 'jwtdec_error_parts';
        _errorDetail = null;
      });
      return;
    }

    try {
      final String header = _decodePart(parts[0]);
      final String payload = _decodePart(parts[1]);

      _headerController.text = header;
      _payloadController.text = payload;
      _signatureController.text = parts[2];

      try {
        final Map<String, dynamic> payloadMap =
        json.decode(utf8.decode(base64.decode(_normalizeBase64(parts[1]))))
        as Map<String, dynamic>;
        if (payloadMap['exp'] is int) {
          _expEpoch = payloadMap['exp'] as int;
          _hasExp = true;
          final int now =
              DateTime.now().millisecondsSinceEpoch ~/ 1000;
          _isExpired = now > _expEpoch!;
        }
        if (payloadMap['iat'] is int) {
          _iatEpoch = payloadMap['iat'] as int;
        }
        if (payloadMap['nbf'] is int) {
          _nbfEpoch = payloadMap['nbf'] as int;
        }
      } catch (_) {}

      setState(() {
        _errorKey = null;
        _errorDetail = null;
      });
    } catch (e) {
      setState(() {
        _errorKey = 'jwtdec_error_invalid';
        _errorDetail = e.toString();
      });
    }
  }

  void _clear() {
    setState(() {
      _inputController.clear();
      _headerController.clear();
      _payloadController.clear();
      _signatureController.clear();
      _errorKey = null;
      _errorDetail = null;
      _isExpired = false;
      _hasExp = false;
      _expEpoch = null;
      _iatEpoch = null;
      _nbfEpoch = null;
    });
  }

  Future<void> _copy(String text) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('jwtdec_copied'))),
    );
  }

  Widget _resultField(String labelKey, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        readOnly: true,
        maxLines: null,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        decoration: InputDecoration(
          labelText: context.t(labelKey),
          border: const OutlineInputBorder(),
          alignLabelWithHint: true,
          suffixIcon: IconButton(
            onPressed: () => _copy(controller.text),
            icon: const Icon(Icons.copy),
          ),
        ),
      ),
    );
  }

  Widget _infoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('jwtdec_title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _inputController,
              maxLines: 4,
              minLines: 3,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: InputDecoration(
                labelText: context.t('jwtdec_input_hint'),
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton(
                    onPressed: _decode,
                    child: Text(context.t('jwtdec_decode')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clear,
                    icon: const Icon(Icons.clear),
                    label: Text(context.t('jwtdec_clear')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_errorKey != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
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
            if (_hasExp)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _infoChip(
                      context.t('jwtdec_status'),
                      _isExpired
                          ? context.t('jwtdec_expired')
                          : context.t('jwtdec_valid'),
                      _isExpired ? colors.error : Colors.green,
                    ),
                    if (_expEpoch != null)
                      _infoChip(
                        'exp',
                        _formatEpoch(_expEpoch!),
                        colors.primary,
                      ),
                    if (_iatEpoch != null)
                      _infoChip(
                        'iat',
                        _formatEpoch(_iatEpoch!),
                        colors.primary,
                      ),
                    if (_nbfEpoch != null)
                      _infoChip(
                        'nbf',
                        _formatEpoch(_nbfEpoch!),
                        colors.primary,
                      ),
                  ],
                ),
              ),
            _resultField('jwtdec_header', _headerController),
            _resultField('jwtdec_payload', _payloadController),
            _resultField('jwtdec_signature', _signatureController),
          ],
        ),
      ),
    );
  }
}