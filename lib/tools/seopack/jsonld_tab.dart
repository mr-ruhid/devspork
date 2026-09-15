import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'jsonld_engine.dart';
import 'models.dart';
import 'ui_kit.dart';

class JsonLdTab extends StatefulWidget {
  const JsonLdTab({super.key});

  @override
  State<JsonLdTab> createState() => _JsonLdTabState();
}

class _JsonLdTabState extends State<JsonLdTab> {
  final JsonLdConfig _config = JsonLdConfig();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _headlineCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _urlCtrl = TextEditingController();
  final TextEditingController _imageCtrl = TextEditingController();
  final TextEditingController _logoCtrl = TextEditingController();
  final TextEditingController _authorNameCtrl = TextEditingController();
  final TextEditingController _authorUrlCtrl = TextEditingController();
  final TextEditingController _publisherCtrl = TextEditingController();
  final TextEditingController _publisherLogoCtrl = TextEditingController();
  final TextEditingController _datePubCtrl = TextEditingController();
  final TextEditingController _dateModCtrl = TextEditingController();
  final TextEditingController _inLangCtrl = TextEditingController();

  final TextEditingController _brandCtrl = TextEditingController();
  final TextEditingController _skuCtrl = TextEditingController();
  final TextEditingController _gtinCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _currencyCtrl =
  TextEditingController(text: 'USD');
  final TextEditingController _availCtrl = TextEditingController(
    text: 'https://schema.org/InStock',
  );
  final TextEditingController _ratingCtrl = TextEditingController();
  final TextEditingController _ratingCountCtrl = TextEditingController();

  final TextEditingController _startDateCtrl = TextEditingController();
  final TextEditingController _endDateCtrl = TextEditingController();
  final TextEditingController _locNameCtrl = TextEditingController();
  final TextEditingController _locAddrCtrl = TextEditingController();

  final TextEditingController _jobTitleCtrl = TextEditingController();
  final TextEditingController _sameAsCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  final TextEditingController _streetCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _regionCtrl = TextEditingController();
  final TextEditingController _postalCtrl = TextEditingController();
  final TextEditingController _countryCtrl = TextEditingController();
  final TextEditingController _latCtrl = TextEditingController();
  final TextEditingController _lngCtrl = TextEditingController();
  final TextEditingController _hoursCtrl = TextEditingController();
  final TextEditingController _priceRangeCtrl = TextEditingController();

  final TextEditingController _searchUrlCtrl = TextEditingController();
  final TextEditingController _siteNameCtrl = TextEditingController();

  Timer? _debounce;
  String _output = '';
  String? _errorKey;
  String? _errorDetail;
  bool _copied = false;

