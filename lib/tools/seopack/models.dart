import 'package:flutter/material.dart';

// ============================================================================
// SITEMAP
// ============================================================================


enum SitemapMode { urlset, sitemapIndex }

extension SitemapModeX on SitemapMode {
  String get display {
    switch (this) {
      case SitemapMode.urlset:
        return 'urlset';
      case SitemapMode.sitemapIndex:
        return 'sitemapindex';
    }
  }
}

enum ChangeFreq { always, hourly, daily, weekly, monthly, yearly, never }

extension ChangeFreqX on ChangeFreq {
  String get display {
    switch (this) {
      case ChangeFreq.always:
        return 'always';
      case ChangeFreq.hourly:
        return 'hourly';
      case ChangeFreq.daily:
        return 'daily';
      case ChangeFreq.weekly:
        return 'weekly';
      case ChangeFreq.monthly:
        return 'monthly';
      case ChangeFreq.yearly:
        return 'yearly';
      case ChangeFreq.never:
        return 'never';
    }
  }
}

class SitemapUrlEntry {
  SitemapUrlEntry({
    required this.loc,
    this.lastmod,
    this.changeFreq,
    this.priority,
  });

  String loc;
  String? lastmod;
  ChangeFreq? changeFreq;
  double? priority;

  SitemapUrlEntry clone() => SitemapUrlEntry(
    loc: loc,
    lastmod: lastmod,
    changeFreq: changeFreq,
    priority: priority,
  );
}

class SitemapIndexEntry {
  SitemapIndexEntry({required this.loc, this.lastmod});

  String loc;
  String? lastmod;

  SitemapIndexEntry clone() =>
      SitemapIndexEntry(loc: loc, lastmod: lastmod);
}

class SitemapConfig {
  SitemapConfig({
    this.mode = SitemapMode.urlset,
    this.includeXmlDeclaration = true,
    this.includeXsl = false,
    this.xslHref = '',
    this.applyDefaults = false,
    this.defaultChangeFreq = ChangeFreq.weekly,
    this.defaultPriority = 0.5,
    List<SitemapUrlEntry>? urls,
    List<SitemapIndexEntry>? indexes,
  })  : urls = urls ?? <SitemapUrlEntry>[],
        indexes = indexes ?? <SitemapIndexEntry>[];

  SitemapMode mode;
  bool includeXmlDeclaration;
  bool includeXsl;
  String xslHref;
  bool applyDefaults;
  ChangeFreq defaultChangeFreq;
  double defaultPriority;
  final List<SitemapUrlEntry> urls;
  final List<SitemapIndexEntry> indexes;

  void clear() {
    urls.clear();
    indexes.clear();
  }
}

// ============================================================================
// REDIRECT
// ============================================================================

enum RedirectStatus { s301, s302, s303, s307, s308 }

extension RedirectStatusX on RedirectStatus {
  int get code {
    switch (this) {
      case RedirectStatus.s301:
        return 301;
      case RedirectStatus.s302:
        return 302;
      case RedirectStatus.s303:
        return 303;
      case RedirectStatus.s307:
        return 307;
      case RedirectStatus.s308:
        return 308;
    }
  }

  String get display {
    switch (this) {
      case RedirectStatus.s301:
        return '301 Permanent';
      case RedirectStatus.s302:
        return '302 Temporary';
      case RedirectStatus.s303:
        return '303 See Other';
      case RedirectStatus.s307:
        return '307 Temporary (preserve method)';
      case RedirectStatus.s308:
        return '308 Permanent (preserve method)';
    }
  }
}

enum RedirectFormat { htaccess, nginx, netlify, vercel, cloudflare }

extension RedirectFormatX on RedirectFormat {
  String get display {
    switch (this) {
      case RedirectFormat.htaccess:
        return 'Apache .htaccess';
      case RedirectFormat.nginx:
        return 'Nginx';
      case RedirectFormat.netlify:
        return 'Netlify _redirects';
      case RedirectFormat.vercel:
        return 'Vercel vercel.json';
      case RedirectFormat.cloudflare:
        return 'Cloudflare _redirects';
    }
  }

