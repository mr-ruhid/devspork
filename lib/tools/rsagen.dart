import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization/app_localization.dart';

class RsaGen extends StatefulWidget {
  const RsaGen({super.key});

  @override
  State<RsaGen> createState() => _RsaGenState();
}

class _RsaGenState extends State<RsaGen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  int _keySize = 2048;
  bool _loading = false;
  String _privatePem = '';
  String _publicPem = '';
  String? _errorKey;
  String? _errorDetail;

  Isolate? _isolate;
  ReceivePort? _receivePort;

  static const List<int> _sizes = <int>[1024, 2048, 3072, 4096];

  static const Color _accentA = Color(0xFF7C4DFF);
  static const Color _accentB = Color(0xFF00E5FF);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();
    super.dispose();
  }

  static void _generateEntry(List<dynamic> args) {
    final SendPort sendPort = args[0] as SendPort;
    final int bits = args[1] as int;
    try {
      final AsymmetricKeyPair<PublicKey, PrivateKey> pair =
      CryptoUtils.generateRSAKeyPair(keySize: bits);
      final RSAPrivateKey priv = pair.privateKey as RSAPrivateKey;
      final RSAPublicKey pub = pair.publicKey as RSAPublicKey;
      final String privatePem = CryptoUtils.encodeRSAPrivateKeyToPem(priv);
      final String publicPem = CryptoUtils.encodeRSAPublicKeyToPem(pub);
      sendPort.send(<String>[privatePem, publicPem]);
    } catch (e) {
      sendPort.send(e.toString());
    }
  }

  Future<void> _generate() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _errorKey = null;
      _errorDetail = null;
      _privatePem = '';
      _publicPem = '';
    });

    final ReceivePort receivePort = ReceivePort();
    _receivePort = receivePort;

    try {
      _isolate = await Isolate.spawn<List<dynamic>>(
        _generateEntry,
        <dynamic>[receivePort.sendPort, _keySize],
      );
      final dynamic result = await receivePort.first;

      if (!mounted) return;

      if (result is List<String>) {
        setState(() {
          _privatePem = result[0];
          _publicPem = result[1];
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _errorKey = 'rsagen_error';
          _errorDetail = result.toString();
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorKey = 'rsagen_error';
        _errorDetail = e.toString();
      });
    } finally {
      receivePort.close();
      _receivePort = null;
      _isolate = null;
    }
  }

  void _cancelGeneration() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _receivePort?.close();
    _receivePort = null;
    setState(() {
      _loading = false;
    });
  }

  void _clear() {
    setState(() {
      _privatePem = '';
      _publicPem = '';
      _errorKey = null;
      _errorDetail = null;
    });
  }

  Future<void> _copy(String text) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withOpacity(0.75),
        content: Text(context.t('rsagen_copied')),
      ),
    );
  }

  String _estimatedTime(int bits) {
    switch (bits) {
      case 1024:
        return context.t('rsagen_time_fast');
      case 2048:
        return context.t('rsagen_time_medium');
      case 3072:
        return context.t('rsagen_time_slow');
      case 4096:
      default:
        return context.t('rsagen_time_veryslow');
    }
  }

  double _strength(int bits) {
    switch (bits) {
      case 1024:
        return 0.25;
      case 2048:
        return 0.6;
      case 3072:
        return 0.85;
      case 4096:
      default:
        return 1.0;
    }
  }

  Color _strengthColor(int bits) {
    switch (bits) {
      case 1024:
        return const Color(0xFFFF5C5C);
      case 2048:
        return const Color(0xFFFFC24B);
      case 3072:
        return const Color(0xFF4BD68B);
      case 4096:
      default:
        return _accentB;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasKeys = _privatePem.isNotEmpty && _publicPem.isNotEmpty;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.t('rsagen_title')),
        bottom: hasKeys ? _glassTabBar() : null,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF1B1035),
              Color(0xFF2A1550),
              Color(0xFF0F2A4A),
            ],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: -80,
              left: -60,
              child: _blurBlob(220, _accentA),
            ),
            Positioned(
              bottom: -100,
              right: -60,
              child: _blurBlob(260, _accentB),
            ),
            SafeArea(
              child: hasKeys ? _buildKeysView() : _buildFormView(),
            ),
          ],
        ),
      ),
      floatingActionButton: hasKeys ? _glassFab() : null,
    );
  }

  PreferredSizeWidget _glassTabBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(52),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: _GlassCard(
          padding: const EdgeInsets.all(4),
          radius: 16,
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: <Color>[_accentA, _accentB],
              ),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: <Widget>[
              Tab(text: context.t('rsagen_tab_private')),
              Tab(text: context.t('rsagen_tab_public')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeysView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 64, 16, 16),
      child: TabBarView(
        controller: _tabController,
        children: <Widget>[
          _keyView(
            titleKey: 'rsagen_private_label',
            pem: _privatePem,
          ),
          _keyView(
            titleKey: 'rsagen_public_label',
            pem: _publicPem,
          ),
        ],
      ),
    );
  }

  Widget _keyView({required String titleKey, required String pem}) {
    if (pem.isEmpty) {
      return Center(
        child: Text(
          context.t('rsagen_no_key'),
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }
    return SingleChildScrollView(
      child: _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    context.t(titleKey),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _GlassIconButton(
                  icon: Icons.copy,
                  onTap: () => _copy(pem),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: SelectableText(
                pem,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  height: 1.5,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 100, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  context.t('rsagen_key_size'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _sizes.map((int s) {
                    final bool selected = _keySize == s;
                    return GestureDetector(
                      onTap: _loading ? null : () => setState(() => _keySize = s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: selected
                              ? const LinearGradient(
                            colors: <Color>[_accentA, _accentB],
                          )
                              : null,
                          color: selected ? null : Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? Colors.transparent
                                : Colors.white.withOpacity(0.15),
                          ),
                        ),
                        child: Text(
                          '$s bit',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Icon(Icons.shield_outlined,
                        size: 16, color: _strengthColor(_keySize)),
                    const SizedBox(width: 6),
                    Text(
                      _estimatedTime(_keySize),
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _strength(_keySize),
                    minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _strengthColor(_keySize),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (_loading)
                  Column(
                    children: <Widget>[
                      const SizedBox(height: 8),
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: _accentB,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        context.t('rsagen_generating'),
                        style: const TextStyle(color: Colors.white60),
                      ),
                      const SizedBox(height: 14),
                      TextButton.icon(
                        onPressed: _cancelGeneration,
                        icon: const Icon(Icons.close, size: 16, color: Colors.white60),
                        label: Text(
                          context.t('rsagen_cancel'),
                          style: const TextStyle(color: Colors.white60),
                        ),
                      ),
                    ],
                  )
                else
                  _GlassPrimaryButton(
                    icon: Icons.vpn_key_rounded,
                    label: context.t('rsagen_generate'),
                    onTap: _generate,
                  ),
                if (_errorKey != null) ...<Widget>[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5C5C).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFF5C5C).withOpacity(0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          context.t(_errorKey!),
                          style: const TextStyle(
                            color: Color(0xFFFF8A8A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_errorDetail != null) ...<Widget>[
                          const SizedBox(height: 4),
                          Text(
                            _errorDetail!,
                            style: const TextStyle(
                              color: Color(0xFFFFBFBF),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(Icons.info_outline,
                        size: 16, color: Colors.white60),
                    const SizedBox(width: 8),
                    Text(
                      context.t('rsagen_info_title'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  context.t('rsagen_info_body'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassFab() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.white.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: _clear,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.refresh, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    context.t('rsagen_new'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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

  Widget _blurBlob(double size, Color color) {
    return IgnorePointer(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.35),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white.withOpacity(0.08),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(icon, size: 18, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassPrimaryButton extends StatelessWidget {
  const _GlassPrimaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[
                  _RsaGenState._accentA,
                  _RsaGenState._accentB,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
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