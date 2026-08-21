import 'dart:async';
import 'dart:io';

class ReverseDns {
  ReverseDns._();
  static final ReverseDns instance = ReverseDns._();

  final Map<String, String> _cache = {
    '1.1.1.1': 'one.one.one.one',
    '1.0.0.1': 'one.one.one.one',
    '8.8.8.8': 'dns.google',
    '8.8.4.4': 'dns.google',
    '9.9.9.9': 'dns.quad9.net',
    '208.67.222.222': 'dns.opendns.com',
    '94.140.14.14': 'dns.adguard.com',
  };

  Future<String?> lookup(String ip) async {
    if (ip.isEmpty) return null;
    if (_cache.containsKey(ip)) return _cache[ip];

    try {
      final addr = InternetAddress(ip);
      final reversed = await addr.reverse().timeout(const Duration(seconds: 2));
      if (reversed.host.isNotEmpty && reversed.host != ip) {
        _cache[ip] = reversed.host;
        return reversed.host;
      }
    } catch (_) {}

    return null;
  }
}
