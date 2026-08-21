import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/catalog.dart';
import '../probe/engine.dart';
import '../probe/models.dart';
import '../theme.dart';
import 'cells.dart';
import 'profile/item_profile_page.dart';
import 'profile/route_map_page.dart';

class ProbeBoard extends StatelessWidget {
  const ProbeBoard({super.key, required this.engine, this.compact = false});

  final ProbeEngine engine;
  final bool compact;

  void _openProfile(BuildContext context, ItemProfileInfo info) {
    ItemProfilePage.open(context, engine: engine, targetInfo: info);
  }

  void _openTrace(BuildContext context, String target, String title) {
    RouteMapPage.open(context, target: target, title: title);
  }

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
                    privacyMode: engine.settings.privacyMode,
                    label: r.short,
                    hit: engine.dnsHits[r.address] ?? Hit.idle,
                    live: engine.liveDns == r.address,
                    onTap: () => _openProfile(
                      context,
                      ItemProfileInfo(
                        id: r.address,
                        category: ItemCategory.dns,
                        title: r.name,
                        subtitle: 'DNS Server · ${r.address}',
                        tag: r.short,
                        hostOrIp: r.address,
                        port: 53,
                        provider: r.organization ?? r.name,
                        whatItTests:
                            'Tests DNS response time by sending a query to ${r.name} (${r.address}).',
                        whyItMatters:
                            'A fast DNS server makes websites load faster and connections more reliable.',
                        explanation: r.description,
                      ),
                    ),
                    onTraceroute: () => _openTrace(context, r.address, r.name),
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
                    privacyMode: engine.settings.privacyMode,
                    label: p.label,
                    hit: engine.protoHits[p.id] ?? Hit.idle,
                    live: engine.liveProto == p.id,
                    onTap: () {
                      ItemProfileInfo info;
                      switch (p.id) {
                        case 'v4':
                          info = const ItemProfileInfo(
                            id: 'v4',
                            category: ItemCategory.proto,
                            title: 'IPv4 Connection',
                            subtitle: 'Pings 1.1.1.1 on port 443',
                            tag: 'v4',
                            whatItTests:
                                'Checks if your standard IPv4 internet connection is working.',
                            whyItMatters:
                                'Most internet services use IPv4. If this fails, you may be disconnected.',
                          );
                          break;
                        case 'v6':
                          info = const ItemProfileInfo(
                            id: 'v6',
                            category: ItemCategory.proto,
                            title: 'IPv6 Connection',
                            subtitle: 'Pings IPv6 2606:4700:4700::1111',
                            tag: 'v6',
                            whatItTests:
                                'Checks if your network has working IPv6 support.',
                            whyItMatters:
                                'IPv6 is newer and sometimes avoids restrictions, but requires network support.',
                          );
                          break;
                        case 'https':
                          info = const ItemProfileInfo(
                            id: 'https',
                            category: ItemCategory.proto,
                            title: 'HTTPS Connection',
                            subtitle: 'Tests SSL connection to cloudflare.com',
                            tag: 'tls',
                            whatItTests:
                                'Checks if secure HTTPS web connections work properly.',
                            whyItMatters:
                                'Ensures encrypted website traffic can connect without errors.',
                          );
                          break;
                        case 'sni':
                        default:
                          info = const ItemProfileInfo(
                            id: 'sni',
                            category: ItemCategory.proto,
                            title: 'Domain Filtering Check',
                            subtitle: 'Tests connection with youtube.com domain',
                            tag: 'sni',
                            whatItTests:
                                'Checks if your network blocks websites based on their domain name.',
                            whyItMatters:
                                'Helps identify if website blocking is happening at the network level.',
                          );
                          break;
                      }
                      _openProfile(context, info);
                    },
                    onTraceroute: () => _openTrace(context, '1.1.1.1', p.label),
                    onCopy: '${p.label} ${engine.protoHits[p.id]?.readout}',
                  ),
                ),
              for (final e in engine.edges)
                SizedBox(
                  width: edgeW,
                  child: ProbeCell(
                    privacyMode: engine.settings.privacyMode,
                    label: e.short,
                    hit: engine.edgeHits[e.ip] ?? Hit.idle,
                    live: engine.liveEdge == e.ip,
                    onTap: () => _openProfile(
                      context,
                      ItemProfileInfo(
                        id: e.ip,
                        category: ItemCategory.edge,
                        title: 'Cloudflare (${e.short})',
                        subtitle: 'CDN Server · ${e.ip}',
                        tag: e.label,
                        hostOrIp: e.ip,
                        sni: e.sni,
                        port: 443,
                        provider: 'Cloudflare',
                        whatItTests:
                            'Tests response time to Cloudflare CDN server at ${e.ip}.',
                        whyItMatters:
                            'Cloudflare servers power millions of websites and proxy connections.',
                      ),
                    ),
                    onTraceroute: () => _openTrace(context, e.ip, 'Cloudflare (${e.short})'),
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
                    privacyMode: engine.settings.privacyMode,
                    label: r.short,
                    hit: engine.huntHits[r.address] ?? Hit.idle,
                    live: engine.liveHunt == r.address,
                    sub: engine.huntHits[r.address]?.detail,
                    onTap: () => _openProfile(
                      context,
                      ItemProfileInfo(
                        id: r.address,
                        category: ItemCategory.hunt,
                        title: '${r.name} · ${engine.settings.huntName}',
                        subtitle: 'Checking ${engine.settings.huntName} on ${r.address}',
                        tag: r.short,
                        hostOrIp: r.address,
                        port: 53,
                        provider: r.name,
                        whatItTests:
                            'Asks ${r.name} to find the address for ${engine.settings.huntName} to verify it returns the real website address.',
                        whyItMatters:
                            'Checks whether your network is redirecting or tampering with DNS lookups for blocked websites.',
                      ),
                    ),
                    onTraceroute: () => _openTrace(context, r.address, r.name),
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
                    privacyMode: engine.settings.privacyMode,
                    label: d.short,
                    hit: hit,
                    live: engine.liveDomain == d.host,
                    sub: hit.detail,
                    onTap: () => _openProfile(
                      context,
                      ItemProfileInfo(
                        id: d.host,
                        category: ItemCategory.domain,
                        title: d.host,
                        subtitle: 'https://${d.host}/',
                        tag: d.short,
                        hostOrIp: d.host,
                        sni: d.host,
                        port: 443,
                        whatItTests:
                            'Pings https://${d.host}/ to check if the website is online and how fast it responds.',
                        whyItMatters:
                            'Tells you if you can visit ${d.host} on your current connection.',
                      ),
                    ),
                    onTraceroute: () => _openTrace(context, d.host, d.host),
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
  final text = engine.buildReport();
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Report (${engine.settings.exportFormat.toUpperCase()}) copied to clipboard')));
  }
}
