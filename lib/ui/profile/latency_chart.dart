import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../probe/models.dart';
import '../../theme.dart';

class ItemLatencyChart extends StatefulWidget {
  const ItemLatencyChart({
    super.key,
    required this.samples,
    required this.accentColor,
    this.height = 180,
  });

  final List<ProbeSample> samples;
  final Color accentColor;
  final double height;

  @override
  State<ItemLatencyChart> createState() => _ItemLatencyChartState();
}

class _ItemLatencyChartState extends State<ItemLatencyChart> {
  int _range = 30;
  int? _scrubIndex;

  List<ProbeSample> get _filteredSamples {
    final valid = widget.samples
        .where((s) => s.status != HitStatus.idle)
        .toList();
    if (_range == 0 || valid.length <= _range) return valid;
    return valid.sublist(valid.length - _range);
  }

  @override
  Widget build(BuildContext context) {
    final samples = _filteredSamples;

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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.accentColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.accentColor.withValues(alpha: 0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PING HISTORY',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: kPaper,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                  ),
                ],
              ),
              const Spacer(),
              _RangeSelector(
                current: _range,
                onChanged: (r) => setState(() {
                  _range = r;
                  _scrubIndex = null;
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (samples.isEmpty)
            SizedBox(
              height: widget.height,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.show_chart,
                      color: kMute.withValues(alpha: 0.4),
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Waiting for probe telemetry...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: kMute,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            if (_scrubIndex != null &&
                _scrubIndex! >= 0 &&
                _scrubIndex! < samples.length) ...[
              _ScrubTooltip(
                sample: samples[_scrubIndex!],
                accentColor: widget.accentColor,
              ),
              const SizedBox(height: 6),
            ],
            SizedBox(
              height: widget.height,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onHorizontalDragStart: (details) =>
                        _updateScrub(details.localPosition.dx, constraints.maxWidth, samples.length),
                    onHorizontalDragUpdate: (details) =>
                        _updateScrub(details.localPosition.dx, constraints.maxWidth, samples.length),
                    onHorizontalDragEnd: (_) => setState(() => _scrubIndex = null),
                    onTapDown: (details) =>
                        _updateScrub(details.localPosition.dx, constraints.maxWidth, samples.length),
                    child: CustomPaint(
                      size: Size(constraints.maxWidth, widget.height),
                      painter: _SplineChartPainter(
                        samples: samples,
                        accentColor: widget.accentColor,
                        scrubIndex: _scrubIndex,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _updateScrub(double localX, double width, int count) {
    if (count <= 1 || width <= 0) return;
    final pct = (localX / width).clamp(0.0, 1.0);
    final idx = (pct * (count - 1)).round().clamp(0, count - 1);
    setState(() => _scrubIndex = idx);
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.current, required this.onChanged});

  final int current;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RangeButton(
            label: '15',
            active: current == 15,
            onTap: () => onChanged(15),
          ),
          _RangeButton(
            label: '30',
            active: current == 30,
            onTap: () => onChanged(30),
          ),
          _RangeButton(
            label: 'ALL',
            active: current == 0,
            onTap: () => onChanged(0),
          ),
        ],
      ),
    );
  }
}

class _RangeButton extends StatelessWidget {
  const _RangeButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: active ? kPaper : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: active ? kInk : kMute,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                fontSize: 10,
              ),
        ),
      ),
    );
  }
}

class _ScrubTooltip extends StatelessWidget {
  const _ScrubTooltip({required this.sample, required this.accentColor});

  final ProbeSample sample;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '::';
    final msStr = sample.ms != null ? 'ms' : sample.status.name;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x28FFFFFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            timeStr,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: kMute,
                  fontSize: 11,
                ),
          ),
          const SizedBox(width: 8),
          Text(
            msStr,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: sample.status == HitStatus.ok ? accentColor : kFail,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
          ),
          if (sample.detail != null && sample.detail!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              '()',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: kMute,
                    fontSize: 10,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SplineChartPainter extends CustomPainter {
  _SplineChartPainter({
    required this.samples,
    required this.accentColor,
    this.scrubIndex,
  });

  final List<ProbeSample> samples;
  final Color accentColor;
  final int? scrubIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;

    final latencies = samples.map((s) => (s.ms ?? (s.status == HitStatus.ok ? 10 : 1000)).toDouble()).toList();
    var maxVal = latencies.reduce(math.max);
    if (maxVal < 100) maxVal = 100;
    maxVal = (maxVal * 1.25).ceilToDouble();
    const minVal = 0.0;

    final width = size.width;
    final height = size.height;
    final topPad = 12.0;
    final bottomPad = 22.0;
    final chartHeight = height - topPad - bottomPad;

    final gridPaint = Paint()
      ..color = const Color(0x14FFFFFF)
      ..strokeWidth = 1;

    final textStyle = TextStyle(
      fontFamily: 'Space Mono',
      fontSize: 9,
      color: kMute.withValues(alpha: 0.5),
    );

    final gridSteps = 3;
    for (var i = 0; i <= gridSteps; i++) {
      final y = topPad + (chartHeight / gridSteps) * i;
      final val = (maxVal - (maxVal / gridSteps) * i).round();
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);

      final textSpan = TextSpan(text: '${val}ms', style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(width - textPainter.width - 2, y - 11));
    }

    if (samples.length == 1) {
      final y = topPad + chartHeight * (1 - (latencies.first / maxVal));
      final p = Offset(width / 2, y);
      canvas.drawCircle(p, 4, Paint()..color = accentColor);
      return;
    }

    final points = <Offset>[];
    final dx = width / (samples.length - 1);
    for (var i = 0; i < samples.length; i++) {
      final val = latencies[i].clamp(minVal, maxVal);
      final y = topPad + chartHeight * (1 - (val / maxVal));
      points.add(Offset(i * dx, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, topPad + chartHeight)
      ..lineTo(points.first.dx, topPad + chartHeight)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accentColor.withValues(alpha: 0.28),
          accentColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, topPad, width, chartHeight));

    canvas.drawPath(fillPath, fillPaint);

    final glowPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.45)
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, glowPaint);

    final linePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);

    for (var i = 0; i < points.length; i++) {
      final s = samples[i];
      final pt = points[i];
      final isLast = i == points.length - 1;
      final isScrubbed = scrubIndex == i;

      final dotColor = s.status == HitStatus.ok ? accentColor : kFail;
      final dotRadius = isScrubbed ? 6.0 : (isLast ? 4.5 : 2.5);

      canvas.drawCircle(pt, dotRadius, Paint()..color = dotColor);
      if (isLast || isScrubbed) {
        canvas.drawCircle(
          pt,
          dotRadius + 3,
          Paint()
            ..color = dotColor.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }

    if (scrubIndex != null && scrubIndex! >= 0 && scrubIndex! < points.length) {
      final targetPt = points[scrubIndex!];
      final crosshairPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..strokeWidth = 1.0;
      canvas.drawLine(
        Offset(targetPt.dx, topPad),
        Offset(targetPt.dx, topPad + chartHeight),
        crosshairPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SplineChartPainter oldDelegate) => true;
}
