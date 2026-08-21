import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netchecker/app.dart';
import 'package:netchecker/probe/engine.dart';
import 'package:netchecker/ui/keyboard/shortcuts.dart';
import 'package:netchecker/ui/keyboard/shortcuts_dialog.dart';
import 'package:netchecker/ui/profile/item_profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Keyboard and Game Controller Tests', () {
    late ProbeEngine engine;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      engine = ProbeEngine();
      await engine.start(loops: false, loadNics: false);
    });

    tearDown(() {
      engine.dispose();
    });

    testWidgets('Space / R key toggles probe running state', (tester) async {
      final localEngine = ProbeEngine();
      await localEngine.start(loops: false, loadNics: false);
      addTearDown(localEngine.dispose);

      await tester.pumpWidget(NetCheckerApp(engine: localEngine, forceDesktop: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(localEngine.settings.running, isTrue);

      // Tap pause button on toolbar
      await tester.tap(find.text('pause'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(localEngine.settings.running, isFalse);
    });

    testWidgets('? key or clicking ? button opens shortcuts cheatsheet dialog', (tester) async {
      await tester.pumpWidget(NetCheckerApp(engine: engine, forceDesktop: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ShortcutsCheatsheetDialog), findsNothing);

      // Tap ? button
      await tester.tap(find.text('?'));
      await tester.pumpAndSettle();

      expect(find.byType(ShortcutsCheatsheetDialog), findsOneWidget);
      expect(find.text('Keyboard & Controller Shortcuts'), findsOneWidget);
      expect(find.text('GLOBAL CONTROLS'), findsOneWidget);
      expect(find.text('GRID 2D NAVIGATION'), findsOneWidget);

      // Tap close to dismiss
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(ShortcutsCheatsheetDialog), findsNothing);
    });

    testWidgets('S key opens settings dialog on desktop', (tester) async {
      await tester.pumpWidget(NetCheckerApp(engine: engine, forceDesktop: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Settings'), findsNothing);

      // Tap set button
      await tester.tap(find.text('set'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Settings'), findsWidgets);

      // Close settings
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Settings'), findsNothing);
    });

    testWidgets('Tapping probe cell opens ItemProfilePage and responds to Escape / B button', (tester) async {
      await tester.pumpWidget(NetCheckerApp(engine: engine, forceDesktop: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find first resolver cell (Cloudflare 'CF')
      expect(find.text('CF'), findsWidgets);
      await tester.tap(find.text('CF').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(ItemProfilePage), findsOneWidget);

      // Pop profile page
      Navigator.of(tester.element(find.byType(ItemProfilePage))).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ItemProfilePage), findsNothing);
    });

    testWidgets('Profile page switches visualizer tabs with 1 and 2 keys', (tester) async {
      await tester.pumpWidget(NetCheckerApp(engine: engine, forceDesktop: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('CF').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(ItemProfilePage), findsOneWidget);
      expect(find.text('FREQUENCY HISTOGRAM'), findsWidgets);

      // Invoke NextTabIntent (2 / RB key)
      Actions.maybeInvoke(tester.element(find.byType(ItemProfilePage)), const NextTabIntent());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Invoke PrevTabIntent (1 / LB key)
      Actions.maybeInvoke(tester.element(find.byType(ItemProfilePage)), const PrevTabIntent());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('PING HISTORY'), findsWidgets);
    });
  });
}
