import 'package:flutter/material.dart';

// ============================================================================
// DNS
// ============================================================================

enum DnsProvider { google, cloudflare }

extension DnsProviderX on DnsProvider {
  String get display {
    switch (this) {
      case DnsProvider.google:
        return 'Google (8.8.8.8)';
      case DnsProvider.cloudflare:
        return 'Cloudflare (1.1.1.1)';
    }
  }

  String get endpoint {
    switch (this) {
      case DnsProvider.google:
        return 'https://dns.google/resolve';
      case DnsProvider.cloudflare:
        return 'https://cloudflare-dns.com/dns-query';
    }
  }
}

enum DnsRecordType { a, aaaa, cname, mx, ns, txt, soa, ptr, srv, caa, any }

extension DnsRecordTypeX on DnsRecordType {
  String get query {
    switch (this) {
      case DnsRecordType.a:
        return 'A';
      case DnsRecordType.aaaa:
        return 'AAAA';
      case DnsRecordType.cname:
        return 'CNAME';
      case DnsRecordType.mx:
        return 'MX';
      case DnsRecordType.ns:
        return 'NS';
      case DnsRecordType.txt:
        return 'TXT';
      case DnsRecordType.soa:
        return 'SOA';
      case DnsRecordType.ptr:
        return 'PTR';
      case DnsRecordType.srv:
        return 'SRV';
      case DnsRecordType.caa:
        return 'CAA';
      case DnsRecordType.any:
        return 'ANY';
    }
  }

  int get typeCode {
    switch (this) {
      case DnsRecordType.a:
        return 1;
      case DnsRecordType.ns:
        return 2;
      case DnsRecordType.cname:
        return 5;
      case DnsRecordType.soa:
        return 6;
      case DnsRecordType.ptr:
        return 12;
      case DnsRecordType.mx:
        return 15;
      case DnsRecordType.txt:
        return 16;
      case DnsRecordType.aaaa:
        return 28;
      case DnsRecordType.srv:
        return 33;
      case DnsRecordType.caa:
        return 257;
      case DnsRecordType.any:
        return 255;
    }
  }

  static String? typeNameFromCode(int code) {
    switch (code) {
      case 1:
        return 'A';
      case 2:
        return 'NS';
      case 5:
        return 'CNAME';
      case 6:
        return 'SOA';
      case 12:
        return 'PTR';
      case 15:
        return 'MX';
      case 16:
        return 'TXT';
      case 28:
        return 'AAAA';
      case 33:
        return 'SRV';
      case 257:
        return 'CAA';
      case 255:
        return 'ANY';
      default:
        return null;
    }
  }
}

class DnsAnswer {
  DnsAnswer({
    required this.name,
    required this.typeCode,
    required this.typeName,
    required this.ttl,
    required this.data,
  });

  final String name;
  final int typeCode;
  final String typeName;
  final int ttl;
  final String data;
}

class DnsResult {
  DnsResult({
    required this.domain,
    required this.recordType,
    required this.provider,
    required this.answers,
    required this.authorities,
    required this.status,
    required this.statusName,
    required this.elapsedMs,
    required this.truncated,
  });

  final String domain;
  final DnsRecordType recordType;
  final DnsProvider provider;
  final List<DnsAnswer> answers;
  final List<DnsAnswer> authorities;
  final int status;
  final String statusName;
  final int elapsedMs;
  final bool truncated;

  bool get isSuccess => status == 0;

  bool get isNxDomain => status == 3;

  bool get hasAnswers => answers.isNotEmpty;
}

// ============================================================================
// IP
// ============================================================================

enum IpVersion { v4, v6 }

extension IpVersionX on IpVersion {
  String get display {
    switch (this) {
      case IpVersion.v4:
        return 'IPv4';
      case IpVersion.v6:
        return 'IPv6';
    }
  }
}

class IpInfo {
  IpInfo({
    required this.ip,
    required this.version,
    this.country,
    this.countryCode,
    this.region,
    this.city,
    this.postal,
    this.latitude,
    this.longitude,
    this.timezone,
    this.isp,
    this.org,
    this.asn,
    this.source,
  });

