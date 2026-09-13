import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/app_localization.dart';
import 'history_store.dart';
import 'models.dart';
import 'request_handler.dart';

const Color _accentA = Color(0xFF7C4DFF);
const Color _accentB = Color(0xFF00E5FF);
const Color _danger = Color(0xFFFF5C5C);
const Color _warning = Color(0xFFFFC24B);
const Color _success = Color(0xFF4BD68B);
const Color _info = Color(0xFF4B9BFF);
const Color _bgTop = Color(0xFF1B1035);
const Color _bgMid = Color(0xFF2A1550);
const Color _bgBot = Color(0xFF0F2A4A);

class ApiBuilder extends StatefulWidget {
  const ApiBuilder({super.key});

  @override
  State<ApiBuilder> createState() => _ApiBuilderState();
}

class _ApiBuilderState extends State<ApiBuilder>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final ApiRequest _request = ApiRequest(
    headers: <HeaderPair>[HeaderPair()],
  );
  final TextEditingController _urlCtrl = TextEditingController();
  final TextEditingController _bodyCtrl = TextEditingController();
  final List<TextEditingController> _headerKeyCtrls =
  <TextEditingController>[];
  final List<TextEditingController> _headerValueCtrls =
  <TextEditingController>[];

  ApiResponse? _response;
  bool _loading = false;
  List<HistoryEntry> _history = <HistoryEntry>[];
  List<SavedRequest> _saved = <SavedRequest>[];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _attachHeaderControllers();
    _loadStores();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlCtrl.dispose();
    _bodyCtrl.dispose();
    for (final TextEditingController c in _headerKeyCtrls) {
      c.dispose();
    }
    for (final TextEditingController c in _headerValueCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  bool _canHaveBody(ApiRequest r) =>
      r.method != HttpMethod.get && r.method != HttpMethod.head;

  String _bodyTypeLabel(BodyType t) {
    switch (t) {
      case BodyType.none:
        return 'None';
      case BodyType.json:
        return 'JSON';
      case BodyType.formUrlEncoded:
        return 'Form';
      case BodyType.raw:
        return 'Raw';
    }
  }

  String _prettyDuration(int ms) {
    if (ms < 1000) return '$ms ms';
    return '${(ms / 1000).toStringAsFixed(2)} s';
  }

  String _prettySize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  bool _isJsonResponse(ApiResponse resp) {
    final String? ct = resp.headers['content-type'];
    if (ct != null && ct.toLowerCase().contains('json')) return true;
    final String trimmed = resp.body.trim();
    if (trimmed.isEmpty) return false;
    final String first = trimmed[0];
    if (first != '{' && first != '[') return false;
    try {
      jsonDecode(trimmed);
      return true;
    } catch (_) {
      return false;
    }
  }

  HeaderPair _cloneHeader(HeaderPair h) => HeaderPair(
    key: h.key,
    value: h.value,
    enabled: h.enabled,
  );

  Future<void> _loadStores() async {
    final List<HistoryEntry> h = await HistoryStore.load();
    final List<SavedRequest> s = await CollectionsStore.load();
    if (!mounted) return;
    setState(() {
      _history = h;
      _saved = s;
    });
  }

  void _attachHeaderControllers() {
    for (final HeaderPair h in _request.headers) {
      _headerKeyCtrls.add(TextEditingController(text: h.key));
      _headerValueCtrls.add(TextEditingController(text: h.value));
    }
  }

  void _disposeHeaderControllers() {
    for (final TextEditingController c in _headerKeyCtrls) {
      c.dispose();
    }
    for (final TextEditingController c in _headerValueCtrls) {
      c.dispose();
    }
    _headerKeyCtrls.clear();
    _headerValueCtrls.clear();
  }

  void _syncRequestFromUI() {
    _request.url = _urlCtrl.text.trim();
    _request.body = _bodyCtrl.text;
    for (int i = 0; i < _request.headers.length; i++) {
      if (i < _headerKeyCtrls.length) {
        _request.headers[i].key = _headerKeyCtrls[i].text;
      }
      if (i < _headerValueCtrls.length) {
        _request.headers[i].value = _headerValueCtrls[i].text;
      }
    }
  }

  void _loadRequestToUI(ApiRequest req) {
    setState(() {
      _request.method = req.method;
      _request.url = req.url;
      _request.bodyType = req.bodyType;
      _request.body = req.body;
      _urlCtrl.text = req.url;
      _bodyCtrl.text = req.body;

      _disposeHeaderControllers();
      _request.headers = req.headers.isEmpty
          ? <HeaderPair>[HeaderPair()]
          : req.headers.map(_cloneHeader).toList();
      _attachHeaderControllers();

      _response = null;
    });
  }

  void _addHeader() {
    setState(() {
      _request.headers.add(HeaderPair());
      _headerKeyCtrls.add(TextEditingController());
      _headerValueCtrls.add(TextEditingController());
    });
  }

  void _removeHeader(int index) {
    if (_request.headers.length <= 1) {
      setState(() {
        _request.headers[0] = HeaderPair();
        _headerKeyCtrls[0].clear();
        _headerValueCtrls[0].clear();
      });
      return;
    }
    setState(() {
      _request.headers.removeAt(index);
      _headerKeyCtrls.removeAt(index).dispose();
      _headerValueCtrls.removeAt(index).dispose();
    });
  }

  Future<void> _send() async {
    _syncRequestFromUI();
    if (_request.url.trim().isEmpty) {
      _showSnack(context.t('apibuilder_url_required'));
      return;
    }
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _response = null;
    });

    final ApiResponse resp = await RequestHandler.send(_request);

    final HistoryEntry entry = HistoryEntry(
      request: _request.copy(),
      statusCode: resp.statusCode,
      durationMs: resp.durationMs,
      timestamp: DateTime.now(),
    );
    await HistoryStore.add(entry);
    final List<HistoryEntry> h = await HistoryStore.load();

    if (!mounted) return;
    setState(() {
      _response = resp;
      _loading = false;
      _history = h;
    });
    _tabController.animateTo(1);
  }

  Future<void> _copy(String text) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    _showSnack(context.t('apibuilder_copied'));
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withOpacity(0.75),
        content: Text(message),
      ),
    );
  }

  Future<void> _exportCurl() async {
    _syncRequestFromUI();
    final String curl = CurlExporter.export(_request);
    await Clipboard.setData(ClipboardData(text: curl));
    if (!mounted) return;
    _showDialog(
      title: context.t('apibuilder_curl_export'),
      content: curl,
      onCopy: () => _copy(curl),
    );
  }

  Future<void> _importCurl() async {
    final TextEditingController ctrl = TextEditingController();
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => _glassInputDialog(
        ctx: ctx,
        title: context.t('apibuilder_curl_import'),
        hint: context.t('apibuilder_curl_paste'),
        controller: ctrl,
        confirmKey: 'apibuilder_import',
      ),
    );
    ctrl.dispose();
    if (result == null || result.trim().isEmpty) return;

    final ApiRequest? parsed = CurlParser.parse(result);
    if (parsed == null) {
      if (!mounted) return;
      _showSnack(context.t('apibuilder_curl_invalid'));
      return;
    }
    _loadRequestToUI(parsed);
    if (!mounted) return;
    _showSnack(context.t('apibuilder_curl_loaded'));
  }

  Future<void> _saveToCollection() async {
    _syncRequestFromUI();
    if (_request.url.trim().isEmpty) {
      _showSnack(context.t('apibuilder_url_required'));
      return;
    }
    final TextEditingController ctrl = TextEditingController(
      text: _request.url,
    );
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => _glassInputDialog(
        ctx: ctx,
        title: context.t('apibuilder_save_request'),
        hint: context.t('apibuilder_name_hint'),
        controller: ctrl,
        confirmKey: 'apibuilder_save',
      ),
    );
    ctrl.dispose();
    if (name == null || name.trim().isEmpty) return;

    await CollectionsStore.save(
      SavedRequest(name: name.trim(), request: _request.copy()),
    );
    final List<SavedRequest> s = await CollectionsStore.load();
    if (!mounted) return;
    setState(() => _saved = s);
    _showSnack(context.t('apibuilder_saved'));
  }

  Future<void> _clearAll() async {
    setState(() {
      _request.method = HttpMethod.get;
      _request.url = '';
      _request.bodyType = BodyType.none;
      _request.body = '';
      _urlCtrl.clear();
      _bodyCtrl.clear();
      _disposeHeaderControllers();
      _request.headers = <HeaderPair>[HeaderPair()];
      _attachHeaderControllers();
      _response = null;
    });
  }

  void _loadHistoryEntry(HistoryEntry entry) {
    _loadRequestToUI(entry.request);
  }

  Future<void> _deleteHistoryAt(int index) async {
    await HistoryStore.removeAt(index);
    final List<HistoryEntry> h = await HistoryStore.load();
    if (!mounted) return;
    setState(() => _history = h);
  }

  Future<void> _clearHistory() async {
    await HistoryStore.clear();
    final List<HistoryEntry> h = await HistoryStore.load();
    if (!mounted) return;
    setState(() => _history = h);
  }

  void _loadSaved(SavedRequest saved) {
    _loadRequestToUI(saved.request);
  }

  Future<void> _deleteSaved(String id) async {
    await CollectionsStore.remove(id);
    final List<SavedRequest> s = await CollectionsStore.load();
    if (!mounted) return;
    setState(() => _saved = s);
  }

  Color _methodColor(HttpMethod m) {
    switch (m) {
      case HttpMethod.get:
        return _success;
      case HttpMethod.post:
        return _warning;
      case HttpMethod.put:
        return _info;
      case HttpMethod.patch:
        return _accentA;
      case HttpMethod.delete:
        return _danger;
      case HttpMethod.head:
      case HttpMethod.options:
        return Colors.white60;
    }
  }

  Color _statusColor(int? code) {
    if (code == null) return Colors.white54;
    if (code >= 200 && code < 300) return _success;
    if (code >= 300 && code < 400) return _info;
    if (code >= 400 && code < 500) return _warning;
    if (code >= 500) return _danger;
    return Colors.white54;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.t('apibuilder_title')),
        actions: <Widget>[
          _glassIconButton(
            icon: Icons.download_rounded,
            tooltip: context.t('apibuilder_import'),
            onTap: _importCurl,
          ),
          _glassIconButton(
            icon: Icons.upload_rounded,
            tooltip: context.t('apibuilder_export'),
            onTap: _exportCurl,
          ),
          _glassIconButton(
            icon: Icons.bookmark_add_outlined,
            tooltip: context.t('apibuilder_save'),
            onTap: _saveToCollection,
          ),
          _glassIconButton(
            icon: Icons.cleaning_services_outlined,
            tooltip: context.t('apibuilder_clear'),
            onTap: _clearAll,
          ),
          const SizedBox(width: 8),
        ],
        bottom: _glassTabBar(),
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
            Positioned(top: -80, left: -60, child: _blurBlob(220, _accentA)),
            Positioned(
              bottom: -100,
              right: -60,
              child: _blurBlob(260, _accentB),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 60),
                child: TabBarView(
                  controller: _tabController,
                  children: <Widget>[
                    _buildRequestTab(),
                    _buildResponseTab(),
                    _buildHistoryTab(),
                    _buildSavedTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            tabs: <Widget>[
              Tab(text: context.t('apibuilder_tab_request')),
              Tab(text: context.t('apibuilder_tab_response')),
              Tab(text: context.t('apibuilder_tab_history')),
              Tab(text: context.t('apibuilder_tab_saved')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestTab() {
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
                    _methodDropdown(),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _glassTextField(
                        controller: _urlCtrl,
                        hint: context.t('apibuilder_url_hint'),
                        keyboardType: TextInputType.url,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _sendButton(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.list_alt_rounded,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.t('apibuilder_headers'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _addHeader,
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: _accentB,
                        size: 20,
                      ),
                      splashRadius: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._buildHeaderRows(),
              ],
            ),
          ),
          if (_canHaveBody(_request)) ...<Widget>[
            const SizedBox(height: 16),
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.code_rounded,
                        size: 16,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.t('apibuilder_body'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _bodyTypeSelector(),
                  const SizedBox(height: 10),
                  if (_request.bodyType != BodyType.none)
                    _glassTextField(
                      controller: _bodyCtrl,
                      hint: _bodyHint(),
                      maxLines: 10,
                      minLines: 4,
                      monospace: true,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _methodDropdown() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<HttpMethod>(
            value: _request.method,
            dropdownColor: const Color(0xFF2A1550),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white70,
              size: 18,
            ),
            style: TextStyle(
              color: _methodColor(_request.method),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            items: HttpMethod.values.map((HttpMethod m) {
              return DropdownMenuItem<HttpMethod>(
                value: m,
                child: Text(
                  m.value,
                  style: TextStyle(
                    color: _methodColor(m),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              );
            }).toList(),
            onChanged: (HttpMethod? m) {
              if (m == null) return;
              setState(() {
                _request.method = m;
                if (!_canHaveBody(_request)) {
                  _request.bodyType = BodyType.none;
                }
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _bodyTypeSelector() {
    final List<BodyType> types = <BodyType>[
      BodyType.none,
      BodyType.json,
      BodyType.formUrlEncoded,
      BodyType.raw,
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: types.map((BodyType t) {
        final bool selected = _request.bodyType == t;
        return GestureDetector(
          onTap: () => setState(() => _request.bodyType = t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(
                colors: <Color>[_accentA, _accentB],
              )
                  : null,
              color: selected ? null : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : Colors.white.withOpacity(0.15),
              ),
            ),
            child: Text(
              _bodyTypeLabel(t),
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _bodyHint() {
    switch (_request.bodyType) {
      case BodyType.json:
        return '{\n  "key": "value"\n}';
      case BodyType.formUrlEncoded:
        return 'key1=value1&key2=value2';
      case BodyType.raw:
        return context.t('apibuilder_body_hint');
      case BodyType.none:
        return '';
    }
  }

  List<Widget> _buildHeaderRows() {
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < _request.headers.length; i++) {
      final HeaderPair h = _request.headers[i];
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: <Widget>[
              GestureDetector(
                onTap: () => setState(() => h.enabled = !h.enabled),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: h.enabled
                        ? _accentB.withOpacity(0.25)
                        : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: h.enabled
                          ? _accentB
                          : Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: h.enabled
                      ? const Icon(Icons.check, size: 14, color: _accentB)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _glassTextField(
                  controller: _headerKeyCtrls[i],
                  hint: context.t('apibuilder_header_key'),
                  dense: true,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 3,
                child: _glassTextField(
                  controller: _headerValueCtrls[i],
                  hint: context.t('apibuilder_header_value'),
                  dense: true,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => _removeHeader(i),
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white54,
                  size: 18,
                ),
                splashRadius: 16,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      );
    }
    return rows;
  }

  Widget _sendButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _loading ? null : _send,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: _loading
                  ? LinearGradient(
                colors: <Color>[
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.1),
                ],
              )
                  : const LinearGradient(
                colors: <Color>[_accentA, _accentB],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (_loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                const SizedBox(width: 10),
                Text(
                  _loading
                      ? context.t('apibuilder_sending')
                      : context.t('apibuilder_send'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponseTab() {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(color: _accentB, strokeWidth: 2.5),
        ),
      );
    }
    final ApiResponse? resp = _response;
    if (resp == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.cloud_outlined,
                size: 48,
                color: Colors.white.withOpacity(0.25),
              ),
              const SizedBox(height: 12),
              Text(
                context.t('apibuilder_no_response'),
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      );
    }

    final Color statusColor = _statusColor(resp.statusCode);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _GlassCard(
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    resp.statusCode?.toString() ?? 'ERR',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    resp.error != null
                        ? context.t(resp.error!)
                        : (resp.statusMessage ?? ''),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _infoChip(
                  Icons.timer_outlined,
                  _prettyDuration(resp.durationMs),
                ),
                const SizedBox(width: 6),
                _infoChip(
                  Icons.data_usage_rounded,
                  _prettySize(resp.sizeBytes),
                ),
              ],
            ),
          ),
          if (resp.error != null && resp.statusMessage != null) ...<Widget>[
            const SizedBox(height: 12),
            _GlassCard(
              child: Text(
                resp.statusMessage!,
                style: const TextStyle(
                  color: Color(0xFFFFBFBF),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
          if (resp.body.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.article_outlined,
                        size: 16,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isJsonResponse(resp)
                            ? context.t('apibuilder_body_json')
                            : context.t('apibuilder_body_text'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      _glassIconButton(
                        icon: Icons.copy_rounded,
                        tooltip: context.t('apibuilder_copy'),
                        onTap: () => _copy(resp.prettyBody),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: SelectableText(
                      resp.prettyBody,
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
          ],
          if (resp.headers.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.tune_rounded,
                        size: 16,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.t('apibuilder_response_headers'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...resp.headers.entries.map(
                        (MapEntry<String, String> e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(
                            width: 130,
                            child: Text(
                              e.key,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: _accentB,
                              ),
                            ),
                          ),
                          Expanded(
                            child: SelectableText(
                              e.value,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: Colors.white60),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_history.isEmpty) {
      return _emptyState(
        icon: Icons.history_rounded,
        message: context.t('apibuilder_history_empty'),
      );
    }
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: <Widget>[
              Text(
                '${_history.length} ${context.t('apibuilder_items')}',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _clearHistory,
                icon: const Icon(
                  Icons.delete_sweep_outlined,
                  size: 16,
                  color: _danger,
                ),
                label: Text(
                  context.t('apibuilder_clear_all'),
                  style: const TextStyle(color: _danger, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: _history.length,
            itemBuilder: (BuildContext context, int i) {
              final HistoryEntry e = _history[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _GlassCard(
                  padding: const EdgeInsets.all(12),
                  radius: 14,
                  child: InkWell(
                    onTap: () => _loadHistoryEntry(e),
                    child: Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _methodColor(e.request.method)
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            e.request.method.value,
                            style: TextStyle(
                              color: _methodColor(e.request.method),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                e.request.url,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${e.statusCode ?? "ERR"} • ${e.durationMs} ms',
                                style: TextStyle(
                                  color: _statusColor(e.statusCode),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _deleteHistoryAt(i),
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Colors.white38,
                          ),
                          splashRadius: 14,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSavedTab() {
    if (_saved.isEmpty) {
      return _emptyState(
        icon: Icons.bookmark_outline_rounded,
        message: context.t('apibuilder_saved_empty'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _saved.length,
      itemBuilder: (BuildContext context, int i) {
        final SavedRequest s = _saved[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _GlassCard(
            padding: const EdgeInsets.all(12),
            radius: 14,
            child: InkWell(
              onTap: () => _loadSaved(s),
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _methodColor(s.request.method).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      s.request.method.value,
                      style: TextStyle(
                        color: _methodColor(s.request.method),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          s.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.request.url,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _deleteSaved(s.id),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Colors.white38,
                    ),
                    splashRadius: 14,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState({required IconData icon, required String message}) {
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

  Widget _glassTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int? maxLines = 1,
    int? minLines,
    bool dense = false,
    bool monospace = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: minLines,
      style: TextStyle(
        color: Colors.white,
        fontSize: dense ? 12 : 13,
        fontFamily: monospace ? 'monospace' : null,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.35),
          fontSize: dense ? 12 : 13,
        ),
        isDense: true,
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: dense ? 8 : 12,
        ),
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

  Widget _glassInputDialog({
    required BuildContext ctx,
    required String title,
    required String hint,
    required TextEditingController controller,
    required String confirmKey,
  }) {
    return Dialog(
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
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 14),
                _glassTextField(
                  controller: controller,
                  hint: hint,
                  maxLines: 6,
                  minLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(
                        context.t('apibuilder_cancel'),
                        style: const TextStyle(color: Colors.white60),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () =>
                          Navigator.of(ctx).pop(controller.text),
                      child: Text(
                        context.t(confirmKey),
                        style: const TextStyle(
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
    );
  }

  void _showDialog({
    required String title,
    required String content,
    required VoidCallback onCopy,
  }) {
    showDialog<void>(
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
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        content,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Colors.white,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(
                          context.t('apibuilder_cancel'),
                          style: const TextStyle(color: Colors.white60),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: onCopy,
                        child: Text(
                          context.t('apibuilder_copy'),
                          style: const TextStyle(
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