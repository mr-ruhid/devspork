import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'meta_engine.dart';
import 'models.dart';
import 'ui_kit.dart';

class MetaTab extends StatefulWidget {
  const MetaTab({super.key});

  @override
  State<MetaTab> createState() => _MetaTabState();
}

class _MetaTabState extends State<MetaTab> {
  final MetaConfig _config = MetaConfig();

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _keywordsCtrl = TextEditingController();
  final TextEditingController _authorCtrl = TextEditingController();
  final TextEditingController _canonicalCtrl = TextEditingController();
  final TextEditingController _languageCtrl = TextEditingController();
  final TextEditingController _viewportCtrl =
  TextEditingController(text: 'width=device-width, initial-scale=1');
  final TextEditingController _themeColorCtrl = TextEditingController();

  final TextEditingController _ogTitleCtrl = TextEditingController();
  final TextEditingController _ogDescCtrl = TextEditingController();
  final TextEditingController _ogImageCtrl = TextEditingController();
  final TextEditingController _ogUrlCtrl = TextEditingController();
  final TextEditingController _ogSiteNameCtrl = TextEditingController();
  final TextEditingController _ogLocaleCtrl = TextEditingController();

  final TextEditingController _twTitleCtrl = TextEditingController();
  final TextEditingController _twDescCtrl = TextEditingController();
  final TextEditingController _twImageCtrl = TextEditingController();
  final TextEditingController _twSiteCtrl = TextEditingController();
  final TextEditingController _twCreatorCtrl = TextEditingController();

  final TextEditingController _faviconCtrl = TextEditingController();
  final TextEditingController _appleIconCtrl = TextEditingController();
  final TextEditingController _manifestCtrl = TextEditingController();
  final TextEditingController _iconSvgCtrl = TextEditingController();
  final TextEditingController _icon32Ctrl = TextEditingController();
  final TextEditingController _icon16Ctrl = TextEditingController();

