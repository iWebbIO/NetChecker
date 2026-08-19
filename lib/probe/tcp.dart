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
