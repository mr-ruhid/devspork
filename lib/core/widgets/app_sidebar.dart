import 'package:flutter/material.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

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
        child: Column(
          children: <Widget>[
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF7C4DFF), Color(0xFF00E5FF)],
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
            _SidebarIcon(
              icon: Icons.home_rounded,
              selected: selectedIndex == 0,
              onTap: () => onSelect(0),
            ),
            _SidebarIcon(
              icon: Icons.grid_view_rounded,
              selected: selectedIndex == 1,
              onTap: () => onSelect(1),
            ),
            _SidebarIcon(
              icon: Icons.star_rounded,
              selected: selectedIndex == 2,
              onTap: () => onSelect(2),
            ),
            _SidebarIcon(
              icon: Icons.history_rounded,
              selected: selectedIndex == 3,
              onTap: () => onSelect(3),
            ),
            const Spacer(),
            _SidebarIcon(
              icon: Icons.settings_outlined,
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

class _SidebarIcon extends StatelessWidget {
  const _SidebarIcon({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
    );
  }
}