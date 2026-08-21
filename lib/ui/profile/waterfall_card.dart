import 'package:flutter/material.dart';

import '../../probe/models.dart';
import '../../theme.dart';

class ConnectionWaterfallCard extends StatelessWidget {
  const ConnectionWaterfallCard({
    super.key,
    required this.phase,
    required this.targetInfo,
    required this.onRunDeepProbe,
    this.isProbing = false,
  });

  final PhaseBreakdown? phase;
  final ItemProfileInfo targetInfo;
  final VoidCallback onRunDeepProbe;
  final bool isProbing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF09070E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1FFFFFFF), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF8B5CF6),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x998B5CF6),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'SPEED BREAKDOWN',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: kPaper,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (phase == null || phase!.totalMs == 0) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0x0DFFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x14FFFFFF)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.speed_outlined,
                    color: Color(0xFF8B5CF6),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No speed breakdown yet',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: kPaper,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tap "Ping Now" above to measure DNS, connection, and SSL speed.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: kMute,
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Proportional Multi-color Bar
            _WaterfallProportionBar(phase: phase!),
            const SizedBox(height: 16),

            // Stepped Milestones
            if (phase!.dnsMs != null)
              _WaterfallStepRow(
                index: '1',
                name: 'DNS Lookup',
                ms: phase!.dnsMs!,
                color: const Color(0xFF06B6D4),
                detail: phase!.resolvedIps != null && phase!.resolvedIps!.isNotEmpty
                    ? 'Found IP: ${phase!.resolvedIps!.join(", ")}'
                    : 'Looked up domain',
                isAlert: phase!.anomaly != null && phase!.anomaly!.contains('DNS'),
              ),
            if (phase!.tcpMs != null)
              _WaterfallStepRow(
                index: '2',
                name: 'Connecting (TCP)',
                ms: phase!.tcpMs!,
                color: const Color(0xFF10B981),
                detail: 'Connected to port ${targetInfo.port}',
                isAlert: phase!.anomaly != null && phase!.anomaly!.contains('TCP'),
              ),
            if (phase!.tlsMs != null)
              _WaterfallStepRow(
                index: '3',
                name: 'Secure Handshake (SSL)',
                ms: phase!.tlsMs!,
                color: const Color(0xFF8B5CF6),
                detail: 'SSL encryption verified',
                isAlert: phase!.anomaly != null && phase!.anomaly!.contains('TLS'),
              ),
            if (phase!.httpMs != null || phase!.httpStatusCode != null)
              _WaterfallStepRow(
                index: '4',
                name: 'Response (HTTP)',
                ms: phase!.httpMs ?? 0,
                color: const Color(0xFFF59E0B),
                detail: phase!.httpStatusCode != null
                    ? 'HTTP Status ${phase!.httpStatusCode}'
                    : 'Response received',
                isAlert: phase!.httpStatusCode != null && phase!.httpStatusCode! >= 400,
              ),
          ],

          if (phase?.anomaly != null && phase!.anomaly!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kFail.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kFail.withValues(alpha: 0.4), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: kFail, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Anomaly: ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: kFail,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WaterfallProportionBar extends StatelessWidget {
  const _WaterfallProportionBar({required this.phase});

  final PhaseBreakdown phase;

  @override
  Widget build(BuildContext context) {
    final total = phase.totalMs <= 0 ? 1 : phase.totalMs;
    final dnsFlex = ((phase.dnsMs ?? 0) / total * 100).round().clamp(5, 85);
    final tcpFlex = ((phase.tcpMs ?? 0) / total * 100).round().clamp(5, 85);
    final tlsFlex = ((phase.tlsMs ?? 0) / total * 100).round().clamp(5, 85);
    final httpFlex = ((phase.httpMs ?? 0) / total * 100).round().clamp(5, 85);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                if (phase.dnsMs != null && phase.dnsMs! > 0)
                  Expanded(
                    flex: dnsFlex,
                    child: Container(color: const Color(0xFF06B6D4)),
                  ),
                if (phase.tcpMs != null && phase.tcpMs! > 0)
                  Expanded(
                    flex: tcpFlex,
                    child: Container(color: const Color(0xFF10B981)),
                  ),
                if (phase.tlsMs != null && phase.tlsMs! > 0)
                  Expanded(
                    flex: tlsFlex,
                    child: Container(color: const Color(0xFF8B5CF6)),
                  ),
                if (phase.httpMs != null && phase.httpMs! > 0)
                  Expanded(
                    flex: httpFlex,
                    child: Container(color: const Color(0xFFF59E0B)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Duration: ms',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: kPaper,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Row(
              children: [
                _LegendDot(color: const Color(0xFF06B6D4), label: 'DNS'),
                const SizedBox(width: 8),
                _LegendDot(color: const Color(0xFF10B981), label: 'TCP'),
                const SizedBox(width: 8),
                _LegendDot(color: const Color(0xFF8B5CF6), label: 'TLS'),
                const SizedBox(width: 8),
                _LegendDot(color: const Color(0xFFF59E0B), label: 'HTTP'),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: kMute,
                fontSize: 9,
              ),
        ),
      ],
    );
  }
}

class _WaterfallStepRow extends StatelessWidget {
  const _WaterfallStepRow({
    required this.index,
    required this.name,
    required this.ms,
    required this.color,
    required this.detail,
    this.isAlert = false,
  });

  final String index;
  final String name;
  final int ms;
  final Color color;
  final String detail;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0x0CFFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isAlert ? kFail.withValues(alpha: 0.5) : const Color(0x14FFFFFF),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withValues(alpha: 0.6)),
              ),
              child: Center(
                child: Text(
                  index,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: kPaper,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isAlert ? kFail : kMute,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isAlert
                    ? kFail.withValues(alpha: 0.2)
                    : color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'ms',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isAlert ? kFail : color,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
