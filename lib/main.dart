import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'probe/engine.dart';
import 'theme.dart';
import 'ui/desk_window.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final engine = ProbeEngine();

  if (!kIsWeb && Platform.isAndroid) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: kInk,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  await engine.start();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    await DeskWindow.setAlwaysOnTop(engine.settings.alwaysOnTop);
    await DeskWindow.setCompact(engine.settings.alwaysOnTop);
  }

  runApp(NetCheckerApp(engine: engine));
}
