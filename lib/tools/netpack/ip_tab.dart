import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ip_engine.dart';
import 'models.dart';
import 'ui_kit.dart';

class IpTab extends StatefulWidget {
  const IpTab({super.key});

  @override
  State<IpTab> createState() => _IpTabState();
}

class _IpTabState extends State<IpTab>
    with SingleTickerProviderStateMixin {
  late final TabController _subTabs;

  final TextEditingController _lookupCtrl = TextEditingController();

  final TextEditingController _cidrCtrl = TextEditingController();
  final TextEditingController _memberIpCtrl = TextEditingController();
  final TextEditingController _memberCidrCtrl = TextEditingController();

  final TextEditingController _convCtrl = TextEditingController();

  IpInfo? _ownInfo;
  IpInfo? _lookupInfo;
  String? _lookupErrorKey;
  String? _lookupErrorDetail;
  bool _lookupLoading = false;
  bool _ownLoading = false;

  SubnetInfo? _subnetInfo;
  String? _subnetErrorKey;
  String? _subnetErrorDetail;

  IpMembershipResult? _membershipResult;
  String? _memberErrorKey;
  String? _memberErrorDetail;

  String _convOutput = '';
  String? _convErrorKey;
  String? _convErrorDetail;
  String _convMode = 'int';

  bool _copiedOwnIp = false;

  @override
  void initState() {
    super.initState();
    _subTabs = TabController(length: 3, vsync: this);
    _cidrCtrl.text = '192.168.1.0/24';
    _memberIpCtrl.text = '192.168.1.42';
    _memberCidrCtrl.text = '192.168.1.0/24';
    _convCtrl.text = '192.168.1.1';
    _loadOwn();
    _parseCidr();
    _checkMembership();
    _convert();
  }

  @override
  void dispose() {
    _subTabs.dispose();
    _lookupCtrl.dispose();
    _cidrCtrl.dispose();
    _memberIpCtrl.dispose();
    _memberCidrCtrl.dispose();
    _convCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOwn() async {
    setState(() {
      _ownLoading = true;
    });
    try {
      final IpInfo info = await IpEngine.lookupOwn();
      if (!mounted) return;
      setState(() {
        _ownLoading = false;
        _ownInfo = info;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ownLoading = false;
      });
    }
  }

  Future<void> _lookupIp() async {
    final String ip = _lookupCtrl.text.trim();
    if (ip.isEmpty) {
      setState(() {
        _lookupErrorKey = NetErrors.ipEmpty;
        _lookupErrorDetail = null;
        _lookupInfo = null;
      });
      return;
    }

    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();

    setState(() {
      _lookupLoading = true;
      _lookupErrorKey = null;
      _lookupErrorDetail = null;
      _lookupInfo = null;
    });

    try {
      final IpInfo info = await IpEngine.lookupIp(ip);
      if (!mounted) return;
      setState(() {
        _lookupLoading = false;
        _lookupInfo = info;
      });
      HapticFeedback.lightImpact();
    } on IpException catch (e) {
      if (!mounted) return;
      setState(() {
        _lookupLoading = false;
        _lookupErrorKey = e.errorKey;
        _lookupErrorDetail = e.detail;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lookupLoading = false;
        _lookupErrorKey = NetErrors.ipServerError;
        _lookupErrorDetail = e.toString();
      });
    }
  }

  void _parseCidr() {
    final String cidr = _cidrCtrl.text.trim();
    if (cidr.isEmpty) {
      setState(() {
        _subnetInfo = null;
        _subnetErrorKey = null;
        _subnetErrorDetail = null;
      });
      return;
    }
    try {
      final SubnetInfo info = IpEngine.parseCidr(cidr);
      setState(() {
        _subnetInfo = info;
        _subnetErrorKey = null;
        _subnetErrorDetail = null;
      });
    } on IpException catch (e) {
      setState(() {
        _subnetInfo = null;
        _subnetErrorKey = e.errorKey;
        _subnetErrorDetail = e.detail;
      });
    } catch (e) {
      setState(() {
        _subnetInfo = null;
        _subnetErrorKey = NetErrors.ipInvalidCidr;
        _subnetErrorDetail = e.toString();
      });
    }
  }

  void _checkMembership() {
    final String ip = _memberIpCtrl.text.trim();
    final String cidr = _memberCidrCtrl.text.trim();
    if (ip.isEmpty || cidr.isEmpty) {
      setState(() {
        _membershipResult = null;
        _memberErrorKey = null;
        _memberErrorDetail = null;
      });
      return;
    }
    try {
      final IpMembershipResult r = IpEngine.checkMembership(
        ip: ip,
        cidr: cidr,
      );
      setState(() {
        _membershipResult = r;
        _memberErrorKey = null;
        _memberErrorDetail = null;
      });
    } on IpException catch (e) {
      setState(() {
        _membershipResult = null;
        _memberErrorKey = e.errorKey;
        _memberErrorDetail = e.detail;
      });
    } catch (e) {
      setState(() {
        _membershipResult = null;
        _memberErrorKey = NetErrors.ipInvalidCidr;
        _memberErrorDetail = e.toString();
      });
    }
  }

  void _convert() {
    final String input = _convCtrl.text.trim();
    if (input.isEmpty) {
      setState(() {
        _convOutput = '';
        _convErrorKey = null;
        _convErrorDetail = null;
      });
      return;
    }
    try {
      if (!IpEngine.isValidIpv4(input)) {
        throw IpException(
          NetErrors.ipInvalid,
          'Only IPv4 supported in the calculator',
        );
      }
      final int n = IpEngine.ipv4ToInt(input);
      final String binary = IpEngine.ipv4ToBinary(input);
      final String hex = IpEngine.ipv4ToHex(input);
      final String formatted = IpEngine.formatIntegerWithSeparators(n);
      final String cls = IpEngine.ipv4Class(input);
      final bool priv = IpEngine.isPrivateIp(input);

      setState(() {
        _convOutput = <String>[
          'ipv4: $input',
          'integer: $n',
          'formatted: $formatted',
          'binary: $binary',
          'hex: $hex',
          'class: $cls',
          'private: ${priv ? 'yes' : 'no'}',
        ].join('\n');
        _convErrorKey = null;
        _convErrorDetail = null;
      });
    } on IpException catch (e) {
      setState(() {
        _convOutput = '';
        _convErrorKey = e.errorKey;
        _convErrorDetail = e.detail;
      });
    } catch (e) {
      setState(() {
        _convOutput = '';
        _convErrorKey = NetErrors.ipInvalid;
        _convErrorDetail = e.toString();
      });
    }
  }

  Future<void> _copy(String text, {String? flag}) async {
    if (text.isEmpty) return;
    await netCopy(context, text);
    if (flag == 'ownIp' && mounted) {
      setState(() => _copiedOwnIp = true);
      Future<void>.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _copiedOwnIp = false);
      });
    }
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
                Tab(text: netTr(context, 'net_ip_sub_lookup', 'Lookup')),
                Tab(text: netTr(context, 'net_ip_sub_calc', 'Calculator')),
                Tab(text: netTr(context, 'net_ip_sub_convert', 'Convert')),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabs,
            children: <Widget>[
              _buildLookupView(),
              _buildCalcView(),
              _buildConvertView(),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // LOOKUP VIEW
  // ==========================================================================

  Widget _buildLookupView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildOwnIpCard(),
          const SizedBox(height: 14),
          _buildLookupCard(),
          if (_lookupErrorKey != null) ...<Widget>[
            const SizedBox(height: 14),
            NetErrorBox(
              errorKey: _lookupErrorKey!,
              detail: _lookupErrorDetail,
            ),
          ],
          if (_lookupInfo != null) ...<Widget>[
            const SizedBox(height: 14),
            _buildIpInfoCard(_lookupInfo!, title: 'Lookup result'),
          ],
        ],
      ),
    );
  }

  Widget _buildOwnIpCard() {
    return NetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: NetSectionTitle(
                  Icons.wifi_rounded,
                  netTr(context, 'net_ip_own', 'Your IP address'),
                ),
              ),
              NetIconButton(
                icon: Icons.refresh_rounded,
                tooltip: netTr(context, 'net_ip_refresh', 'Refresh'),
                onTap: _ownLoading ? null : _loadOwn,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_ownLoading)
            _buildSkeleton()
          else if (_ownInfo == null)
            Text(
              netTr(
                context,
                'net_ip_own_unavailable',
                'Could not fetch your IP. Check your internet connection.',
              ),
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            _buildIpInfoInline(_ownInfo!, own: true),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          height: 18,
          width: 180,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 12,
          width: 260,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildIpInfoInline(IpInfo info, {bool own = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: SelectableText(
                info.ip,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            NetStatusPill(
              label: info.version.display,
              color: info.version == IpVersion.v4
                  ? NetColors.accentA
                  : NetColors.accentB,
              icon: Icons.tag_rounded,
            ),
            if (own) ...<Widget>[
              const SizedBox(width: 6),
              NetIconButton(
                icon: _copiedOwnIp
                    ? Icons.check_rounded
                    : Icons.copy_rounded,
                tooltip: netTr(context, 'net_copy', 'Copy'),
                onTap: () => _copy(info.ip, flag: 'ownIp'),
                highlighted: _copiedOwnIp,
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        _infoGrid(info),
      ],
    );
  }

  Widget _buildLookupCard() {
    return NetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          NetSectionTitle(
            Icons.search_rounded,
            netTr(context, 'net_ip_lookup', 'Lookup any IP'),
          ),
          const SizedBox(height: 12),
          NetTextField(
            controller: _lookupCtrl,
            hint: '8.8.8.8 or 2001:4860:4860::8888',
            label: netTr(context, 'net_ip_address', 'IP address'),
            onSubmitted: (_) => _lookupIp(),
          ),
          const SizedBox(height: 12),
          NetPrimaryButton(
            icon: _lookupLoading
                ? Icons.hourglass_top_rounded
                : Icons.travel_explore_rounded,
            label: _lookupLoading
                ? netTr(context, 'net_ip_looking', 'Looking up…')
                : netTr(context, 'net_ip_lookup_action', 'Lookup'),
            onTap: _lookupLoading ? null : _lookupIp,
          ),
        ],
      ),
    );
  }

  Widget _buildIpInfoCard(IpInfo info, {required String title}) {
    return NetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: NetSectionTitle(
                  Icons.info_outline_rounded,
                  title,
                ),
              ),
              NetStatusPill(
                label: info.version.display,
                color: info.version == IpVersion.v4
                    ? NetColors.accentA
                    : NetColors.accentB,
                icon: Icons.tag_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            info.ip,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _infoGrid(info),
          if (info.mapUrl != null) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: NetColors.accentA.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: NetColors.accentA.withOpacity(0.4),
                ),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.place_outlined,
                    size: 16,
                    color: NetColors.accentA,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${info.latitude!.toStringAsFixed(4)}, ${info.longitude!.toStringAsFixed(4)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  NetIconButton(
                    icon: Icons.copy_rounded,
                    tooltip: netTr(context, 'net_copy', 'Copy'),
                    onTap: () => _copy(info.mapUrl!),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            netTr(
              context,
              'net_ip_source_note',
              'Data source: ipwho.is (free, no key required).',
            ),
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoGrid(IpInfo info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (info.country != null || info.countryCode != null)
          NetKeyValueRow(
            label: netTr(context, 'net_ip_country', 'Country'),
            value: <String>[
              if (info.country != null) info.country!,
              if (info.countryCode != null) '(${info.countryCode})',
            ].join(' '),
            monospaceValue: false,
          ),
        if (info.region != null)
          NetKeyValueRow(
            label: netTr(context, 'net_ip_region', 'Region'),
            value: info.region!,
            monospaceValue: false,
          ),
        if (info.city != null)
          NetKeyValueRow(
            label: netTr(context, 'net_ip_city', 'City'),
            value: info.city!,
            monospaceValue: false,
          ),
        if (info.postal != null)
          NetKeyValueRow(
            label: netTr(context, 'net_ip_postal', 'Postal code'),
            value: info.postal!,
          ),
        if (info.timezone != null)
          NetKeyValueRow(
            label: netTr(context, 'net_ip_timezone', 'Timezone'),
            value: info.timezone!,
          ),
        if (info.isp != null)
          NetKeyValueRow(
            label: netTr(context, 'net_ip_isp', 'ISP'),
            value: info.isp!,
            monospaceValue: false,
          ),
        if (info.org != null)
          NetKeyValueRow(
            label: netTr(context, 'net_ip_org', 'Organization'),
            value: info.org!,
            monospaceValue: false,
          ),
        if (info.asn != null)
          NetKeyValueRow(
            label: netTr(context, 'net_ip_asn', 'ASN'),
            value: 'AS${info.asn}',
          ),
      ],
    );
  }

  // ==========================================================================
  // CALCULATOR VIEW
  // ==========================================================================

  Widget _buildCalcView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildCidrCard(),
          if (_subnetErrorKey != null) ...<Widget>[
            const SizedBox(height: 14),
            NetErrorBox(
              errorKey: _subnetErrorKey!,
              detail: _subnetErrorDetail,
            ),
          ],
          if (_subnetInfo != null) ...<Widget>[
            const SizedBox(height: 14),
            _buildSubnetResultCard(_subnetInfo!),
          ],
          const SizedBox(height: 14),
          _buildMembershipCard(),
          if (_memberErrorKey != null) ...<Widget>[
            const SizedBox(height: 14),
            NetErrorBox(
              errorKey: _memberErrorKey!,
              detail: _memberErrorDetail,
            ),
          ],
          if (_membershipResult != null) ...<Widget>[
            const SizedBox(height: 14),
            _buildMembershipResultCard(_membershipResult!),
          ],
        ],
      ),
    );
  }

  Widget _buildCidrCard() {
    return NetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          NetSectionTitle(
            Icons.calculate_outlined,
            netTr(context, 'net_ip_cidr', 'CIDR / Subnet'),
          ),
          const SizedBox(height: 12),
          NetTextField(
            controller: _cidrCtrl,
            hint: '192.168.1.0/24',
            label: netTr(context, 'net_ip_cidr_input', 'CIDR notation'),
            onChanged: (_) => _parseCidr(),
            onSubmitted: (_) => _parseCidr(),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <String>[
              '10.0.0.0/8',
              '172.16.0.0/12',
              '192.168.1.0/24',
              '192.168.1.0/26',
              '100.64.0.0/10',
            ].map((String c) {
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _cidrCtrl.text = c);
                  _parseCidr();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                    ),
                  ),
                  child: Text(
                    c,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubnetResultCard(SubnetInfo info) {
    return NetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: NetSectionTitle(
                  Icons.hub_outlined,
                  netTr(context, 'net_ip_subnet_result', 'Subnet info'),
                ),
              ),
              NetStatusPill(
                label: 'Class ${info.ipClass}',
                color: NetColors.accentA,
              ),
            ],
          ),
          const SizedBox(height: 12),
          NetKeyValueRow(
            label: netTr(context, 'net_ip_network', 'Network'),
            value: info.networkAddress,
            copyValue: true,
            onCopy: () => _copy(info.networkAddress),
          ),
          NetKeyValueRow(
            label: netTr(context, 'net_ip_broadcast', 'Broadcast'),
            value: info.broadcastAddress,
            copyValue: true,
            onCopy: () => _copy(info.broadcastAddress),
          ),
          NetKeyValueRow(
            label: netTr(context, 'net_ip_first_host', 'First host'),
            value: info.firstHost,
          ),
          NetKeyValueRow(
            label: netTr(context, 'net_ip_last_host', 'Last host'),
            value: info.lastHost,
          ),
          NetKeyValueRow(
            label: netTr(context, 'net_ip_mask', 'Subnet mask'),
            value: info.subnetMask,
          ),
          NetKeyValueRow(
            label: netTr(context, 'net_ip_wildcard', 'Wildcard mask'),
            value: info.wildcardMask,
          ),
          NetKeyValueRow(
            label: netTr(context, 'net_ip_prefix', 'Prefix length'),
            value: '/${info.prefixLength}',
          ),
          NetKeyValueRow(
            label: netTr(context, 'net_ip_total', 'Total addresses'),
            value: IpEngine.formatIntegerWithSeparators(info.totalHosts),
          ),
          NetKeyValueRow(
            label: netTr(context, 'net_ip_usable', 'Usable hosts'),
            value: IpEngine.formatIntegerWithSeparators(info.usableHosts),
            valueColor: NetColors.success,
          ),
          NetKeyValueRow(
            label: netTr(context, 'net_ip_scope', 'Scope'),
            value: info.isPrivate ? 'Private (RFC 1918)' : 'Public',
            valueColor:
            info.isPrivate ? NetColors.warning : NetColors.accentB,
            monospaceValue: false,
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipCard() {
    return NetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          NetSectionTitle(
            Icons.rule_folder_outlined,
            netTr(context, 'net_ip_membership', 'Membership check'),
          ),
          const SizedBox(height: 12),
          NetTextField(
            controller: _memberIpCtrl,
            hint: '192.168.1.42',
            label: netTr(context, 'net_ip_address', 'IP address'),
            onChanged: (_) => _checkMembership(),
          ),
          const SizedBox(height: 10),
          NetTextField(
            controller: _memberCidrCtrl,
            hint: '192.168.1.0/24',
            label: netTr(context, 'net_ip_network_cidr', 'Network (CIDR)'),
            onChanged: (_) => _checkMembership(),
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipResultCard(IpMembershipResult r) {
    final Color color =
    r.contains ? NetColors.success : NetColors.danger;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            r.contains
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            color: color,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  r.contains
                      ? netTr(
                    context,
                    'net_ip_member_yes',
                    'IP is in the network',
                  )
                      : netTr(
                    context,
                    'net_ip_member_no',
                    'IP is outside the network',
                  ),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${r.ip}  ∈  ${r.cidr}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
                if (r.reason != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    r.reason!,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
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

  // ==========================================================================
  // CONVERT VIEW
  // ==========================================================================

  Widget _buildConvertView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          NetCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                NetSectionTitle(
                  Icons.swap_horiz_rounded,
                  netTr(context, 'net_ip_convert', 'IPv4 converter'),
                ),
                const SizedBox(height: 12),
                NetTextField(
                  controller: _convCtrl,
                  hint: '192.168.1.1',
                  label: netTr(context, 'net_ip_input', 'Input'),
                  onChanged: (_) => _convert(),
                  onSubmitted: (_) => _convert(),
                ),
                const SizedBox(height: 10),
                Text(
                  netTr(
                    context,
                    'net_ip_convert_hint',
                    'Enter an IPv4 address to see its integer, binary, and hex representations.',
                  ),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (_convErrorKey != null) ...<Widget>[
            const SizedBox(height: 14),
            NetErrorBox(
              errorKey: _convErrorKey!,
              detail: _convErrorDetail,
            ),
          ],
          if (_convOutput.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            NetCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  NetSectionTitle(
                    Icons.data_object_rounded,
                    netTr(context, 'net_ip_convert_result', 'Result'),
                  ),
                  const SizedBox(height: 12),
                  ..._convOutput.split('\n').map((String line) {
                    final int colon = line.indexOf(':');
                    if (colon <= 0) {
                      return const SizedBox.shrink();
                    }
                    final String key = line.substring(0, colon);
                    final String value = line.substring(colon + 1).trim();
                    return NetKeyValueRow(
                      label: key,
                      value: value,
                      labelWidth: 100,
                      copyValue: true,
                      onCopy: () => _copy(value),
                    );
                  }),
                  const SizedBox(height: 12),
                  NetPrimaryButton(
                    icon: Icons.copy_rounded,
                    label: netTr(context, 'net_ip_copy_all', 'Copy all'),
                    onTap: () => _copy(_convOutput),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}