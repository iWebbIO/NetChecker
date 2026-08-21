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
    this.onHelp,
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
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    final compact = alwaysOnTop;
    return Container(
      height: compact ? 36 : 44,
      decoration: const BoxDecoration(
        color: kInk,
        border: Border(bottom: BorderSide(color: kLine, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Live Status Dot & Title
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: running ? kOk : kTo,
              shape: BoxShape.circle,
              boxShadow: running
                  ? [
                      BoxShadow(
                        color: kOk.withValues(alpha: 0.6),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: compact ? 11 : 12.5,
                letterSpacing: -0.2,
                color: kPaper,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // NIC Dropdown (if multiple)
          if (nics.length > 1)
            Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: kLine),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: nics.any((n) => n.$1 == nicId) ? nicId : 'any',
                  isDense: true,
                  icon: const Icon(Icons.arrow_drop_down_rounded, size: 16, color: kMute),
                  dropdownColor: const Color(0xFF18181B),
                  style: const TextStyle(
                    fontFamily: 'Space Mono',
                    fontSize: 10,
                    color: kPaper,
                  ),
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

          // Action Button Group
          _ActionButton(
            label: running ? 'pause' : 'run',
            icon: running ? Icons.pause_rounded : Icons.play_arrow_rounded,
            highlightColor: running ? kOk : kTo,
            onTap: onToggleRun,
          ),
          const SizedBox(width: 4),
          _ActionButton(
            label: alwaysOnTop ? 'unpin' : 'pin',
            icon: alwaysOnTop ? Icons.push_pin_rounded : Icons.push_pin_outlined,
            onTap: onTogglePin,
          ),
          const SizedBox(width: 4),
          _ActionButton(
            label: 'copy',
            icon: Icons.copy_rounded,
            onTap: onCopy,
          ),
          const SizedBox(width: 4),
          _ActionButton(
            label: 'set',
            icon: Icons.tune_rounded,
            onTap: onSettings,
          ),
          if (onHelp != null) ...[
            const SizedBox(width: 4),
            _ActionButton(
              label: '?',
              icon: Icons.keyboard_outlined,
              onTap: onHelp!,
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.highlightColor,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? highlightColor;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.highlightColor ?? kPaper;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: _hover
                ? const Color(0xFF27272A)
                : const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _hover ? kPaper.withValues(alpha: 0.3) : kLine,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 13, color: activeColor),
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Space Mono',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: activeColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
