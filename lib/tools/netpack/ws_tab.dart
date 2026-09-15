import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'ui_kit.dart';
import 'ws_engine.dart';

class WsTab extends StatefulWidget {
  const WsTab({super.key});

  @override
  State<WsTab> createState() => _WsTabState();
}

class _WsTabState extends State<WsTab> {
  final WsConfig _config = WsConfig();

  final TextEditingController _urlCtrl = TextEditingController();
  final TextEditingController _messageCtrl = TextEditingController();
  final TextEditingController _subprotocolsCtrl = TextEditingController();
  final TextEditingController _headersCtrl = TextEditingController();
  final ScrollController _logScroll = ScrollController();

  WsSession? _session;
  WsState _state = WsState.idle;
  final List<WsMessage> _messages = <WsMessage>[];
  String? _errorKey;
  String? _errorDetail;
  bool _showConfig = false;
  bool _autoScroll = true;
  bool _copiedLog = false;

  @override
  void initState() {
    super.initState();
    _urlCtrl.text = 'wss://echo.websocket.events';
    _createSession();
  }

  @override
  void dispose() {
    _session?.dispose();
    _urlCtrl.dispose();
    _messageCtrl.dispose();
    _subprotocolsCtrl.dispose();
    _headersCtrl.dispose();
    _logScroll.dispose();
    super.dispose();
  }

  void _createSession() {
    _session?.dispose();
    _session = WsSession(
      onState: (WsState s) {
        if (!mounted) return;
        setState(() => _state = s);
        if (s == WsState.connected) {
          _appendSystem('Connected to ${_urlCtrl.text.trim()}');
        } else if (s == WsState.closed) {
          _appendSystem('Connection closed');
        } else if (s == WsState.error) {
          _appendSystem('Connection error');
        }
      },
      onMessage: (WsMessage m) {
        if (!mounted) return;
        setState(() {
          _messages.add(m);
          if (_messages.length > _config.maxMessages) {
            _messages.removeRange(
              0,
              _messages.length - _config.maxMessages,
            );
          }
        });
        _scheduleAutoScroll();
      },
      onError: (WsException e) {
        if (!mounted) return;
        setState(() {
          _errorKey = e.errorKey;
          _errorDetail = e.detail;
        });
      },
    );
  }

  void _appendSystem(String text) {
    if (!mounted) return;
    setState(() {
      _messages.add(WsMessage(
        direction: WsMessageDirection.system,
        payload: text,
        timestamp: DateTime.now(),
        sizeBytes: 0,
      ));
    });
    _scheduleAutoScroll();
  }

