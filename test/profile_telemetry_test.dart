import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netchecker/app.dart';
import 'package:netchecker/probe/engine.dart';
import 'package:netchecker/probe/models.dart';
import 'package:netchecker/ui/profile/item_profile_page.dart';
import 'package:netchecker/ui/profile/latency_chart.dart';
import 'package:netchecker/ui/profile/waterfall_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ItemMetrics calculation', () {
    test('calculates correct metrics from samples', () {
      final now = DateTime.now();
      final samples = [
        ProbeSample(timestamp: now.subtract(const Duration(seconds: 40)), status: HitStatus.ok, ms: 50),
        ProbeSample(timestamp: now.subtract(const Duration(seconds: 30)), status: HitStatus.ok, ms: 70),
        ProbeSample(timestamp: now.subtract(const Duration(seconds: 20)), status: HitStatus.ok, ms: 60),
        ProbeSample(timestamp: now.subtract(const Duration(seconds: 10)), status: HitStatus.fail, detail: 'rst'),
      ];

      final metrics = ItemMetrics.fromSamples(samples);
      expect(metrics.totalChecks, 4);
      expect(metrics.okCount, 3);
      expect(metrics.failCount, 1);
      expect(metrics.uptimePercent, 75.0);
      expect(metrics.minMs, 50);
      expect(metrics.maxMs, 70);
      expect(metrics.avgMs, 60.0);
      expect(metrics.jitterMs, 15.0); // (|70-50| + |60-70|) / 2 = (20 + 10) / 2 = 15
      expect(metrics.isClean, false);
      expect(metrics.filterStatus, contains('TCP Reset'));
    });

    test('detects DNS poisoning anomaly', () {
      final sample = ProbeSample(
        timestamp: DateTime.now(),
        status: HitStatus.fail,
        ms: 15,
        detail: '10.10.34.34',
        phase: const PhaseBreakdown(
          dnsMs: 15,
          resolvedIps: ['10.10.34.34'],
          anomaly: 'DNS Poisoning (Gov Sinkhole 10.10.34.34)',
        ),
      );

      final metrics = ItemMetrics.fromSamples([sample]);
      expect(metrics.isClean, false);
      expect(metrics.filterStatus, contains('DNS Poisoning'));
    });

    test('ProbeEngine stores history and returns metrics', () async {
      SharedPreferences.setMockInitialValues({});
      final engine = ProbeEngine();
      await engine.start(loops: false, loadNics: false);
      addTearDown(engine.dispose);

      final info = const ItemProfileInfo(
        id: 'example.com',
        category: ItemCategory.domain,
        title: 'example.com',
      );

      expect(engine.getHistory('example.com'), isEmpty);
      expect(engine.getMetrics('example.com').totalChecks, 0);
    });
  });

  group('ItemProfilePage Widget & Navigation', () {
    testWidgets('Tapping domain cell navigates to modern profile page', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final engine = ProbeEngine();
      await engine.start(loops: false, loadNics: false);
      addTearDown(engine.dispose);

      // Pump app
      await tester.pumpWidget(NetCheckerApp(engine: engine, forceDesktop: false));
      await tester.pump();

      // Find youtube.com cell on board
      final ytFinder = find.text('youtube');
      expect(ytFinder, findsOneWidget);

      // Tap on youtube cell
      await tester.tap(ytFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify we are on ItemProfilePage
      expect(find.byType(ItemProfilePage), findsOneWidget);
      expect(find.text('HTTPS DOMAIN'), findsWidgets);
      expect(find.text('youtube.com'), findsWidgets);
      expect(find.text('LATENCY TIMELINE'), findsOneWidget);
      expect(find.text('CONNECTION WATERFALL & PHASES'), findsOneWidget);
      expect(find.text('TECHNICAL SPECIFICATIONS & DIAGNOSTICS'), findsOneWidget);
      expect(find.text('RECENT PROBES AUDIT'), findsOneWidget);
      expect(find.text('Run Deep Diagnostics'), findsOneWidget);
      expect(find.text('Auto-Ping'), findsOneWidget);

      // Verify charts & cards exist
      expect(find.byType(ItemLatencyChart), findsOneWidget);
      expect(find.byType(ConnectionWaterfallCard), findsOneWidget);

      // Test tapping back button
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(ItemProfilePage), findsNothing);
    });

    testWidgets('Tapping DNS resolver cell opens DNS profile', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final engine = ProbeEngine();
      await engine.start(loops: false, loadNics: false);
      addTearDown(engine.dispose);

      await tester.pumpWidget(NetCheckerApp(engine: engine, forceDesktop: false));
      await tester.pump();

      final cfFinder = find.text('CF');
      expect(cfFinder, findsWidgets);

      await tester.tap(cfFinder.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ItemProfilePage), findsOneWidget);
      expect(find.text('DNS RESOLVER SPEED'), findsWidgets);
      expect(find.textContaining('Cloudflare DNS'), findsOneWidget);
      expect(find.text('ABOUT THIS TEST & NETWORK ROLE'), findsOneWidget);
    });

    testWidgets('Tapping edge target and interacting with chart range selector', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final engine = ProbeEngine();
      await engine.start(loops: false, loadNics: false);
      addTearDown(engine.dispose);

      await tester.pumpWidget(NetCheckerApp(engine: engine, forceDesktop: false));
      await tester.pump();

      final edgeFinder = find.text('104.16');
      expect(edgeFinder, findsWidgets);

      await tester.tap(edgeFinder.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ItemProfilePage), findsOneWidget);
      expect(find.text('EDGE CDN ANYCAST IP'), findsWidgets);
      expect(find.text('ABOUT THIS TEST & NETWORK ROLE'), findsOneWidget);

      // Test chart range filter buttons
      expect(find.text('15'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('ALL'), findsOneWidget);

      await tester.ensureVisible(find.text('15'));
      await tester.tap(find.text('15'));
      await tester.pump();
      await tester.ensureVisible(find.text('ALL'));
      await tester.tap(find.text('ALL'));
      await tester.pump();

      // Verify switch exists
      final autoPingSwitch = find.byType(Switch);
      expect(autoPingSwitch, findsOneWidget);
    });

    testWidgets('Tapping proto target opens proto profile', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final engine = ProbeEngine();
      await engine.start(loops: false, loadNics: false);
      addTearDown(engine.dispose);

      await tester.pumpWidget(NetCheckerApp(engine: engine, forceDesktop: false));
      await tester.pump();

      final protoFinder = find.text('v4');
      expect(protoFinder, findsWidgets);

      await tester.tap(protoFinder.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ItemProfilePage), findsOneWidget);
      expect(find.text('CORE NETWORK PROTOCOL'), findsWidgets);
      expect(find.text('ABOUT THIS TEST & NETWORK ROLE'), findsOneWidget);
    });

    testWidgets('Tapping Hunt item opens crystal-clear DNS Poisoning profile', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final engine = ProbeEngine();
      await engine.start(loops: false, loadNics: false);
      addTearDown(engine.dispose);

      await tester.pumpWidget(NetCheckerApp(engine: engine, forceDesktop: false));
      await tester.pump();

      final odFinder = find.text('OD');
      expect(odFinder, findsWidgets);

      // Tap the second 'OD' which is in the HUNT row
      await tester.tap(odFinder.last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ItemProfilePage), findsOneWidget);
      expect(find.text('DNS POISONING DETECTOR'), findsWidgets);
      expect(find.textContaining('OpenDNS'), findsWidgets);
      expect(find.textContaining('DNS Poisoning Check'), findsOneWidget);
      expect(find.text('ABOUT THIS TEST & NETWORK ROLE'), findsOneWidget);
    });
  });
}
