import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../core/localization/app_localization.dart';

class MdPreview extends StatefulWidget {
  const MdPreview({super.key});

  @override
  State<MdPreview> createState() => _MdPreviewState();
}

class _MdPreviewState extends State<MdPreview> {
  final TextEditingController _controller = TextEditingController();
  bool _showPreviewOnly = false;

  static const String _sample = '''# Başlıq

**Qalın** və *maili* mətn.

- Siyahı 1
- Siyahı 2

`kod` və [link](https://flutter.dev)

```dart
void main() {
  print('Salam');
}
```
''';

  @override
  void initState() {
    super.initState();
    _controller.text = _sample;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    setState(() {
      _controller.clear();
    });
  }

  Future<void> _paste() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null) return;
    setState(() {
      _controller.text = data.text!;
    });
  }

  Future<void> _copy() async {
    if (_controller.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _controller.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('mdpreview_copied'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('mdpreview_title')),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              setState(() {
                _showPreviewOnly = !_showPreviewOnly;
              });
            },
            icon: Icon(
              _showPreviewOnly ? Icons.edit : Icons.visibility,
            ),
            tooltip: _showPreviewOnly
                ? context.t('mdpreview_edit')
                : context.t('mdpreview_preview'),
          ),
          PopupMenuButton<String>(
            onSelected: (String value) {
              if (value == 'paste') _paste();
              if (value == 'copy') _copy();
              if (value == 'clear') _clear();
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'paste',
                child: Text(context.t('mdpreview_paste')),
              ),
              PopupMenuItem<String>(
                value: 'copy',
                child: Text(context.t('mdpreview_copy')),
              ),
              PopupMenuItem<String>(
                value: 'clear',
                child: Text(context.t('mdpreview_clear')),
              ),
            ],
          ),
        ],
      ),
      body: _showPreviewOnly
          ? _buildPreview(colors)
          : Column(
        children: <Widget>[
          Expanded(
            flex: 1,
            child: Container(
              color: colors.surfaceContainerHighest,
              child: TextField(
                controller: _controller,
                expands: true,
                maxLines: null,
                minLines: null,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
                onChanged: (String value) => setState(() {}),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                  hintText: '# Markdown yaz...',
                ),
              ),
            ),
          ),
          Container(
            height: 1,
            color: colors.outlineVariant,
          ),
          Expanded(
            flex: 1,
            child: _buildPreview(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(ColorScheme colors) {
    return Container(
      color: colors.surface,
      child: _controller.text.trim().isEmpty
          ? Center(
        child: Text(
          context.t('mdpreview_empty'),
          style: TextStyle(color: colors.outline),
        ),
      )
          : Markdown(
        data: _controller.text,
        selectable: true,
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}