  void _scheduleAutoScroll() {
    if (!_autoScroll) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_logScroll.hasClients) return;
      _logScroll.animateTo(
        _logScroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _connect() async {
    final String url = _urlCtrl.text.trim();
    if (url.isEmpty) {
      setState(() {
        _errorKey = NetErrors.wsEmptyUrl;
        _errorDetail = null;
      });
      return;
    }

    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();

    setState(() {
      _errorKey = null;
      _errorDetail = null;
      _messages.clear();
    });

    _createSession();

    try {
      final List<String> protocols = _subprotocolsCtrl.text
          .split(RegExp(r'[,\s]+'))
          .map((String s) => s.trim())
          .where((String s) => s.isNotEmpty)
          .toList();

      final Map<String, String> headers = WsSession.parseHeaders(
        _headersCtrl.text,
      );

      await _session!.connect(
        url: url,
        subprotocols: protocols,
        headers: headers,
      );
      HapticFeedback.lightImpact();
    } on WsException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorKey = e.errorKey;
        _errorDetail = e.detail;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorKey = NetErrors.wsConnectFailed;
        _errorDetail = e.toString();
      });
    }
  }

  Future<void> _disconnect() async {
    HapticFeedback.selectionClick();
    try {
      await _session?.close();
    } catch (_) {}
  }

  void _sendMessage() {
    final String text = _messageCtrl.text;
    if (text.trim().isEmpty) {
      setState(() {
        _errorKey = NetErrors.wsInvalidPayload;
        _errorDetail = 'Message is empty';
      });
      return;
    }

    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();

    try {
      _session!.sendFormatted(text, _config.sendFormat);
      _messageCtrl.clear();
      setState(() {
        _errorKey = null;
        _errorDetail = null;
      });
    } on WsException catch (e) {
      setState(() {
        _errorKey = e.errorKey;
        _errorDetail = e.detail;
      });
    } catch (e) {
      setState(() {
        _errorKey = NetErrors.wsSendFailed;
        _errorDetail = e.toString();
      });
    }
  }

  void _clearLog() {
    HapticFeedback.mediumImpact();
    setState(() {
      _messages.clear();
      _errorKey = null;
      _errorDetail = null;
    });
  }

  void _toggleAutoScroll() {
    HapticFeedback.selectionClick();
    setState(() => _autoScroll = !_autoScroll);
    if (_autoScroll) _scheduleAutoScroll();
  }

  Future<void> _copyLog() async {
    if (_messages.isEmpty) return;
    final String log = WsSession.messagesToLog(_messages);
    await netCopy(context, log);
    if (!mounted) return;
    setState(() => _copiedLog = true);
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _copiedLog = false);
    });
  }

  Future<void> _copyLogJson() async {
    if (_messages.isEmpty) return;
    final String json = WsSession.messagesToJson(_messages);
    await netCopy(context, json);
  }

  Future<void> _pasteUrl() async {
    final ClipboardData? c = await Clipboard.getData(Clipboard.kTextPlain);
    if (c == null || c.text == null) return;
    HapticFeedback.selectionClick();
    _urlCtrl.text = c.text!;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildConnectionCard(),
          const SizedBox(height: 14),
          _buildConfigCard(),
          if (_state == WsState.connected) ...<Widget>[
            const SizedBox(height: 14),
            _buildSendCard(),
          ],
          if (_errorKey != null) ...<Widget>[
            const SizedBox(height: 14),
            NetErrorBox(errorKey: _errorKey!, detail: _errorDetail),
          ],
          const SizedBox(height: 14),
          _buildLogCard(),
        ],
      ),
    );
  }

  Widget _buildConnectionCard() {
    return NetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: NetSectionTitle(
                  Icons.bolt_rounded,
                  netTr(context, 'net_ws_connection', 'Connection'),
                ),
              ),
              _buildStatePill(),
            ],
          ),
          const SizedBox(height: 12),
          NetTextField(
            controller: _urlCtrl,
            hint: 'wss://echo.websocket.events',
            label: netTr(context, 'net_ws_url', 'WebSocket URL'),
            onSubmitted: (_) =>
            _state == WsState.connected ? _disconnect() : _connect(),
            suffixIcon: IconButton(
              icon: const Icon(
                Icons.content_paste_rounded,
                size: 18,
                color: Colors.white54,
              ),
              onPressed: _pasteUrl,
            ),
          ),
          const SizedBox(height: 12),
          if (_state == WsState.connected)
            _buildDisconnectButton()
          else
            _buildConnectButton(),
          const SizedBox(height: 8),
          Text(
            netTr(
              context,
              'net_ws_hint',
              'Use wss:// for encrypted connections. ws:// works only on local/trusted networks.',
            ),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatePill() {
    return NetStatusPill(
      label: _state.display,
      color: _state.color,
      icon: _state == WsState.connected
          ? Icons.check_circle_rounded
          : (_state == WsState.connecting
          ? Icons.sync_rounded
          : (_state == WsState.error
          ? Icons.error_outline
          : Icons.circle_outlined)),
    );
  }

  Widget _buildConnectButton() {
    final bool connecting = _state == WsState.connecting;
    return NetPrimaryButton(
      icon: connecting
          ? Icons.hourglass_top_rounded
          : Icons.link_rounded,
      label: connecting
          ? netTr(context, 'net_ws_connecting', 'Connecting…')
          : netTr(context, 'net_ws_connect', 'Connect'),
      onTap: connecting ? null : _connect,
    );
  }

  Widget _buildDisconnectButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: NetColors.danger.withOpacity(0.18),
        child: InkWell(
          onTap: _disconnect,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: NetColors.danger.withOpacity(0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(
                  Icons.link_off_rounded,
                  color: NetColors.danger,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  netTr(context, 'net_ws_disconnect', 'Disconnect'),
                  style: const TextStyle(
                    color: NetColors.danger,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfigCard() {
    return NetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GestureDetector(
            onTap: () => setState(() => _showConfig = !_showConfig),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: NetSectionTitle(
                    Icons.tune_rounded,
                    netTr(
                      context,
                      'net_ws_config',
                      'Connection options',
                    ),
                  ),
                ),
                Icon(
                  _showConfig
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: Colors.white60,
                  size: 20,
                ),
              ],
            ),
          ),
          if (_showConfig) ...<Widget>[
            const SizedBox(height: 12),
            NetTextField(
              controller: _subprotocolsCtrl,
              hint: 'chat, graphql-ws',
              label: netTr(
                context,
                'net_ws_subprotocols',
                'Subprotocols (comma separated)',
              ),
            ),
            const SizedBox(height: 10),
            NetTextField(
              controller: _headersCtrl,
              hint: 'Authorization: Bearer ...\nX-Custom: value',
              label: netTr(
                context,
                'net_ws_headers',
                'Custom headers (one per line)',
              ),
              maxLines: 4,
              minLines: 2,
            ),
            const SizedBox(height: 10),
            NetSwitchRow(
              label: netTr(
                context,
                'net_ws_auto_scroll',
                'Auto-scroll message log',
              ),
              value: _autoScroll,
              onChanged: (bool v) {
                setState(() => _autoScroll = v);
                if (v) _scheduleAutoScroll();
              },
            ),
            const SizedBox(height: 6),
            NetChipPicker<WsPayloadFormat>(
              label: netTr(
                context,
                'net_ws_send_format',
                'Send payload as',
              ),
              values: WsPayloadFormat.values,
              current: _config.sendFormat,
              labelOf: (WsPayloadFormat v) => v.name.toUpperCase(),
              onChanged: (WsPayloadFormat v) =>
                  setState(() => _config.sendFormat = v),
              scrollable: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSendCard() {
    return NetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: NetSectionTitle(
                  Icons.send_rounded,
                  netTr(context, 'net_ws_send', 'Send message'),
                ),
              ),
              NetStatusPill(
                label: _config.sendFormat.name.toUpperCase(),
                color: NetColors.accentB,
              ),
            ],
          ),
          const SizedBox(height: 12),
          NetTextField(
            controller: _messageCtrl,
            hint: _sendHintFor(_config.sendFormat),
            maxLines: 4,
            minLines: 2,
          ),
          const SizedBox(height: 12),
          NetPrimaryButton(
            icon: Icons.send_rounded,
            label: netTr(context, 'net_ws_send_action', 'Send'),
            onTap: _sendMessage,
          ),
        ],
      ),
    );
  }

  String _sendHintFor(WsPayloadFormat format) {
    switch (format) {
      case WsPayloadFormat.text:
        return '{"type":"ping"}';
      case WsPayloadFormat.hex:
        return '48 65 6c 6c 6f';
      case WsPayloadFormat.base64:
        return 'SGVsbG8gd29ybGQ=';
    }
  }

  Widget _buildLogCard() {
    return NetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: NetSectionTitle(
                  Icons.article_outlined,
                  netTr(context, 'net_ws_log', 'Message log'),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: NetColors.accentB.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_messages.length}',
                  style: const TextStyle(
                    color: NetColors.accentB,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 6),
              NetIconButton(
                icon: _autoScroll
                    ? Icons.vertical_align_bottom_rounded
                    : Icons.vertical_align_center_rounded,
                tooltip: netTr(
                  context,
                  'net_ws_auto_scroll_short',
                  'Auto-scroll',
                ),
                onTap: _toggleAutoScroll,
                highlighted: _autoScroll,
              ),
              const SizedBox(width: 4),
              NetIconButton(
                icon: _copiedLog
                    ? Icons.check_rounded
                    : Icons.copy_rounded,
                tooltip: netTr(context, 'net_copy', 'Copy'),
                onTap: _copyLog,
                highlighted: _copiedLog,
              ),
              const SizedBox(width: 4),
              NetIconButton(
                icon: Icons.data_object_rounded,
                tooltip: netTr(context, 'net_ws_copy_json', 'Copy as JSON'),
                onTap: _copyLogJson,
              ),
              const SizedBox(width: 4),
              NetIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: netTr(context, 'net_clear', 'Clear'),
                onTap: _messages.isEmpty ? null : _clearLog,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(minHeight: 200, maxHeight: 400),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: _messages.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 36,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      netTr(
                        context,
                        'net_ws_log_empty',
                        'No messages yet. Connect and send something.',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
                : Scrollbar(
              controller: _logScroll,
              thumbVisibility: true,
              child: ListView.builder(
                controller: _logScroll,
                padding: const EdgeInsets.all(10),
                itemCount: _messages.length,
                itemBuilder: (BuildContext context, int i) {
                  return _messageRow(_messages[i]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageRow(WsMessage m) {
    Color color;
    IconData icon;
    String prefix;

    switch (m.direction) {
      case WsMessageDirection.incoming:
        color = NetColors.success;
        icon = Icons.arrow_downward_rounded;
        prefix = '<<';
        break;
      case WsMessageDirection.outgoing:
        color = NetColors.accentA;
        icon = Icons.arrow_upward_rounded;
        prefix = '>>';
        break;
      case WsMessageDirection.system:
        color = Colors.white54;
        icon = Icons.circle;
        prefix = '··';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              icon,
              size: m.direction == WsMessageDirection.system ? 6 : 14,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      m.timeLabel,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      prefix,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (m.sizeBytes > 0) ...<Widget>[
                      const SizedBox(width: 8),
                      Text(
                        '${m.sizeBytes} B',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 9,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                SelectableText(
                  m.payload,
                  style: TextStyle(
                    color: m.direction == WsMessageDirection.system
                        ? Colors.white54
                        : Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 11,
                    height: 1.4,
                    fontStyle: m.direction == WsMessageDirection.system
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}