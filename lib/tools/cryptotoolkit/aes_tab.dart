import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'aes_engine.dart';
import 'models.dart';
import 'ui_kit.dart';

class AesTab extends StatefulWidget {
  const AesTab({super.key});

  @override
  State<AesTab> createState() => _AesTabState();
}

class _AesTabState extends State<AesTab> {
  final TextEditingController _plainCtrl = TextEditingController();
  final TextEditingController _cipherCtrl = TextEditingController();
  final TextEditingController _keyCtrl = TextEditingController();
  final TextEditingController _ivCtrl = TextEditingController();

  AesMode _mode = AesMode.gcm;
  AesKeySize _keySize = AesKeySize.bits256;
  AesOperation _op = AesOperation.encrypt;

  bool _showKey = false;
  bool _useCombined = false;

  AesEncryptedResult? _encResult;
  AesDecryptedResult? _decResult;
  String? _errorKey;
  String? _errorDetail;

  bool _copiedCipher = false;
  bool _copiedKey = false;
  bool _copiedIv = false;
  bool _copiedPlain = false;
  bool _copiedCombined = false;

  @override
  void initState() {
    super.initState();
    _plainCtrl.addListener(_invalidate);
    _cipherCtrl.addListener(_invalidate);
    _keyCtrl.addListener(_invalidate);
    _ivCtrl.addListener(_invalidate);
  }

  @override
  void dispose() {
    _plainCtrl.dispose();
    _cipherCtrl.dispose();
    _keyCtrl.dispose();
    _ivCtrl.dispose();
    super.dispose();
  }

  void _invalidate() {
    if (_encResult != null || _decResult != null || _errorKey != null) {
      setState(() {
        _encResult = null;
        _decResult = null;
        _errorKey = null;
        _errorDetail = null;
      });
    }
  }

  void _changeMode(AesMode m) {
    if (_mode == m) return;
    setState(() {
      _mode = m;
      _encResult = null;
      _decResult = null;
      _errorKey = null;
      _errorDetail = null;
      _useCombined = false;
      if (m == AesMode.gcm && _ivCtrl.text.length > 24) {
        _ivCtrl.clear();
      }
    });
  }

  void _changeKeySize(AesKeySize s) {
    if (_keySize == s) return;
    setState(() {
      _keySize = s;
      _encResult = null;
      _decResult = null;
      _errorKey = null;
      _errorDetail = null;
      _keyCtrl.clear();
    });
  }

  void _generateKey() {
    HapticFeedback.selectionClick();
    setState(() {
      _keyCtrl.text = AesEngine.generateRandomKeyHex(_keySize);
      _showKey = true;
    });
  }

  void _generateIv() {
    HapticFeedback.selectionClick();
    setState(() {
      _ivCtrl.text = AesEngine.generateRandomIvHex(_mode);
    });
  }

  Uint8List _parseKey() {
    return AesEngine.parseKeyInput(_keyCtrl.text, _keySize);
  }

  Uint8List _parseIv() {
    return AesEngine.parseIvInput(_ivCtrl.text, _mode);
  }

  void _encrypt() {
    FocusScope.of(context).unfocus();
    try {
      final Uint8List key = _parseKey();
      final Uint8List iv = _parseIv();
      final AesEncryptedResult r = AesEngine.encrypt(
        plaintext: _plainCtrl.text,
        keyBytes: key,
        ivBytes: iv,
        mode: _mode,
      );
      setState(() {
        _encResult = r;
        _decResult = null;
        _errorKey = null;
        _errorDetail = null;
      });
      HapticFeedback.lightImpact();
    } on AesException catch (e) {
      setState(() {
        _encResult = null;
        _decResult = null;
        _errorKey = e.errorKey;
        _errorDetail = e.detail;
      });
    } catch (e) {
      setState(() {
        _encResult = null;
        _decResult = null;
        _errorKey = CryptoToolkitErrors.aesInvalidKey;
        _errorDetail = e.toString();
      });
    }
  }

