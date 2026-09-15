import 'package:flutter/material.dart';

import '../../core/localization/app_localization.dart';
import 'jsonld_tab.dart';
import 'meta_tab.dart';
import 'redirect_tab.dart';
import 'sitemap_tab.dart';
import 'ui_kit.dart';

class SeoPack extends StatefulWidget {
  const SeoPack({super.key});

  @override
  State<SeoPack> createState() => _SeoPackState();
}

class _SeoPackState extends State<SeoPack>
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
      backgroundColor: const Color(0xFF0A1929),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.t('seopack_title')),
        bottom: SeoTabBar(
          controller: _tabs,
          labels: <String>[
            seoTr(context, 'seo_tab_sitemap', 'Sitemap'),
            seoTr(context, 'seo_tab_redirect', 'Redirect'),
            seoTr(context, 'seo_tab_meta', 'Meta'),
            seoTr(context, 'seo_tab_jsonld', 'JSON-LD'),
          ],
        ),
      ),
      body: SeoScaffold(
        body: TabBarView(
          controller: _tabs,
          children: <Widget>[
            const SitemapTab(),
            const RedirectTab(),
            const MetaTab(),
            const JsonLdTab(),
          ],
        ),
      ),
    );
  }
}