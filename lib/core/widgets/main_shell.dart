import 'package:flutter/material.dart';

import '../platform/platform_detector.dart';
import 'app_sidebar.dart';
import 'edge_panel.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  void _onSelect(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final AppSidebar sidebar = AppSidebar(
      selectedIndex: _selectedIndex,
      onSelect: _onSelect,
    );

    if (PlatformDetector.isDesktop) {
      return Row(
        children: <Widget>[
          sidebar,
          Expanded(child: widget.child),
        ],
      );
    }

    return EdgePanel(
      panel: sidebar,
      child: widget.child,
    );
  }
}