  String get filename {
    switch (this) {
      case RedirectFormat.htaccess:
        return '.htaccess';
      case RedirectFormat.nginx:
        return 'nginx.conf';
      case RedirectFormat.netlify:
        return '_redirects';
      case RedirectFormat.vercel:
        return 'vercel.json';
      case RedirectFormat.cloudflare:
        return '_redirects';
    }
  }
}

class RedirectRule {
  RedirectRule({
    required this.from,
    required this.to,
    this.status = RedirectStatus.s301,
    this.preserveQuery = true,
    this.forceHttps = false,
    this.removeWww = false,
    this.addWww = false,
    this.removeTrailingSlash = false,
  });

  String from;
  String to;
  RedirectStatus status;
  bool preserveQuery;
  bool forceHttps;
  bool removeWww;
  bool addWww;
  bool removeTrailingSlash;

  RedirectRule clone() => RedirectRule(
    from: from,
    to: to,
    status: status,
    preserveQuery: preserveQuery,
    forceHttps: forceHttps,
    removeWww: removeWww,
    addWww: addWww,
    removeTrailingSlash: removeTrailingSlash,
  );
}

class RedirectConfig {
  RedirectConfig({
    this.format = RedirectFormat.htaccess,
    List<RedirectRule>? rules,
  }) : rules = rules ?? <RedirectRule>[];

  RedirectFormat format;
  final List<RedirectRule> rules;

  void clear() => rules.clear();
}

// ============================================================================
// META
// ============================================================================

enum TwitterCardType { summary, summaryLargeImage, app, player }

extension TwitterCardTypeX on TwitterCardType {
  String get value {
    switch (this) {
      case TwitterCardType.summary:
        return 'summary';
      case TwitterCardType.summaryLargeImage:
        return 'summary_large_image';
      case TwitterCardType.app:
        return 'app';
      case TwitterCardType.player:
        return 'player';
    }
  }

  String get display {
    switch (this) {
      case TwitterCardType.summary:
        return 'Summary';
      case TwitterCardType.summaryLargeImage:
        return 'Summary (Large Image)';
      case TwitterCardType.app:
        return 'App';
      case TwitterCardType.player:
        return 'Player';
    }
  }
}

enum OgType {
  website,
  article,
  product,
  profile,
  videoMovie,
  musicSong,
  book,
}

extension OgTypeX on OgType {
  String get value {
    switch (this) {
      case OgType.website:
        return 'website';
      case OgType.article:
        return 'article';
      case OgType.product:
        return 'product';
      case OgType.profile:
        return 'profile';
      case OgType.videoMovie:
        return 'video.movie';
      case OgType.musicSong:
        return 'music.song';
      case OgType.book:
        return 'book';
    }
  }

  String get display {
    switch (this) {
      case OgType.website:
        return 'Website';
      case OgType.article:
        return 'Article';
      case OgType.product:
        return 'Product';
      case OgType.profile:
        return 'Profile';
      case OgType.videoMovie:
        return 'Video';
      case OgType.musicSong:
        return 'Music';
      case OgType.book:
        return 'Book';
    }
  }
}

class MetaConfig {
  MetaConfig({
    this.title = '',
    this.description = '',
    this.keywords = '',
    this.author = '',
    this.canonical = '',
    this.language = '',
    this.viewport = 'width=device-width, initial-scale=1',
    this.themeColor = '',
    this.robotsIndex = true,
    this.robotsFollow = true,
    this.robotsNoarchive = false,
    this.robotsNosnippet = false,
    this.robotsNoimageindex = false,
    this.ogEnabled = true,
    this.ogType = OgType.website,
    this.ogTitle = '',
    this.ogDescription = '',
    this.ogImage = '',
    this.ogUrl = '',
    this.ogSiteName = '',
    this.ogLocale = '',
    this.twitterEnabled = true,
    this.twitterCard = TwitterCardType.summaryLargeImage,
    this.twitterTitle = '',
    this.twitterDescription = '',
    this.twitterImage = '',
    this.twitterSite = '',
    this.twitterCreator = '',
    this.faviconEnabled = false,
    this.faviconIco = '',
    this.appleTouchIcon = '',
    this.manifest = '',
    this.iconSvg = '',
    this.icon32 = '',
    this.icon16 = '',
  });

