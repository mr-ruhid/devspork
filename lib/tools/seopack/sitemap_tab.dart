import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'sitemap_engine.dart';
import 'ui_kit.dart';

class SitemapTab extends StatefulWidget {
  const SitemapTab({super.key});

  @override
  State<SitemapTab> createState() => _SitemapTabState();
}

class _SitemapTabState extends State<SitemapTab> {
  final SitemapConfig _config = SitemapConfig();
  final TextEditingController _bulkCtrl = TextEditingController();

  final Map<int, TextEditingController> _urlCtrls =
  <int, TextEditingController>{};
  final Map<int, TextEditingController> _lastmodCtrls =
  <int, TextEditingController>{};
  final Map<int, TextEditingController> _indexCtrls =
  <int, TextEditingController>{};
  final Map<int, TextEditingController> _indexLastmodCtrls =
  <int, TextEditingController>{};

  String _output = '';
  String? _errorKey;
  String? _errorDetail;
  bool _copied = false;
  bool _showBulk = false;

  @override
  void initState() {
    super.initState();
    _addUrlEntry();
    _addUrlEntry();
    _addUrlEntry();
    _regenerate();
  }

  @override
  void dispose() {
    _bulkCtrl.dispose();
    _disposeAll();
    super.dispose();
  }

  void _disposeAll() {
    for (final c in _urlCtrls.values) {
      c.dispose();
    }
    for (final c in _lastmodCtrls.values) {
      c.dispose();
    }
    for (final c in _indexCtrls.values) {
      c.dispose();
    }
    for (final c in _indexLastmodCtrls.values) {
      c.dispose();
    }
    _urlCtrls.clear();
    _lastmodCtrls.clear();
    _indexCtrls.clear();
    _indexLastmodCtrls.clear();
  }

  void _rebuildControllers() {
    _disposeAll();
    for (int i = 0; i < _config.urls.length; i++) {
      final SitemapUrlEntry e = _config.urls[i];
      final TextEditingController loc = TextEditingController(text: e.loc);
      final TextEditingController lm =
      TextEditingController(text: e.lastmod ?? '');
      final int idx = i;
      loc.addListener(() {
        _config.urls[idx].loc = loc.text;
        _regenerate();
      });
      lm.addListener(() {
        final String t = lm.text.trim();
        _config.urls[idx].lastmod = t.isEmpty ? null : t;
        _regenerate();
      });
      _urlCtrls[i] = loc;
      _lastmodCtrls[i] = lm;
    }
    for (int i = 0; i < _config.indexes.length; i++) {
      final SitemapIndexEntry e = _config.indexes[i];
      final TextEditingController loc = TextEditingController(text: e.loc);
      final TextEditingController lm =
      TextEditingController(text: e.lastmod ?? '');
      final int idx = i;
      loc.addListener(() {
        _config.indexes[idx].loc = loc.text;
        _regenerate();
      });
      lm.addListener(() {
        final String t = lm.text.trim();
        _config.indexes[idx].lastmod = t.isEmpty ? null : t;
        _regenerate();
      });
      _indexCtrls[i] = loc;
      _indexLastmodCtrls[i] = lm;
    }
  }

  void _addUrlEntry({String loc = ''}) {
    HapticFeedback.selectionClick();
    setState(() {
      _config.urls.add(SitemapUrlEntry(loc: loc));
      _rebuildControllers();
      _regenerate();
    });
  }

  void _removeUrlEntry(int i) {
    HapticFeedback.mediumImpact();
    setState(() {
      _config.urls.removeAt(i);
      _rebuildControllers();
      _regenerate();
    });
  }

  void _addIndexEntry() {
    HapticFeedback.selectionClick();
    setState(() {
      _config.indexes.add(SitemapIndexEntry(loc: ''));
      _rebuildControllers();
      _regenerate();
    });
  }

  void _removeIndexEntry(int i) {
    HapticFeedback.mediumImpact();
    setState(() {
      _config.indexes.removeAt(i);
      _rebuildControllers();
      _regenerate();
    });
  }

  void _changeMode(SitemapMode m) {
    if (_config.mode == m) return;
    setState(() {
      _config.mode = m;
      _regenerate();
    });
  }

  void _setChangeFreq(int i, ChangeFreq? f) {
    setState(() {
      _config.urls[i].changeFreq = f;
      _regenerate();
    });
  }

  void _setPriority(int i, double? p) {
    setState(() {
      _config.urls[i].priority = p;
      _regenerate();
    });
  }

