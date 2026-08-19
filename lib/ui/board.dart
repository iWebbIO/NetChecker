import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/catalog.dart';
import '../probe/engine.dart';
import '../probe/models.dart';
import '../theme.dart';
import 'cells.dart';

class ProbeBoard extends StatelessWidget {
  const ProbeBoard({super.key, required this.engine, this.compact = false});

  final ProbeEngine engine;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dnsW = compact ? 52.0 : 56.0;
    final edgeW = compact ? 68.0 : 76.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepRow(
          label: 'DNS',
          child: Row(
            children: [
              for (final r in engine.resolvers)
                SizedBox(
                  width: dnsW,
                  child: ProbeCell(
                    label: r.short,
                    hit: engine.dnsHits[r.address] ?? Hit.idle,
                    live: engine.liveDns == r.address,
                    onCopy:
                        '${r.name} ${r.address} ${engine.dnsHits[r.address]?.readout}',
                  ),
                ),
            ],
          ),
        ),
        _StepRow(
          label: 'NET',
          child: Row(
            children: [
              for (final p in kProtoTargets)
                SizedBox(
                  width: 52,
                  child: ProbeCell(
                    label: p.label,
                    hit: engine.protoHits[p.id] ?? Hit.idle,
                    live: engine.liveProto == p.id,
                    onCopy: '${p.label} ${engine.protoHits[p.id]?.readout}',
                  ),
                ),
              for (final e in engine.edges)
                SizedBox(
                  width: edgeW,
                  child: ProbeCell(
                    label: e.short,
                    hit: engine.edgeHits[e.ip] ?? Hit.idle,
                    live: engine.liveEdge == e.ip,
                    onCopy: '${e.ip} ${engine.edgeHits[e.ip]?.readout}',
                  ),
                ),
            ],
          ),
        ),
        _StepRow(
          label: 'HUNT',
          child: Row(
            children: [
              for (final r in engine.resolvers)
                SizedBox(
                  width: dnsW,
                  child: ProbeCell(
                    label: r.short,
                    hit: engine.huntHits[r.address] ?? Hit.idle,
                    live: engine.liveHunt == r.address,
                    sub: engine.huntHits[r.address]?.detail,
                    onCopy:
                        '${r.short} ${engine.settings.huntName} ${engine.huntHits[r.address]?.detail ?? engine.huntHits[r.address]?.readout}',
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final minExtent = compact ? 48.0 : 48.0;
              final cols = (constraints.maxWidth / (compact ? 96 : 108))
                  .floor()
                  .clamp(2, 12);
              final rows = (engine.domains.length / cols).ceil().clamp(1, 40);
              var extent = constraints.maxHeight / rows;
              if (extent < minExtent) extent = minExtent;
              return GridView.builder(
                padding: EdgeInsets.zero,
                physics: extent * rows <= constraints.maxHeight + 0.5
                    ? const NeverScrollableScrollPhysics()
                    : const ClampingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisExtent: extent,
                  crossAxisSpacing: 0,
                  mainAxisSpacing: 0,
                ),
                itemCount: engine.domains.length,
                itemBuilder: (context, i) {
                  final d = engine.domains[i];
                  final hit = engine.domainHits[d.host] ?? Hit.idle;
                  return ProbeCell(
                    label: d.short,
                    hit: hit,
                    live: engine.liveDomain == d.host,
                    sub: hit.detail,
                    onCopy: '${d.host} ${hit.readout} ${hit.detail ?? ''}',
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kLine)),
      ),
      child: Row(
        children: [
          StripLabel(label),
          const SizedBox(
            height: 44,
            child: VerticalDivider(width: 1, thickness: 1),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> copyReport(BuildContext context, ProbeEngine engine) async {
  await Clipboard.setData(ClipboardData(text: engine.report()));
  if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Report copied')));
  }
}
