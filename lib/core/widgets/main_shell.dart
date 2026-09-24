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
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  SidebarPlugin? _selected;

  void _onSelect(SidebarPlugin plugin) {
    if (_selected?.id == plugin.id) return;
    setState(() => _selected = plugin);
  }

  Widget _buildContent() {
    final SidebarPlugin? p = _selected;
    if (p == null) {
      return widget.child is Home ? widget.child : const Home();
    }
    switch (p.id) {
      case 'cache_cleaner':
        return const CacheCleaner();
      case 'plugin_edit':
        return const PluginEdit();
      case 'downloads':
        return const Downloads();
      case 'settings':
        return const Settings();
      default:
        if (p.url != null) {
          return PluginWebView(
            title: p.labelKey,
            url: p.url!,
          );
        }
        return widget.child is Home ? widget.child : const Home();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppSidebar sidebar = AppSidebar(
      selectedId: _selected?.id,
      onSelect: _onSelect,
    );

    final Widget content = _buildContent();

    if (PlatformDetector.isDesktop) {
      return Row(
        children: <Widget>[
          sidebar,
          Expanded(child: content),
        ],
      );
    }

    return EdgePanel(
      panel: sidebar,
      child: content,
    );
  }
}