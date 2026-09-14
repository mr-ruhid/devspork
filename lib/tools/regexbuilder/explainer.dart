
import 'models.dart';

class RegexExplainer {
  RegexExplainer._();

  static List<ExplainLine> explain(String pattern) {
    if (pattern.isEmpty) return <ExplainLine>[];

    final List<ExplainLine> lines = <ExplainLine>[];
    int i = 0;
    int depth = 0;

    while (i < pattern.length) {
      final String ch = pattern[i];

      if (ch == '(') {
        final String? group = _parseGroupHeader(pattern, i);
        if (group != null) {
          lines.add(
            ExplainLine(
              token: group,
              descriptionKey: _groupDescKey(group),
              detail: _groupDetail(group),
              depth: depth,
            ),
          );
          i += group.length;
          depth++;
          continue;
        }
        lines.add(
          ExplainLine(
            token: '(',
            descriptionKey: 'regexbuilder_explain_group_start',
            depth: depth,
          ),
        );
        depth++;
        i++;
        continue;
      }

      if (ch == ')') {
        if (depth > 0) depth--;
        lines.add(
          ExplainLine(
            token: ')',
            descriptionKey: 'regexbuilder_explain_group_end',
            depth: depth,
          ),
        );
        i++;
        continue;
      }

      if (ch == '[') {
        final int end = _findCharClassEnd(pattern, i);
        if (end != -1) {
          final String cls = pattern.substring(i, end + 1);
          lines.add(
            ExplainLine(
              token: cls,
              descriptionKey: 'regexbuilder_explain_char_class',
              detail: _charClassDetail(cls),
              depth: depth,
            ),
          );
          i = end + 1;
          continue;
        }
      }

      if (ch == '\\' && i + 1 < pattern.length) {
        final String seq = pattern.substring(i, i + 2);
        lines.add(
          ExplainLine(
            token: seq,
            descriptionKey: _escapeDescKey(seq),
            detail: _escapeDetail(seq),
            depth: depth,
          ),
        );
        i += 2;
        continue;
      }

      if (_isQuantifierStart(ch)) {
        final String? quant = _readQuantifier(pattern, i);
        if (quant != null) {
          lines.add(
            ExplainLine(
              token: quant,
              descriptionKey: _quantifierDescKey(quant),
              detail: _quantifierDetail(quant),
              depth: depth,
            ),
          );
          i += quant.length;
          continue;
        }
      }

      if (ch == '|') {
        lines.add(
          ExplainLine(
            token: '|',
            descriptionKey: 'regexbuilder_explain_alternation',
            depth: depth,
          ),
        );
        i++;
        continue;
      }

      if (ch == '^') {
        lines.add(
          ExplainLine(
            token: '^',
            descriptionKey: 'regexbuilder_explain_anchor_start',
            depth: depth,
          ),
        );
        i++;
        continue;
      }

      if (ch == r'$') {
        lines.add(
          ExplainLine(
            token: r'$',
            descriptionKey: 'regexbuilder_explain_anchor_end',
            depth: depth,
          ),
        );
        i++;
        continue;
      }

      if (ch == '.') {
        lines.add(
          ExplainLine(
            token: '.',
            descriptionKey: 'regexbuilder_explain_dot',
            depth: depth,
          ),
        );
        i++;
        continue;
      }

      final String literal = _readLiteral(pattern, i);
      lines.add(
        ExplainLine(
          token: literal,
          descriptionKey: 'regexbuilder_explain_literal',
          detail: literal,
          depth: depth,
        ),
      );
      i += literal.length;
    }

    return lines;
  }

  static bool _isQuantifierStart(String ch) =>
      ch == '*' || ch == '+' || ch == '?' || ch == '{';

  static String _readLiteral(String pattern, int start) {
    final StringBuffer sb = StringBuffer();
    int i = start;
    while (i < pattern.length) {
      final String ch = pattern[i];
      if (ch == '(' ||
          ch == ')' ||
          ch == '[' ||
          ch == '\\' ||
          ch == '|' ||
          ch == '^' ||
          ch == r'$' ||
          ch == '.' ||
          ch == '*' ||
          ch == '+' ||
          ch == '?' ||
          ch == '{') {
        break;
      }
      sb.write(ch);
      i++;
    }
    return sb.toString();
  }

  static String? _parseGroupHeader(String pattern, int start) {
    if (start + 1 >= pattern.length) return null;
    if (pattern[start] != '(') return null;
    final String next = pattern[start + 1];
    if (next != '?') return null;

    if (start + 2 >= pattern.length) return null;
    final String third = pattern[start + 2];

    if (third == ':') return '(?:';
    if (third == '=') return '(?=';
    if (third == '!') return '(?!';

    if (third == '<' && start + 3 < pattern.length) {
      final String fourth = pattern[start + 3];
      if (fourth == '=') return '(?<=';
      if (fourth == '!') return '(?<!';

      final int end = pattern.indexOf('>', start + 3);
      if (end != -1) {
        return pattern.substring(start, end + 1);
      }
    }
    return null;
  }

