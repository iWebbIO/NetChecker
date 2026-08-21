import 'dart:convert';
import '../probe/engine.dart';
import '../probe/models.dart';
import '../data/catalog.dart';

enum ExportFormat {
  plaintext,
  markdown,
  csv,
  json,
}

class ReportExport {
  static String generate(ProbeEngine engine, {ExportFormat format = ExportFormat.markdown}) {
    switch (format) {
      case ExportFormat.json:
        return _generateJson(engine);
      case ExportFormat.csv:
        return _generateCsv(engine);
      case ExportFormat.markdown:
        return _generateMarkdown(engine);
      case ExportFormat.plaintext:
        return _generatePlaintext(engine);
    }
  }

  static String _generateJson(ProbeEngine engine) {
    final data = <String, dynamic>{
      'tool': 'NetChecker',
      'timestamp': DateTime.now().toIso8601String(),
      'summary': {
        'totalOk': engine.totalOk,
        'totalDown': engine.totalDown,
        'isRunning': engine.isRunning,
      },
      'domains': <String, dynamic>{},
      'dns': <String, dynamic>{},
      'edges': <String, dynamic>{},
      'proto': <String, dynamic>{},
      'hunt': <String, dynamic>{},
    };

    void addItem(Map<String, dynamic> targetMap, String id, String title, ItemCategory cat) {
      final metrics = engine.getMetrics(id);
      final samples = engine.getHistory(id);
      targetMap[id] = {
        'id': id,
        'title': title,
        'category': cat.name,
        'status': metrics.filterStatus,
        'isClean': metrics.isClean,
        'avgMs': metrics.avgMs,
        'minMs': metrics.minMs,
        'maxMs': metrics.maxMs,
        'stdDevMs': metrics.stdDevMs,
        'jitterMs': metrics.jitterMs,
        'lossPercent': metrics.lossPercent,
        'totalChecks': metrics.totalChecks,
        'okCount': metrics.okCount,
        'failCount': metrics.failCount,
        'samples': samples
            .map((s) => {
                  'timestamp': s.timestamp.toIso8601String(),
                  'status': s.status.name,
                  'ms': s.ms,
                  'detail': s.detail,
                })
            .toList(),
      };
    }

    for (final d in engine.effectiveDomains) {
      addItem(data['domains'] as Map<String, dynamic>, d.host, d.host, ItemCategory.domain);
    }
    for (final r in kDefaultResolvers) {
      addItem(data['dns'] as Map<String, dynamic>, r.address, r.name, ItemCategory.dns);
    }
    for (final e in kDefaultEdges) {
      addItem(data['edges'] as Map<String, dynamic>, e.ip, e.short, ItemCategory.edge);
    }
    for (final p in kProtoTargets) {
      addItem(data['proto'] as Map<String, dynamic>, p.id, p.label, ItemCategory.proto);
    }
    for (final r in kDefaultResolvers) {
      final huntId = 'hunt_${r.address}';
      addItem(data['hunt'] as Map<String, dynamic>, huntId, '${r.short} (${engine.settings.huntName})', ItemCategory.hunt);
    }

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  static String _generateCsv(ProbeEngine engine) {
    final sb = StringBuffer();
    sb.writeln('ID,Title,Category,Status,AvgMs,MinMs,MaxMs,StdDevMs,JitterMs,LossPercent,Sent,Recv');

    void writeItem(String id, String title, ItemCategory cat) {
      final m = engine.getMetrics(id);
      sb.writeln(
        '"$id","$title","${cat.name}","${m.filterStatus}",${m.avgMs.toStringAsFixed(1)},${m.minMs},${m.maxMs},${m.stdDevMs.toStringAsFixed(1)},${m.jitterMs.toStringAsFixed(1)},${m.lossPercent.toStringAsFixed(1)},${m.totalChecks},${m.okCount}',
      );
    }

    for (final d in engine.effectiveDomains) {
      writeItem(d.host, d.host, ItemCategory.domain);
    }
    for (final r in kDefaultResolvers) {
      writeItem(r.address, r.name, ItemCategory.dns);
    }
    for (final e in kDefaultEdges) {
      writeItem(e.ip, e.short, ItemCategory.edge);
    }
    for (final p in kProtoTargets) {
      writeItem(p.id, p.label, ItemCategory.proto);
    }

    return sb.toString();
  }

  static String _generateMarkdown(ProbeEngine engine) {
    final sb = StringBuffer();
    sb.writeln('# NetChecker Diagnostic Report');
    sb.writeln('**Generated**: ${DateTime.now().toLocal()}');
    sb.writeln('**Summary**: ${engine.totalOk} OK · ${engine.totalDown} DOWN\n');

    sb.writeln('| Item | Type | Status | Loss% | Snd | Recv | Avg | Min | Max | StdDev | Jitter |');
    sb.writeln('|---|---|---|---|---|---|---|---|---|---|---|');

    void writeRow(String id, String title, String type) {
      final m = engine.getMetrics(id);
      sb.writeln(
        '| $title | $type | ${m.filterStatus} | ${m.lossPercent.toStringAsFixed(1)}% | ${m.totalChecks} | ${m.okCount} | ${m.avgMs.round()}ms | ${m.minMs}ms | ${m.maxMs}ms | ±${m.stdDevMs.toStringAsFixed(1)}ms | ±${m.jitterMs.toStringAsFixed(1)}ms |',
      );
    }

    for (final d in engine.effectiveDomains) {
      writeRow(d.host, d.host, 'Website');
    }
    for (final r in kDefaultResolvers) {
      writeRow(r.address, '${r.name} (${r.short})', 'DNS Server');
    }
    for (final e in kDefaultEdges) {
      writeRow(e.ip, '${e.ip} (${e.short})', 'CDN Edge');
    }
    for (final p in kProtoTargets) {
      writeRow(p.id, p.label, 'Network Test');
    }

    return sb.toString();
  }

  static String _generatePlaintext(ProbeEngine engine) {
    final buf = StringBuffer();
    buf.writeln('NetChecker ${DateTime.now().toIso8601String()}');
    buf.writeln('nic=${engine.nic.label} timeout=${engine.settings.httpTimeoutMs}ms delay=${engine.settings.itemDelayMs}ms');
    buf.writeln('DNS');
    for (final r in engine.resolvers) {
      final h = engine.dnsHits[r.address] ?? Hit.idle;
      final detail = h.detail ?? '';
      buf.writeln('  ${r.short} ${r.address} ${h.readout} $detail');
    }
    buf.writeln('PROTO');
    for (final p in kProtoTargets) {
      final h = engine.protoHits[p.id] ?? Hit.idle;
      final detail = h.detail ?? '';
      buf.writeln('  ${p.label} ${h.readout} $detail');
    }
    buf.writeln('EDGE TLS ${kDefaultEdges.first.sni}');
    for (final e in engine.edges) {
      final h = engine.edgeHits[e.ip] ?? Hit.idle;
      buf.writeln('  ${e.ip} ${h.readout}');
    }
    buf.writeln('HUNT ${engine.settings.huntName}');
    for (final r in engine.resolvers) {
      final h = engine.huntHits[r.address] ?? Hit.idle;
      final detail = h.detail ?? '';
      buf.writeln('  ${r.short} ${h.readout} $detail');
    }
    buf.writeln('SITES');
    for (final d in engine.domains) {
      final h = engine.domainHits[d.host] ?? Hit.idle;
      final detail = h.detail ?? '';
      buf.writeln('  ${d.host} ${h.readout} $detail');
    }
    return buf.toString();
  }
}
