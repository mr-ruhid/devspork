import 'package:shared_preferences/shared_preferences.dart';

class SidebarPreferences {
  SidebarPreferences._();

  static const String _kDisabledIds = 'sidebar_disabled_ids';
  static const String _kOrder = 'sidebar_order';

  static Future<Set<String>> loadDisabledIds() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> list =
        prefs.getStringList(_kDisabledIds) ?? <String>[];
    return list.toSet();
  }

  static Future<void> saveDisabledIds(Set<String> ids) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kDisabledIds, ids.toList());
  }

  static Future<List<String>> loadOrder() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kOrder) ?? <String>[];
  }

  static Future<void> saveOrder(List<String> ids) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kOrder, ids);
  }

  static Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kDisabledIds);
    await prefs.remove(_kOrder);
  }
}