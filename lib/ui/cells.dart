import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../probe/models.dart';
import '../theme.dart';

class ProbeCell extends StatelessWidget {
  const ProbeCell({
    super.key,
    required this.label,
    required this.hit,
    this.sub,
    this.live = false,
    this.wide = false,
    this.onCopy,
    this.onTap,
  });

  final String label;
  final String? sub;
  final Hit hit;
  final bool live;
  final bool wide;
  final String? onCopy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final inverted = live && !reduce;
    final color = inverted ? kInk : statusColor(hit.status);
    final pad = wide
        ? const EdgeInsets.fromLTRB(8, 4, 8, 4)
        : const EdgeInsets.fromLTRB(6, 3, 6, 3);

    final minTap = !kIsWeb && Platform.isAndroid ? 48.0 : 0.0;

    return Semantics(
      button: true,
      label: '$label ${hit.readout}',
      child: Material(
        color: inverted ? kLive : Colors.transparent,
        child: InkWell(
          mouseCursor: onTap != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onTap: onTap,
          onLongPress: onCopy == null
              ? null
              : () async {
                  await Clipboard.setData(ClipboardData(text: onCopy!));
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Copied')));
                  }
                },
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minTap, minWidth: minTap),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: kLine, width: 1),
                  bottom: BorderSide(color: kLine, width: 1),
                ),
              ),
              child: Padding(
                padding: pad,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: inverted ? kInk : kPaper,
                        fontWeight: live ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                    Text(
                      hit.readout,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: color),
                    ),
                    if (sub != null && sub!.isNotEmpty)
                      Text(
                        sub!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: inverted ? kInk : kMute,
                          fontSize: 10,
                        ),
                      ),
                  ],
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
