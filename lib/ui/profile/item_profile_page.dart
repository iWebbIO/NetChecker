import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../probe/engine.dart';
import '../../probe/models.dart';
import '../../theme.dart';
import 'latency_chart.dart';
import 'waterfall_card.dart';

class ItemProfilePage extends StatefulWidget {
  const ItemProfilePage({
    super.key,
    required this.engine,
    required this.targetInfo,
  });

  final ProbeEngine engine;
  final ItemProfileInfo targetInfo;

  static Future<void> open(
    BuildContext context, {
    required ProbeEngine engine,
    required ItemProfileInfo targetInfo,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => ItemProfilePage(
          engine: engine,
          targetInfo: targetInfo,
        ),
      ),
    );
  }

  @override
  State<ItemProfilePage> createState() => _ItemProfilePageState();
}

class _ItemProfilePageState extends State<ItemProfilePage> {
  bool _isProbing = false;
  bool _liveMonitor = false;
  Timer? _liveTimer;
  PhaseBreakdown? _latestPhase;

  @override
  void initState() {
    super.initState();
    _loadInitialPhase();
  }

  void _loadInitialPhase() {
    final samples = widget.engine.getHistory(widget.targetInfo.id);
    for (final s in samples.reversed) {
      if (s.phase != null) {
        _latestPhase = s.phase;
        break;
      }
    }
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }

