import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'models.dart';

class AsnLookup {
  AsnLookup._();
  static final AsnLookup instance = AsnLookup._();

  final Map<String, AsnInfo> _cache = {
    '1.1.1.1': const AsnInfo(asn: 13335, holder: 'Cloudflare, Inc.', country: 'US'),
    '1.0.0.1': const AsnInfo(asn: 13335, holder: 'Cloudflare, Inc.', country: 'US'),
    '8.8.8.8': const AsnInfo(asn: 15169, holder: 'Google LLC', country: 'US'),
    '8.8.4.4': const AsnInfo(asn: 15169, holder: 'Google LLC', country: 'US'),
    '9.9.9.9': const AsnInfo(asn: 19281, holder: 'Quad9', country: 'US'),
    '208.67.222.222': const AsnInfo(asn: 36692, holder: 'OpenDNS (Cisco)', country: 'US'),
    '94.140.14.14': const AsnInfo(asn: 47583, holder: 'AdGuard Software', country: 'CY'),
    '194.242.2.2': const AsnInfo(asn: 20473, holder: 'Mullvad VPN', country: 'SE'),
    '76.76.2.0': const AsnInfo(asn: 13335, holder: 'Control D', country: 'CA'),
    '4.2.2.1': const AsnInfo(asn: 3356, holder: 'Lumen (Level 3)', country: 'US'),
    '178.22.122.100': const AsnInfo(asn: 58224, holder: 'Shecan / ITC', country: 'IR'),
    '78.157.42.100': const AsnInfo(asn: 44244, holder: 'Electro / Irancell', country: 'IR'),
    '10.202.10.10': const AsnInfo(asn: 197207, holder: 'Radar Game / Shatel', country: 'IR'),
    '10.202.10.202': const AsnInfo(asn: 197207, holder: '403.online / Shatel', country: 'IR'),
    '185.55.226.26': const AsnInfo(asn: 44244, holder: 'Begzar / MCI', country: 'IR'),
    '87.107.110.109': const AsnInfo(asn: 44244, holder: 'DNS Pro', country: 'IR'),
  };

  Future<AsnInfo?> lookup(String ip) async {
    if (ip.isEmpty) return null;
    if (_cache.containsKey(ip)) return _cache[ip];

    if (ip.startsWith('10.') || ip.startsWith('192.168.') || ip.startsWith('172.16.') || ip.startsWith('127.')) {
      final info = const AsnInfo(asn: 0, holder: 'Private Network (RFC 1918)', country: 'LAN');
      _cache[ip] = info;
      return info;
    }

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 2);
      final req = await client.getUrl(Uri.parse('https://rdap.arin.net/registry/ip/$ip')).timeout(const Duration(seconds: 2));
      final res = await req.close().timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final name = json['name'] as String? ?? json['handle'] as String? ?? 'Autonomous System';
        final info = AsnInfo(
          asn: null,
          holder: name,
          prefix: json['startAddress']?.toString(),
          country: json['country'] as String?,
        );
        _cache[ip] = info;
        client.close();
        return info;
      }
      client.close();
    } catch (_) {}

    return null;
  }
}
