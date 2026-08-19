import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/catalog.dart';
import '../settings/app_settings.dart';
import 'dns.dart';
import 'models.dart';
import 'nics.dart';
import 'tcp.dart';

class ProbeEngine extends ChangeNotifier {
  ProbeEngine();

  AppSettings settings = AppSettings();
  SharedPreferences? _prefs;

  List<DomainTarget> domains = List.of(kDefaultDomains);
  final resolvers = List.of(kDefaultResolvers);
  final edges = List.of(kDefaultEdges);

  final Map<String, Hit> domainHits = {};
  final Map<String, Hit> dnsHits = {};
  final Map<String, Hit> edgeHits = {};
  final Map<String, Hit> huntHits = {};
  final Map<String, Hit> protoHits = {};

  String? liveDomain;
  String? liveDns;
  String? liveEdge;
  String? liveHunt;
  String? liveProto;

  List<NicChoice> nics = const [NicChoice.any];
  NicChoice get nic {
    return nics.firstWhere(
      (n) => n.id == settings.nicId,
      orElse: () => NicChoice.any,
    );
  }

  bool _disposed = false;
  bool _loops = false;
  int _epoch = 0;

  int get okCount =>
      domainHits.values.where((h) => h.status == HitStatus.ok).length;
  int get failCount => domainHits.values
      .where((h) => h.status == HitStatus.fail || h.status == HitStatus.timeout)
      .length;
  int get checkedCount =>
      domainHits.values.where((h) => h.status != HitStatus.idle).length;

  Future<void> start({bool loops = true, bool loadNics = true}) async {
    _prefs = await SharedPreferences.getInstance();
    settings = AppSettings.fromPrefs(_prefs!);
    _rebuildDomains();
    if (loadNics && !kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      try {
        nics = await listNics().timeout(const Duration(seconds: 2));
      } catch (_) {}
    }
    notifyListeners();
    if (loops) _ensureLoops();
  }

  void _rebuildDomains() {
    final extra = settings.extraDomains
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map((e) => DomainTarget(e.replaceFirst(RegExp(r'^https?://'), '')))
        .toList();
    domains = [if (settings.useDefaultDomains) ...kDefaultDomains, ...extra];
  }

  Future<void> apply(AppSettings next) async {
    settings = next;
    _rebuildDomains();
    await settings.save(_prefs!);
    _epoch++;
    _ensureLoops();
    notifyListeners();
  }

  Future<void> setRunning(bool running) async {
    await apply(settings.copyWith(running: running));
  }

  Future<void> setNic(String nicId) async {
    await apply(settings.copyWith(nicId: nicId));
  }

  Future<void> setAlwaysOnTop(bool value) async {
    await apply(settings.copyWith(alwaysOnTop: value));
  }

  void _ensureLoops() {
    if (_loops || _disposed) return;
    _loops = true;
    unawaited(_domainLoop());
    unawaited(_dnsLoop());
    unawaited(_auxLoop());
  }

  InternetAddress? get _bind => parseBind(nic.address);

  DnsProbe get _dns => DnsProbe(sourceAddress: _bind);
  TcpTlsProbe get _tcp => TcpTlsProbe(sourceAddress: _bind);

  Future<void> _waitWhilePaused() async {
    while (!_disposed && !settings.running) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
  }

  Future<void> _domainLoop() async {
    var i = 0;
    while (!_disposed) {
      await _waitWhilePaused();
      if (_disposed) return;
      if (domains.isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        continue;
      }
      i = i % domains.length;
      final target = domains[i];
      liveDomain = target.host;
      domainHits[target.host] = Hit.checking;
      notifyListeners();
      final epoch = _epoch;
      final hit = await _tcp.https(target.host, timeout: settings.httpTimeout);
      if (_disposed) return;
      if (epoch == _epoch) {
        domainHits[target.host] = hit;
        liveDomain = null;
        notifyListeners();
        i++;
      }
      await Future<void>.delayed(settings.itemDelay);
    }
  }

  Future<void> _dnsLoop() async {
    var i = 0;
    while (!_disposed) {
      await _waitWhilePaused();
      if (_disposed) return;
      i = i % resolvers.length;
      final r = resolvers[i];
      liveDns = r.address;
      dnsHits[r.address] = Hit.checking;
      notifyListeners();
      final epoch = _epoch;
      final hit = await _dns.latency(
        r.address,
        'google.com',
        timeout: settings.dnsTimeout,
      );
      if (_disposed) return;
      if (epoch == _epoch) {
        dnsHits[r.address] = hit;
        liveDns = null;
        notifyListeners();
        i++;
      }
      await Future<void>.delayed(settings.dnsDelay);
    }
  }

