import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'probe/engine.dart';
import 'theme.dart';
import 'ui/android_home.dart';
import 'ui/desktop_home.dart';

class NetCheckerApp extends StatelessWidget {
  const NetCheckerApp({super.key, required this.engine, this.forceDesktop});

  final ProbeEngine engine;
  final bool? forceDesktop;

  bool get _desktop {
    if (forceDesktop != null) return forceDesktop!;
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: engine,
      builder: (context, _) {
        return MaterialApp(
          title: 'NetChecker',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(compact: engine.settings.alwaysOnTop),
          themeMode: ThemeMode.dark,
          home: _desktop
              ? DesktopHome(engine: engine)
              : AndroidHome(engine: engine),
        );
      },
    );
  }
}
