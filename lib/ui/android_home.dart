import 'package:flutter/material.dart';

import '../probe/engine.dart';
import '../theme.dart';
import 'board.dart';
import 'settings_form.dart';

class AndroidHome extends StatelessWidget {
  const AndroidHome({super.key, required this.engine});

  final ProbeEngine engine;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: engine,
      builder: (context, _) {
        final isRunning = engine.settings.running;
        final totalDomains = engine.domains.length;

        return Scaffold(
          backgroundColor: kInk,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Container(
              decoration: const BoxDecoration(
                color: kInk,
                border: Border(bottom: BorderSide(color: kLine, width: 1)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      // Brand & Live Pulse
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18181B),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: kLine),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isRunning ? kOk : kTo,
                                shape: BoxShape.circle,
                                boxShadow: isRunning
                                    ? [
                                        BoxShadow(
                                          color: kOk.withValues(alpha: 0.6),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'NetChecker',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                letterSpacing: -0.2,
                                color: kPaper,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Stat Badges
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _MetricPill(
                                label: '${engine.okCount} ok',
                                color: kOk,
                              ),
                              const SizedBox(width: 4),
                              _MetricPill(
                                label: '${engine.failCount} down',
                                color: engine.failCount > 0 ? kFail : kSubtle,
                              ),
                              const SizedBox(width: 4),
                              _MetricPill(
                                label: '${engine.checkedCount}/$totalDomains',
                                color: kMute,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Action Buttons
                      _ActionPill(
                        label: isRunning ? 'pause' : 'run',
                        icon: isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: isRunning ? kOk : kTo,
                        onTap: () => engine.setRunning(!isRunning),
                      ),
                      const SizedBox(width: 4),
                      _ActionPill(
                        label: 'copy',
                        icon: Icons.copy_rounded,
                        color: kPaper,
                        onTap: () => copyReport(context, engine),
                      ),
                      const SizedBox(width: 4),
                      _ActionPill(
                        label: 'set',
                        icon: Icons.tune_rounded,
                        color: kPaper,
                        onTap: () => _openSettings(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: SafeArea(
            child: ProbeBoard(engine: engine),
          ),
        );
      },
    );
  }

  Future<void> _openSettings(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFF0F0F12),
      barrierColor: const Color(0x99000000),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: kLine, width: 1),
      ),
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.sizeOf(ctx).height * 0.90,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Settings',
                          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Configure probe timers, targeting, and exports',
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                color: kMute,
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF18181B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: const BorderSide(color: kLine),
                        ),
                        padding: const EdgeInsets.all(6),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(child: SettingsForm(engine: engine)),
            ],
          ),
        );
      },
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Space Mono',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: kLine),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12.5, color: color),
            const SizedBox(width: 3.5),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Space Mono',
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
