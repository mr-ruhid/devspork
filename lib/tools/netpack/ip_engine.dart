import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class IpException implements Exception {
  IpException(this.errorKey, [this.detail]);

  final String errorKey;
  final String? detail;

  @override
  String toString() => detail == null ? errorKey : '$errorKey: $detail';
}

class IpEngine {
  IpEngine._();

  static const String _endpoint = 'https://ipwho.is';

  // ==========================================================================
  // LOOKUP
  // ==========================================================================

  static Future<IpInfo> lookupOwn({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    return _fetch('$_endpoint/', timeout: timeout);
  }

  static Future<IpInfo> lookupIp(
      String ip, {
        Duration timeout = const Duration(seconds: 12),
      }) async {
    final String cleaned = ip.trim();
    if (cleaned.isEmpty) {
      throw IpException(NetErrors.ipEmpty);
    }
    if (!isValidIp(cleaned)) {
      throw IpException(
        NetErrors.ipInvalid,
        '"$cleaned" is not a valid IP address',
      );
    }
    return _fetch('$_endpoint/$cleaned', timeout: timeout);
  }

  static Future<IpInfo> _fetch(
      String url, {
        required Duration timeout,
      }) async {
    http.Response response;
    try {
      response = await http.get(
        Uri.parse(url),
        headers: <String, String>{
          'User-Agent': 'MiniTools-NetPack/1.0',
          'Accept': 'application/json',
        },
      ).timeout(timeout);
    } on http.ClientException catch (e) {
      throw IpException(NetErrors.ipOffline, e.message);
    } on TimeoutException {
      throw IpException(NetErrors.ipTimeout);
    } catch (e) {
      final String msg = e.toString().toLowerCase();
      if (msg.contains('socketexception') ||
          msg.contains('failed host lookup') ||
          msg.contains('network')) {
        throw IpException(NetErrors.ipOffline, e.toString());
      }
      throw IpException(NetErrors.ipServerError, e.toString());
    }

    if (response.statusCode != 200) {
      throw IpException(
        NetErrors.ipServerError,
        'HTTP ${response.statusCode}',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw IpException(NetErrors.ipServerError, 'Invalid JSON response');
    }

    if (decoded is! Map) {
      throw IpException(NetErrors.ipServerError, 'Unexpected response shape');
    }

    final bool success = decoded['success'] != false;
    if (!success) {
      final String msg = (decoded['message'] ?? 'Lookup failed').toString();
      throw IpException(NetErrors.ipServerError, msg);
    }

    final String ip = (decoded['ip'] ?? '').toString();
    if (ip.isEmpty) {
      throw IpException(NetErrors.ipInvalid, 'No IP in response');
    }

    return IpInfo(
      ip: ip,
      version: ip.contains(':') ? IpVersion.v6 : IpVersion.v4,
      country: _strOrNull(decoded['country']),
      countryCode: _strOrNull(decoded['country_code']),
      region: _strOrNull(decoded['region']),
      city: _strOrNull(decoded['city']),
      postal: _strOrNull(decoded['postal']),
      latitude: _doubleOrNull(decoded['latitude']),
      longitude: _doubleOrNull(decoded['longitude']),
      timezone: _extractTimezone(decoded),
      isp: _extractConnectionField(decoded, 'isp'),
      org: _extractConnectionField(decoded, 'org'),
      asn: _extractAsn(decoded),
      source: 'ipwho.is',
    );
  }

  static String? _extractTimezone(dynamic decoded) {
    if (decoded is! Map) return null;
    final dynamic tz = decoded['timezone'];
    if (tz is Map) {
      return _strOrNull(tz['id']);
    }
    if (tz is String) return tz;
    return null;
  }

  static String? _extractConnectionField(dynamic decoded, String key) {
    if (decoded is! Map) return null;
    final dynamic conn = decoded['connection'];
    if (conn is Map) {
      return _strOrNull(conn[key]);
    }
    return _strOrNull(decoded[key]);
  }

  static String? _extractAsn(dynamic decoded) {
    if (decoded is! Map) return null;
    final dynamic conn = decoded['connection'];
    if (conn is Map) {
      final dynamic asn = conn['asn'];
      if (asn == null) return null;
      return asn.toString();
    }
    return null;
  }

  static String? _strOrNull(dynamic v) {
    if (v == null) return null;
    final String s = v.toString().trim();
    if (s.isEmpty || s == 'null') return null;
    return s;
  }

  static double? _doubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  // ==========================================================================
  // IP VALIDATION
  // ==========================================================================

  static bool isValidIp(String value) {
    final String t = value.trim();
    if (t.isEmpty) return false;
    if (t.contains(':')) return isValidIpv6(t);
    return isValidIpv4(t);
  }

  static bool isValidIpv4(String value) {
    final String t = value.trim();
    final List<String> parts = t.split('.');
    if (parts.length != 4) return false;
    for (final String p in parts) {
      if (p.isEmpty) return false;
      if (!RegExp(r'^\d+$').hasMatch(p)) return false;
      if (p.length > 1 && p.startsWith('0')) return false;
      final int? n = int.tryParse(p);
      if (n == null || n < 0 || n > 255) return false;
    }
    return true;
  }

  static bool isValidIpv6(String value) {
    String t = value.trim().toLowerCase();
    if (t.isEmpty) return false;
    if (!RegExp(r'^[0-9a-f:.]+$').hasMatch(t)) return false;

    if (t == '::') return true;

    final int doubleColonCount = '::'.allMatches(t).length;
    if (doubleColonCount > 1) return false;

    final List<String> groups = t.split(':');

    int nonEmpty = 0;
    for (final String g in groups) {
      if (g.isEmpty) continue;
      if (!RegExp(r'^[0-9a-f]{1,4}$').hasMatch(g)) return false;
      nonEmpty++;
    }

    if (doubleColonCount == 1) {
      return nonEmpty <= 7;
    }
    return nonEmpty == 8;
  }

  static bool isPrivateIp(String value) {
    final String t = value.trim();
    if (isValidIpv4(t)) {
      final List<String> parts = t.split('.');
      final int a = int.parse(parts[0]);
      final int b = int.parse(parts[1]);
      if (a == 10) return true;
      if (a == 172 && b >= 16 && b <= 31) return true;
      if (a == 192 && b == 168) return true;
      if (a == 127) return true;
      if (a == 169 && b == 254) return true;
      return false;
    }
    if (isValidIpv6(t)) {
      final String lower = t.toLowerCase();
      if (lower == '::1') return true;
      if (lower.startsWith('fc') || lower.startsWith('fd')) return true;
      if (lower.startsWith('fe80')) return true;
      return false;
    }
    return false;
  }

  static String ipv4Class(String value) {
    if (!isValidIpv4(value)) return '—';
    final int first = int.parse(value.split('.').first);
    if (first == 0) return 'Reserved (0.0.0.0/8)';
    if (first <= 127) return 'A';
    if (first <= 191) return 'B';
    if (first <= 223) return 'C';
    if (first <= 239) return 'D (Multicast)';
    if (first <= 255) return 'E (Reserved)';
    return '—';
  }

  // ==========================================================================
  // IPV4 <-> INTEGER
  // ==========================================================================

  static int ipv4ToInt(String ip) {
    if (!isValidIpv4(ip)) {
      throw IpException(NetErrors.ipInvalid, '"$ip" is not a valid IPv4');
    }
    final List<String> parts = ip.split('.');
    int result = 0;
    for (final String p in parts) {
      result = (result << 8) | int.parse(p);
    }
    return result;
  }

  static String intToIpv4(int value) {
    return <int>[
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    ].join('.');
  }

  // ==========================================================================
  // CIDR / SUBNET
  // ==========================================================================

  static SubnetInfo parseCidr(String cidr) {
    final String t = cidr.trim();
    if (t.isEmpty) {
      throw IpException(NetErrors.ipEmpty);
    }

    final int slash = t.indexOf('/');
    if (slash < 0) {
      throw IpException(
        NetErrors.ipInvalidCidr,
        'CIDR must include a prefix (e.g. 192.168.1.0/24)',
      );
    }

    final String ipPart = t.substring(0, slash).trim();
    final String prefixPart = t.substring(slash + 1).trim();

    if (!isValidIpv4(ipPart)) {
      throw IpException(
        NetErrors.ipInvalidCidr,
        'Base IP must be IPv4 (IPv6 CIDR not supported yet)',
      );
    }

    final int? prefix = int.tryParse(prefixPart);
    if (prefix == null || prefix < 0 || prefix > 32) {
      throw IpException(
        NetErrors.ipPrefixRange,
        'Prefix must be between 0 and 32',
      );
    }

    final int ipInt = ipv4ToInt(ipPart);
    final int mask = prefix == 0 ? 0 : (0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF;
    final int networkInt = ipInt & mask;
    final int broadcastInt = networkInt | (~mask & 0xFFFFFFFF);
    final int wildcardMask = ~mask & 0xFFFFFFFF;

    final int total = 1 << (32 - prefix);
    final int usable = prefix >= 31
        ? (prefix == 32 ? 1 : 2)
        : total - 2;

    final String firstHost;
    final String lastHost;
    if (prefix == 32) {
      firstHost = intToIpv4(networkInt);
      lastHost = intToIpv4(networkInt);
    } else if (prefix == 31) {
      firstHost = intToIpv4(networkInt);
      lastHost = intToIpv4(broadcastInt);
    } else {
      firstHost = intToIpv4(networkInt + 1);
      lastHost = intToIpv4(broadcastInt - 1);
    }

    return SubnetInfo(
      cidr: '$ipPart/$prefix',
      networkAddress: intToIpv4(networkInt),
      broadcastAddress: intToIpv4(broadcastInt),
      firstHost: firstHost,
      lastHost: lastHost,
      subnetMask: intToIpv4(mask),
      wildcardMask: intToIpv4(wildcardMask),
      prefixLength: prefix,
      totalHosts: total,
      usableHosts: usable,
      ipClass: ipv4Class(ipPart),
      isPrivate: isPrivateIp(ipPart),
      intAddress: ipInt,
      networkInt: networkInt,
      broadcastInt: broadcastInt,
    );
  }

  static IpMembershipResult checkMembership({
    required String ip,
    required String cidr,
  }) {
    final String ipClean = ip.trim();
    if (!isValidIpv4(ipClean)) {
      throw IpException(
        NetErrors.ipInvalid,
        '"$ipClean" is not a valid IPv4',
      );
    }

    final SubnetInfo subnet = parseCidr(cidr);
    final int ipInt = ipv4ToInt(ipClean);
    final bool contains =
        ipInt >= subnet.networkInt && ipInt <= subnet.broadcastInt;

    String? reason;
    if (contains) {
      if (ipInt == subnet.networkInt) {
        reason = 'network address';
      } else if (ipInt == subnet.broadcastInt && subnet.prefixLength < 31) {
        reason = 'broadcast address';
      }
    }

    return IpMembershipResult(
      ip: ipClean,
      cidr: subnet.cidr,
      contains: contains,
      reason: reason,
    );
  }

  // ==========================================================================
  // HELPERS
  // ==========================================================================

  static String formatIntegerWithSeparators(int value) {
    final String s = value.toString();
    final StringBuffer b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  static String ipv4ToBinary(String ip) {
    if (!isValidIpv4(ip)) return '';
    final List<String> parts = ip.split('.');
    return parts
        .map((String p) =>
        int.parse(p).toRadixString(2).padLeft(8, '0'))
        .join('.');
  }

  static String ipv4ToHex(String ip) {
    if (!isValidIpv4(ip)) return '';
    final int n = ipv4ToInt(ip);
    return '0x${n.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  static String formatInteger(int value) {
    if (value < 0) return '—';
    return value.toString();
  }
}