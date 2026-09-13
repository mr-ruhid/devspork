import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../core/localization/app_localization.dart';

class B64Img extends StatefulWidget {
  const B64Img({super.key});

  @override
  State<B64Img> createState() => _B64ImgState();
}

class _B64ImgState extends State<B64Img>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _inputController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _imageBytes;
  String _mimeType = 'image/png';
  String? _errorKey;
  String? _errorDetail;
  bool _autoPrefix = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _errorKey = null;
        _errorDetail = null;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  bool get _isEncode => _tabController.index == 0;

  String _guessMime(String name) {
    final String lower = name.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.bmp')) return 'image/bmp';
    if (lower.endsWith('.svg')) return 'image/svg+xml';
    return 'image/png';
  }

  Future<void> _pickImage() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (file == null) return;
      final Uint8List bytes = await file.readAsBytes();
      final String mime = _guessMime(file.name);
      setState(() {
        _imageBytes = bytes;
        _mimeType = mime;
        _errorKey = null;
        _errorDetail = null;
      });
      _encodeImage();
    } catch (e) {
      setState(() {
        _errorKey = 'b64img_error_pick';
        _errorDetail = e.toString();
      });
    }
  }

  void _encodeImage() {
    if (_imageBytes == null) return;
    final String b64 = base64.encode(_imageBytes!);
    final String result = _autoPrefix ? 'data:$_mimeType;base64,$b64' : b64;
    setState(() {
      _inputController.text = result;
      _errorKey = null;
      _errorDetail = null;
    });
  }

  void _decodeString() {
    final String raw = _inputController.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _imageBytes = null;
        _errorKey = 'b64img_error_empty';
        _errorDetail = null;
      });
      return;
    }
    try {
      String cleaned = raw;
      String mime = 'image/png';
      if (cleaned.startsWith('data:')) {
        final int comma = cleaned.indexOf(',');
        if (comma == -1) throw Exception('invalid data url');
        final String header = cleaned.substring(5, comma);
        final List<String> hp = header.split(';');
        if (hp.isNotEmpty) mime = hp.first;
        cleaned = cleaned.substring(comma + 1);
      }
      cleaned = cleaned.replaceAll(RegExp(r'\s+'), '');
      final Uint8List bytes = base64.decode(cleaned);
      setState(() {
        _imageBytes = bytes;
        _mimeType = mime;
        _errorKey = null;
        _errorDetail = null;
      });
    } catch (e) {
      setState(() {
        _imageBytes = null;
        _errorKey = 'b64img_error_invalid';
        _errorDetail = e.toString();
      });
    }
  }

  void _clear() {
    setState(() {
      _inputController.clear();
      _imageBytes = null;
      _errorKey = null;
      _errorDetail = null;
    });
  }

  Future<void> _paste() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null) return;
    _inputController.text = data.text!;
    if (!_isEncode) _decodeString();
  }

  Future<void> _copy() async {
    if (_inputController.text.isEmpty) return;
    await Clipboard.setData(
      ClipboardData(text: _inputController.text),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('b64img_copied'))),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Widget _buildEncode(ColorScheme colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (_imageBytes != null)
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _imageBytes!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              Icons.image_outlined,
                              size: 48,
                              color: colors.outline,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              context.t('b64img_no_image'),
                              style: TextStyle(color: colors.outline),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (_imageBytes != null)
                    Text(
                      '${_mimeType}  •  ${_formatSize(_imageBytes!.length)}',
                      style: TextStyle(
                        color: colors.outline,
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.photo_library),
                          label: Text(context.t('b64img_pick')),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _imageBytes != null ? _encodeImage : null,
                        icon: const Icon(Icons.refresh),
                        tooltip: context.t('b64img_reencode'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.t('b64img_auto_prefix')),
            value: _autoPrefix,
            onChanged: (bool v) {
              setState(() {
                _autoPrefix = v;
              });
              if (_imageBytes != null) _encodeImage();
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  context.t('b64img_output_hint'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: _copy,
                icon: const Icon(Icons.copy, size: 18),
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
            readOnly: true,
            maxLines: 10,
            minLines: 6,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecode(ColorScheme colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  context.t('b64img_input_hint'),
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
            minLines: 5,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              hintText: 'data:image/png;base64,iVBORw0KGgo...',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _decodeString,
            icon: const Icon(Icons.image_search),
            label: Text(context.t('b64img_decode')),
          ),
          if (_errorKey != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
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
          const SizedBox(height: 16),
          if (_imageBytes != null) ...<Widget>[
            Text(
              context.t('b64img_preview'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.memory(
                  _imageBytes!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_mimeType}  •  ${_formatSize(_imageBytes!.length)}',
              style: TextStyle(
                color: colors.outline,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('b64img_title')),
        bottom: TabBar(
          controller: _tabController,
          tabs: <Widget>[
            Tab(text: context.t('b64img_tab_encode')),
            Tab(text: context.t('b64img_tab_decode')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          _buildEncode(colors),
          _buildDecode(colors),
        ],
      ),
    );
  }
}