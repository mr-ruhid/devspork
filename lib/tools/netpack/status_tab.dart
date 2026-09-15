import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'status_engine.dart';
import 'ui_kit.dart';

class StatusTab extends StatefulWidget {
  const StatusTab({super.key});

  @override
  State<StatusTab> createState() => _StatusTabState();
}

class _StatusTabState extends State<StatusTab>
    with SingleTickerProviderStateMixin {
  late final TabController _subTabs;

  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _urlCtrl = TextEditingController();

  HttpStatusCategory? _filterCategory;
  List<HttpStatusCode> _filtered = StatusEngine.allCodes;

  String _probeMethod = 'GET';
  HttpProbeResult? _probeResult;
  String? _probeErrorKey;
  String? _probeErrorDetail;
  bool _probeLoading = false;
  bool _followRedirects = true;

  bool _copiedHeaders = false;
  bool _copiedRedirects = false;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _subTabs = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(_onSearch);
    _urlCtrl.text = 'https://example.com';
    _applyFilter();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _subTabs.dispose();
    _searchCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), _applyFilter);
  }

  void _applyFilter() {
    final List<HttpStatusCode> searchResult =
    StatusEngine.search(_searchCtrl.text);
    final List<HttpStatusCode> byCat = _filterCategory == null
        ? searchResult
        : searchResult
        .where((HttpStatusCode s) =>
    s.category == _filterCategory)
        .toList();
    setState(() => _filtered = byCat);
  }

  void _setCategory(HttpStatusCategory? c) {
    setState(() => _filterCategory = c);
    _applyFilter();
  }

  void _clearSearch() {
    HapticFeedback.selectionClick();
    _searchCtrl.clear();
    setState(() => _filterCategory = null);
    _applyFilter();
  }

  Future<void> _probe() async {
    final String url = _urlCtrl.text.trim();
    if (url.isEmpty) {
      setState(() {
        _probeErrorKey = NetErrors.statusEmptyUrl;
        _probeErrorDetail = null;
        _probeResult = null;
      });
      return;
    }

    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();

    setState(() {
      _probeLoading = true;
      _probeErrorKey = null;
      _probeErrorDetail = null;
      _probeResult = null;
    });

    try {
      final HttpProbeResult r = await StatusEngine.probe(
        url,
        method: _probeMethod,
        maxRedirects: _followRedirects ? 10 : 0,
      );
      if (!mounted) return;
      setState(() {
        _probeLoading = false;
        _probeResult = r;
      });
      HapticFeedback.lightImpact();
    } on StatusException catch (e) {
      if (!mounted) return;
      setState(() {
        _probeLoading = false;
        _probeErrorKey = e.errorKey;
        _probeErrorDetail = e.detail;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _probeLoading = false;
        _probeErrorKey = NetErrors.statusFailed;
        _probeErrorDetail = e.toString();
      });
    }
  }

  Future<void> _copyHeaders() async {
    final HttpProbeResult? r = _probeResult;
    if (r == null) return;
    await netCopy(context, StatusEngine.headersToText(r.headers));
    if (!mounted) return;
    setState(() => _copiedHeaders = true);
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _copiedHeaders = false);
    });
  }

  Future<void> _copyRedirects() async {
    final HttpProbeResult? r = _probeResult;
    if (r == null) return;
    await netCopy(context, StatusEngine.redirectsToText(r.redirects));
    if (!mounted) return;
    setState(() => _copiedRedirects = true);
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _copiedRedirects = false);
    });
  }

  Future<void> _copyJson() async {
    final HttpProbeResult? r = _probeResult;
    if (r == null) return;
    await netCopy(context, StatusEngine.probeToJson(r));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: NetCard(
            padding: const EdgeInsets.all(4),
            radius: 14,
            child: TabBar(
              controller: _subTabs,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: <Color>[
                    NetColors.accentA,
                    NetColors.accentB,
                  ],
                ),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              tabs: <Widget>[
                Tab(
                  text: netTr(context, 'net_status_sub_probe', 'Probe'),
                ),
                Tab(
                  text: netTr(context, 'net_status_sub_reference', 'Reference'),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabs,
            children: <Widget>[
              _buildProbeView(),
              _buildReferenceView(),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // PROBE VIEW
  // ==========================================================================

  Widget _buildProbeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildProbeInputCard(),
          if (_probeErrorKey != null) ...<Widget>[
            const SizedBox(height: 14),
            NetErrorBox(
              errorKey: _probeErrorKey!,
              detail: _probeErrorDetail,
            ),
          ],
          if (_probeResult != null) ...<Widget>[
            const SizedBox(height: 14),
            _buildProbeSummaryCard(_probeResult!),
            if (_probeResult!.hasRedirects) ...<Widget>[
              const SizedBox(height: 14),
              _buildRedirectsCard(_probeResult!),
            ],
            const SizedBox(height: 14),
            _buildHeadersCard(_probeResult!),
            const SizedBox(height: 14),
            _buildExportCard(_probeResult!),
          ],
        ],
      ),
    );
  }

  Widget _buildProbeInputCard() {
    return NetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          NetSectionTitle(
            Icons.travel_explore_rounded,
            netTr(context, 'net_status_probe', 'Live URL probe'),
          ),
          const SizedBox(height: 12),
          NetTextField(
            controller: _urlCtrl,
            hint: 'https://example.com',
            label: netTr(context, 'net_status_url', 'URL'),
            onSubmitted: (_) => _probe(),
          ),
          const SizedBox(height: 12),
          NetChipPicker<String>(
            label: netTr(context, 'net_status_method', 'Method'),
            values: const <String>[
              'GET',
              'HEAD',
              'OPTIONS',
              'POST',
            ],
            current: _probeMethod,
            labelOf: (String v) => v,
            onChanged: (String v) => setState(() => _probeMethod = v),
            scrollable: false,
          ),
          const SizedBox(height: 10),
          NetSwitchRow(
            label: netTr(
              context,
              'net_status_follow_redirects',
              'Follow redirects (up to 10)',
            ),
            value: _followRedirects,
            onChanged: (bool v) => setState(() => _followRedirects = v),
          ),
          const SizedBox(height: 12),
          NetPrimaryButton(
            icon: _probeLoading
                ? Icons.hourglass_top_rounded
                : Icons.play_arrow_rounded,
            label: _probeLoading
                ? netTr(context, 'net_status_sending', 'Sending…')
                : netTr(context, 'net_status_send', 'Send request'),
            onTap: _probeLoading ? null : _probe,
          ),
        ],
      ),
    );
  }

  Widget _buildProbeSummaryCard(HttpProbeResult r) {
    final Color color = r.category.color;
    return NetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: NetSectionTitle(
                  Icons.check_circle_outline_rounded,
                  netTr(context, 'net_status_summary', 'Response'),
                ),
              ),
              NetStatusPill(
                label: '${r.statusCode} ${r.statusText}',
                color: color,
                icon: _statusIcon(r.statusCode),
              ),
            ],
          ),
          const SizedBox(height: 12),
          NetKeyValueRow(
            label: netTr(context, 'net_status_method', 'Method'),
            value: r.method,
            labelWidth: 120,
          ),
          NetKeyValueRow(
            label: netTr(context, 'net_status_final_url', 'Final URL'),
            value: r.finalUrl,
            labelWidth: 120,
            monospaceValue: true,
            copyValue: true,
            onCopy: () => netCopy(context, r.finalUrl),
          ),
          if (r.finalUrl != r.url)
            NetKeyValueRow(
              label: netTr(context, 'net_status_initial_url', 'Initial URL'),
              value: r.url,
              labelWidth: 120,
              monospaceValue: true,
            ),
          NetKeyValueRow(
            label: netTr(context, 'net_status_elapsed', 'Response time'),
            value: StatusEngine.formatDuration(r.elapsedMs),
            labelWidth: 120,
            valueColor: r.elapsedMs < 300
                ? NetColors.success
                : (r.elapsedMs < 1000
                ? NetColors.warning
                : NetColors.danger),
          ),
          if (r.contentType != null)
            NetKeyValueRow(
              label: 'Content-Type',
              value: r.contentType!,
              labelWidth: 120,
            ),
          if (r.contentLength != null)
            NetKeyValueRow(
              label: 'Content-Length',
              value: StatusEngine.formatBytes(r.contentLength!),
              labelWidth: 120,
            ),
          NetKeyValueRow(
            label: netTr(context, 'net_status_redirects_count', 'Redirects'),
            value: '${r.redirects.length - 1}',
            labelWidth: 120,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Row(
              children: <Widget>[
                Icon(_statusIcon(r.statusCode), color: color, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _categoryMessage(r),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(int code) {
    if (code < 200) return Icons.info_outline_rounded;
    if (code < 300) return Icons.check_circle_rounded;
    if (code < 400) return Icons.swap_horiz_rounded;
    if (code < 500) return Icons.warning_amber_rounded;
    return Icons.error_outline_rounded;
  }

  String _categoryMessage(HttpProbeResult r) {
    final HttpStatusCode? found = StatusEngine.findByCode(r.statusCode);
    if (found != null) return found.description;
    return r.category.display;
  }

  Widget _buildRedirectsCard(HttpProbeResult r) {
    return NetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: NetSectionTitle(
                  Icons.alt_route_rounded,
                  netTr(context, 'net_status_redirect_chain', 'Redirect chain'),
                ),
              ),
              NetIconButton(
                icon: _copiedRedirects
                    ? Icons.check_rounded
                    : Icons.copy_rounded,
                tooltip: netTr(context, 'net_copy', 'Copy'),
                onTap: _copyRedirects,
                highlighted: _copiedRedirects,
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < r.redirects.length; i++)
            _redirectStep(r.redirects[i], i, r.redirects.length),
        ],
      ),
    );
  }

  Widget _redirectStep(HttpRedirectStep step, int i, int total) {
    final bool isRedirect = step.statusCode >= 300 && step.statusCode < 400;
    final Color color =
    isRedirect ? NetColors.warning : NetColors.success;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.5)),
                ),
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (i < total - 1)
                Container(
                  width: 2,
                  height: 18,
                  color: Colors.white.withOpacity(0.15),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${step.statusCode}',
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SelectableText(
                  step.url,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                if (step.location != null && step.location!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  SelectableText(
                    '→ ${step.location}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontFamily: 'monospace',
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadersCard(HttpProbeResult r) {
    return NetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: NetSectionTitle(
                  Icons.list_alt_rounded,
                  netTr(context, 'net_status_headers', 'Response headers'),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: NetColors.accentB.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${r.headers.length}',
                  style: const TextStyle(
                    color: NetColors.accentB,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 6),
              NetIconButton(
                icon: _copiedHeaders
                    ? Icons.check_rounded
                    : Icons.copy_rounded,
                tooltip: netTr(context, 'net_copy', 'Copy'),
                onTap: _copyHeaders,
                highlighted: _copiedHeaders,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (r.headers.isEmpty)
            Text(
              netTr(context, 'net_status_no_headers', 'No headers'),
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            for (final HttpHeader h in r.headers)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 140,
                      child: Text(
                        h.name,
                        style: const TextStyle(
                          color: NetColors.accentA,
                          fontSize: 11,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SelectableText(
                        h.value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontFamily: 'monospace',
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildExportCard(HttpProbeResult r) {
    return NetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          NetSectionTitle(
            Icons.download_rounded,
            netTr(context, 'net_status_export', 'Export'),
          ),
          const SizedBox(height: 12),
          NetPrimaryButton(
            icon: Icons.data_object_rounded,
            label: netTr(context, 'net_status_copy_json', 'Copy as JSON'),
            onTap: _copyJson,
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // REFERENCE VIEW
  // ==========================================================================

  Widget _buildReferenceView() {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              NetTextField(
                controller: _searchCtrl,
                hint: netTr(
                  context,
                  'net_status_search_hint',
                  'Search by code, title, or description…',
                ),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Colors.white54,
                  ),
                  onPressed: _clearSearch,
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    _categoryChip(
                      label: netTr(context, 'net_status_all', 'All'),
                      selected: _filterCategory == null,
                      color: NetColors.accentA,
                      onTap: () => _setCategory(null),
                    ),
                    const SizedBox(width: 6),
                    for (final HttpStatusCategory c
                    in HttpStatusCategory.values) ...<Widget>[
                      _categoryChip(
                        label: c.display,
                        selected: _filterCategory == c,
                        color: c.color,
                        onTap: () => _setCategory(c),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _filtered.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 12),
                Text(
                  netTr(
                    context,
                    'net_status_no_match',
                    'No matching status codes',
                  ),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
              : ListView.separated(
            padding:
            const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: _filtered.length,
            separatorBuilder: (_, __) =>
            const SizedBox(height: 8),
            itemBuilder: (BuildContext context, int i) {
              return _statusCard(_filtered[i]);
            },
          ),
        ),
      ],
    );
  }

  Widget _categoryChip({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.2)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? color.withOpacity(0.6)
                : Colors.white.withOpacity(0.15),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : Colors.white70,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _statusCard(HttpStatusCode s) {
    final Color color = s.category.color;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.5)),
                ),
                child: Text(
                  '${s.code}',
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              NetIconButton(
                icon: Icons.copy_rounded,
                tooltip: netTr(context, 'net_copy', 'Copy'),
                onTap: () => netCopy(context, '${s.code} ${s.title}'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            s.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                s.category.display,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}