import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class MimeList extends StatefulWidget {
  const MimeList({super.key});

  @override
  State<MimeList> createState() => _MimeListState();
}

class _MimeListState extends State<MimeList> {
  final TextEditingController _searchController = TextEditingController();

  String _category = 'all';
  List<_MimeEntry> _filtered = <_MimeEntry>[];

  static const List<_MimeEntry> _all = <_MimeEntry>[
    _MimeEntry('text/plain', 'txt', 'text'),
    _MimeEntry('text/html', 'html, htm', 'text'),
    _MimeEntry('text/css', 'css', 'text'),
    _MimeEntry('text/csv', 'csv', 'text'),
    _MimeEntry('text/xml', 'xml', 'text'),
    _MimeEntry('text/javascript', 'js, mjs', 'text'),
    _MimeEntry('text/markdown', 'md, markdown', 'text'),
    _MimeEntry('text/calendar', 'ics', 'text'),
    _MimeEntry('text/vcard', 'vcf', 'text'),
    _MimeEntry('text/rtf', 'rtf', 'text'),
    _MimeEntry('application/json', 'json', 'application'),
    _MimeEntry('application/ld+json', 'jsonld', 'application'),
    _MimeEntry('application/xml', 'xml', 'application'),
    _MimeEntry('application/pdf', 'pdf', 'application'),
    _MimeEntry('application/zip', 'zip', 'application'),
    _MimeEntry('application/gzip', 'gz', 'application'),
    _MimeEntry('application/x-tar', 'tar', 'application'),
    _MimeEntry('application/x-7z-compressed', '7z', 'application'),
    _MimeEntry('application/x-rar-compressed', 'rar', 'application'),
    _MimeEntry('application/x-bzip2', 'bz2', 'application'),
    _MimeEntry('application/msword', 'doc', 'application'),
    _MimeEntry(
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'docx',
        'application'),
    _MimeEntry('application/vnd.ms-excel', 'xls', 'application'),
    _MimeEntry(
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'xlsx',
        'application'),
    _MimeEntry('application/vnd.ms-powerpoint', 'ppt', 'application'),
    _MimeEntry(
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        'pptx',
        'application'),
    _MimeEntry('application/vnd.oasis.opendocument.text', 'odt', 'application'),
    _MimeEntry(
        'application/vnd.oasis.opendocument.spreadsheet', 'ods', 'application'),
    _MimeEntry(
        'application/vnd.oasis.opendocument.presentation', 'odp', 'application'),
    _MimeEntry('application/javascript', 'js', 'application'),
    _MimeEntry('application/octet-stream', 'bin, exe, dll', 'application'),
    _MimeEntry('application/wasm', 'wasm', 'application'),
    _MimeEntry('application/x-shockwave-flash', 'swf', 'application'),
    _MimeEntry('application/x-httpd-php', 'php', 'application'),
    _MimeEntry('application/epub+zip', 'epub', 'application'),
    _MimeEntry('application/vnd.android.package-archive', 'apk', 'application'),
    _MimeEntry('application/x-apple-diskimage', 'dmg', 'application'),
    _MimeEntry('application/x-msdownload', 'exe, dll', 'application'),
    _MimeEntry('application/x-deb', 'deb', 'application'),
    _MimeEntry('application/x-rpm', 'rpm', 'application'),
    _MimeEntry('image/jpeg', 'jpg, jpeg', 'image'),
    _MimeEntry('image/png', 'png', 'image'),
    _MimeEntry('image/gif', 'gif', 'image'),
    _MimeEntry('image/webp', 'webp', 'image'),
    _MimeEntry('image/svg+xml', 'svg', 'image'),
    _MimeEntry('image/bmp', 'bmp', 'image'),
    _MimeEntry('image/tiff', 'tif, tiff', 'image'),
    _MimeEntry('image/x-icon', 'ico', 'image'),
    _MimeEntry('image/vnd.microsoft.icon', 'ico', 'image'),
    _MimeEntry('image/heic', 'heic', 'image'),
    _MimeEntry('image/avif', 'avif', 'image'),
    _MimeEntry('image/jp2', 'jp2', 'image'),
    _MimeEntry('audio/mpeg', 'mp3', 'audio'),
    _MimeEntry('audio/wav', 'wav', 'audio'),
    _MimeEntry('audio/ogg', 'ogg, oga', 'audio'),
    _MimeEntry('audio/webm', 'weba', 'audio'),
    _MimeEntry('audio/aac', 'aac', 'audio'),
    _MimeEntry('audio/flac', 'flac', 'audio'),
    _MimeEntry('audio/mp4', 'm4a', 'audio'),
    _MimeEntry('audio/midi', 'mid, midi', 'audio'),
    _MimeEntry('audio/opus', 'opus', 'audio'),
    _MimeEntry('video/mp4', 'mp4, m4v', 'video'),
    _MimeEntry('video/mpeg', 'mpeg, mpg', 'video'),
    _MimeEntry('video/webm', 'webm', 'video'),
    _MimeEntry('video/ogg', 'ogv', 'video'),
    _MimeEntry('video/quicktime', 'mov', 'video'),
    _MimeEntry('video/x-msvideo', 'avi', 'video'),
    _MimeEntry('video/x-matroska', 'mkv', 'video'),
    _MimeEntry('video/x-ms-wmv', 'wmv', 'video'),
    _MimeEntry('video/3gpp', '3gp', 'video'),
    _MimeEntry('video/x-flv', 'flv', 'video'),
    _MimeEntry('font/woff', 'woff', 'font'),
    _MimeEntry('font/woff2', 'woff2', 'font'),
    _MimeEntry('font/ttf', 'ttf', 'font'),
    _MimeEntry('font/otf', 'otf', 'font'),
    _MimeEntry('font/eot', 'eot', 'font'),
    _MimeEntry('application/vnd.ms-fontobject', 'eot', 'font'),
    _MimeEntry('message/rfc822', 'eml', 'message'),
    _MimeEntry('message/http', 'http', 'message'),
    _MimeEntry('multipart/form-data', 'form', 'multipart'),
    _MimeEntry('multipart/mixed', 'mixed', 'multipart'),
    _MimeEntry('model/gltf+json', 'gltf', 'model'),
    _MimeEntry('model/gltf-binary', 'glb', 'model'),
    _MimeEntry('model/obj', 'obj', 'model'),
    _MimeEntry('model/stl', 'stl', 'model'),
    _MimeEntry('application/x-httpd-php', 'php', 'application'),
    _MimeEntry('application/x-sh', 'sh', 'application'),
    _MimeEntry('application/x-python-code', 'pyc', 'application'),
    _MimeEntry('application/x-java-archive', 'jar', 'application'),
    _MimeEntry('application/x-sqlite3', 'sqlite, db', 'application'),
    _MimeEntry('application/x-shockwave-flash', 'swf', 'application'),
    _MimeEntry('application/vnd.apple.installer+xml', 'mpkg', 'application'),
  ];

