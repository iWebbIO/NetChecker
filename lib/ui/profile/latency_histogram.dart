import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../probe/models.dart';
import '../../theme.dart';

class LatencyHistogramCard extends StatelessWidget {
  const LatencyHistogramCard({
    super.key,
    required this.samples,
    this.accentColor = kOk,
  });

  final List<ProbeSample> samples;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final validSamples = samples.where((s) => s.status == HitStatus.ok && s.ms != null).toList();
    final latencies = validSamples.map((s) => s.ms!).toList();

    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kLine, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'FREQUENCY HISTOGRAM',
                    style: TextStyle(
                      fontFamily: 'Space Mono',
                      color: kPaper,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Text(
                '${latencies.length} samples',
                style: const TextStyle(
                  fontFamily: 'Space Mono',
                  color: kMute,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (latencies.isEmpty)
            SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  'No latency data collected yet',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: kMute),
                ),
              ),
            )
          else
            _HistogramBars(latencies: latencies, accentColor: accentColor),
        ],
      ),
    );
  }
}

class _HistogramBars extends StatelessWidget {
  const _HistogramBars({
    required this.latencies,
    required this.accentColor,
  });

  final List<int> latencies;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final minVal = latencies.reduce(math.min);
    final maxVal = math.max(latencies.reduce(math.max), minVal + 10);
    final bucketCount = math.min(6, math.max(3, (maxVal - minVal) ~/ 15 + 1));
    final range = maxVal - minVal;
    final step = math.max(1, (range / bucketCount).ceil());

    final buckets = List.generate(bucketCount, (i) {
      final start = minVal + i * step;
      final end = (i == bucketCount - 1) ? maxVal + 1 : start + step;
      return _Bucket(
        start: start,
        end: end,
        count: 0,
      );
    });

    for (final ms in latencies) {
      for (final b in buckets) {
        if (ms >= b.start && ms < b.end) {
          b.count++;
          break;
        }
      }
    }

    final maxCount = buckets.map((b) => b.count).fold<int>(0, math.max);

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: buckets.map((b) {
          final ratio = maxCount == 0 ? 0.0 : (b.count / maxCount);
          final percent = (b.count / latencies.length) * 100;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${b.count}',
                    style: const TextStyle(
                      fontFamily: 'Space Mono',
                      fontSize: 9,
                      color: kMute,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: math.max(0.04, ratio),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                accentColor,
                                accentColor.withValues(alpha: 0.3),
                              ],
                            ),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.7),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${b.start}ms',
                    style: const TextStyle(
                      fontFamily: 'Space Mono',
                      fontSize: 8,
                      color: kMute,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${percent.round()}%',
                    style: TextStyle(
                      fontFamily: 'Space Mono',
                      fontSize: 8,
                      color: kMute.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Bucket {
  _Bucket({
    required this.start,
    required this.end,
    required this.count,
  });

  final int start;
  final int end;
  int count;
}
