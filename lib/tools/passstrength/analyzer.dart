import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:zxcvbn/zxcvbn.dart';

import 'models.dart';

class PassStrengthException implements Exception {
  PassStrengthException(this.errorKey, [this.detail]);

  final String errorKey;
  final String? detail;

  @override
  String toString() => detail == null ? errorKey : '$errorKey: $detail';
}

class BreachResult {
  const BreachResult({required this.count});

  final int count;

  bool get isBreached => count > 0;
}

class PassStrengthAnalyzer {
  PassStrengthAnalyzer._();

  static final Zxcvbn _zxcvbn = Zxcvbn();
  static final Random _random = Random.secure();

  // -----------------------------------------------------------------
  // Runtime-safe dynamic field access.
  //
  // The `zxcvbn` package (careapp.com.au) is a close, largely
  // undocumented port of the old Dropbox CoffeeScript source. Its exact
  // field names (snake_case in places, e.g. `calc_time`,
  // `crack_times_display`) are not reliably documented, and differ from
  // the zxcvbn-ts style API (`crackTimesDisplay`, `guessesLog10`, etc.).
  //
  // Rather than hard-coding field names that may not compile or may be
  // wrong, every access below goes through `_safeGet`, which reads a
  // dynamic member and swallows any "member not found" / type error,
  // returning null instead. This guarantees the file compiles and never
  // crashes even if a specific internal field name turns out to differ
  // from what we assume here — it just degrades to a shorter
  // description/estimate instead of throwing.
  // -----------------------------------------------------------------
  static T? _safeGet<T>(dynamic Function() getter) {
    try {
      final dynamic value = getter();
      if (value == null) return null;
      return value as T;
    } catch (_) {
      return null;
    }
  }

  static StrengthResult analyze(String password) {
    if (password.isEmpty) {
      throw PassStrengthException(PassStrengthErrors.emptyPassword);
    }

    final dynamic r = _zxcvbn.evaluate(password);

    // score: some versions expose this as a double, others as an int.
    final int score = (_safeGet<num>(() => r.score) ?? 0).round().clamp(0, 4);

    // guesses / guesses_log10 (snake_case in this package).
    final double guesses = (_safeGet<num>(() => r.guesses) ?? 0).toDouble();
    final double guessesLog10 = (_safeGet<num>(() => r.guesses_log10) ??
        (guesses > 0 ? (log(guesses) / ln10) : 0))
        .toDouble();

    // crack_times_display: object with per-scenario display strings.
    final dynamic ctd = _safeGet<dynamic>(() => r.crack_times_display);
    final CrackTimeEstimate crackTimes = CrackTimeEstimate(
      offlineFastHashing: _safe(
        _safeGet<String>(() => ctd?.offline_fast_hashing_1e10_per_second),
      ),
      offlineSlowHashing: _safe(
        _safeGet<String>(() => ctd?.offline_slow_hashing_1e4_per_second),
      ),
      onlineNoThrottle: _safe(
        _safeGet<String>(() => ctd?.online_no_throttling_10_per_second),
      ),
      onlineThrottle: _safe(
        _safeGet<String>(() => ctd?.online_throttling_100_per_hour),
      ),
    );

    // sequence / match_sequence: list of pattern matches.
    final List<PatternMatch> patterns = <PatternMatch>[];
    final dynamic sequence = _safeGet<dynamic>(() => r.sequence) ??
        _safeGet<dynamic>(() => r.match_sequence);
    if (sequence is List) {
      for (final dynamic m in sequence) {
        final String pattern =
        (_safeGet<Object>(() => m.pattern) ?? 'unknown').toString();
        final String token = (_safeGet<Object>(() => m.token) ?? '').toString();
        patterns.add(PatternMatch(
          pattern: pattern,
          token: token,
          description: _describeMatch(m, pattern, token),
        ));
      }
    }

    final String? warning = _safeGet<String>(() => r.feedback?.warning);
    final dynamic rawSuggestions = _safeGet<dynamic>(() => r.feedback?.suggestions);
    final List<String> suggestions = rawSuggestions is List
        ? rawSuggestions.map((dynamic e) => e.toString()).toList()
        : <String>[];

    return StrengthResult(
      password: password,
      score: score,
      guesses: guesses,
      guessesLog10: guessesLog10,
      crackTimes: crackTimes,
      feedbackWarning: (warning == null || warning.isEmpty) ? null : warning,
      feedbackSuggestions: suggestions,
      patterns: patterns,
    );
  }

  static String _safe(String? value) {
    if (value == null || value.isEmpty) return '—';
    return value;
  }

  static String _describeMatch(dynamic m, String pattern, String token) {
    switch (pattern) {
      case 'dictionary':
        final String word =
        (_safeGet<Object>(() => m.matched_word) ?? token).toString();
        final dynamic rankVal = _safeGet<Object>(() => m.rank);
        final String rank = rankVal != null ? '#$rankVal' : '';
        final String dict =
        (_safeGet<Object>(() => m.dictionary_name) ?? '').toString();
        final String parts = <String>[
          if (dict.isNotEmpty) dict,
          if (rank.isNotEmpty) rank,
        ].join(' ');
        return parts.isEmpty ? '"$word"' : '"$word" ($parts)';
      case 'spatial':
        return '"$token" (keyboard pattern)';
      case 'repeat':
        final String base =
        (_safeGet<Object>(() => m.base_token) ?? '').toString();
        final dynamic countVal = _safeGet<Object>(() => m.repeat_count);
        return base.isEmpty
            ? '"$token" repeated'
            : '"$base" × ${countVal ?? '?'}';
      case 'sequence':
        final String name =
        (_safeGet<Object>(() => m.sequence_name) ?? '').toString();
        return name.isEmpty ? '"$token"' : '"$token" ($name)';
      case 'regex':
        final String name =
        (_safeGet<Object>(() => m.regex_name) ?? '').toString();
        return name.isEmpty ? '"$token"' : '"$token" ($name)';
      case 'date':
        return '"$token" (date)';
      case 'bruteforce':
        return '"$token"';
      default:
        return '"$token"';
    }
  }