  void _decrypt() {
    FocusScope.of(context).unfocus();
    try {
      final Uint8List key = _parseKey();

      Uint8List iv;
      String cipherText;

      if (_useCombined) {
        final (Uint8List parsedIv, Uint8List _) =
        AesEngine.parseCombined(_cipherCtrl.text, _mode);
        iv = parsedIv;
        cipherText = _cipherCtrl.text;
        if (_useCombined) {
          final (Uint8List pIv, Uint8List pCt) =
          AesEngine.parseCombined(_cipherCtrl.text, _mode);
          iv = pIv;
          cipherText = base64Encode(pCt);
        }
      } else {
        iv = _parseIv();
        cipherText = _cipherCtrl.text;
      }

      final AesDecryptedResult r = AesEngine.decrypt(
        cipherBase64: cipherText,
        keyBytes: key,
        ivBytes: iv,
        mode: _mode,
      );
      setState(() {
        _decResult = r;
        _encResult = null;
        _errorKey = null;
        _errorDetail = null;
      });
      HapticFeedback.lightImpact();
    } on AesException catch (e) {
      setState(() {
        _decResult = null;
        _encResult = null;
        _errorKey = e.errorKey;
        _errorDetail = e.detail;
      });
    } catch (e) {
      setState(() {
        _decResult = null;
        _encResult = null;
        _errorKey = CryptoToolkitErrors.aesDecryptFailed;
        _errorDetail = e.toString();
      });
    }
  }

  void _clearAll() {
    HapticFeedback.mediumImpact();
    _plainCtrl.clear();
    _cipherCtrl.clear();
    _keyCtrl.clear();
    _ivCtrl.clear();
    setState(() {
      _encResult = null;
      _decResult = null;
      _errorKey = null;
      _errorDetail = null;
      _useCombined = false;
    });
  }

