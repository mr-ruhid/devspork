import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'models.dart';

class WsException implements Exception {
  WsException(this.errorKey, [this.detail]);

  final String errorKey;
  final String? detail;

  @override
  String toString() => detail == null ? errorKey : '$errorKey: $detail';
}

typedef WsStateCallback = void Function(WsState state);
typedef WsMessageCallback = void Function(WsMessage message);
typedef WsErrorCallback = void Function(WsException error);

class WsSession {
  WsSession({
    required this.onState,
    required this.onMessage,
    required this.onError,
  });

  final WsStateCallback onState;
  final WsMessageCallback onMessage;
  final WsErrorCallback onError;

  WebSocket? _socket;
  StreamSubscription<dynamic>? _sub;
  WsState _state = WsState.idle;
  bool _manualClose = false;

  WsState get state => _state;
  bool get isConnected => _state == WsState.connected;

  Future<void> connect({
    required String url,
    List<String> subprotocols = const <String>[],
    Map<String, String> headers = const <String, String>{},
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (_state == WsState.connected || _state == WsState.connecting) {
      throw WsException(
        NetErrors.wsConnectFailed,
        'Already connected or connecting',
      );
    }

    _manualClose = false;
    _emitState(WsState.connecting);

    try {
      final Uri uri = _parseWsUrl(url);

      final WebSocket socket = await WebSocket.connect(
        uri.toString(),
        protocols: subprotocols.isEmpty ? null : subprotocols,
        headers: headers.isEmpty ? null : headers,
      ).timeout(timeout);

      socket.pingInterval = const Duration(seconds: 20);

      _socket = socket;
      _emitState(WsState.connected);

      _sub = socket.listen(
            (dynamic data) => _handleIncoming(data),
        onError: (Object error) {
          _emitError(WsException(
            NetErrors.wsConnectFailed,
            error.toString(),
          ));
          _emitState(WsState.error);
        },
        onDone: () {
          final int? code = _socket?.closeCode;
          final String? reason = _socket?.closeReason;
          final String detail = (code != null)
              ? 'Closed (code: $code${reason != null && reason.isNotEmpty ? ', $reason' : ''})'
              : 'Connection closed';
          _emitMessage(WsMessage(
            direction: WsMessageDirection.system,
            payload: detail,
            timestamp: DateTime.now(),
            sizeBytes: 0,
          ));
          _emitState(_manualClose ? WsState.closed : WsState.closed);
          _cleanup();
        },
        cancelOnError: false,
      );
    } on WsException {
      rethrow;
    } on TimeoutException {
      _emitState(WsState.error);
      _cleanup();
      throw WsException(NetErrors.wsConnectFailed, 'Connection timed out');
    } on SocketException catch (e) {
      _emitState(WsState.error);
      _cleanup();
      throw WsException(NetErrors.wsConnectFailed, e.message);
    } catch (e) {
      _emitState(WsState.error);
      _cleanup();
      throw WsException(NetErrors.wsConnectFailed, e.toString());
    }
  }

  void _handleIncoming(dynamic data) {
    final DateTime now = DateTime.now();
    if (data is String) {
      _emitMessage(WsMessage(
        direction: WsMessageDirection.incoming,
        payload: data,
        timestamp: now,
        sizeBytes: utf8.encode(data).length,
      ));
      return;
    }
    if (data is List<int>) {
      final Uint8List bytes = Uint8List.fromList(data);
      _emitMessage(WsMessage(
        direction: WsMessageDirection.incoming,
        payload: _encodeBytes(bytes, WsPayloadFormat.text),
        timestamp: now,
        sizeBytes: bytes.length,
      ));
      return;
    }
    _emitMessage(WsMessage(
      direction: WsMessageDirection.incoming,
      payload: data.toString(),
      timestamp: now,
      sizeBytes: 0,
    ));
  }

  void sendText(String text) {
    final WebSocket? s = _socket;
    if (s == null || _state != WsState.connected) {
      throw WsException(NetErrors.wsNotConnected);
    }
    if (text.isEmpty) {
      throw WsException(NetErrors.wsInvalidPayload, 'Empty payload');
    }
    try {
      s.add(text);
      _emitMessage(WsMessage(
        direction: WsMessageDirection.outgoing,
        payload: text,
        timestamp: DateTime.now(),
        sizeBytes: utf8.encode(text).length,
      ));
    } catch (e) {
      throw WsException(NetErrors.wsSendFailed, e.toString());
    }
  }

  void sendBytes(Uint8List bytes) {
    final WebSocket? s = _socket;
    if (s == null || _state != WsState.connected) {
      throw WsException(NetErrors.wsNotConnected);
    }
    if (bytes.isEmpty) {
      throw WsException(NetErrors.wsInvalidPayload, 'Empty payload');
    }
    try {
      s.add(bytes);
      _emitMessage(WsMessage(
        direction: WsMessageDirection.outgoing,
        payload: _encodeBytes(bytes, WsPayloadFormat.text),
        timestamp: DateTime.now(),
        sizeBytes: bytes.length,
      ));
    } catch (e) {
      throw WsException(NetErrors.wsSendFailed, e.toString());
    }
  }

  void sendFormatted(String input, WsPayloadFormat format) {
    switch (format) {
      case WsPayloadFormat.text:
        sendText(input);
        break;
      case WsPayloadFormat.hex:
        sendBytes(_decodeHex(input));
        break;
      case WsPayloadFormat.base64:
        sendBytes(_decodeBase64(input));
        break;
    }
  }

  Future<void> close({int code = 1000, String reason = ''}) async {
    final WebSocket? s = _socket;
    if (s == null) {
      _emitState(WsState.closed);
      return;
    }
    _manualClose = true;
    _emitState(WsState.closing);
    try {
      await s.close(code, reason);
    } catch (_) {}
    _emitState(WsState.closed);
    _cleanup();
  }

  void _cleanup() {
    _sub?.cancel();
    _sub = null;
    _socket = null;
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    try {
      _socket?.close();
    } catch (_) {}
    _socket = null;
  }

  void _emitState(WsState s) {
    _state = s;
    onState(s);
  }

  void _emitMessage(WsMessage m) => onMessage(m);

  void _emitError(WsException e) => onError(e);

  // ==========================================================================
  // STATIC HELPERS
  // ==========================================================================

  static Uri _parseWsUrl(String raw) {
    final String t = raw.trim();
    if (t.isEmpty) {
      throw WsException(NetErrors.wsEmptyUrl);
    }

    Uri? uri = Uri.tryParse(t);
    if (uri == null) {
      throw WsException(NetErrors.wsInvalidUrl, 'Malformed URL');
    }

    if (!uri.hasScheme) {
      uri = Uri.tryParse('wss://$t');
      if (uri == null) {
        throw WsException(NetErrors.wsInvalidUrl, 'Malformed URL');
      }
    }

    final String scheme = uri.scheme.toLowerCase();
    if (scheme != 'ws' && scheme != 'wss') {
      throw WsException(
        NetErrors.wsInvalidUrl,
        'Only ws:// and wss:// schemes are supported',
      );
    }

    if (uri.host.isEmpty) {
      throw WsException(NetErrors.wsInvalidUrl, 'URL has no host');
    }

    return uri;
  }

  static String _encodeBytes(Uint8List bytes, WsPayloadFormat format) {
    switch (format) {
      case WsPayloadFormat.hex:
        return _bytesToHex(bytes);
      case WsPayloadFormat.base64:
        return base64Encode(bytes);
      case WsPayloadFormat.text:
        try {
          return utf8.decode(bytes);
        } catch (_) {
          return _bytesToHex(bytes);
        }
    }
  }

  static String _bytesToHex(Uint8List bytes) {
    return bytes
        .map((int b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  static Uint8List _decodeHex(String raw) {
    final String cleaned = raw.replaceAll(RegExp(r'[\s,:-]+'), '');
    if (cleaned.isEmpty) {
      throw WsException(NetErrors.wsInvalidPayload, 'Empty hex');
    }
    if (cleaned.length.isOdd) {
      throw WsException(
        NetErrors.wsInvalidPayload,
        'Hex length must be even',
      );
    }
    if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(cleaned)) {
      throw WsException(
        NetErrors.wsInvalidPayload,
        'Invalid hex characters',
      );
    }
    final Uint8List out = Uint8List(cleaned.length ~/ 2);
    for (int i = 0; i < out.length; i++) {
      out[i] = int.parse(cleaned.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }

  static Uint8List _decodeBase64(String raw) {
    final String cleaned = raw.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.isEmpty) {
      throw WsException(NetErrors.wsInvalidPayload, 'Empty base64');
    }
    try {
      return base64Decode(cleaned);
    } catch (_) {
      throw WsException(NetErrors.wsInvalidPayload, 'Invalid base64');
    }
  }

  static String parseSubprotocols(String raw) {
    return raw
        .split(RegExp(r'[,\s]+'))
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .join(',');
  }

  static Map<String, String> parseHeaders(String raw) {
    final Map<String, String> out = <String, String>{};
    final List<String> lines = const LineSplitter().convert(raw);
    for (final String line in lines) {
      final String l = line.trim();
      if (l.isEmpty) continue;
      final int colon = l.indexOf(':');
      if (colon <= 0) continue;
      final String key = l.substring(0, colon).trim();
      final String value = l.substring(colon + 1).trim();
      if (key.isEmpty || value.isEmpty) continue;
      out[key] = value;
    }
    return out;
  }

  static String headersToText(Map<String, String> headers) {
    final StringBuffer b = StringBuffer();
    headers.forEach((String k, String v) => b.writeln('$k: $v'));
    return b.toString().trimRight();
  }

  static String messagesToJson(List<WsMessage> messages) {
    final List<Map<String, dynamic>> out =
    messages.map((WsMessage m) => <String, dynamic>{
      'direction': m.direction.name,
      'timestamp': m.timestamp.toIso8601String(),
      'sizeBytes': m.sizeBytes,
      'isError': m.isError,
      'payload': m.payload,
    }).toList();
    return const JsonEncoder.withIndent('  ').convert(out);
  }

  static String messagesToLog(List<WsMessage> messages) {
    final StringBuffer b = StringBuffer();
    for (final WsMessage m in messages) {
      String prefix;
      switch (m.direction) {
        case WsMessageDirection.incoming:
          prefix = '<<';
          break;
        case WsMessageDirection.outgoing:
          prefix = '>>';
          break;
        case WsMessageDirection.system:
          prefix = '··';
          break;
      }
      b.writeln('[${m.timeLabel}] $prefix ${m.payload}');
    }
    return b.toString().trimRight();
  }
}