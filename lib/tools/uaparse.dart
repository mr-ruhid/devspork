import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class UaParse extends StatefulWidget {
  const UaParse({super.key});

  @override
  State<UaParse> createState() => _UaParseState();
}

class _UaParseState extends State<UaParse> {
  final TextEditingController _inputController = TextEditingController();

  Map<String, String> _info = <String, String>{};
  bool _parsed = false;

  static const String _sample =
      'Mozilla/5.0 (Linux; Android 13; SM-S918B) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36';

  @override
  void initState() {
    super.initState();
    _inputController.text = _sample;
    _parse();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  String _detectBrowser(String ua) {
    final String u = ua.toLowerCase();
    if (u.contains('edg/') || u.contains('edge/')) {
      return 'Microsoft Edge';
    }
    if (u.contains('opr/') || u.contains('opera')) return 'Opera';
    if (u.contains('opios')) return 'Opera Mini';
    if (u.contains('chrome') && !u.contains('chromium')) return 'Chrome';
    if (u.contains('chromium')) return 'Chromium';
    if (u.contains('firefox') || u.contains('fxios')) return 'Firefox';
    if (u.contains('safari') && !u.contains('chrome')) return 'Safari';
    if (u.contains('msie') || u.contains('trident')) return 'Internet Explorer';
    if (u.contains('samsungbrowser')) return 'Samsung Internet';
    if (u.contains('ucbrowser')) return 'UC Browser';
    if (u.contains('brave')) return 'Brave';
    if (u.contains('vivaldi')) return 'Vivaldi';
    if (u.contains('yabrowser')) return 'Yandex Browser';
    return '';
  }

  String _browserVersion(String ua, String browser) {
    RegExp? re;
    switch (browser) {
      case 'Microsoft Edge':
        re = RegExp(r'(?:Edg|Edge)/([\d.]+)');
        break;
      case 'Opera':
        re = RegExp(r'(?:OPR|Opera)/([\d.]+)');
        break;
      case 'Opera Mini':
        re = RegExp(r'OPiOS/([\d.]+)');
        break;
      case 'Chrome':
        re = RegExp(r'Chrome/([\d.]+)');
        break;
      case 'Chromium':
        re = RegExp(r'Chromium/([\d.]+)');
        break;
      case 'Firefox':
        re = RegExp(r'(?:Firefox|FxiOS)/([\d.]+)');
        break;
      case 'Safari':
        re = RegExp(r'Version/([\d.]+)');
        break;
      case 'Internet Explorer':
        re = RegExp(r'(?:MSIE |rv:)([\d.]+)');
        break;
      case 'Samsung Internet':
        re = RegExp(r'SamsungBrowser/([\d.]+)');
        break;
      case 'UC Browser':
        re = RegExp(r'UCBrowser/([\d.]+)');
        break;
      case 'Yandex Browser':
        re = RegExp(r'YaBrowser/([\d.]+)');
        break;
    }
    final Match? m = re?.firstMatch(ua);
    return m?.group(1) ?? '';
  }

  String _detectOs(String ua) {
    final String u = ua.toLowerCase();
    if (u.contains('windows nt 10')) return 'Windows 10/11';
    if (u.contains('windows nt 6.3')) return 'Windows 8.1';
    if (u.contains('windows nt 6.2')) return 'Windows 8';
    if (u.contains('windows nt 6.1')) return 'Windows 7';
    if (u.contains('windows')) return 'Windows';
    if (u.contains('android')) return 'Android';
    if (u.contains('iphone') || u.contains('ipad') || u.contains('ipod')) {
      return 'iOS';
    }
    if (u.contains('mac os x') || u.contains('macintosh')) return 'macOS';
    if (u.contains('cros')) return 'Chrome OS';
    if (u.contains('ubuntu')) return 'Ubuntu';
    if (u.contains('linux')) return 'Linux';
    if (u.contains('freebsd')) return 'FreeBSD';
    return '';
  }

  String _osVersion(String ua, String os) {
    RegExp? re;
    switch (os) {
      case 'Android':
        re = RegExp(r'Android\s+([\d.]+)');
        break;
      case 'iOS':
        re = RegExp(r'OS\s+([\d_]+)\s+like');
        break;
      case 'macOS':
        re = RegExp(r'Mac OS X\s+([\d_.]+)');
        break;
      case 'Windows 10/11':
        re = RegExp(r'Windows NT\s+([\d.]+)');
        break;
    }
    final Match? m = re?.firstMatch(ua);
    if (m == null) return '';
    return m.group(1)!.replaceAll('_', '.');
  }

  String _detectDevice(String ua) {
    final String u = ua.toLowerCase();
    if (u.contains('iphone')) return 'iPhone';
    if (u.contains('ipad')) return 'iPad';
    if (u.contains('ipod')) return 'iPod';
    if (u.contains('android')) {
      final RegExp re = RegExp(r'Android[^;]*;\s*([^)]+)\)');
      final Match? m = re.firstMatch(ua);
      if (m != null) {
        String model = m.group(1)!.trim();
        if (model.toLowerCase().contains('build')) {
          model = model.split(' Build').first.trim();
        }
        return model;
      }
      return 'Android Device';
    }
    if (u.contains('windows')) return 'PC';
    if (u.contains('macintosh')) return 'Mac';
    if (u.contains('linux')) return 'Linux PC';
    if (u.contains('bot') || u.contains('crawler') || u.contains('spider')) {
      return 'Bot / Crawler';
    }
    return '';
  }

  String _detectType(String ua) {
    final String u = ua.toLowerCase();
    if (u.contains('bot') || u.contains('crawler') || u.contains('spider')) {
      return 'Bot';
    }
    if (u.contains('tablet') || u.contains('ipad')) return 'Tablet';
    if (u.contains('mobile') || u.contains('iphone') || u.contains('android')) {
      return 'Mobile';
    }
    return 'Desktop';
  }

  String _detectEngine(String ua) {
    final String u = ua.toLowerCase();
    if (u.contains('blink') ||
        (u.contains('chrome') && !u.contains('edge'))) {
      return 'Blink';
    }
    if (u.contains('webkit')) return 'WebKit';
    if (u.contains('gecko') && u.contains('firefox')) return 'Gecko';
    if (u.contains('trident')) return 'Trident';
    return '';
  }

  void _parse() {
    final String ua = _inputController.text.trim();
    if (ua.isEmpty) {
      setState(() {
        _info = <String, String>{};
        _parsed = false;
      });
      return;
    }
    final String browser = _detectBrowser(ua);
    final String os = _detectOs(ua);
    final Map<String, String> info = <String, String>{};
    info['uaparse_browser'] = browser.isEmpty
        ? '-'
        : '$browser ${_browserVersion(ua, browser)}'.trim();
    info['uaparse_os'] = os.isEmpty
        ? '-'
        : '$os ${_osVersion(ua, os)}'.trim();
    info['uaparse_device'] = _detectDevice(ua).isEmpty
        ? '-'
        : _detectDevice(ua);
    info['uaparse_type'] = _detectType(ua);
    final String engine = _detectEngine(ua);
    info['uaparse_engine'] = engine.isEmpty ? '-' : engine;
    setState(() {
      _info = info;
      _parsed = true;
    });
  }

  void _clear() {
    setState(() {
      _inputController.clear();
      _info = <String, String>{};
      _parsed = false;
    });
  }

  Future<void> _paste() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null) return;
    _inputController.text = data.text!;
    _parse();
  }

  Future<void> _copy(String text) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('uaparse_copied'))),
    );
  }

  Widget _infoRow(String labelKey, String value, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(
              context.t(labelKey),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => _copy(value),
            icon: const Icon(Icons.copy, size: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('uaparse_title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    context.t('uaparse_input_hint'),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: _paste,
                  icon: const Icon(Icons.paste, size: 18),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: _clear,
                  icon: const Icon(Icons.clear, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _inputController,
              maxLines: 5,
              minLines: 3,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _parse,
              child: Text(context.t('uaparse_parse')),
            ),
            const SizedBox(height: 16),
            if (_parsed)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      for (final String key in _info.keys)
                        _infoRow(key, _info[key] ?? '-', colors),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}