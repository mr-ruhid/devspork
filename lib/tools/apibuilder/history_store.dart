import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class HistoryStore {
  HistoryStore._();

  static const String _key = 'devspork_apibuilder_history_v1';
  static const int _maxEntries = 100;

  static List<HistoryEntry> _cache = <HistoryEntry>[];
  static bool _loaded = false;

  static Future<List<HistoryEntry>> load() async {
    if (_loaded) return List<HistoryEntry>.from(_cache);

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) {
        _cache = <HistoryEntry>[];
        _loaded = true;
        return <HistoryEntry>[];
      }

      final dynamic decoded = jsonDecode(raw);
      if (decoded is! List) {
        _cache = <HistoryEntry>[];
        _loaded = true;
        return <HistoryEntry>[];
      }

      final List<HistoryEntry> entries = <HistoryEntry>[];
      for (final dynamic item in decoded) {
        if (item is Map<String, dynamic>) {
          try {
            entries.add(HistoryEntry.fromJson(item));
          } catch (_) {}
        }
      }

      entries.sort((HistoryEntry a, HistoryEntry b) =>
          b.timestamp.compareTo(a.timestamp));

      _cache = entries;
      _loaded = true;
      return List<HistoryEntry>.from(_cache);
    } catch (_) {
      _cache = <HistoryEntry>[];
      _loaded = true;
      return <HistoryEntry>[];
    }
  }

  static Future<void> add(HistoryEntry entry) async {
    if (!_loaded) await load();

    _cache.insert(0, entry);

    if (_cache.length > _maxEntries) {
      _cache = _cache.sublist(0, _maxEntries);
    }

    await _persist();
  }

  static Future<void> removeByTimestamp(DateTime timestamp) async {
    if (!_loaded) await load();
    _cache.removeWhere(
          (HistoryEntry e) => e.timestamp.isAtSameMomentAs(timestamp),
    );
    await _persist();
  }

  static Future<void> removeAt(int index) async {
    if (!_loaded) await load();
    if (index < 0 || index >= _cache.length) return;
    _cache.removeAt(index);
    await _persist();
  }

  static Future<void> clear() async {
    _cache = <HistoryEntry>[];
    _loaded = true;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }

  static Future<void> _persist() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String raw = jsonEncode(
        _cache.map((HistoryEntry e) => e.toJson()).toList(),
      );
      await prefs.setString(_key, raw);
    } catch (_) {}
  }

  static List<HistoryEntry> get cached => List<HistoryEntry>.from(_cache);

  static bool get isLoaded => _loaded;

  static Future<void> reload() async {
    _loaded = false;
    _cache = <HistoryEntry>[];
    await load();
  }
}

class CollectionsStore {
  CollectionsStore._();

  static const String _key = 'devspork_apibuilder_collections_v1';
  static const int _maxCollections = 200;

  static List<SavedRequest> _cache = <SavedRequest>[];
  static bool _loaded = false;

  static Future<List<SavedRequest>> load() async {
    if (_loaded) return List<SavedRequest>.from(_cache);

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) {
        _cache = <SavedRequest>[];
        _loaded = true;
        return <SavedRequest>[];
      }

      final dynamic decoded = jsonDecode(raw);
      if (decoded is! List) {
        _cache = <SavedRequest>[];
        _loaded = true;
        return <SavedRequest>[];
      }

      final List<SavedRequest> items = <SavedRequest>[];
      for (final dynamic item in decoded) {
        if (item is Map<String, dynamic>) {
          try {
            items.add(SavedRequest.fromJson(item));
          } catch (_) {}
        }
      }

      items.sort((SavedRequest a, SavedRequest b) =>
          b.savedAt.compareTo(a.savedAt));

      _cache = items;
      _loaded = true;
      return List<SavedRequest>.from(_cache);
    } catch (_) {
      _cache = <SavedRequest>[];
      _loaded = true;
      return <SavedRequest>[];
    }
  }

  static Future<void> save(SavedRequest saved) async {
    if (!_loaded) await load();

    final int existingIndex =
    _cache.indexWhere((SavedRequest s) => s.id == saved.id);
    if (existingIndex != -1) {
      _cache[existingIndex] = saved;
    } else {
      _cache.insert(0, saved);
      if (_cache.length > _maxCollections) {
        _cache = _cache.sublist(0, _maxCollections);
      }
    }

    await _persist();
  }

  static Future<void> remove(String id) async {
    if (!_loaded) await load();
    _cache.removeWhere((SavedRequest s) => s.id == id);
    await _persist();
  }

  static Future<void> removeAt(int index) async {
    if (!_loaded) await load();
    if (index < 0 || index >= _cache.length) return;
    _cache.removeAt(index);
    await _persist();
  }

  static Future<void> clear() async {
    _cache = <SavedRequest>[];
    _loaded = true;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }

  static Future<void> _persist() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String raw = jsonEncode(
        _cache.map((SavedRequest s) => s.toJson()).toList(),
      );
      await prefs.setString(_key, raw);
    } catch (_) {}
  }

  static List<SavedRequest> get cached => List<SavedRequest>.from(_cache);

  static bool get isLoaded => _loaded;
}

class SavedRequest {
  final String id;
  final String name;
  final ApiRequest request;
  final DateTime savedAt;

  SavedRequest({
    String? id,
    required this.name,
    required this.request,
    DateTime? savedAt,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        savedAt = savedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'request': request.toJson(),
    'savedAt': savedAt.toIso8601String(),
  };

  factory SavedRequest.fromJson(Map<String, dynamic> j) => SavedRequest(
    id: j['id']?.toString(),
    name: j['name']?.toString() ?? '',
    request: ApiRequest.fromJson(
      (j['request'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    ),
    savedAt: DateTime.tryParse(j['savedAt']?.toString() ?? '') ??
        DateTime.now(),
  );

  SavedRequest copyWith({String? name, ApiRequest? request}) => SavedRequest(
    id: id,
    name: name ?? this.name,
    request: request ?? this.request,
    savedAt: savedAt,
  );
}