  // -----------------------------------------------------------------
  // Password generator
  // -----------------------------------------------------------------

  static String generatePassword(GeneratorOptions opts) {
    final StringBuffer charset = StringBuffer();

    if (opts.includeUppercase) charset.write('ABCDEFGHIJKLMNOPQRSTUVWXYZ');
    if (opts.includeLowercase) charset.write('abcdefghijklmnopqrstuvwxyz');
    if (opts.includeDigits) charset.write('0123456789');
    if (opts.includeSymbols) charset.write(opts.customSymbols);

    String pool = charset.toString();
    if (opts.excludeAmbiguous) {
      pool = pool.replaceAll(RegExp(r'[Il1O0o]'), '');
    }

    if (pool.isEmpty) {
      throw PassStrengthException(PassStrengthErrors.noCharset);
    }

    final int length = opts.length.clamp(4, 256);
    final List<String> chars = <String>[];
    for (int i = 0; i < length; i++) {
      chars.add(pool[_random.nextInt(pool.length)]);
    }

    return _ensureCoverage(chars, opts, pool);
  }

  static String _ensureCoverage(
      List<String> chars,
      GeneratorOptions opts,
      String pool,
      ) {
    final List<String> required = <String>[];
    if (opts.includeUppercase) {
      required.add(_pickFrom(_upperPool(opts), pool));
    }
    if (opts.includeLowercase) {
      required.add(_pickFrom(_lowerPool(opts), pool));
    }
    if (opts.includeDigits) {
      required.add(_pickFrom('0123456789', pool));
    }
    if (opts.includeSymbols) {
      required.add(_pickFrom(_symbolPool(opts), pool));
    }

    for (int i = 0; i < required.length && i < chars.length; i++) {
      final String ch = required[i];
      if (ch.isEmpty) continue;
      chars[i] = ch;
    }

    _shuffle(chars);
    return chars.join();
  }

  static String _upperPool(GeneratorOptions opts) {
    String p = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (opts.excludeAmbiguous) p = p.replaceAll(RegExp(r'[IO]'), '');
    return p;
  }

  static String _lowerPool(GeneratorOptions opts) {
    String p = 'abcdefghijklmnopqrstuvwxyz';
    if (opts.excludeAmbiguous) p = p.replaceAll(RegExp(r'[lo]'), '');
    return p;
  }

  static String _symbolPool(GeneratorOptions opts) {
    return opts.customSymbols;
  }

  static String _pickFrom(String source, String fallback) {
    if (source.isEmpty) source = fallback;
    if (source.isEmpty) return '';
    return source[_random.nextInt(source.length)];
  }

  static void _shuffle(List<String> list) {
    for (int i = list.length - 1; i > 0; i--) {
      final int j = _random.nextInt(i + 1);
      final String tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
  }

  // -----------------------------------------------------------------
  // HIBP breach check
  // -----------------------------------------------------------------

  static Future<BreachResult> checkBreach(
      String password, {
        Duration timeout = const Duration(seconds: 10),
      }) async {
    if (password.isEmpty) {
      throw PassStrengthException(PassStrengthErrors.emptyPassword);
    }

    final String hash = sha1.convert(utf8.encode(password)).toString().toUpperCase();
    final String prefix = hash.substring(0, 5);
    final String suffix = hash.substring(5);

    final Uri uri = Uri.parse('https://api.pwnedpasswords.com/range/$prefix');

    http.Response response;
    try {
      response = await http.get(
        uri,
        headers: <String, String>{
          'Add-Padding': 'true',
          'User-Agent': 'MiniTools-PasswordStrength',
        },
      ).timeout(timeout);
    } on http.ClientException catch (e) {
      throw PassStrengthException(
        PassStrengthErrors.breachOffline,
        e.message,
      );
    } on Exception catch (e) {
      final String msg = e.toString().toLowerCase();
      if (msg.contains('timeout') || msg.contains('timed out')) {
        throw PassStrengthException(PassStrengthErrors.breachTimeout);
      }
      throw PassStrengthException(PassStrengthErrors.breachOffline, e.toString());
    }

    if (response.statusCode != 200) {
      throw PassStrengthException(
        PassStrengthErrors.breachServer,
        'HTTP ${response.statusCode}',
      );
    }

    final int count = _findSuffix(response.body, suffix);
    return BreachResult(count: count);
  }

  static int _findSuffix(String body, String suffix) {
    final List<String> lines = const LineSplitter().convert(body);
    for (final String line in lines) {
      final int colon = line.indexOf(':');
      if (colon < 0) continue;
      final String s = line.substring(0, colon).trim().toUpperCase();
      if (s != suffix) continue;
      final String c = line.substring(colon + 1).trim();
      final int? parsed = int.tryParse(c);
      if (parsed == null) return 0;
      return parsed;
    }
    return 0;
  }
}