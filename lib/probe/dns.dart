import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'models.dart';

final _rand = Random();

Uint8List buildDnsQuery(String qname, {required int id, int type = 1}) {
  final out = BytesBuilder();
  out.addByte((id >> 8) & 0xff);
  out.addByte(id & 0xff);
  out.addByte(0x01); // recursion desired
  out.addByte(0x00);
  out.addByte(0x00);
  out.addByte(0x01); // QDCOUNT
  out.add([0, 0, 0, 0, 0, 0]);
  for (final label in qname.split('.')) {
    if (label.isEmpty) continue;
    final bytes = utf8.encode(label);
    if (bytes.length > 63) {
      throw FormatException('DNS label too long: $label');
    }
    out.addByte(bytes.length);
    out.add(bytes);
  }
  out.addByte(0);
  out.addByte(0);
  out.addByte(type);
  out.addByte(0);
  out.addByte(1);
  return out.toBytes();
}

List<String> parseDnsARecords(Uint8List msg) {
  if (msg.length < 12) return const [];
  final anCount = (msg[6] << 8) | msg[7];
  var i = 12;
  i = _skipName(msg, i);
  i += 4; // QTYPE QCLASS
  final records = <String>[];
  for (var n = 0; n < anCount && i + 10 <= msg.length; n++) {
    i = _skipName(msg, i);
    if (i + 10 > msg.length) break;
    final type = (msg[i] << 8) | msg[i + 1];
    final rdlength = (msg[i + 8] << 8) | msg[i + 9];
    i += 10;
    if (i + rdlength > msg.length) break;
    if (type == 1 && rdlength == 4) {
      records.add('${msg[i]}.${msg[i + 1]}.${msg[i + 2]}.${msg[i + 3]}');
    }
    i += rdlength;
  }
  return records;
}

int _skipName(Uint8List msg, int i) {
  var hops = 0;
  while (i < msg.length && hops++ < 32) {
    final len = msg[i];
    if (len == 0) return i + 1;
    if (len & 0xc0 == 0xc0) return i + 2;
    i += 1 + len;
  }
  return msg.length;
}

class DnsProbe {
  DnsProbe({this.sourceAddress});

  final InternetAddress? sourceAddress;

  Future<Hit> latency(
    String resolver,
    String qname, {
    required Duration timeout,
  }) async {
    return _query(resolver, qname, timeout: timeout, wantRecords: false);
  }

  Future<Hit> hunt(
    String resolver,
    String qname, {
    required Duration timeout,
  }) async {
    return _query(resolver, qname, timeout: timeout, wantRecords: true);
  }

  Future<Hit> _query(
    String resolver,
    String qname, {
    required Duration timeout,
    required bool wantRecords,
  }) async {
    final ip = InternetAddress.tryParse(resolver);
    if (ip == null) {
      return Hit(status: HitStatus.fail, detail: 'bad ip', at: DateTime.now());
    }
    final id = _rand.nextInt(0xffff);
    final packet = buildDnsQuery(qname, id: id);
    final sw = Stopwatch()..start();
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(
        sourceAddress ?? InternetAddress.anyIPv4,
        0,
      );
      socket.send(packet, ip, 53);
      final completer = Completer<Datagram?>();
      late StreamSubscription<RawSocketEvent> sub;
      final timer = Timer(timeout, () {
        if (!completer.isCompleted) completer.complete(null);
      });
      sub = socket.listen((event) {
        if (event == RawSocketEvent.read && !completer.isCompleted) {
          final dg = socket!.receive();
          if (dg != null &&
              dg.data.length >= 2 &&
              dg.data[0] == (id >> 8) &&
              dg.data[1] == (id & 0xff)) {
            completer.complete(dg);
          }
        }
      });
      final dg = await completer.future;
      timer.cancel();
      await sub.cancel();
      sw.stop();
      if (dg == null) {
        return Hit(
          status: HitStatus.timeout,
          ms: sw.elapsedMilliseconds,
          at: DateTime.now(),
        );
      }
      final records = parseDnsARecords(Uint8List.fromList(dg.data));
      return Hit(
        status: HitStatus.ok,
        ms: sw.elapsedMilliseconds,
        detail: wantRecords
            ? (records.isEmpty ? 'nodata' : records.first)
            : null,
        at: DateTime.now(),
      );
    } on SocketException catch (e) {
      sw.stop();
      return Hit(
        status: HitStatus.fail,
        ms: sw.elapsedMilliseconds,
        detail: _shortErr(e.message),
        at: DateTime.now(),
      );
    } catch (e) {
      sw.stop();
      return Hit(
        status: HitStatus.fail,
        ms: sw.elapsedMilliseconds,
        detail: _shortErr('$e'),
        at: DateTime.now(),
      );
    } finally {
      socket?.close();
    }
  }
}

String _shortErr(String message) {
  final m = message.toLowerCase();
  if (m.contains('timed out') || m.contains('timeout')) return 'to';
  if (m.contains('unreachable')) return 'unreach';
  if (m.contains('refused')) return 'refused';
  if (m.contains('reset')) return 'rst';
  if (message.length > 12) return 'fail';
  return message;
}
