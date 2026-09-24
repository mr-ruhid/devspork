import 'package:flutter/material.dart';

import '../../scene/home.dart';
import '../../scene/settings.dart';
import '../../scene/sidebar_plugins/cache_cleaner.dart';
import '../../scene/sidebar_plugins/downloads.dart';
import '../../scene/sidebar_plugins/plugin_edit.dart';
import '../../scene/sidebar_plugins/web_view.dart';
import '../platform/platform_detector.dart';
import '../sidebar/sidebar_plugin.dart';
import 'app_sidebar.dart';
import 'edge_panel.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  String? _selectedId;

  Route<void> _routeFor(SidebarPlugin p) {
    switch (p.id) {
      case 'cache_cleaner':
        return MaterialPageRoute<void>(builder: (_) => const CacheCleaner());
      case 'plugin_edit':
        return MaterialPageRoute<void>(builder: (_) => const PluginEdit());
      case 'downloads':
        return MaterialPageRoute<void>(builder: (_) => const Downloads());
      case 'settings':
        return MaterialPageRoute<void>(builder: (_) => const Settings());
      default:
        final String? url = p.url;
        if (url != null) {
          return MaterialPageRoute<void>(
            builder: (_) => PluginWebView(title: p.labelKey, url: url),
          );
        }
        return MaterialPageRoute<void>(builder: (_) => const Home());
    }
  }

  void _onSelect(SidebarPlugin p) {
    final NavigatorState? nav = _navKey.currentState;
    if (nav == null) return;
    setState(() => _selectedId = p.id);
    nav.push(_routeFor(p));
  }

  @override
  Widget build(BuildContext context) {
    final AppSidebar sidebar = AppSidebar(
      selectedId: _selectedId,
      onSelect: _onSelect,
    );

    final Widget navigator = Navigator(
      key: _navKey,
      onGenerateRoute: (RouteSettings settings) => MaterialPageRoute<void>(
        builder: (_) => const Home(),
      ),
    );

    if (PlatformDetector.isDesktop) {
      return Row(children: <Widget>[sidebar, Expanded(child: navigator)]);
    }

    return EdgePanel(panel: sidebar, child: navigator);
  }
}