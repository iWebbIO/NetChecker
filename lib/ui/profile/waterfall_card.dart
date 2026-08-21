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
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kLine, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF8B5CF6),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x998B5CF6),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'SPEED BREAKDOWN',
                style: TextStyle(
                  fontFamily: 'Space Mono',
                  color: kPaper,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (phase == null || phase!.totalMs == 0) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kLine),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.speed_outlined,
                    color: Color(0xFF8B5CF6),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'No speed breakdown yet',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: kPaper,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Tap "Ping Now" above to measure DNS, connection, and SSL speed.',
                          style: TextStyle(
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
                color: kFail.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kFail.withValues(alpha: 0.3), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: kFail, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Anomaly: ${phase!.anomaly!}',
                      style: const TextStyle(
                        fontFamily: 'Space Mono',
                        color: kFail,
                        fontSize: 11,
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
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 10,
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
              'Total Duration: ${phase.totalMs}ms',
              style: const TextStyle(
                fontFamily: 'Space Mono',
                color: kPaper,
                fontWeight: FontWeight.w600,
                fontSize: 10.5,
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
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Space Mono',
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isAlert ? kFail.withValues(alpha: 0.4) : kLine,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Center(
                child: Text(
                  index,
                  style: TextStyle(
                    fontFamily: 'Space Mono',
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 9.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: kPaper,
                      fontWeight: FontWeight.w500,
                      fontSize: 12.5,
                    ),
                  ),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Space Mono',
                      color: isAlert ? kFail : kMute,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isAlert
                    ? kFail.withValues(alpha: 0.15)
                    : color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isAlert
                      ? kFail.withValues(alpha: 0.3)
                      : color.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                '${ms}ms',
                style: TextStyle(
                  fontFamily: 'Space Mono',
                  color: isAlert ? kFail : color,
                  fontWeight: FontWeight.w700,
                  fontSize: 10.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