  void _regenerate() {
    try {
      final String out = SitemapEngine.build(_config);
      if (!mounted) return;
      setState(() {
        _output = out;
        _errorKey = null;
        _errorDetail = null;
      });
    } on SitemapException catch (e) {
      if (!mounted) return;
      setState(() {
        _output = '';
        _errorKey = e.errorKey;
        _errorDetail = e.detail;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _output = '';
        _errorKey = SeoErrors.sitemapEmpty;
        _errorDetail = e.toString();
      });
    }
  }

  Future<void> _pasteBulk() async {
    final ClipboardData? c = await Clipboard.getData(Clipboard.kTextPlain);
    if (c == null || c.text == null) return;
    HapticFeedback.selectionClick();
    _bulkCtrl.text = c.text!;
  }

  void _applyBulk() {
    final String raw = _bulkCtrl.text.trim();
    if (raw.isEmpty) return;

    FocusScope.of(context).unfocus();
    try {
      final List<SitemapUrlEntry> parsed = SitemapEngine.parseUrlLines(
        raw,
        applyDefaults: _config.applyDefaults,
        defaultFreq: _config.defaultChangeFreq,
        defaultPriority: _config.defaultPriority,
      );
      if (parsed.isEmpty) return;
      setState(() {
        _config.urls
          ..clear()
          ..addAll(parsed);
        _rebuildControllers();
        _bulkCtrl.clear();
        _showBulk = false;
        _regenerate();
      });
      HapticFeedback.lightImpact();
    } catch (e) {
      setState(() {
        _errorKey = SeoErrors.sitemapInvalidUrl;
        _errorDetail = e.toString();
      });
    }
  }

  Future<void> _copy() async {
    if (_output.isEmpty) return;
    await seoCopy(context, _output);
    if (!mounted) return;
    setState(() => _copied = true);
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _setTodayLastmod(int i) {
    HapticFeedback.selectionClick();
    setState(() {
      _config.urls[i].lastmod = SitemapEngine.todayIso();
      _lastmodCtrls[i]?.text = _config.urls[i].lastmod!;
      _regenerate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildModeCard(),
          const SizedBox(height: 14),
          if (_config.mode == SitemapMode.urlset) ...<Widget>[
            _buildOptionsCard(),
            const SizedBox(height: 14),
            _buildBulkCard(),
            const SizedBox(height: 14),
            _buildUrlListCard(),
          ] else ...<Widget>[
            _buildIndexOptionsCard(),
            const SizedBox(height: 14),
            _buildIndexListCard(),
          ],
          if (_errorKey != null) ...<Widget>[
            const SizedBox(height: 14),
            SeoErrorBox(errorKey: _errorKey!, detail: _errorDetail),
          ],
          const SizedBox(height: 14),
          _buildOutputCard(),
        ],
      ),
    );
  }

