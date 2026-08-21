import 'dart:math' as math;

enum HitStatus { idle, checking, ok, timeout, fail }

enum ItemCategory { domain, dns, edge, proto, hunt }

class PhaseBreakdown {
  const PhaseBreakdown({
    this.dnsMs,
    this.resolvedIps,
    this.tcpMs,
    this.tlsMs,
    this.httpMs,
    this.httpStatusCode,
    this.anomaly,
  });

  final int? dnsMs;
  final List<String>? resolvedIps;
  final int? tcpMs;
  final int? tlsMs;
  final int? httpMs;
  final int? httpStatusCode;
  final String? anomaly;

  int get totalMs =>
      (dnsMs ?? 0) + (tcpMs ?? 0) + (tlsMs ?? 0) + (httpMs ?? 0);
}

class ProbeSample {
  const ProbeSample({
    required this.timestamp,
    required this.status,
    this.ms,
    this.detail,
    this.phase,
  });

  final DateTime timestamp;
  final HitStatus status;
  final int? ms;
  final String? detail;
  final PhaseBreakdown? phase;

  static ProbeSample fromHit(Hit hit, {DateTime? at, PhaseBreakdown? phase}) {
    return ProbeSample(
      timestamp: at ?? hit.at ?? DateTime.now(),
      status: hit.status,
      ms: hit.ms,
      detail: hit.detail,
      phase: phase,
    );
  }
}

class ItemProfileInfo {
  const ItemProfileInfo({
    required this.id,
    required this.category,
    required this.title,
    this.subtitle,
    this.tag,
    this.hostOrIp,
    this.sni,
    this.port = 443,
    this.whatItTests,
    this.whyItMatters,
    this.provider,
    this.networkType,
    this.explanation,
  });

  final String id;
  final ItemCategory category;
  final String title;
  final String? subtitle;
  final String? tag;
  final String? hostOrIp;
  final String? sni;
  final int port;
  final String? whatItTests;
  final String? whyItMatters;
  final String? provider;
  final String? networkType;
  final String? explanation;

  String get categoryLabel {
    switch (category) {
      case ItemCategory.domain:
        return 'Website';
      case ItemCategory.dns:
        return 'DNS Server';
      case ItemCategory.edge:
        return 'CDN Server';
      case ItemCategory.proto:
        return 'Network Test';
      case ItemCategory.hunt:
        return 'DNS Check';
    }
  }
}

class ItemMetrics {
  const ItemMetrics({
    required this.avgMs,
    required this.minMs,
    required this.maxMs,
    required this.jitterMs,
    required this.stdDevMs,
    required this.uptimePercent,
    required this.totalChecks,
    required this.okCount,
    required this.failCount,
    required this.filterStatus,
    required this.isClean,
  });

  final double avgMs;
  final int minMs;
  final int maxMs;
  final double jitterMs;
  final double stdDevMs;
  final double uptimePercent;
  final int totalChecks;
  final int okCount;
  final int failCount;
  final String filterStatus;
  final bool isClean;

  double get lossPercent => totalChecks == 0 ? 0.0 : (failCount / totalChecks) * 100.0;

  static const empty = ItemMetrics(
    avgMs: 0,
    minMs: 0,
    maxMs: 0,
    jitterMs: 0,
    stdDevMs: 0,
    uptimePercent: 0,
    totalChecks: 0,
    okCount: 0,
    failCount: 0,
    filterStatus: 'Idle / Not probed yet',
    isClean: true,
  );

