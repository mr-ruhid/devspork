import 'dart:convert';

import 'models.dart';

class SitemapException implements Exception {
  SitemapException(this.errorKey, [this.detail]);

  final String errorKey;
  final String? detail;

  @override
  String toString() => detail == null ? errorKey : '$errorKey: $detail';
}

class SitemapEngine {
  SitemapEngine._();

  static final RegExp _urlRegex = RegExp(
    r'^https?://[^\s/$.?#].[^\s]*$',
    caseSensitive: false,
  );

  static final RegExp _dateRegex = RegExp(
    r'^\d{4}-\d{2}-\d{2}(T\d{2}:\d{2}(:\d{2})?(\.\d+)?(Z|[+-]\d{2}:\d{2})?)?$',
  );

  static String build(SitemapConfig config) {
    if (config.mode == SitemapMode.urlset) {
      return _buildUrlset(config);
    }
    return _buildIndex(config);
  }

  static String _buildUrlset(SitemapConfig config) {
    if (config.urls.isEmpty) {
      throw SitemapException(SeoErrors.sitemapEmpty);
    }

    final StringBuffer b = StringBuffer();
    if (config.includeXmlDeclaration) {
      b.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    }

    b.write('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"');
    if (config.includeXsl && config.xslHref.trim().isNotEmpty) {
      b.write('\n        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"');
      b.write('\n        xsl:version="1.0"');
    }
    b.write('>');

    for (int i = 0; i < config.urls.length; i++) {
      final SitemapUrlEntry u = config.urls[i];
      _validateUrl(u.loc, i);
      if (u.priority != null && (u.priority! < 0 || u.priority! > 1)) {
        throw SitemapException(
          SeoErrors.sitemapInvalidPriority,
          'Entry #${i + 1}: priority must be between 0.0 and 1.0',
        );
      }
      if (u.lastmod != null &&
          u.lastmod!.isNotEmpty &&
          !_dateRegex.hasMatch(u.lastmod!)) {
        throw SitemapException(
          SeoErrors.sitemapInvalidDate,
          'Entry #${i + 1}: invalid lastmod format',
        );
      }

      b.write('\n  <url>');
      b.write('\n    <loc>${_escapeXml(u.loc.trim())}</loc>');
      if (u.lastmod != null && u.lastmod!.trim().isNotEmpty) {
        b.write('\n    <lastmod>${u.lastmod!.trim()}</lastmod>');
      }
      final ChangeFreq? cf = u.changeFreq ??
          (config.applyDefaults ? config.defaultChangeFreq : null);
      if (cf != null) {
        b.write('\n    <changefreq>${cf.display}</changefreq>');
      }
      final double? pr = u.priority ??
          (config.applyDefaults ? config.defaultPriority : null);
      if (pr != null) {
        b.write('\n    <priority>${_formatPriority(pr)}</priority>');
      }
      b.write('\n  </url>');
    }

    b.write('\n</urlset>');
    return b.toString();
  }

  static String _buildIndex(SitemapConfig config) {
    if (config.indexes.isEmpty) {
      throw SitemapException(SeoErrors.sitemapEmpty);
    }

    final StringBuffer b = StringBuffer();
    if (config.includeXmlDeclaration) {
      b.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    }
    b.write('<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">');

    for (int i = 0; i < config.indexes.length; i++) {
      final SitemapIndexEntry s = config.indexes[i];
      _validateUrl(s.loc, i);
      if (s.lastmod != null &&
          s.lastmod!.isNotEmpty &&
          !_dateRegex.hasMatch(s.lastmod!)) {
        throw SitemapException(
          SeoErrors.sitemapInvalidDate,
          'Entry #${i + 1}: invalid lastmod format',
        );
      }
      b.write('\n  <sitemap>');
      b.write('\n    <loc>${_escapeXml(s.loc.trim())}</loc>');
      if (s.lastmod != null && s.lastmod!.trim().isNotEmpty) {
        b.write('\n    <lastmod>${s.lastmod!.trim()}</lastmod>');
      }
      b.write('\n  </sitemap>');
    }

    b.write('\n</sitemapindex>');
    return b.toString();
  }

  static void _validateUrl(String url, int index) {
    final String t = url.trim();
    if (t.isEmpty) {
      throw SitemapException(
        SeoErrors.sitemapInvalidUrl,
        'Entry #${index + 1}: empty URL',
      );
    }
    if (!_urlRegex.hasMatch(t)) {
      throw SitemapException(
        SeoErrors.sitemapInvalidUrl,
        'Entry #${index + 1}: "$t" is not a valid URL',
      );
    }
    if (t.length > 2048) {
      throw SitemapException(
        SeoErrors.sitemapInvalidUrl,
        'Entry #${index + 1}: URL exceeds 2048 characters',
      );
    }
  }

  static String _formatPriority(double p) {
    if (p == 1.0) return '1.0';
    if (p == 0.0) return '0.0';
    String s = p.toStringAsFixed(1);
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '');
      if (s.endsWith('.')) s = '${s}0';
    }
    return s;
  }

  static String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static List<SitemapUrlEntry> parseUrlLines(
      String raw, {
        bool applyDefaults = false,
        ChangeFreq defaultFreq = ChangeFreq.weekly,
        double defaultPriority = 0.5,
      }) {
    final List<SitemapUrlEntry> out = <SitemapUrlEntry>[];
    final List<String> lines = const LineSplitter().convert(raw);

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty) continue;
      if (line.startsWith('#')) continue;

      String? lastmod;
      ChangeFreq? cf;
      double? pr;

      if (line.contains('|')) {
        final List<String> parts = line.split('|');
        line = parts[0].trim();
        for (int p = 1; p < parts.length; p++) {
          final String part = parts[p].trim();
          if (part.isEmpty) continue;
          final double? parsed = double.tryParse(part);
          if (parsed != null && parsed >= 0 && parsed <= 1) {
            pr = parsed;
            continue;
          }
          final ChangeFreq? freq = _parseChangeFreq(part);
          if (freq != null) {
            cf = freq;
            continue;
          }
          if (_dateRegex.hasMatch(part)) {
            lastmod = part;
          }
        }
      }

      out.add(SitemapUrlEntry(
        loc: line,
        lastmod: lastmod,
        changeFreq: cf ??
            (applyDefaults ? defaultFreq : null),
        priority: pr ??
            (applyDefaults ? defaultPriority : null),
      ));
    }

    return out;
  }

  static ChangeFreq? _parseChangeFreq(String value) {
    final String v = value.toLowerCase().trim();
    for (final ChangeFreq f in ChangeFreq.values) {
      if (f.display == v) return f;
    }
    return null;
  }

  static String todayIso() {
    final DateTime now = DateTime.now().toUtc();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  static int estimateSizeBytes(String xml) => utf8.encode(xml).length;

  static int countEntries(SitemapConfig config) {
    if (config.mode == SitemapMode.urlset) return config.urls.length;
    return config.indexes.length;
  }
}