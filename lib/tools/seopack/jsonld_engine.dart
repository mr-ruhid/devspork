import 'dart:convert';

import 'models.dart';

class JsonLdException implements Exception {
  JsonLdException(this.errorKey, [this.detail]);

  final String errorKey;
  final String? detail;

  @override
  String toString() => detail == null ? errorKey : '$errorKey: $detail';
}

class JsonLdEngine {
  JsonLdEngine._();

  static Map<String, dynamic> buildMap(JsonLdConfig c) {
    final Map<String, dynamic> root = <String, dynamic>{};
    if (c.includeContext) {
      root['@context'] = c.context.trim().isEmpty
          ? 'https://schema.org'
          : c.context.trim();
    }
    root['@type'] = c.type.schemaOrgType;

    switch (c.type) {
      case SchemaType.article:
      case SchemaType.blogPosting:
        _buildArticle(c, root);
        break;
      case SchemaType.product:
        _buildProduct(c, root);
        break;
      case SchemaType.organization:
        _buildOrganization(c, root);
        break;
      case SchemaType.person:
        _buildPerson(c, root);
        break;
      case SchemaType.event:
        _buildEvent(c, root);
        break;
      case SchemaType.faqPage:
        _buildFaqPage(c, root);
        break;
      case SchemaType.breadcrumbList:
        _buildBreadcrumbList(c, root);
        break;
      case SchemaType.recipe:
        _buildRecipe(c, root);
        break;
      case SchemaType.localBusiness:
        _buildLocalBusiness(c, root);
        break;
      case SchemaType.webSite:
        _buildWebSite(c, root);
        break;
    }

    return root;
  }

  static String build(JsonLdConfig c) {
    final Map<String, dynamic> map = buildMap(c);
    final Object json = c.pretty
        ? const JsonEncoder.withIndent('  ').convert(map)
        : jsonEncode(map);
    return '<script type="application/ld+json">\n$json\n</script>';
  }

  static String buildRaw(JsonLdConfig c) {
    final Map<String, dynamic> map = buildMap(c);
    return c.pretty
        ? const JsonEncoder.withIndent('  ').convert(map)
        : jsonEncode(map);
  }

  // ==========================================================================
  // TYPE BUILDERS
  // ==========================================================================

  static void _buildArticle(JsonLdConfig c, Map<String, dynamic> out) {
    _set(out, 'headline', c.headline.isEmpty ? c.name : c.headline);
    _set(out, 'name', c.name);
    _set(out, 'description', c.description);
    _set(out, 'url', c.url);
    _set(out, 'image', c.image);
    _set(out, 'inLanguage', c.inLanguage);
    _set(out, 'datePublished', c.datePublished);
    _set(out, 'dateModified', c.dateModified);

    if (c.authorName.trim().isNotEmpty) {
      out['author'] = <String, dynamic>{
        '@type': 'Person',
        'name': c.authorName.trim(),
        if (c.authorUrl.trim().isNotEmpty) 'url': c.authorUrl.trim(),
      };
    }

    if (c.publisherName.trim().isNotEmpty) {
      out['publisher'] = <String, dynamic>{
        '@type': 'Organization',
        'name': c.publisherName.trim(),
        if (c.publisherLogo.trim().isNotEmpty)
          'logo': <String, dynamic>{
            '@type': 'ImageObject',
            'url': c.publisherLogo.trim(),
          },
      };
    }

    if (c.publisherLogo.trim().isNotEmpty &&
        c.publisherName.trim().isEmpty) {
      out['publisher'] = <String, dynamic>{
        '@type': 'Organization',
        'logo': <String, dynamic>{
          '@type': 'ImageObject',
          'url': c.publisherLogo.trim(),
        },
      };
    }
  }

