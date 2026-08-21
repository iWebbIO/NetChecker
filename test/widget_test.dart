import 'package:flutter_test/flutter_test.dart';
import 'package:netchecker/app.dart';
import 'package:netchecker/probe/engine.dart';
import 'package:netchecker/ui/settings_form.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android home shows the instrument', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final engine = ProbeEngine();
    await engine.start(loops: false, loadNics: false);
    addTearDown(engine.dispose);

    await tester.pumpWidget(NetCheckerApp(engine: engine, forceDesktop: false));
    await tester.pump();

    expect(find.textContaining('NetChecker'), findsWidgets);
    expect(find.text('DNS'), findsOneWidget);
    expect(find.text('HUNT'), findsOneWidget);
    expect(find.text('set'), findsOneWidget);

    await tester.tap(find.text('set'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('HTTP timeout'), findsOneWidget);

    // Scroll to and verify Updates section in settings
    await tester.drag(find.byType(SettingsForm), const Offset(0, -1200));
    await tester.pumpAndSettle();

    expect(find.text('Updates'), findsOneWidget);
    expect(find.text('Check for Updates'), findsOneWidget);
  });
}
