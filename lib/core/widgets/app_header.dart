import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../localization/app_localization.dart';
import '../platform/platform_detector.dart';
import '../platform/window_controls.dart';
import '../theme/app_ui_kit.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.onSettingsTap,
    this.actions = const <Widget>[],
    this.showBack = false,
  });

  final VoidCallback? onSettingsTap;
  final List<Widget> actions;
  final bool showBack;

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
      title: context.t('home_title'),
      actions: <Widget>[
        ...actions,
        GlassIconButton(
          icon: Icons.settings_outlined,
          tooltip: context.t('home_settings'),
          onTap: onSettingsTap ?? () {},
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