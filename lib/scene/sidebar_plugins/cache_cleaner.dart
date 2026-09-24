import 'package:flutter/material.dart';

import '../../core/localization/app_localization.dart';
import '../../core/theme/app_ui_kit.dart';
import '../../core/widgets/app_header.dart';

class CacheCleaner extends StatelessWidget {
  const CacheCleaner({super.key});

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
                  context.t('cache_cleaner_title'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.t('cache_cleaner_subtitle'),
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  radius: 16,
                  child: Column(
                    children: <Widget>[
                      const Icon(
                        Icons.cleaning_services_rounded,
                        color: kAccentB,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.t('cache_cleaner_placeholder'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
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