  String title;
  String description;
  String keywords;
  String author;
  String canonical;
  String language;
  String viewport;
  String themeColor;

  bool robotsIndex;
  bool robotsFollow;
  bool robotsNoarchive;
  bool robotsNosnippet;
  bool robotsNoimageindex;

  bool ogEnabled;
  OgType ogType;
  String ogTitle;
  String ogDescription;
  String ogImage;
  String ogUrl;
  String ogSiteName;
  String ogLocale;

  bool twitterEnabled;
  TwitterCardType twitterCard;
  String twitterTitle;
  String twitterDescription;
  String twitterImage;
  String twitterSite;
  String twitterCreator;

  bool faviconEnabled;
  String faviconIco;
  String appleTouchIcon;
  String manifest;
  String iconSvg;
  String icon32;
  String icon16;

  String get robotsContent {
    final List<String> parts = <String>[];
    parts.add(robotsIndex ? 'index' : 'noindex');
    parts.add(robotsFollow ? 'follow' : 'nofollow');
    if (robotsNoarchive) parts.add('noarchive');
    if (robotsNosnippet) parts.add('nosnippet');
    if (robotsNoimageindex) parts.add('noimageindex');
    return parts.join(', ');
  }
}

// ============================================================================
// JSON-LD
// ============================================================================

enum SchemaType {
  article,
  blogPosting,
  product,
  organization,
  person,
  event,
  faqPage,
  breadcrumbList,
  recipe,
  localBusiness,
  webSite,
}

extension SchemaTypeX on SchemaType {
  String get schemaOrgType {
    switch (this) {
      case SchemaType.article:
        return 'Article';
      case SchemaType.blogPosting:
        return 'BlogPosting';
      case SchemaType.product:
        return 'Product';
      case SchemaType.organization:
        return 'Organization';
      case SchemaType.person:
        return 'Person';
      case SchemaType.event:
        return 'Event';
      case SchemaType.faqPage:
        return 'FAQPage';
      case SchemaType.breadcrumbList:
        return 'BreadcrumbList';
      case SchemaType.recipe:
        return 'Recipe';
      case SchemaType.localBusiness:
        return 'LocalBusiness';
      case SchemaType.webSite:
        return 'WebSite';
    }
  }

  String get display {
    switch (this) {
      case SchemaType.article:
        return 'Article';
      case SchemaType.blogPosting:
        return 'Blog Posting';
      case SchemaType.product:
        return 'Product';
      case SchemaType.organization:
        return 'Organization';
      case SchemaType.person:
        return 'Person';
      case SchemaType.event:
        return 'Event';
      case SchemaType.faqPage:
        return 'FAQ Page';
      case SchemaType.breadcrumbList:
        return 'Breadcrumb List';
      case SchemaType.recipe:
        return 'Recipe';
      case SchemaType.localBusiness:
        return 'Local Business';
      case SchemaType.webSite:
        return 'WebSite';
    }
  }
}

class FaqItem {
  FaqItem({required this.question, required this.answer});

  String question;
  String answer;

  FaqItem clone() => FaqItem(question: question, answer: answer);
}

class BreadcrumbItem {
  BreadcrumbItem({required this.name, required this.url});

  String name;
  String url;

  BreadcrumbItem clone() => BreadcrumbItem(name: name, url: url);
}

class RecipeIngredient {
  RecipeIngredient(this.value);

  String value;

  RecipeIngredient clone() => RecipeIngredient(value);
}

class RecipeStep {
  RecipeStep(this.value);

  String value;

  RecipeStep clone() => RecipeStep(value);
}