  static void _buildProduct(JsonLdConfig c, Map<String, dynamic> out) {
    _set(out, 'name', c.name);
    _set(out, 'description', c.description);
    _set(out, 'image', c.image);
    _set(out, 'url', c.url);
    _set(out, 'sku', c.sku);
    _set(out, 'gtin', c.gtin);

    if (c.brand.trim().isNotEmpty) {
      out['brand'] = <String, dynamic>{
        '@type': 'Brand',
        'name': c.brand.trim(),
      };
    }

    if (c.price.trim().isNotEmpty) {
      out['offers'] = <String, dynamic>{
        '@type': 'Offer',
        'price': c.price.trim(),
        'priceCurrency': c.currency.trim().isEmpty
            ? 'USD'
            : c.currency.trim().toUpperCase(),
        if (c.url.trim().isNotEmpty) 'url': c.url.trim(),
        if (c.availability.trim().isNotEmpty)
          'availability': c.availability.trim(),
      };
    }

    if (c.ratingValue.trim().isNotEmpty &&
        c.ratingCount.trim().isNotEmpty) {
      out['aggregateRating'] = <String, dynamic>{
        '@type': 'AggregateRating',
        'ratingValue': c.ratingValue.trim(),
        'reviewCount': c.ratingCount.trim(),
      };
    }
  }

  static void _buildOrganization(JsonLdConfig c, Map<String, dynamic> out) {
    _set(out, 'name', c.name);
    _set(out, 'url', c.url);
    _set(out, 'description', c.description);
    _set(out, 'email', c.email);
    _set(out, 'telephone', c.telephone);
    if (c.logoUrl.trim().isNotEmpty) {
      out['logo'] = <String, dynamic>{
        '@type': 'ImageObject',
        'url': c.logoUrl.trim(),
      };
    }
    _setStringList(out, 'sameAs', c.sameAs);
    _setAddress(out, c);
    _setGeo(out, c);
  }

  static void _buildPerson(JsonLdConfig c, Map<String, dynamic> out) {
    _set(out, 'name', c.name);
    _set(out, 'url', c.url);
    _set(out, 'description', c.description);
    _set(out, 'email', c.email);
    _set(out, 'telephone', c.telephone);
    _set(out, 'jobTitle', c.jobTitle);
    _set(out, 'image', c.image);
    if (c.logoUrl.trim().isNotEmpty && c.image.trim().isEmpty) {
      out['image'] = c.logoUrl.trim();
    }
    _setStringList(out, 'sameAs', c.sameAs);
  }

  static void _buildEvent(JsonLdConfig c, Map<String, dynamic> out) {
    _set(out, 'name', c.name);
    _set(out, 'description', c.description);
    _set(out, 'url', c.url);
    _set(out, 'image', c.image);
    _set(out, 'startDate', c.startDate);
    _set(out, 'endDate', c.endDate);
    _set(out, 'eventStatus', c.eventStatus);
    _set(out, 'inLanguage', c.inLanguage);

    if (c.locationName.trim().isNotEmpty ||
        c.locationAddress.trim().isNotEmpty) {
      final Map<String, dynamic> loc = <String, dynamic>{
        '@type': 'Place',
      };
      if (c.locationName.trim().isNotEmpty) {
        loc['name'] = c.locationName.trim();
      }
      if (c.locationAddress.trim().isNotEmpty) {
        loc['address'] = <String, dynamic>{
          '@type': 'PostalAddress',
          'streetAddress': c.locationAddress.trim(),
          if (c.city.trim().isNotEmpty) 'addressLocality': c.city.trim(),
          if (c.region.trim().isNotEmpty) 'addressRegion': c.region.trim(),
          if (c.postalCode.trim().isNotEmpty)
            'postalCode': c.postalCode.trim(),
          if (c.country.trim().isNotEmpty)
            'addressCountry': c.country.trim(),
        };
      }
      _setGeo(loc, c);
      out['location'] = loc;
    }

    if (c.price.trim().isNotEmpty) {
      out['offers'] = <String, dynamic>{
        '@type': 'Offer',
        'price': c.price.trim(),
        'priceCurrency': c.currency.trim().isEmpty
            ? 'USD'
            : c.currency.trim().toUpperCase(),
        'availability': c.availability.trim().isEmpty
            ? 'https://schema.org/InStock'
            : c.availability.trim(),
      };
    }

    if (c.authorName.trim().isNotEmpty) {
      out['organizer'] = <String, dynamic>{
        '@type': 'Organization',
        'name': c.authorName.trim(),
        if (c.authorUrl.trim().isNotEmpty) 'url': c.authorUrl.trim(),
      };
    }
  }