  Timer? _debounce;
  String _output = '';
  MetaAnalysis? _analysis;
  bool _copied = false;
  bool _showOg = true;
  bool _showTwitter = true;
  bool _showFavicon = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl.text = 'MiniTools — Developer Utilities';
    _descCtrl.text =
    'A collection of fast, privacy-first developer tools that run entirely in your browser.';
    _canonicalCtrl.text = 'https://example.com/';
    _languageCtrl.text = 'en';
    _ogSiteNameCtrl.text = 'MiniTools';
    _ogLocaleCtrl.text = 'en_US';
    _twSiteCtrl.text = '@minitools';
    _syncAll();
    _regenerate();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _keywordsCtrl.dispose();
    _authorCtrl.dispose();
    _canonicalCtrl.dispose();
    _languageCtrl.dispose();
    _viewportCtrl.dispose();
    _themeColorCtrl.dispose();
    _ogTitleCtrl.dispose();
    _ogDescCtrl.dispose();
    _ogImageCtrl.dispose();
    _ogUrlCtrl.dispose();
    _ogSiteNameCtrl.dispose();
    _ogLocaleCtrl.dispose();
    _twTitleCtrl.dispose();
    _twDescCtrl.dispose();
    _twImageCtrl.dispose();
    _twSiteCtrl.dispose();
    _twCreatorCtrl.dispose();
    _faviconCtrl.dispose();
    _appleIconCtrl.dispose();
    _manifestCtrl.dispose();
    _iconSvgCtrl.dispose();
    _icon32Ctrl.dispose();
    _icon16Ctrl.dispose();
    super.dispose();
  }

  void _syncAll() {
    _config
      ..title = _titleCtrl.text
      ..description = _descCtrl.text
      ..keywords = _keywordsCtrl.text
      ..author = _authorCtrl.text
      ..canonical = _canonicalCtrl.text
      ..language = _languageCtrl.text
      ..viewport = _viewportCtrl.text
      ..themeColor = _themeColorCtrl.text
      ..ogTitle = _ogTitleCtrl.text
      ..ogDescription = _ogDescCtrl.text
      ..ogImage = _ogImageCtrl.text
      ..ogUrl = _ogUrlCtrl.text
      ..ogSiteName = _ogSiteNameCtrl.text
      ..ogLocale = _ogLocaleCtrl.text
      ..twitterTitle = _twTitleCtrl.text
      ..twitterDescription = _twDescCtrl.text
      ..twitterImage = _twImageCtrl.text
      ..twitterSite = _twSiteCtrl.text
      ..twitterCreator = _twCreatorCtrl.text
      ..faviconIco = _faviconCtrl.text
      ..appleTouchIcon = _appleIconCtrl.text
      ..manifest = _manifestCtrl.text
      ..iconSvg = _iconSvgCtrl.text
      ..icon32 = _icon32Ctrl.text
      ..icon16 = _icon16Ctrl.text;
  }

  void _scheduleRegen() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), _regenerate);
  }

  void _regenerate() {
    _syncAll();
    try {
      final String out = MetaEngine.build(_config);
      final MetaAnalysis a = MetaEngine.analyze(_config);
      if (!mounted) return;
      setState(() {
        _output = out;
        _analysis = a;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _output = '<!-- Error: ${e.toString()} -->';
        _analysis = null;
      });
    }
  }

  Future<void> _copy() async {
    if (_output.isEmpty) return;
    await seoCopy(context, _output);
    if (!mounted) return;
    setState(() => _copied = true);
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _pasteInto(TextEditingController ctrl) async {
    final ClipboardData? c = await Clipboard.getData(Clipboard.kTextPlain);
    if (c == null || c.text == null) return;
    HapticFeedback.selectionClick();
    ctrl.text = c.text!;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_analysis != null) ...<Widget>[
            _buildAnalysisCard(_analysis!),
            const SizedBox(height: 14),
          ],
          _buildBasicCard(),
          const SizedBox(height: 14),
          _buildRobotsCard(),
          const SizedBox(height: 14),
          _buildOgCard(),
          const SizedBox(height: 14),
          _buildTwitterCard(),
          const SizedBox(height: 14),
          _buildFaviconCard(),
          const SizedBox(height: 14),
          _buildOutputCard(),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(MetaAnalysis a) {
    return SeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SeoSectionTitle(
            Icons.analytics_outlined,
            seoTr(context, 'seo_meta_analysis', 'SEO analysis'),
          ),
          const SizedBox(height: 12),
          _analysisRow(
            label: seoTr(context, 'seo_meta_title_len', 'Title length'),
            value: '${a.titleLength}',
            status: a.titleStatus,
            recommended: '${MetaEngine.titleMin}–${MetaEngine.titleMax}',
          ),
          const SizedBox(height: 10),
          _analysisRow(
            label: seoTr(context, 'seo_meta_desc_len', 'Description length'),
            value: '${a.descriptionLength}',
            status: a.descriptionStatus,
            recommended:
            '${MetaEngine.descriptionMin}–${MetaEngine.descriptionMax}',
          ),
          if (a.warnings.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),
            for (final String w in a.warnings)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(
                        Icons.error_outline,
                        size: 14,
                        color: SeoColors.danger,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        w,
                        style: const TextStyle(
                          color: Color(0xFFFFBFBF),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (a.tips.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            for (final String t in a.tips)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 14,
                        color: SeoColors.accentB,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _analysisRow({
    required String label,
    required String value,
    required SeoLengthStatus status,
    required String recommended,
  }) {
    Color c;
    IconData icon;
    switch (status) {
      case SeoLengthStatus.tooShort:
        c = SeoColors.warning;
        icon = Icons.trending_down_rounded;
        break;
      case SeoLengthStatus.optimal:
        c = SeoColors.success;
        icon = Icons.check_circle_outline_rounded;
        break;
      case SeoLengthStatus.tooLong:
        c = SeoColors.danger;
        icon = Icons.trending_up_rounded;
        break;
    }
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: c),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        Text(
          '$value / $recommended',
          style: TextStyle(
            color: c,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildBasicCard() {
    return SeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SeoSectionTitle(
            Icons.info_outline_rounded,
            seoTr(context, 'seo_meta_basic', 'Basic meta tags'),
          ),
          const SizedBox(height: 12),
          _textFieldWithCounter(
            label: seoTr(context, 'seo_meta_title', 'Page title'),
            controller: _titleCtrl,
            hint: 'Your Page Title — Brand',
            max: MetaEngine.titleMax,
          ),
          const SizedBox(height: 10),
          _textFieldWithCounter(
            label: seoTr(context, 'seo_meta_description', 'Description'),
            controller: _descCtrl,
            hint: 'A short, descriptive summary of the page.',
            max: MetaEngine.descriptionMax,
            maxLines: 3,
          ),
          const SizedBox(height: 10),
          _simpleField(
            label: seoTr(context, 'seo_meta_keywords', 'Keywords (legacy)'),
            controller: _keywordsCtrl,
            hint: 'keyword1, keyword2, keyword3',
          ),
          const SizedBox(height: 10),
          _simpleField(
            label: seoTr(context, 'seo_meta_author', 'Author'),
            controller: _authorCtrl,
            hint: 'Jane Doe',
          ),
          const SizedBox(height: 10),
          _simpleField(
            label: seoTr(context, 'seo_meta_canonical', 'Canonical URL'),
            controller: _canonicalCtrl,
            hint: 'https://example.com/page',
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _simpleField(
                  label: seoTr(context, 'seo_meta_language', 'Language'),
                  controller: _languageCtrl,
                  hint: 'en',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _simpleField(
                  label: seoTr(context, 'seo_meta_theme_color', 'Theme color'),
                  controller: _themeColorCtrl,
                  hint: '#7C4DFF',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _simpleField(
            label: seoTr(context, 'seo_meta_viewport', 'Viewport'),
            controller: _viewportCtrl,
            hint: 'width=device-width, initial-scale=1',
          ),
        ],
      ),
    );
  }

  Widget _buildRobotsCard() {
    return SeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SeoSectionTitle(
            Icons.smart_toy_outlined,
            seoTr(context, 'seo_meta_robots', 'Robots'),
          ),
          const SizedBox(height: 6),
          SeoSwitchRow(
            label: seoTr(context, 'seo_meta_robots_index', 'Allow indexing'),
            value: _config.robotsIndex,
            onChanged: (bool v) {
              setState(() => _config.robotsIndex = v);
              _regenerate();
            },
          ),
          SeoSwitchRow(
            label: seoTr(context, 'seo_meta_robots_follow', 'Allow following links'),
            value: _config.robotsFollow,
            onChanged: (bool v) {
              setState(() => _config.robotsFollow = v);
              _regenerate();
            },
          ),
          SeoSwitchRow(
            label: seoTr(context, 'seo_meta_robots_noarchive', 'No archive'),
            value: _config.robotsNoarchive,
            onChanged: (bool v) {
              setState(() => _config.robotsNoarchive = v);
              _regenerate();
            },
          ),
          SeoSwitchRow(
            label: seoTr(context, 'seo_meta_robots_nosnippet', 'No snippet'),
            value: _config.robotsNosnippet,
            onChanged: (bool v) {
              setState(() => _config.robotsNosnippet = v);
              _regenerate();
            },
          ),
          SeoSwitchRow(
            label: seoTr(context, 'seo_meta_robots_noimageindex', 'No image index'),
            value: _config.robotsNoimageindex,
            onChanged: (bool v) {
              setState(() => _config.robotsNoimageindex = v);
              _regenerate();
            },
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Text(
              _config.robotsContent,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOgCard() {
    return SeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: SeoSectionTitle(
                  Icons.share_outlined,
                  seoTr(context, 'seo_meta_og', 'Open Graph'),
                ),
              ),
              Switch.adaptive(
                value: _config.ogEnabled,
                onChanged: (bool v) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _config.ogEnabled = v;
                    _showOg = v;
                  });
                  _regenerate();
                },
              ),
            ],
          ),
          if (_config.ogEnabled) ...<Widget>[
            const SizedBox(height: 12),
            SeoChipPicker<OgType>(
              label: seoTr(context, 'seo_meta_og_type', 'Type'),
              values: OgType.values,
              current: _config.ogType,
              labelOf: (OgType v) => v.display,
              onChanged: (OgType v) {
                setState(() => _config.ogType = v);
                _regenerate();
              },
            ),
            const SizedBox(height: 12),
            _simpleField(
              label: seoTr(context, 'seo_meta_og_title', 'og:title'),
              controller: _ogTitleCtrl,
              hint: seoTr(context, 'seo_meta_fallback_title',
                  'Falls back to <title>'),
            ),
            const SizedBox(height: 10),
            _simpleField(
              label: seoTr(context, 'seo_meta_og_description', 'og:description'),
              controller: _ogDescCtrl,
              hint: seoTr(context, 'seo_meta_fallback_desc',
                  'Falls back to description'),
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            _simpleField(
              label: seoTr(context, 'seo_meta_og_image', 'og:image'),
              controller: _ogImageCtrl,
              hint: 'https://example.com/og.png (1200×630)',
            ),
            const SizedBox(height: 10),
            _simpleField(
              label: seoTr(context, 'seo_meta_og_url', 'og:url'),
              controller: _ogUrlCtrl,
              hint: seoTr(context, 'seo_meta_fallback_canonical',
                  'Falls back to canonical'),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: _simpleField(
                    label: seoTr(context, 'seo_meta_og_site', 'og:site_name'),
                    controller: _ogSiteNameCtrl,
                    hint: 'MiniTools',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _simpleField(
                    label: seoTr(context, 'seo_meta_og_locale', 'og:locale'),
                    controller: _ogLocaleCtrl,
                    hint: 'en_US',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTwitterCard() {
    return SeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: SeoSectionTitle(
                  Icons.alternate_email_rounded,
                  seoTr(context, 'seo_meta_twitter', 'Twitter Card'),
                ),
              ),
              Switch.adaptive(
                value: _config.twitterEnabled,
                onChanged: (bool v) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _config.twitterEnabled = v;
                    _showTwitter = v;
                  });
                  _regenerate();
                },
              ),
            ],
          ),
          if (_config.twitterEnabled) ...<Widget>[
            const SizedBox(height: 12),
            SeoChipPicker<TwitterCardType>(
              label: seoTr(context, 'seo_meta_twitter_card', 'Card type'),
              values: TwitterCardType.values,
              current: _config.twitterCard,
              labelOf: (TwitterCardType v) => v.display,
              onChanged: (TwitterCardType v) {
                setState(() => _config.twitterCard = v);
                _regenerate();
              },
            ),
            const SizedBox(height: 12),
            _simpleField(
              label: 'twitter:title',
              controller: _twTitleCtrl,
              hint: seoTr(context, 'seo_meta_fallback_title',
                  'Falls back to <title>'),
            ),
            const SizedBox(height: 10),
            _simpleField(
              label: 'twitter:description',
              controller: _twDescCtrl,
              hint: seoTr(context, 'seo_meta_fallback_desc',
                  'Falls back to description'),
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            _simpleField(
              label: 'twitter:image',
              controller: _twImageCtrl,
              hint: seoTr(context, 'seo_meta_fallback_og_image',
                  'Falls back to og:image'),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: _simpleField(
                    label: 'twitter:site',
                    controller: _twSiteCtrl,
                    hint: '@yourbrand',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _simpleField(
                    label: 'twitter:creator',
                    controller: _twCreatorCtrl,
                    hint: '@author',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFaviconCard() {
    return SeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: SeoSectionTitle(
                  Icons.favorite_border_rounded,
                  seoTr(context, 'seo_meta_favicon', 'Favicons'),
                ),
              ),
              Switch.adaptive(
                value: _config.faviconEnabled,
                onChanged: (bool v) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _config.faviconEnabled = v;
                    _showFavicon = v;
                  });
                  _regenerate();
                },
              ),
            ],
          ),
          if (_config.faviconEnabled) ...<Widget>[
            const SizedBox(height: 12),
            _simpleField(
              label: 'favicon.ico',
              controller: _faviconCtrl,
              hint: '/favicon.ico',
            ),
            const SizedBox(height: 10),
            _simpleField(
              label: 'icon (SVG)',
              controller: _iconSvgCtrl,
              hint: '/icon.svg',
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: _simpleField(
                    label: '32×32 PNG',
                    controller: _icon32Ctrl,
                    hint: '/icon-32.png',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _simpleField(
                    label: '16×16 PNG',
                    controller: _icon16Ctrl,
                    hint: '/icon-16.png',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _simpleField(
              label: 'apple-touch-icon',
              controller: _appleIconCtrl,
              hint: '/apple-touch-icon.png (180×180)',
            ),
            const SizedBox(height: 10),
            _simpleField(
              label: 'manifest',
              controller: _manifestCtrl,
              hint: '/site.webmanifest',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOutputCard() {
    return SeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: SeoSectionTitle(
                  Icons.code_rounded,
                  seoTr(context, 'seo_meta_output', 'Generated <head>'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SeoOutputBlock(
            label: 'HTML',
            value: _output,
            copied: _copied,
            onCopy: _copy,
            maxHeight: 400,
          ),
        ],
      ),
    );
  }

  Widget _textFieldWithCounter({
    required String label,
    required TextEditingController controller,
    required String hint,
    required int max,
    int? maxLines = 1,
  }) {
    return SeoTextField(
      label: label,
      controller: controller,
      hint: hint,
      maxLines: maxLines,
      counterMax: max,
      onChanged: (_) => _scheduleRegen(),
    );
  }

  Widget _simpleField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SeoIconButton(
              icon: Icons.content_paste_rounded,
              tooltip: seoTr(context, 'seo_paste', 'Paste'),
              onTap: () => _pasteInto(controller),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SeoTextField(
          controller: controller,
          hint: hint,
          maxLines: maxLines,
          minLines: maxLines > 1 ? maxLines - 1 : null,
          onChanged: (_) => _scheduleRegen(),
        ),
      ],
    );
  }
}