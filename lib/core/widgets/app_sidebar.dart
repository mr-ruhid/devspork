import 'package:flutter/material.dart';

import '../localization/app_localization.dart';
import '../sidebar/sidebar_controller.dart';
import '../sidebar/sidebar_plugin.dart';
import '../theme/app_ui_kit.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.selectedId,
    required this.onSelect,
  });

  final String? selectedId;
  final ValueChanged<SidebarPlugin> onSelect;

  static const double width = 72;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xFF0F0B24),
        border: Border(
          right: BorderSide(
            color: Colors.white.withOpacity(0.06),
          ),
        ),
      ),
      child: SafeArea(
        child: AnimatedBuilder(
          animation: SidebarController.instance,
          builder: (BuildContext context, Widget? _) {
            final SidebarController c = SidebarController.instance;
            final List<SidebarPlugin> top = c.visibleTop;
            final SidebarPlugin? bottom = c.pinnedBottom;

            final List<Widget> children = <Widget>[
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[kAccentA, kAccentB],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.terminal_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(height: 24),
            ];

            SidebarGroup? previous;
            for (final SidebarPlugin p in top) {
              if (previous != null && previous != p.group) {
                children.add(_Divider());
              }
              previous = p.group;
              children.add(
                _SidebarIcon(
                  icon: p.icon,
                  selected: selectedId == p.id,
                  tooltip: context.t(p.labelKey),
                  onTap: () => onSelect(p),
                ),
              );
            }

            children.add(const Spacer());

            if (bottom != null) {
              children.add(
                _SidebarIcon(
                  icon: bottom.icon,
                  selected: selectedId == bottom.id,
                  tooltip: context.t(bottom.labelKey),
                  onTap: () => onSelect(bottom),
                ),
              );
            }

            children.add(const SizedBox(height: 16));

            return Column(children: children);
          },
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: Colors.white.withOpacity(0.10),
    );
  }
}

class _SidebarIcon extends StatelessWidget {
  const _SidebarIcon({
    required this.icon,
    required this.selected,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? Colors.white.withOpacity(0.20)
                      : Colors.transparent,
                ),
              ),
              child: Icon(
                icon,
                size: 20,
                color: selected ? Colors.white : Colors.white60,
              ),
            ),
          ),
        ),
      ),
    );
  }
}