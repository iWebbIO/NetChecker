import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netchecker/app.dart';
import 'package:netchecker/export/report_export.dart';
import 'package:netchecker/probe/asn_lookup.dart';
import 'package:netchecker/probe/engine.dart';
import 'package:netchecker/probe/geoip.dart';
import 'package:netchecker/probe/models.dart';
import 'package:netchecker/probe/traceroute.dart';
import 'package:netchecker/theme.dart';
import 'package:netchecker/ui/cells.dart';
import 'package:netchecker/ui/profile/item_profile_page.dart';
import 'package:netchecker/ui/profile/latency_chart.dart';
import 'package:netchecker/ui/profile/latency_histogram.dart';
import 'package:netchecker/ui/profile/route_map_page.dart';
import 'package:netchecker/ui/profile/waterfall_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ItemMetrics calculation', () {
    test('calculates correct metrics from samples including stdDev and lossPercent', () {
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
      expect(metrics.lossPercent, 25.0);
      expect(metrics.minMs, 50);
      expect(metrics.maxMs, 70);
      expect(metrics.avgMs, 60.0);
      expect(metrics.jitterMs, 15.0);
      expect(metrics.stdDevMs, closeTo(8.16, 0.1));
      expect(metrics.isClean, false);
      expect(metrics.filterStatus, contains('Connection reset'));
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

      expect(engine.getHistory('example.com'), isEmpty);
      expect(engine.getMetrics('example.com').totalChecks, 0);
    });

    test('ProbeEngine stats reset clears history', () async {
      SharedPreferences.setMockInitialValues({});
      final engine = ProbeEngine();
      await engine.start(loops: false, loadNics: false);
      addTearDown(engine.dispose);

      engine.domainHits['test.com'] = const Hit(status: HitStatus.ok, ms: 35);
      engine.resetStats('test.com');
      expect(engine.domainHits['test.com'], isNull);

      engine.domainHits['a.com'] = const Hit(status: HitStatus.ok, ms: 20);
      engine.resetAllStats();
      expect(engine.domainHits, isEmpty);
    });
  });

  group('Network Intelligence: ASN, GeoIP, and Export', () {
    test('AsnLookup resolves known IP', () async {
      final asn = await AsnLookup.instance.lookup('1.1.1.1');
      expect(asn, isNotNull);
      expect(asn!.asn, 13335);
      expect(asn.holder, contains('Cloudflare'));
      expect(asn.label, 'AS13335 · Cloudflare, Inc.');
    });

    test('GeoIpService resolves known IP', () async {
      final geo = await GeoIpService.instance.lookup('8.8.8.8');
      expect(geo, isNotNull);
      expect(geo!.countryCode, 'US');
      expect(geo.city, 'Mountain View');
      expect(geo.flagEmoji, isNotEmpty);
      expect(geo.locationString, contains('Mountain View'));
    });

    test('ReportExport generates valid JSON, CSV, and Markdown', () async {
      SharedPreferences.setMockInitialValues({});
      final engine = ProbeEngine();
      await engine.start(loops: false, loadNics: false);
      addTearDown(engine.dispose);

      final jsonStr = ReportExport.generate(engine, format: ExportFormat.json);
      expect(jsonStr, contains('"tool": "NetChecker"'));
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(decoded.containsKey('summary'), isTrue);

      final csvStr = ReportExport.generate(engine, format: ExportFormat.csv);
      expect(csvStr, startsWith('ID,Title,Category,Status'));

      final mdStr = ReportExport.generate(engine, format: ExportFormat.markdown);
      expect(mdStr, contains('# NetChecker Diagnostic Report'));
      expect(mdStr, contains('| Item | Type | Status |'));
    });

    test('TracerouteEngine emits initial hop structure', () async {
      final stream = TracerouteEngine.instance.trace('1.1.1.1');
      final firstRes = await stream.first;
      expect(firstRes.target, '1.1.1.1');
      expect(firstRes.hops, isNotNull);
    });
  });

  group('ItemProfilePage Widget & Navigation', () {
    testWidgets('Tapping domain cell navigates to modern profile page', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final engine = ProbeEngine();
      await engine.start(loops: false, loadNics: false);
      addTearDown(engine.dispose);

      await tester.pumpWidget(NetCheckerApp(engine: engine, forceDesktop: false));
      await tester.pump();

      final ytFinder = find.text('youtube');
      expect(ytFinder, findsOneWidget);

      await tester.tap(ytFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ItemProfilePage), findsOneWidget);
      expect(find.text('Website'), findsWidgets);
      expect(find.text('youtube.com'), findsWidgets);
      expect(find.text('PING HISTORY'), findsWidgets);
      expect(find.text('SPEED BREAKDOWN'), findsOneWidget);
      expect(find.text('DETAILS'), findsOneWidget);
      expect(find.text('RECENT PINGS'), findsOneWidget);
      expect(find.text('Ping Now'), findsOneWidget);
      expect(find.text('Auto'), findsOneWidget);
      expect(find.text('Trace'), findsOneWidget);

      expect(find.byType(ItemLatencyChart), findsOneWidget);
      expect(find.byType(ConnectionWaterfallCard), findsOneWidget);

      // Switch to Latency Histogram tab
      await tester.tap(find.text('FREQUENCY HISTOGRAM'));
      await tester.pump();
      expect(find.byType(LatencyHistogramCard), findsOneWidget);

      // Switch back to Ping History tab
      await tester.tap(find.text('PING HISTORY').first);
      await tester.pump();
      expect(find.byType(ItemLatencyChart), findsOneWidget);

      // Test tapping back button
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
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
      expect(find.text('DNS Server'), findsWidgets);
      expect(find.text('Cloudflare'), findsOneWidget);
      expect(find.text('ABOUT THIS ITEM'), findsOneWidget);
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
      expect(find.text('CDN Server'), findsWidgets);
      expect(find.text('ABOUT THIS ITEM'), findsOneWidget);

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

      final autoPingSwitch = find.byType(Switch);
      expect(autoPingSwitch, findsOneWidget);
    });

    testWidgets('RouteMapPage renders header and hop timeline correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RouteMapPage(
            target: '1.1.1.1',
            title: 'Cloudflare DNS',
            autoStart: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('ROUTE MAP · TRACEROUTE'), findsOneWidget);
      expect(find.text('Cloudflare DNS'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    });
  });

  group('Private and DNS Poisoning IP Classification', () {
    test('identifies Iran TIC DNS poisoning IPs (10.10.34.0/24)', () {
      expect(isPrivateOrPoisonedIp('10.10.34.36'), isTrue);
      expect(isPrivateOrPoisonedIp('10.10.34.34'), isTrue);
      expect(isPrivateOrPoisonedIp('10.10.34.35'), isTrue);
      expect(isPrivateOrPoisonedIp('10.10.34.1'), isTrue);
      expect(isPrivateOrPoisonedIp('10.10.34.254'), isTrue);
    });

    test('identifies 198.18.0.0/16 and 198.18.0.0/15 benchmarking/filtering ranges', () {
      expect(isPrivateOrPoisonedIp('198.18.0.1'), isTrue);
      expect(isPrivateOrPoisonedIp('198.18.34.56'), isTrue);
      expect(isPrivateOrPoisonedIp('198.19.100.200'), isTrue);
      expect(isPrivateOrPoisonedIp('198.20.0.1'), isFalse);
    });

    test('identifies RFC 1918 private ranges and CGNAT', () {
      expect(isPrivateOrPoisonedIp('10.0.0.1'), isTrue);
      expect(isPrivateOrPoisonedIp('10.255.255.254'), isTrue);
      expect(isPrivateOrPoisonedIp('172.16.0.1'), isTrue);
      expect(isPrivateOrPoisonedIp('172.31.255.255'), isTrue);
      expect(isPrivateOrPoisonedIp('172.32.0.1'), isFalse);
      expect(isPrivateOrPoisonedIp('192.168.1.1'), isTrue);
      expect(isPrivateOrPoisonedIp('192.168.0.254'), isTrue);
      expect(isPrivateOrPoisonedIp('100.64.0.1'), isTrue);
      expect(isPrivateOrPoisonedIp('100.127.255.255'), isTrue);
      expect(isPrivateOrPoisonedIp('100.128.0.1'), isFalse);
      expect(isPrivateOrPoisonedIp('127.0.0.1'), isTrue);
      expect(isPrivateOrPoisonedIp('169.254.1.1'), isTrue);
    });

    test('identifies Iranian government filtering sinkholes and IPv6', () {
      expect(isPrivateOrPoisonedIp('185.88.153.235'), isTrue);
      expect(isPrivateOrPoisonedIp('185.88.153.236'), isTrue);
      expect(isPrivateOrPoisonedIp('185.88.153.1'), isFalse);
      expect(isPrivateOrPoisonedIp('::1'), isTrue);
      expect(isPrivateOrPoisonedIp('fc00::1'), isTrue);
      expect(isPrivateOrPoisonedIp('fe80::1'), isTrue);
    });

    test('does not flag normal public IPs as poisoned', () {
      expect(isPrivateOrPoisonedIp('1.1.1.1'), isFalse);
      expect(isPrivateOrPoisonedIp('8.8.8.8'), isFalse);
      expect(isPrivateOrPoisonedIp('142.250.180.14'), isFalse);
      expect(isPrivateOrPoisonedIp('104.16.132.229'), isFalse);
      expect(isPrivateOrPoisonedIp(null), isFalse);
      expect(isPrivateOrPoisonedIp(''), isFalse);
    });
  });

  group('ProbeCell Visual Border for Private / Poisoned IPs', () {
    testWidgets('renders 4-sided yellow border when private/poisoned IP is returned', (tester) async {
      const poisonedHit = Hit(
        status: HitStatus.fail,
        ms: 12,
        detail: '10.10.34.36',
        isPoisoned: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(compact: false),
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 100,
                height: 60,
                child: ProbeCell(
                  label: 'youtube',
                  hit: poisonedHit,
                  sub: '10.10.34.36',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Find the DecoratedBox in ProbeCell
      final decoratedBoxes = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
      bool foundYellowBorder = false;

      for (final db in decoratedBoxes) {
        final deco = db.decoration;
        if (deco is BoxDecoration && deco.border is Border) {
          final border = deco.border as Border;
          if (border.top.color == kPoison &&
              border.right.color == kPoison &&
              border.bottom.color == kPoison &&
              border.left.color == kPoison &&
              border.top.width == 2.0) {
            foundYellowBorder = true;
            break;
          }
        }
      }

      expect(foundYellowBorder, isTrue, reason: 'ProbeCell should have 4-sided yellow border when poisoned');
      expect(find.text('youtube'), findsOneWidget);
      expect(find.text('10.10.34.36'), findsWidgets);
    });

    testWidgets('renders standard 1-side border when normal hit is returned', (tester) async {
      const normalHit = Hit(
        status: HitStatus.ok,
        ms: 25,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(compact: false),
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 100,
                height: 60,
                child: ProbeCell(
                  label: 'google',
                  hit: normalHit,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final decoratedBoxes = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
      bool has4SidedYellow = false;

      for (final db in decoratedBoxes) {
        final deco = db.decoration;
        if (deco is BoxDecoration && deco.border is Border) {
          final border = deco.border as Border;
          if (border.top.color == kPoison) {
            has4SidedYellow = true;
          }
        }
      }

      expect(has4SidedYellow, isFalse);
      expect(find.text('google'), findsOneWidget);
      expect(find.text('25ms'), findsOneWidget);
    });
  });
}