  static void _buildFaqPage(JsonLdConfig c, Map<String, dynamic> out) {
    final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];
    for (int i = 0; i < c.faqItems.length; i++) {
      final FaqItem f = c.faqItems[i];
      if (f.question.trim().isEmpty || f.answer.trim().isEmpty) {
        throw JsonLdException(
          SeoErrors.jsonldInvalidFaq,
          'Item #${i + 1}: question and answer are required',
        );
      }
      items.add(<String, dynamic>{
        '@type': 'Question',
        'name': f.question.trim(),
        'acceptedAnswer': <String, dynamic>{
          '@type': 'Answer',
          'text': f.answer.trim(),
        },
      });
    }

    if (items.isEmpty) {
      throw JsonLdException(SeoErrors.jsonldEmpty);
    }

    out['mainEntity'] = items;
  }

  static void _buildBreadcrumbList(JsonLdConfig c, Map<String, dynamic> out) {
    final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];
    for (int i = 0; i < c.breadcrumbs.length; i++) {
      final BreadcrumbItem bc = c.breadcrumbs[i];
      if (bc.name.trim().isEmpty || bc.url.trim().isEmpty) {
        throw JsonLdException(
          SeoErrors.jsonldInvalidBreadcrumb,
          'Item #${i + 1}: name and url are required',
        );
      }
      items.add(<String, dynamic>{
        '@type': 'ListItem',
        'position': i + 1,
        'name': bc.name.trim(),
        'item': bc.url.trim(),
      });
    }

    if (items.isEmpty) {
      throw JsonLdException(SeoErrors.jsonldEmpty);
    }

    out['itemListElement'] = items;
  }

  static void _buildRecipe(JsonLdConfig c, Map<String, dynamic> out) {
    _set(out, 'name', c.name);
    _set(out, 'description', c.description);
    _set(out, 'image', c.image);
    _set(out, 'author', c.authorName);
    _set(out, 'datePublished', c.datePublished);
    _set(out, 'inLanguage', c.inLanguage);

    if (c.authorName.trim().isNotEmpty) {
      out['author'] = <String, dynamic>{
        '@type': 'Person',
        'name': c.authorName.trim(),
      };
    }

    if (c.ratingValue.trim().isNotEmpty &&
        c.ratingCount.trim().isNotEmpty) {
      out['aggregateRating'] = <String, dynamic>{
        '@type': 'AggregateRating',
        'ratingValue': c.ratingValue.trim(),
        'reviewCount': c.ratingCount.trim(),
      };
    }

    final List<String> ingredients = c.recipeIngredients
        .map((RecipeIngredient i) => i.value.trim())
        .where((String s) => s.isNotEmpty)
        .toList();
    if (ingredients.isNotEmpty) {
      out['recipeIngredient'] = ingredients;
    }

    final List<Map<String, dynamic>> steps = <Map<String, dynamic>>[];
    for (int i = 0; i < c.recipeSteps.length; i++) {
      final String v = c.recipeSteps[i].value.trim();
      if (v.isEmpty) continue;
      steps.add(<String, dynamic>{
        '@type': 'HowToStep',
        'position': i + 1,
        'text': v,
      });
    }
    if (steps.isNotEmpty) {
      out['recipeInstructions'] = steps;
    }

    if (c.openingHours.trim().isNotEmpty) {
      out['cookTime'] = c.openingHours.trim();
    }
  }

  static void _buildLocalBusiness(JsonLdConfig c, Map<String, dynamic> out) {
    _set(out, 'name', c.name);
    _set(out, 'description', c.description);
    _set(out, 'url', c.url);
    _set(out, 'telephone', c.telephone);
    _set(out, 'email', c.email);
    _set(out, 'priceRange', c.priceRange);

    if (c.image.trim().isNotEmpty) {
      out['image'] = c.image.trim();
    } else if (c.logoUrl.trim().isNotEmpty) {
      out['image'] = c.logoUrl.trim();
    }

    _setAddress(out, c);
    _setGeo(out, c);

    if (c.openingHours.trim().isNotEmpty) {
      out['openingHours'] = c.openingHours.trim();
    }

    _setStringList(out, 'sameAs', c.sameAs);
  }

  static void _buildWebSite(JsonLdConfig c, Map<String, dynamic> out) {
    _set(out, 'name', c.siteName.isEmpty ? c.name : c.siteName);
    _set(out, 'url', c.url);
    _set(out, 'description', c.description);
    _set(out, 'inLanguage', c.inLanguage);

    if (c.searchUrlTemplate.trim().isNotEmpty) {
      out['potentialAction'] = <String, dynamic>{
        '@type': 'SearchAction',
        'target': <String, dynamic>{
          '@type': 'EntryPoint',
          'urlTemplate': c.searchUrlTemplate.trim(),
        },
        'query-input': 'required name=search_term_string',
      };
    }
  }

  // ==========================================================================
  // HELPERS
  // ==========================================================================

  static void _set(Map<String, dynamic> out, String key, String value) {
    final String v = value.trim();
    if (v.isEmpty) return;
    out[key] = v;
  }

  static void _setStringList(
      Map<String, dynamic> out,
      String key,
      String raw,
      ) {
    final String v = raw.trim();
    if (v.isEmpty) return;
    final List<String> parts = v
        .split(RegExp(r'[\n,]+'))
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return;
    out[key] = parts.length == 1 ? parts.first : parts;
  }

  static void _setAddress(Map<String, dynamic> out, JsonLdConfig c) {
    if (c.streetAddress.trim().isEmpty &&
        c.city.trim().isEmpty &&
        c.postalCode.trim().isEmpty &&
        c.country.trim().isEmpty) {
      return;
    }
    out['address'] = <String, dynamic>{
      '@type': 'PostalAddress',
      if (c.streetAddress.trim().isNotEmpty)
        'streetAddress': c.streetAddress.trim(),
      if (c.city.trim().isNotEmpty) 'addressLocality': c.city.trim(),
      if (c.region.trim().isNotEmpty) 'addressRegion': c.region.trim(),
      if (c.postalCode.trim().isNotEmpty)
        'postalCode': c.postalCode.trim(),
      if (c.country.trim().isNotEmpty) 'addressCountry': c.country.trim(),
    };
  }

  static void _setGeo(Map<String, dynamic> out, JsonLdConfig c) {
    if (c.latitude.trim().isEmpty || c.longitude.trim().isEmpty) return;
    final double? lat = double.tryParse(c.latitude.trim());
    final double? lng = double.tryParse(c.longitude.trim());
    if (lat == null || lng == null) return;
    out['geo'] = <String, dynamic>{
      '@type': 'GeoCoordinates',
      'latitude': lat,
      'longitude': lng,
    };
  }

  static String? validate(JsonLdConfig c) {
    try {
      if (c.type == SchemaType.faqPage) {
        if (c.faqItems.isEmpty) return 'FAQ items are empty';
      }
      if (c.type == SchemaType.breadcrumbList) {
        if (c.breadcrumbs.isEmpty) return 'Breadcrumbs are empty';
      }
      buildMap(c);
      return null;
    } on JsonLdException catch (e) {
      return e.detail ?? e.errorKey;
    } catch (e) {
      return e.toString();
    }
  }
}