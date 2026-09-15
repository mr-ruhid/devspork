import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'sri_engine.dart';
import 'ui_kit.dart';

class SriTab extends StatefulWidget {
  const SriTab({super.key});

  @override
  State<SriTab> createState() => _SriTabState();
}

class _SriTabState extends State<SriTab> {
  final TextEditingController _contentCtrl = TextEditingController();
  final TextEditingController _urlCtrl = TextEditingController();
  final TextEditingController _targetCtrl = TextEditingController();

  SriSource _source = SriSource.text;
  SriAlgorithm _algo = SriAlgorithm.sha384;
  SriTagType _tagType = SriTagType.script;
  bool _crossOrigin = true;
  bool _defer = false;
  bool _async = false;

  SriResult? _result;
  String? _errorKey;
  String? _errorDetail;
  bool _loading = false;

  Timer? _debounce;
  bool _copiedIntegrity = false;
  bool _copiedTag = false;

  @override
  void initState() {
    super.initState();
    _contentCtrl.addListener(_scheduleCompute);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _contentCtrl.removeListener(_scheduleCompute);
    _contentCtrl.dispose();
    _urlCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  void _scheduleCompute() {
    if (_source != SriSource.text) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _computeText);
  }

  void _computeText() {
    final String text = _contentCtrl.text;
    if (text.isEmpty) {
      if (_result != null || _errorKey != null) {
        setState(() {
          _result = null;
          _errorKey = null;
          _errorDetail = null;
        });
      }
      return;
    }
    try {
      final SriResult r = SriEngine.fromText(text, _algo);
      setState(() {
        _result = r;
        _errorKey = null;
        _errorDetail = null;
      });
    } on SriException catch (e) {
      setState(() {
        _result = null;
        _errorKey = e.errorKey;
        _errorDetail = e.detail;
      });
    } catch (e) {
      setState(() {
        _result = null;
        _errorKey = CryptoToolkitErrors.sriEmptyInput;
        _errorDetail = e.toString();
      });
    }
  }