  factory ItemMetrics.fromSamples(
    List<ProbeSample> samples, {
    Hit? currentHit,
  }) {
    if (samples.isEmpty && (currentHit == null || currentHit.status == HitStatus.idle)) {
      return empty;
    }

    final validSamples = samples.where((s) => s.status != HitStatus.idle).toList();
    if (validSamples.isEmpty) {
      if (currentHit != null && currentHit.status != HitStatus.idle) {
        validSamples.add(ProbeSample.fromHit(currentHit));
      } else {
        return empty;
      }
    }

    final total = validSamples.length;
    final oks = validSamples.where((s) => s.status == HitStatus.ok).toList();
    final okCount = oks.length;
    final failCount = total - okCount;
    final uptimePercent = total == 0 ? 0.0 : (okCount / total) * 100.0;

    final latencies = oks.map((s) => s.ms).whereType<int>().toList();
    double avgMs = 0;
    int minMs = 0;
    int maxMs = 0;
    double jitter = 0;
    double stdDev = 0;

    if (latencies.isNotEmpty) {
      final sum = latencies.reduce((a, b) => a + b);
      avgMs = sum / latencies.length;
      minMs = latencies.reduce(math.min);
      maxMs = latencies.reduce(math.max);

      if (latencies.length > 1) {
        var diffSum = 0;
        for (var i = 1; i < latencies.length; i++) {
          diffSum += (latencies[i] - latencies[i - 1]).abs();
        }
        jitter = diffSum / (latencies.length - 1);

        double varianceSum = 0;
        for (final val in latencies) {
          varianceSum += math.pow(val - avgMs, 2);
        }
        stdDev = math.sqrt(varianceSum / latencies.length);
      }
    }

    final lastSample = validSamples.last;
    final lastStatus = currentHit?.status ?? lastSample.status;
    final lastDetail = (currentHit?.detail ?? lastSample.detail ?? '').toLowerCase();
    final phaseAnomaly = lastSample.phase?.anomaly;

    String filterStatus;
    bool isClean = true;

    final isPoisoned = (currentHit?.hasPrivateIp == true) ||
        isPrivateOrPoisonedIp(currentHit?.detail) ||
        isPrivateOrPoisonedIp(lastSample.detail) ||
        (phaseAnomaly != null && phaseAnomaly.contains('Poisoning'));

    if (isPoisoned) {
      final ip = currentHit?.detail ?? lastSample.detail ?? 'Fake IP';
      filterStatus = 'DNS Poisoning ($ip)';
      isClean = false;
    } else if (phaseAnomaly != null && phaseAnomaly.isNotEmpty) {
      filterStatus = phaseAnomaly;
      isClean = false;
    } else if (lastStatus == HitStatus.ok) {
      filterStatus = 'Working normally';
      isClean = true;
    } else if (lastStatus == HitStatus.timeout) {
      filterStatus = 'Timed out';
      isClean = false;
    } else if (lastDetail.contains('rst')) {
      filterStatus = 'Connection reset';
      isClean = false;
    } else if (lastDetail.contains('tls') || lastDetail.contains('hs')) {
      filterStatus = 'SSL / TLS error';
      isClean = false;
    } else if (lastDetail.contains('nx') || lastDetail.contains('bad ip')) {
      filterStatus = 'DNS lookup failed';
      isClean = false;
    } else if (lastDetail.contains('403')) {
      filterStatus = 'Blocked (HTTP 403)';
      isClean = false;
    } else if (lastDetail.contains('unreach')) {
      filterStatus = 'Unreachable';
      isClean = false;
    } else if (lastDetail.contains('refused')) {
      filterStatus = 'Connection refused';
      isClean = false;
    } else {
      filterStatus = lastDetail.isNotEmpty ? 'Error ($lastDetail)' : 'Offline';
      isClean = false;
    }

    return ItemMetrics(
      avgMs: avgMs,
      minMs: minMs,
      maxMs: maxMs,
      jitterMs: jitter,
      stdDevMs: stdDev,
      uptimePercent: uptimePercent,
      totalChecks: total,
      okCount: okCount,
      failCount: failCount,
      filterStatus: filterStatus,
      isClean: isClean,
    );
  }
}

class GeoInfo {
  const GeoInfo({
    this.country,
    this.countryCode,
    this.city,
    this.lat,
    this.lon,
    this.isp,
  });

  final String? country;
  final String? countryCode;
  final String? city;
  final double? lat;
  final double? lon;
  final String? isp;

  String get locationString {
    final parts = [if (city != null && city!.isNotEmpty) city, if (country != null && country!.isNotEmpty) country];
    return parts.isEmpty ? 'Unknown Location' : parts.join(', ');
  }

  String get flagEmoji {
    if (countryCode == null || countryCode!.length != 2) return '🌐';
    final code = countryCode!.toUpperCase();
    final first = code.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final second = code.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(first) + String.fromCharCode(second);
  }
}

class AsnInfo {
  const AsnInfo({
    this.asn,
    this.holder,
    this.prefix,
    this.country,
  });

  final int? asn;
  final String? holder;
  final String? prefix;
  final String? country;

  String get label {
    if (asn == null) return 'Unknown AS';
    if (holder != null && holder!.isNotEmpty) return 'AS$asn · $holder';
    return 'AS$asn';
  }
}

class TracerouteHop {
  const TracerouteHop({
    required this.ttl,
    this.ip,
    this.hostname,
    this.rttMs,
    this.lossPercent = 0.0,
    this.sent = 1,
    this.recv = 1,
    this.bestMs,
    this.worstMs,
    this.avgMs,
    this.stdDevMs,
    this.asn,
    this.geo,
    this.status = HitStatus.ok,
    this.detail,
  });

  final int ttl;
  final String? ip;
  final String? hostname;
  final int? rttMs;
  final double lossPercent;
  final int sent;
  final int recv;
  final int? bestMs;
  final int? worstMs;
  final double? avgMs;
  final double? stdDevMs;
  final AsnInfo? asn;
  final GeoInfo? geo;
  final HitStatus status;
  final String? detail;

  String get displayHost {
    if (hostname != null && hostname!.isNotEmpty) return hostname!;
    if (ip != null && ip!.isNotEmpty) return ip!;
    return '* * * (No Response)';
  }

