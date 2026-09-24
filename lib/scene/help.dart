import 'package:flutter/material.dart';

import '../core/localization/app_localization.dart';
import '../core/theme/app_ui_kit.dart';
import '../core/widgets/app_header.dart';

class Help extends StatelessWidget {
  const Help({super.key});

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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: <Widget>[
                Text(
                  context.t('help_title'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.t('help_subtitle'),
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                _HelpSection(
                  icon: Icons.rocket_launch_rounded,
                  title: context.t('help_getting_started'),
                  body: context.t('help_getting_started_body'),
                ),
                const SizedBox(height: 12),
                _HelpSection(
                  icon: Icons.quiz_outlined,
                  title: context.t('help_faq'),
                  body: context.t('help_faq_body'),
                ),
                const SizedBox(height: 12),
                _HelpSection(
                  icon: Icons.mail_outline_rounded,
                  title: context.t('help_contact'),
                  body: context.t('help_contact_body'),
                ),
                const SizedBox(height: 12),
                _HelpSection(
                  icon: Icons.info_outline_rounded,
                  title: context.t('help_about'),
                  body: context.t('help_about_body'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      radius: 14,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[kAccentA, kAccentB],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}