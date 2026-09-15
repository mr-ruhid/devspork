import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'server.dart';
import 'spec_parser.dart';

const Color _accentA = Color(0xFF7C4DFF);
const Color _accentB = Color(0xFF00E5FF);
const Color _danger = Color(0xFFFF5C5C);
const Color _warning = Color(0xFFFFC24B);
const Color _success = Color(0xFF4BD68B);
const Color _info = Color(0xFF4B9BFF);
const Color _bgTop = Color(0xFF1B1035);
const Color _bgMid = Color(0xFF2A1550);
const Color _bgBot = Color(0xFF0F2A4A);

class MockServerPage extends StatefulWidget {
  const MockServerPage({super.key});

  @override
  State<MockServerPage> createState() => _MockServerPageState();
}

class _MockServerPageState extends State<MockServerPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final MockServerController _controller = MockServerController();

  final List<MockEndpoint> _endpoints = <MockEndpoint>[];
  MockServerConfig _config = MockServerConfig();

  final TextEditingController _portCtrl = TextEditingController(text: '8080');
  final TextEditingController _hostCtrl = TextEditingController(text: '0.0.0.0');
  final TextEditingController _delayCtrl = TextEditingController(text: '0');

  Timer? _logTimer;
  String? _startError;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _endpoints.add(
      MockEndpoint(
        method: 'GET',
        path: '/users',
        responseBody: '[\n  {"id": 1, "name": "Alice"},\n  {"id": 2, "name": "Bob"}\n]',
        description: 'Sample endpoint',
      ),
    );
  }

  @override
  void dispose() {
    _logTimer?.cancel();
    _tabs.dispose();
    _portCtrl.dispose();
    _hostCtrl.dispose();
    _delayCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _syncConfigFromUI() {
    _config = MockServerConfig(
      port: int.tryParse(_portCtrl.text.trim()) ?? 8080,
      host: _hostCtrl.text.trim().isEmpty ? '0.0.0.0' : _hostCtrl.text.trim(),
      corsEnabled: _config.corsEnabled,
      logRequests: _config.logRequests,
      globalDelayMs: int.tryParse(_delayCtrl.text.trim()) ?? 0,
    );
  }

  Future<void> _startServer() async {
    FocusScope.of(context).unfocus();
    _syncConfigFromUI();
    setState(() => _startError = null);

    try {
      await _controller.start(
        config: _config,
        endpoints: _endpoints,
        onLog: () {
          if (mounted) setState(() {});
        },
      );
      if (!mounted) return;
      setState(() {});
      _logTimer?.cancel();
      _logTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
      _tabs.animateTo(3);
      HapticFeedback.mediumImpact();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _startError = e.toString();
      });
    }
  }

  Future<void> _stopServer() async {
    _logTimer?.cancel();
    await _controller.stop();
    if (!mounted) return;
    setState(() {});
    HapticFeedback.lightImpact();
  }

  void _addEndpoint() {
    setState(() {
      _endpoints.add(MockEndpoint());
      _controller.updateEndpoints(_endpoints);
    });
  }

  void _removeEndpoint(int index) {
    setState(() {
      _endpoints.removeAt(index);
      _controller.updateEndpoints(_endpoints);
    });
  }

  void _updateEndpoint() {
    _controller.updateEndpoints(_endpoints);
    setState(() {});
  }

  Future<void> _copyText(String text, [String? message]) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    _snack(message ?? 'Kopyalandı');
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withOpacity(0.85),
        content: Text(message, style: const TextStyle(fontSize: 12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openImportDialog() async {
    final TextEditingController ctrl = TextEditingController();
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1550).withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'OpenAPI / Swagger import',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'YAML və ya JSON formatında spec yapışdır',
                    style: TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: ctrl,
                    maxLines: 10,
                    minLines: 5,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                    decoration: InputDecoration(
                      hintText: 'openapi: 3.0.0\ninfo:\n  title: ...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        BorderSide(color: Colors.white.withOpacity(0.15)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        BorderSide(color: Colors.white.withOpacity(0.15)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        const BorderSide(color: _accentB, width: 1.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text(
                          'Ləğv et',
                          style: TextStyle(color: Colors.white60),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text(
                          'İmport',
                          style: TextStyle(
                            color: _accentB,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (result != true) {
      ctrl.dispose();
      return;
    }

    final String spec = ctrl.text;
    ctrl.dispose();

    final OpenApiParseResult parsed = OpenApiParser.parse(spec);
    if (!mounted) return;

    if (!parsed.isSuccess) {
      _snack(parsed.error ?? 'Parse xətası');
      return;
    }

    setState(() {
      _endpoints.clear();
      _endpoints.addAll(parsed.endpoints);
      _controller.updateEndpoints(_endpoints);
    });
    _tabs.animateTo(0);
    _snack('${parsed.endpoints.length} endpoint əlavə edildi');
  }

  @override
  Widget build(BuildContext context) {
    final bool running = _controller.status == MockServerStatus.running;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0B0B12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Mock Server'),
        actions: <Widget>[
          if (running)
            _glassIconButton(
              icon: Icons.link_rounded,
              tooltip: 'URL kopyala',
              onTap: () => _copyText(_controller.baseUrl, _controller.baseUrl),
            ),
          const SizedBox(width: 4),
          _glassIconButton(
            icon: Icons.file_download_outlined,
            tooltip: 'OpenAPI import',
            onTap: _openImportDialog,
          ),
          const SizedBox(width: 8),
        ],
        bottom: _buildTabBar(),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[_bgTop, _bgMid, _bgBot],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(top: -80, left: -60, child: _blob(220, _accentA)),
            Positioned(bottom: -100, right: -60, child: _blob(260, _accentB)),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 56),
                child: TabBarView(
                  controller: _tabs,
                  children: <Widget>[
                    _buildEndpointsTab(),
                    _buildServerTab(),
                    _buildConfigTab(),
                    _buildLogsTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTabBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(52),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: _GlassCard(
          padding: const EdgeInsets.all(4),
          radius: 16,
          child: TabBar(
            controller: _tabs,
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
            labelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            tabs: const <Widget>[
              Tab(text: 'Endpoints'),
              Tab(text: 'Server'),
              Tab(text: 'Config'),
              Tab(text: 'Logs'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEndpointsTab() {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: <Widget>[
              Text(
                '${_endpoints.length} endpoint',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const Spacer(),
              if (_endpoints.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _endpoints.clear();
                      _controller.updateEndpoints(_endpoints);
                    });
                  },
                  icon: const Icon(
                    Icons.delete_sweep_outlined,
                    size: 16,
                    color: _danger,
                  ),
                  label: const Text(
                    'Hamısını sil',
                    style: TextStyle(color: _danger, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: _endpoints.isEmpty
              ? _emptyState(
            icon: Icons.dns_outlined,
            message: 'Heç bir endpoint yoxdur',
          )
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            itemCount: _endpoints.length,
            itemBuilder: (BuildContext context, int i) {
              return _endpointCard(i);
            },
          ),
        ),
      ],
    );
  }

  Widget _endpointCard(int index) {
    final MockEndpoint e = _endpoints[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _GlassCard(
        padding: const EdgeInsets.all(12),
        radius: 14,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _methodColor(e.method).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _methodColor(e.method).withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    e.method,
                    style: TextStyle(
                      color: _methodColor(e.method),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    e.path,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Switch.adaptive(
                  value: e.enabled,
                  onChanged: (bool v) {
                    setState(() {
                      e.enabled = v;
                      _controller.updateEndpoints(_endpoints);
                    });
                  },
                ),
                _miniIconButton(
                  icon: Icons.edit_outlined,
                  onTap: () => _editEndpoint(index),
                ),
                _miniIconButton(
                  icon: Icons.close_rounded,
                  onTap: () => _removeEndpoint(index),
                ),
              ],
            ),
            if (e.description.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                e.description,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                _infoChip(
                  icon: Icons.tag_rounded,
                  label: '${e.statusCode}',
                  color: _statusColor(e.statusCode),
                ),
                const SizedBox(width: 6),
                if (e.delayMs > 0)
                  _infoChip(
                    icon: Icons.timer_outlined,
                    label: '${e.delayMs} ms',
                    color: _warning,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editEndpoint(int index) async {
    final MockEndpoint e = _endpoints[index];
    final TextEditingController methodCtrl =
    TextEditingController(text: e.method);
    final TextEditingController pathCtrl =
    TextEditingController(text: e.path);
    final TextEditingController statusCtrl =
    TextEditingController(text: e.statusCode.toString());
    final TextEditingController delayCtrl =
    TextEditingController(text: e.delayMs.toString());
    final TextEditingController bodyCtrl =
    TextEditingController(text: e.responseBody);
    final TextEditingController descCtrl =
    TextEditingController(text: e.description);

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1550).withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text(
                      'Endpoint redaktə',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        Expanded(
                          flex: 2,
                          child: _dialogField(
                            controller: methodCtrl,
                            label: 'Method',
                            hint: 'GET',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 4,
                          child: _dialogField(
                            controller: pathCtrl,
                            label: 'Path',
                            hint: '/users/{id}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _dialogField(
                            controller: statusCtrl,
                            label: 'Status',
                            hint: '200',
                            numeric: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _dialogField(
                            controller: delayCtrl,
                            label: 'Delay (ms)',
                            hint: '0',
                            numeric: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _dialogField(
                      controller: descCtrl,
                      label: 'Description',
                      hint: 'Optional',
                    ),
                    const SizedBox(height: 10),
                    _dialogField(
                      controller: bodyCtrl,
                      label: 'Response body',
                      hint: '{"key": "value"}',
                      maxLines: 8,
                      minLines: 4,
                      monospace: true,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text(
                            'Ləğv et',
                            style: TextStyle(color: Colors.white60),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text(
                            'Yadda saxla',
                            style: TextStyle(
                              color: _accentB,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (ok != true) {
      methodCtrl.dispose();
      pathCtrl.dispose();
      statusCtrl.dispose();
      delayCtrl.dispose();
      bodyCtrl.dispose();
      descCtrl.dispose();
      return;
    }

    setState(() {
      e.method = methodCtrl.text.trim().toUpperCase().isEmpty
          ? 'GET'
          : methodCtrl.text.trim().toUpperCase();
      e.path = pathCtrl.text.trim().isEmpty ? '/' : pathCtrl.text.trim();
      e.statusCode = int.tryParse(statusCtrl.text.trim()) ?? 200;
      e.delayMs = int.tryParse(delayCtrl.text.trim()) ?? 0;
      e.responseBody = bodyCtrl.text;
      e.description = descCtrl.text.trim();
      _controller.updateEndpoints(_endpoints);
    });

    methodCtrl.dispose();
    pathCtrl.dispose();
    statusCtrl.dispose();
    delayCtrl.dispose();
    bodyCtrl.dispose();
    descCtrl.dispose();
  }

  Widget _dialogField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool numeric = false,
    bool monospace = false,
    int maxLines = 1,
    int minLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      minLines: minLines,
      style: TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontFamily: monospace ? 'monospace' : null,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 11),
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.25),
          fontSize: 11,
          fontFamily: monospace ? 'monospace' : null,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _accentB, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildServerTab() {
    final MockServerStatus status = _controller.status;
    final bool running = status == MockServerStatus.running;
    final bool starting = status == MockServerStatus.starting;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _statusIndicator(status),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: _statusIndicator(status).withOpacity(0.6),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _statusLabel(status),
                      style: TextStyle(
                        color: _statusIndicator(status),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (running) ...<Widget>[
                  const Text(
                    'Base URL',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(10),
                      border:
                      Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: SelectableText(
                            _controller.baseUrl,
                            style: const TextStyle(
                              color: _accentB,
                              fontFamily: 'monospace',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _miniIconButton(
                          icon: Icons.copy_rounded,
                          onTap: () => _copyText(
                            _controller.baseUrl,
                            _controller.baseUrl,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Endpointlər: ${_endpoints.where((MockEndpoint e) => e.enabled).length} aktiv',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
                if (_startError != null) ...<Widget>[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _danger.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _danger.withOpacity(0.4)),
                    ),
                    child: Text(
                      _startError!,
                      style: const TextStyle(
                        color: Color(0xFFFFBFBF),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (running)
                  _primaryButton(
                    icon: Icons.stop_rounded,
                    label: 'Serveri dayandır',
                    color: _danger,
                    onTap: _stopServer,
                  )
                else
                  _primaryButton(
                    icon: starting
                        ? Icons.hourglass_top_rounded
                        : Icons.play_arrow_rounded,
                    label: starting ? 'Başladılır...' : 'Serveri başlat',
                    color: _success,
                    onTap: starting ? null : _startServer,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Sürətli test',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Server işə düşdükdən sonra brauzerdə və ya curl ilə yoxla:',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 10),
                if (running)
                  ...<String>[
                    'curl ${_controller.baseUrl}/users',
                  ].map(
                        (String cmd) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: SelectableText(
                                cmd,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            _miniIconButton(
                              icon: Icons.copy_rounded,
                              onTap: () => _copyText(cmd),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  const Text(
                    'Server aktiv deyil',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusIndicator(MockServerStatus s) {
    switch (s) {
      case MockServerStatus.stopped:
        return Colors.white54;
      case MockServerStatus.starting:
        return _warning;
      case MockServerStatus.running:
        return _success;
      case MockServerStatus.error:
        return _danger;
    }
  }

  String _statusLabel(MockServerStatus s) {
    switch (s) {
      case MockServerStatus.stopped:
        return 'Dayandırılıb';
      case MockServerStatus.starting:
        return 'Başladılır...';
      case MockServerStatus.running:
        return 'İşləyir';
      case MockServerStatus.error:
        return 'Xəta';
    }
  }

  Widget _buildConfigTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Şəbəkə',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: _dialogField(
                        controller: _hostCtrl,
                        label: 'Host',
                        hint: '0.0.0.0',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: _dialogField(
                        controller: _portCtrl,
                        label: 'Port',
                        hint: '8080',
                        numeric: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '0.0.0.0 — bütün interfeyslərə açıqdır (LAN-dan da əlçatandır)',
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Davranış',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                _switchRow(
                  label: 'CORS aktiv',
                  value: _config.corsEnabled,
                  onChanged: (bool v) {
                    setState(() {
                      _config = MockServerConfig(
                        port: _config.port,
                        host: _config.host,
                        corsEnabled: v,
                        logRequests: _config.logRequests,
                        globalDelayMs: _config.globalDelayMs,
                      );
                    });
                  },
                ),
                _switchRow(
                  label: 'Sorğuları log et',
                  value: _config.logRequests,
                  onChanged: (bool v) {
                    setState(() {
                      _config = MockServerConfig(
                        port: _config.port,
                        host: _config.host,
                        corsEnabled: _config.corsEnabled,
                        logRequests: v,
                        globalDelayMs: _config.globalDelayMs,
                      );
                    });
                  },
                ),
                const SizedBox(height: 6),
                _dialogField(
                  controller: _delayCtrl,
                  label: 'Qlobal gecikmə (ms)',
                  hint: '0',
                  numeric: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Qeyd',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Config dəyişiklikləri yalnız server dayandırılmış halda tətbiq olunur. Serveri yenidən başlat.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
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

  Widget _buildLogsTab() {
    final List<ServerLogEntry> logs = _controller.logs;

    if (logs.isEmpty) {
      return _emptyState(
        icon: Icons.receipt_long_outlined,
        message: _controller.status == MockServerStatus.running
            ? 'Hələ sorğu gəlməyib'
            : 'Server başladılmayıb',
      );
    }

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: <Widget>[
              Text(
                '${logs.length} sorğu',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  _controller.clearLogs();
                  setState(() {});
                },
                icon: const Icon(
                  Icons.delete_sweep_outlined,
                  size: 16,
                  color: _danger,
                ),
                label: const Text(
                  'Təmizlə',
                  style: TextStyle(color: _danger, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: logs.length,
            itemBuilder: (BuildContext context, int i) {
              final ServerLogEntry e = logs[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _GlassCard(
                  padding: const EdgeInsets.all(10),
                  radius: 12,
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _methodColor(e.method).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          e.method,
                          style: TextStyle(
                            color: _methodColor(e.method),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              e.query == null || e.query!.isEmpty
                                  ? e.path
                                  : '${e.path}?${e.query}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatTime(e.timestamp),
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            '${e.statusCode}',
                            style: TextStyle(
                              color: _statusColor(e.statusCode),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Text(
                            '${e.durationMs} ms',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }

  Color _methodColor(String m) {
    switch (m.toUpperCase()) {
      case 'GET':
        return _success;
      case 'POST':
        return _warning;
      case 'PUT':
        return _info;
      case 'PATCH':
        return _accentA;
      case 'DELETE':
        return _danger;
      default:
        return Colors.white60;
    }
  }

  Color _statusColor(int code) {
    if (code >= 200 && code < 300) return _success;
    if (code >= 300 && code < 400) return _info;
    if (code >= 400 && code < 500) return _warning;
    if (code >= 500) return _danger;
    return Colors.white54;
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 48, color: Colors.white.withOpacity(0.25)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: (bool v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _primaryButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: onTap == null ? 0.5 : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[color.withOpacity(0.9), color],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
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

  Widget _miniIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: Colors.white70),
        ),
      ),
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: ClipRRect(
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