  Future<void> _copy(String text, String flag) async {
    if (text.isEmpty) return;
    await ctkCopy(context, text);
    if (!mounted) return;
    setState(() {
      switch (flag) {
        case 'cipher':
          _copiedCipher = true;
          break;
        case 'key':
          _copiedKey = true;
          break;
        case 'iv':
          _copiedIv = true;
          break;
        case 'plain':
          _copiedPlain = true;
          break;
        case 'combined':
          _copiedCombined = true;
          break;
      }
    });
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        switch (flag) {
          case 'cipher':
            _copiedCipher = false;
            break;
          case 'key':
            _copiedKey = false;
            break;
          case 'iv':
            _copiedIv = false;
            break;
          case 'plain':
            _copiedPlain = false;
            break;
          case 'combined':
            _copiedCombined = false;
            break;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildOperationCard(),
          const SizedBox(height: 14),
          _buildKeyCard(),
          const SizedBox(height: 14),
          if (!_useCombined || _op == AesOperation.encrypt)
            _buildIvCard(),
          if (!_useCombined || _op == AesOperation.encrypt)
            const SizedBox(height: 14),
          if (_op == AesOperation.encrypt)
            _buildPlainCard()
          else
            _buildCipherCard(),
          if (_errorKey != null) ...<Widget>[
            const SizedBox(height: 14),
            GlassErrorBox(errorKey: _errorKey!, detail: _errorDetail),
          ],
          const SizedBox(height: 14),
          if (_op == AesOperation.encrypt)
            GlassPrimaryButton(
              icon: Icons.lock_rounded,
              label: ctkTr(context, 'ctk_aes_encrypt', 'Encrypt'),
              onTap: _encrypt,
            )
          else
            GlassPrimaryButton(
              icon: Icons.lock_open_rounded,
              label: ctkTr(context, 'ctk_aes_decrypt', 'Decrypt'),
              onTap: _decrypt,
            ),
          if (_encResult != null) ...<Widget>[
            const SizedBox(height: 14),
            _buildEncryptResultCard(_encResult!),
          ],
          if (_decResult != null) ...<Widget>[
            const SizedBox(height: 14),
            _buildDecryptResultCard(_decResult!),
          ],
        ],
      ),
    );
  }

  Widget _buildOperationCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: GlassSectionTitle(
                  Icons.shield_outlined,
                  ctkTr(context, 'ctk_aes_operation', 'Operation'),
                ),
              ),
              GlassIconButton(
                icon: Icons.refresh_rounded,
                tooltip: ctkTr(context, 'ctk_reset', 'Reset'),
                onTap: _clearAll,
              ),
            ],
          ),
          const SizedBox(height: 10),
          GlassChipPicker<AesOperation>(
            values: AesOperation.values,
            current: _op,
            labelOf: (AesOperation v) => v == AesOperation.encrypt
                ? ctkTr(context, 'ctk_aes_op_encrypt', 'Encrypt')
                : ctkTr(context, 'ctk_aes_op_decrypt', 'Decrypt'),
            onChanged: (AesOperation v) {
              setState(() {
                _op = v;
                _encResult = null;
                _decResult = null;
                _errorKey = null;
                _errorDetail = null;
              });
            },
          ),
          const SizedBox(height: 14),
          GlassSectionTitle(
            Icons.swap_horiz_rounded,
            ctkTr(context, 'ctk_aes_mode', 'Mode'),
          ),
          const SizedBox(height: 10),
          GlassChipPicker<AesMode>(
            values: AesMode.values,
            current: _mode,
            labelOf: (AesMode v) => v.display,
            onChanged: _changeMode,
          ),
          const SizedBox(height: 10),
          Text(
            _mode == AesMode.gcm
                ? ctkTr(
              context,
              'ctk_aes_mode_gcm_desc',
              'GCM: authenticated encryption. Detects tampering. 12-byte nonce.',
            )
                : ctkTr(
              context,
              'ctk_aes_mode_cbc_desc',
              'CBC: classic mode. No integrity check. 16-byte IV.',
            ),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          GlassSectionTitle(
            Icons.vpn_key_rounded,
            ctkTr(context, 'ctk_aes_key_size', 'Key size'),
          ),
          const SizedBox(height: 10),
          GlassChipPicker<AesKeySize>(
            values: AesKeySize.values,
            current: _keySize,
            labelOf: (AesKeySize v) => v.display,
            onChanged: _changeKeySize,
          ),
          const SizedBox(height: 10),
          Text(
            ctkTr(
              context,
              'ctk_aes_key_format_hint',
              'Key accepts hex / base64 / UTF-8 text matching the exact byte length.',
            ),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              height: 1.4,
            ),
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
                  Icons.key_rounded,
                  ctkTr(context, 'ctk_aes_key', 'Key'),
                ),
              ),
              GlassIconButton(
                icon: Icons.casino_outlined,
                tooltip: ctkTr(context, 'ctk_aes_gen_key', 'Random key'),
                onTap: _generateKey,
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
                onTap: () {
                  HapticFeedback.selectionClick();
                  _keyCtrl.clear();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          GlassTextField(
            controller: _keyCtrl,
            hint: '${_keySize.bytes} bytes / ${_keySize.bytes * 2} hex chars',
            obscure: !_showKey,
            maxLines: 3,
            minLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildIvCard() {
    final int ivLen = AesEngine.ivLengthFor(_mode);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: GlassSectionTitle(
                  Icons.tag_rounded,
                  _mode == AesMode.gcm
                      ? ctkTr(context, 'ctk_aes_nonce', 'Nonce (IV)')
                      : ctkTr(context, 'ctk_aes_iv', 'IV'),
                ),
              ),
              GlassIconButton(
                icon: Icons.casino_outlined,
                tooltip: ctkTr(context, 'ctk_aes_gen_iv', 'Random IV'),
                onTap: _generateIv,
              ),
              const SizedBox(width: 6),
              GlassIconButton(
                icon: Icons.content_paste_rounded,
                tooltip: ctkTr(context, 'ctk_paste', 'Paste'),
                onTap: () => ctkPaste(context, _ivCtrl),
              ),
              const SizedBox(width: 6),
              GlassIconButton(
                icon: Icons.close_rounded,
                tooltip: ctkTr(context, 'ctk_clear', 'Clear'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  _ivCtrl.clear();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          GlassTextField(
            controller: _ivCtrl,
            hint: '$ivLen bytes / ${ivLen * 2} hex chars',
            maxLines: 2,
            minLines: 1,
          ),
          const SizedBox(height: 10),
          GlassInfoBanner(
            icon: Icons.info_outline,
            color: CtkColors.accentB,
            text: _mode == AesMode.gcm
                ? ctkTr(
              context,
              'ctk_aes_gcm_nonce_hint',
              'GCM requires a 12-byte nonce. Never reuse it with the same key.',
            )
                : ctkTr(
              context,
              'ctk_aes_cbc_iv_hint',
              'CBC uses a 16-byte IV. Must be random for each message.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlainCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: GlassSectionTitle(
                  Icons.description_outlined,
                  ctkTr(context, 'ctk_aes_plaintext', 'Plaintext'),
                ),
              ),
              GlassIconButton(
                icon: Icons.content_paste_rounded,
                tooltip: ctkTr(context, 'ctk_paste', 'Paste'),
                onTap: () => ctkPaste(context, _plainCtrl),
              ),
              const SizedBox(width: 6),
              GlassIconButton(
                icon: Icons.close_rounded,
                tooltip: ctkTr(context, 'ctk_clear', 'Clear'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  _plainCtrl.clear();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          GlassTextField(
            controller: _plainCtrl,
            hint: ctkTr(
              context,
              'ctk_aes_plain_hint',
              'Text to encrypt…',
            ),
            maxLines: 6,
            minLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildCipherCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: GlassSectionTitle(
                  Icons.lock_outline_rounded,
                  ctkTr(context, 'ctk_aes_ciphertext', 'Ciphertext (base64)'),
                ),
              ),
              GlassIconButton(
                icon: Icons.content_paste_rounded,
                tooltip: ctkTr(context, 'ctk_paste', 'Paste'),
                onTap: () => ctkPaste(context, _cipherCtrl),
              ),
              const SizedBox(width: 6),
              GlassIconButton(
                icon: Icons.close_rounded,
                tooltip: ctkTr(context, 'ctk_clear', 'Clear'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  _cipherCtrl.clear();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          GlassTextField(
            controller: _cipherCtrl,
            hint: ctkTr(
              context,
              'ctk_aes_cipher_hint',
              'Base64-encoded ciphertext…',
            ),
            maxLines: 6,
            minLines: 4,
          ),
          const SizedBox(height: 10),
          GlassSwitchRow(
            label: ctkTr(
              context,
              'ctk_aes_use_combined',
              'Combined format (IV + ciphertext)',
            ),
            value: _useCombined,
            onChanged: (bool v) => setState(() {
              _useCombined = v;
              _decResult = null;
              _encResult = null;
              _errorKey = null;
              _errorDetail = null;
            }),
          ),
          if (_useCombined) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              ctkTr(
                context,
                'ctk_aes_combined_hint',
                'Single base64 blob where the first bytes are the IV/nonce and the rest is the ciphertext.',
              ),
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEncryptResultCard(AesEncryptedResult r) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: GlassSectionTitle(
                  Icons.check_circle_outline_rounded,
                  ctkTr(context, 'ctk_aes_result', 'Result'),
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
                  '${r.plaintextBytes}B → ${r.cipherBytes}B',
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
          GlassOutputBlock(
            label: 'CIPHERTEXT (base64)',
            value: r.cipherBase64,
            copied: _copiedCipher,
            onCopy: () => _copy(r.cipherBase64, 'cipher'),
          ),
          const SizedBox(height: 12),
          GlassOutputBlock(
            label: 'COMBINED (iv+ct, base64)',
            value: r.combinedBase64,
            copied: _copiedCombined,
            onCopy: () => _copy(r.combinedBase64, 'combined'),
          ),
          const SizedBox(height: 12),
          GlassOutputBlock(
            label: 'KEY (hex)',
            value: r.keyHex,
            copied: _copiedKey,
            onCopy: () => _copy(r.keyHex, 'key'),
          ),
          const SizedBox(height: 12),
          GlassOutputBlock(
            label: _mode == AesMode.gcm ? 'NONCE (hex)' : 'IV (hex)',
            value: r.ivHex,
            copied: _copiedIv,
            onCopy: () => _copy(r.ivHex, 'iv'),
          ),
          const SizedBox(height: 10),
          GlassInfoBanner(
            icon: Icons.info_outline,
            color: CtkColors.accentB,
            text: ctkTr(
              context,
              'ctk_aes_store_hint',
              'Store key, IV/nonce, and ciphertext. Decryption requires all three.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecryptResultCard(AesDecryptedResult r) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: GlassSectionTitle(
                  Icons.check_circle_outline_rounded,
                  ctkTr(context, 'ctk_aes_plain_result', 'Decrypted'),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: CtkColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${r.plaintextBytes} B',
                  style: const TextStyle(
                    color: CtkColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GlassOutputBlock(
            label: 'PLAINTEXT',
            value: r.plaintext,
            copied: _copiedPlain,
            onCopy: () => _copy(r.plaintext, 'plain'),
          ),
        ],
      ),
    );
  }
}