import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/localization/app_localization.dart';

const Color _accentA = Color(0xFF7C4DFF);
const Color _accentB = Color(0xFF00E5FF);
const Color _danger = Color(0xFFFF5C5C);
const Color _success = Color(0xFF4BD68B);
const Color _warning = Color(0xFFFFC24B);
const Color _bgTop = Color(0xFF1B1035);
const Color _bgMid = Color(0xFF2A1550);
const Color _bgBot = Color(0xFF0F2A4A);

const int _hardCombinationCap = 20000000;

class WordlistGeneratorPage extends StatefulWidget {
  const WordlistGeneratorPage({super.key});

  @override
  State<WordlistGeneratorPage> createState() => _WordlistGeneratorPageState();
}

class _WordlistGeneratorPageState extends State<WordlistGeneratorPage> {
  final TextEditingController _minLenCtrl = TextEditingController(text: '3');
  final TextEditingController _maxLenCtrl = TextEditingController(text: '5');
  final TextEditingController _charsetCtrl =
  TextEditingController(text: 'abcdefghijklmnopqrstuvwxyz0123456789');
  final TextEditingController _prefixCtrl = TextEditingController();
  final TextEditingController _suffixCtrl = TextEditingController();
  final TextEditingController _separatorCtrl = TextEditingController();

  bool _allowRepeats = false;
  bool _excludeSimilar = false;
  bool _caseVariations = false;
  bool _leetVariations = false;
  int _maxConsecutiveRepeats = 1;

  bool _generating = false;
  List<String> _generatedList = <String>[];
  String? _statusKey;
  String? _statusDetail;
  int _previewLimit = 200;

  bool _copied = false;
  bool _saved = false;

  Isolate? _isolate;
  ReceivePort? _receivePort;
  Stopwatch? _genStopwatch;
  Duration? _lastElapsed;

  final List<_RunHistoryItem> _history = <_RunHistoryItem>[];

  @override
  void dispose() {
    _minLenCtrl.dispose();
    _maxLenCtrl.dispose();
    _charsetCtrl.dispose();
    _prefixCtrl.dispose();
    _suffixCtrl.dispose();
    _separatorCtrl.dispose();
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();
    super.dispose();
  }

  BigInt _estimateCombinations() {
    final int minLen = int.tryParse(_minLenCtrl.text.trim()) ?? 0;
    final int maxLen = int.tryParse(_maxLenCtrl.text.trim()) ?? 0;
    final int charsetLen = _effectiveCharsetLength();
    if (minLen < 1 || maxLen < minLen || charsetLen < 1) return BigInt.zero;

    BigInt total = BigInt.zero;
    for (int len = minLen; len <= maxLen; len++) {
      if (_allowRepeats) {
        total += BigInt.from(charsetLen).pow(len);
      } else {
        if (len > charsetLen) continue;
        BigInt perms = BigInt.one;
        for (int i = 0; i < len; i++) {
          perms *= BigInt.from(charsetLen - i);
        }
        total += perms;
      }
    }
    int multiplier = 1;
    if (_caseVariations) multiplier *= 3;
    if (_leetVariations) multiplier *= 2;
    return total * BigInt.from(multiplier);
  }

  int _effectiveCharsetLength() {
    String charset = _charsetCtrl.text.trim();
    if (_excludeSimilar) {
      const List<String> similar = <String>['0', 'O', 'o', '1', 'l', 'I'];
      charset =
          charset.split('').where((String c) => !similar.contains(c)).join();
    }
    return charset.split('').toSet().length;
  }

  String _formatBig(BigInt n) {
    if (n < BigInt.from(1000)) return n.toString();
    final double asDouble = n.toDouble();
    const List<String> units = <String>['', 'K', 'M', 'B', 'T'];
    double v = asDouble;
    int unit = 0;
    while (v >= 1000 && unit < units.length - 1) {
      v /= 1000;
      unit++;
    }
    return '${v.toStringAsFixed(v < 10 ? 2 : 1)}${units[unit]}';
  }