  final String ip;
  final IpVersion version;
  final String? country;
  final String? countryCode;
  final String? region;
  final String? city;
  final String? postal;
  final double? latitude;
  final double? longitude;
  final String? timezone;
  final String? isp;
  final String? org;
  final String? asn;
  final String? source;

  bool get hasLocation => latitude != null && longitude != null;

  String? get mapUrl {
    if (!hasLocation) return null;
    return 'https://www.google.com/maps?q=$latitude,$longitude';
  }
}

class SubnetInfo {
  SubnetInfo({
    required this.cidr,
    required this.networkAddress,
    required this.broadcastAddress,
    required this.firstHost,
    required this.lastHost,
    required this.subnetMask,
    required this.wildcardMask,
    required this.prefixLength,
    required this.totalHosts,
    required this.usableHosts,
    required this.ipClass,
    required this.isPrivate,
    required this.intAddress,
    required this.networkInt,
    required this.broadcastInt,
  });

  final String cidr;
  final String networkAddress;
  final String broadcastAddress;
  final String firstHost;
  final String lastHost;
  final String subnetMask;
  final String wildcardMask;
  final int prefixLength;
  final int totalHosts;
  final int usableHosts;
  final String ipClass;
  final bool isPrivate;
  final int intAddress;
  final int networkInt;
  final int broadcastInt;
}

class IpMembershipResult {
  IpMembershipResult({
    required this.ip,
    required this.cidr,
    required this.contains,
    required this.reason,
  });

  final String ip;
  final String cidr;
  final bool contains;
  final String? reason;
}

// ============================================================================
// HTTP STATUS
// ============================================================================

class HttpStatusCode {
  const HttpStatusCode({
    required this.code,
    required this.title,
    required this.description,
    required this.category,
  });

  final int code;
  final String title;
  final String description;
  final HttpStatusCategory category;
}

enum HttpStatusCategory { informational, success, redirect, clientError, serverError }

extension HttpStatusCategoryX on HttpStatusCategory {
  String get display {
    switch (this) {
      case HttpStatusCategory.informational:
        return '1xx Informational';
      case HttpStatusCategory.success:
        return '2xx Success';
      case HttpStatusCategory.redirect:
        return '3xx Redirection';
      case HttpStatusCategory.clientError:
        return '4xx Client Error';
      case HttpStatusCategory.serverError:
        return '5xx Server Error';
    }
  }

  Color get color {
    switch (this) {
      case HttpStatusCategory.informational:
        return const Color(0xFF60A5FA);
      case HttpStatusCategory.success:
        return const Color(0xFF4BD68B);
      case HttpStatusCategory.redirect:
        return const Color(0xFFFFC24B);
      case HttpStatusCategory.clientError:
        return const Color(0xFFFF8C42);
      case HttpStatusCategory.serverError:
        return const Color(0xFFFF5C5C);
    }
  }
}

class HttpHeader {
  HttpHeader({required this.name, required this.value});

  final String name;
  final String value;
}

class HttpRedirectStep {
  HttpRedirectStep({
    required this.url,
    required this.statusCode,
    required this.location,
  });

  final String url;
  final int statusCode;
  final String? location;
}

class HttpProbeResult {
  HttpProbeResult({
    required this.url,
    required this.finalUrl,
    required this.statusCode,
    required this.statusText,
    required this.headers,
    required this.redirects,
    required this.elapsedMs,
    required this.contentType,
    required this.contentLength,
    required this.method,
  });

  final String url;
  final String finalUrl;
  final int statusCode;
  final String statusText;
  final List<HttpHeader> headers;
  final List<HttpRedirectStep> redirects;
  final int elapsedMs;
  final String? contentType;
  final int? contentLength;
  final String method;

  HttpStatusCategory get category {
    if (statusCode < 200) return HttpStatusCategory.informational;
    if (statusCode < 300) return HttpStatusCategory.success;
    if (statusCode < 400) return HttpStatusCategory.redirect;
    if (statusCode < 500) return HttpStatusCategory.clientError;
    return HttpStatusCategory.serverError;
  }

  bool get hasRedirects => redirects.length > 1;
}

// ============================================================================
// WEBSOCKET
// ============================================================================

enum WsState { idle, connecting, connected, closing, closed, error }

