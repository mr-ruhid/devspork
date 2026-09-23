import 'package:flutter/material.dart';

import '../tools/apibuilder/main.dart';
import '../tools/asciiart.dart';
import '../tools/audioconvert/main.dart';
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
import '../tools/cryptotoolkit/main.dart';
import '../tools/csslayout/main.dart';
import '../tools/csstools.dart';
import '../tools/devcalc.dart';
import '../tools/devopsgen/main.dart';
import '../tools/diffcheck.dart';
import '../tools/envmanager/main.dart';
import '../tools/excel2table.dart';
import '../tools/gitgen/main.dart';
import '../tools/hashgen.dart';
import '../tools/htmlent.dart';
import '../tools/imagecompress/main.dart';
import '../tools/imageconvert/main.dart';
import '../tools/imagecrop.dart';
import '../tools/imagetopdf/main.dart';
import '../tools/jsoncodegen/main.dart';
import '../tools/jsonfmt.dart';
import '../tools/jsonschemagen/main.dart';
import '../tools/jsonschemavalidator/main.dart';
import '../tools/jsonsuite.dart';
import '../tools/jwtdec.dart';
import '../tools/jwtgen/main.dart';
import '../tools/k8sgen/main.dart';
import '../tools/listconv.dart';
import '../tools/loccompare.dart';
import '../tools/loremgen.dart';
import '../tools/mdhtml.dart';
import '../tools/mdpreview.dart';
import '../tools/mdtable/main.dart';
import '../tools/mimelist.dart';
import '../tools/mockgen.dart';
import '../tools/mockserver/main.dart';
import '../tools/netpack/main.dart';
import '../tools/passgen.dart';
import '../tools/passstrength/main.dart';
import '../tools/pdfcompress.dart';
import '../tools/pdfmerge/main.dart';
import '../tools/pdfsplit/main.dart';
import '../tools/qrgen.dart';
import '../tools/regexbuilder/main.dart';
import '../tools/regextest.dart';
import '../tools/rsagen.dart';
import '../tools/seopack/main.dart';
import '../tools/seotools.dart';
import '../tools/sluggen.dart';
import '../tools/sociallinks.dart';
import '../tools/sqlbuilder/main.dart';
import '../tools/sqlfmt.dart';
import '../tools/svgpath/main.dart';
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
import '../tools/wordlistgen/main.dart';
import '../tools/yamljson.dart';

class ToolItem {
  final String id;
  final String category;
  final IconData icon;
  final List<Color> gradient;
  final Widget Function() builder;

  const ToolItem({
    required this.id,
    required this.category,
    required this.icon,
    required this.gradient,
    required this.builder,
  });
}

