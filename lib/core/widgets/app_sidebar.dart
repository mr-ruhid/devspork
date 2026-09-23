import 'package:flutter/material.dart';

import '../localization/app_localization.dart';
import '../theme/app_ui_kit.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const double width = 240;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        border: Border(
          right: BorderSide(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: <Color>[Color(0xFF7C4DFF), Color(0xFF00E5FF)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.terminal_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'DevSpork',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SidebarItem(
              icon: Icons.home_rounded,
              label: context.t('sidebar_home'),
              selected: selectedIndex == 0,
              onTap: () => onSelect(0),
            ),
            _SidebarItem(
              icon: Icons.grid_view_rounded,
              label: context.t('sidebar_tools'),
              selected: selectedIndex == 1,
              onTap: () => onSelect(1),
            ),
            _SidebarItem(
              icon: Icons.star_rounded,
              label: context.t('sidebar_favorites'),
              selected: selectedIndex == 2,
              onTap: () => onSelect(2),
            ),
            _SidebarItem(
              icon: Icons.history_rounded,
              label: context.t('sidebar_history'),
              selected: selectedIndex == 3,
              onTap: () => onSelect(3),
            ),
            const Spacer(),
            _SidebarItem(
              icon: Icons.settings_outlined,
              label: context.t('sidebar_settings'),
              selected: selectedIndex == 4,
              onTap: () => onSelect(4),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? Colors.white.withOpacity(0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? Colors.white.withOpacity(0.18)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  icon,
                  size: 18,
                  color: selected ? Colors.white : Colors.white60,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontSize: 13.5,
                      fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w500,
                    ),
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