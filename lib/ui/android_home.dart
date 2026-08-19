import 'package:flutter/material.dart';

import '../probe/engine.dart';
import 'board.dart';
import 'settings_form.dart';

class AndroidHome extends StatelessWidget {
  const AndroidHome({super.key, required this.engine});

  final ProbeEngine engine;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: engine,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 12,
            title: Text(
              'NetChecker  ${engine.okCount} ok  ${engine.failCount} down  ${engine.checkedCount}/${engine.domains.length}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              TextButton(
                onPressed: () => engine.setRunning(!engine.settings.running),
                child: Text(engine.settings.running ? 'pause' : 'run'),
              ),
              TextButton(
                onPressed: () => copyReport(context, engine),
                child: const Text('copy'),
              ),
              TextButton(
                onPressed: () => _openSettings(context),
                child: const Text('set'),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                const Divider(height: 1),
                Expanded(child: ProbeBoard(engine: engine)),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openSettings(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFF0C0A10),
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.sizeOf(ctx).height * 0.88,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Settings',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              const Divider(height: 1),
              Expanded(child: SettingsForm(engine: engine)),
            ],
          ),
        );
      },
    );
  }
}
