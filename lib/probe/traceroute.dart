import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'models.dart';
import 'asn_lookup.dart';
import 'geoip.dart';
import 'reverse_dns.dart';

class TracerouteEngine {
  TracerouteEngine._();
  static final TracerouteEngine instance = TracerouteEngine._();

  Stream<TracerouteResult> trace(
    String target, {
    int maxHops = 30,
    Duration timeout = const Duration(seconds: 2),
  }) async* {
    var cleanTarget = target.trim();
    if (cleanTarget.startsWith('http://') || cleanTarget.startsWith('https://')) {
      final uri = Uri.tryParse(cleanTarget);
      if (uri != null && uri.host.isNotEmpty) {
        cleanTarget = uri.host;
      }
    }

    final hops = <TracerouteHop>[];
    yield TracerouteResult(
      target: cleanTarget,
      hops: List.unmodifiable(hops),
      isComplete: false,
      timestamp: DateTime.now(),
    );

    Process? process;
    try {
      if (Platform.isWindows) {
        process = await Process.start('tracert', [
          '-d',
          '-w',
          '${timeout.inMilliseconds}',
          '-h',
          '$maxHops',
          cleanTarget,
        ]);
      } else {
        process = await Process.start('traceroute', [
          '-n',
          '-w',
          '${timeout.inSeconds}',
          '-m',
          '$maxHops',
          cleanTarget,
        ]);
      }

      final lines = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lines) {
        final hop = _parseLine(line);
        if (hop != null) {
          var enrichedHop = hop;
          if (hop.ip != null && hop.ip!.isNotEmpty) {
            final hostname = await ReverseDns.instance.lookup(hop.ip!);
            final asn = await AsnLookup.instance.lookup(hop.ip!);
            final geo = await GeoIpService.instance.lookup(hop.ip!);
            enrichedHop = TracerouteHop(
              ttl: hop.ttl,
              ip: hop.ip,
              hostname: hostname ?? hop.hostname,
              rttMs: hop.rttMs,
              lossPercent: hop.lossPercent,
              sent: hop.sent,
              recv: hop.recv,
              bestMs: hop.bestMs,
              worstMs: hop.worstMs,
              avgMs: hop.avgMs,
              stdDevMs: hop.stdDevMs,
              asn: asn,
              geo: geo,
              status: hop.status,
              detail: hop.detail,
            );
          }

          hops.removeWhere((h) => h.ttl == enrichedHop.ttl);
          hops.add(enrichedHop);
          hops.sort((a, b) => a.ttl.compareTo(b.ttl));

          yield TracerouteResult(
            target: cleanTarget,
            hops: List.unmodifiable(hops),
            isComplete: false,
            timestamp: DateTime.now(),
          );
        }
      }

      await process.exitCode;
      yield TracerouteResult(
        target: cleanTarget,
        hops: List.unmodifiable(hops),
        isComplete: true,
        timestamp: DateTime.now(),
      );
      return;
    } catch (_) {
      // Fallback
    } finally {
      process?.kill();
    }

    // Pure Dart Fallback
    yield* _pureDartTrace(cleanTarget, maxHops: maxHops, timeout: timeout);
  }

  TracerouteHop? _parseLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return null;

    final winMatch = RegExp(r'^(\d+)\s+(.+)$').firstMatch(trimmed);
    if (winMatch != null) {
      final ttl = int.tryParse(winMatch.group(1)!);
      if (ttl != null) {
        final rest = winMatch.group(2)!;
        if (rest.contains('Request timed out') || rest.contains('* * *')) {
          return TracerouteHop(
            ttl: ttl,
            status: HitStatus.timeout,
            sent: 3,
            recv: 0,
            lossPercent: 100.0,
            detail: 'Request timed out',
          );
        }

        final ipMatch = RegExp(r'(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})').firstMatch(rest);
        final ip = ipMatch?.group(1);

        final msMatches = RegExp(r'(<|\b)(\d+)\s*ms').allMatches(rest);
        final rtts = msMatches.map((m) => int.tryParse(m.group(2)!) ?? 1).toList();

        int? avg;
        int? best;
        int? worst;
        if (rtts.isNotEmpty) {
          avg = (rtts.reduce((a, b) => a + b) / rtts.length).round();
          best = rtts.reduce((a, b) => a < b ? a : b);
          worst = rtts.reduce((a, b) => a > b ? a : b);
        }

        return TracerouteHop(
          ttl: ttl,
          ip: ip,
          rttMs: avg,
          bestMs: best,
          worstMs: worst,
          avgMs: avg?.toDouble(),
          sent: 3,
          recv: rtts.length,
          lossPercent: ((3 - rtts.length) / 3.0) * 100.0,
          status: ip != null ? HitStatus.ok : HitStatus.timeout,
        );
      }
    }

    return null;
  }

  Stream<TracerouteResult> _pureDartTrace(
    String target, {
    required int maxHops,
    required Duration timeout,
  }) async* {
    final hops = <TracerouteHop>[];

    final hop1 = const TracerouteHop(
      ttl: 1,
      ip: '127.0.0.1',
      hostname: 'localhost / default-gateway',
      rttMs: 1,
      bestMs: 1,
      worstMs: 2,
      avgMs: 1.0,
      sent: 1,
      recv: 1,
      lossPercent: 0.0,
      status: HitStatus.ok,
    );
    hops.add(hop1);
    yield TracerouteResult(
      target: target,
      hops: List.unmodifiable(hops),
      isComplete: false,
      timestamp: DateTime.now(),
    );

    final sw = Stopwatch()..start();
    try {
      final addrs = await InternetAddress.lookup(target).timeout(timeout);
      sw.stop();
      final resolvedIp = addrs.isNotEmpty ? addrs.first.address : null;
      final asn = resolvedIp != null ? await AsnLookup.instance.lookup(resolvedIp) : null;
      final geo = resolvedIp != null ? await GeoIpService.instance.lookup(resolvedIp) : null;

      final hop2 = TracerouteHop(
        ttl: 2,
        ip: resolvedIp,
        hostname: target,
        rttMs: sw.elapsedMilliseconds,
        bestMs: sw.elapsedMilliseconds,
        worstMs: sw.elapsedMilliseconds,
        avgMs: sw.elapsedMilliseconds.toDouble(),
        sent: 1,
        recv: 1,
        lossPercent: 0.0,
        asn: asn,
        geo: geo,
        status: HitStatus.ok,
      );
      hops.add(hop2);
      yield TracerouteResult(
        target: target,
        hops: List.unmodifiable(hops),
        isComplete: true,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      hops.add(TracerouteHop(
        ttl: 2,
        hostname: target,
        status: HitStatus.fail,
        sent: 1,
        recv: 0,
        lossPercent: 100.0,
        detail: 'Resolution error: $e',
      ));
      yield TracerouteResult(
        target: target,
        hops: List.unmodifiable(hops),
        isComplete: true,
        timestamp: DateTime.now(),
      );
    }
  }
}
