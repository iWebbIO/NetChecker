import 'package:flutter/material.dart';

import '../probe/engine.dart';
import '../theme.dart';
import 'board.dart';
import 'desk_window.dart';
import 'keyboard/shortcuts.dart';
import 'keyboard/shortcuts_dialog.dart';
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

  void _showHelp(BuildContext context) {
    ShortcutsCheatsheetDialog.show(context);
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
            color: const Color(0xFF0F0F12),
            child: Container(
              width: 380,
              height: MediaQuery.sizeOf(ctx).height,
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: kLine, width: 1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
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
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF18181B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                              side: const BorderSide(color: kLine),
                            ),
                            padding: const EdgeInsets.all(6),
                          ),
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
        return Builder(
          builder: (bCtx) {
            return AppShortcutsWrapper(
              onToggleRun: () => engine.setRunning(!engine.settings.running),
              onOpenSettings: () => _settings(bCtx),
              onCopyReport: () => copyReport(bCtx, engine),
              onTogglePin: () => _pin(!compact),
              onShowHelp: () => _showHelp(bCtx),
              child: Material(
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
                      onCopy: () => copyReport(bCtx, engine),
                      onSettings: () => _settings(bCtx),
                      onHelp: () => _showHelp(bCtx),
                      onNic: engine.setNic,
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ProbeBoard(engine: engine, compact: compact),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
