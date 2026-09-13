import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class SeoTools extends StatefulWidget {
  const SeoTools({super.key});

  @override
  State<SeoTools> createState() => _SeoToolsState();
}

class _SeoToolsState extends State<SeoTools>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Meta Tag Generator
  final TextEditingController _metaTitle = TextEditingController();
  final TextEditingController _metaDescription = TextEditingController();
  final TextEditingController _metaKeywords = TextEditingController();
  final TextEditingController _metaAuthor = TextEditingController();
  final TextEditingController _metaUrl = TextEditingController();
  final TextEditingController _metaImage = TextEditingController();
  final TextEditingController _metaSiteName = TextEditingController();
  final TextEditingController _metaTwitter = TextEditingController();
  bool _metaTwitterCard = true;
  bool _metaOg = true;
  bool _metaCanonical = true;
  bool _metaRobotsIndex = true;
  bool _metaRobotsFollow = true;
  String _metaOutput = '';

  // OG Preview
  final TextEditingController _ogUrl = TextEditingController();
  final TextEditingController _ogTitle = TextEditingController();
  final TextEditingController _ogDescription = TextEditingController();
  final TextEditingController _ogImage = TextEditingController();
  final TextEditingController _ogSiteName = TextEditingController();
  String _ogPlatform = 'facebook';

  // Robots.txt
  final TextEditingController _robotsUserAgent = TextEditingController(text: '*');
  bool _robotsDisallowAll = false;
  bool _robotsAllowAll = false;
  final TextEditingController _robotsDisallow = TextEditingController();
  final TextEditingController _robotsAllow = TextEditingController();
  final TextEditingController _robotsSitemap = TextEditingController();
  final TextEditingController _robotsCrawlDelay = TextEditingController();
  String _robotsOutput = '';

  // Sitemap.xml
  final TextEditingController _sitemapBaseUrl = TextEditingController();
  final TextEditingController _sitemapUrls = TextEditingController();
  String _sitemapChangeFreq = 'weekly';
  String _sitemapPriority = '0.8';
  String _sitemapOutput = '';

  static const List<String> _ogPlatforms = <String>[
    'facebook',
    'twitter',
    'linkedin',
    'whatsapp',
  ];

  static const List<String> _changeFreqs = <String>[
    'always',
    'hourly',
    'daily',
    'weekly',
    'monthly',
    'yearly',
    'never',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _metaTitle.text = 'DevSpork — Developer Tool Kit';
    _metaDescription.text =
    'Mini developer alətləri: JSON, Regex, Base64, Hash, JWT və daha çoxu.';
    _metaKeywords.text = 'developer, tools, json, regex, base64';
    _metaAuthor.text = 'DevSpork';
    _metaUrl.text = 'https://devspork.app';
    _metaImage.text = 'https://devspork.app/og.png';
    _metaSiteName.text = 'DevSpork';
    _metaTwitter.text = '@devspork';

    _ogUrl.text = 'https://devspork.app';
    _ogTitle.text = 'DevSpork — Developer Tool Kit';
    _ogDescription.text = 'Mini developer alətləri bir tətbiqdə.';
    _ogImage.text = 'https://devspork.app/og.png';
    _ogSiteName.text = 'DevSpork';

    _sitemapBaseUrl.text = 'https://devspork.app';
    _sitemapUrls.text = '/\n/about\n/tools/json\n/tools/regex\n/contact';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _metaTitle.dispose();
    _metaDescription.dispose();
    _metaKeywords.dispose();
    _metaAuthor.dispose();
    _metaUrl.dispose();
    _metaImage.dispose();
    _metaSiteName.dispose();
    _metaTwitter.dispose();
    _ogUrl.dispose();
    _ogTitle.dispose();
    _ogDescription.dispose();
    _ogImage.dispose();
    _ogSiteName.dispose();
    _robotsUserAgent.dispose();
    _robotsDisallow.dispose();
    _robotsAllow.dispose();
    _robotsSitemap.dispose();
    _robotsCrawlDelay.dispose();
    _sitemapBaseUrl.dispose();
    _sitemapUrls.dispose();
    super.dispose();
  }

  Future<void> _copy(String text) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('seotools_copied'))),
    );
  }

  Future<void> _pasteTo(TextEditingController c) async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null) return;
    c.text = data.text!;
  }

  String _esc(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('"', '&quot;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  // -------- Meta Tags --------

  void _generateMeta() {
    final StringBuffer b = StringBuffer();
    final String title = _metaTitle.text.trim();
    final String description = _metaDescription.text.trim();
    final String keywords = _metaKeywords.text.trim();
    final String author = _metaAuthor.text.trim();
    final String url = _metaUrl.text.trim();
    final String image = _metaImage.text.trim();
    final String siteName = _metaSiteName.text.trim();
    final String twitter = _metaTwitter.text.trim();

    if (title.isNotEmpty) {
      b.writeln('<title>${_esc(title)}</title>');
    }
    if (description.isNotEmpty) {
      b.writeln(
        '<meta name="description" content="${_esc(description)}">',
      );
    }
    if (keywords.isNotEmpty) {
      b.writeln('<meta name="keywords" content="${_esc(keywords)}">');
    }
    if (author.isNotEmpty) {
      b.writeln('<meta name="author" content="${_esc(author)}">');
    }
    final String robots =
        '${_metaRobotsIndex ? 'index' : 'noindex'}, ${_metaRobotsFollow ? 'follow' : 'nofollow'}';
    b.writeln('<meta name="robots" content="$robots">');
    b.writeln('<meta name="viewport" content="width=device-width, initial-scale=1.0">');
    b.writeln('<meta charset="UTF-8">');
    if (_metaCanonical && url.isNotEmpty) {
      b.writeln('<link rel="canonical" href="${_esc(url)}">');
    }
    if (_metaOg) {
      b.writeln();
      b.writeln('<!-- Open Graph -->');
      b.writeln('<meta property="og:type" content="website">');
      if (title.isNotEmpty) {
        b.writeln('<meta property="og:title" content="${_esc(title)}">');
      }
      if (description.isNotEmpty) {
        b.writeln(
          '<meta property="og:description" content="${_esc(description)}">',
        );
      }
      if (url.isNotEmpty) {
        b.writeln('<meta property="og:url" content="${_esc(url)}">');
      }
      if (image.isNotEmpty) {
        b.writeln('<meta property="og:image" content="${_esc(image)}">');
      }
      if (siteName.isNotEmpty) {
        b.writeln(
          '<meta property="og:site_name" content="${_esc(siteName)}">',
        );
      }
    }
    if (_metaTwitterCard) {
      b.writeln();
      b.writeln('<!-- Twitter Card -->');
      b.writeln('<meta name="twitter:card" content="summary_large_image">');
      if (twitter.isNotEmpty) {
        b.writeln('<meta name="twitter:site" content="${_esc(twitter)}">');
      }
      if (title.isNotEmpty) {
        b.writeln('<meta name="twitter:title" content="${_esc(title)}">');
      }
      if (description.isNotEmpty) {
        b.writeln(
          '<meta name="twitter:description" content="${_esc(description)}">',
        );
      }
      if (image.isNotEmpty) {
        b.writeln('<meta name="twitter:image" content="${_esc(image)}">');
      }
    }
    setState(() {
      _metaOutput = b.toString().trimRight();
    });
  }

  // -------- Robots.txt --------

  void _generateRobots() {
    final StringBuffer b = StringBuffer();
    final String ua = _robotsUserAgent.text.trim().isEmpty
        ? '*'
        : _robotsUserAgent.text.trim();
    b.writeln('User-agent: $ua');
    if (_robotsDisallowAll) {
      b.writeln('Disallow: /');
    } else if (_robotsAllowAll) {
      b.writeln('Allow: /');
    } else {
      final List<String> disallow = _robotsDisallow.text
          .split('\n')
          .map((String l) => l.trim())
          .where((String l) => l.isNotEmpty)
          .toList();
      final List<String> allow = _robotsAllow.text
          .split('\n')
          .map((String l) => l.trim())
          .where((String l) => l.isNotEmpty)
          .toList();
      for (final String p in disallow) {
        b.writeln('Disallow: $p');
      }
      for (final String p in allow) {
        b.writeln('Allow: $p');
      }
    }
    final String delay = _robotsCrawlDelay.text.trim();
    if (delay.isNotEmpty) {
      b.writeln('Crawl-delay: $delay');
    }
    final String sitemap = _robotsSitemap.text.trim();
    if (sitemap.isNotEmpty) {
      b.writeln();
      b.writeln('Sitemap: $sitemap');
    }
    setState(() {
      _robotsOutput = b.toString().trimRight();
    });
  }

  // -------- Sitemap --------

  void _generateSitemap() {
    final String base = _sitemapBaseUrl.text.trim();
    if (base.isEmpty) {
      setState(() {
        _sitemapOutput = context.t('seotools_sitemap_error_base');
      });
      return;
    }
    final List<String> paths = _sitemapUrls.text
        .split('\n')
        .map((String l) => l.trim())
        .where((String l) => l.isNotEmpty)
        .toList();
    if (paths.isEmpty) {
      setState(() {
        _sitemapOutput = context.t('seotools_sitemap_error_empty');
      });
      return;
    }
    final String cleanBase =
    base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final String today = _todayIso();
    final StringBuffer b = StringBuffer();
    b.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    b.writeln('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">');
    for (final String path in paths) {
      final String loc = path.startsWith('http')
          ? path
          : '$cleanBase${path.startsWith('/') ? '' : '/'}$path';
      b.writeln('  <url>');
      b.writeln('    <loc>${_esc(loc)}</loc>');
      b.writeln('    <lastmod>$today</lastmod>');
      b.writeln('    <changefreq>$_sitemapChangeFreq</changefreq>');
      b.writeln('    <priority>$_sitemapPriority</priority>');
      b.writeln('  </url>');
    }
    b.writeln('</urlset>');
    setState(() {
      _sitemapOutput = b.toString().trimRight();
    });
  }

  String _todayIso() {
    final DateTime now = DateTime.now();
    return '${now.year}-${_two(now.month)}-${_two(now.day)}';
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  // -------- UI helpers --------

  Widget _field({
    required String labelKey,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    bool paste = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        minLines: 1,
        decoration: InputDecoration(
          labelText: context.t(labelKey),
          hintText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: paste
              ? IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => _pasteTo(controller),
            icon: const Icon(Icons.paste, size: 18),
          )
              : null,
        ),
      ),
    );
  }

  Widget _outputBlock(String text, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                context.t('seotools_output'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => _copy(text),
              icon: const Icon(Icons.copy, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: text.isEmpty
              ? Text(
            context.t('seotools_output_empty'),
            style: TextStyle(color: colors.outline),
          )
              : SelectableText(
            text,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // -------- Tabs --------

  Widget _buildMeta() {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _field(
            labelKey: 'seotools_meta_title',
            controller: _metaTitle,
            hint: '60 simvola qədər',
          ),
          _field(
            labelKey: 'seotools_meta_description',
            controller: _metaDescription,
            maxLines: 3,
            hint: '160 simvola qədər',
          ),
          _field(
            labelKey: 'seotools_meta_keywords',
            controller: _metaKeywords,
            hint: 'söz1, söz2, söz3',
          ),
          _field(
            labelKey: 'seotools_meta_author',
            controller: _metaAuthor,
          ),
          _field(
            labelKey: 'seotools_meta_url',
            controller: _metaUrl,
            hint: 'https://example.com',
          ),
          _field(
            labelKey: 'seotools_meta_image',
            controller: _metaImage,
            hint: 'https://example.com/og.png',
          ),
          _field(
            labelKey: 'seotools_meta_site_name',
            controller: _metaSiteName,
          ),
          _field(
            labelKey: 'seotools_meta_twitter',
            controller: _metaTwitter,
            hint: '@username',
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(context.t('seotools_meta_og')),
            value: _metaOg,
            onChanged: (bool v) => setState(() => _metaOg = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(context.t('seotools_meta_twitter_card')),
            value: _metaTwitterCard,
            onChanged: (bool v) => setState(() => _metaTwitterCard = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(context.t('seotools_meta_canonical')),
            value: _metaCanonical,
            onChanged: (bool v) => setState(() => _metaCanonical = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(context.t('seotools_meta_robots_index')),
            value: _metaRobotsIndex,
            onChanged: (bool v) => setState(() => _metaRobotsIndex = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(context.t('seotools_meta_robots_follow')),
            value: _metaRobotsFollow,
            onChanged: (bool v) => setState(() => _metaRobotsFollow = v),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _generateMeta,
            icon: const Icon(Icons.tag),
            label: Text(context.t('seotools_generate')),
          ),
          const SizedBox(height: 16),
          _outputBlock(_metaOutput, colors),
          const SizedBox(height: 16),
          _charCount('seotools_meta_title', _metaTitle.text, 60, colors),
          _charCount(
            'seotools_meta_description',
            _metaDescription.text,
            160,
            colors,
          ),
        ],
      ),
    );
  }

  Widget _charCount(
      String labelKey,
      String text,
      int max,
      ColorScheme colors,
      ) {
    final int len = text.length;
    final bool ok = len <= max;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              context.t(labelKey),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Text(
            '$len / $max',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: ok ? Colors.green : colors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOgPreview() {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String platform = _ogPlatform;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _field(
            labelKey: 'seotools_og_url',
            controller: _ogUrl,
          ),
          _field(
            labelKey: 'seotools_og_title',
            controller: _ogTitle,
          ),
          _field(
            labelKey: 'seotools_og_description',
            controller: _ogDescription,
            maxLines: 3,
          ),
          _field(
            labelKey: 'seotools_og_image',
            controller: _ogImage,
          ),
          _field(
            labelKey: 'seotools_og_site_name',
            controller: _ogSiteName,
          ),
          const SizedBox(height: 8),
          Text(
            context.t('seotools_og_platform'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _ogPlatforms.map((String p) {
              return ChoiceChip(
                label: Text(context.t('seotools_og_$p')),
                selected: _ogPlatform == p,
                onSelected: (_) {
                  setState(() {
                    _ogPlatform = p;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            context.t('seotools_og_preview'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          _previewCard(platform, colors),
        ],
      ),
    );
  }

  Widget _previewCard(String platform, ColorScheme colors) {
    final String host = _extractHost(_ogUrl.text);
    final String image = _ogImage.text.trim();
    final String title = _ogTitle.text.trim();
    final String desc = _ogDescription.text.trim();
    final String site = _ogSiteName.text.trim();

    if (platform == 'twitter') {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (image.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 140,
                    color: colors.surfaceContainerHighest,
                    child: Center(
                      child: Text(
                        image,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: colors.outline,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                title.isEmpty ? 'Title' : title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (desc.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    desc,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.outline,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  host,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.outline,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (image.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Container(
                height: 160,
                color: colors.surfaceContainerHighest,
                child: Center(
                  child: Text(
                    image,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: colors.outline,
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  host.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.outline,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title.isEmpty ? 'Title' : title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (desc.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      desc,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.outline,
                      ),
                    ),
                  ),
                if (site.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      site,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.outline,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _extractHost(String url) {
    if (url.trim().isEmpty) return 'example.com';
    try {
      final Uri u = Uri.parse(url.trim());
      return u.host.isEmpty ? url.trim() : u.host;
    } catch (_) {
      return url;
    }
  }

  Widget _buildRobots() {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _field(
            labelKey: 'seotools_robots_ua',
            controller: _robotsUserAgent,
            hint: '*',
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(context.t('seotools_robots_disallow_all')),
            value: _robotsDisallowAll,
            onChanged: (bool v) {
              setState(() {
                _robotsDisallowAll = v;
                if (v) _robotsAllowAll = false;
              });
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(context.t('seotools_robots_allow_all')),
            value: _robotsAllowAll,
            onChanged: (bool v) {
              setState(() {
                _robotsAllowAll = v;
                if (v) _robotsDisallowAll = false;
              });
            },
          ),
          if (!_robotsDisallowAll && !_robotsAllowAll) ...<Widget>[
            _field(
              labelKey: 'seotools_robots_disallow',
              controller: _robotsDisallow,
              maxLines: 4,
              hint: '/admin\n/api\n/private',
            ),
            _field(
              labelKey: 'seotools_robots_allow',
              controller: _robotsAllow,
              maxLines: 3,
              hint: '/public',
            ),
          ],
          _field(
            labelKey: 'seotools_robots_sitemap',
            controller: _robotsSitemap,
            hint: 'https://example.com/sitemap.xml',
          ),
          _field(
            labelKey: 'seotools_robots_crawl_delay',
            controller: _robotsCrawlDelay,
            hint: '10',
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _generateRobots,
            icon: const Icon(Icons.smart_toy),
            label: Text(context.t('seotools_generate')),
          ),
          const SizedBox(height: 16),
          _outputBlock(_robotsOutput, colors),
        ],
      ),
    );
  }

  Widget _buildSitemap() {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _field(
            labelKey: 'seotools_sitemap_base',
            controller: _sitemapBaseUrl,
            hint: 'https://example.com',
          ),
          _field(
            labelKey: 'seotools_sitemap_urls',
            controller: _sitemapUrls,
            maxLines: 8,
            hint: '/\n/about\n/contact',
          ),
          const SizedBox(height: 8),
          Text(
            context.t('seotools_sitemap_changefreq'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _changeFreqs.map((String f) {
              return ChoiceChip(
                label: Text(f, style: const TextStyle(fontSize: 12)),
                selected: _sitemapChangeFreq == f,
                onSelected: (_) {
                  setState(() {
                    _sitemapChangeFreq = f;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            context.t('seotools_sitemap_priority'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <String>['0.1', '0.3', '0.5', '0.7', '0.8', '1.0']
                .map((String p) {
              return ChoiceChip(
                label: Text(p),
                selected: _sitemapPriority == p,
                onSelected: (_) {
                  setState(() {
                    _sitemapPriority = p;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _generateSitemap,
            icon: const Icon(Icons.map),
            label: Text(context.t('seotools_generate')),
          ),
          const SizedBox(height: 16),
          _outputBlock(_sitemapOutput, colors),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('seotools_title')),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: <Widget>[
            Tab(text: context.t('seotools_tab_meta')),
            Tab(text: context.t('seotools_tab_og')),
            Tab(text: context.t('seotools_tab_robots')),
            Tab(text: context.t('seotools_tab_sitemap')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          _buildMeta(),
          _buildOgPreview(),
          _buildRobots(),
          _buildSitemap(),
        ],
      ),
    );
  }
}