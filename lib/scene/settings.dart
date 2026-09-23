import 'package:flutter/material.dart';

import '../core/localization/app_localization.dart';
import '../core/theme/app_ui_kit.dart';
import '../core/widgets/app_header.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: kScaffoldBg,
      appBar: const AppHeader(showBack: true),
      body: GlassBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: kToolbarHeight),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: <Widget>[
                _SectionTitle(title: context.t('settings_general')),
                _SettingsTile(
                  icon: Icons.language,
                  title: context.t('settings_language'),
                  subtitle: context.t('settings_language_desc'),
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.dark_mode_outlined,
                  title: context.t('settings_theme'),
                  subtitle: context.t('settings_theme_desc'),
                  onTap: () {},
                ),
                const SizedBox(height: 16),
                _SectionTitle(title: context.t('settings_about')),
                _SettingsTile(
                  icon: Icons.info_outline,
                  title: context.t('settings_version'),
                  subtitle: 'DevSpork',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        title,
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

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: EdgeInsets.zero,
        radius: 14,
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: Colors.white70),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: Colors.white38,
          ),
        ),
      ),
    );
  }
}