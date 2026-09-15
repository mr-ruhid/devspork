import 'dart:ui';

import 'models.dart';

class SvgParseException implements Exception {
  SvgParseException(this.errorKey, [this.detail]);

  final String errorKey;
  final String? detail;

  @override
  String toString() => detail == null ? errorKey : '$errorKey: $detail';
}

class SvgPathParser {
  SvgPathParser._();

  static SvgPathData parse(String input) {
    final String text = input.trim();
    if (text.isEmpty) {
      throw SvgParseException(SvgPathErrors.emptyInput);
    }

    final List<_Token> tokens = _tokenize(text);
    if (tokens.isEmpty) {
      throw SvgParseException(SvgPathErrors.emptyInput);
    }

    final List<SvgPathSegment> segments = <SvgPathSegment>[];
    Offset current = Offset.zero;
    Offset subpathStart = Offset.zero;
    SvgPathCommand? lastCommand;
    bool lastWasRelative = false;
    int i = 0;

    while (i < tokens.length) {
      final _Token token = tokens[i];

      if (token.type != _TokenType.command) {
        if (lastCommand == null) {
          throw SvgParseException(SvgPathErrors.missingStart);
        }
        if (lastCommand == SvgPathCommand.moveTo) {
          final SvgPathCommand implicit = lastWasRelative
              ? SvgPathCommand.lineTo
              : SvgPathCommand.lineTo;
          final _ParseResult r = _parseArgs(
            tokens,
            i,
            implicit,
            lastWasRelative,
            current,
            subpathStart,
          );
          segments.add(r.segment);
          current = r.endPoint;
          i = r.nextIndex;
          lastCommand = implicit;
          continue;
        }
        final _ParseResult r = _parseArgs(
          tokens,
          i,
          lastCommand,
          lastWasRelative,
          current,
          subpathStart,
        );
        segments.add(r.segment);
        current = r.endPoint;
        if (lastCommand == SvgPathCommand.moveTo) {
          subpathStart = current;
        }
        i = r.nextIndex;
        continue;
      }

      final String letter = token.value;
      final SvgPathCommand? cmd = _commandFromLetter(letter);
      if (cmd == null) {
        throw SvgParseException(
          SvgPathErrors.invalidCommand,
          'Unknown command "$letter" at position ${token.position}',
        );
      }

      final bool relative = letter == letter.toLowerCase() && letter != letter.toUpperCase();

      i++;

      if (cmd == SvgPathCommand.closePath) {
        final SvgPathSegment seg = SvgPathSegment(
          command: cmd,
          args: const <double>[],
          relative: relative,
          startPoint: current,
          endPoint: subpathStart,
        );
        segments.add(seg);
        current = subpathStart;
        lastCommand = cmd;
        lastWasRelative = relative;
        continue;
      }

      if (i >= tokens.length || tokens[i].type != _TokenType.number) {
        throw SvgParseException(
          SvgPathErrors.missingArguments,
          'Command "$letter" expects ${cmd.argumentCount} arguments',
        );
      }

      final _ParseResult r = _parseArgs(
        tokens,
        i,
        cmd,
        relative,
        current,
        subpathStart,
      );
      segments.add(r.segment);
      current = r.endPoint;
      if (cmd == SvgPathCommand.moveTo) {
        subpathStart = current;
      }
      i = r.nextIndex;
      lastCommand = cmd;
      lastWasRelative = relative;
    }

    if (segments.isEmpty) {
      throw SvgParseException(SvgPathErrors.emptyInput);
    }

    return SvgPathData(segments);
  }

  static _ParseResult _parseArgs(
      List<_Token> tokens,
      int startIndex,
      SvgPathCommand cmd,
      bool relative,
      Offset current,
      Offset subpathStart,
      ) {
    final int count = cmd.argumentCount;
    if (startIndex + count > tokens.length) {
      throw SvgParseException(
        SvgPathErrors.missingArguments,
        'Command "${cmd.letter}" expects $count arguments',
      );
    }

    final List<double> args = <double>[];
    for (int k = 0; k < count; k++) {
      final _Token t = tokens[startIndex + k];
      if (t.type != _TokenType.number) {
        throw SvgParseException(
          SvgPathErrors.invalidNumber,
          'Expected number at position ${t.position}, got "${t.value}"',
        );
      }
      args.add(double.parse(t.value));
    }

    final int nextIndex = startIndex + count;
    final Offset startPoint = current;
    final Offset endPoint = _computeEndPoint(
      cmd,
      args,
      relative,
      current,
      subpathStart,
    );

    return _ParseResult(
      segment: SvgPathSegment(
        command: cmd,
        args: args,
        relative: relative,
        startPoint: startPoint,
        endPoint: endPoint,
      ),
      endPoint: endPoint,
      nextIndex: nextIndex,
    );
  }

