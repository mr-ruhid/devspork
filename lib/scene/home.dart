import 'dart:async';

import 'package:flutter/material.dart';

import '../core/localization/app_localization.dart';
import '../core/theme/app_ui_kit.dart';
import '../core/widgets/app_header.dart';

import 'tools_registry.dart';

const double _kTileHeight = 168;
const double _kTileMaxWidth = 220;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _category = 'all';
  Timer? _searchDebounce;

  final Map<String, _ToolStrings> _stringsCache = <String, _ToolStrings>{};
  Locale? _cachedLocale;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() => _query = value);
    });
  }

  void _ensureStringsCache() {
    final Locale locale = Localizations.localeOf(context);
    if (_cachedLocale == locale && _stringsCache.isNotEmpty) return;
    _cachedLocale = locale;
    _stringsCache.clear();
    for (final ToolItem tool in toolsRegistry) {
      final String title = context.t('home_tool_${tool.id}_title');
      final String desc = context.t('home_tool_${tool.id}_desc');
      _stringsCache[tool.id] = _ToolStrings(
        title: title,
        description: desc,
        searchBlob: '$title $desc ${tool.id}'.toLowerCase(),
      );
    }
  }

  void _openTool(ToolItem tool) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => tool.builder()),
    );
  }

  @override
  Widget build(BuildContext context) {
    _ensureStringsCache();

    final ColorScheme colors = Theme.of(context).colorScheme;
    final String q = _query.trim().toLowerCase();

    final List<_ResolvedTool> resolved = <_ResolvedTool>[];
    for (final ToolItem tool in toolsRegistry) {
      if (_category != 'all' && tool.category != _category) continue;
      final _ToolStrings s = _stringsCache[tool.id]!;
      if (q.isNotEmpty && !s.searchBlob.contains(q)) continue;
      resolved.add(_ResolvedTool(
        item: tool,
        title: s.title,
        description: s.description,
      ));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: kScaffoldBg,
      appBar: const AppHeader(),
      body: GlassBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: kToolbarHeight),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: _searchBar(),
                ),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: toolCategories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (BuildContext context, int index) {
                      final String c = toolCategories[index];
                      return GlassChip(
                        label: context.t('home_cat_$c'),
                        selected: _category == c,
                        onTap: () {
                          setState(() {
                            _category = c;
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: resolved.isEmpty
                      ? _emptyState(colors)
                      : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: false,
                    cacheExtent: _kTileHeight * 2,
                    gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: _kTileMaxWidth,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: _kTileHeight,
                    ),
                    itemCount: resolved.length,
                    itemBuilder: (BuildContext context, int i) {
                      final _ResolvedTool r = resolved[i];
                      return _ToolCard(
                        key: ValueKey<String>(r.item.id),
                        tool: r.item,
                        title: r.title,
                        description: r.description,
                        onTap: () => _openTool(r.item),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchBar() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      radius: 16,
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: context.t('home_search_hint'),
          hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
            onPressed: () {
              _searchDebounce?.cancel();
              _searchController.clear();
              setState(() {
                _query = '';
              });
            },
            icon: const Icon(Icons.close, color: Colors.white70),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _emptyState(ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.search_off, size: 56, color: colors.outline),
          const SizedBox(height: 12),
          Text(
            context.t('home_no_results'),
            style: TextStyle(color: colors.outline),
          ),
        ],
      ),
    );
  }
}

class _ToolStrings {
  const _ToolStrings({
    required this.title,
    required this.description,
    required this.searchBlob,
  });

  final String title;
  final String description;
  final String searchBlob;
}

class _ResolvedTool {
  final ToolItem item;
  final String title;
  final String description;

  const _ResolvedTool({
    required this.item,
    required this.title,
    required this.description,
  });
}

class _ToolCard extends StatefulWidget {
  const _ToolCard({
    super.key,
    required this.tool,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final ToolItem tool;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  State<_ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<_ToolCard> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final Color glow = widget.tool.gradient.first;

    return RepaintBoundary(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _setHovered(true),
        onExit: (_) => _setHovered(false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Colors.white.withOpacity(_hovered ? 0.16 : 0.10),
                  Colors.white.withOpacity(0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _hovered
                    ? glow.withOpacity(0.55)
                    : Colors.white.withOpacity(0.18),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: _hovered
                      ? glow.withOpacity(0.25)
                      : Colors.black.withOpacity(0.22),
                  blurRadius: _hovered ? 20 : 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _ToolIcon(
                  hovered: _hovered,
                  gradient: widget.tool.gradient,
                  icon: widget.tool.icon,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      height: 1.25,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    widget.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: Colors.white60,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolIcon extends StatelessWidget {
  const _ToolIcon({
    required this.hovered,
    required this.gradient,
    required this.icon,
  });

  final bool hovered;
  final List<Color> gradient;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(13),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: gradient.first.withOpacity(hovered ? 0.55 : 0.3),
            blurRadius: hovered ? 16 : 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 22,
      ),
    );
  }
}