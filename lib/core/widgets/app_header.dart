import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../localization/app_localization.dart';
import '../platform/platform_detector.dart';
import '../platform/window_controls.dart';
import '../theme/app_ui_kit.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.actions = const <Widget>[],
    this.showBack = false,
    this.showSearch = true,
    this.showHelp = true,
  });

  final List<Widget> actions;
  final bool showBack;
  final bool showSearch;
  final bool showHelp;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final Widget bar = GlassAppBar(
      leading: showBack
          ? GlassIconButton(
        icon: Icons.arrow_back,
        tooltip: context.t('common_back'),
        onTap: () => Navigator.of(context).maybePop(),
      )
          : null,
      titleWidget:
      showSearch ? const _FakeSearchBar() : const SizedBox.shrink(),
      actions: <Widget>[
        ...actions,
        if (showHelp)
          GlassIconButton(
            icon: Icons.help_outline_rounded,
            tooltip: context.t('common_help'),
            onTap: () {},
          ),
        const SizedBox(width: 8),
        const WindowControls(),
      ],
    );

    if (PlatformDetector.isDesktop) {
      return DragToMoveArea(child: bar);
    }
    return bar;
  }
}

class _FakeSearchBar extends StatelessWidget {
  const _FakeSearchBar();

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          height: 38,
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withOpacity(0.10),
            ),
          ),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.search,
                size: 16,
                color: Colors.white54,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.t('header_search_hint'),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}