class JsonLdConfig {
  JsonLdConfig({
    this.type = SchemaType.article,
    this.context = 'https://schema.org',
    this.includeContext = true,
    this.pretty = true,

    // Common
    this.name = '',
    this.headline = '',
    this.description = '',
    this.url = '',
    this.image = '',
    this.logoUrl = '',
    this.authorName = '',
    this.authorUrl = '',
    this.publisherName = '',
    this.publisherLogo = '',
    this.datePublished = '',
    this.dateModified = '',
    this.inLanguage = '',

    // Product
    this.brand = '',
    this.sku = '',
    this.gtin = '',
    this.price = '',
    this.currency = 'USD',
    this.availability = 'https://schema.org/InStock',
    this.ratingValue = '',
    this.ratingCount = '',

    // Event
    this.startDate = '',
    this.endDate = '',
    this.locationName = '',
    this.locationAddress = '',
    this.eventStatus = 'https://schema.org/EventScheduled',

    // Person
    this.jobTitle = '',
    this.sameAs = '',
    this.email = '',
    this.telephone = '',

    // LocalBusiness
    this.streetAddress = '',
    this.city = '',
    this.region = '',
    this.postalCode = '',
    this.country = '',
    this.latitude = '',
    this.longitude = '',
    this.openingHours = '',
    this.priceRange = '',

    // WebSite
    this.searchUrlTemplate = '',
    this.siteName = '',

    List<FaqItem>? faqItems,
    List<BreadcrumbItem>? breadcrumbs,
    List<RecipeIngredient>? recipeIngredients,
    List<RecipeStep>? recipeSteps,
  })  : faqItems = faqItems ?? <FaqItem>[],
        breadcrumbs = breadcrumbs ?? <BreadcrumbItem>[],
        recipeIngredients = recipeIngredients ?? <RecipeIngredient>[],
        recipeSteps = recipeSteps ?? <RecipeStep>[];

  SchemaType type;
  String context;
  bool includeContext;
  bool pretty;

  String name;
  String headline;
  String description;
  String url;
  String image;
  String logoUrl;
  String authorName;
  String authorUrl;
  String publisherName;
  String publisherLogo;
  String datePublished;
  String dateModified;
  String inLanguage;

  String brand;
  String sku;
  String gtin;
  String price;
  String currency;
  String availability;
  String ratingValue;
  String ratingCount;

  String startDate;
  String endDate;
  String locationName;
  String locationAddress;
  String eventStatus;

  String jobTitle;
  String sameAs;
  String email;
  String telephone;

  String streetAddress;
  String city;
  String region;
  String postalCode;
  String country;
  String latitude;
  String longitude;
  String openingHours;
  String priceRange;

  String searchUrlTemplate;
  String siteName;

  final List<FaqItem> faqItems;
  final List<BreadcrumbItem> breadcrumbs;
  final List<RecipeIngredient> recipeIngredients;
  final List<RecipeStep> recipeSteps;

  void resetForType() {
    faqItems.clear();
    breadcrumbs.clear();
    recipeIngredients.clear();
    recipeSteps.clear();
  }
}

// ============================================================================
// ERRORS
// ============================================================================

class SeoErrors {
  SeoErrors._();

  static const String sitemapEmpty = 'seo_sitemap_empty';
  static const String sitemapInvalidUrl = 'seo_sitemap_invalid_url';
  static const String sitemapInvalidPriority = 'seo_sitemap_invalid_priority';
  static const String sitemapInvalidDate = 'seo_sitemap_invalid_date';

  static const String redirectEmpty = 'seo_redirect_empty';
  static const String redirectInvalidFrom = 'seo_redirect_invalid_from';
  static const String redirectInvalidTo = 'seo_redirect_invalid_to';

  static const String metaEmptyTitle = 'seo_meta_empty_title';
  static const String metaTitleTooLong = 'seo_meta_title_long';
  static const String metaDescriptionTooLong = 'seo_meta_desc_long';

  static const String jsonldEmpty = 'seo_jsonld_empty';
  static const String jsonldInvalidFaq = 'seo_jsonld_invalid_faq';
  static const String jsonldInvalidBreadcrumb = 'seo_jsonld_invalid_breadcrumb';
  static const String jsonldMissingField = 'seo_jsonld_missing_field';
}

// ============================================================================
// THEME
// ============================================================================

class SeoColors {
  SeoColors._();

  static const Color accentA = Color(0xFF43CEA2);
  static const Color accentB = Color(0xFF185A9D);
  static const Color danger = Color(0xFFFF5C5C);
  static const Color warning = Color(0xFFFFC24B);
  static const Color success = Color(0xFF4BD68B);
  static const Color bgTop = Color(0xFF06202A);
  static const Color bgMid = Color(0xFF0B3B4A);
  static const Color bgBot = Color(0xFF0A1929);
}