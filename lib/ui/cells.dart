import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../probe/models.dart';
import '../theme.dart';
import 'keyboard/shortcuts.dart';

class ProbeCell extends StatefulWidget {
  const ProbeCell({
    super.key,
    required this.label,
    required this.hit,
    this.sub,
    this.live = false,
    this.wide = false,
    this.privacyMode = false,
    this.onCopy,
    this.onTap,
    this.onTraceroute,
  });

  final String label;
  final String? sub;
  final Hit hit;
  final bool live;
  final bool wide;
  final bool privacyMode;
  final String? onCopy;
  final VoidCallback? onTap;
  final VoidCallback? onTraceroute;

  @override
  State<ProbeCell> createState() => _ProbeCellState();
}

class _ProbeCellState extends State<ProbeCell> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
      if (_focusNode.hasFocus) {
        Scrollable.ensureVisible(
          context,
          alignment: 0.5,
          duration: const Duration(milliseconds: 150),
        );
      }
    }
  }

  Future<void> _copyContent() async {
    final text = widget.onCopy ?? '${widget.label} ${widget.hit.readout}';
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied: $text'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final inverted = widget.live && !reduce;
    final color = inverted ? kInk : statusColor(widget.hit.status);
    final pad = widget.wide
        ? const EdgeInsets.fromLTRB(8, 4, 8, 4)
        : const EdgeInsets.fromLTRB(6, 3, 6, 3);

    final minTap = !kIsWeb && Platform.isAndroid ? 48.0 : 0.0;

    String displayLabel = widget.label;
    if (widget.privacyMode) {
      if (widget.label.length <= 3) {
        displayLabel = '***';
      } else {
        displayLabel = '${widget.label[0]}***${widget.label[widget.label.length - 1]}';
      }
    }

    final isFail = widget.hit.status == HitStatus.fail;
    final isPoisoned = widget.hit.hasPrivateIp ||
        isPrivateOrPoisonedIp(widget.hit.detail) ||
        (widget.sub != null && isPrivateOrPoisonedIp(widget.sub));

    Border borderDecoration;
    if (_isFocused) {
      borderDecoration = isPoisoned
          ? Border.all(color: kPoison, width: 2.5)
          : Border.all(color: kPaper, width: 2.0);
    } else if (isPoisoned) {
      borderDecoration = Border.all(color: kPoison, width: 2.0);
    } else {
      borderDecoration = const Border(
        right: BorderSide(color: kLine, width: 1),
        bottom: BorderSide(color: kLine, width: 1),
      );
    }

    return FocusableActionDetector(
      focusNode: _focusNode,
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.select): const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.gameButtonA): const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.keyT): const TracerouteIntent(),
        const SingleActivator(LogicalKeyboardKey.gameButtonThumbRight): const TracerouteIntent(),
        const SingleActivator(LogicalKeyboardKey.keyC): const CopyReportIntent(),
        const SingleActivator(LogicalKeyboardKey.gameButtonThumbLeft): const CopyReportIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (widget.onTap != null) widget.onTap!();
            return null;
          },
        ),
        TracerouteIntent: CallbackAction<TracerouteIntent>(
          onInvoke: (_) {
            if (widget.onTraceroute != null) {
              widget.onTraceroute!();
            } else if (widget.onTap != null) {
              widget.onTap!();
            }
            return null;
          },
        ),
        CopyReportIntent: CallbackAction<CopyReportIntent>(
          onInvoke: (_) {
            _copyContent();
            return null;
          },
        ),
      },
      child: Semantics(
        button: true,
        label: '$displayLabel ${widget.hit.readout}${isPoisoned ? " (Poisoned Private IP)" : ""}',
        child: Material(
          color: inverted
              ? kLive
              : (_isFocused
                  ? const Color(0xFF27272A)
                  : (_isHovered ? const Color(0xFF18181B) : Colors.transparent)),
          child: InkWell(
            mouseCursor: widget.onTap != null
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            onTap: widget.onTap,
            onLongPress: widget.onCopy == null ? null : _copyContent,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minTap, minWidth: minTap),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                decoration: BoxDecoration(
                  border: borderDecoration,
                  boxShadow: _isFocused
                      ? [
                          BoxShadow(
                            color: (isPoisoned ? kPoison : kPaper).withValues(alpha: 0.25),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                  gradient: !inverted && isFail
                      ? RadialGradient(
                          center: Alignment.bottomRight,
                          radius: 1.15,
                          colors: [
                            const Color(0xFFEF4444).withValues(alpha: 0.38),
                            const Color(0xFFEF4444).withValues(alpha: 0.12),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        )
                      : null,
                ),
                child: Padding(
                  padding: pad,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: inverted ? kInk : kPaper,
                          fontWeight: widget.live ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),
                      Text(
                        widget.hit.readout,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: color),
                      ),
                      if (widget.sub != null && widget.sub!.isNotEmpty)
                        Text(
                          widget.sub!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: inverted
                                ? kInk
                                : (isPoisoned ? kPoison : kMute),
                            fontSize: 10,
                            fontWeight: isPoisoned
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StripLabel extends StatelessWidget {
  const StripLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: kInk,
      child: SizedBox(
        width: 44,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 10, 4, 0),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      ),
    );
  }
}
