import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'models.dart';

class GeoIpService {
  GeoIpService._();
  static final GeoIpService instance = GeoIpService._();

  final Map<String, GeoInfo> _cache = {
    '1.1.1.1': const GeoInfo(country: 'United States', countryCode: 'US', city: 'San Francisco', lat: 37.7749, lon: -122.4194, isp: 'Cloudflare'),
    '1.0.0.1': const GeoInfo(country: 'United States', countryCode: 'US', city: 'San Francisco', lat: 37.7749, lon: -122.4194, isp: 'Cloudflare'),
    '8.8.8.8': const GeoInfo(country: 'United States', countryCode: 'US', city: 'Mountain View', lat: 37.3861, lon: -122.0839, isp: 'Google LLC'),
    '8.8.4.4': const GeoInfo(country: 'United States', countryCode: 'US', city: 'Mountain View', lat: 37.3861, lon: -122.0839, isp: 'Google LLC'),
    '9.9.9.9': const GeoInfo(country: 'United States', countryCode: 'US', city: 'Berkeley', lat: 37.8716, lon: -122.2727, isp: 'Quad9'),
    '208.67.222.222': const GeoInfo(country: 'United States', countryCode: 'US', city: 'San Francisco', lat: 37.7749, lon: -122.4194, isp: 'OpenDNS'),
    '94.140.14.14': const GeoInfo(country: 'Cyprus', countryCode: 'CY', city: 'Nicosia', lat: 35.1856, lon: 33.3823, isp: 'AdGuard'),
    '194.242.2.2': const GeoInfo(country: 'Sweden', countryCode: 'SE', city: 'Gothenburg', lat: 57.7089, lon: 11.9746, isp: 'Mullvad'),
    '76.76.2.0': const GeoInfo(country: 'Canada', countryCode: 'CA', city: 'Toronto', lat: 43.6532, lon: -79.3832, isp: 'Control D'),
    '4.2.2.1': const GeoInfo(country: 'United States', countryCode: 'US', city: 'Monroe', lat: 32.5093, lon: -92.1193, isp: 'Lumen (Level 3)'),
    '178.22.122.100': const GeoInfo(country: 'Iran', countryCode: 'IR', city: 'Tehran', lat: 35.6892, lon: 51.3890, isp: 'Shecan / ITC'),
    '78.157.42.100': const GeoInfo(country: 'Iran', countryCode: 'IR', city: 'Tehran', lat: 35.6892, lon: 51.3890, isp: 'Electro / Irancell'),
    '10.202.10.10': const GeoInfo(country: 'Iran', countryCode: 'IR', city: 'Tehran', lat: 35.6892, lon: 51.3890, isp: 'Radar Game / Shatel'),
    '10.202.10.202': const GeoInfo(country: 'Iran', countryCode: 'IR', city: 'Tehran', lat: 35.6892, lon: 51.3890, isp: '403.online / Shatel'),
    '185.55.226.26': const GeoInfo(country: 'Iran', countryCode: 'IR', city: 'Tehran', lat: 35.6892, lon: 51.3890, isp: 'Begzar / MCI'),
    '87.107.110.109': const GeoInfo(country: 'Iran', countryCode: 'IR', city: 'Tehran', lat: 35.6892, lon: 51.3890, isp: 'DNS Pro'),
  };

  Future<GeoInfo?> lookup(String ip) async {
    if (ip.isEmpty) return null;
    if (_cache.containsKey(ip)) return _cache[ip];

    if (ip.startsWith('10.') || ip.startsWith('192.168.') || ip.startsWith('172.16.') || ip.startsWith('127.')) {
      final info = const GeoInfo(country: 'Local Network', countryCode: 'LAN', city: 'Private Gateway', isp: 'LAN');
      _cache[ip] = info;
      return info;
    }

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 2);
      final uri = Uri.parse('http://ip-api.com/json/$ip?fields=status,country,countryCode,city,lat,lon,isp');
      final req = await client.getUrl(uri).timeout(const Duration(seconds: 2));
      final res = await req.close().timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        if (json['status'] == 'success') {
          final info = GeoInfo(
            country: json['country'] as String?,
            countryCode: json['countryCode'] as String?,
            city: json['city'] as String?,
            lat: (json['lat'] as num?)?.toDouble(),
            lon: (json['lon'] as num?)?.toDouble(),
            isp: json['isp'] as String?,
          );
          _cache[ip] = info;
          client.close();
          return info;
        }
      }
      client.close();
    } catch (_) {}

    return null;
  }
}
