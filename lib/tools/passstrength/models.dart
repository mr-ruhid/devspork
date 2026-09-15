import 'package:flutter/material.dart';

enum StrengthLevel { veryWeak, weak, fair, strong, veryStrong }

extension StrengthLevelX on StrengthLevel {
  String get labelKey {
    switch (this) {
      case StrengthLevel.veryWeak:
        return 'passstrength_level_very_weak';
      case StrengthLevel.weak:
        return 'passstrength_level_weak';
      case StrengthLevel.fair:
        return 'passstrength_level_fair';
      case StrengthLevel.strong:
        return 'passstrength_level_strong';
      case StrengthLevel.veryStrong:
        return 'passstrength_level_very_strong';
    }
  }

  Color get color {
    switch (this) {
      case StrengthLevel.veryWeak:
        return const Color(0xFFFF3B30);
      case StrengthLevel.weak:
        return const Color(0xFFFF9500);
      case StrengthLevel.fair:
        return const Color(0xFFFFCC00);
      case StrengthLevel.strong:
        return const Color(0xFF34C759);
      case StrengthLevel.veryStrong:
        return const Color(0xFF00C7BE);
    }
  }

  static StrengthLevel fromScore(int score) {
    switch (score) {
      case 0:
        return StrengthLevel.veryWeak;
      case 1:
        return StrengthLevel.weak;
      case 2:
        return StrengthLevel.fair;
      case 3:
        return StrengthLevel.strong;
      default:
        return StrengthLevel.veryStrong;
    }
  }
}

class CrackTimeEstimate {
  const CrackTimeEstimate({
    required this.offlineFastHashing,
    required this.offlineSlowHashing,
    required this.onlineNoThrottle,
    required this.onlineThrottle,
  });

  final String offlineFastHashing;
  final String offlineSlowHashing;
  final String onlineNoThrottle;
  final String onlineThrottle;
}

class PatternMatch {
  const PatternMatch({
    required this.pattern,
    required this.token,
    required this.description,
  });

  final String pattern;
  final String token;
  final String description;
}

class StrengthResult {
  const StrengthResult({
    required this.password,
    required this.score,
    required this.guesses,
    required this.guessesLog10,
    required this.crackTimes,
    required this.feedbackWarning,
    required this.feedbackSuggestions,
    required this.patterns,
    this.isBreached,
    this.breachCount,
  });

  final String password;
  final int score;
  final double guesses;
  final double guessesLog10;
  final CrackTimeEstimate crackTimes;
  final String? feedbackWarning;
  final List<String> feedbackSuggestions;
  final List<PatternMatch> patterns;
  final bool? isBreached;
  final int? breachCount;

  StrengthLevel get level => StrengthLevelX.fromScore(score);

  bool get hasFeedback =>
      (feedbackWarning != null && feedbackWarning!.isNotEmpty) ||
          feedbackSuggestions.isNotEmpty;

  StrengthResult copyWith({
    bool? isBreached,
    int? breachCount,
  }) {
    return StrengthResult(
      password: password,
      score: score,
      guesses: guesses,
      guessesLog10: guessesLog10,
      crackTimes: crackTimes,
      feedbackWarning: feedbackWarning,
      feedbackSuggestions: feedbackSuggestions,
      patterns: patterns,
      isBreached: isBreached ?? this.isBreached,
      breachCount: breachCount ?? this.breachCount,
    );
  }
}

class GeneratorOptions {
  const GeneratorOptions({
    this.length = 20,
    this.includeUppercase = true,
    this.includeLowercase = true,
    this.includeDigits = true,
    this.includeSymbols = true,
    this.excludeAmbiguous = false,
    this.customSymbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?',
  });

  final int length;
  final bool includeUppercase;
  final bool includeLowercase;
  final bool includeDigits;
  final bool includeSymbols;
  final bool excludeAmbiguous;
  final String customSymbols;

  GeneratorOptions copyWith({
    int? length,
    bool? includeUppercase,
    bool? includeLowercase,
    bool? includeDigits,
    bool? includeSymbols,
    bool? excludeAmbiguous,
    String? customSymbols,
  }) {
    return GeneratorOptions(
      length: length ?? this.length,
      includeUppercase: includeUppercase ?? this.includeUppercase,
      includeLowercase: includeLowercase ?? this.includeLowercase,
      includeDigits: includeDigits ?? this.includeDigits,
      includeSymbols: includeSymbols ?? this.includeSymbols,
      excludeAmbiguous: excludeAmbiguous ?? this.excludeAmbiguous,
      customSymbols: customSymbols ?? this.customSymbols,
    );
  }
}

class PassStrengthErrors {
  PassStrengthErrors._();

  static const String emptyPassword = 'passstrength_error_empty';
  static const String noCharset = 'passstrength_error_no_charset';
  static const String breachOffline = 'passstrength_error_breach_offline';
  static const String breachTimeout = 'passstrength_error_breach_timeout';
  static const String breachServer = 'passstrength_error_breach_server';
}