
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dns_engine.dart';
import 'models.dart';
import 'ui_kit.dart';

class DnsTab extends StatefulWidget {
  const DnsTab({super.key});

  @override
  State<DnsTab> createState() => _DnsTabState();
}

class _DnsTabState extends State<DnsTab> {
  final TextEditingController _domainCtrl = TextEditingController();

  DnsProvider _provider = DnsProvider.google;
  DnsRecordType _type = DnsRecordType.a;

  DnsResult? _result;
  Map<DnsRecordType, DnsResult>? _bulkResult;
  String? _errorKey;
  String? _errorDetail;
  bool _loading = false;
  bool _bulkLoading = false;
  bool _showBulk = false;

  final List<String> _recentDomains = <String>[];

  @override
  void initState() {
    super.initState();
    _domainCtrl.text = 'example.com';
  }

  @override
  void dispose() {
    _domainCtrl.dispose();
    super.dispose();
  }

  void _addRecent(String domain) {
    final String d = domain.trim().toLowerCase();
    if (d.isEmpty) return;
    _recentDomains.remove(d);
    _recentDomains.insert(0, d);
    if (_recentDomains.length > 6) {
      _recentDomains.removeRange(6, _recentDomains.length);
    }
  }

  Future<void> _lookup() async {
    final String domain = _domainCtrl.text.trim();
    if (domain.isEmpty) {
      setState(() {
        _errorKey = NetErrors.dnsEmptyDomain;
        _errorDetail = null;
        _result = null;
      });
      return;
    }

    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();

    setState(() {
      _loading = true;
      _errorKey = null;
      _errorDetail = null;
      _result = null;
      _bulkResult = null;
    });

    try {
      final DnsResult r = await DnsEngine.lookup(
        domain: domain,
        type: _type,
        provider: _provider,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _result = r;
        if (r.isNxDomain) {
          _errorKey = NetErrors.dnsNxDomain;
          _errorDetail = 'The domain does not exist.';
        } else if (!r.hasAnswers && r.isSuccess) {
          _errorKey = NetErrors.dnsNoRecords;
          _errorDetail = 'No ${_type.query} records found for $domain.';
        }
      });
      _addRecent(domain);
      HapticFeedback.lightImpact();
    } on DnsException catch (e) {
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
        _errorKey = NetErrors.dnsServerError;
        _errorDetail = e.toString();
      });
    }
  }

  Future<void> _lookupAll() async {
    final String domain = _domainCtrl.text.trim();
    if (domain.isEmpty) {
      setState(() {
        _errorKey = NetErrors.dnsEmptyDomain;
        _errorDetail = null;
      });
      return;
    }

    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();

    setState(() {
      _bulkLoading = true;
      _bulkResult = null;
      _result = null;
      _errorKey = null;
      _errorDetail = null;
      _showBulk = true;
    });

    try {
      final Map<DnsRecordType, DnsResult> results =
      await DnsEngine.lookupAll(
        domain: domain,
        provider: _provider,
      );
      if (!mounted) return;
      setState(() {
        _bulkLoading = false;
        _bulkResult = results;
      });
      _addRecent(domain);
    } on DnsException catch (e) {
      if (!mounted) return;
      setState(() {
        _bulkLoading = false;
        _errorKey = e.errorKey;
        _errorDetail = e.detail;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _bulkLoading = false;
        _errorKey = NetErrors.dnsServerError;
        _errorDetail = e.toString();
      });
    }
  }

  void _setFromRecent(String d) {
    HapticFeedback.selectionClick();
    setState(() => _domainCtrl.text = d);
  }

  void _clear() {
    HapticFeedback.selectionClick();
    setState(() {
      _domainCtrl.clear();
      _result = null;
      _bulkResult = null;
      _errorKey = null;
      _errorDetail = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildProviderCard(),
          const SizedBox(height: 14),
          _buildQueryCard(),
          if (_recentDomains.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            _buildRecentCard(),
          ],
          if (_errorKey != null) ...<Widget>[
            const SizedBox(height: 14),
            NetErrorBox(errorKey: _errorKey!, detail: _errorDetail),
          ],
          if (_result != null) ...<Widget>[
            const SizedBox(height: 14),
            _buildResultCard(_result!),
          ],
          if (_bulkResult != null) ...<Widget>[
            const SizedBox(height: 14),
            _buildBulkResultCard(_bulkResult!),
          ],
        ],
      ),
    );
  }

  Widget _buildProviderCard() {
    return NetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          NetSectionTitle(
            Icons.cloud_outlined,
            netTr(context, 'net_dns_provider', 'DNS provider'),
          ),
          const SizedBox(height: 10),
          NetChipPicker<DnsProvider>(
            values: DnsProvider.values,
            current: _provider,
            labelOf: (DnsProvider v) => v.display,
            onChanged: (DnsProvider v) {
              setState(() => _provider = v);
              if (_result != null) _lookup();
              if (_bulkResult != null) _lookupAll();
            },
          ),
          const SizedBox(height: 10),
          NetInfoBanner(
            icon: Icons.info_outline,
            color: NetColors.accentA,
            text: netTr(
              context,
              'net_dns_doh_hint',
              'DNS-over-HTTPS — queries are sent encrypted to the provider.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueryCard() {
    return NetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: NetSectionTitle(
                  Icons.dns_outlined,
                  netTr(context, 'net_dns_lookup', 'DNS lookup'),
                ),
              ),
              NetIconButton(
                icon: Icons.clear_all_rounded,
                tooltip: netTr(context, 'net_clear', 'Clear'),
                onTap: _clear,
              ),
            ],
          ),
          const SizedBox(height: 12),
          NetTextField(
            controller: _domainCtrl,
            hint: 'example.com',
            label: netTr(context, 'net_dns_domain', 'Domain'),
            onSubmitted: (_) => _lookup(),
          ),
          const SizedBox(height: 12),
          NetChipPicker<DnsRecordType>(
            label: netTr(context, 'net_dns_type', 'Record type'),
            values: DnsRecordType.values,
            current: _type,
            labelOf: (DnsRecordType v) => v.query,
            onChanged: (DnsRecordType v) {
              setState(() => _type = v);
              if (_result != null) _lookup();
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: NetPrimaryButton(
                  icon: _loading
                      ? Icons.hourglass_top_rounded
                      : Icons.search_rounded,
                  label: _loading
                      ? netTr(context, 'net_dns_querying', 'Querying…')
                      : netTr(context, 'net_dns_query', 'Lookup'),
                  onTap: _loading ? null : _lookup,
                ),
              ),
              const SizedBox(width: 10),
              Tooltip(
                message: netTr(
                  context,
                  'net_dns_bulk_tooltip',
                  'Query A + AAAA + CNAME + MX + NS + TXT',
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Material(
                    color: NetColors.accentB.withOpacity(0.18),
                    child: InkWell(
                      onTap: _bulkLoading ? null : _lookupAll,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Icon(
                          _bulkLoading
                              ? Icons.hourglass_top_rounded
                              : Icons.view_list_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCard() {
    return NetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          NetSectionTitle(
            Icons.history_rounded,
            netTr(context, 'net_dns_recent', 'Recent'),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _recentDomains
                .map((String d) => GestureDetector(
              onTap: () => _setFromRecent(d),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                  ),
                ),
                child: Text(
                  d,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(DnsResult r) {
    return NetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: NetSectionTitle(
                  Icons.check_circle_outline_rounded,
                  netTr(context, 'net_dns_result', 'Result'),
                ),
              ),
              NetStatusPill(
                label: r.statusName,
                color: r.isSuccess
                    ? NetColors.success
                    : (r.isNxDomain
                    ? NetColors.warning
                    : NetColors.danger),
                icon: r.isSuccess
                    ? Icons.check_rounded
                    : Icons.error_outline,
              ),
            ],
          ),
          const SizedBox(height: 12),
          NetKeyValueRow(
            label: netTr(context, 'net_dns_domain', 'Domain'),
            value: r.domain,
          ),
          NetKeyValueRow(
            label: netTr(context, 'net_dns_type', 'Record type'),
            value: r.recordType.query,
          ),
          NetKeyValueRow(
            label: netTr(context, 'net_dns_provider_used', 'Provider'),
            value: r.provider.display,
          ),
          NetKeyValueRow(
            label: netTr(context, 'net_dns_response_time', 'Response time'),
            value: '${r.elapsedMs}ms',
            valueColor: r.elapsedMs < 200
                ? NetColors.success
                : (r.elapsedMs < 800
                ? NetColors.warning
                : NetColors.danger),
          ),
          if (r.truncated)
            NetInfoBanner(
              icon: Icons.warning_amber_rounded,
              text: netTr(
                context,
                'net_dns_truncated',
                'Response was truncated. Try a specific record type.',
              ),
            ),
          if (r.hasAnswers) ...<Widget>[
            const SizedBox(height: 14),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),
            Text(
              '${r.answers.length} ${netTr(context, 'net_dns_records', 'record(s)')}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < r.answers.length; i++) ...<Widget>[
              _answerTile(r.answers[i], i),
              if (i < r.answers.length - 1) const SizedBox(height: 8),
            ],
          ],
          if (!r.hasAnswers && r.isSuccess) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              netTr(
                context,
                'net_dns_no_answer_records',
                'No records in the answer section.',
              ),
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (r.authorities.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),
            Text(
              netTr(context, 'net_dns_authority', 'Authority'),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            for (final DnsAnswer a in r.authorities)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  '${a.typeName}  ${a.data}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _answerTile(DnsAnswer a, int index) {
    final String? priority = DnsEngine.extractPriority(a.data);
    final String display = DnsEngine.summarizeAnswer(a);

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
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: NetColors.accentA.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: NetColors.accentA.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  a.typeName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (priority != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: NetColors.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'pri $priority',
                    style: const TextStyle(
                      color: NetColors.warning,
                      fontSize: 9,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'TTL ${DnsEngine.formatTtl(a.ttl)}',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 9,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              NetIconButton(
                icon: Icons.copy_rounded,
                tooltip: netTr(context, 'net_copy', 'Copy'),
                onTap: () => netCopy(context, a.data),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            display,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkResultCard(Map<DnsRecordType, DnsResult> results) {
    final int totalRecords = results.values
        .fold<int>(0, (int sum, DnsResult r) => sum + r.answers.length);

    return NetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: NetSectionTitle(
                  Icons.list_alt_rounded,
                  netTr(context, 'net_dns_bulk_result', 'Bulk lookup'),
                ),
              ),
              NetStatusPill(
                label: '$totalRecords',
                color: NetColors.accentB,
                icon: Icons.article_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...results.entries.map((MapEntry<DnsRecordType, DnsResult> e) {
            final DnsResult r = e.value;
            final bool ok = r.isSuccess && r.hasAnswers;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: (ok ? NetColors.success : NetColors.warning)
                              .withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: (ok ? NetColors.success : NetColors.warning)
                                .withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          e.key.query,
                          style: TextStyle(
                            color: ok
                                ? NetColors.success
                                : NetColors.warning,
                            fontSize: 10,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        r.isSuccess
                            ? '${r.answers.length} record(s)'
                            : r.statusName,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${r.elapsedMs}ms',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  if (r.hasAnswers) ...<Widget>[
                    const SizedBox(height: 6),
                    for (final DnsAnswer a in r.answers)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child: SelectableText(
                          '· ${DnsEngine.summarizeAnswer(a)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'monospace',
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}