const List<String> toolCategories = <String>[
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

final List<ToolItem> toolsRegistry = <ToolItem>[
  ToolItem(
    id: 'caseconv',
    category: 'text',
    icon: Icons.text_fields,
    gradient: <Color>[Color(0xFF7C4DFF), Color(0xFF00E5FF)],
    builder: () => const CaseConv(),
  ),
  ToolItem(
    id: 'textstats',
    category: 'text',
    icon: Icons.analytics_outlined,
    gradient: <Color>[Color(0xFF00B8D4), Color(0xFF64FFDA)],
    builder: () => const TextStats(),
  ),
  ToolItem(
    id: 'textools',
    category: 'text',
    icon: Icons.tune,
    gradient: <Color>[Color(0xFFF857A6), Color(0xFFFF5858)],
    builder: () => const TexTools(),
  ),
  ToolItem(
    id: 'textmasker',
    category: 'text',
    icon: Icons.visibility_off,
    gradient: <Color>[Color(0xFF6A11CB), Color(0xFF2575FC)],
    builder: () => const TextMasker(),
  ),
  ToolItem(
    id: 'loremgen',
    category: 'text',
    icon: Icons.article_outlined,
    gradient: <Color>[Color(0xFFFF9966), Color(0xFFFF5E62)],
    builder: () => const LoremGen(),
  ),
  ToolItem(
    id: 'sluggen',
    category: 'text',
    icon: Icons.link,
    gradient: <Color>[Color(0xFF11998E), Color(0xFF38EF7D)],
    builder: () => const SlugGen(),
  ),
  ToolItem(
    id: 'diffcheck',
    category: 'text',
    icon: Icons.compare_arrows,
    gradient: <Color>[Color(0xFFFF512F), Color(0xFFDD2476)],
    builder: () => const DiffCheck(),
  ),
  ToolItem(
    id: 'mdpreview',
    category: 'text',
    icon: Icons.preview,
    gradient: <Color>[Color(0xFF4776E6), Color(0xFF8E54E9)],
    builder: () => const MdPreview(),
  ),
  ToolItem(
    id: 'mdhtml',
    category: 'text',
    icon: Icons.swap_horiz,
    gradient: <Color>[Color(0xFF1FA2FF), Color(0xFF12D8FA)],
    builder: () => const MdHtml(),
  ),
  ToolItem(
    id: 'mdtable',
    category: 'text',
    icon: Icons.table_rows_rounded,
    gradient: <Color>[Color(0xFF1FA2FF), Color(0xFF12D8FA)],
    builder: () => const MdTableBuilder(),
  ),
  ToolItem(
    id: 'excel2table',
    category: 'text',
    icon: Icons.table_chart_outlined,
    gradient: <Color>[Color(0xFF0F9B0F), Color(0xFF8FD800)],
    builder: () => const Excel2Table(),
  ),
  ToolItem(
    id: 'codefmt',
    category: 'text',
    icon: Icons.auto_fix_high_rounded,
    gradient: <Color>[Color(0xFF1FA2FF), Color(0xFF12D8FA)],
    builder: () => const CodeFmt(),
  ),
  ToolItem(
    id: 'jsonfmt',
    category: 'data',
    icon: Icons.data_object,
    gradient: <Color>[Color(0xFF2196F3), Color(0xFF00BCD4)],
    builder: () => const JsonFmt(),
  ),
  ToolItem(
    id: 'jsonsuite',
    category: 'data',
    icon: Icons.schema,
    gradient: <Color>[Color(0xFF3F51B5), Color(0xFF9C27B0)],
    builder: () => const JsonSuite(),
  ),
  ToolItem(
    id: 'jsonschemagen',
    category: 'data',
    icon: Icons.rule_folder_outlined,
    gradient: <Color>[Color(0xFF11998E), Color(0xFF00E5FF)],
    builder: () => const JsonSchemaGen(),
  ),
  ToolItem(
    id: 'jsonschemavalidator',
    category: 'data',
    icon: Icons.verified_rounded,
    gradient: <Color>[Color(0xFF11998E), Color(0xFF00E5FF)],
    builder: () => const JsonSchemaValidatorPage(),
  ),
  ToolItem(
    id: 'jsoncodegen',
    category: 'data',
    icon: Icons.code_rounded,
    gradient: <Color>[Color(0xFF4A00E0), Color(0xFF8E2DE2)],
    builder: () => const JsonCodeGen(),
  ),
  ToolItem(
    id: 'sqlfmt',
    category: 'data',
    icon: Icons.storage,
    gradient: <Color>[Color(0xFF8E2DE2), Color(0xFF4A00E0)],
    builder: () => const SqlFmt(),
  ),
  ToolItem(
    id: 'sqlbuilder',
    category: 'data',
    icon: Icons.storage_rounded,
    gradient: <Color>[Color(0xFF396AFC), Color(0xFF00C9FF)],
    builder: () => const SqlBuilder(),
  ),
  ToolItem(
    id: 'mockgen',
    category: 'data',
    icon: Icons.dataset,
    gradient: <Color>[Color(0xFFFF6A00), Color(0xFFFFD200)],
    builder: () => const MockGen(),
  ),
  ToolItem(
    id: 'loccompare',
    category: 'data',
    icon: Icons.translate,
    gradient: <Color>[Color(0xFF00C9FF), Color(0xFF92FE9D)],
    builder: () => const LocCompare(),
  ),
  ToolItem(
    id: 'binview',
    category: 'data',
    icon: Icons.memory,
    gradient: <Color>[Color(0xFF141E30), Color(0xFF243B55)],
    builder: () => const BinView(),
  ),
  ToolItem(
    id: 'cronparse',
    category: 'data',
    icon: Icons.schedule_send,
    gradient: <Color>[Color(0xFF5F2C82), Color(0xFF49A09D)],
    builder: () => const CronParse(),
  ),
  ToolItem(
    id: 'cronbuilder',
    category: 'data',
    icon: Icons.schedule_rounded,
    gradient: <Color>[Color(0xFF5F2C82), Color(0xFF49A09D)],
    builder: () => const CronBuilder(),
  ),
  ToolItem(
    id: 'regextest',
    category: 'data',
    icon: Icons.search,
    gradient: <Color>[Color(0xFFFF8008), Color(0xFFFFC837)],
    builder: () => const RegexTest(),
  ),
  ToolItem(
    id: 'regexbuilder',
    category: 'data',
    icon: Icons.rule_rounded,
    gradient: <Color>[Color(0xFFFF8008), Color(0xFFFFC837)],
    builder: () => const RegexBuilder(),
  ),
  ToolItem(
    id: 'tableviewer',
    category: 'data',
    icon: Icons.table_view_rounded,
    gradient: <Color>[Color(0xFF2193B0), Color(0xFF6DD5ED)],
    builder: () => const TableViewer(),
  ),
  ToolItem(
    id: 'hashgen',
    category: 'security',
    icon: Icons.fingerprint,
    gradient: <Color>[Color(0xFF654EA3), Color(0xFFEAAFC8)],
    builder: () => const HashGen(),
  ),
  ToolItem(
    id: 'bcryptgen',
    category: 'security',
    icon: Icons.security,
    gradient: <Color>[Color(0xFFB92B27), Color(0xFF1565C0)],
    builder: () => const BcryptGen(),
  ),
  ToolItem(
    id: 'cryptotoolkit',
    category: 'security',
    icon: Icons.enhanced_encryption_rounded,
    gradient: <Color>[Color(0xFF232526), Color(0xFF414345)],
    builder: () => const CryptoToolkit(),
  ),
  ToolItem(
    id: 'jwtdec',
    category: 'security',
    icon: Icons.vpn_key,
    gradient: <Color>[Color(0xFF232526), Color(0xFF414345)],
    builder: () => const JwtDec(),
  ),
  ToolItem(
    id: 'jwtgen',
    category: 'security',
    icon: Icons.key_rounded,
    gradient: <Color>[Color(0xFF11998E), Color(0xFF00E5FF)],
    builder: () => const JwtGen(),
  ),
  ToolItem(
    id: 'rsagen',
    category: 'security',
    icon: Icons.enhanced_encryption,
    gradient: <Color>[Color(0xFF11998E), Color(0xFF38EF7D)],
    builder: () => const RsaGen(),
  ),
  ToolItem(
    id: 'uuidgen',
    category: 'security',
    icon: Icons.tag,
    gradient: <Color>[Color(0xFF7F00FF), Color(0xFFE100FF)],
    builder: () => const UuidGen(),
  ),
  ToolItem(
    id: 'passgen',
    category: 'security',
    icon: Icons.password,
    gradient: <Color>[Color(0xFF134E5E), Color(0xFF71B280)],
    builder: () => const PassGen(),
  ),
  ToolItem(
    id: 'passstrength',
    category: 'security',
    icon: Icons.shield_moon_rounded,
    gradient: <Color>[Color(0xFFB92B27), Color(0xFF1565C0)],
    builder: () => const PassStrength(),
  ),
  ToolItem(
    id: 'wordlistgen',
    category: 'security',
    icon: Icons.list_alt_rounded,
    gradient: <Color>[Color(0xFF0F2027), Color(0xFF2C5364)],
    builder: () => const WordlistGeneratorPage(),
  ),
  ToolItem(
    id: 'totpgen',
    category: 'security',
    icon: Icons.timer_rounded,
    gradient: <Color>[Color(0xFFB92B27), Color(0xFF1565C0)],
    builder: () => const TotpGen(),
  ),
  ToolItem(
    id: 'b64urlend',
    category: 'security',
    icon: Icons.code,
    gradient: <Color>[Color(0xFFFDC830), Color(0xFFF37335)],
    builder: () => const B64UrlEnd(),
  ),
  ToolItem(
    id: 'htmlent',
    category: 'security',
    icon: Icons.html,
    gradient: <Color>[Color(0xFFee0979), Color(0xFFff6a00)],
    builder: () => const HtmlEnt(),
  ),
  ToolItem(
    id: 'urlparse',
    category: 'web',
    icon: Icons.link_outlined,
    gradient: <Color>[Color(0xFF396AFC), Color(0xFF2948FF)],
    builder: () => const UrlParse(),
  ),
  ToolItem(
    id: 'apibuilder',
    category: 'web',
    icon: Icons.api_rounded,
    gradient: <Color>[Color(0xFF7C4DFF), Color(0xFF00E5FF)],
    builder: () => const ApiBuilder(),
  ),
  ToolItem(
    id: 'sociallinks',
    category: 'web',
    icon: Icons.share,
    gradient: <Color>[Color(0xFFFF512F), Color(0xFFF09819)],
    builder: () => const SocialLinks(),
  ),
  ToolItem(
    id: 'seotools',
    category: 'web',
    icon: Icons.travel_explore,
    gradient: <Color>[Color(0xFF43CEA2), Color(0xFF185A9D)],
    builder: () => const SeoTools(),
  ),
  ToolItem(
    id: 'seopack',
    category: 'web',
    icon: Icons.travel_explore_rounded,
    gradient: <Color>[Color(0xFF43CEA2), Color(0xFF185A9D)],
    builder: () => const SeoPack(),
  ),
  ToolItem(
    id: 'uaparse',
    category: 'web',
    icon: Icons.devices,
    gradient: <Color>[Color(0xFF6A3093), Color(0xFFA044FF)],
    builder: () => const UaParse(),
  ),
  ToolItem(
    id: 'mimelist',
    category: 'web',
    icon: Icons.list_alt,
    gradient: <Color>[Color(0xFF1D976C), Color(0xFF93F9B9)],
    builder: () => const MimeList(),
  ),
  ToolItem(
    id: 'csstools',
    category: 'web',
    icon: Icons.brush,
    gradient: <Color>[Color(0xFF396AFC), Color(0xFF00C9FF)],
    builder: () => const CssTools(),
  ),
  ToolItem(
    id: 'csslayout',
    category: 'web',
    icon: Icons.dashboard_customize_rounded,
    gradient: <Color>[Color(0xFF7C4DFF), Color(0xFF00E5FF)],
    builder: () => const CssLayoutGen(),
  ),
  ToolItem(
    id: 'netpack',
    category: 'web',
    icon: Icons.lan_rounded,
    gradient: <Color>[Color(0xFF11998E), Color(0xFF38EF7D)],
    builder: () => const NetPack(),
  ),
  ToolItem(
    id: 'codefilecon',
    category: 'convert',
    icon: Icons.transform,
    gradient: <Color>[Color(0xFF00C6FF), Color(0xFF0072FF)],
    builder: () => const CodeFileCon(),
  ),
  ToolItem(
    id: 'yamljson',
    category: 'convert',
    icon: Icons.sync_alt,
    gradient: <Color>[Color(0xFFB621FE), Color(0xFF1FD1F9)],
    builder: () => const YamlJson(),
  ),
  ToolItem(
    id: 'listconv',
    category: 'convert',
    icon: Icons.format_list_bulleted,
    gradient: <Color>[Color(0xFFFC5C7D), Color(0xFF6A82FB)],
    builder: () => const ListConv(),
  ),
  ToolItem(
    id: 'baseconv',
    category: 'convert',
    icon: Icons.numbers,
    gradient: <Color>[Color(0xFF00B09B), Color(0xFF96C93D)],
    builder: () => const BaseConv(),
  ),
  ToolItem(
    id: 'colorconv',
    category: 'convert',
    icon: Icons.color_lens_outlined,
    gradient: <Color>[Color(0xFFEC008C), Color(0xFFFC6767)],
    builder: () => const ColorConv(),
  ),
  ToolItem(
    id: 'tsconv',
    category: 'convert',
    icon: Icons.schedule,
    gradient: <Color>[Color(0xFF2193B0), Color(0xFF6DD5ED)],
    builder: () => const TsConv(),
  ),
  ToolItem(
    id: 'devcalc',
    category: 'convert',
    icon: Icons.calculate_outlined,
    gradient: <Color>[Color(0xFF56AB2F), Color(0xFFA8E063)],
    builder: () => const DevCalc(),
  ),
  ToolItem(
    id: 'envmanager',
    category: 'convert',
    icon: Icons.settings_suggest_rounded,
    gradient: <Color>[Color(0xFF134E5E), Color(0xFF71B280)],
    builder: () => const EnvManager(),
  ),
  ToolItem(
    id: 'b64img',
    category: 'media',
    icon: Icons.image_outlined,
    gradient: <Color>[Color(0xFFDA22FF), Color(0xFF9733EE)],
    builder: () => const B64Img(),
  ),
  ToolItem(
    id: 'qrgen',
    category: 'media',
    icon: Icons.qr_code_2,
    gradient: <Color>[Color(0xFF0F2027), Color(0xFF2C5364)],
    builder: () => const QrGen(),
  ),
  ToolItem(
    id: 'asciiart',
    category: 'media',
    icon: Icons.text_format,
    gradient: <Color>[Color(0xFFff00cc), Color(0xFF333399)],
    builder: () => const AsciiArt(),
  ),
  ToolItem(
    id: 'colorpalette',
    category: 'media',
    icon: Icons.palette_rounded,
    gradient: <Color>[Color(0xFFEC008C), Color(0xFFFC6767)],
    builder: () => const ColorPalette(),
  ),
  ToolItem(
    id: 'svgpath',
    category: 'media',
    icon: Icons.polyline_rounded,
    gradient: <Color>[Color(0xFFDA22FF), Color(0xFF9733EE)],
    builder: () => const SvgPathViewer(),
  ),
  ToolItem(
    id: 'imagecompress',
    category: 'media',
    icon: Icons.compress_rounded,
    gradient: <Color>[Color(0xFF11998E), Color(0xFF38EF7D)],
    builder: () => const ImageCompressPage(),
  ),
  ToolItem(
    id: 'imageconvert',
    category: 'media',
    icon: Icons.swap_horiz_rounded,
    gradient: <Color>[Color(0xFF00C6FF), Color(0xFF0072FF)],
    builder: () => const ImageConvertPage(),
  ),
  ToolItem(
    id: 'imagecrop',
    category: 'media',
    icon: Icons.crop_rounded,
    gradient: <Color>[Color(0xFF7C4DFF), Color(0xFFFF6A00)],
    builder: () => const ImageCrop(),
  ),
  ToolItem(
    id: 'imagetopdf',
    category: 'media',
    icon: Icons.picture_as_pdf_rounded,
    gradient: <Color>[Color(0xFFDD2476), Color(0xFF2196F3)],
    builder: () => const ImageToPdfPage(),
  ),
  ToolItem(
    id: 'pdfmerge',
    category: 'media',
    icon: Icons.merge_type_rounded,
    gradient: <Color>[Color(0xFFB92B27), Color(0xFF1565C0)],
    builder: () => const PdfMerge(),
  ),
  ToolItem(
    id: 'pdfsplit',
    category: 'media',
    icon: Icons.content_cut_rounded,
    gradient: <Color>[Color(0xFF8E2DE2), Color(0xFF4A00E0)],
    builder: () => const PdfSplitPage(),
  ),
  ToolItem(
    id: 'pdfcompress',
    category: 'media',
    icon: Icons.compress,
    gradient: <Color>[Color(0xFFB92B27), Color(0xFFDD2476)],
    builder: () => const PdfCompress(),
  ),
  ToolItem(
    id: 'audioconvert',
    category: 'media',
    icon: Icons.audio_file_rounded,
    gradient: <Color>[Color(0xFF00B8D4), Color(0xFF64FFDA)],
    builder: () => const AudioConvert(),
  ),
  ToolItem(
    id: 'gitgen',
    category: 'dev',
    icon: Icons.account_tree_rounded,
    gradient: <Color>[Color(0xFFFF512F), Color(0xFFDD2476)],
    builder: () => const GitGen(),
  ),
  ToolItem(
    id: 'devopsgen',
    category: 'dev',
    icon: Icons.terminal_rounded,
    gradient: <Color>[Color(0xFF8E2DE2), Color(0xFF4A00E0)],
    builder: () => const DevOpsGen(),
  ),
  ToolItem(
    id: 'k8sgen',
    category: 'dev',
    icon: Icons.cloud_queue_rounded,
    gradient: <Color>[Color(0xFF326CE5), Color(0xFF00E5FF)],
    builder: () => const K8sGen(),
  ),
  ToolItem(
    id: 'mockserver',
    category: 'dev',
    icon: Icons.dns_rounded,
    gradient: <Color>[Color(0xFF4B9BFF), Color(0xFF00E5FF)],
    builder: () => const MockServerPage(),
  ),
  ToolItem(
    id: 'timezoneplanner',
    category: 'other',
    icon: Icons.public_rounded,
    gradient: <Color>[Color(0xFF43CEA2), Color(0xFF185A9D)],
    builder: () => const TimezonePlanner(),
  ),
];