  static String _groupDescKey(String group) {
    if (group == '(?:') return 'regexbuilder_explain_group_noncapturing';
    if (group == '(?=') return 'regexbuilder_explain_lookahead_pos';
    if (group == '(?!') return 'regexbuilder_explain_lookahead_neg';
    if (group == '(?<=') return 'regexbuilder_explain_lookbehind_pos';
    if (group == '(?<!') return 'regexbuilder_explain_lookbehind_neg';
    if (group.startsWith('(?<')) return 'regexbuilder_explain_named_group';
    return 'regexbuilder_explain_group';
  }

  static String? _groupDetail(String group) {
    if (group.startsWith('(?<') &&
        !group.startsWith('(?<=') &&
        !group.startsWith('(?<!')) {
      return group.substring(3, group.length - 1);
    }
    return null;
  }

  static int _findCharClassEnd(String pattern, int start) {
    if (pattern[start] != '[') return -1;
    int i = start + 1;
    if (i < pattern.length && pattern[i] == '^') i++;
    if (i < pattern.length && pattern[i] == ']') i++;
    while (i < pattern.length) {
      if (pattern[i] == '\\' && i + 1 < pattern.length) {
        i += 2;
        continue;
      }
      if (pattern[i] == ']') return i;
      i++;
    }
    return -1;
  }

  static String _charClassDetail(String cls) {
    final bool negated = cls.length > 1 && cls[1] == '^';
    return negated ? 'negated' : 'positive';
  }

  static String _escapeDescKey(String seq) {
    switch (seq) {
      case r'\d':
        return 'regexbuilder_explain_digit';
      case r'\D':
        return 'regexbuilder_explain_non_digit';
      case r'\w':
        return 'regexbuilder_explain_word';
      case r'\W':
        return 'regexbuilder_explain_non_word';
      case r'\s':
        return 'regexbuilder_explain_space';
      case r'\S':
        return 'regexbuilder_explain_non_space';
      case r'\b':
        return 'regexbuilder_explain_word_boundary';
      case r'\B':
        return 'regexbuilder_explain_non_word_boundary';
      case r'\A':
        return 'regexbuilder_explain_anchor_start_input';
      case r'\z':
        return 'regexbuilder_explain_anchor_end_input';
      case r'\n':
        return 'regexbuilder_explain_newline';
      case r'\t':
        return 'regexbuilder_explain_tab';
      case r'\r':
        return 'regexbuilder_explain_return';
      case r'\f':
        return 'regexbuilder_explain_form_feed';
      case r'\v':
        return 'regexbuilder_explain_vertical_tab';
      case r'\0':
        return 'regexbuilder_explain_null';
      default:
        return 'regexbuilder_explain_escaped_literal';
    }
  }

  static String? _escapeDetail(String seq) {
    if (seq.length == 2) {
      final String c = seq[1];
      if (!'dDwWsSbBAznrtfv0'.contains(c)) {
        return c;
      }
    }
    return null;
  }

  static String? _readQuantifier(String pattern, int start) {
    final String ch = pattern[start];
    if (ch == '*' || ch == '+' || ch == '?') {
      final StringBuffer sb = StringBuffer(ch);
      if (start + 1 < pattern.length && pattern[start + 1] == '?') {
        sb.write('?');
      } else if (start + 1 < pattern.length && pattern[start + 1] == '+') {
        sb.write('+');
      }
      return sb.toString();
    }

    if (ch == '{') {
      final int end = pattern.indexOf('}', start);
      if (end == -1) return null;
      final String inner = pattern.substring(start + 1, end);
      if (!RegExp(r'^\d+(,\d*)?$').hasMatch(inner)) return null;
      final String base = pattern.substring(start, end + 1);
      if (end + 1 < pattern.length) {
        if (pattern[end + 1] == '?') return '$base?';
        if (pattern[end + 1] == '+') return '$base+';
      }
      return base;
    }
    return null;
  }

  static String _quantifierDescKey(String quant) {
    if (quant.startsWith('{')) {
      if (quant.contains('}')) {
        final String inner =
        quant.substring(1, quant.indexOf('}'));
        if (inner.contains(',')) {
          if (inner.endsWith(',')) {
            return 'regexbuilder_explain_quant_at_least';
          }
          return 'regexbuilder_explain_quant_between';
        }
        return 'regexbuilder_explain_quant_exact';
      }
    }

    final bool lazy = quant.endsWith('?') &&
        quant.length == 2 &&
        (quant[0] == '*' || quant[0] == '+' || quant[0] == '?');
    final bool possessive = quant.endsWith('+') && quant.length == 2;

    final String base = quant[0];

    if (base == '*') {
      if (lazy) return 'regexbuilder_explain_quant_star_lazy';
      if (possessive) return 'regexbuilder_explain_quant_star_possessive';
      return 'regexbuilder_explain_quant_star';
    }
    if (base == '+') {
      if (lazy) return 'regexbuilder_explain_quant_plus_lazy';
      if (possessive) return 'regexbuilder_explain_quant_plus_possessive';
      return 'regexbuilder_explain_quant_plus';
    }
    if (base == '?') {
      if (lazy) return 'regexbuilder_explain_quant_question_lazy';
      if (possessive) {
        return 'regexbuilder_explain_quant_question_possessive';
      }
      return 'regexbuilder_explain_quant_question';
    }
    return 'regexbuilder_explain_quant';
  }

  static String? _quantifierDetail(String quant) {
    if (!quant.startsWith('{')) return null;
    final int end = quant.indexOf('}');
    if (end == -1) return null;
    return quant.substring(1, end);
  }
}