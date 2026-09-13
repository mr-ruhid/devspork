import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:markdown/markdown.dart' as md;
import '../core/localization/app_localization.dart';

class MdHtml extends StatefulWidget {
  const MdHtml({super.key});

  @override
  State<MdHtml> createState() => _MdHtmlState();
}

class _MdHtmlState extends State<MdHtml>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();

  String? _errorKey;
  String? _errorDetail;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _inputController.clear();
        _outputController.clear();
        _errorKey = null;
        _errorDetail = null;
      });
    });
    _inputController.text = '''# Başlıq

**Qalın** və *maili* mətn.

- Siyahı 1
- Siyahı 2

[Link](https://flutter.dev)

```dart
void main() {}
```''';
    _convert();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  bool get _isMdToHtml => _tabController.index == 0;

  void _convert() {
    final String input = _inputController.text;
    if (input.trim().isEmpty) {
      setState(() {
        _outputController.text = '';
        _errorKey = null;
        _errorDetail = null;
      });
      return;
    }
    try {
      if (_isMdToHtml) {
        final String html = md.markdownToHtml(
          input,
          extensionSet: md.ExtensionSet.gitHubFlavored,
        );
        setState(() {
          _outputController.text = html;
          _errorKey = null;
          _errorDetail = null;
        });
      } else {
        final String markdown = _htmlToMarkdown(input);
        setState(() {
          _outputController.text = markdown;
          _errorKey = null;
          _errorDetail = null;
        });
      }
    } catch (e) {
      setState(() {
        _outputController.text = '';
        _errorKey = _isMdToHtml
            ? 'mdhtml_error_md'
            : 'mdhtml_error_html';
        _errorDetail = e.toString();
      });
    }
  }

  String _htmlToMarkdown(String html) {
    final dom.Document doc = html_parser.parse(html);
    final StringBuffer buffer = StringBuffer();
    for (final dom.Node node in doc.body?.nodes ?? <dom.Node>[]) {
      final String part = _nodeToMd(node);
      if (part.trim().isEmpty) continue;
      buffer.writeln(part);
      buffer.writeln();
    }
    return buffer.toString().trimRight();
  }

  String _inline(dom.Node node) {
    if (node is dom.Text) {
      return node.text;
    }
    if (node is! dom.Element) return '';
    final String tag = node.localName ?? '';
    final String inner =
    node.nodes.map((dom.Node n) => _inline(n)).join();
    switch (tag) {
      case 'strong':
      case 'b':
        return '**$inner**';
      case 'em':
      case 'i':
        return '*$inner*';
      case 'code':
        return '`$inner`';
      case 'a':
        final String href = node.attributes['href'] ?? '';
        return '[$inner]($href)';
      case 'img':
        final String src = node.attributes['src'] ?? '';
        final String alt = node.attributes['alt'] ?? '';
        return '![$alt]($src)';
      case 'br':
        return '  \n';
      case 'del':
      case 's':
        return '~~$inner~~';
      case 'u':
        return '<u>$inner</u>';
      default:
        return inner;
    }
  }

  String _nodeToMd(dom.Node node) {
    if (node is dom.Text) return node.text.trim();
    if (node is! dom.Element) return '';
    final String tag = node.localName ?? '';
    final String innerText =
    node.nodes.map((dom.Node n) => _inline(n)).join();

    switch (tag) {
      case 'h1':
        return '# $innerText';
      case 'h2':
        return '## $innerText';
      case 'h3':
        return '### $innerText';
      case 'h4':
        return '#### $innerText';
      case 'h5':
        return '##### $innerText';
      case 'h6':
        return '###### $innerText';
      case 'p':
        return innerText;
      case 'blockquote':
        return innerText
            .split('\n')
            .map((String l) => '> $l')
            .join('\n');
      case 'pre':
        final dom.Element? code = node.querySelector('code');
        final String lang = code?.attributes['class']
            ?.replaceFirst('language-', '') ??
            '';
        final String codeText = code?.text ?? node.text;
        return '```$lang\n$codeText\n```';
      case 'hr':
        return '---';
      case 'br':
        return '';
      case 'ul':
        final StringBuffer buffer = StringBuffer();
        for (final dom.Element li
        in node.querySelectorAll(':scope > li')) {
          final String liText =
          li.nodes.map((dom.Node n) => _inline(n)).join();
          buffer.writeln('- $liText');
        }
        return buffer.toString().trimRight();
      case 'ol':
        final StringBuffer buffer = StringBuffer();
        int i = 1;
        for (final dom.Element li
        in node.querySelectorAll(':scope > li')) {
          final String liText =
          li.nodes.map((dom.Node n) => _inline(n)).join();
          buffer.writeln('$i. $liText');
          i++;
        }
        return buffer.toString().trimRight();
      case 'table':
        final List<dom.Element> rows = node.querySelectorAll('tr');
        if (rows.isEmpty) return '';
        final List<List<String>> data = <List<String>>[];
        for (final dom.Element row in rows) {
          final List<String> cells = row
              .querySelectorAll('th, td')
              .map((dom.Element c) => c.text.trim())
              .toList();
          data.add(cells);
        }
        if (data.isEmpty) return '';
        final int cols = data.first.length;
        final StringBuffer buffer = StringBuffer();
        buffer.writeln('| ${data.first.join(' | ')} |');
        buffer.writeln('| ${List<String>.filled(cols, '---').join(' | ')} |');
        for (int i = 1; i < data.length; i++) {
          final List<String> row = data[i];
          while (row.length < cols) {
            row.add('');
          }
          buffer.writeln('| ${row.join(' | ')} |');
        }
        return buffer.toString().trimRight();
      default:
        return node.nodes.map(_nodeToMd).join('\n');
    }
  }

  void _clear() {
    setState(() {
      _inputController.clear();
      _outputController.clear();
      _errorKey = null;
      _errorDetail = null;
    });
  }

  Future<void> _paste() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null) return;
    _inputController.text = data.text!;
    _convert();
  }

  Future<void> _copy() async {
    if (_outputController.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _outputController.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('mdhtml_copied'))),
    );
  }

  void _swap() {
    final String tmp = _inputController.text;
    _inputController.text = _outputController.text;
    _outputController.text = tmp;
    _tabController.index = _tabController.index == 0 ? 1 : 0;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('mdhtml_title')),
        bottom: TabBar(
          controller: _tabController,
          tabs: <Widget>[
            Tab(text: context.t('mdhtml_tab_m2h')),
            Tab(text: context.t('mdhtml_tab_h2m')),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _isMdToHtml
                        ? context.t('mdhtml_input_md')
                        : context.t('mdhtml_input_html'),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: _paste,
                  icon: const Icon(Icons.paste, size: 18),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: _clear,
                  icon: const Icon(Icons.clear, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _inputController,
              maxLines: 8,
              minLines: 6,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton(
                    onPressed: _convert,
                    child: Text(context.t('mdhtml_convert')),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _swap,
                  icon: const Icon(Icons.swap_vert),
                  tooltip: context.t('mdhtml_swap'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _isMdToHtml
                        ? context.t('mdhtml_output_html')
                        : context.t('mdhtml_output_md'),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: _copy,
                  icon: const Icon(Icons.copy, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _outputController,
              readOnly: true,
              maxLines: null,
              minLines: 8,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            if (_errorKey != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      context.t(_errorKey!),
                      style: TextStyle(color: colors.error),
                    ),
                    if (_errorDetail != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _errorDetail!,
                          style: TextStyle(
                            color: colors.error,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}