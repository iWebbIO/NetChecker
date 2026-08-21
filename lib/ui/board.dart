import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/catalog.dart';
import '../probe/engine.dart';
import '../probe/models.dart';
import '../theme.dart';
import 'cells.dart';
import 'profile/item_profile_page.dart';

class ProbeBoard extends StatelessWidget {
  const ProbeBoard({super.key, required this.engine, this.compact = false});

  final ProbeEngine engine;
  final bool compact;

  void _openProfile(BuildContext context, ItemProfileInfo info) {
    ItemProfilePage.open(context, engine: engine, targetInfo: info);
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
                    label: r.short,
                    hit: engine.dnsHits[r.address] ?? Hit.idle,
                    live: engine.liveDns == r.address,
                    onTap: () => _openProfile(
                      context,
                      ItemProfileInfo(
                        id: r.address,
                        category: ItemCategory.dns,
                        title: '${r.name} DNS (${r.address})',
                        subtitle: '${r.organization ?? r.name} · ${r.location}',
                        tag: r.short,
                        hostOrIp: r.address,
                        port: 53,
                        provider: r.organization ?? r.name,
                        networkType: r.isIranian
                            ? 'Iranian Sanction-Bypass / Domestic DNS'
                            : 'Global Anycast Public Resolver',
                        whatItTests:
                            'Sends standard UDP DNS queries to ${r.name} (${r.address}) on port 53 to test resolver reachability and query response latency.',
                        whyItMatters:
                            'A responsive, unhindered DNS resolver is crucial for fast web browsing and reliable VPN tunneling. If this times out or shows high latency, your ISP or network firewall may be throttling or filtering port 53 UDP traffic.',
                        explanation: r.description,
                      ),
                    ),
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
                    onTap: () {
                      ItemProfileInfo info;
                      switch (p.id) {
                        case 'v4':
                          info = const ItemProfileInfo(
                            id: 'v4',
                            category: ItemCategory.proto,
                            title: 'IPv4 Global Reachability',
                            subtitle:
                                'Direct TCP SYN to 1.1.1.1:443 (Cloudflare Anycast)',
                            tag: 'v4',
                            networkType: 'Core Internet Protocol (IPv4)',
                            whatItTests:
                                'Tests whether standard IPv4 TCP packets can route out of your current network interface to global Anycast internet servers (1.1.1.1:443).',
                            whyItMatters:
                                'The vast majority of internet services run on IPv4. If this check fails, your base internet connection or network interface is disconnected.',
                          );
                          break;
                        case 'v6':
                          info = const ItemProfileInfo(
                            id: 'v6',
                            category: ItemCategory.proto,
                            title: 'IPv6 Dual-Stack Reachability',
                            subtitle:
                                'Direct TCP SYN to 2606:4700:4700::1111:443 (IPv6)',
                            tag: 'v6',
                            networkType: 'Next-Generation Protocol (IPv6)',
                            whatItTests:
                                'Tests whether your ISP or VPN tunnel provides operational IPv6 dual-stack connectivity to 2606:4700:4700::1111:443.',
                            whyItMatters:
                                'IPv6 traffic often bypasses legacy IPv4 firewall filters, but requires IPv6 support from your ISP or VPN provider. If your network is IPv4-only, this will show timeout or unreachable.',
                          );
                          break;
                        case 'https':
                          info = const ItemProfileInfo(
                            id: 'https',
                            category: ItemCategory.proto,
                            title: 'Direct HTTPS / TLS Protocol Check',
                            subtitle:
                                'Full TLS 1.3 Handshake & HTTP HEAD to cloudflare.com',
                            tag: 'tls',
                            networkType: 'Encrypted Web Protocol',
                            whatItTests:
                                'Establishes a complete TLS 1.3 cryptographic handshake followed by an HTTP HEAD response verification.',
                            whyItMatters:
                                'Confirms that secure web traffic can be negotiated cleanly without SSL/TLS protocol tampering or man-in-the-middle degradation.',
                          );
                          break;
                        case 'sni':
                        default:
                          info = const ItemProfileInfo(
                            id: 'sni',
                            category: ItemCategory.proto,
                            title: 'SNI Firewall Filtering Probe',
                            subtitle:
                                'TLS ClientHello with SNI: youtube.com sent to 1.1.1.1',
                            tag: 'sni',
                            networkType: 'DPI Censorship Detection',
                            whatItTests:
                                'Connects to Cloudflare Anycast (1.1.1.1) but sends a Server Name Indication (SNI) header for "youtube.com".',
                            whyItMatters:
                                'Deep Packet Inspection (DPI) firewalls monitor unencrypted SNI domain headers. If your ISP blocks YouTube via SNI filtering, this probe triggers and exposes the RST packet injection.',
                          );
                          break;
                      }
                      _openProfile(context, info);
                    },
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
                    onTap: () => _openProfile(
                      context,
                      ItemProfileInfo(
                        id: e.ip,
                        category: ItemCategory.edge,
                        title: 'Cloudflare CDN Anycast IP (${e.short})',
                        subtitle: 'Anycast IP: ${e.ip} · SNI: ${e.sni}',
                        tag: e.label,
                        hostOrIp: e.ip,
                        sni: e.sni,
                        port: 443,
                        provider: 'Cloudflare Anycast Network',
                        networkType: 'CDN Anycast Edge Subnet',
                        whatItTests:
                            'Connects directly to Cloudflare CDN Anycast IP ${e.ip} on port 443 and performs a TLS handshake with SNI ${e.sni}.',
                        whyItMatters:
                            'Millions of websites, APIs, and VPN proxies rely on Cloudflare Anycast edge IP ranges. ISPs frequently throttle or blackhole specific Cloudflare subnets (like 104.16-104.21). This test shows which edge IPs are fast and clean.',
                      ),
                    ),
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
                    onTap: () => _openProfile(
                      context,
                      ItemProfileInfo(
                        id: r.address,
                        category: ItemCategory.hunt,
                        title:
                            '${r.name} — DNS Poisoning Check for ${engine.settings.huntName}',
                        subtitle:
                            'Resolver: ${r.address} (${r.organization ?? r.name}) · Target: ${engine.settings.huntName}',
                        tag: r.short,
                        hostOrIp: r.address,
                        port: 53,
                        provider: r.organization ?? r.name,
                        networkType: 'DNS Poisoning & Censorship Detector',
                        whatItTests:
                            'Queries ${r.name} (${r.address}) for "${engine.settings.huntName}" and inspects the returned IP addresses to verify authenticity.',
                        whyItMatters:
                            'When firewalls block websites, they often poison DNS responses to redirect you to an official block page (such as 10.10.34.34) or return NXDomain. This test exposes whether ${r.name} is giving you genuine IP addresses or hijacked censorship results.',
                        explanation:
                            'DNS poisoning occurs when an ISP or firewall intercepts DNS lookups and injects falsified IP records before the authentic server can answer.',
                      ),
                    ),
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
                    onTap: () => _openProfile(
                      context,
                      ItemProfileInfo(
                        id: d.host,
                        category: ItemCategory.domain,
                        title: '${d.short.toUpperCase()} (${d.host})',
                        subtitle:
                            'HTTPS Website Probe · https://${d.host}/',
                        tag: d.short,
                        hostOrIp: d.host,
                        sni: d.host,
                        port: 443,
                        networkType: 'HTTPS Web Destination',
                        whatItTests:
                            'Continuously checks DNS resolution, TCP socket connection to port 443, TLS certificate validation, and HTTP response codes for ${d.host}.',
                        whyItMatters:
                            'Tells you instantly whether ${d.host} is reachable through your current network or VPN tunnel, and isolates whether any failure is due to DNS poisoning, TCP reset injection, SNI filtering, or server timeout.',
                      ),
                    ),
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
