import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalization extends ChangeNotifier {
  AppLocalization._();
  static final AppLocalization instance = AppLocalization._();

  static const List<Locale> supportedLocales = <Locale>[
    Locale('az'),
    Locale('en'),
    Locale('ru'),
  ];

  Locale _locale = const Locale('az');
  Map<String, String> _translations = <String, String>{};

  Locale get locale => _locale;
  Map<String, String> get translations => _translations;

  Future<void> init() async {
    await _load(_locale);
  }

  Future<void> changeLocale(String languageCode) async {
    if (languageCode == _locale.languageCode) return;
    await _load(Locale(languageCode));
  }

  Future<void> _load(Locale locale) async {
    final String raw =
    await rootBundle.loadString('assets/lang/${locale.languageCode}.json');
    final Map<String, dynamic> decoded =
    json.decode(raw) as Map<String, dynamic>;
    _translations = decoded.map(
          (String key, dynamic value) =>
          MapEntry<String, String>(key, value.toString()),
    );
    _locale = locale;
    notifyListeners();
  }

  String translate(String key) {
    return _translations[key] ?? key;
  }
}

extension AppLocalizationX on BuildContext {
  String t(String key) => AppLocalization.instance.translate(key);
}