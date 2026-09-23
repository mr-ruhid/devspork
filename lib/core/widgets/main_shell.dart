import 'package:flutter/material.dart';

import '../../scene/home.dart';
import '../../scene/settings.dart';
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
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const Home()),
              (Route<dynamic> route) => false,
        );
        break;
      case 4:
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const Settings()),
        );
        break;
      default:
        setState(() => _selectedIndex = index);
        return;
    }
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