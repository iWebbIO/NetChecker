import 'package:flutter/material.dart';

import '../probe/engine.dart';
import '../theme.dart';
import 'board.dart';
import 'desk_window.dart';
import 'settings_form.dart';
import 'title_bar.dart';

class DesktopHome extends StatelessWidget {
  const DesktopHome({super.key, required this.engine});

  final ProbeEngine engine;

  Future<void> _pin(bool on) async {
    await engine.setAlwaysOnTop(on);
    await DeskWindow.setAlwaysOnTop(on);
    await DeskWindow.setCompact(on);
  }

  Future<void> _settings(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Settings',
      barrierColor: const Color(0x99000000),
      pageBuilder: (ctx, a, b) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: const Color(0xFF0C0A10),
            child: SizedBox(
              width: 360,
              height: MediaQuery.sizeOf(ctx).height,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Settings',
                            style: Theme.of(ctx).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close, size: 18),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: SettingsForm(
                      engine: engine,
                      showWindowControls: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: engine,
      builder: (context, _) {
        final compact = engine.settings.alwaysOnTop;
        return Material(
          color: kInk,
          child: Column(
            children: [
              DesktopToolbar(
                title:
                    'NetChecker  ${engine.okCount} ok  ${engine.failCount} down  ${engine.checkedCount}/${engine.domains.length}',
                alwaysOnTop: compact,
                running: engine.settings.running,
                nics: [for (final n in engine.nics) (n.id, n.label)],
                nicId: engine.settings.nicId,
                onToggleRun: () => engine.setRunning(!engine.settings.running),
                onTogglePin: () => _pin(!compact),
                onCopy: () => copyReport(context, engine),
                onSettings: () => _settings(context),
                onNic: engine.setNic,
              ),
              const Divider(height: 1),
              Expanded(
                child: ProbeBoard(engine: engine, compact: compact),
              ),
            ],
          ),
        );
      },
    );
  }
}
