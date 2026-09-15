import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class DnsException implements Exception {
  DnsException(this.errorKey, [this.detail]);

  final String errorKey;
  final String? detail;

  @override
  String toString() => detail == null ? errorKey : '$errorKey: $detail';
}

class DnsEngine {
  DnsEngine._();

  static final RegExp _domainRegex = RegExp(
    r'^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)*'
    r'[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$',
  );

  static Future<DnsResult> lookup({
    required String domain,
    required DnsRecordType type,
    required DnsProvider provider,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final String cleaned = domain.trim().toLowerCase();
    if (cleaned.isEmpty) {
      throw DnsException(NetErrors.dnsEmptyDomain);
    }
    if (!_isValidDomain(cleaned)) {
      throw DnsException(
        NetErrors.dnsInvalidDomain,
        '"$cleaned" is not a valid domain',
      );
    }

    final Uri uri = Uri.parse(provider.endpoint).replace(
      queryParameters: <String, String>{
        'name': cleaned,
        'type': type.query,
      },
    );

    final Map<String, String> headers = <String, String>{
      'Accept': 'application/dns-json',
      'User-Agent': 'MiniTools-NetPack/1.0',
    };

    final Stopwatch sw = Stopwatch()..start();
    http.Response response;
    try {
      response = await http
          .get(uri, headers: headers)
          .timeout(timeout);
    } on http.ClientException catch (e) {
      throw DnsException(NetErrors.dnsOffline, e.message);
    } on TimeoutException {
      throw DnsException(NetErrors.dnsTimeout);
    } catch (e) {
      final String msg = e.toString().toLowerCase();
      if (msg.contains('socketexception') ||
          msg.contains('failed host lookup') ||
          msg.contains('network')) {
        throw DnsException(NetErrors.dnsOffline, e.toString());
      }
      throw DnsException(NetErrors.dnsServerError, e.toString());
    }
    sw.stop();

    if (response.statusCode != 200) {
      throw DnsException(
        NetErrors.dnsServerError,
        'HTTP ${response.statusCode}',
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (e) {
      throw DnsException(NetErrors.dnsServerError, 'Invalid JSON response');
    }

    if (decoded is! Map) {
      throw DnsException(NetErrors.dnsServerError, 'Unexpected response shape');
    }

    final int status = _asInt(decoded['Status']) ?? -1;
    final bool truncated = decoded['TC'] == true;
    final List<DnsAnswer> answers = _parseAnswers(decoded['Answer']);
    final List<DnsAnswer> authorities = _parseAnswers(decoded['Authority']);

    return DnsResult(
      domain: cleaned,
      recordType: type,
      provider: provider,
      answers: answers,
      authorities: authorities,
      status: status,
      statusName: _statusName(status),
      elapsedMs: sw.elapsedMilliseconds,
      truncated: truncated,
    );
  }

  static List<DnsAnswer> _parseAnswers(dynamic raw) {
    if (raw is! List) return const <DnsAnswer>[];
    final List<DnsAnswer> out = <DnsAnswer>[];
    for (final dynamic item in raw) {
      if (item is! Map) continue;
      final int typeCode = _asInt(item['type']) ?? 0;
      final String typeName = DnsRecordTypeX.typeNameFromCode(typeCode) ??
          'TYPE$typeCode';
      out.add(DnsAnswer(
        name: (item['name'] ?? '').toString(),
        typeCode: typeCode,
        typeName: typeName,
        ttl: _asInt(item['TTL']) ?? 0,
        data: (item['data'] ?? '').toString(),
      ));
    }
    return out;
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static bool _isValidDomain(String domain) {
    if (domain.length > 253) return false;
    if (domain.contains('..')) return false;
    if (domain.startsWith('.') || domain.endsWith('.')) {
      return _domainRegex.hasMatch(domain.replaceAll(RegExp(r'\.$'), ''));
    }
    return _domainRegex.hasMatch(domain);
  }

  static String _statusName(int status) {
    switch (status) {
      case 0:
        return 'NOERROR';
      case 1:
        return 'FORMERR';
      case 2:
        return 'SERVFAIL';
      case 3:
        return 'NXDOMAIN';
      case 4:
        return 'NOTIMP';
      case 5:
        return 'REFUSED';
      case 6:
        return 'YXDOMAIN';
      case 7:
        return 'YXRRSET';
      case 8:
        return 'NXRRSET';
      case 9:
        return 'NOTAUTH';
      case 10:
        return 'NOTZONE';
      default:
        return 'STATUS$status';
    }
  }

  static String formatTtl(int ttl) {
    if (ttl < 60) return '${ttl}s';
    if (ttl < 3600) return '${(ttl / 60).round()}m';
    if (ttl < 86400) return '${(ttl / 3600).toStringAsFixed(1)}h';
    return '${(ttl / 86400).toStringAsFixed(1)}d';
  }

  static String? extractPriority(String data) {
    final List<String> parts = data.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && int.tryParse(parts.first) != null) {
      return parts.first;
    }
    return null;
  }

  static String? extractMxHost(String data) {
    final List<String> parts = data.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && int.tryParse(parts.first) != null) {
      return parts.sublist(1).join(' ');
    }
    return null;
  }

  static String cleanTxtQuotes(String data) {
    String d = data.trim();
    if (d.startsWith('"') && d.endsWith('"') && d.length >= 2) {
      d = d.substring(1, d.length - 1);
    }
    return d.replaceAll('" "', '');
  }

  static List<String> parseSrv(String data) {
    final List<String> parts = data.trim().split(RegExp(r'\s+'));
    if (parts.length < 4) return <String>[];
    return parts;
  }

  static String summarizeAnswer(DnsAnswer a) {
    switch (a.typeName) {
      case 'TXT':
        return cleanTxtQuotes(a.data);
      case 'MX':
        final String? host = extractMxHost(a.data);
        return host == null ? a.data : host;
      default:
        return a.data;
    }
  }

  static Future<Map<DnsRecordType, DnsResult>> lookupAll({
    required String domain,
    required DnsProvider provider,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    const List<DnsRecordType> types = <DnsRecordType>[
      DnsRecordType.a,
      DnsRecordType.aaaa,
      DnsRecordType.cname,
      DnsRecordType.mx,
      DnsRecordType.ns,
      DnsRecordType.txt,
    ];

    final Map<DnsRecordType, DnsResult> out = <DnsRecordType, DnsResult>{};
    for (final DnsRecordType t in types) {
      try {
        final DnsResult r = await lookup(
          domain: domain,
          type: t,
          provider: provider,
          timeout: timeout,
        );
        out[t] = r;
      } catch (e) {
        out[t] = DnsResult(
          domain: domain,
          recordType: t,
          provider: provider,
          answers: const <DnsAnswer>[],
          authorities: const <DnsAnswer>[],
          status: -1,
          statusName: 'ERROR',
          elapsedMs: 0,
          truncated: false,
        );
      }
    }
    return out;
  }
}