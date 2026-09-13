import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class SocialLinks extends StatefulWidget {
  const SocialLinks({super.key});

  @override
  State<SocialLinks> createState() => _SocialLinksState();
}

class _SocialLinksState extends State<SocialLinks>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Tab 1: Social
  final TextEditingController _usernameController = TextEditingController();
  final Set<String> _enabled = <String>{
    'instagram',
    'instagram_dm',
    'facebook',
    'messenger',
    'whatsapp',
    'telegram',
    'twitter',
    'tiktok',
    'youtube',
    'linkedin',
    'github',
    'reddit',
    'pinterest',
    'snapchat',
    'email',
    'phone',
  };
  Map<String, String> _generated = <String, String>{};
  String? _socialError;

  // Tab 2: UTM
  final TextEditingController _utmUrlController = TextEditingController();
  final TextEditingController _utmSourceController = TextEditingController();
  final TextEditingController _utmMediumController = TextEditingController();
  final TextEditingController _utmCampaignController = TextEditingController();
  final TextEditingController _utmTermController = TextEditingController();
  final TextEditingController _utmContentController = TextEditingController();
  final TextEditingController _utmOutputController = TextEditingController();
  String? _utmError;

  // Tab 3: WhatsApp
  final TextEditingController _waPhoneController = TextEditingController();
  final TextEditingController _waMessageController = TextEditingController();
  final TextEditingController _waOutputController = TextEditingController();
  String? _waError;

  // Tab 4: Email / SMS
  final TextEditingController _mailToController = TextEditingController();
  final TextEditingController _mailCcController = TextEditingController();
  final TextEditingController _mailBccController = TextEditingController();
  final TextEditingController _mailSubjectController = TextEditingController();
  final TextEditingController _mailBodyController = TextEditingController();
  final TextEditingController _mailOutputController = TextEditingController();
  final TextEditingController _smsPhoneController = TextEditingController();
  final TextEditingController _smsBodyController = TextEditingController();
  final TextEditingController _smsOutputController = TextEditingController();
  String? _mailError;
  String? _smsError;

  static const Map<String, String> _platformLabels = <String, String>{
    'instagram': 'Instagram Profile',
    'instagram_dm': 'Instagram DM',
    'facebook': 'Facebook',
    'messenger': 'Messenger',
    'whatsapp': 'WhatsApp',
    'telegram': 'Telegram',
    'twitter': 'Twitter / X',
    'tiktok': 'TikTok',
    'youtube': 'YouTube',
    'linkedin': 'LinkedIn',
    'github': 'GitHub',
    'reddit': 'Reddit',
    'pinterest': 'Pinterest',
    'snapchat': 'Snapchat',
    'email': 'Email',
    'phone': 'Phone',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _usernameController.text = 'devspork';
    _utmUrlController.text = 'https://example.com';
    _waPhoneController.text = '994501234567';
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {}); // reset düyməsinin tooltip-i tab dəyişəndə yenilənsin
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    _utmUrlController.dispose();
    _utmSourceController.dispose();
    _utmMediumController.dispose();
    _utmCampaignController.dispose();
    _utmTermController.dispose();
    _utmContentController.dispose();
    _utmOutputController.dispose();
    _waPhoneController.dispose();
    _waMessageController.dispose();
    _waOutputController.dispose();
    _mailToController.dispose();
    _mailCcController.dispose();
    _mailBccController.dispose();
    _mailSubjectController.dispose();
    _mailBodyController.dispose();
    _mailOutputController.dispose();
    _smsPhoneController.dispose();
    _smsBodyController.dispose();
    _smsOutputController.dispose();
    super.dispose();
  }

  String _cleanUsername(String raw) {
    String s = raw.trim();
    if (s.startsWith('@')) s = s.substring(1);
    s = s.replaceAll(RegExp(r'^https?://'), '');
    s = s.replaceAll(RegExp(r'^www\.'), '');
    final List<String> hosts = <String>[
      'instagram.com',
      'facebook.com',
      'fb.com',
      'tiktok.com',
      'twitter.com',
      'x.com',
      'youtube.com',
      'linkedin.com',
      'github.com',
      'reddit.com',
      'pinterest.com',
      'snapchat.com',
      't.me',
      'telegram.me',
      'm.me',
      'ig.me',
      'wa.me',
    ];
    for (final String h in hosts) {
      if (s.toLowerCase().startsWith(h)) {
        s = s.substring(h.length);
        break;
      }
    }
    s = s.replaceAll(RegExp(r'^/+'), '');
    s = s.replaceAll(RegExp(r'/+$'), '');
    if (s.contains('/')) {
      s = s.split('/').first;
    }
    return s;
  }

  String _cleanPhone(String raw) {
    return raw.replaceAll(RegExp(r'[^\d]'), '');
  }

  /// SMS mətninin təxmini seqment sayı (standart GSM-7: 160 simvol / 1
  /// seqment, çoxseqmentli mesajlarda hər seqment 153 simvol).
  int _smsSegments(String text) {
    if (text.isEmpty) return 0;
    final int len = text.length;
    if (len <= 160) return 1;
    return (len / 153).ceil();
  }

  void _generateSocial() {
    final String raw = _usernameController.text;
    if (raw.trim().isEmpty) {
      setState(() {
        _socialError = 'sociallinks_error_empty';
        _generated = <String, String>{};
      });
      return;
    }
    final String username = _cleanUsername(raw);
    final Map<String, String> result = <String, String>{};

    bool wants(String id) => _enabled.contains(id);

    if (wants('instagram')) {
      result['Instagram Profile'] = 'https://instagram.com/$username';
    }
    if (wants('instagram_dm')) {
      result['Instagram DM'] = 'https://ig.me/m/$username';
    }
    if (wants('facebook')) {
      result['Facebook'] = 'https://facebook.com/$username';
    }
    if (wants('messenger')) {
      result['Messenger'] = 'https://m.me/$username';
    }
    if (wants('whatsapp')) {
      final String phone = _cleanPhone(raw);
      if (phone.isNotEmpty) {
        result['WhatsApp'] = 'https://wa.me/$phone';
      }
    }
    if (wants('telegram')) {
      result['Telegram'] = 'https://t.me/$username';
    }
    if (wants('twitter')) {
      result['Twitter / X'] = 'https://x.com/$username';
    }
    if (wants('tiktok')) {
      result['TikTok'] = 'https://tiktok.com/@$username';
    }
    if (wants('youtube')) {
      result['YouTube'] = 'https://youtube.com/@$username';
    }
    if (wants('linkedin')) {
      result['LinkedIn'] = 'https://linkedin.com/in/$username';
    }
    if (wants('github')) {
      result['GitHub'] = 'https://github.com/$username';
    }
    if (wants('reddit')) {
      result['Reddit'] = 'https://reddit.com/user/$username';
    }
    if (wants('pinterest')) {
      result['Pinterest'] = 'https://pinterest.com/$username';
    }
    if (wants('snapchat')) {
      result['Snapchat'] = 'https://snapchat.com/add/$username';
    }
    if (wants('email')) {
      final String email =
      raw.contains('@') && raw.contains('.') ? raw.trim() : '';
      if (email.isNotEmpty) {
        result['Email'] = 'mailto:$email';
      }
    }
    if (wants('phone')) {
      final String phone = _cleanPhone(raw);
      if (phone.isNotEmpty) {
        result['Phone'] = 'tel:+$phone';
      }
    }

    setState(() {
      _generated = result;
      _socialError = result.isEmpty ? 'sociallinks_error_none' : null;
    });
  }

  void _selectAllPlatforms() {
    setState(() {
      _enabled
        ..clear()
        ..addAll(_platformLabels.keys);
    });
  }

  void _clearAllPlatforms() {
    setState(() {
      _enabled.clear();
    });
  }

  Future<void> _copyAllGenerated() async {
    if (_generated.isEmpty) return;
    final String text = _generated.entries
        .map((MapEntry<String, String> e) => '${e.key}: ${e.value}')
        .join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('sociallinks_copied_all'))),
    );
  }

  void _resetSocial() {
    setState(() {
      _usernameController.clear();
      _enabled
        ..clear()
        ..addAll(_platformLabels.keys);
      _generated = <String, String>{};
      _socialError = null;
    });
  }

  void _generateUtm() {
    final String url = _utmUrlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _utmError = 'sociallinks_error_url';
        _utmOutputController.text = '';
      });
      return;
    }
    try {
      final Uri base = Uri.parse(url);
      final Map<String, String> params = Map<String, String>.from(
        base.queryParameters,
      );
      void addIfNotEmpty(String key, String value) {
        final String v = value.trim();
        if (v.isNotEmpty) params[key] = v;
      }

      addIfNotEmpty('utm_source', _utmSourceController.text);
      addIfNotEmpty('utm_medium', _utmMediumController.text);
      addIfNotEmpty('utm_campaign', _utmCampaignController.text);
      addIfNotEmpty('utm_term', _utmTermController.text);
      addIfNotEmpty('utm_content', _utmContentController.text);

      if (params.isEmpty) {
        setState(() {
          _utmError = 'sociallinks_error_utm_params';
          _utmOutputController.text = '';
        });
        return;
      }

      final Uri built = base.replace(queryParameters: params);
      setState(() {
        _utmOutputController.text = built.toString();
        _utmError = null;
      });
    } catch (e) {
      setState(() {
        _utmError = 'sociallinks_error_invalid_url';
        _utmOutputController.text = '';
      });
    }
  }

  void _resetUtm() {
    setState(() {
      _utmUrlController.clear();
      _utmSourceController.clear();
      _utmMediumController.clear();
      _utmCampaignController.clear();
      _utmTermController.clear();
      _utmContentController.clear();
      _utmOutputController.clear();
      _utmError = null;
    });
  }

  void _generateWhatsApp() {
    final String phone = _cleanPhone(_waPhoneController.text);
    if (phone.isEmpty) {
      setState(() {
        _waError = 'sociallinks_error_phone';
        _waOutputController.text = '';
      });
      return;
    }
    final String msg = _waMessageController.text.trim();
    final String base = 'https://wa.me/$phone';
    final String result =
    msg.isEmpty ? base : '$base?text=${Uri.encodeQueryComponent(msg)}';
    setState(() {
      _waOutputController.text = result;
      _waError = null;
    });
  }

  void _resetWhatsApp() {
    setState(() {
      _waPhoneController.clear();
      _waMessageController.clear();
      _waOutputController.clear();
      _waError = null;
    });
  }

  void _generateMail() {
    final String to = _mailToController.text.trim();
    if (to.isEmpty || !to.contains('@')) {
      setState(() {
        _mailError = 'sociallinks_error_email';
        _mailOutputController.text = '';
      });
      return;
    }
    final List<String> parts = <String>[];
    final String cc = _mailCcController.text.trim();
    final String bcc = _mailBccController.text.trim();
    final String subject = _mailSubjectController.text.trim();
    final String body = _mailBodyController.text;
    if (cc.isNotEmpty) {
      parts.add('cc=${Uri.encodeQueryComponent(cc)}');
    }
    if (bcc.isNotEmpty) {
      parts.add('bcc=${Uri.encodeQueryComponent(bcc)}');
    }
    if (subject.isNotEmpty) {
      parts.add('subject=${Uri.encodeQueryComponent(subject)}');
    }
    if (body.isNotEmpty) {
      parts.add('body=${Uri.encodeQueryComponent(body)}');
    }
    final String query = parts.isEmpty ? '' : '?${parts.join('&')}';
    setState(() {
      _mailOutputController.text = 'mailto:$to$query';
      _mailError = null;
    });
  }

  void _generateSms() {
    final String phone = _cleanPhone(_smsPhoneController.text);
    if (phone.isEmpty) {
      setState(() {
        _smsError = 'sociallinks_error_phone';
        _smsOutputController.text = '';
      });
      return;
    }
    final String body = _smsBodyController.text;
    final String query =
    body.isEmpty ? '' : '?body=${Uri.encodeQueryComponent(body)}';
    setState(() {
      _smsOutputController.text = 'sms:+$phone$query';
      _smsError = null;
    });
  }

  void _resetMailSms() {
    setState(() {
      _mailToController.clear();
      _mailCcController.clear();
      _mailBccController.clear();
      _mailSubjectController.clear();
      _mailBodyController.clear();
      _mailOutputController.clear();
      _smsPhoneController.clear();
      _smsBodyController.clear();
      _smsOutputController.clear();
      _mailError = null;
      _smsError = null;
    });
  }

  void _resetCurrentTab() {
    switch (_tabController.index) {
      case 0:
        _resetSocial();
        break;
      case 1:
        _resetUtm();
        break;
      case 2:
        _resetWhatsApp();
        break;
      case 3:
        _resetMailSms();
        break;
    }
  }

  Future<void> _copy(String text) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('sociallinks_copied'))),
    );
  }

  Future<void> _pasteTo(TextEditingController c) async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null) return;
    c.text = data.text!;
  }

  // ---------- Glass helpers ----------

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Widget _glassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    final bool isDark = _isDark;
    final Color tint =
    isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.55);
    final Color borderColor =
    isDark ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.6);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  InputDecoration _glassDecoration({
    String? labelText,
    String? hint,
    Widget? suffixIcon,
  }) {
    final bool isDark = _isDark;
    return InputDecoration(
      labelText: labelText,
      hintText: hint,
      filled: true,
      fillColor: Colors.white.withOpacity(isDark ? 0.06 : 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      isDense: true,
      contentPadding: const EdgeInsets.all(12),
      suffixIcon: suffixIcon,
    );
  }

  // ---------- UI helpers ----------

  Widget _inputRow({
    required String labelKey,
    required TextEditingController controller,
    bool allowPaste = true,
    int maxLines = 1,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        minLines: 1,
        decoration: _glassDecoration(
          labelText: context.t(labelKey),
          hint: hint,
          suffixIcon: allowPaste
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

  Widget _outputField(TextEditingController controller) {
    return TextField(
      controller: controller,
      readOnly: true,
      maxLines: 3,
      minLines: 2,
      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      decoration: _glassDecoration(
        suffixIcon: IconButton(
          onPressed: () => _copy(controller.text),
          icon: const Icon(Icons.copy),
        ),
      ),
    );
  }

  Widget _errorText(String? key, ColorScheme colors) {
    if (key == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        context.t(key),
        style: TextStyle(color: colors.error, fontSize: 12),
      ),
    );
  }

  // ---------- Tabs ----------

  Widget _buildSocialTab(ColorScheme colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _inputRow(
                  labelKey: 'sociallinks_username',
                  controller: _usernameController,
                  hint: '@username və ya telefon (994...)',
                ),
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        context.t('sociallinks_platforms'),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    TextButton(
                      onPressed: _selectAllPlatforms,
                      child: Text(context.t('sociallinks_select_all')),
                    ),
                    TextButton(
                      onPressed: _clearAllPlatforms,
                      child: Text(context.t('sociallinks_clear_all')),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _platformLabels.entries.map((
                      MapEntry<String, String> entry) {
                    final String id = entry.key;
                    final bool selected = _enabled.contains(id);
                    return FilterChip(
                      label: Text(
                        entry.value,
                        style: const TextStyle(fontSize: 12),
                      ),
                      selected: selected,
                      backgroundColor: Colors.white.withOpacity(
                        _isDark ? 0.06 : 0.4,
                      ),
                      onSelected: (bool v) {
                        setState(() {
                          if (v) {
                            _enabled.add(id);
                          } else {
                            _enabled.remove(id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _generateSocial,
                  icon: const Icon(Icons.link),
                  label: Text(context.t('sociallinks_generate')),
                ),
                _errorText(_socialError, colors),
              ],
            ),
          ),
          if (_generated.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            _glassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          '${context.t('sociallinks_results')} (${_generated.length})',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _copyAllGenerated,
                        icon: const Icon(Icons.copy_all, size: 18),
                        label: Text(context.t('sociallinks_copy_all')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  for (final MapEntry<String, String> e in _generated.entries)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(_isDark ? 0.05 : 0.35),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  e.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _copy(e.value),
                                icon: const Icon(Icons.copy, size: 18),
                              ),
                            ],
                          ),
                          SelectableText(
                            e.value,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ],
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

  Widget _buildUtmTab(ColorScheme colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _inputRow(
                  labelKey: 'sociallinks_utm_url',
                  controller: _utmUrlController,
                  hint: 'https://example.com/page',
                ),
                _inputRow(
                  labelKey: 'sociallinks_utm_source',
                  controller: _utmSourceController,
                  hint: 'google, facebook, newsletter',
                ),
                _inputRow(
                  labelKey: 'sociallinks_utm_medium',
                  controller: _utmMediumController,
                  hint: 'cpc, email, social',
                ),
                _inputRow(
                  labelKey: 'sociallinks_utm_campaign',
                  controller: _utmCampaignController,
                  hint: 'spring_sale',
                ),
                _inputRow(
                  labelKey: 'sociallinks_utm_term',
                  controller: _utmTermController,
                  hint: 'running+shoes',
                ),
                _inputRow(
                  labelKey: 'sociallinks_utm_content',
                  controller: _utmContentController,
                  hint: 'logolink, textlink',
                ),
                const SizedBox(height: 4),
                FilledButton.icon(
                  onPressed: _generateUtm,
                  icon: const Icon(Icons.link),
                  label: Text(context.t('sociallinks_generate')),
                ),
                _errorText(_utmError, colors),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _glassCard(child: _outputField(_utmOutputController)),
        ],
      ),
    );
  }

  Widget _buildWhatsAppTab(ColorScheme colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _inputRow(
                  labelKey: 'sociallinks_wa_phone',
                  controller: _waPhoneController,
                  hint: '994501234567',
                ),
                _inputRow(
                  labelKey: 'sociallinks_wa_message',
                  controller: _waMessageController,
                  maxLines: 4,
                ),
                const SizedBox(height: 4),
                FilledButton.icon(
                  onPressed: _generateWhatsApp,
                  icon: const Icon(Icons.chat),
                  label: Text(context.t('sociallinks_generate')),
                ),
                _errorText(_waError, colors),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _glassCard(child: _outputField(_waOutputController)),
        ],
      ),
    );
  }

  Widget _buildMailSmsTab(ColorScheme colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  context.t('sociallinks_mail_section'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                _inputRow(
                  labelKey: 'sociallinks_mail_to',
                  controller: _mailToController,
                  hint: 'someone@example.com',
                ),
                _inputRow(
                  labelKey: 'sociallinks_mail_cc',
                  controller: _mailCcController,
                  hint: 'cc@example.com',
                ),
                _inputRow(
                  labelKey: 'sociallinks_mail_bcc',
                  controller: _mailBccController,
                  hint: 'bcc@example.com',
                ),
                _inputRow(
                  labelKey: 'sociallinks_mail_subject',
                  controller: _mailSubjectController,
                ),
                _inputRow(
                  labelKey: 'sociallinks_mail_body',
                  controller: _mailBodyController,
                  maxLines: 4,
                ),
                FilledButton.icon(
                  onPressed: _generateMail,
                  icon: const Icon(Icons.email),
                  label: Text(context.t('sociallinks_generate')),
                ),
                _errorText(_mailError, colors),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _glassCard(child: _outputField(_mailOutputController)),
          const SizedBox(height: 24),
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  context.t('sociallinks_sms_section'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                _inputRow(
                  labelKey: 'sociallinks_sms_phone',
                  controller: _smsPhoneController,
                  hint: '994501234567',
                ),
                _inputRow(
                  labelKey: 'sociallinks_sms_body',
                  controller: _smsBodyController,
                  maxLines: 3,
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _smsBodyController,
                  builder: (BuildContext context, TextEditingValue value,
                      Widget? _) {
                    final int len = value.text.length;
                    final int segments = _smsSegments(value.text);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${context.t('sociallinks_sms_chars')}: $len'
                            ' • ${context.t('sociallinks_sms_segments')}: $segments',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  },
                ),
                FilledButton.icon(
                  onPressed: _generateSms,
                  icon: const Icon(Icons.sms),
                  label: Text(context.t('sociallinks_generate')),
                ),
                _errorText(_smsError, colors),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _glassCard(child: _outputField(_smsOutputController)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isDark = _isDark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(context.t('sociallinks_title')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: <Widget>[
          IconButton(
            onPressed: _resetCurrentTab,
            icon: const Icon(Icons.refresh),
            tooltip: context.t('sociallinks_reset'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: <Widget>[
            Tab(text: context.t('sociallinks_tab_social')),
            Tab(text: context.t('sociallinks_tab_utm')),
            Tab(text: context.t('sociallinks_tab_wa')),
            Tab(text: context.t('sociallinks_tab_mail_sms')),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? <Color>[
              const Color(0xFF1B1035),
              const Color(0xFF0F1C3F),
              const Color(0xFF091626),
            ]
                : <Color>[
              const Color(0xFFDCE9FF),
              const Color(0xFFE9E2FF),
              const Color(0xFFF3F6FF),
            ],
          ),
        ),
        child: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: <Widget>[
              _buildSocialTab(colors),
              _buildUtmTab(colors),
              _buildWhatsAppTab(colors),
              _buildMailSmsTab(colors),
            ],
          ),
        ),
      ),
    );
  }
}