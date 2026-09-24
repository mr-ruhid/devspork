
import 'package:flutter/foundation.dart';

import 'sidebar_plugin.dart';
import 'sidebar_preferences.dart';
import 'sidebar_registry.dart';

class SidebarController extends ChangeNotifier {
  SidebarController._();

  static final SidebarController instance = SidebarController._();

  bool _initialized = false;
  List<SidebarPlugin> _ordered = <SidebarPlugin>[];
  Set<String> _disabledIds = <String>{};

  bool get initialized => _initialized;

  List<SidebarPlugin> get all =>
      List<SidebarPlugin>.unmodifiable(_ordered);

  List<SidebarPlugin> get visibleTop => _ordered
      .where((SidebarPlugin p) =>
  !p.pinnedBottom && !_disabledIds.contains(p.id))
      .toList(growable: false);

  SidebarPlugin? get pinnedBottom {
    for (final SidebarPlugin p in _ordered) {
      if (p.pinnedBottom) return p;
    }
    return null;
  }

  bool isEnabled(String id) => !_disabledIds.contains(id);

  Future<void> init() async {
    if (_initialized) return;
    final Set<String> disabled = await SidebarPreferences.loadDisabledIds();
    final List<String> order = await SidebarPreferences.loadOrder();
    _disabledIds = disabled;
    _ordered = _applyOrder(order);
    _initialized = true;
    notifyListeners();
  }

  List<SidebarPlugin> _applyOrder(List<String> order) {
    final Map<String, SidebarPlugin> byId = <String, SidebarPlugin>{
      for (final SidebarPlugin p in sidebarRegistry) p.id: p,
    };
    final List<SidebarPlugin> result = <SidebarPlugin>[];
    final Set<String> used = <String>{};
    for (final String id in order) {
      final SidebarPlugin? p = byId[id];
      if (p != null && !used.contains(id)) {
        result.add(p);
        used.add(id);
      }
    }
    final List<SidebarPlugin> remaining = sidebarRegistry
        .where((SidebarPlugin p) => !used.contains(p.id))
        .toList()
      ..sort((SidebarPlugin a, SidebarPlugin b) =>
          a.defaultOrder.compareTo(b.defaultOrder));
    result.addAll(remaining);
    return result;
  }

  Future<void> toggle(String id) async {
    final SidebarPlugin? p = _byId(id);
    if (p == null || !p.canHide) return;
    if (_disabledIds.contains(id)) {
      _disabledIds.remove(id);
    } else {
      _disabledIds.add(id);
    }
    await SidebarPreferences.saveDisabledIds(_disabledIds);
    notifyListeners();
  }

  Future<void> reorderWithinGroup(
      SidebarGroup group,
      int oldIndex,
      int newIndex,
      ) async {
    final List<SidebarPlugin> groupItems = _ordered
        .where((SidebarPlugin p) => p.group == group && !p.pinnedBottom)
        .toList();
    if (oldIndex < 0 || oldIndex >= groupItems.length) return;
    if (newIndex < 0 || newIndex >= groupItems.length) return;
    if (oldIndex == newIndex) return;

    final SidebarPlugin moved = groupItems.removeAt(oldIndex);
    groupItems.insert(newIndex, moved);

    final List<SidebarPlugin> newOrdered = <SidebarPlugin>[];
    int cursor = 0;
    for (final SidebarPlugin p in _ordered) {
      if (p.group == group && !p.pinnedBottom) {
        newOrdered.add(groupItems[cursor++]);
      } else {
        newOrdered.add(p);
      }
    }
    _ordered = newOrdered;
    await SidebarPreferences.saveOrder(
      _ordered.map((SidebarPlugin p) => p.id).toList(),
    );
    notifyListeners();
  }

  Future<void> reset() async {
    await SidebarPreferences.clear();
    _disabledIds = <String>{};
    _ordered = _applyOrder(<String>[]);
    notifyListeners();
  }

  SidebarPlugin? _byId(String id) {
    for (final SidebarPlugin p in _ordered) {
      if (p.id == id) return p;
    }
    return null;
  }
}