import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- Intent Definitions ---

class ToggleRunIntent extends Intent {
  const ToggleRunIntent();
}

class OpenSettingsIntent extends Intent {
  const OpenSettingsIntent();
}

class CopyReportIntent extends Intent {
  const CopyReportIntent();
}

class TogglePinIntent extends Intent {
  const TogglePinIntent();
}

class ShowShortcutsHelpIntent extends Intent {
  const ShowShortcutsHelpIntent();
}

class EscapeIntent extends Intent {
  const EscapeIntent();
}

class TracerouteIntent extends Intent {
  const TracerouteIntent();
}

class NextTabIntent extends Intent {
  const NextTabIntent();
}

class PrevTabIntent extends Intent {
  const PrevTabIntent();
}

class PingNowIntent extends Intent {
  const PingNowIntent();
}

class ToggleAutoIntent extends Intent {
  const ToggleAutoIntent();
}

// --- Global Shortcut Key Mappings ---

Map<ShortcutActivator, Intent> buildGlobalShortcuts() {
  return <ShortcutActivator, Intent>{
    // 1. Toggle Run / Pause
    const SingleActivator(LogicalKeyboardKey.space): const ToggleRunIntent(),
    const SingleActivator(LogicalKeyboardKey.keyR): const ToggleRunIntent(),
    const SingleActivator(LogicalKeyboardKey.gameButtonX): const ToggleRunIntent(),
    const SingleActivator(LogicalKeyboardKey.mediaPlayPause): const ToggleRunIntent(),
    const SingleActivator(LogicalKeyboardKey.mediaPlay): const ToggleRunIntent(),
    const SingleActivator(LogicalKeyboardKey.mediaPause): const ToggleRunIntent(),

    // 2. Open Settings
    const SingleActivator(LogicalKeyboardKey.keyS): const OpenSettingsIntent(),
    const SingleActivator(LogicalKeyboardKey.comma, control: true): const OpenSettingsIntent(),
    const SingleActivator(LogicalKeyboardKey.comma, meta: true): const OpenSettingsIntent(),
    const SingleActivator(LogicalKeyboardKey.gameButtonY): const OpenSettingsIntent(),
    const SingleActivator(LogicalKeyboardKey.contextMenu): const OpenSettingsIntent(),
    const SingleActivator(LogicalKeyboardKey.info): const OpenSettingsIntent(),

    // 3. Copy Report
    const SingleActivator(LogicalKeyboardKey.keyC): const CopyReportIntent(),
    const SingleActivator(LogicalKeyboardKey.keyC, control: true): const CopyReportIntent(),
    const SingleActivator(LogicalKeyboardKey.keyC, meta: true): const CopyReportIntent(),
    const SingleActivator(LogicalKeyboardKey.gameButtonThumbLeft): const CopyReportIntent(),

    // 4. Toggle Pin Always-on-top (Desktop)
    const SingleActivator(LogicalKeyboardKey.keyP): const TogglePinIntent(),

    // 5. Help / Cheatsheet Dialog
    const SingleActivator(LogicalKeyboardKey.slash, shift: true): const ShowShortcutsHelpIntent(),
    const SingleActivator(LogicalKeyboardKey.question): const ShowShortcutsHelpIntent(),
    const SingleActivator(LogicalKeyboardKey.f1): const ShowShortcutsHelpIntent(),
    const SingleActivator(LogicalKeyboardKey.gameButtonSelect): const ShowShortcutsHelpIntent(),

    // 6. Escape / Back
    const SingleActivator(LogicalKeyboardKey.escape): const EscapeIntent(),
    const SingleActivator(LogicalKeyboardKey.gameButtonB): const EscapeIntent(),
    const SingleActivator(LogicalKeyboardKey.goBack): const EscapeIntent(),
  };
}

/// Helper widget that attaches global keyboard and gamepad bindings
/// and ignores single-key shortcuts when a text editable field has focus.
class AppShortcutsWrapper extends StatefulWidget {
  const AppShortcutsWrapper({
    super.key,
    required this.child,
    required this.onToggleRun,
    required this.onOpenSettings,
    required this.onCopyReport,
    required this.onShowHelp,
    this.onTogglePin,
    this.onEscape,
  });

  final Widget child;
  final VoidCallback onToggleRun;
  final VoidCallback onOpenSettings;
  final VoidCallback onCopyReport;
  final VoidCallback onShowHelp;
  final VoidCallback? onTogglePin;
  final VoidCallback? onEscape;

  @override
  State<AppShortcutsWrapper> createState() => _AppShortcutsWrapperState();
}

class _AppShortcutsWrapperState extends State<AppShortcutsWrapper> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'AppShortcuts');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  bool _isTextEditing(BuildContext context) {
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus == null) return false;
    final w = primaryFocus.context?.widget;
    return w is EditableText;
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: buildGlobalShortcuts(),
      child: Actions(
        actions: <Type, Action<Intent>>{
          ToggleRunIntent: CallbackAction<ToggleRunIntent>(
            onInvoke: (intent) {
              if (_isTextEditing(context)) return null;
              widget.onToggleRun();
              return true;
            },
          ),
          OpenSettingsIntent: CallbackAction<OpenSettingsIntent>(
            onInvoke: (_) {
              if (_isTextEditing(context)) return null;
              widget.onOpenSettings();
              return null;
            },
          ),
          CopyReportIntent: CallbackAction<CopyReportIntent>(
            onInvoke: (_) {
              if (_isTextEditing(context)) return null;
              widget.onCopyReport();
              return null;
            },
          ),
          TogglePinIntent: CallbackAction<TogglePinIntent>(
            onInvoke: (_) {
              if (_isTextEditing(context)) return null;
              if (widget.onTogglePin != null) widget.onTogglePin!();
              return null;
            },
          ),
          ShowShortcutsHelpIntent: CallbackAction<ShowShortcutsHelpIntent>(
            onInvoke: (_) {
              if (_isTextEditing(context)) return null;
              widget.onShowHelp();
              return null;
            },
          ),
          EscapeIntent: CallbackAction<EscapeIntent>(
            onInvoke: (_) {
              if (widget.onEscape != null) {
                widget.onEscape!();
              } else {
                FocusManager.instance.primaryFocus?.unfocus();
              }
              return null;
            },
          ),
        },
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          canRequestFocus: true,
          child: widget.child,
        ),
      ),
    );
  }
}
