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

  final Map<String, List<ProbeSample>> sampleHistory = {};

  void _recordSample(String id, Hit hit, {PhaseBreakdown? phase}) {
    final list = sampleHistory.putIfAbsent(id, () => []);
    list.add(ProbeSample.fromHit(hit, phase: phase));
    if (list.length > 60) {
      list.removeRange(0, list.length - 60);
    }
  }

  List<ProbeSample> getHistory(String id) =>
      List.unmodifiable(sampleHistory[id] ?? const []);

  ItemMetrics getMetrics(String id, {Hit? currentHit}) {
    final samples = sampleHistory[id] ?? const [];
    return ItemMetrics.fromSamples(samples, currentHit: currentHit);
  }

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
        _recordSample(target.host, hit);
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
        _recordSample(r.address, hit);
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
        _recordSample(proto.id, protoHit);
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
        _recordSample(edge.ip, edgeHit);
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
        _recordSample(hunter.address, huntHit);
        liveHunt = null;
        huntI++;
        notifyListeners();
      }
      await Future<void>.delayed(settings.dnsDelay);
    }
  }

  Future<ProbeSample> runDeepProbe(ItemProfileInfo item) async {
    switch (item.category) {
      case ItemCategory.domain:
        final sample = await _tcp.deepHttps(
          item.hostOrIp ?? item.id,
          timeout: settings.httpTimeout,
        );
        final hit = Hit(
          status: sample.status,
          ms: sample.ms,
          detail: sample.detail,
          at: sample.timestamp,
        );
        domainHits[item.id] = hit;
        _recordSample(item.id, hit, phase: sample.phase);
        notifyListeners();
        return sample;

      case ItemCategory.dns:
        final hit = await _dns.latency(
          item.hostOrIp ?? item.id,
          'google.com',
          timeout: settings.dnsTimeout,
        );
        dnsHits[item.id] = hit;
        final sample = ProbeSample.fromHit(
          hit,
          phase: PhaseBreakdown(
            dnsMs: hit.ms,
            anomaly: hit.status == HitStatus.ok
                ? null
                : (hit.detail ?? 'DNS Query Timeout/Fail'),
          ),
        );
        _recordSample(item.id, hit, phase: sample.phase);
        notifyListeners();
        return sample;

      case ItemCategory.edge:
        final edge = edges.firstWhere(
          (e) => e.ip == item.id,
          orElse: () => EdgeTarget(item.id, sni: item.sni ?? 'cloudflare.com'),
        );
        final tcpHit = await _tcp.connect(edge.ip, 443, timeout: settings.httpTimeout);
        final tlsHit = await _tcp.tls(edge.ip, edge.sni, timeout: settings.httpTimeout);
        final overallOk = tlsHit.status == HitStatus.ok;
        final hit = tlsHit;
        edgeHits[item.id] = hit;
        final sample = ProbeSample(
          timestamp: DateTime.now(),
          status: hit.status,
          ms: hit.ms,
          detail: hit.detail,
          phase: PhaseBreakdown(
            tcpMs: tcpHit.ms,
            tlsMs: tlsHit.ms,
            anomaly: overallOk ? null : 'Edge TLS Fail (${tlsHit.detail})',
          ),
        );
        _recordSample(item.id, hit, phase: sample.phase);
        notifyListeners();
        return sample;

      case ItemCategory.hunt:
        final hit = await _dns.hunt(
          item.hostOrIp ?? item.id,
          settings.huntName,
          timeout: settings.dnsTimeout,
        );
        huntHits[item.id] = hit;
        final isPoisoned = hit.detail != null &&
            (hit.detail!.startsWith('10.10.34.') ||
                hit.detail == '185.88.153.235' ||
                hit.detail == '185.88.153.236');
        final sample = ProbeSample.fromHit(
          hit,
          phase: PhaseBreakdown(
            dnsMs: hit.ms,
            resolvedIps: hit.detail != null ? [hit.detail!] : null,
            anomaly: isPoisoned ? 'DNS Poisoning (${hit.detail})' : null,
          ),
        );
        _recordSample(item.id, hit, phase: sample.phase);
        notifyListeners();
        return sample;

      case ItemCategory.proto:
        final hit = await _runProto(item.id);
        protoHits[item.id] = hit;
        final sample = ProbeSample.fromHit(
          hit,
          phase: PhaseBreakdown(
            tcpMs: hit.ms,
            anomaly: hit.status == HitStatus.ok ? null : 'Protocol Check Failed',
          ),
        );
        _recordSample(item.id, hit, phase: sample.phase);
        notifyListeners();
        return sample;
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
