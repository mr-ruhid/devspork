import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class BaseConv extends StatefulWidget {
  const BaseConv({super.key});

  @override
  State<BaseConv> createState() => _BaseConvState();
}

class _BaseConvState extends State<BaseConv> {
  final TextEditingController _binController = TextEditingController();
  final TextEditingController _octController = TextEditingController();
  final TextEditingController _decController = TextEditingController();
  final TextEditingController _hexController = TextEditingController();

  int _activeBase = 10;
  String? _errorKey;

  @override
  void initState() {
    super.initState();
    _binController.addListener(() => _onChanged(_binController.text, 2));
    _octController.addListener(() => _onChanged(_octController.text, 8));
    _decController.addListener(() => _onChanged(_decController.text, 10));
    _hexController.addListener(() => _onChanged(_hexController.text, 16));
  }

  @override
  void dispose() {
    _binController.dispose();
    _octController.dispose();
    _decController.dispose();
    _hexController.dispose();
    super.dispose();
  }

  void _onChanged(String value, int base) {
    if (_activeBase != base) return;
    final String input = value.trim();
    if (input.isEmpty) {
      setState(() {
        _errorKey = null;
        _clearExcept(base);
      });
      return;
    }
    final BigInt? big = BigInt.tryParse(input, radix: base);
    if (big == null) {
      setState(() {
        _errorKey = 'baseconv_error_invalid';
      });
      return;
    }
    if (big.isNegative) {
      setState(() {
        _errorKey = 'baseconv_error_negative';
      });
      return;
    }
    setState(() {
      _errorKey = null;
      _setFieldsFromBig(big, base);
    });
  }

  void _setFieldsFromBig(BigInt value, int sourceBase) {
    _activeBase = 0;
    if (sourceBase != 2) {
      _binController.text = value.toRadixString(2);
    }
    if (sourceBase != 8) {
      _octController.text = value.toRadixString(8);
    }
    if (sourceBase != 10) {
      _decController.text = value.toRadixString(10);
    }
    if (sourceBase != 16) {
      _hexController.text = value.toRadixString(16).toUpperCase();
    }
    _activeBase = sourceBase;
  }

  void _clearExcept(int base) {
    _activeBase = 0;
    if (base != 2) _binController.clear();
    if (base != 8) _octController.clear();
    if (base != 10) _decController.clear();
    if (base != 16) _hexController.clear();
    _activeBase = base;
  }

  Future<void> _copy(String text) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('baseconv_copied'))),
    );
  }

  Widget _field({
    required String labelKey,
    required TextEditingController controller,
    required TextInputType keyboard,
    required List<TextInputFormatter> formatters,
    required int base,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        inputFormatters: formatters,
        onTap: () {
          _activeBase = base;
        },
        decoration: InputDecoration(
          labelText: context.t(labelKey),
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            onPressed: () => _copy(controller.text),
            icon: const Icon(Icons.copy),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('baseconv_title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _field(
              labelKey: 'baseconv_binary',
              controller: _binController,
              keyboard: TextInputType.number,
              base: 2,
              formatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[01]')),
              ],
            ),
            _field(
              labelKey: 'baseconv_octal',
              controller: _octController,
              keyboard: TextInputType.number,
              base: 8,
              formatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-7]')),
              ],
            ),
            _field(
              labelKey: 'baseconv_decimal',
              controller: _decController,
              keyboard: TextInputType.number,
              base: 10,
              formatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            _field(
              labelKey: 'baseconv_hex',
              controller: _hexController,
              keyboard: TextInputType.text,
              base: 16,
              formatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
              ],
            ),
            if (_errorKey != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  context.t(_errorKey!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                _activeBase = 0;
                _binController.clear();
                _octController.clear();
                _decController.clear();
                _hexController.clear();
                _activeBase = 10;
                setState(() {
                  _errorKey = null;
                });
              },
              icon: const Icon(Icons.clear),
              label: Text(context.t('baseconv_clear')),
            ),
          ],
        ),
      ),
    );
  }
}