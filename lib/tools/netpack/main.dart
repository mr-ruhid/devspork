import 'package:flutter/material.dart';

import '../../core/localization/app_localization.dart';
import 'dns_tab.dart';
import 'ip_tab.dart';
import 'models.dart';
import 'status_tab.dart';
import 'ui_kit.dart';
import 'ws_tab.dart';

class NetPack extends StatefulWidget {
  const NetPack({super.key});

  @override
  State<NetPack> createState() => _NetPackState();
}

class _NetPackState extends State<NetPack>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: NetColors.bgBot,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.t('netpack_title')),
        bottom: NetTabBar(
          controller: _tabs,
          labels: <String>[
            netTr(context, 'net_tab_dns', 'DNS'),
            netTr(context, 'net_tab_ip', 'IP'),
            netTr(context, 'net_tab_status', 'Status'),
            netTr(context, 'net_tab_ws', 'WS'),
          ],
        ),
      ),
      body: NetScaffold(
        body: TabBarView(
          controller: _tabs,
          children: const <Widget>[
            DnsTab(),
            IpTab(),
            StatusTab(),
            WsTab(),
          ],
        ),
      ),
    );
  }
}