  final List<TextEditingController> _faqQCtrls = <TextEditingController>[];
  final List<TextEditingController> _faqACtrls = <TextEditingController>[];
  final List<TextEditingController> _bcNameCtrls = <TextEditingController>[];
  final List<TextEditingController> _bcUrlCtrls = <TextEditingController>[];
  final List<TextEditingController> _ingCtrls = <TextEditingController>[];
  final List<TextEditingController> _stepCtrls = <TextEditingController>[];

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = 'My Page';
    _descCtrl.text = 'A description of the page.';
    _urlCtrl.text = 'https://example.com/page';
    _imageCtrl.text = 'https://example.com/image.jpg';
    _authorNameCtrl.text = 'Jane Doe';
    _publisherCtrl.text = 'MiniTools';
    _publisherLogoCtrl.text = 'https://example.com/logo.png';
    _inLangCtrl.text = 'en';
    _siteNameCtrl.text = 'MiniTools';
    _syncAll();
    _regenerate();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameCtrl.dispose();
    _headlineCtrl.dispose();
    _descCtrl.dispose();
    _urlCtrl.dispose();
    _imageCtrl.dispose();
    _logoCtrl.dispose();
    _authorNameCtrl.dispose();
    _authorUrlCtrl.dispose();
    _publisherCtrl.dispose();
    _publisherLogoCtrl.dispose();
    _datePubCtrl.dispose();
    _dateModCtrl.dispose();
    _inLangCtrl.dispose();
    _brandCtrl.dispose();
    _skuCtrl.dispose();
    _gtinCtrl.dispose();
    _priceCtrl.dispose();
    _currencyCtrl.dispose();
    _availCtrl.dispose();
    _ratingCtrl.dispose();
    _ratingCountCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    _locNameCtrl.dispose();
    _locAddrCtrl.dispose();
    _jobTitleCtrl.dispose();
    _sameAsCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _regionCtrl.dispose();
    _postalCtrl.dispose();
    _countryCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _hoursCtrl.dispose();
    _priceRangeCtrl.dispose();
    _searchUrlCtrl.dispose();
    _siteNameCtrl.dispose();
    _disposeList(_faqQCtrls);
    _disposeList(_faqACtrls);
    _disposeList(_bcNameCtrls);
    _disposeList(_bcUrlCtrls);
    _disposeList(_ingCtrls);
    _disposeList(_stepCtrls);
    super.dispose();
  }

  void _disposeList(List<TextEditingController> l) {
    for (final c in l) {
      c.dispose();
    }
    l.clear();
  }

  void _syncAll() {
    _config
      ..name = _nameCtrl.text
      ..headline = _headlineCtrl.text
      ..description = _descCtrl.text
      ..url = _urlCtrl.text
      ..image = _imageCtrl.text
      ..logoUrl = _logoCtrl.text
      ..authorName = _authorNameCtrl.text
      ..authorUrl = _authorUrlCtrl.text
      ..publisherName = _publisherCtrl.text
      ..publisherLogo = _publisherLogoCtrl.text
      ..datePublished = _datePubCtrl.text
      ..dateModified = _dateModCtrl.text
      ..inLanguage = _inLangCtrl.text
      ..brand = _brandCtrl.text
      ..sku = _skuCtrl.text
      ..gtin = _gtinCtrl.text
      ..price = _priceCtrl.text
      ..currency = _currencyCtrl.text
      ..availability = _availCtrl.text
      ..ratingValue = _ratingCtrl.text
      ..ratingCount = _ratingCountCtrl.text
      ..startDate = _startDateCtrl.text
      ..endDate = _endDateCtrl.text
      ..locationName = _locNameCtrl.text
      ..locationAddress = _locAddrCtrl.text
      ..jobTitle = _jobTitleCtrl.text
      ..sameAs = _sameAsCtrl.text
      ..email = _emailCtrl.text
      ..telephone = _phoneCtrl.text
      ..streetAddress = _streetCtrl.text
      ..city = _cityCtrl.text
      ..region = _regionCtrl.text
      ..postalCode = _postalCtrl.text
      ..country = _countryCtrl.text
      ..latitude = _latCtrl.text
      ..longitude = _lngCtrl.text
      ..openingHours = _hoursCtrl.text
      ..priceRange = _priceRangeCtrl.text
      ..searchUrlTemplate = _searchUrlCtrl.text
      ..siteName = _siteNameCtrl.text;
  }

  void _scheduleRegen() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), _regenerate);
  }

  void _regenerate() {
    _syncAll();

    _config.faqItems
      ..clear()
      ..addAll(List<FaqItem>.generate(
        _faqQCtrls.length,
            (int i) => FaqItem(
          question: _faqQCtrls[i].text,
          answer: _faqACtrls[i].text,
        ),
      ));

    _config.breadcrumbs
      ..clear()
      ..addAll(List<BreadcrumbItem>.generate(
        _bcNameCtrls.length,
            (int i) => BreadcrumbItem(
          name: _bcNameCtrls[i].text,
          url: _bcUrlCtrls[i].text,
        ),
      ));

    _config.recipeIngredients
      ..clear()
      ..addAll(_ingCtrls.map((TextEditingController c) =>
          RecipeIngredient(c.text)));

    _config.recipeSteps
      ..clear()
      ..addAll(_stepCtrls.map((TextEditingController c) =>
          RecipeStep(c.text)));

    try {
      final String raw = JsonLdEngine.buildRaw(_config);
      final String out = '<script type="application/ld+json">\n$raw\n</script>';
      if (!mounted) return;
      setState(() {
        _output = out;
        _errorKey = null;
        _errorDetail = null;
      });
    } on JsonLdException catch (e) {
      if (!mounted) return;
      setState(() {
        _output = '';
        _errorKey = e.errorKey;
        _errorDetail = e.detail;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _output = '';
        _errorKey = SeoErrors.jsonldEmpty;
        _errorDetail = e.toString();
      });
    }
  }

  void _changeType(SchemaType t) {
    if (_config.type == t) return;
    setState(() {
      _config.type = t;
      _regenerate();
    });
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

  void _addFaq() {
    HapticFeedback.selectionClick();
    setState(() {
      _faqQCtrls.add(TextEditingController());
      _faqACtrls.add(TextEditingController());
      _regenerate();
    });
  }

  void _removeFaq(int i) {
    HapticFeedback.mediumImpact();
    setState(() {
      _faqQCtrls.removeAt(i).dispose();
      _faqACtrls.removeAt(i).dispose();
      _regenerate();
    });
  }

  void _addBreadcrumb() {
    HapticFeedback.selectionClick();
    setState(() {
      _bcNameCtrls.add(TextEditingController());
      _bcUrlCtrls.add(TextEditingController());
      _regenerate();
    });
  }

  void _removeBreadcrumb(int i) {
    HapticFeedback.mediumImpact();
    setState(() {
      _bcNameCtrls.removeAt(i).dispose();
      _bcUrlCtrls.removeAt(i).dispose();
      _regenerate();
    });
  }

  void _addIngredient() {
    HapticFeedback.selectionClick();
    setState(() {
      _ingCtrls.add(TextEditingController());
      _regenerate();
    });
  }

  void _removeIngredient(int i) {
    HapticFeedback.mediumImpact();
    setState(() {
      _ingCtrls.removeAt(i).dispose();
      _regenerate();
    });
  }

  void _addStep() {
    HapticFeedback.selectionClick();
    setState(() {
      _stepCtrls.add(TextEditingController());
      _regenerate();
    });
  }

  void _removeStep(int i) {
    HapticFeedback.mediumImpact();
    setState(() {
      _stepCtrls.removeAt(i).dispose();
      _regenerate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildTypeCard(),
          const SizedBox(height: 14),
          ..._buildTypeSpecificFields(),
          if (_errorKey != null) ...<Widget>[
            const SizedBox(height: 14),
            SeoErrorBox(errorKey: _errorKey!, detail: _errorDetail),
          ],
          const SizedBox(height: 14),
          _buildOutputCard(),
        ],
      ),
    );
  }

  Widget _buildTypeCard() {
    return SeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SeoSectionTitle(
            Icons.category_outlined,
            seoTr(context, 'seo_jsonld_type', 'Schema type'),
          ),
          const SizedBox(height: 10),
          SeoChipPicker<SchemaType>(
            values: SchemaType.values,
            current: _config.type,
            labelOf: (SchemaType v) => v.display,
            onChanged: _changeType,
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: SeoSwitchRow(
                  label: seoTr(context, 'seo_jsonld_context', 'Include @context'),
                  value: _config.includeContext,
                  onChanged: (bool v) {
                    setState(() => _config.includeContext = v);
                    _regenerate();
                  },
                ),
              ),
            ],
          ),
          SeoSwitchRow(
            label: seoTr(context, 'seo_jsonld_pretty', 'Pretty JSON'),
            value: _config.pretty,
            onChanged: (bool v) {
              setState(() => _config.pretty = v);
              _regenerate();
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTypeSpecificFields() {
    switch (_config.type) {
      case SchemaType.article:
      case SchemaType.blogPosting:
        return _buildArticleFields();
      case SchemaType.product:
        return _buildProductFields();
      case SchemaType.organization:
        return _buildOrganizationFields();
      case SchemaType.person:
        return _buildPersonFields();
      case SchemaType.event:
        return _buildEventFields();
      case SchemaType.faqPage:
        return _buildFaqFields();
      case SchemaType.breadcrumbList:
        return _buildBreadcrumbFields();
      case SchemaType.recipe:
        return _buildRecipeFields();
      case SchemaType.localBusiness:
        return _buildLocalBusinessFields();
      case SchemaType.webSite:
        return _buildWebSiteFields();
    }
  }

  // ==========================================================================
  // ARTICLE
  // ==========================================================================

  List<Widget> _buildArticleFields() {
    return <Widget>[
      _card('Article', Icons.article_outlined, <Widget>[
        _field('headline', _headlineCtrl, 'My article headline'),
        _field('name', _nameCtrl, 'Article name'),
        _field('description', _descCtrl, 'Short summary…', maxLines: 2),
        _field('url', _urlCtrl, 'https://example.com/article'),
        _field('image', _imageCtrl, 'https://example.com/cover.jpg'),
        _field('inLanguage', _inLangCtrl, 'en'),
        _field('datePublished', _datePubCtrl, '2024-01-15T10:00:00Z'),
        _field('dateModified', _dateModCtrl, '2024-06-01T12:00:00Z'),
      ]),
      const SizedBox(height: 14),
      _card('Author', Icons.person_outline, <Widget>[
        _field('author name', _authorNameCtrl, 'Jane Doe'),
        _field('author url', _authorUrlCtrl, 'https://example.com/jane'),
      ]),
      const SizedBox(height: 14),
      _card('Publisher', Icons.business_outlined, <Widget>[
        _field('publisher name', _publisherCtrl, 'MiniTools'),
        _field('publisher logo', _publisherLogoCtrl,
            'https://example.com/logo.png'),
      ]),
      const SizedBox(height: 14),
    ];
  }

  // ==========================================================================
  // PRODUCT
  // ==========================================================================

  List<Widget> _buildProductFields() {
    return <Widget>[
      _card('Product', Icons.shopping_bag_outlined, <Widget>[
        _field('name', _nameCtrl, 'Product name'),
        _field('description', _descCtrl, 'Product description…', maxLines: 2),
        _field('image', _imageCtrl, 'https://example.com/product.jpg'),
        _field('url', _urlCtrl, 'https://example.com/product'),
        _field('brand', _brandCtrl, 'Acme'),
        _field('sku', _skuCtrl, 'SKU-12345'),
        _field('gtin', _gtinCtrl, '0123456789012'),
      ]),
      const SizedBox(height: 14),
      _card('Offer', Icons.local_offer_outlined, <Widget>[
        _field('price', _priceCtrl, '99.99'),
        _field('currency', _currencyCtrl, 'USD'),
        _field('availability', _availCtrl,
            'https://schema.org/InStock'),
      ]),
      const SizedBox(height: 14),
      _card('Rating', Icons.star_outline_rounded, <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: _field('rating value', _ratingCtrl, '4.5')),
            const SizedBox(width: 10),
            Expanded(
              child: _field('review count', _ratingCountCtrl, '128'),
            ),
          ],
        ),
      ]),
      const SizedBox(height: 14),
    ];
  }

  // ==========================================================================
  // ORGANIZATION
  // ==========================================================================

  List<Widget> _buildOrganizationFields() {
    return <Widget>[
      _card('Organization', Icons.business_rounded, <Widget>[
        _field('name', _nameCtrl, 'MiniTools Inc.'),
        _field('url', _urlCtrl, 'https://example.com'),
        _field('description', _descCtrl, 'About the company…', maxLines: 2),
        _field('logo url', _logoCtrl, 'https://example.com/logo.png'),
        _field('email', _emailCtrl, 'hello@example.com'),
        _field('telephone', _phoneCtrl, '+1 555 1234'),
        _field('sameAs (comma/newline)', _sameAsCtrl,
            'https://twitter.com/brand\nhttps://github.com/brand',
            maxLines: 3),
      ]),
      const SizedBox(height: 14),
      _addressCard(),
      const SizedBox(height: 14),
    ];
  }

  // ==========================================================================
  // PERSON
  // ==========================================================================

  List<Widget> _buildPersonFields() {
    return <Widget>[
      _card('Person', Icons.person_rounded, <Widget>[
        _field('name', _nameCtrl, 'Jane Doe'),
        _field('url', _urlCtrl, 'https://example.com/jane'),
        _field('job title', _jobTitleCtrl, 'Software Engineer'),
        _field('image', _imageCtrl, 'https://example.com/jane.jpg'),
        _field('description', _descCtrl, 'Short bio…', maxLines: 2),
        _field('email', _emailCtrl, 'jane@example.com'),
        _field('telephone', _phoneCtrl, '+1 555 1234'),
        _field('sameAs (comma/newline)', _sameAsCtrl,
            'https://twitter.com/jane\nhttps://github.com/jane',
            maxLines: 3),
      ]),
      const SizedBox(height: 14),
    ];
  }

  // ==========================================================================
  // EVENT
  // ==========================================================================

  List<Widget> _buildEventFields() {
    return <Widget>[
      _card('Event', Icons.event_outlined, <Widget>[
        _field('name', _nameCtrl, 'Dev Conference 2024'),
        _field('description', _descCtrl, 'Event details…', maxLines: 2),
        _field('url', _urlCtrl, 'https://example.com/event'),
        _field('image', _imageCtrl, 'https://example.com/event.jpg'),
        _field('start date', _startDateCtrl, '2024-09-15T09:00:00Z'),
        _field('end date', _endDateCtrl, '2024-09-15T18:00:00Z'),
        _field('inLanguage', _inLangCtrl, 'en'),
      ]),
      const SizedBox(height: 14),
      _card('Location', Icons.place_outlined, <Widget>[
        _field('name', _locNameCtrl, 'Convention Center'),
        _field('address', _locAddrCtrl, '123 Main St', maxLines: 2),
      ]),
      const SizedBox(height: 14),
      _card('Offer', Icons.local_offer_outlined, <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: _field('price', _priceCtrl, '49.00')),
            const SizedBox(width: 10),
            Expanded(child: _field('currency', _currencyCtrl, 'USD')),
          ],
        ),
      ]),
      const SizedBox(height: 14),
    ];
  }

  // ==========================================================================
  // FAQ
  // ==========================================================================

  List<Widget> _buildFaqFields() {
    return <Widget>[
      _card(
        'FAQ',
        Icons.question_answer_outlined,
        <Widget>[
          if (_faqQCtrls.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                seoTr(context, 'seo_jsonld_faq_empty',
                    'No items yet. Add your first question.'),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          for (int i = 0; i < _faqQCtrls.length; i++) ...<Widget>[
            _faqItem(i),
            if (i < _faqQCtrls.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
          SeoPrimaryButton(
            icon: Icons.add_rounded,
            label: seoTr(context, 'seo_jsonld_add_faq', 'Add question'),
            onTap: _addFaq,
          ),
        ],
      ),
      const SizedBox(height: 14),
    ];
  }

  Widget _faqItem(int i) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: SeoColors.accentA.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '#${i + 1}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              SeoIconButton(
                icon: Icons.close_rounded,
                tooltip: seoTr(context, 'seo_remove', 'Remove'),
                onTap: () => _removeFaq(i),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _fieldRaw('Question', _faqQCtrls[i], 'What is…?'),
          const SizedBox(height: 8),
          _fieldRaw('Answer', _faqACtrls[i], 'The answer is…', maxLines: 3),
        ],
      ),
    );
  }

  // ==========================================================================
  // BREADCRUMB
  // ==========================================================================

  List<Widget> _buildBreadcrumbFields() {
    return <Widget>[
      _card(
        'Breadcrumbs',
        Icons.linear_scale_rounded,
        <Widget>[
          if (_bcNameCtrls.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                seoTr(context, 'seo_jsonld_bc_empty',
                    'No items yet. Add your first breadcrumb.'),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          for (int i = 0; i < _bcNameCtrls.length; i++) ...<Widget>[
            _breadcrumbItem(i),
            if (i < _bcNameCtrls.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
          SeoPrimaryButton(
            icon: Icons.add_rounded,
            label: seoTr(context, 'seo_jsonld_add_bc', 'Add breadcrumb'),
            onTap: _addBreadcrumb,
          ),
        ],
      ),
      const SizedBox(height: 14),
    ];
  }

  Widget _breadcrumbItem(int i) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: SeoColors.accentA.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '#${i + 1}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              SeoIconButton(
                icon: Icons.close_rounded,
                tooltip: seoTr(context, 'seo_remove', 'Remove'),
                onTap: () => _removeBreadcrumb(i),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _fieldRaw('Name', _bcNameCtrls[i], 'Home'),
          const SizedBox(height: 8),
          _fieldRaw('URL', _bcUrlCtrls[i], 'https://example.com/',
              monospace: true),
        ],
      ),
    );
  }

  // ==========================================================================
  // RECIPE
  // ==========================================================================

  List<Widget> _buildRecipeFields() {
    return <Widget>[
      _card('Recipe', Icons.restaurant_menu_rounded, <Widget>[
        _field('name', _nameCtrl, 'Chocolate Cake'),
        _field('description', _descCtrl, 'Rich, moist chocolate cake…',
            maxLines: 2),
        _field('image', _imageCtrl, 'https://example.com/cake.jpg'),
        _field('author name', _authorNameCtrl, 'Jane Baker'),
        _field('date published', _datePubCtrl, '2024-01-15T10:00:00Z'),
        _field('inLanguage', _inLangCtrl, 'en'),
        _field('cook time', _hoursCtrl, 'PT45M'),
      ]),
      const SizedBox(height: 14),
      _card(
        'Ingredients',
        Icons.egg_outlined,
        <Widget>[
          for (int i = 0; i < _ingCtrls.length; i++) ...<Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: SeoTextField(
                    controller: _ingCtrls[i],
                    hint: '2 cups flour',
                    onChanged: (_) => _scheduleRegen(),
                  ),
                ),
                const SizedBox(width: 6),
                SeoIconButton(
                  icon: Icons.close_rounded,
                  tooltip: seoTr(context, 'seo_remove', 'Remove'),
                  onTap: () => _removeIngredient(i),
                ),
              ],
            ),
            if (i < _ingCtrls.length - 1) const SizedBox(height: 8),
          ],
          const SizedBox(height: 12),
          SeoPrimaryButton(
            icon: Icons.add_rounded,
            label: seoTr(context, 'seo_jsonld_add_ing', 'Add ingredient'),
            onTap: _addIngredient,
          ),
        ],
      ),
      const SizedBox(height: 14),
      _card(
        'Steps',
        Icons.format_list_numbered_rounded,
        <Widget>[
          for (int i = 0; i < _stepCtrls.length; i++) ...<Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: SeoTextField(
                    controller: _stepCtrls[i],
                    hint: 'Preheat oven to 180°C…',
                    maxLines: 2,
                    minLines: 1,
                    onChanged: (_) => _scheduleRegen(),
                  ),
                ),
                const SizedBox(width: 6),
                SeoIconButton(
                  icon: Icons.close_rounded,
                  tooltip: seoTr(context, 'seo_remove', 'Remove'),
                  onTap: () => _removeStep(i),
                ),
              ],
            ),
            if (i < _stepCtrls.length - 1) const SizedBox(height: 8),
          ],
          const SizedBox(height: 12),
          SeoPrimaryButton(
            icon: Icons.add_rounded,
            label: seoTr(context, 'seo_jsonld_add_step', 'Add step'),
            onTap: _addStep,
          ),
        ],
      ),
      const SizedBox(height: 14),
    ];
  }

  // ==========================================================================
  // LOCAL BUSINESS
  // ==========================================================================

  List<Widget> _buildLocalBusinessFields() {
    return <Widget>[
      _card('Local Business', Icons.storefront_outlined, <Widget>[
        _field('name', _nameCtrl, 'Coffee & Co.'),
        _field('description', _descCtrl, 'Best coffee in town…', maxLines: 2),
        _field('url', _urlCtrl, 'https://example.com'),
        _field('image', _imageCtrl, 'https://example.com/shop.jpg'),
        _field('telephone', _phoneCtrl, '+1 555 1234'),
        _field('email', _emailCtrl, 'hello@example.com'),
        _field('price range', _priceRangeCtrl, '\$\$'),
        _field('opening hours', _hoursCtrl, 'Mo-Fr 09:00-18:00'),
        _field('sameAs (comma/newline)', _sameAsCtrl,
            'https://twitter.com/shop\nhttps://facebook.com/shop',
            maxLines: 3),
      ]),
      const SizedBox(height: 14),
      _addressCard(),
      const SizedBox(height: 14),
    ];
  }

  // ==========================================================================
  // WEB SITE
  // ==========================================================================

  List<Widget> _buildWebSiteFields() {
    return <Widget>[
      _card('WebSite', Icons.public_rounded, <Widget>[
        _field('site name', _siteNameCtrl, 'MiniTools'),
        _field('url', _urlCtrl, 'https://example.com'),
        _field('description', _descCtrl, 'Short description…', maxLines: 2),
        _field('inLanguage', _inLangCtrl, 'en'),
        _field('search URL template', _searchUrlCtrl,
            'https://example.com/search?q={search_term_string}',
            monospace: true),
      ]),
      const SizedBox(height: 14),
    ];
  }

  // ==========================================================================
  // SHARED
  // ==========================================================================

  Widget _addressCard() {
    return _card('Address', Icons.location_on_outlined, <Widget>[
      _field('street', _streetCtrl, '123 Main St'),
      const SizedBox(height: 8),
      Row(
        children: <Widget>[
          Expanded(child: _field('city', _cityCtrl, 'San Francisco')),
          const SizedBox(width: 10),
          Expanded(child: _field('region', _regionCtrl, 'CA')),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: <Widget>[
          Expanded(child: _field('postal code', _postalCtrl, '94103')),
          const SizedBox(width: 10),
          Expanded(child: _field('country', _countryCtrl, 'US')),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: <Widget>[
          Expanded(child: _field('latitude', _latCtrl, '37.7749')),
          const SizedBox(width: 10),
          Expanded(child: _field('longitude', _lngCtrl, '-122.4194')),
        ],
      ),
    ]);
  }

  Widget _card(String title, IconData icon, List<Widget> children) {
    return SeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SeoSectionTitle(icon, title),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _field(
      String label,
      TextEditingController ctrl,
      String hint, {
        int maxLines = 1,
        bool monospace = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: _fieldRaw(
        label,
        ctrl,
        hint,
        maxLines: maxLines,
        monospace: monospace,
      ),
    );
  }

  Widget _fieldRaw(
      String label,
      TextEditingController ctrl,
      String hint, {
        int maxLines = 1,
        bool monospace = false,
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
              onTap: () => _pasteInto(ctrl),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SeoTextField(
          controller: ctrl,
          hint: hint,
          maxLines: maxLines,
          minLines: maxLines > 1 ? maxLines - 1 : null,
          monospace: monospace,
          onChanged: (_) => _scheduleRegen(),
        ),
      ],
    );
  }

  Widget _buildOutputCard() {
    return SeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SeoSectionTitle(
            Icons.code_rounded,
            seoTr(context, 'seo_jsonld_output', 'JSON-LD output'),
          ),
          const SizedBox(height: 10),
          SeoOutputBlock(
            label: 'JSON-LD',
            value: _output,
            copied: _copied,
            onCopy: _copy,
            emptyHint: seoTr(
              context,
              'seo_jsonld_output_empty',
              'Fill in the required fields to generate JSON-LD.',
            ),
            maxHeight: 400,
          ),
        ],
      ),
    );
  }
}