
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'hmac_engine.dart';
import 'models.dart';
import 'ui_kit.dart';

class HmacTab extends StatefulWidget {
  const HmacTab({super.key});

  @override
  State<HmacTab> createState() => _HmacTabState();
}

class _HmacTabState extends State<HmacTab> {
  final TextEditingController _messageCtrl = TextEditingController();
  final TextEditingController _keyCtrl = TextEditingController();
  final TextEditingController _expectedCtrl = TextEditingController();

  HmacAlgorithm _algo = HmacAlgorithm.sha256;
  KeyFormat _keyFormat = KeyFormat.hex;
  bool _showKey = false;
  bool _showHexGrouped = false;

  HmacOutput? _output;
  String? _errorKey;
  String? _errorDetail;

  HmacVerifyResult? _verifyResult;

  Timer? _debounce;
  bool _copiedHex = false;
  bool _copiedB64 = false;

  @override
  void initState() {
    super.initState();
    _messageCtrl.addListener(_scheduleCompute);
    _keyCtrl.addListener(_scheduleCompute);
    _expectedCtrl.addListener(_onExpectedChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _messageCtrl.removeListener(_scheduleCompute);
    _keyCtrl.removeListener(_scheduleCompute);
    _expectedCtrl.removeListener(_onExpectedChanged);
    _messageCtrl.dispose();
    _keyCtrl.dispose();
    _expectedCtrl.dispose();
    super.dispose();
  }

  void _scheduleCompute() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), _compute);
  }

  void _onExpectedChanged() {
    if (_verifyResult != null) {
      setState(() => _verifyResult = null);
    }
  }

  void _compute() {
    final String message = _messageCtrl.text;
    final String key = _keyCtrl.text;

    if (message.isEmpty || key.isEmpty) {
      if (_output != null || _errorKey != null) {
        setState(() {
          _output = null;
          _errorKey = null;
          _errorDetail = null;
          _verifyResult = null;
        });
      }
      return;
    }

    try {
      final HmacOutput out = HmacEngine.compute(
        message: message,
        key: key,
        keyFormat: _keyFormat,
        algorithm: _algo,
      );
      setState(() {
        _output = out;
        _errorKey = null;
        _errorDetail = null;
      });
    } on HmacException catch (e) {
      setState(() {
        _output = null;
        _errorKey = e.errorKey;
        _errorDetail = e.detail;
      });
    } catch (e) {
      setState(() {
        _output = null;
        _errorKey = CryptoToolkitErrors.hmacInvalidKey;
        _errorDetail = e.toString();
      });
    }
  }

  void _verify() {
    final String expected = _expectedCtrl.text.trim();
    if (expected.isEmpty || _output == null) return;

    final HmacVerifyResult r = HmacEngine.verify(
      expected: expected,
      actual: _output!,
    );
    setState(() => _verifyResult = r);
    HapticFeedback.lightImpact();
  }

  void _randomKey() {
    final String key = HmacEngine.generateRandomKey(
      bytes: 32,
      format: _keyFormat,
    );
    HapticFeedback.selectionClick();
    setState(() => _keyCtrl.text = key);
  }

  void _clearKey() {
    HapticFeedback.selectionClick();
    setState(() {
      _keyCtrl.clear();
      _showKey = false;
    });
  }

  void _clearAll() {
    HapticFeedback.mediumImpact();
    _messageCtrl.clear();
    _keyCtrl.clear();
    _expectedCtrl.clear();
    setState(() {
      _output = null;
      _errorKey = null;
      _errorDetail = null;
      _verifyResult = null;
      _showKey = false;
    });
  }

  Future<void> _copy(String text, {required bool isHex}) async {
    await ctkCopy(context, text);
    if (!mounted) return;
    setState(() {
      if (isHex) {
        _copiedHex = true;
      } else {
        _copiedB64 = true;
      }
    });
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _copiedHex = false;
          _copiedB64 = false;
        });
      }
    });
  }

  String get _hexDisplay {
    final HmacOutput? out = _output;
    if (out == null) return '';
    if (!_showHexGrouped) return out.hex;
    return HmacEngine.formatHex(out.hex);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildAlgorithmCard(),
          const SizedBox(height: 14),
          _buildMessageCard(),
          const SizedBox(height: 14),
          _buildKeyCard(),
          if (_errorKey != null) ...<Widget>[
            const SizedBox(height: 14),
            GlassErrorBox(
              errorKey: _errorKey!,
              detail: _errorDetail,
            ),
          ],
          const SizedBox(height: 14),
          _buildOutputCard(),
          const SizedBox(height: 14),
          _buildVerifyCard(),
          if (_verifyResult != null) ...<Widget>[
            const SizedBox(height: 14),
            _buildVerifyResultCard(_verifyResult!),
          ],
        ],
      ),
    );
  }

  Widget _buildAlgorithmCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GlassSectionTitle(
            Icons.functions_rounded,
            ctkTr(context, 'ctk_hmac_algorithm', 'Algorithm'),
          ),
          const SizedBox(height: 10),
          GlassChipPicker<HmacAlgorithm>(
            values: HmacAlgorithm.values,
            current: _algo,
            labelOf: (HmacAlgorithm v) => v.display,
            onChanged: (HmacAlgorithm v) {
              setState(() => _algo = v);
              _compute();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: GlassSectionTitle(
                  Icons.message_outlined,
                  ctkTr(context, 'ctk_hmac_message', 'Message'),
                ),
              ),
              GlassIconButton(
                icon: Icons.content_paste_rounded,
                tooltip: ctkTr(context, 'ctk_paste', 'Paste'),
                onTap: () => ctkPaste(context, _messageCtrl),
              ),
              const SizedBox(width: 6),
              GlassIconButton(
                icon: Icons.close_rounded,
                tooltip: ctkTr(context, 'ctk_clear', 'Clear'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  _messageCtrl.clear();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          GlassTextField(
            controller: _messageCtrl,
            hint: ctkTr(
              context,
              'ctk_hmac_message_hint',
              'Type or paste the message…',
            ),
            maxLines: 5,
            minLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildKeyCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: GlassSectionTitle(
                  Icons.vpn_key_outlined,
                  ctkTr(context, 'ctk_hmac_key', 'Secret key'),
                ),
              ),
              GlassIconButton(
                icon: Icons.casino_outlined,
                tooltip: ctkTr(context, 'ctk_random_key', 'Random key'),
                onTap: _randomKey,
              ),
              const SizedBox(width: 6),
              GlassIconButton(
                icon: _showKey
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                tooltip: _showKey
                    ? ctkTr(context, 'ctk_hide', 'Hide')
                    : ctkTr(context, 'ctk_show', 'Show'),
                onTap: () => setState(() => _showKey = !_showKey),
              ),
              const SizedBox(width: 6),
              GlassIconButton(
                icon: Icons.content_paste_rounded,
                tooltip: ctkTr(context, 'ctk_paste', 'Paste'),
                onTap: () => ctkPaste(context, _keyCtrl),
              ),
              const SizedBox(width: 6),
              GlassIconButton(
                icon: Icons.close_rounded,
                tooltip: ctkTr(context, 'ctk_clear', 'Clear'),
                onTap: _clearKey,
              ),
            ],
          ),
          const SizedBox(height: 8),
          GlassTextField(
            controller: _keyCtrl,
            hint: _keyHintFor(_keyFormat),
            obscure: !_showKey,
            maxLines: 3,
            minLines: 1,
          ),
          const SizedBox(height: 10),
          GlassChipPicker<KeyFormat>(
            label: ctkTr(context, 'ctk_hmac_key_format', 'Key format'),
            values: KeyFormat.values,
            current: _keyFormat,
            labelOf: (KeyFormat v) => v.display,
            onChanged: (KeyFormat v) {
              setState(() => _keyFormat = v);
              _compute();
            },
          ),
        ],
      ),
    );
  }

  String _keyHintFor(KeyFormat f) {
    switch (f) {
      case KeyFormat.hex:
        return 'deadbeef0123…';
      case KeyFormat.base64:
        return 'SGVsbG8gd29ybGQ=';
      case KeyFormat.text:
        return ctkTr(context, 'ctk_hmac_key_hint', 'Enter secret key…');
    }
  }

  Widget _buildOutputCard() {
    final HmacOutput? out = _output;
    if (out == null) {
      return GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            GlassSectionTitle(
              Icons.check_circle_outline_rounded,
              ctkTr(context, 'ctk_hmac_output', 'HMAC output'),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Text(
                ctkTr(
                  context,
                  'ctk_hmac_output_empty',
                  'Enter message and key to compute HMAC.',
                ),
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: GlassSectionTitle(
                  Icons.check_circle_outline_rounded,
                  ctkTr(context, 'ctk_hmac_output', 'HMAC output'),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: CtkColors.accentB.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${out.bitLength} bit',
                  style: const TextStyle(
                    color: CtkColors.accentB,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              const Text(
                'HEX',
                style: TextStyle(
                  color: CtkColors.accentB,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => setState(
                      () => _showHexGrouped = !_showHexGrouped,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _showHexGrouped
                        ? CtkColors.accentB.withOpacity(0.2)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _showHexGrouped
                          ? CtkColors.accentB.withOpacity(0.5)
                          : Colors.white.withOpacity(0.15),
                    ),
                  ),
                  child: Text(
                    ctkTr(context, 'ctk_hmac_grouped', 'grouped'),
                    style: TextStyle(
                      color: _showHexGrouped
                          ? CtkColors.accentB
                          : Colors.white54,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              GlassIconButton(
                icon: _copiedHex
                    ? Icons.check_rounded
                    : Icons.copy_rounded,
                tooltip: _copiedHex
                    ? ctkTr(context, 'ctk_copied', 'Copied')
                    : ctkTr(context, 'ctk_copy', 'Copy'),
                onTap: () => _copy(out.hex, isHex: true),
                highlighted: _copiedHex,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: SelectableText(
              _hexDisplay,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          GlassOutputBlock(
            label: 'BASE64',
            value: out.base64,
            copied: _copiedB64,
            onCopy: () => _copy(out.base64, isHex: false),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyCard() {
    final bool canVerify = _output != null;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: GlassSectionTitle(
                  Icons.verified_user_outlined,
                  ctkTr(context, 'ctk_hmac_verify_title', 'Verify HMAC'),
                ),
              ),
              GlassIconButton(
                icon: Icons.content_paste_rounded,
                tooltip: ctkTr(context, 'ctk_paste', 'Paste'),
                onTap: () => ctkPaste(context, _expectedCtrl),
              ),
              const SizedBox(width: 6),
              GlassIconButton(
                icon: Icons.close_rounded,
                tooltip: ctkTr(context, 'ctk_clear', 'Clear'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _expectedCtrl.clear();
                    _verifyResult = null;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ctkTr(
              context,
              'ctk_hmac_verify_desc',
              'Constant-time comparison against an expected hex signature.',
            ),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          GlassTextField(
            controller: _expectedCtrl,
            hint: 'a1b2c3d4…',
            maxLines: 3,
            minLines: 2,
          ),
          const SizedBox(height: 12),
          GlassPrimaryButton(
            icon: Icons.compare_arrows_rounded,
            label: ctkTr(context, 'ctk_hmac_verify_action', 'Verify'),
            onTap: canVerify ? _verify : null,
          ),
          if (!canVerify) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              ctkTr(
                context,
                'ctk_hmac_verify_no_hash',
                'Compute an HMAC first to enable verification.',
              ),
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVerifyResultCard(HmacVerifyResult r) {
    final Color color =
    r.matches ? CtkColors.success : CtkColors.danger;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                r.matches
                    ? Icons.verified_rounded
                    : Icons.gpp_bad_rounded,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  r.matches
                      ? ctkTr(context, 'ctk_hmac_verify_ok', 'HMAC matches')
                      : ctkTr(context, 'ctk_hmac_verify_fail',
                      'HMAC does not match'),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _verifyRow(
            ctkTr(context, 'ctk_hmac_expected', 'Expected'),
            r.expected,
          ),
          const SizedBox(height: 6),
          _verifyRow(
            ctkTr(context, 'ctk_hmac_actual', 'Actual'),
            r.actual,
          ),
        ],
      ),
    );
  }

  Widget _verifyRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: SelectableText(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}