  void _toggleLiveMonitor(bool value) {
    setState(() => _liveMonitor = value);
    _liveTimer?.cancel();
    if (value) {
      _liveTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!_isProbing && mounted) {
          _triggerDeepProbe(silent: true);
        }
      });
      _triggerDeepProbe(silent: true);
    }
  }

  Future<void> _triggerDeepProbe({bool silent = false}) async {
    if (_isProbing) return;
    if (!silent) setState(() => _isProbing = true);
    try {
      final sample = await widget.engine.runDeepProbe(widget.targetInfo);
      if (mounted) {
        setState(() {
          if (sample.phase != null) {
            _latestPhase = sample.phase;
          }
        });
      }
    } finally {
      if (!silent && mounted) {
        setState(() => _isProbing = false);
      }
    }
  }

  Hit _getCurrentHit() {
    final id = widget.targetInfo.id;
    switch (widget.targetInfo.category) {
      case ItemCategory.domain:
        return widget.engine.domainHits[id] ?? Hit.idle;
      case ItemCategory.dns:
        return widget.engine.dnsHits[id] ?? Hit.idle;
      case ItemCategory.edge:
        return widget.engine.edgeHits[id] ?? Hit.idle;
      case ItemCategory.hunt:
        return widget.engine.huntHits[id] ?? Hit.idle;
      case ItemCategory.proto:
        return widget.engine.protoHits[id] ?? Hit.idle;
    }
  }

  Color _getStatusAccent(HitStatus status, bool isClean) {
    if (!isClean && status != HitStatus.idle) return kFail;
    switch (status) {
      case HitStatus.ok:
        return const Color(0xFF10B981);
      case HitStatus.timeout:
        return const Color(0xFFF59E0B);
      case HitStatus.fail:
        return kFail;
      case HitStatus.checking:
        return const Color(0xFF06B6D4);
      case HitStatus.idle:
        return kMute;
    }
  }

  Future<void> _copyReport(ItemMetrics metrics, List<ProbeSample> samples) async {
    final buf = StringBuffer();
    buf.writeln('=== NetChecker Diagnostic Profile ===');
    buf.writeln('Target: ${widget.targetInfo.title} (${widget.targetInfo.categoryLabel})');
    buf.writeln('ID/Host: ${widget.targetInfo.id}');
    buf.writeln('Timestamp: ${DateTime.now().toIso8601String()}');
    buf.writeln('NIC: ${widget.engine.nic.label} (${widget.engine.nic.address ?? "default"})');
    buf.writeln('Diagnosis: ${metrics.filterStatus}');
    buf.writeln('Uptime: ${metrics.uptimePercent.toStringAsFixed(1)}% (${metrics.okCount}/${metrics.totalChecks} OK)');
    buf.writeln('Latency: avg=${metrics.avgMs.toStringAsFixed(1)}ms min=${metrics.minMs}ms max=${metrics.maxMs}ms jitter=${metrics.jitterMs.toStringAsFixed(1)}ms');
    if (_latestPhase != null) {
      buf.writeln('Phases: DNS=${_latestPhase!.dnsMs ?? 0}ms TCP=${_latestPhase!.tcpMs ?? 0}ms TLS=${_latestPhase!.tlsMs ?? 0}ms HTTP=${_latestPhase!.httpMs ?? 0}ms (Status: ${_latestPhase!.httpStatusCode ?? "-"})');
      if (_latestPhase!.resolvedIps != null && _latestPhase!.resolvedIps!.isNotEmpty) {
        buf.writeln('Resolved IPs: ${_latestPhase!.resolvedIps!.join(", ")}');
      }
    }
    buf.writeln('Recent Samples:');
    for (final s in samples.reversed.take(10)) {
      buf.writeln('  ${s.timestamp.toIso8601String()} - ${s.status.name.toUpperCase()} (${s.ms ?? "-"}ms) ${s.detail ?? ""}');
    }
    await Clipboard.setData(ClipboardData(text: buf.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diagnostic summary copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.engine,
      builder: (context, _) {
        final currentHit = _getCurrentHit();
        final samples = widget.engine.getHistory(widget.targetInfo.id);
        final metrics = widget.engine.getMetrics(
          widget.targetInfo.id,
          currentHit: currentHit,
        );
        final accent = _getStatusAccent(currentHit.status, metrics.isClean);

        return Scaffold(
          backgroundColor: const Color(0xFF040207),
          appBar: AppBar(
            backgroundColor: const Color(0xFF040207),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            title: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x14FFFFFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x28FFFFFF)),
              ),
              child: Text(
                widget.targetInfo.categoryLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: kPaper,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      fontSize: 10,
                    ),
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Copy Diagnostic Report',
                icon: const Icon(Icons.copy_rounded, size: 18),
                onPressed: () => _copyReport(metrics, samples),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Hero Identity & Live Status Banner
                  _HeroBanner(
                    targetInfo: widget.targetInfo,
                    currentHit: currentHit,
                    metrics: metrics,
                    accentColor: accent,
                    isProbing: _isProbing,
                    liveMonitor: _liveMonitor,
                    onToggleLive: _toggleLiveMonitor,
                    onRunDeepProbe: () => _triggerDeepProbe(),
                  ),
                  const SizedBox(height: 16),

                  // 2. What Is This Test? (Clarification Hero Card)
                  _ClarificationCard(
                    targetInfo: widget.targetInfo,
                    currentHit: currentHit,
                    metrics: metrics,
                    accentColor: accent,
                  ),
                  const SizedBox(height: 16),

                  // 3. 4-Card KPI Telemetry Grid
                  _KpiMetricGrid(metrics: metrics, accentColor: accent),
                  const SizedBox(height: 16),

                  // 4. Interactive Latency Timeline Chart
                  ItemLatencyChart(
                    samples: samples,
                    accentColor: accent,
                    height: 170,
                  ),
                  const SizedBox(height: 16),

                  // 5. Multi-Phase Connection Waterfall
                  ConnectionWaterfallCard(
                    phase: _latestPhase,
                    targetInfo: widget.targetInfo,
                    isProbing: _isProbing,
                    onRunDeepProbe: () => _triggerDeepProbe(),
                  ),
                  const SizedBox(height: 16),

                  // 6. Technical Specifications Card
                  _TechnicalSpecsCard(
                    targetInfo: widget.targetInfo,
                    engine: widget.engine,
                    phase: _latestPhase,
                    metrics: metrics,
                  ),
                  const SizedBox(height: 16),

                  // 7. Recent Probes Audit Stream
                  _RecentAuditLog(samples: samples, accentColor: accent),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.targetInfo,
    required this.currentHit,
    required this.metrics,
    required this.accentColor,
    required this.isProbing,
    required this.liveMonitor,
    required this.onToggleLive,
    required this.onRunDeepProbe,
  });

  final ItemProfileInfo targetInfo;
  final Hit currentHit;
  final ItemMetrics metrics;
  final Color accentColor;
  final bool isProbing;
  final bool liveMonitor;
  final ValueChanged<bool> onToggleLive;
  final VoidCallback onRunDeepProbe;

  String _getDisplayTag() {
    if (targetInfo.tag != null && targetInfo.tag!.isNotEmpty) {
      return targetInfo.tag!;
    }
    final clean = targetInfo.title.replaceAll(RegExp(r'^(https?://|www\.)'), '');
    if (clean.length <= 3) return clean.toUpperCase();
    final parts = clean.split('.');
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 3 ? 3 : parts[0].length).toUpperCase();
    }
    return clean.substring(0, 2).toUpperCase();
  }

  String _getHumanStatusText() {
    if (currentHit.status == HitStatus.checking) {
      return 'PROBING TELEMETRY...';
    }
    if (currentHit.status == HitStatus.ok) {
      return 'REACHABLE · ${currentHit.ms ?? 0}ms';
    }
    if (currentHit.status == HitStatus.timeout) {
      return 'TIMEOUT · PACKET DROP';
    }
    if (currentHit.status == HitStatus.idle) {
      return 'IDLE · PENDING CHECK';
    }
    final detail = currentHit.detail ?? '';
    if (detail.contains('rst')) return 'BLOCKED · TCP RESET (RST)';
    if (detail.contains('tls') || detail.contains('hs')) return 'BLOCKED · TLS SNI FILTER';
    if (detail.contains('nx')) return 'FAILED · NXDOMAIN';
    if (detail.startsWith('10.10.34.') || detail == '185.88.153.235') {
      return 'POISONED · GOV SINKHOLE ($detail)';
    }
    return 'FAILED · $detail';
  }

  @override
  Widget build(BuildContext context) {
    final tag = _getDisplayTag();
    final statusText = _getHumanStatusText();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B0912),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.12),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Monogram / Tag Badge
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColor.withValues(alpha: 0.35),
                      const Color(0x08FFFFFF),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontFamily: 'Space Mono',
                      fontWeight: FontWeight.w700,
                      fontSize: tag.length > 2 ? 14 : 17,
                      color: accentColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title, Subtitle, and Type Tag
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      targetInfo.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: kPaper,
                            fontSize: 18,
                            height: 1.2,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      targetInfo.subtitle ?? targetInfo.id,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: kMute,
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Metadata Chips Row
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (targetInfo.networkType != null)
                _ChipPill(
                  label: targetInfo.networkType!,
                  color: const Color(0xFF8B5CF6),
                ),
              if (targetInfo.provider != null)
                _ChipPill(
                  label: targetInfo.provider!,
                  color: const Color(0xFF06B6D4),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Status Badge Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PulsingDot(color: accentColor),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Primary Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isProbing ? null : onRunDeepProbe,
                  icon: isProbing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: kInk,
                          ),
                        )
                      : const Icon(Icons.bolt, size: 18),
                  label: Text(
                    isProbing ? 'Probing...' : 'Run Deep Diagnostics',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPaper,
                    foregroundColor: kInk,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: liveMonitor
                        ? const Color(0xFF10B981).withValues(alpha: 0.5)
                        : const Color(0x1AFFFFFF),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  children: [
                    Text(
                      'Auto-Ping',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: liveMonitor ? const Color(0xFF10B981) : kMute,
                            fontSize: 11,
                          ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      height: 24,
                      width: 36,
                      child: Switch(
                        value: liveMonitor,
                        onChanged: onToggleLive,
                        activeColor: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChipPill extends StatelessWidget {
  const _ChipPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _ClarificationCard extends StatelessWidget {
  const _ClarificationCard({
    required this.targetInfo,
    required this.currentHit,
    required this.metrics,
    required this.accentColor,
  });

  final ItemProfileInfo targetInfo;
  final Hit currentHit;
  final ItemMetrics metrics;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final whatItTests = targetInfo.whatItTests ??
        'Continuously probes network reachability and response latency to this destination.';
    final whyItMatters = targetInfo.whyItMatters ??
        'Verifies whether this network component is reachable and operating without firewall interference.';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF09070E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x24FFFFFF), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.help_outline_rounded,
                color: Color(0xFF06B6D4),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'ABOUT THIS TEST & NETWORK ROLE',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: kPaper,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // What it tests section
          _ClarificationSection(
            title: 'What does this probe check?',
            content: whatItTests,
            icon: Icons.search_rounded,
            iconColor: const Color(0xFF06B6D4),
          ),
          const SizedBox(height: 12),

          // Why it matters section
          _ClarificationSection(
            title: 'Why is this important for your network?',
            content: whyItMatters,
            icon: Icons.lightbulb_outline_rounded,
            iconColor: const Color(0xFFF59E0B),
          ),

          // Optional extra explanation
          if (targetInfo.explanation != null &&
              targetInfo.explanation!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0x14FFFFFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x1EFFFFFF)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF8B5CF6),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      targetInfo.explanation!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: kPaper.withValues(alpha: 0.85),
                            fontSize: 11,
                            height: 1.35,
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

class _ClarificationSection extends StatelessWidget {
  const _ClarificationSection({
    required this.title,
    required this.content,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String content;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 6),
            Text(
              title,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: kPaper,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(
            content,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: kMute,
                  fontSize: 11.5,
                  height: 1.35,
                ),
          ),
        ),
      ],
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});

  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _ctrl.stop();
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final scale = 1.0 + (_ctrl.value * 0.35);
        final opacity = 0.4 + (_ctrl.value * 0.6);
        return Container(
          width: 8 * scale,
          height: 8 * scale,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: opacity),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.8),
                blurRadius: 6 * scale,
                spreadRadius: 1 * scale,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KpiMetricGrid extends StatelessWidget {
  const _KpiMetricGrid({required this.metrics, required this.accentColor});

  final ItemMetrics metrics;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final avgStr = metrics.avgMs > 0 ? '${metrics.avgMs.toStringAsFixed(0)} ms' : '-';
    final uptimeStr = metrics.totalChecks > 0
        ? '${metrics.uptimePercent.toStringAsFixed(0)}%'
        : '-';
    final jitterStr = metrics.jitterMs > 0
        ? '± ${metrics.jitterMs.toStringAsFixed(1)} ms'
        : '± 0 ms';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 500;
        return GridView.count(
          crossAxisCount: isWide ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: isWide ? 1.4 : 1.35,
          children: [
            _KpiCard(
              label: 'AVG LATENCY',
              value: avgStr,
              subtext: metrics.minMs > 0
                  ? 'Min ${metrics.minMs}ms · Max ${metrics.maxMs}ms'
                  : 'Based on recent samples',
              icon: Icons.timer_outlined,
              accentColor: accentColor,
            ),
            _KpiCard(
              label: 'REACHABILITY',
              value: uptimeStr,
              subtext: '${metrics.okCount} of ${metrics.totalChecks} successful',
              icon: Icons.verified_outlined,
              accentColor: metrics.uptimePercent > 80
                  ? const Color(0xFF10B981)
                  : (metrics.uptimePercent > 40
                      ? const Color(0xFFF59E0B)
                      : kFail),
            ),
            _KpiCard(
              label: 'JITTER VARIANCE',
              value: jitterStr,
              subtext: metrics.jitterMs < 10 ? 'Stable Connection' : 'High Deviation',
              icon: Icons.graphic_eq_rounded,
              accentColor: const Color(0xFF8B5CF6),
            ),
            _KpiCard(
              label: 'CENSORSHIP STATE',
              value: metrics.isClean ? 'Clean' : 'Anomaly',
              subtext: metrics.filterStatus,
              icon: metrics.isClean
                  ? Icons.shield_outlined
                  : Icons.gpp_bad_outlined,
              accentColor: metrics.isClean ? const Color(0xFF10B981) : kFail,
            ),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.subtext,
    required this.icon,
    required this.accentColor,
  });

  final String label;
  final String value;
  final String subtext;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF09070E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x14FFFFFF), width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: kMute,
                        fontWeight: FontWeight.w600,
                        fontSize: 9.5,
                        letterSpacing: 0.5,
                      ),
                ),
              ),
              Icon(icon, size: 16, color: accentColor),
            ],
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Space Mono',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: kPaper,
            ),
          ),
          Text(
            subtext,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: kMute.withValues(alpha: 0.8),
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }
}