  Future<void> _auxLoop() async {
    var edgeI = 0;
    var huntI = 0;
    var protoI = 0;
    while (!_disposed) {
      await _waitWhilePaused();
      if (_disposed) return;

      final proto = kProtoTargets[protoI % kProtoTargets.length];
      liveProto = proto.id;
      protoHits[proto.id] = Hit.checking;
      notifyListeners();
      final epoch = _epoch;
      final protoHit = await _runProto(proto.id);
      if (_disposed) return;
      if (epoch == _epoch) {
        protoHits[proto.id] = protoHit;
        liveProto = null;
        protoI++;
        notifyListeners();
      }
      await Future<void>.delayed(settings.itemDelay);
      if (_disposed) return;
      await _waitWhilePaused();

      final edge = edges[edgeI % edges.length];
      liveEdge = edge.ip;
      edgeHits[edge.ip] = Hit.checking;
      notifyListeners();
      final edgeHit = await _tcp.tls(
        edge.ip,
        edge.sni,
        timeout: settings.httpTimeout,
      );
      if (_disposed) return;
      if (epoch == _epoch) {
        edgeHits[edge.ip] = edgeHit;
        liveEdge = null;
        edgeI++;
        notifyListeners();
      }
      await Future<void>.delayed(settings.itemDelay);
      if (_disposed) return;
      await _waitWhilePaused();

      final hunter = resolvers[huntI % resolvers.length];
      liveHunt = hunter.address;
      huntHits[hunter.address] = Hit.checking;
      notifyListeners();
      final huntHit = await _dns.hunt(
        hunter.address,
        settings.huntName,
        timeout: settings.dnsTimeout,
      );
      if (_disposed) return;
      if (epoch == _epoch) {
        huntHits[hunter.address] = huntHit;
        liveHunt = null;
        huntI++;
        notifyListeners();
      }
      await Future<void>.delayed(settings.dnsDelay);
    }
  }

  Future<Hit> _runProto(String id) {
    switch (id) {
      case 'v4':
        return _tcp.connect('1.1.1.1', 443, timeout: settings.httpTimeout);
      case 'v6':
        return _tcp.connect(
          '2606:4700:4700::1111',
          443,
          timeout: settings.httpTimeout,
        );
      case 'https':
        return _tcp.https('cloudflare.com', timeout: settings.httpTimeout);
      case 'sni':
        return _tcp.tls(
          '1.1.1.1',
          'youtube.com',
          timeout: settings.httpTimeout,
        );
      default:
        return Future.value(const Hit(status: HitStatus.fail, detail: '?'));
    }
  }

  String report() {
    final buf = StringBuffer();
    buf.writeln('NetChecker ${DateTime.now().toIso8601String()}');
    buf.writeln(
      'nic=${nic.label} timeout=${settings.httpTimeoutMs}ms delay=${settings.itemDelayMs}ms',
    );
    buf.writeln('DNS');
    for (final r in resolvers) {
      final h = dnsHits[r.address] ?? Hit.idle;
      buf.writeln('  ${r.short} ${r.address} ${h.readout} ${h.detail ?? ''}');
    }
    buf.writeln('PROTO');
    for (final p in kProtoTargets) {
      final h = protoHits[p.id] ?? Hit.idle;
      buf.writeln('  ${p.label} ${h.readout} ${h.detail ?? ''}');
    }
    buf.writeln('EDGE TLS ${kDefaultEdges.first.sni}');
    for (final e in edges) {
      final h = edgeHits[e.ip] ?? Hit.idle;
      buf.writeln('  ${e.ip} ${h.readout}');
    }
    buf.writeln('HUNT ${settings.huntName}');
    for (final r in resolvers) {
      final h = huntHits[r.address] ?? Hit.idle;
      buf.writeln('  ${r.short} ${h.readout} ${h.detail ?? ''}');
    }
    buf.writeln('SITES');
    for (final d in domains) {
      final h = domainHits[d.host] ?? Hit.idle;
      buf.writeln('  ${d.host} ${h.readout} ${h.detail ?? ''}');
    }
    return buf.toString();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