  static const List<String> _categories = <String>[
    'all',
    'text',
    'application',
    'image',
    'audio',
    'video',
    'font',
    'model',
    'message',
    'multipart',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filter);
    _filtered = List<_MimeEntry>.from(_all);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filter);
    _searchController.dispose();
    super.dispose();
  }

  void _filter() {
    final String q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = _all.where((_MimeEntry e) {
        if (_category != 'all' && e.category != _category) return false;
        if (q.isEmpty) return true;
        return e.mime.toLowerCase().contains(q) ||
            e.extensions.toLowerCase().contains(q);
      }).toList();
    });
  }

  Future<void> _copy(String text) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('mimelist_copied'))),
    );
  }

  IconData _iconFor(String category) {
    switch (category) {
      case 'text':
        return Icons.description;
      case 'application':
        return Icons.apps;
      case 'image':
        return Icons.image;
      case 'audio':
        return Icons.audiotrack;
      case 'video':
        return Icons.movie;
      case 'font':
        return Icons.text_fields;
      case 'model':
        return Icons.view_in_ar;
      case 'message':
        return Icons.email;
      case 'multipart':
        return Icons.layers;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('mimelist_title')),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: context.t('mimelist_search_hint'),
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  icon: const Icon(Icons.clear),
                )
                    : null,
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (BuildContext context, int index) {
                final String cat = _categories[index];
                return ChoiceChip(
                  label: Text(context.t('mimelist_cat_$cat')),
                  selected: _category == cat,
                  onSelected: (_) {
                    setState(() {
                      _category = cat;
                    });
                    _filter();
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: <Widget>[
                Text(
                  '${context.t('mimelist_found')}: ${_filtered.length}',
                  style: TextStyle(color: colors.outline, fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
              child: Text(
                context.t('mimelist_empty'),
                style: TextStyle(color: colors.outline),
              ),
            )
                : ListView.separated(
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: colors.outlineVariant,
              ),
              itemBuilder: (BuildContext context, int index) {
                final _MimeEntry e = _filtered[index];
                return ListTile(
                  leading: Icon(
                    _iconFor(e.category),
                    color: colors.primary,
                  ),
                  title: Text(
                    e.mime,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    e.extensions,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                  trailing: IconButton(
                    onPressed: () => _copy(e.mime),
                    icon: const Icon(Icons.copy, size: 18),
                  ),
                  onLongPress: () => _copy(e.mime),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MimeEntry {
  final String mime;
  final String extensions;
  final String category;

  const _MimeEntry(this.mime, this.extensions, this.category);
}