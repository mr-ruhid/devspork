import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../core/localization/app_localization.dart';

import '../tools/apibuilder/main.dart';
import '../tools/asciiart.dart';
import '../tools/b64img.dart';
import '../tools/b64urlend.dart';
import '../tools/baseconv.dart';
import '../tools/bcryptgen.dart';
import '../tools/binview.dart';
import '../tools/caseconv.dart';
import '../tools/codefilecon.dart';
import '../tools/codefmt/main.dart';
import '../tools/colorconv.dart';
import '../tools/colorpalette.dart';
import '../tools/cronbuilder/main.dart';
import '../tools/cronparse.dart';
import '../tools/csstools.dart';
import '../tools/devcalc.dart';
import '../tools/devopsgen/main.dart';
import '../tools/diffcheck.dart';
import '../tools/envmanager/main.dart';
import '../tools/excel2table.dart';
import '../tools/gitgen/main.dart';
import '../tools/hashgen.dart';
import '../tools/htmlent.dart';
import '../tools/jsoncodegen/main.dart';
import '../tools/jsonfmt.dart';
import '../tools/jsonschemagen/main.dart';
import '../tools/jsonschemavalidator/main.dart';
import '../tools/jsonsuite.dart';
import '../tools/jwtdec.dart';
import '../tools/jwtgen/main.dart';
import '../tools/listconv.dart';
import '../tools/loccompare.dart';
import '../tools/loremgen.dart';
import '../tools/mdhtml.dart';
import '../tools/mdpreview.dart';
import '../tools/mimelist.dart';
import '../tools/mockgen.dart';
import '../tools/passgen.dart';
import '../tools/qrgen.dart';
import '../tools/regexbuilder/main.dart';
import '../tools/regextest.dart';
import '../tools/rsagen.dart';
import '../tools/seotools.dart';
import '../tools/sluggen.dart';
import '../tools/sociallinks.dart';
import '../tools/sqlbuilder/main.dart';
import '../tools/sqlfmt.dart';
import '../tools/tableviewer/main.dart';
import '../tools/textmasker.dart';
import '../tools/textools.dart';
import '../tools/textstats.dart';
import '../tools/timezoneplanner/main.dart';
import '../tools/totpgen/main.dart';
import '../tools/tsconv.dart';
import '../tools/uaparse.dart';
import '../tools/urlparse.dart';
import '../tools/uuidgen.dart';
import '../tools/yamljson.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _category = 'all';

  static const List<String> _categories = <String>[
    'all',
    'text',
    'data',
    'security',
    'web',
    'convert',
    'media',
    'dev',
    'other',
  ];

  late final List<_ToolItem> _tools = <_ToolItem>[
    // ===================== TEXT =====================
    _ToolItem(
      id: 'caseconv',
      category: 'text',
      icon: Icons.text_fields,
      gradient: <Color>[Color(0xFF7C4DFF), Color(0xFF00E5FF)],
      builder: () => const CaseConv(),
    ),
    _ToolItem(
      id: 'textstats',
      category: 'text',
      icon: Icons.analytics_outlined,
      gradient: <Color>[Color(0xFF00B8D4), Color(0xFF64FFDA)],
      builder: () => const TextStats(),
    ),
    _ToolItem(
      id: 'textools',
      category: 'text',
      icon: Icons.tune,
      gradient: <Color>[Color(0xFFF857A6), Color(0xFFFF5858)],
      builder: () => const TexTools(),
    ),
    _ToolItem(
      id: 'textmasker',
      category: 'text',
      icon: Icons.visibility_off,
      gradient: <Color>[Color(0xFF6A11CB), Color(0xFF2575FC)],
      builder: () => const TextMasker(),
    ),
    _ToolItem(
      id: 'loremgen',
      category: 'text',
      icon: Icons.article_outlined,
      gradient: <Color>[Color(0xFFFF9966), Color(0xFFFF5E62)],
      builder: () => const LoremGen(),
    ),
    _ToolItem(
      id: 'sluggen',
      category: 'text',
      icon: Icons.link,
      gradient: <Color>[Color(0xFF11998E), Color(0xFF38EF7D)],
      builder: () => const SlugGen(),
    ),
    _ToolItem(
      id: 'diffcheck',
      category: 'text',
      icon: Icons.compare_arrows,
      gradient: <Color>[Color(0xFFFF512F), Color(0xFFDD2476)],
      builder: () => const DiffCheck(),
    ),
    _ToolItem(
      id: 'mdpreview',
      category: 'text',
      icon: Icons.preview,
      gradient: <Color>[Color(0xFF4776E6), Color(0xFF8E54E9)],
      builder: () => const MdPreview(),
    ),
    _ToolItem(
      id: 'mdhtml',
      category: 'text',
      icon: Icons.swap_horiz,
      gradient: <Color>[Color(0xFF1FA2FF), Color(0xFF12D8FA)],
      builder: () => const MdHtml(),
    ),
    _ToolItem(
      id: 'excel2table',
      category: 'text',
      icon: Icons.table_chart_outlined,
      gradient: <Color>[Color(0xFF0F9B0F), Color(0xFF8FD800)],
      builder: () => const Excel2Table(),
    ),
    _ToolItem(
      id: 'codefmt',
      category: 'text',
      icon: Icons.auto_fix_high_rounded,
      gradient: <Color>[Color(0xFF1FA2FF), Color(0xFF12D8FA)],
      builder: () => const CodeFmt(),
    ),

    // ===================== DATA =====================
    _ToolItem(
      id: 'jsonfmt',
      category: 'data',
      icon: Icons.data_object,
      gradient: <Color>[Color(0xFF2196F3), Color(0xFF00BCD4)],
      builder: () => const JsonFmt(),
    ),
    _ToolItem(
      id: 'jsonsuite',
      category: 'data',
      icon: Icons.schema,
      gradient: <Color>[Color(0xFF3F51B5), Color(0xFF9C27B0)],
      builder: () => const JsonSuite(),
    ),
    _ToolItem(
      id: 'jsonschemagen',
      category: 'data',
      icon: Icons.rule_folder_outlined,
      gradient: <Color>[Color(0xFF11998E), Color(0xFF00E5FF)],
      builder: () => const JsonSchemaGen(),
    ),
    _ToolItem(
      id: 'jsonschemavalidator',
      category: 'data',
      icon: Icons.verified_rounded,
      gradient: <Color>[Color(0xFF11998E), Color(0xFF00E5FF)],
      builder: () => const JsonSchemaValidatorPage(),
    ),
    _ToolItem(
      id: 'jsoncodegen',
      category: 'data',
      icon: Icons.code_rounded,
      gradient: <Color>[Color(0xFF4A00E0), Color(0xFF8E2DE2)],
      builder: () => const JsonCodeGen(),
    ),
    _ToolItem(
      id: 'sqlfmt',
      category: 'data',
      icon: Icons.storage,
      gradient: <Color>[Color(0xFF8E2DE2), Color(0xFF4A00E0)],
      builder: () => const SqlFmt(),
    ),
    _ToolItem(
      id: 'sqlbuilder',
      category: 'data',
      icon: Icons.storage_rounded,
      gradient: <Color>[Color(0xFF396AFC), Color(0xFF00C9FF)],
      builder: () => const SqlBuilder(),
    ),
    _ToolItem(
      id: 'mockgen',
      category: 'data',
      icon: Icons.dataset,
      gradient: <Color>[Color(0xFFFF6A00), Color(0xFFFFD200)],
      builder: () => const MockGen(),
    ),
    _ToolItem(
      id: 'loccompare',
      category: 'data',
      icon: Icons.translate,
      gradient: <Color>[Color(0xFF00C9FF), Color(0xFF92FE9D)],
      builder: () => const LocCompare(),
    ),
    _ToolItem(
      id: 'binview',
      category: 'data',
      icon: Icons.memory,
      gradient: <Color>[Color(0xFF141E30), Color(0xFF243B55)],
      builder: () => const BinView(),
    ),
    _ToolItem(
      id: 'cronparse',
      category: 'data',
      icon: Icons.schedule_send,
      gradient: <Color>[Color(0xFF5F2C82), Color(0xFF49A09D)],
      builder: () => const CronParse(),
    ),
    _ToolItem(
      id: 'cronbuilder',
      category: 'data',
      icon: Icons.schedule_rounded,
      gradient: <Color>[Color(0xFF5F2C82), Color(0xFF49A09D)],
      builder: () => const CronBuilder(),
    ),
    _ToolItem(
      id: 'regextest',
      category: 'data',
      icon: Icons.search,
      gradient: <Color>[Color(0xFFFF8008), Color(0xFFFFC837)],
      builder: () => const RegexTest(),
    ),
    _ToolItem(
      id: 'regexbuilder',
      category: 'data',
      icon: Icons.rule_rounded,
      gradient: <Color>[Color(0xFFFF8008), Color(0xFFFFC837)],
      builder: () => const RegexBuilder(),
    ),
    _ToolItem(
      id: 'tableviewer',
      category: 'data',
      icon: Icons.table_view_rounded,
      gradient: <Color>[Color(0xFF2193B0), Color(0xFF6DD5ED)],
      builder: () => const TableViewer(),
    ),

    // ===================== SECURITY =====================
    _ToolItem(
      id: 'hashgen',
      category: 'security',
      icon: Icons.fingerprint,
      gradient: <Color>[Color(0xFF654EA3), Color(0xFFEAAFC8)],
      builder: () => const HashGen(),
    ),
    _ToolItem(
      id: 'bcryptgen',
      category: 'security',
      icon: Icons.security,
      gradient: <Color>[Color(0xFFB92B27), Color(0xFF1565C0)],
      builder: () => const BcryptGen(),
    ),
    _ToolItem(
      id: 'jwtdec',
      category: 'security',
      icon: Icons.vpn_key,
      gradient: <Color>[Color(0xFF232526), Color(0xFF414345)],
      builder: () => const JwtDec(),
    ),
    _ToolItem(
      id: 'jwtgen',
      category: 'security',
      icon: Icons.key_rounded,
      gradient: <Color>[Color(0xFF11998E), Color(0xFF00E5FF)],
      builder: () => const JwtGen(),
    ),
    _ToolItem(
      id: 'rsagen',
      category: 'security',
      icon: Icons.enhanced_encryption,
      gradient: <Color>[Color(0xFF11998E), Color(0xFF38EF7D)],
      builder: () => const RsaGen(),
    ),
    _ToolItem(
      id: 'uuidgen',
      category: 'security',
      icon: Icons.tag,
      gradient: <Color>[Color(0xFF7F00FF), Color(0xFFE100FF)],
      builder: () => const UuidGen(),
    ),
    _ToolItem(
      id: 'passgen',
      category: 'security',
      icon: Icons.password,
      gradient: <Color>[Color(0xFF134E5E), Color(0xFF71B280)],
      builder: () => const PassGen(),
    ),
    _ToolItem(
      id: 'totpgen',
      category: 'security',
      icon: Icons.timer_rounded,
      gradient: <Color>[Color(0xFFB92B27), Color(0xFF1565C0)],
      builder: () => const TotpGen(),
    ),
    _ToolItem(
      id: 'b64urlend',
      category: 'security',
      icon: Icons.code,
      gradient: <Color>[Color(0xFFFDC830), Color(0xFFF37335)],
      builder: () => const B64UrlEnd(),
    ),
    _ToolItem(
      id: 'htmlent',
      category: 'security',
      icon: Icons.html,
      gradient: <Color>[Color(0xFFee0979), Color(0xFFff6a00)],
      builder: () => const HtmlEnt(),
    ),

    // ===================== WEB =====================
    _ToolItem(
      id: 'urlparse',
      category: 'web',
      icon: Icons.link_outlined,
      gradient: <Color>[Color(0xFF396AFC), Color(0xFF2948FF)],
      builder: () => const UrlParse(),
    ),
    _ToolItem(
      id: 'apibuilder',
      category: 'web',
      icon: Icons.api_rounded,
      gradient: <Color>[Color(0xFF7C4DFF), Color(0xFF00E5FF)],
      builder: () => const ApiBuilder(),
    ),
    _ToolItem(
      id: 'sociallinks',
      category: 'web',
      icon: Icons.share,
      gradient: <Color>[Color(0xFFFF512F), Color(0xFFF09819)],
      builder: () => const SocialLinks(),
    ),
    _ToolItem(
      id: 'seotools',
      category: 'web',
      icon: Icons.travel_explore,
      gradient: <Color>[Color(0xFF43CEA2), Color(0xFF185A9D)],
      builder: () => const SeoTools(),
    ),
    _ToolItem(
      id: 'uaparse',
      category: 'web',
      icon: Icons.devices,
      gradient: <Color>[Color(0xFF6A3093), Color(0xFFA044FF)],
      builder: () => const UaParse(),
    ),
    _ToolItem(
      id: 'mimelist',
      category: 'web',
      icon: Icons.list_alt,
      gradient: <Color>[Color(0xFF1D976C), Color(0xFF93F9B9)],
      builder: () => const MimeList(),
    ),
    _ToolItem(
      id: 'csstools',
      category: 'web',
      icon: Icons.brush,
      gradient: <Color>[Color(0xFF396AFC), Color(0xFF00C9FF)],
      builder: () => const CssTools(),
    ),

    // ===================== CONVERT =====================
    _ToolItem(
      id: 'codefilecon',
      category: 'convert',
      icon: Icons.transform,
      gradient: <Color>[Color(0xFF00C6FF), Color(0xFF0072FF)],
      builder: () => const CodeFileCon(),
    ),
    _ToolItem(
      id: 'yamljson',
      category: 'convert',
      icon: Icons.sync_alt,
      gradient: <Color>[Color(0xFFB621FE), Color(0xFF1FD1F9)],
      builder: () => const YamlJson(),
    ),
    _ToolItem(
      id: 'listconv',
      category: 'convert',
      icon: Icons.format_list_bulleted,
      gradient: <Color>[Color(0xFFFC5C7D), Color(0xFF6A82FB)],
      builder: () => const ListConv(),
    ),
    _ToolItem(
      id: 'baseconv',
      category: 'convert',
      icon: Icons.numbers,
      gradient: <Color>[Color(0xFF00B09B), Color(0xFF96C93D)],
      builder: () => const BaseConv(),
    ),
    _ToolItem(
      id: 'colorconv',
      category: 'convert',
      icon: Icons.color_lens_outlined,
      gradient: <Color>[Color(0xFFEC008C), Color(0xFFFC6767)],
      builder: () => const ColorConv(),
    ),
    _ToolItem(
      id: 'tsconv',
      category: 'convert',
      icon: Icons.schedule,
      gradient: <Color>[Color(0xFF2193B0), Color(0xFF6DD5ED)],
      builder: () => const TsConv(),
    ),
    _ToolItem(
      id: 'devcalc',
      category: 'convert',
      icon: Icons.calculate_outlined,
      gradient: <Color>[Color(0xFF56AB2F), Color(0xFFA8E063)],
      builder: () => const DevCalc(),
    ),
    _ToolItem(
      id: 'envmanager',
      category: 'convert',
      icon: Icons.settings_suggest_rounded,
      gradient: <Color>[Color(0xFF134E5E), Color(0xFF71B280)],
      builder: () => const EnvManager(),
    ),

    // ===================== MEDIA =====================
    _ToolItem(
      id: 'b64img',
      category: 'media',
      icon: Icons.image_outlined,
      gradient: <Color>[Color(0xFFDA22FF), Color(0xFF9733EE)],
      builder: () => const B64Img(),
    ),
    _ToolItem(
      id: 'qrgen',
      category: 'media',
      icon: Icons.qr_code_2,
      gradient: <Color>[Color(0xFF0F2027), Color(0xFF2C5364)],
      builder: () => const QrGen(),
    ),
    _ToolItem(
      id: 'asciiart',
      category: 'media',
      icon: Icons.text_format,
      gradient: <Color>[Color(0xFFff00cc), Color(0xFF333399)],
      builder: () => const AsciiArt(),
    ),
    _ToolItem(
      id: 'colorpalette',
      category: 'media',
      icon: Icons.palette_rounded,
      gradient: <Color>[Color(0xFFEC008C), Color(0xFFFC6767)],
      builder: () => const ColorPalette(),
    ),

    // ===================== DEV =====================
    _ToolItem(
      id: 'gitgen',
      category: 'dev',
      icon: Icons.account_tree_rounded,
      gradient: <Color>[Color(0xFFFF512F), Color(0xFFDD2476)],
      builder: () => const GitGen(),
    ),
    _ToolItem(
      id: 'devopsgen',
      category: 'dev',
      icon: Icons.terminal_rounded,
      gradient: <Color>[Color(0xFF8E2DE2), Color(0xFF4A00E0)],
      builder: () => const DevOpsGen(),
    ),

    // ===================== OTHER =====================
    _ToolItem(
      id: 'timezoneplanner',
      category: 'other',
      icon: Icons.public_rounded,
      gradient: <Color>[Color(0xFF43CEA2), Color(0xFF185A9D)],
      builder: () => const TimezonePlanner(),
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_ToolItem> get _filtered {
    return _tools.where((_ToolItem t) {
      if (_category != 'all' && t.category != _category) return false;
      if (_query.isEmpty) return true;
      final String q = _query.toLowerCase();
      final String title =
      context.t('home_tool_${t.id}_title').toLowerCase();
      final String desc =
      context.t('home_tool_${t.id}_desc').toLowerCase();
      return title.contains(q) || desc.contains(q) || t.id.contains(q);
    }).toList();
  }

  void _openTool(_ToolItem tool) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => tool.builder()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final List<_ToolItem> visible = _filtered;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.t('home_title'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined),
            tooltip: context.t('home_settings'),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? <Color>[
              const Color(0xFF0F0B24),
              const Color(0xFF1A0F3C),
              const Color(0xFF071B33),
            ]
                : <Color>[
              const Color(0xFFF5F3FF),
              const Color(0xFFEEF2FF),
              const Color(0xFFE0F2FE),
            ],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: -100,
              left: -80,
              child: _blob(240, const Color(0xFF7C4DFF)),
            ),
            Positioned(
              bottom: -120,
              right: -80,
              child: _blob(280, const Color(0xFF00E5FF)),
            ),
            SafeArea(
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: _searchBar(colors, dark),
                  ),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (BuildContext context, int index) {
                        final String c = _categories[index];
                        final bool selected = _category == c;
                        return _categoryChip(c, selected, dark);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: visible.isEmpty
                        ? _emptyState(colors)
                        : LayoutBuilder(
                      builder: (
                          BuildContext context,
                          BoxConstraints constraints,
                          ) {
                        final double w = constraints.maxWidth;
                        final int cols = w > 1100
                            ? 5
                            : w > 850
                            ? 4
                            : w > 600
                            ? 3
                            : 2;
                        return GridView.builder(
                          padding:
                          const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.95,
                          ),
                          itemCount: visible.length,
                          itemBuilder: (BuildContext context, int i) {
                            return _toolCard(visible[i], dark);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return IgnorePointer(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.25),
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchBar(ColorScheme colors, bool dark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: TextField(
          controller: _searchController,
          onChanged: (String v) {
            setState(() {
              _query = v;
            });
          },
          style: TextStyle(
            color: dark ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: context.t('home_search_hint'),
            hintStyle: TextStyle(
              color: dark ? Colors.white54 : Colors.black45,
              fontSize: 13,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: dark ? Colors.white70 : Colors.black54,
            ),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _query = '';
                });
              },
              icon: Icon(
                Icons.close,
                color: dark ? Colors.white70 : Colors.black54,
              ),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            filled: true,
            fillColor:
            dark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(String c, bool selected, bool dark) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _category = c;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
            colors: <Color>[Color(0xFF7C4DFF), Color(0xFF00E5FF)],
          )
              : null,
          color: selected
              ? null
              : dark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : (dark
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.08)),
          ),
        ),
        child: Text(
          context.t('home_cat_$c'),
          style: TextStyle(
            color: selected
                ? Colors.white
                : (dark ? Colors.white70 : Colors.black87),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
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

  Widget _toolCard(_ToolItem tool, bool dark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: dark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.85),
          child: InkWell(
            onTap: () => _openTool(tool),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: dark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: tool.gradient,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: tool.gradient.first
                              .withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      tool.icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Text(
                      context.t('home_tool_${tool.id}_title'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        height: 1.2,
                        color: dark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.t('home_tool_${tool.id}_desc'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.3,
                      color: dark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolItem {
  final String id;
  final String category;
  final IconData icon;
  final List<Color> gradient;
  final Widget Function() builder;

  const _ToolItem({
    required this.id,
    required this.category,
    required this.icon,
    required this.gradient,
    required this.builder,
  });
}