class _TechnicalSpecsCard extends StatelessWidget {
  const _TechnicalSpecsCard({
    required this.targetInfo,
    required this.engine,
    required this.phase,
    required this.metrics,
  });

  final ItemProfileInfo targetInfo;
  final ProbeEngine engine;
  final PhaseBreakdown? phase;
  final ItemMetrics metrics;

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
          Text(
            'TECHNICAL SPECIFICATIONS & DIAGNOSTICS',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: kPaper,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
          ),
          const SizedBox(height: 12),
          _SpecRow(label: 'Target ID / Host', value: targetInfo.id),
          _SpecRow(
            label: 'Category',
            value: targetInfo.categoryLabel,
          ),
          if (targetInfo.provider != null)
            _SpecRow(
              label: 'Provider / Service',
              value: targetInfo.provider!,
            ),
          _SpecRow(
            label: 'Port & Protocol',
            value: '${targetInfo.port} (${targetInfo.category == ItemCategory.dns ? "UDP/DNS" : "TCP/TLS"})',
          ),
          _SpecRow(
            label: 'SNI Host Indication',
            value: targetInfo.sni ?? targetInfo.hostOrIp ?? targetInfo.title,
          ),
          _SpecRow(
            label: 'Bound Network NIC',
            value: engine.nic.label,
          ),
          if (phase?.resolvedIps != null && phase!.resolvedIps!.isNotEmpty)
            _SpecRow(
              label: 'Resolved Endpoint(s)',
              value: phase!.resolvedIps!.join(', '),
            ),
          _SpecRow(
            label: 'Heuristic Classification',
            value: metrics.filterStatus,
            isWarning: !metrics.isClean,
          ),
        ],
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({
    required this.label,
    required this.value,
    this.isWarning = false,
  });

  final String label;
  final String value;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: kMute,
                    fontSize: 11.5,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isWarning ? kFail : kPaper,
                    fontWeight: isWarning ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 11.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentAuditLog extends StatelessWidget {
  const _RecentAuditLog({required this.samples, required this.accentColor});

  final List<ProbeSample> samples;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final recent = samples.reversed.take(8).toList();

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RECENT PROBES AUDIT',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: kPaper,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
              ),
              Text(
                'Latest ${recent.length}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: kMute,
                      fontSize: 10,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Text(
                  'No historical samples logged yet',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: kMute,
                      ),
                ),
              ),
            )
          else
            for (final s in recent) ...[
              _AuditItemRow(sample: s, accentColor: accentColor),
            ],
        ],
      ),
    );
  }
}

class _AuditItemRow extends StatelessWidget {
  const _AuditItemRow({required this.sample, required this.accentColor});

  final ProbeSample sample;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${sample.timestamp.hour.toString().padLeft(2, '0')}:${sample.timestamp.minute.toString().padLeft(2, '0')}:${sample.timestamp.second.toString().padLeft(2, '0')}';
    final isOk = sample.status == HitStatus.ok;
    final statusColor = isOk ? accentColor : (sample.status == HitStatus.timeout ? const Color(0xFFF59E0B) : kFail);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            timeStr,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: kMute,
                  fontSize: 11,
                ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              sample.status.name.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 9.5,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              sample.detail != null && sample.detail!.isNotEmpty
                  ? sample.detail!
                  : (isOk ? '200 OK' : '-'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: kPaper,
                    fontSize: 11,
                  ),
            ),
          ),
          Text(
            sample.ms != null ? '${sample.ms}ms' : '-',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
          ),
        ],
      ),
    );
  }
}
