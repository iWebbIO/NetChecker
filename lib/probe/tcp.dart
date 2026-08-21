import 'dart:async';
import 'dart:io';

import 'models.dart';

class TcpTlsProbe {
  TcpTlsProbe({this.sourceAddress});

  final InternetAddress? sourceAddress;

  Future<Hit> connect(
    String host,
    int port, {
    required Duration timeout,
  }) async {
    final sw = Stopwatch()..start();
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: timeout,
        sourceAddress: sourceAddress,
      );
      sw.stop();
      socket.destroy();
      return Hit(
        status: HitStatus.ok,
        ms: sw.elapsedMilliseconds,
        at: DateTime.now(),
      );
    } on SocketException catch (e) {
      sw.stop();
      return _fromSocket(e, sw.elapsedMilliseconds);
    } on TimeoutException {
      sw.stop();
      return Hit(
        status: HitStatus.timeout,
        ms: sw.elapsedMilliseconds,
        at: DateTime.now(),
      );
    } catch (e) {
      sw.stop();
      return Hit(
        status: HitStatus.fail,
        ms: sw.elapsedMilliseconds,
        detail: 'fail',
        at: DateTime.now(),
      );
    }
  }

  Future<Hit> tls(
    String ip,
    String sni, {
    required Duration timeout,
    int port = 443,
  }) async {
    final sw = Stopwatch()..start();
    Socket? raw;
    SecureSocket? secure;
    try {
      raw = await Socket.connect(
        ip,
        port,
        timeout: timeout,
        sourceAddress: sourceAddress,
      );
      secure = await SecureSocket.secure(
        raw,
        host: sni,
        onBadCertificate: (_) => true,
      ).timeout(timeout);
      sw.stop();
      return Hit(
        status: HitStatus.ok,
        ms: sw.elapsedMilliseconds,
        at: DateTime.now(),
      );
    } on TimeoutException {
      sw.stop();
      return Hit(
        status: HitStatus.timeout,
        ms: sw.elapsedMilliseconds,
        at: DateTime.now(),
      );
    } on HandshakeException {
      sw.stop();
      return Hit(
        status: HitStatus.fail,
        ms: sw.elapsedMilliseconds,
        detail: 'hs',
        at: DateTime.now(),
      );
    } on SocketException catch (e) {
      sw.stop();
      return _fromSocket(e, sw.elapsedMilliseconds);
    } catch (e) {
      sw.stop();
      return Hit(
        status: HitStatus.fail,
        ms: sw.elapsedMilliseconds,
        detail: 'fail',
        at: DateTime.now(),
      );
    } finally {
      try {
        await secure?.close();
      } catch (_) {}
      raw?.destroy();
    }
  }

  Future<Hit> https(String host, {required Duration timeout}) async {
    final sw = Stopwatch()..start();
    HttpClient? client;
    try {
      // Check DNS resolution for private / poisoned IP
      List<InternetAddress>? addrs;
      try {
        addrs = await InternetAddress.lookup(host).timeout(
          timeout > const Duration(seconds: 2) ? const Duration(seconds: 2) : timeout,
        );
      } catch (_) {}

      String? poisonedIp;
      if (addrs != null && addrs.isNotEmpty) {
        for (final a in addrs) {
          if (isPrivateOrPoisonedIp(a.address)) {
            poisonedIp = a.address;
            break;
          }
        }
      }

      if (poisonedIp != null) {
        sw.stop();
        return Hit(
          status: HitStatus.fail,
          ms: sw.elapsedMilliseconds,
          detail: poisonedIp,
          isPoisoned: true,
          at: DateTime.now(),
        );
      }

      client = HttpClient();
      client.connectionTimeout = timeout;
      client.idleTimeout = timeout;
      client.userAgent = 'NetChecker/1.0';
      client.badCertificateCallback = (cert, host, port) => true;
      if (sourceAddress != null) {
        final bind = sourceAddress!;
        client.connectionFactory = (uri, proxyHost, proxyPort) {
          return Socket.startConnect(uri.host, uri.port, sourceAddress: bind);
        };
      }
      final uri = Uri.parse('https://$host/');
      final req = await client.openUrl('HEAD', uri).timeout(timeout);
      req.followRedirects = false;
      var res = await req.close().timeout(timeout);
      if (res.statusCode == 405 || res.statusCode == 501) {
        await res.drain<void>();
        final get = await client.getUrl(uri).timeout(timeout);
        get.followRedirects = false;
        res = await get.close().timeout(timeout);
      }
      await res.drain<void>();
      sw.stop();
      final code = res.statusCode;
      final ok = code < 500;
      return Hit(
        status: ok ? HitStatus.ok : HitStatus.fail,
        ms: sw.elapsedMilliseconds,
        detail: '$code',
        at: DateTime.now(),
      );
    } on TimeoutException {
      sw.stop();
      return Hit(
        status: HitStatus.timeout,
        ms: sw.elapsedMilliseconds,
        at: DateTime.now(),
      );
    } on SocketException catch (e) {
      sw.stop();
      return _fromSocket(e, sw.elapsedMilliseconds);
    } on HandshakeException {
      sw.stop();
      return Hit(
        status: HitStatus.fail,
        ms: sw.elapsedMilliseconds,
        detail: 'tls',
        at: DateTime.now(),
      );
    } catch (e) {
      sw.stop();
      return Hit(
        status: HitStatus.fail,
        ms: sw.elapsedMilliseconds,
        detail: 'fail',
        at: DateTime.now(),
      );
    } finally {
      client?.close(force: true);
    }
  }

  Future<ProbeSample> deepHttps(
    String host, {
    required Duration timeout,
  }) async {
    int? dnsMs;
    List<String> resolvedIps = [];
    int? tcpMs;
    int? tlsMs;
    int? httpMs;
    int? httpStatusCode;
    String? anomaly;

    final overallSw = Stopwatch()..start();

    // 1. DNS Phase
    final dnsSw = Stopwatch()..start();
    try {
      final addrs = await InternetAddress.lookup(host).timeout(timeout);
      dnsSw.stop();
      dnsMs = dnsSw.elapsedMilliseconds;
      resolvedIps = addrs.map((a) => a.address).toList();

      for (final ip in resolvedIps) {
        if (isPrivateOrPoisonedIp(ip)) {
          anomaly = 'DNS Poisoning (Gov Sinkhole $ip)';
          break;
        }
      }
    } on TimeoutException {
      dnsSw.stop();
      return ProbeSample(
        timestamp: DateTime.now(),
        status: HitStatus.timeout,
        ms: dnsSw.elapsedMilliseconds,
        detail: 'to',
        phase: PhaseBreakdown(
          dnsMs: dnsSw.elapsedMilliseconds,
          anomaly: 'DNS Lookup Timed Out',
        ),
      );
    } catch (e) {
      dnsSw.stop();
      return ProbeSample(
        timestamp: DateTime.now(),
        status: HitStatus.fail,
        ms: dnsSw.elapsedMilliseconds,
        detail: 'nx',
        phase: PhaseBreakdown(
          dnsMs: dnsSw.elapsedMilliseconds,
          anomaly: 'DNS Resolution Failed ($e)',
        ),
      );
    }

    // 2. TCP Connect Phase
    final connectHost = resolvedIps.isNotEmpty ? resolvedIps.first : host;
    final tcpSw = Stopwatch()..start();
    Socket? socket;
    try {
      socket = await Socket.connect(
        connectHost,
        443,
        sourceAddress: sourceAddress,
        timeout: timeout,
      );
      tcpSw.stop();
      tcpMs = tcpSw.elapsedMilliseconds;
    } on TimeoutException {
      tcpSw.stop();
      return ProbeSample(
        timestamp: DateTime.now(),
        status: HitStatus.timeout,
        ms: overallSw.elapsedMilliseconds,
        detail: 'to',
        phase: PhaseBreakdown(
          dnsMs: dnsMs,
          resolvedIps: resolvedIps,
          tcpMs: tcpSw.elapsedMilliseconds,
          anomaly: 'TCP Connection Timed Out (Blackhole)',
        ),
      );
    } on SocketException catch (e) {
      tcpSw.stop();
      final hit = _fromSocket(e, tcpSw.elapsedMilliseconds);
      final isRst = hit.detail == 'rst';
      return ProbeSample(
        timestamp: DateTime.now(),
        status: hit.status,
        ms: overallSw.elapsedMilliseconds,
        detail: hit.detail,
        phase: PhaseBreakdown(
          dnsMs: dnsMs,
          resolvedIps: resolvedIps,
          tcpMs: tcpSw.elapsedMilliseconds,
          anomaly: isRst ? 'TCP Reset (DPI RST Injected)' : 'TCP Connect Refused/Failed',
        ),
      );
    } catch (e) {
      tcpSw.stop();
      return ProbeSample(
        timestamp: DateTime.now(),
        status: HitStatus.fail,
        ms: overallSw.elapsedMilliseconds,
        detail: 'fail',
        phase: PhaseBreakdown(
          dnsMs: dnsMs,
          resolvedIps: resolvedIps,
          tcpMs: tcpSw.elapsedMilliseconds,
          anomaly: 'TCP Error ($e)',
        ),
      );
    }

    // 3. TLS Handshake Phase
    final tlsSw = Stopwatch()..start();
    SecureSocket? secure;
    try {
      secure = await SecureSocket.secure(
        socket,
        host: host,
        onBadCertificate: (_) => true,
      ).timeout(timeout);
      tlsSw.stop();
      tlsMs = tlsSw.elapsedMilliseconds;
    } on TimeoutException {
      tlsSw.stop();
      try {
        socket.destroy();
      } catch (_) {}
      return ProbeSample(
        timestamp: DateTime.now(),
        status: HitStatus.timeout,
        ms: overallSw.elapsedMilliseconds,
        detail: 'to',
        phase: PhaseBreakdown(
          dnsMs: dnsMs,
          resolvedIps: resolvedIps,
          tcpMs: tcpMs,
          tlsMs: tlsSw.elapsedMilliseconds,
          anomaly: 'TLS Handshake Timed Out (SNI Filter)',
        ),
      );
    } on HandshakeException catch (e) {
      tlsSw.stop();
      try {
        socket.destroy();
      } catch (_) {}
      return ProbeSample(
        timestamp: DateTime.now(),
        status: HitStatus.fail,
        ms: overallSw.elapsedMilliseconds,
        detail: 'tls',
        phase: PhaseBreakdown(
          dnsMs: dnsMs,
          resolvedIps: resolvedIps,
          tcpMs: tcpMs,
          tlsMs: tlsSw.elapsedMilliseconds,
          anomaly: 'TLS Handshake Rejected (SNI Block: $e)',
        ),
      );
    } catch (e) {
      tlsSw.stop();
      try {
        socket.destroy();
      } catch (_) {}
      return ProbeSample(
        timestamp: DateTime.now(),
        status: HitStatus.fail,
        ms: overallSw.elapsedMilliseconds,
        detail: 'tls',
        phase: PhaseBreakdown(
          dnsMs: dnsMs,
          resolvedIps: resolvedIps,
          tcpMs: tcpMs,
          tlsMs: tlsSw.elapsedMilliseconds,
          anomaly: 'TLS Handshake Failed ($e)',
        ),
      );
    }

    // 4. HTTP HEAD / Status Phase
    final httpSw = Stopwatch()..start();
    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = timeout;
      client.idleTimeout = timeout;
      client.userAgent = 'NetChecker/1.0';
      client.badCertificateCallback = (cert, host, port) => true;
      if (sourceAddress != null) {
        final bind = sourceAddress!;
        client.connectionFactory = (uri, proxyHost, proxyPort) {
          return Socket.startConnect(uri.host, uri.port, sourceAddress: bind);
        };
      }
      final uri = Uri.parse('https://$host/');
      final req = await client.openUrl('HEAD', uri).timeout(timeout);
      req.followRedirects = false;
      var res = await req.close().timeout(timeout);
      if (res.statusCode == 405 || res.statusCode == 501) {
        await res.drain<void>();
        final get = await client.getUrl(uri).timeout(timeout);
        get.followRedirects = false;
        res = await get.close().timeout(timeout);
      }
      await res.drain<void>();
      httpSw.stop();
      httpMs = httpSw.elapsedMilliseconds;
      httpStatusCode = res.statusCode;

      if (res.statusCode == 403 && anomaly == null) {
        anomaly = 'HTTP 403 (Censorship / Forbidden)';
      }
    } catch (_) {
      httpSw.stop();
      httpMs = httpSw.elapsedMilliseconds;
      httpStatusCode = 200;
    } finally {
      client?.close(force: true);
      try {
        await secure.close();
      } catch (_) {}
      socket.destroy();
    }

    overallSw.stop();
    final ok = httpStatusCode < 500 && anomaly == null;

    return ProbeSample(
      timestamp: DateTime.now(),
      status: ok ? HitStatus.ok : (anomaly != null ? HitStatus.fail : HitStatus.ok),
      ms: overallSw.elapsedMilliseconds,
      detail: '$httpStatusCode',
      phase: PhaseBreakdown(
        dnsMs: dnsMs,
        resolvedIps: resolvedIps,
        tcpMs: tcpMs,
        tlsMs: tlsMs,
        httpMs: httpMs,
        httpStatusCode: httpStatusCode,
        anomaly: anomaly,
      ),
    );
  }
}

Hit _fromSocket(SocketException e, int ms) {
  final m = e.message.toLowerCase();
  final os = (e.osError?.message ?? '').toLowerCase();
  final blob = '$m $os';
  if (blob.contains('timed out') || blob.contains('timeout')) {
    return Hit(status: HitStatus.timeout, ms: ms, at: DateTime.now());
  }
  String detail = 'fail';
  if (blob.contains('unreachable')) detail = 'unreach';
  if (blob.contains('refused')) detail = 'refused';
  if (blob.contains('reset')) detail = 'rst';
  if (blob.contains('failed host lookup') || blob.contains('name or service')) {
    detail = 'nx';
  }
  return Hit(
    status: HitStatus.fail,
    ms: ms,
    detail: detail,
    at: DateTime.now(),
  );
}
