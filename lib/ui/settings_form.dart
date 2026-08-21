import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/update_service.dart';
import '../probe/engine.dart';
import '../probe/models.dart';
import '../settings/app_settings.dart';
import '../theme.dart';
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

  String _appVersion = '1.0.0+1';
  bool _checkingUpdate = false;
  UpdateCheckResult? _updateResult;
  bool _downloading = false;
  double _downloadProgress = 0.0;
  String? _downloadStatusText;

  @override
  void initState() {
    super.initState();
    _draft = widget.engine.settings;
    _hunt = TextEditingController(text: _draft.huntName);
    _extra = TextEditingController(text: _draft.extraDomains.join('\n'));
    _initVersion();
  }

  Future<void> _initVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = info.buildNumber.isNotEmpty
              ? '${info.version}+${info.buildNumber}'
              : info.version;
        });
      }
    } catch (_) {
      // Keep default fallback
    }
  }

  Future<void> _checkUpdate() async {
    setState(() {
      _checkingUpdate = true;
      _updateResult = null;
      _downloadStatusText = null;
    });

    try {
      final res = await UpdateService.checkForUpdates(
        currentVersionOverride: _appVersion,
      );
      if (mounted) {
        setState(() {
          _updateResult = res;
          _checkingUpdate = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _checkingUpdate = false;
          _updateResult = UpdateCheckResult(
            currentVersion: _appVersion,
            isUpdateAvailable: false,
            errorMessage: 'Error: $e',
          );
        });
      }
    }
  }

  Future<void> _downloadAndInstall(ReleaseInfo release) async {
    final apk = release.apkAsset;
    if (apk == null) {
      await UpdateService.openUrl(release.htmlUrl);
      return;
    }

    setState(() {
      _downloading = true;
      _downloadProgress = 0.0;
      _downloadStatusText = 'Starting download...';
    });

    try {
      final file = await UpdateService.downloadApk(
        downloadUrl: apk.downloadUrl,
        onProgress: (received, total) {
          if (mounted && total > 0) {
            setState(() {
              _downloadProgress = received / total;
              final mbRec = (received / (1024 * 1024)).toStringAsFixed(1);
              final mbTot = (total / (1024 * 1024)).toStringAsFixed(1);
              _downloadStatusText = '$mbRec MB / $mbTot MB (${(_downloadProgress * 100).toInt()}%)';
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _downloading = false;
          _downloadStatusText = 'Download completed. Launching installer...';
        });
      }

      await UpdateService.installApk(file.path);
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _downloadStatusText = 'Download failed: $e';
        });
      }
    }
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
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Privacy Mode'),
          subtitle: const Text('Masks hostnames and IPs on the homescreen'),
          value: _draft.privacyMode,
          onChanged: (v) => setState(() {
            _draft = _draft.copyWith(privacyMode: v);
          }),
        ),
        const SizedBox(height: 8),
        Text(
          'Export Format',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        DropdownButton<String>(
          isExpanded: true,
          value: _draft.exportFormat,
          dropdownColor: const Color(0xFF0C0A10),
          items: const [
            DropdownMenuItem(value: 'markdown', child: Text('Markdown Table')),
            DropdownMenuItem(value: 'csv', child: Text('CSV Spreadsheet')),
            DropdownMenuItem(value: 'json', child: Text('JSON Report')),
            DropdownMenuItem(value: 'plaintext', child: Text('Plaintext Summary')),
          ],
          onChanged: (fmt) {
            if (fmt == null) return;
            setState(() => _draft = _draft.copyWith(exportFormat: fmt));
          },
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 16),
        Text('Updates', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        Text(
          'NetChecker v$_appVersion',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: kMute),
        ),
        const SizedBox(height: 4),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Auto-check for updates'),
          subtitle: const Text('Checks GitHub releases for new versions'),
          value: _draft.autoCheckUpdates,
          onChanged: (v) => setState(() {
            _draft = _draft.copyWith(autoCheckUpdates: v);
          }),
        ),
        const SizedBox(height: 8),
        _buildUpdateStatusCard(context),
        const SizedBox(height: 20),
        const Divider(height: 1),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            widget.engine.resetAllStats();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('All statistics and telemetry reset')),
            );
          },
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Reset All Statistics'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFEF4444),
            side: const BorderSide(color: Color(0x33EF4444)),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(onPressed: _save, child: const Text('Apply')),
      ],
    );
  }

  Widget _buildUpdateStatusCard(BuildContext context) {
    final isAndroid = !kIsWeb && Platform.isAndroid;

    if (_checkingUpdate) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF09070C),
          border: Border.all(color: kLine),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: kPaper),
            ),
            SizedBox(width: 10),
            Text(
              'Checking GitHub releases...',
              style: TextStyle(fontSize: 12, color: kPaper),
            ),
          ],
        ),
      );
    }

    if (_updateResult != null) {
      final res = _updateResult!;
      if (res.isUpdateAvailable && res.latestRelease != null) {
        final rel = res.latestRelease!;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF09070C),
            border: Border.all(color: kOk.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.new_releases_outlined, size: 16, color: kOk),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'New release: ${rel.tagName}',
                      style: const TextStyle(
                        fontFamily: 'Space Mono',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: kOk,
                      ),
                    ),
                  ),
                ],
              ),
              if (rel.name.isNotEmpty && rel.name != rel.tagName) ...[
                const SizedBox(height: 4),
                Text(
                  rel.name,
                  style: const TextStyle(fontSize: 12, color: kPaper),
                ),
              ],
              if (rel.body.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxHeight: 90),
                  padding: const EdgeInsets.all(6),
                  color: const Color(0x33000000),
                  child: SingleChildScrollView(
                    child: Text(
                      rel.body.trim(),
                      style: const TextStyle(
                        fontFamily: 'Space Mono',
                        fontSize: 10,
                        color: kMute,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              if (_downloading) ...[
                LinearProgressIndicator(
                  value: _downloadProgress > 0 ? _downloadProgress : null,
                  color: kOk,
                  backgroundColor: kLine,
                ),
                const SizedBox(height: 4),
                if (_downloadStatusText != null)
                  Text(
                    _downloadStatusText!,
                    style: const TextStyle(
                      fontFamily: 'Space Mono',
                      fontSize: 10,
                      color: kPaper,
                    ),
                  ),
              ] else ...[
                if (_downloadStatusText != null) ...[
                  Text(
                    _downloadStatusText!,
                    style: const TextStyle(fontSize: 11, color: kMute),
                  ),
                  const SizedBox(height: 6),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (isAndroid && rel.apkAsset != null)
                      FilledButton.icon(
                        onPressed: () => _downloadAndInstall(rel),
                        icon: const Icon(Icons.download, size: 14),
                        label: const Text('Download APK & Install'),
                        style: FilledButton.styleFrom(
                          backgroundColor: kOk,
                          foregroundColor: kInk,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: () => UpdateService.openUrl(rel.htmlUrl),
                      icon: const Icon(Icons.open_in_new, size: 14),
                      label: const Text('View on GitHub'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      } else if (res.errorMessage != null) {
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF09070C),
            border: Border.all(color: kFail.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, size: 16, color: kFail),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  res.errorMessage!,
                  style: const TextStyle(fontSize: 11, color: kMute),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 14),
                onPressed: _checkUpdate,
                tooltip: 'Retry',
              ),
            ],
          ),
        );
      } else {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF09070C),
            border: Border.all(color: kLine),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline, size: 16, color: kOk),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Up to date (${res.currentVersion})',
                  style: const TextStyle(fontSize: 12, color: kPaper),
                ),
              ),
              TextButton(
                onPressed: _checkUpdate,
                child: const Text('Check again', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        );
      }
    }

    return OutlinedButton.icon(
      onPressed: _checkUpdate,
      icon: const Icon(Icons.sync, size: 16),
      label: const Text('Check for Updates'),
      style: OutlinedButton.styleFrom(
        foregroundColor: kPaper,
        side: const BorderSide(color: kLine),
      ),
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
