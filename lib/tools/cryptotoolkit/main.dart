import 'package:flutter/material.dart';

import '../../core/localization/app_localization.dart';
import 'aes_tab.dart';
import 'hmac_tab.dart';
import 'models.dart';
import 'oauth_tab.dart';
import 'sri_tab.dart';
import 'ui_kit.dart';

class CryptoToolkit extends StatefulWidget {
  const CryptoToolkit({super.key});

  @override
  State<CryptoToolkit> createState() => _CryptoToolkitState();
}

class _CryptoToolkitState extends State<CryptoToolkit>
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
      backgroundColor: const Color(0xFF0B0B12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.t('cryptotoolkit_title')),
        bottom: GlassTabBar(
          controller: _tabs,
          labels: <String>[
            ctkTr(context, 'ctk_tab_hmac', 'HMAC'),
            ctkTr(context, 'ctk_tab_aes', 'AES'),
            ctkTr(context, 'ctk_tab_sri', 'SRI'),
            ctkTr(context, 'ctk_tab_oauth', 'OAuth'),
          ],
        ),
      ),
      body: GlassTabScaffold(
        body: TabBarView(
          controller: _tabs,
          children: const <Widget>[
            HmacTab(),
            AesTab(),
            SriTab(),
            OAuthTab(),
          ],
        ),
      ),
    );
  }
}