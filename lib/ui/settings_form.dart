import 'package:flutter/material.dart';

import '../probe/engine.dart';
import '../probe/models.dart';
import '../settings/app_settings.dart';
import 'desk_window.dart';

class SettingsForm extends StatefulWidget {
  const SettingsForm({
    super.key,
    required this.engine,
    this.showWindowControls = false,
  });

  final ProbeEngine engine;
  final bool showWindowControls;

  @override
  State<SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<SettingsForm> {
  late final TextEditingController _hunt;
  late final TextEditingController _extra;
  late AppSettings _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.engine.settings;
    _hunt = TextEditingController(text: _draft.huntName);
    _extra = TextEditingController(text: _draft.extraDomains.join('\n'));
  }

  @override
  void dispose() {
    _hunt.dispose();
    _extra.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final extra = _extra.text
        .split(RegExp(r'[\s,]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    await widget.engine.apply(
      _draft.copyWith(
        huntName: _hunt.text.trim().isEmpty ? 'youtube.com' : _hunt.text.trim(),
        extraDomains: extra,
      ),
    );
    if (widget.showWindowControls) {
      await DeskWindow.setAlwaysOnTop(_draft.alwaysOnTop);
      await DeskWindow.setCompact(_draft.alwaysOnTop);
    }
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final nics = widget.engine.nics;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text('Timeouts', style: Theme.of(context).textTheme.titleSmall),
        _MsSlider(
          label: 'HTTP timeout',
          value: _draft.httpTimeoutMs,
          min: 500,
          max: 15000,
          onChanged: (v) => setState(() {
            _draft = _draft.copyWith(httpTimeoutMs: v);
          }),
        ),
        _MsSlider(
          label: 'Delay between sites',
          value: _draft.itemDelayMs,
          min: 0,
          max: 5000,
          onChanged: (v) => setState(() {
            _draft = _draft.copyWith(itemDelayMs: v);
          }),
        ),
        _MsSlider(
          label: 'DNS timeout',
          value: _draft.dnsTimeoutMs,
          min: 300,
          max: 8000,
          onChanged: (v) => setState(() {
            _draft = _draft.copyWith(dnsTimeoutMs: v);
          }),
        ),
        _MsSlider(
          label: 'Delay between DNS',
          value: _draft.dnsDelayMs,
          min: 0,
          max: 5000,
          onChanged: (v) => setState(() {
            _draft = _draft.copyWith(dnsDelayMs: v);
          }),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _hunt,
          decoration: const InputDecoration(
            labelText: 'Hunt name',
            hintText: 'youtube.com',
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Default top 30'),
          subtitle: const Text('Sites commonly filtered in Iran'),
          value: _draft.useDefaultDomains,
          onChanged: (v) => setState(() {
            _draft = _draft.copyWith(useDefaultDomains: v);
          }),
        ),
        TextField(
          controller: _extra,
          minLines: 4,
          maxLines: 8,
          decoration: const InputDecoration(
            labelText: 'Extra hosts',
            hintText: 'one host per line',
          ),
        ),
        if (widget.showWindowControls) ...[
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Always on top'),
            subtitle: const Text('Corner instrument while you test'),
            value: _draft.alwaysOnTop,
            onChanged: (v) => setState(() {
              _draft = _draft.copyWith(alwaysOnTop: v);
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'Network interface',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          DropdownButton<String>(
            isExpanded: true,
            value: nics.any((n) => n.id == _draft.nicId)
                ? _draft.nicId
                : NicChoice.any.id,
            dropdownColor: const Color(0xFF0C0A10),
            items: [
              for (final n in nics)
                DropdownMenuItem(value: n.id, child: Text(n.label)),
            ],
            onChanged: (id) {
              if (id == null) return;
              setState(() => _draft = _draft.copyWith(nicId: id));
            },
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(onPressed: _save, child: const Text('Apply')),
      ],
    );
  }
}

class _MsSlider extends StatelessWidget {
  const _MsSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              Expanded(child: Text(label)),
              Text('${value}ms', style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
        Slider(
          value: value.toDouble().clamp(min.toDouble(), max.toDouble()),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: ((max - min) / 100).round().clamp(1, 200),
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }
}