  bool get hasResponse => ip != null || rttMs != null;
}

class TracerouteResult {
  const TracerouteResult({
    required this.target,
    required this.hops,
    this.isComplete = false,
    required this.timestamp,
    this.error,
  });

  final String target;
  final List<TracerouteHop> hops;
  final bool isComplete;
  final DateTime timestamp;
  final String? error;
}

/// Checks whether an IP string is a private / non-routable address (RFC 1918,
/// RFC 2544 benchmark/filtering 198.18.0.0/16 & 198.18.0.0/15, CGNAT 100.64.0.0/10,
/// loopback 127.0.0.0/8, link-local, IPv6 ULA) or a known Iranian TIC DNS poisoning sinkhole.
bool isPrivateOrPoisonedIp(String? raw) {
  if (raw == null) return false;
  var ipStr = raw.trim();
  if (ipStr.isEmpty) return false;

  // Strip CIDR prefix or port (e.g. "10.10.34.36/24" or "10.10.34.36:53")
  if (ipStr.contains('/') && !ipStr.contains('://')) {
    ipStr = ipStr.split('/').first.trim();
  }
  if (ipStr.contains(':') && !ipStr.contains('::')) {
    final colonCount = ipStr.split(':').length - 1;
    if (colonCount == 1 && ipStr.contains('.')) {
      ipStr = ipStr.split(':').first.trim();
    }
  }

  // Known Iranian TIC censorship / government filtering sinkholes
  if (ipStr == '185.88.153.235' || ipStr == '185.88.153.236') {
    return true;
  }

  // Parse IPv4
  final parts = ipStr.split('.');
  if (parts.length == 4) {
    final a = int.tryParse(parts[0]);
    final b = int.tryParse(parts[1]);
    final c = int.tryParse(parts[2]);
    final d = int.tryParse(parts[3]);
    if (a != null &&
        b != null &&
        c != null &&
        d != null &&
        a >= 0 &&
        a <= 255 &&
        b >= 0 &&
        b <= 255 &&
        c >= 0 &&
        c <= 255 &&
        d >= 0 &&
        d <= 255) {
      // 0.0.0.0/8
      if (a == 0) return true;
      // 10.0.0.0/8 (RFC 1918, includes Iranian TIC 10.10.34.0/24, 10.10.34.34, 10.10.34.35, 10.10.34.36, etc.)
      if (a == 10) return true;
      // 100.64.0.0/10 (Carrier-Grade NAT)
      if (a == 100 && (b >= 64 && b <= 127)) return true;
      // 127.0.0.0/8 (Loopback)
      if (a == 127) return true;
      // 169.254.0.0/16 (Link-Local)
      if (a == 169 && b == 254) return true;
      // 172.16.0.0/12 (RFC 1918)
      if (a == 172 && (b >= 16 && b <= 31)) return true;
      // 192.168.0.0/16 (RFC 1918)
      if (a == 192 && b == 168) return true;
      // 198.18.0.0/15 & 198.18.0.0/16 (RFC 2544 / Iranian DPI & Filtering)
      if (a == 198 && (b == 18 || b == 19)) return true;
      return false;
    }
  }

  // Parse IPv6
  final lower = ipStr.toLowerCase();
  if (lower == '::1' ||
      lower == '::' ||
      lower.startsWith('fe80:') ||
      lower.startsWith('fc') ||
      lower.startsWith('fd')) {
    return true;
  }

  return false;
}

class Hit {
  const Hit({
    this.status = HitStatus.idle,
    this.ms,
    this.detail,
    this.at,
    this.isPoisoned = false,
  });

  final HitStatus status;
  final int? ms;
  final String? detail;
  final DateTime? at;
  final bool isPoisoned;

  static const idle = Hit();
  static const checking = Hit(status: HitStatus.checking);

  Hit copyWith({
    HitStatus? status,
    int? ms,
    String? detail,
    DateTime? at,
    bool? isPoisoned,
  }) {
    return Hit(
      status: status ?? this.status,
      ms: ms ?? this.ms,
      detail: detail ?? this.detail,
      at: at ?? this.at,
      isPoisoned: isPoisoned ?? this.isPoisoned,
    );
  }

  bool get hasPrivateIp => isPoisoned || isPrivateOrPoisonedIp(detail);

  String get readout {
    switch (status) {
      case HitStatus.idle:
        return '·';
      case HitStatus.checking:
        return '…';
      case HitStatus.ok:
        return ms == null ? 'ok' : '${ms}ms';
      case HitStatus.timeout:
        return 'to';
      case HitStatus.fail:
        return detail == null || detail!.isEmpty ? 'fail' : detail!;
    }
  }

  bool get isLive => status == HitStatus.checking;
}

class NicChoice {
  const NicChoice({required this.id, required this.label, this.address});

  final String id;
  final String label;
  final String? address;

  static const any = NicChoice(id: 'any', label: 'any NIC');
}
