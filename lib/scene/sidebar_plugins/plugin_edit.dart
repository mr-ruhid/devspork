import 'package:flutter/material.dart';

import '../../core/localization/app_localization.dart';
import '../../core/sidebar/sidebar_controller.dart';
import '../../core/sidebar/sidebar_plugin.dart';
import '../../core/theme/app_ui_kit.dart';
import '../../core/widgets/app_header.dart';

class PluginEdit extends StatelessWidget {
  const PluginEdit({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: kScaffoldBg,
      appBar: const AppHeader(
        showBack: true,
        showSearch: false,
        showHelp: false,
      ),
      body: GlassBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: kToolbarHeight),
            child: AnimatedBuilder(
              animation: SidebarController.instance,
              builder: (BuildContext context, Widget? _) {
                final List<SidebarPlugin> all =
                    SidebarController.instance.all;
                final Map<SidebarGroup, List<SidebarPlugin>> grouped =
                <SidebarGroup, List<SidebarPlugin>>{};
                for (final SidebarPlugin p in all) {
                  grouped.putIfAbsent(p.group, () => <SidebarPlugin>[]).add(p);
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: <Widget>[
                    Text(
                      context.t('plugin_edit_title'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.t('plugin_edit_subtitle'),
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),
                    for (final SidebarGroup group in SidebarGroup.values)
                      if (grouped[group] != null) ...<Widget>[
                        _GroupHeader(group: group),
                        const SizedBox(height: 8),
                        for (final SidebarPlugin p in grouped[group]!)
                          _PluginRow(plugin: p),
                        const SizedBox(height: 20),
                      ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group});

  final SidebarGroup group;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      child: Text(
        context.t(group.labelKey),
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _PluginRow extends StatelessWidget {
  const _PluginRow({required this.plugin});

  final SidebarPlugin plugin;

  @override
  Widget build(BuildContext context) {
    final SidebarController c = SidebarController.instance;
    final bool enabled = c.isEnabled(plugin.id);
    final bool locked = !plugin.canHide;
    final bool pinned = plugin.pinnedBottom;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: EdgeInsets.zero,
        radius: 12,
        child: ListTile(
          leading: Icon(plugin.icon, color: Colors.white70),
          title: Text(
            context.t(plugin.labelKey),
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          trailing: pinned
              ? const Icon(
            Icons.push_pin_rounded,
            size: 18,
            color: Colors.white38,
          )
              : Transform.scale(
            scale: 0.85,
            child: Switch(
              value: locked ? true : enabled,
              activeThumbColor: kAccentA,
              onChanged: locked
                  ? null
                  : (_) => c.toggle(plugin.id),
            ),
          ),
        ),
      ),
    );
  }
}