  Future<void> _generate() async {
    FocusScope.of(context).unfocus();
    final int minLen = int.tryParse(_minLenCtrl.text.trim()) ?? 3;
    final int maxLen = int.tryParse(_maxLenCtrl.text.trim()) ?? 5;
    final String charset = _charsetCtrl.text.trim();

    if (charset.isEmpty) {
      _showToast(context.t('wordlistgen_error_charset_empty'));
      return;
    }
    if (minLen < 1 || maxLen < minLen || maxLen > 20) {
      _showToast(context.t('wordlistgen_error_length'));
      return;
    }

    final Set<String> uniqueChars = charset.split('').toSet();
    if (uniqueChars.length < 2) {
      _showToast(context.t('wordlistgen_error_charset_min'));
      return;
    }

    final BigInt estimate = _estimateCombinations();
    if (estimate > BigInt.from(_hardCombinationCap)) {
      _showToast(
        '${context.t('wordlistgen_error_too_big')}: ~${_formatBig(estimate)}',
      );
      return;
    }

    String effectiveCharset = charset;
    if (_excludeSimilar) {
      const List<String> similar = <String>['0', 'O', 'o', '1', 'l', 'I'];
      effectiveCharset = effectiveCharset
          .split('')
          .where((String c) => !similar.contains(c))
          .join();
    }

    final Map<String, dynamic> params = <String, dynamic>{
      'minLen': minLen,
      'maxLen': maxLen,
      'charset': effectiveCharset,
      'prefix': _prefixCtrl.text.trim(),
      'suffix': _suffixCtrl.text.trim(),
      'separator': _separatorCtrl.text.trim(),
      'allowRepeats': _allowRepeats,
      'maxConsecutiveRepeats': _maxConsecutiveRepeats,
      'caseVariations': _caseVariations,
      'leetVariations': _leetVariations,
    };

    setState(() {
      _generating = true;
      _generatedList = <String>[];
      _statusKey = 'wordlistgen_status_preparing';
      _statusDetail = null;
      _previewLimit = 200;
    });

    _genStopwatch = Stopwatch()..start();
    final ReceivePort receivePort = ReceivePort();
    _receivePort = receivePort;

    try {
      _isolate = await Isolate.spawn<List<dynamic>>(
        _isolateEntry,
        <dynamic>[receivePort.sendPort, params],
      );
      final dynamic message = await receivePort.first;
      _genStopwatch?.stop();
      _cleanupIsolate();
      if (!mounted) return;

      if (message is List<String>) {
        setState(() {
          _generatedList = message;
          _generating = false;
          _statusKey = 'wordlistgen_status_generated';
          _statusDetail = '${message.length}';
          _lastElapsed = _genStopwatch?.elapsed;
        });
        _history.insert(
          0,
          _RunHistoryItem(
            count: message.length,
            minLen: minLen,
            maxLen: maxLen,
            charsetLen: uniqueChars.length,
            at: DateTime.now(),
          ),
        );
        if (_history.length > 5) _history.removeLast();
        HapticFeedback.mediumImpact();
      } else {
        setState(() {
          _generating = false;
          _statusKey = 'wordlistgen_status_error';
          _statusDetail = '$message';
        });
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      _cleanupIsolate();
      if (!mounted) return;
      setState(() {
        _generating = false;
        _statusKey = 'wordlistgen_status_error';
        _statusDetail = '$e';
      });
    }
  }

  void _cancelGeneration() {
    HapticFeedback.heavyImpact();
    _isolate?.kill(priority: Isolate.immediate);
    _cleanupIsolate();
    _genStopwatch?.stop();
    setState(() {
      _generating = false;
      _statusKey = 'wordlistgen_status_cancelled';
      _statusDetail = null;
    });
  }

  void _cleanupIsolate() {
    _isolate = null;
    _receivePort?.close();
    _receivePort = null;
  }

  Future<void> _saveToFile() async {
    if (_generatedList.isEmpty) return;
    try {
      final Directory dir = await getApplicationDocumentsDirectory();
      final String fileName =
          'wordlist_${DateTime.now().millisecondsSinceEpoch}.txt';
      final File file = File('${dir.path}/$fileName');
      final IOSink sink = file.openWrite();
      for (final String w in _generatedList) {
        sink.writeln(w);
      }
      await sink.flush();
      await sink.close();
      if (!mounted) return;
      setState(() => _saved = true);
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _saved = false);
      });
      _showToast('${context.t('wordlistgen_saved')}: $fileName');
      HapticFeedback.lightImpact();
    } catch (e) {
      _showToast('${context.t('wordlistgen_error_save')}: $e');
    }
  }

  Future<void> _shareFile() async {
    if (_generatedList.isEmpty) return;
    try {
      final Directory dir = await getApplicationDocumentsDirectory();
      final String fileName =
          'wordlist_${DateTime.now().millisecondsSinceEpoch}.txt';
      final File file = File('${dir.path}/$fileName');
      final IOSink sink = file.openWrite();
      for (final String w in _generatedList) {
        sink.writeln(w);
      }
      await sink.flush();
      await sink.close();
      await Share.shareXFiles(<XFile>[XFile(file.path)], text: fileName);
    } catch (e) {
      _showToast('${context.t('wordlistgen_error_share')}: $e');
    }
  }

  Future<void> _copyAll() async {
    if (_generatedList.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _generatedList.join('\n')));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _copied = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
    _showToast(context.t('wordlistgen_copied'));
  }

  void _clear() {
    HapticFeedback.lightImpact();
    setState(() {
      _generatedList = <String>[];
      _statusKey = null;
      _statusDetail = null;
      _previewLimit = 200;
      _lastElapsed = null;
    });
  }

  void _loadMorePreview() {
    HapticFeedback.selectionClick();
    setState(
          () => _previewLimit = min(_previewLimit + 400, _generatedList.length),
    );
  }

  void _showToast(String message) {
    final OverlayState overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (BuildContext ctx) => Positioned(
        bottom: 90,
        left: 40,
        right: 40,
        child: _ToastBubble(message: message),
      ),
    );
    overlay.insert(entry);
    Future<void>.delayed(const Duration(milliseconds: 1600), entry.remove);
  }

  @override
  Widget build(BuildContext context) {
    final BigInt estimate = _estimateCombinations();
    final bool tooBig = estimate > BigInt.from(_hardCombinationCap);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0B0B12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.t('wordlistgen_title'),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        actions: <Widget>[
          if (_generatedList.isNotEmpty)
            _glassIconButton(
              icon: _saved
                  ? CupertinoIcons.checkmark_alt
                  : CupertinoIcons.arrow_down_doc,
              tooltip: context.t('wordlistgen_save_file'),
              onTap: _saveToFile,
              highlighted: _saved,
            ),
          const SizedBox(width: 4),
          if (_generatedList.isNotEmpty)
            _glassIconButton(
              icon: CupertinoIcons.share,
              tooltip: context.t('wordlistgen_share'),
              onTap: _shareFile,
            ),
          const SizedBox(width: 4),
          if (_generatedList.isNotEmpty)
            _glassIconButton(
              icon: _copied
                  ? CupertinoIcons.checkmark_alt
                  : CupertinoIcons.doc_on_doc,
              tooltip: context.t('wordlistgen_copy'),
              onTap: _copyAll,
              highlighted: _copied,
            ),
          const SizedBox(width: 4),
          _glassIconButton(
            icon: CupertinoIcons.refresh,
            tooltip: context.t('wordlistgen_clear'),
            onTap: _clear,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[_bgTop, _bgMid, _bgBot],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(top: -80, left: -60, child: _blob(220, _accentA)),
            Positioned(bottom: -100, right: -60, child: _blob(260, _accentB)),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildLengthCard(),
                    const SizedBox(height: 14),
                    _buildCharsetCard(),
                    const SizedBox(height: 14),
                    _buildOptionsCard(),
                    const SizedBox(height: 14),
                    _buildAffixCard(),
                    const SizedBox(height: 14),
                    _buildEstimateCard(estimate, tooBig),
                    const SizedBox(height: 14),
                    _buildGenerateButton(tooBig),
                    if (_generating) ...<Widget>[
                      const SizedBox(height: 14),
                      _GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            const LinearProgressIndicator(
                              backgroundColor: Colors.white12,
                              color: _accentB,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    _statusKey != null
                                        ? context.t(_statusKey!)
                                        : '',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _cancelGeneration,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _danger.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _danger.withOpacity(0.4),
                                      ),
                                    ),
                                    child: Text(
                                      context.t('wordlistgen_cancel'),
                                      style: const TextStyle(
                                        color: _danger,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (!_generating &&
                        _statusKey != null &&
                        _statusKey!.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 14),
                      _GlassCard(
                        child: Row(
                          children: <Widget>[
                            Icon(
                              _statusKey == 'wordlistgen_status_error'
                                  ? CupertinoIcons.exclamationmark_triangle
                                  : CupertinoIcons.check_mark_circled,
                              color: _statusKey == 'wordlistgen_status_error'
                                  ? _danger
                                  : _success,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _statusDetail != null
                                    ? '${context.t(_statusKey!)} ${_statusDetail!}'
                                    : context.t(_statusKey!),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (_lastElapsed != null)
                              Text(
                                '${_lastElapsed!.inMilliseconds}ms',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.35),
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (_generatedList.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 14),
                      _buildPreviewCard(),
                    ],
                    if (_history.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 14),
                      _buildHistoryCard(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstimateCard(BigInt estimate, bool tooBig) {
    final Color color = tooBig
        ? _danger
        : (estimate > BigInt.from(200000) ? _warning : _success);
    return _GlassCard(
      child: Row(
        children: <Widget>[
          Icon(
            tooBig
                ? CupertinoIcons.exclamationmark_triangle_fill
                : CupertinoIcons.chart_bar_alt_fill,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '~${_formatBig(estimate)}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  tooBig
                      ? '${context.t('wordlistgen_estimate_too_big')} (${_formatBig(BigInt.from(_hardCombinationCap))})'
                      : context.t('wordlistgen_estimate_hint'),
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLengthCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            CupertinoIcons.arrow_left_right,
            context.t('wordlistgen_section_length'),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _inlineField(
                  controller: _minLenCtrl,
                  label: context.t('wordlistgen_min'),
                  keyboard: TextInputType.number,
                  onChanged: () => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _inlineField(
                  controller: _maxLenCtrl,
                  label: context.t('wordlistgen_max'),
                  keyboard: TextInputType.number,
                  onChanged: () => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.t('wordlistgen_length_hint'),
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildCharsetCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            CupertinoIcons.textformat_abc,
            context.t('wordlistgen_section_charset'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _charsetCtrl,
            maxLines: 3,
            minLines: 2,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontFamily: 'monospace',
            ),
            decoration: _inputDecoration(
              context.t('wordlistgen_charset_hint'),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              _quickCharset('abc', 'abc'),
              _quickCharset('ABC', 'ABC'),
              _quickCharset('123', '123'),
              _quickCharset('abc123', 'abc123'),
              _quickCharset('a-z', 'abcdefghijklmnopqrstuvwxyz'),
              _quickCharset('A-Z', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
              _quickCharset('0-9', '0123456789'),
              _quickCharset('!@#', '!@#\$%^&*'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickCharset(String label, String value) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _charsetCtrl.text = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _accentB.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _accentB.withOpacity(0.4)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: _accentB,
            fontSize: 11,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            CupertinoIcons.slider_horizontal_3,
            context.t('wordlistgen_section_options'),
          ),
          const SizedBox(height: 6),
          _switchRow(
            label: context.t('wordlistgen_allow_repeats'),
            value: _allowRepeats,
            onChanged: (bool v) => setState(() => _allowRepeats = v),
          ),
          if (_allowRepeats) ...<Widget>[
            const SizedBox(height: 4),
            _sliderRow(
              label: context.t('wordlistgen_max_consecutive'),
              value: _maxConsecutiveRepeats.toDouble(),
              min: 1,
              max: 5,
              onChanged: (double v) =>
                  setState(() => _maxConsecutiveRepeats = v.round()),
            ),
          ],
          _switchRow(
            label: context.t('wordlistgen_exclude_similar'),
            value: _excludeSimilar,
            onChanged: (bool v) => setState(() => _excludeSimilar = v),
          ),
          _switchRow(
            label: context.t('wordlistgen_case_variations'),
            value: _caseVariations,
            onChanged: (bool v) => setState(() => _caseVariations = v),
          ),
          _switchRow(
            label: context.t('wordlistgen_leet_variations'),
            value: _leetVariations,
            onChanged: (bool v) => setState(() => _leetVariations = v),
          ),
        ],
      ),
    );
  }

  Widget _buildAffixCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            CupertinoIcons.link,
            context.t('wordlistgen_section_affix'),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _inlineField(
                  controller: _prefixCtrl,
                  label: context.t('wordlistgen_prefix'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _inlineField(
                  controller: _suffixCtrl,
                  label: context.t('wordlistgen_suffix'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _inlineField(
            controller: _separatorCtrl,
            label: context.t('wordlistgen_separator'),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton(bool disabled) {
    final bool inactive = _generating || disabled;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: inactive ? null : _generate,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: inactive ? 0.5 : 1,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[_accentA, _accentB],
                ),
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    _generating
                        ? CupertinoIcons.hourglass
                        : CupertinoIcons.sparkles,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _generating
                        ? context.t('wordlistgen_generating')
                        : context.t('wordlistgen_generate'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    final int previewCount = min(_previewLimit, _generatedList.length);
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _sectionTitle(
                  CupertinoIcons.list_bullet,
                  '${context.t('wordlistgen_preview')} ($previewCount)',
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _accentB.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_generatedList.length}',
                  style: const TextStyle(
                    color: _accentB,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            constraints: const BoxConstraints(maxHeight: 320),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: previewCount,
              itemBuilder: (BuildContext context, int i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    _generatedList[i],
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          if (previewCount < _generatedList.length) ...<Widget>[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _loadMorePreview,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Text(
                  '${context.t('wordlistgen_load_more')} (+${min(400, _generatedList.length - previewCount)})',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionTitle(
            CupertinoIcons.clock,
            context.t('wordlistgen_history'),
          ),
          const SizedBox(height: 8),
          ..._history.map((_RunHistoryItem h) {
            final String hh = h.at.hour.toString().padLeft(2, '0');
            final String mm = h.at.minute.toString().padLeft(2, '0');
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: <Widget>[
                  const Icon(
                    CupertinoIcons.doc_text,
                    size: 13,
                    color: _accentA,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${h.count} · ${h.minLen}-${h.maxLen} · ${h.charsetLen}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    '$hh:$mm',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String text) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _switchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: CupertinoSwitch(
              value: value,
              activeColor: _accentA,
              onChanged: (bool v) {
                HapticFeedback.selectionClick();
                onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _accentB.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${value.round()}',
                  style: const TextStyle(
                    color: _accentB,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _accentA,
              inactiveTrackColor: Colors.white24,
              thumbColor: _accentB,
              trackHeight: 3,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: (max - min).round(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _inlineField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboard,
    VoidCallback? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      onChanged: (_) => onChanged?.call(),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontFamily: 'monospace',
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 11),
        hintText: label,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.25),
          fontSize: 12,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _accentB, width: 1.4),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.white.withOpacity(0.28),
        fontSize: 12,
        fontFamily: 'monospace',
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      contentPadding: const EdgeInsets.all(12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accentB, width: 1.4),
      ),
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool highlighted = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: highlighted
                ? _success.withOpacity(0.25)
                : Colors.white.withOpacity(0.08),
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  icon,
                  size: 18,
                  color: highlighted ? _success : Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return IgnorePointer(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.35),
            ),
          ),
        ),
      ),
    );
  }
}

class _RunHistoryItem {
  _RunHistoryItem({
    required this.count,
    required this.minLen,
    required this.maxLen,
    required this.charsetLen,
    required this.at,
  });
  final int count;
  final int minLen;
  final int maxLen;
  final int charsetLen;
  final DateTime at;
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.06),
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ToastBubble extends StatelessWidget {
  const _ToastBubble({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _isolateEntry(List<dynamic> args) {
  final SendPort sendPort = args[0] as SendPort;
  final Map<String, dynamic> params = args[1] as Map<String, dynamic>;
  try {
    final List<String> result = _generateWordlist(params);
    sendPort.send(result);
  } catch (e) {
    sendPort.send('$e');
  }
}

List<String> _generateWordlist(Map<String, dynamic> params) {
  final int minLen = params['minLen'] as int;
  final int maxLen = params['maxLen'] as int;
  final String charset = params['charset'] as String;
  final String prefix = params['prefix'] as String;
  final String suffix = params['suffix'] as String;
  final String separator = params['separator'] as String;
  final bool allowRepeats = params['allowRepeats'] as bool;
  final int maxConsecutiveRepeats = params['maxConsecutiveRepeats'] as int;
  final bool caseVariations = params['caseVariations'] as bool;
  final bool leetVariations = params['leetVariations'] as bool;

  final Set<String> results = <String>{};
  final List<String> chars = charset.split('');

  for (int len = minLen; len <= maxLen; len++) {
    _generateForLength(
      chars: chars,
      length: len,
      prefix: prefix,
      suffix: suffix,
      separator: separator,
      allowRepeats: allowRepeats,
      maxConsecutiveRepeats: maxConsecutiveRepeats,
      caseVariations: caseVariations,
      leetVariations: leetVariations,
      results: results,
    );
  }

  final List<String> list = results.toList();
  list.sort();
  return list;
}

void _generateForLength({
  required List<String> chars,
  required int length,
  required String prefix,
  required String suffix,
  required String separator,
  required bool allowRepeats,
  required int maxConsecutiveRepeats,
  required bool caseVariations,
  required bool leetVariations,
  required Set<String> results,
}) {
  if (length <= 0) return;

  void recurse(int depth, String current, String lastChar, int repeatCount) {
    if (depth == length) {
      _emit(
        current,
        prefix,
        suffix,
        separator,
        caseVariations,
        leetVariations,
        results,
      );
      return;
    }

    for (final String c in chars) {
      if (!allowRepeats && current.contains(c)) continue;
      if (allowRepeats && maxConsecutiveRepeats > 0 && c == lastChar) {
        if (repeatCount >= maxConsecutiveRepeats) continue;
        recurse(depth + 1, current + c, c, repeatCount + 1);
      } else {
        recurse(depth + 1, current + c, c, 1);
      }
    }
  }

  recurse(0, '', '', 0);
}

void _emit(
    String base,
    String prefix,
    String suffix,
    String separator,
    bool caseVariations,
    bool leetVariations,
    Set<String> results,
    ) {
  final List<String> variants = <String>[base];

  if (caseVariations) {
    final List<String> caseVariants =
    <String>{base, base.toUpperCase(), base.toLowerCase()}.toList();
    variants.addAll(caseVariants);
  }

  if (leetVariations) {
    variants.add(_leetConvert(base));
  }

  for (final String v in variants) {
    if (prefix.isNotEmpty || suffix.isNotEmpty) {
      final String joined = <String>[prefix, v, suffix]
          .where((String s) => s.isNotEmpty)
          .join(separator);
      results.add(joined);
    } else {
      results.add(v);
    }
  }
}

String _leetConvert(String input) {
  final Map<String, String> leet = <String, String>{
    'a': '4',
    'e': '3',
    'i': '1',
    'o': '0',
    's': '5',
    'A': '4',
    'E': '3',
    'I': '1',
    'O': '0',
    'S': '5',
  };
  final StringBuffer sb = StringBuffer();
  for (int i = 0; i < input.length; i++) {
    final String c = input[i];
    sb.write(leet[c] ?? c);
  }
  return sb.toString();
}