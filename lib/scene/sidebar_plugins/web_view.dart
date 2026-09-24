
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/localization/app_localization.dart';
import '../../core/theme/app_ui_kit.dart';
import '../../core/widgets/app_header.dart';

class PluginWebView extends StatefulWidget {
  const PluginWebView({
    super.key,
    required this.title,
    required this.url,
  });

  final String title;
  final String url;

  @override
  State<PluginWebView> createState() => _PluginWebViewState();
}

class _PluginWebViewState extends State<PluginWebView> {
  late final WebViewController _controller;
  bool _loading = true;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(kScaffoldBg)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _loading = true;
              _progress = 0;
            });
          },
          onProgress: (int value) {
            if (!mounted) return;
            setState(() => _progress = value);
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: kScaffoldBg,
      appBar: AppHeader(
        showBack: true,
        showSearch: false,
        showHelp: false,
        actions: <Widget>[
          GlassIconButton(
            icon: Icons.refresh_rounded,
            tooltip: context.t('common_refresh'),
            onTap: () => _controller.reload(),
          ),
        ],
      ),
      body: GlassBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: kToolbarHeight),
            child: Column(
              children: <Widget>[
                if (_loading)
                  LinearProgressIndicator(
                    value: _progress / 100,
                    backgroundColor: Colors.white10,
                    color: kAccentB,
                    minHeight: 2,
                  ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(0),
                    child: WebViewWidget(controller: _controller),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}