import 'package:flutter/material.dart';

import '../theme.dart';

class DesktopToolbar extends StatelessWidget {
  const DesktopToolbar({
    super.key,
    required this.title,
    required this.alwaysOnTop,
    required this.running,
    required this.nics,
    required this.nicId,
    required this.onToggleRun,
    required this.onTogglePin,
    required this.onCopy,
    required this.onSettings,
    required this.onNic,
  });

  final String title;
  final bool alwaysOnTop;
  final bool running;
  final List<(String id, String label)> nics;
  final String nicId;
  final VoidCallback onToggleRun;
  final VoidCallback onTogglePin;
  final VoidCallback onCopy;
  final VoidCallback onSettings;
  final ValueChanged<String> onNic;

  @override
  Widget build(BuildContext context) {
    final compact = alwaysOnTop;
    return ColoredBox(
      color: kInk,
      child: SizedBox(
        height: compact ? 28 : 32,
        child: Row(
          children: [
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontSize: compact ? 11 : 12),
              ),
            ),
            if (nics.length > 1)
              SizedBox(
                width: 168,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: nics.any((n) => n.$1 == nicId) ? nicId : 'any',
                    isDense: true,
                    isExpanded: true,
                    icon: Text(
                      '▾',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    dropdownColor: const Color(0xFF0C0A10),
                    style: Theme.of(context).textTheme.labelSmall,
                    items: [
                      for (final n in nics)
                        DropdownMenuItem(value: n.$1, child: Text(n.$2)),
                    ],
                    onChanged: (v) {
                      if (v != null) onNic(v);
                    },
                  ),
                ),
              ),
            _WordBtn(label: running ? 'pause' : 'run', onTap: onToggleRun),
            _WordBtn(label: alwaysOnTop ? 'unpin' : 'pin', onTap: onTogglePin),
            _WordBtn(label: 'copy', onTap: onCopy),
            _WordBtn(label: 'set', onTap: onSettings),
          ],
        ),
      ),
    );
  }
}

class _WordBtn extends StatefulWidget {
  const _WordBtn({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_WordBtn> createState() => _WordBtnState();
}

class _WordBtnState extends State<_WordBtn> {
  bool _hot = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hot = true),
      onExit: (_) => setState(() => _hot = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: ColoredBox(
          color: _hot ? const Color(0x22FFFFFF) : Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Text(
              widget.label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: kPaper),
            ),
          ),
        ),
      ),
    );
  }
}