  Widget _buildModeCard() {
    return SeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SeoSectionTitle(
            Icons.description_outlined,
            seoTr(context, 'seo_sitemap_mode', 'Sitemap type'),
          ),
          const SizedBox(height: 10),
          SeoChipPicker<SitemapMode>(
            values: SitemapMode.values,
            current: _config.mode,
            labelOf: (SitemapMode v) => v.display,
            onChanged: _changeMode,
          ),
          const SizedBox(height: 10),
          Text(
            _config.mode == SitemapMode.urlset
                ? seoTr(
              context,
              'seo_sitemap_urlset_hint',
              'A single <urlset> file listing all pages of your site.',
            )
                : seoTr(
              context,
              'seo_sitemap_index_hint',
              'A <sitemapindex> pointing to multiple sitemap files (max 50,000 URLs per file).',
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

  Widget _buildOptionsCard() {
    return SeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SeoSectionTitle(
            Icons.tune_rounded,
            seoTr(context, 'seo_sitemap_options', 'Options'),
          ),
          const SizedBox(height: 6),
          SeoSwitchRow(
            label: seoTr(
              context,
              'seo_sitemap_xml_decl',
              'Include <?xml?> declaration',
            ),
            value: _config.includeXmlDeclaration,
            onChanged: (bool v) => setState(() {
              _config.includeXmlDeclaration = v;
              _regenerate();
            }),
          ),
          SeoSwitchRow(
            label: seoTr(
              context,
              'seo_sitemap_apply_defaults',
              'Apply default changefreq & priority',
            ),
            value: _config.applyDefaults,
            onChanged: (bool v) => setState(() {
              _config.applyDefaults = v;
              _regenerate();
            }),
          ),
          if (_config.applyDefaults) ...<Widget>[
            const SizedBox(height: 10),
            SeoChipPicker<ChangeFreq>(
              label: seoTr(
                context,
                'seo_sitemap_default_freq',
                'Default changefreq',
              ),
              values: ChangeFreq.values,
              current: _config.defaultChangeFreq,
              labelOf: (ChangeFreq v) => v.display,
              onChanged: (ChangeFreq v) => setState(() {
                _config.defaultChangeFreq = v;
                _regenerate();
              }),
            ),
            const SizedBox(height: 10),
            _priorityRow(
              seoTr(context, 'seo_sitemap_default_priority',
                  'Default priority'),
              _config.defaultPriority,
                  (double v) => setState(() {
                _config.defaultPriority = v;
                _regenerate();
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIndexOptionsCard() {
    return SeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SeoSectionTitle(
            Icons.tune_rounded,
            seoTr(context, 'seo_sitemap_options', 'Options'),
          ),
          const SizedBox(height: 6),
          SeoSwitchRow(
            label: seoTr(
              context,
              'seo_sitemap_xml_decl',
              'Include <?xml?> declaration',
            ),
            value: _config.includeXmlDeclaration,
            onChanged: (bool v) => setState(() {
              _config.includeXmlDeclaration = v;
              _regenerate();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkCard() {
    return SeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: SeoSectionTitle(
                  Icons.playlist_add_rounded,
                  seoTr(context, 'seo_sitemap_bulk', 'Bulk paste URLs'),
                ),
              ),
              SeoIconButton(
                icon: _showBulk
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                tooltip: _showBulk
                    ? seoTr(context, 'seo_collapse', 'Collapse')
                    : seoTr(context, 'seo_expand', 'Expand'),
                onTap: () => setState(() => _showBulk = !_showBulk),
              ),
            ],
          ),
          if (_showBulk) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              seoTr(
                context,
                'seo_sitemap_bulk_hint',
                'One URL per line. Optional: url|changefreq|priority|lastmod (any order after the first pipe).',
              ),
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            SeoTextField(
              controller: _bulkCtrl,
              hint: 'https://example.com/\n'
                  'https://example.com/about|weekly|0.8\n'
                  'https://example.com/blog|daily|0.9|2024-06-01',
              maxLines: 8,
              minLines: 5,
              monospace: true,
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: SeoPrimaryButton(
                    icon: Icons.download_done_rounded,
                    label: seoTr(context, 'seo_sitemap_apply', 'Replace list'),
                    onTap: _applyBulk,
                  ),
                ),
                const SizedBox(width: 8),
                SeoIconButton(
                  icon: Icons.content_paste_rounded,
                  tooltip: seoTr(context, 'seo_paste', 'Paste'),
                  onTap: _pasteBulk,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUrlListCard() {
    return SeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: SeoSectionTitle(
                  Icons.link_rounded,
                  seoTr(context, 'seo_sitemap_urls', 'URLs'),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: SeoColors.accentB.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_config.urls.length}',
                  style: const TextStyle(
                    color: SeoColors.accentB,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < _config.urls.length; i++) ...<Widget>[
            _buildUrlEntry(i),
            if (i < _config.urls.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
          SeoPrimaryButton(
            icon: Icons.add_rounded,
            label: seoTr(context, 'seo_sitemap_add_url', 'Add URL'),
            onTap: () => _addUrlEntry(),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlEntry(int i) {
    final SitemapUrlEntry e = _config.urls[i];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: SeoColors.accentA.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '#${i + 1}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              SeoIconButton(
                icon: Icons.today_rounded,
                tooltip: seoTr(context, 'seo_sitemap_today', 'Set lastmod to today'),
                onTap: () => _setTodayLastmod(i),
              ),
              const SizedBox(width: 4),
              SeoIconButton(
                icon: Icons.content_paste_rounded,
                tooltip: seoTr(context, 'seo_paste', 'Paste'),
                onTap: () async {
                  final ClipboardData? c =
                  await Clipboard.getData(Clipboard.kTextPlain);
                  if (c == null || c.text == null) return;
                  _urlCtrls[i]?.text = c.text!;
                },
              ),
              const SizedBox(width: 4),
              SeoIconButton(
                icon: Icons.close_rounded,
                tooltip: seoTr(context, 'seo_remove', 'Remove'),
                onTap: () => _removeUrlEntry(i),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SeoTextField(
            controller: _urlCtrls[i]!,
            hint: 'https://example.com/page',
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: SeoTextField(
                  controller: _lastmodCtrls[i]!,
                  hint: 'YYYY-MM-DD (lastmod)',
                  monospace: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _changeFreqPicker(i, e),
          const SizedBox(height: 8),
          _priorityRow(
            seoTr(context, 'seo_sitemap_priority', 'Priority'),
            e.priority ?? 0.5,
                (double v) => _setPriority(i, v),
            allowNull: e.priority == null,
            onClear: () => _setPriority(i, null),
            onSet: () => _setPriority(i, e.priority ?? 0.5),
          ),
        ],
      ),
    );
  }

  Widget _changeFreqPicker(int i, SitemapUrlEntry e) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'changefreq',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: <Widget>[
            _freqChip(
              label: '—',
              selected: e.changeFreq == null,
              onTap: () => _setChangeFreq(i, null),
            ),
            ...ChangeFreq.values.map((ChangeFreq f) => _freqChip(
              label: f.display,
              selected: e.changeFreq == f,
              onTap: () => _setChangeFreq(i, f),
            )),
          ],
        ),
      ],
    );
  }

  Widget _freqChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? SeoColors.accentA.withOpacity(0.35)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? SeoColors.accentA
                : Colors.white.withOpacity(0.15),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white60,
            fontSize: 10,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _priorityRow(
      String label,
      double value,
      ValueChanged<double> onChanged, {
        bool allowNull = false,
        VoidCallback? onClear,
        VoidCallback? onSet,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: SeoColors.accentB.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value.toStringAsFixed(1),
                style: const TextStyle(
                  color: SeoColors.accentB,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            if (allowNull && onSet != null) ...<Widget>[
              const SizedBox(width: 4),
              SeoIconButton(
                icon: Icons.add_rounded,
                tooltip: seoTr(context, 'seo_sitemap_include_priority',
                    'Include priority'),
                onTap: onSet,
              ),
            ],
            if (!allowNull && onClear != null) ...<Widget>[
              const SizedBox(width: 4),
              SeoIconButton(
                icon: Icons.remove_rounded,
                tooltip: seoTr(context, 'seo_sitemap_exclude_priority',
                    'Exclude priority'),
                onTap: onClear,
              ),
            ],
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: SeoColors.accentA,
            inactiveTrackColor: Colors.white24,
            thumbColor: SeoColors.accentB,
            trackHeight: 3,
          ),
          child: Slider(
            value: value.clamp(0.0, 1.0),
            min: 0.0,
            max: 1.0,
            divisions: 10,
            onChanged: (double v) {
              final double rounded = (v * 10).roundToDouble() / 10;
              onChanged(rounded);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIndexListCard() {
    return SeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: SeoSectionTitle(
                  Icons.list_rounded,
                  seoTr(context, 'seo_sitemap_index_list', 'Sitemap files'),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: SeoColors.accentB.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_config.indexes.length}',
                  style: const TextStyle(
                    color: SeoColors.accentB,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < _config.indexes.length; i++) ...<Widget>[
            _buildIndexEntry(i),
            if (i < _config.indexes.length - 1)
              const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
          SeoPrimaryButton(
            icon: Icons.add_rounded,
            label: seoTr(context, 'seo_sitemap_add_index', 'Add sitemap'),
            onTap: _addIndexEntry,
          ),
        ],
      ),
    );
  }

  Widget _buildIndexEntry(int i) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: SeoColors.accentA.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '#${i + 1}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              SeoIconButton(
                icon: Icons.close_rounded,
                tooltip: seoTr(context, 'seo_remove', 'Remove'),
                onTap: () => _removeIndexEntry(i),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SeoTextField(
            controller: _indexCtrls[i]!,
            hint: 'https://example.com/sitemap-posts.xml',
          ),
          const SizedBox(height: 8),
          SeoTextField(
            controller: _indexLastmodCtrls[i]!,
            hint: 'YYYY-MM-DD (lastmod, optional)',
            monospace: true,
          ),
        ],
      ),
    );
  }

  Widget _buildOutputCard() {
    final int size = SitemapEngine.estimateSizeBytes(_output);
    return SeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: SeoSectionTitle(
                  Icons.code_rounded,
                  seoTr(context, 'seo_sitemap_output', 'Sitemap XML'),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: SeoColors.accentB.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${SitemapEngine.countEntries(_config)} · ${SitemapEngine.formatBytes(size)}',
                  style: const TextStyle(
                    color: SeoColors.accentB,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SeoOutputBlock(
            label: 'XML',
            value: _output,
            copied: _copied,
            onCopy: _copy,
            emptyHint: seoTr(
              context,
              'seo_sitemap_output_empty',
              'Add at least one URL to generate the sitemap.',
            ),
            maxHeight: 320,
          ),
        ],
      ),
    );
  }
}