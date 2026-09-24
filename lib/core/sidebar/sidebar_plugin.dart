
import 'package:flutter/material.dart';

enum SidebarGroup {
  fixed,
  ai,
  social,
  cloud,
}

extension SidebarGroupX on SidebarGroup {
  String get id {
    switch (this) {
      case SidebarGroup.fixed:
        return 'fixed';
      case SidebarGroup.ai:
        return 'ai';
      case SidebarGroup.social:
        return 'social';
      case SidebarGroup.cloud:
        return 'cloud';
    }
  }

  String get labelKey {
    switch (this) {
      case SidebarGroup.fixed:
        return 'sidebar_group_fixed';
      case SidebarGroup.ai:
        return 'sidebar_group_ai';
      case SidebarGroup.social:
        return 'sidebar_group_social';
      case SidebarGroup.cloud:
        return 'sidebar_group_cloud';
    }
  }

  static SidebarGroup fromId(String id) {
    switch (id) {
      case 'ai':
        return SidebarGroup.ai;
      case 'social':
        return SidebarGroup.social;
      case 'cloud':
        return SidebarGroup.cloud;
      default:
        return SidebarGroup.fixed;
    }
  }
}

class SidebarPlugin {
  const SidebarPlugin({
    required this.id,
    required this.group,
    required this.icon,
    required this.labelKey,
    required this.defaultOrder,
    this.url,
    this.canHide = true,
    this.pinnedBottom = false,
  });

  final String id;
  final SidebarGroup group;
  final IconData icon;
  final String labelKey;
  final int defaultOrder;
  final String? url;
  final bool canHide;
  final bool pinnedBottom;
}