extension WsStateX on WsState {
  String get display {
    switch (this) {
      case WsState.idle:
        return 'Idle';
      case WsState.connecting:
        return 'Connecting';
      case WsState.connected:
        return 'Connected';
      case WsState.closing:
        return 'Closing';
      case WsState.closed:
        return 'Closed';
      case WsState.error:
        return 'Error';
    }
  }

  Color get color {
    switch (this) {
      case WsState.idle:
        return const Color(0xFF94A3B8);
      case WsState.connecting:
        return const Color(0xFFFFC24B);
      case WsState.connected:
        return const Color(0xFF4BD68B);
      case WsState.closing:
        return const Color(0xFFFF8C42);
      case WsState.closed:
        return const Color(0xFF94A3B8);
      case WsState.error:
        return const Color(0xFFFF5C5C);
    }
  }
}

enum WsMessageDirection { incoming, outgoing, system }

enum WsPayloadFormat { text, hex, base64 }

class WsMessage {
  WsMessage({
    required this.direction,
    required this.payload,
    required this.timestamp,
    required this.sizeBytes,
    this.isError = false,
  });

  final WsMessageDirection direction;
  final String payload;
  final DateTime timestamp;
  final int sizeBytes;
  final bool isError;

  String get timeLabel {
    final String h = timestamp.hour.toString().padLeft(2, '0');
    final String m = timestamp.minute.toString().padLeft(2, '0');
    final String s = timestamp.second.toString().padLeft(2, '0');
    final String ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }
}

class WsConfig {
  WsConfig({
    this.url = '',
    this.sendFormat = WsPayloadFormat.text,
    this.displayFormat = WsPayloadFormat.text,
    this.autoReconnect = false,
    this.showTimestamp = true,
    this.maxMessages = 500,
    this.subprotocols = '',
    this.customHeaders = '',
  });

  String url;
  WsPayloadFormat sendFormat;
  WsPayloadFormat displayFormat;
  bool autoReconnect;
  bool showTimestamp;
  int maxMessages;
  String subprotocols;
  String customHeaders;
}

// ============================================================================
// ERRORS
// ============================================================================

class NetErrors {
  NetErrors._();

  static const String dnsEmptyDomain = 'net_dns_empty_domain';
  static const String dnsInvalidDomain = 'net_dns_invalid_domain';
  static const String dnsOffline = 'net_dns_offline';
  static const String dnsTimeout = 'net_dns_timeout';
  static const String dnsServerError = 'net_dns_server';
  static const String dnsNoRecords = 'net_dns_no_records';
  static const String dnsNxDomain = 'net_dns_nxdomain';

  static const String ipEmpty = 'net_ip_empty';
  static const String ipInvalid = 'net_ip_invalid';
  static const String ipOffline = 'net_ip_offline';
  static const String ipTimeout = 'net_ip_timeout';
  static const String ipServerError = 'net_ip_server';
  static const String ipInvalidCidr = 'net_ip_invalid_cidr';
  static const String ipPrefixRange = 'net_ip_prefix_range';

  static const String statusEmptyUrl = 'net_status_empty_url';
  static const String statusInvalidUrl = 'net_status_invalid_url';
  static const String statusOffline = 'net_status_offline';
  static const String statusTimeout = 'net_status_timeout';
  static const String statusFailed = 'net_status_failed';

  static const String wsEmptyUrl = 'net_ws_empty_url';
  static const String wsInvalidUrl = 'net_ws_invalid_url';
  static const String wsConnectFailed = 'net_ws_connect_failed';
  static const String wsSendFailed = 'net_ws_send_failed';
  static const String wsNotConnected = 'net_ws_not_connected';
  static const String wsInvalidPayload = 'net_ws_invalid_payload';
}

// ============================================================================
// THEME
// ============================================================================

class NetColors {
  NetColors._();

  static const Color accentA = Color(0xFF06B6D4);
  static const Color accentB = Color(0xFF8B5CF6);
  static const Color danger = Color(0xFFFF5C5C);
  static const Color warning = Color(0xFFFFC24B);
  static const Color success = Color(0xFF4BD68B);
  static const Color bgTop = Color(0xFF0A1828);
  static const Color bgMid = Color(0xFF0F2440);
  static const Color bgBot = Color(0xFF06111E);
}