  static Offset _computeEndPoint(
      SvgPathCommand cmd,
      List<double> args,
      bool relative,
      Offset current,
      Offset subpathStart,
      ) {
    Offset abs(double x, double y) =>
        relative ? Offset(current.dx + x, current.dy + y) : Offset(x, y);

    switch (cmd) {
      case SvgPathCommand.moveTo:
      case SvgPathCommand.lineTo:
        return abs(args[0], args[1]);

      case SvgPathCommand.horizontalLineTo:
        final double x = relative ? current.dx + args[0] : args[0];
        return Offset(x, current.dy);

      case SvgPathCommand.verticalLineTo:
        final double y = relative ? current.dy + args[0] : args[0];
        return Offset(current.dx, y);

      case SvgPathCommand.cubicBezierCurveTo:
        return abs(args[4], args[5]);

      case SvgPathCommand.smoothCubicBezierCurveTo:
        return abs(args[2], args[3]);

      case SvgPathCommand.quadraticBezierCurveTo:
        return abs(args[2], args[3]);

      case SvgPathCommand.smoothQuadraticBezierCurveTo:
        return abs(args[0], args[1]);

      case SvgPathCommand.ellipticalArc:
        return abs(args[5], args[6]);

      case SvgPathCommand.closePath:
        return subpathStart;
    }
  }

  static SvgPathCommand? _commandFromLetter(String letter) {
    switch (letter.toUpperCase()) {
      case 'M':
        return SvgPathCommand.moveTo;
      case 'L':
        return SvgPathCommand.lineTo;
      case 'H':
        return SvgPathCommand.horizontalLineTo;
      case 'V':
        return SvgPathCommand.verticalLineTo;
      case 'C':
        return SvgPathCommand.cubicBezierCurveTo;
      case 'S':
        return SvgPathCommand.smoothCubicBezierCurveTo;
      case 'Q':
        return SvgPathCommand.quadraticBezierCurveTo;
      case 'T':
        return SvgPathCommand.smoothQuadraticBezierCurveTo;
      case 'A':
        return SvgPathCommand.ellipticalArc;
      case 'Z':
        return SvgPathCommand.closePath;
      default:
        return null;
    }
  }

  static List<_Token> _tokenize(String input) {
    final List<_Token> tokens = <_Token>[];
    int i = 0;

    while (i < input.length) {
      final String ch = input[i];

      if (ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' || ch == ',') {
        i++;
        continue;
      }

      if (_isCommandLetter(ch)) {
        tokens.add(_Token(_TokenType.command, ch, i));
        i++;
        continue;
      }

      if (_isNumberStart(ch) || (ch == '+' || ch == '-')) {
        final int start = i;
        if (ch == '+' || ch == '-') i++;

        bool hasDigit = false;
        while (i < input.length && _isDigit(input[i])) {
          i++;
          hasDigit = true;
        }

        if (i < input.length && input[i] == '.') {
          i++;
          while (i < input.length && _isDigit(input[i])) {
            i++;
            hasDigit = true;
          }
        }

        if (!hasDigit) {
          throw SvgParseException(
            SvgPathErrors.invalidNumber,
            'Invalid number at position $start',
          );
        }

        if (i < input.length && (input[i] == 'e' || input[i] == 'E')) {
          int save = i;
          i++;
          if (i < input.length && (input[i] == '+' || input[i] == '-')) i++;
          bool hasExpDigit = false;
          while (i < input.length && _isDigit(input[i])) {
            i++;
            hasExpDigit = true;
          }
          if (!hasExpDigit) {
            i = save;
          }
        }

        tokens.add(_Token(_TokenType.number, input.substring(start, i), start));
        continue;
      }

      throw SvgParseException(
        SvgPathErrors.invalidCharacter,
        'Unexpected character "$ch" at position $i',
      );
    }

    return tokens;
  }

  static bool _isCommandLetter(String ch) {
    return const <String>{
      'M', 'm', 'L', 'l', 'H', 'h', 'V', 'v', 'C', 'c',
      'S', 's', 'Q', 'q', 'T', 't', 'A', 'a', 'Z', 'z',
    }.contains(ch);
  }

  static bool _isDigit(String ch) {
    final int c = ch.codeUnitAt(0);
    return c >= 0x30 && c <= 0x39;
  }

  static bool _isNumberStart(String ch) {
    return _isDigit(ch) || ch == '.';
  }

  static bool looksLikePath(String input) {
    final String t = input.trim();
    if (t.isEmpty) return false;
    final String first = t[0];
    return const <String>{
      'M', 'm', 'L', 'l', 'H', 'h', 'V', 'v', 'C', 'c',
      'S', 's', 'Q', 'q', 'T', 't', 'A', 'a',
    }.contains(first);
  }

  static SvgPathData parseFromSvg(String svg) {
    final RegExp dRegex = RegExp(r'''d\s*=\s*["']([^"']+)["']''');
    final Match? m = dRegex.firstMatch(svg);
    if (m == null) {
      throw SvgParseException(SvgPathErrors.noPathInSvg);
    }
    return parse(m.group(1)!);
  }
}

class _Token {
  _Token(this.type, this.value, this.position);

  final _TokenType type;
  final String value;
  final int position;
}

enum _TokenType { command, number }

class _ParseResult {
  _ParseResult({
    required this.segment,
    required this.endPoint,
    required this.nextIndex,
  });

  final SvgPathSegment segment;
  final Offset endPoint;
  final int nextIndex;
}

class SvgPathErrors {
  SvgPathErrors._();

  static const String emptyInput = 'svgpath_error_empty';
  static const String invalidCommand = 'svgpath_error_invalid_command';
  static const String invalidNumber = 'svgpath_error_invalid_number';
  static const String invalidCharacter = 'svgpath_error_invalid_char';
  static const String missingArguments = 'svgpath_error_missing_args';
  static const String missingStart = 'svgpath_error_missing_start';
  static const String noPathInSvg = 'svgpath_error_no_path_in_svg';
}