  Future<void> _computeFromUrl() async {
    final String url = _urlCtrl.text.trim();
    if (url.isEmpty) {
      setState(() {
        _errorKey = CryptoToolkitErrors.sriEmptyInput;
        _errorDetail = null;
        _result = null;
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _errorKey = null;
      _errorDetail = null;
      _result = null;
    });

    try {
      final SriResult r = await SriEngine.fromUrl(url, _algo);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _result = r;
      });
      HapticFeedback.lightImpact();
    } on SriException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorKey = e.errorKey;
        _errorDetail = e.detail;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorKey = CryptoToolkitErrors.sriFetchFailed;
        _errorDetail = e.toString();
      });
    }
  }

  Future<void> _pasteFromFilePicker() async {
    final ClipboardData? c = await Clipboard.getData(Clipboard.kTextPlain);
    if (c == null || c.text == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _source = SriSource.text;
      _contentCtrl.text = c.text!;
    });
    _computeText();
  }

  void _changeSource(SriSource s) {
    if (_source == s) return;
    setState(() {
      _source = s;
      _result = null;
      _errorKey = null;
      _errorDetail = null;
    });
  }

  void _changeAlgo(SriAlgorithm a) {
    setState(() => _algo = a);
    if (_source == SriSource.text) {
      _computeText();
    } else if (_result != null && _urlCtrl.text.trim().isNotEmpty) {
      _computeFromUrl();
    }
  }

  void _clearAll() {
    HapticFeedback.mediumImpact();
    _contentCtrl.clear();
    _urlCtrl.clear();
    _targetCtrl.clear();
    setState(() {
      _result = null;
      _errorKey = null;
      _errorDetail = null;
    });
  }

  String get _targetValue => _targetCtrl.text.trim();

  String get _htmlTag {
    final SriResult? r = _result;
    if (r == null) return '';
    final String target = _targetValue.isEmpty
        ? (r.algorithm.tag == 'sha384'
        ? '/path/to/file.js'
        : '/path/to/file')
        : _targetValue;
    return SriEngine.buildTag(
      result: r,
      tagType: _tagType,
      target: target,
      crossOrigin: _crossOrigin,
      defer: _defer,
      async: _async,
    );
  }

  Future<void> _copyIntegrity() async {
    final SriResult? r = _result;
    if (r == null) return;
    await ctkCopy(context, r.integrity);
    if (!mounted) return;
    setState(() => _copiedIntegrity = true);
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _copiedIntegrity = false);
    });
  }

  Future<void> _copyTag() async {
    final String tag = _htmlTag;
    if (tag.isEmpty) return;
    await ctkCopy(context, tag);
    if (!mounted) return;
    setState(() => _copiedTag = true);
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _copiedTag = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildSourceCard(),
          const SizedBox(height: 14),
          _buildAlgorithmCard(),
          const SizedBox(height: 14),
          if (_source == SriSource.text)
            _buildContentCard()
          else
            _buildUrlCard(),
          if (_errorKey != null) ...<Widget>[
            const SizedBox(height: 14),
            GlassErrorBox(errorKey: _errorKey!, detail: _errorDetail),
          ],
          if (_result != null) ...<Widget>[
            const SizedBox(height: 14),
            _buildResultCard(_result!),
            const SizedBox(height: 14),
            _buildTagOptionsCard(),
            const SizedBox(height: 14),
            _buildTagOutputCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildSourceCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: GlassSectionTitle(
                  Icons.source_outlined,
                  ctkTr(context, 'ctk_sri_source', 'Source'),
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
          GlassChipPicker<SriSource>(
            values: SriSource.values,
            current: _source,
            labelOf: (SriSource v) => v.display,
            onChanged: _changeSource,
          ),
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
            ctkTr(context, 'ctk_sri_algorithm', 'Algorithm'),
          ),
          const SizedBox(height: 10),
          GlassChipPicker<SriAlgorithm>(
            values: SriAlgorithm.values,
            current: _algo,
            labelOf: (SriAlgorithm v) => v.display,
            onChanged: _changeAlgo,
          ),
          const SizedBox(height: 10),
          Text(
            ctkTr(
              context,
              'ctk_sri_algo_hint',
              'sha384 is recommended by W3C (falls back to sha256 on older browsers).',
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

  Widget _buildContentCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: GlassSectionTitle(
                  Icons.code_rounded,
                  ctkTr(context, 'ctk_sri_content', 'Content'),
                ),
              ),
              GlassIconButton(
                icon: Icons.content_paste_rounded,
                tooltip: ctkTr(context, 'ctk_paste', 'Paste'),
                onTap: _pasteFromFilePicker,
              ),
              const SizedBox(width: 6),
              GlassIconButton(
                icon: Icons.close_rounded,
                tooltip: ctkTr(context, 'ctk_clear', 'Clear'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  _contentCtrl.clear();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          GlassTextField(
            controller: _contentCtrl,
            hint: ctkTr(
              context,
              'ctk_sri_content_hint',
              'Paste JS/CSS content or any text…',
            ),
            maxLines: 8,
            minLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildUrlCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: GlassSectionTitle(
                  Icons.link_rounded,
                  ctkTr(context, 'ctk_sri_url', 'URL'),
                ),
              ),
              GlassIconButton(
                icon: Icons.content_paste_rounded,
                tooltip: ctkTr(context, 'ctk_paste', 'Paste'),
                onTap: () => ctkPaste(context, _urlCtrl),
              ),
              const SizedBox(width: 6),
              GlassIconButton(
                icon: Icons.close_rounded,
                tooltip: ctkTr(context, 'ctk_clear', 'Clear'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  _urlCtrl.clear();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          GlassTextField(
            controller: _urlCtrl,
            hint: 'https://cdn.example.com/lib.js',
            maxLines: 1,
          ),
          const SizedBox(height: 12),
          GlassPrimaryButton(
            icon: _loading
                ? Icons.hourglass_top_rounded
                : Icons.cloud_download_outlined,
            label: _loading
                ? ctkTr(context, 'ctk_sri_fetching', 'Fetching…')
                : ctkTr(context, 'ctk_sri_fetch', 'Fetch & hash'),
            onTap: _loading ? null : _computeFromUrl,
          ),
          const SizedBox(height: 10),
          Text(
            ctkTr(
              context,
              'ctk_sri_url_hint',
              'The file is downloaded to your device and hashed locally. It is not sent anywhere.',
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

  Widget _buildResultCard(SriResult r) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: GlassSectionTitle(
                  Icons.verified_outlined,
                  ctkTr(context, 'ctk_sri_result', 'Integrity hash'),
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
                  SriEngine.formatBytes(r.byteLength),
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
            label: 'INTEGRITY',
            value: r.integrity,
            copied: _copiedIntegrity,
            onCopy: _copyIntegrity,
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _infoMini(
                  ctkTr(context, 'ctk_sri_algo_used', 'Algorithm'),
                  r.algorithm.display,
                ),
              ),
              Expanded(
                child: _infoMini(
                  ctkTr(context, 'ctk_sri_length', 'Bytes'),
                  '${r.byteLength}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoMini(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: CtkColors.accentB,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildTagOptionsCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GlassSectionTitle(
            Icons.tune_rounded,
            ctkTr(context, 'ctk_sri_tag_options', 'HTML tag options'),
          ),
          const SizedBox(height: 10),
          GlassChipPicker<SriTagType>(
            label: ctkTr(context, 'ctk_sri_tag_type', 'Tag type'),
            values: SriTagType.values,
            current: _tagType,
            labelOf: (SriTagType v) => v.display,
            onChanged: (SriTagType v) => setState(() => _tagType = v),
          ),
          const SizedBox(height: 12),
          GlassTextField(
            controller: _targetCtrl,
            hint: _tagType == SriTagType.script
                ? 'https://cdn.example.com/lib.js'
                : 'https://cdn.example.com/style.css',
            maxLines: 1,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          GlassSwitchRow(
            label: ctkTr(
              context,
              'ctk_sri_crossorigin',
              'crossorigin="anonymous"',
            ),
            value: _crossOrigin,
            onChanged: (bool v) => setState(() => _crossOrigin = v),
          ),
          if (_tagType == SriTagType.script) ...<Widget>[
            GlassSwitchRow(
              label: 'defer',
              value: _defer,
              onChanged: (bool v) => setState(() => _defer = v),
            ),
            GlassSwitchRow(
              label: 'async',
              value: _async,
              onChanged: (bool v) => setState(() => _async = v),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTagOutputCard() {
    final String tag = _htmlTag;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GlassSectionTitle(
            Icons.html_rounded,
            ctkTr(context, 'ctk_sri_tag_output', 'HTML snippet'),
          ),
          const SizedBox(height: 10),
          GlassOutputBlock(
            label: 'HTML',
            value: tag,
            copied: _copiedTag,
            onCopy: _copyTag,
          ),
        ],
      ),
    );
  }
}