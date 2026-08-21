import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  AppSettings({
    this.httpTimeoutMs = 3000,
    this.itemDelayMs = 400,
    this.dnsTimeoutMs = 2000,
    this.dnsDelayMs = 600,
    this.huntName = 'youtube.com',
    this.extraDomains = const [],
    this.useDefaultDomains = true,
    this.alwaysOnTop = false,
    this.nicId = 'any',
    this.running = true,
    this.privacyMode = false,
    this.maxRounds = 0,
    this.exportFormat = 'markdown',
  });

  final int httpTimeoutMs;
  final int itemDelayMs;
  final int dnsTimeoutMs;
  final int dnsDelayMs;
  final String huntName;
  final List<String> extraDomains;
  final bool useDefaultDomains;
  final bool alwaysOnTop;
  final String nicId;
  final bool running;
  final bool privacyMode;
  final int maxRounds;
  final String exportFormat;

  Duration get httpTimeout => Duration(milliseconds: httpTimeoutMs);
  Duration get itemDelay => Duration(milliseconds: itemDelayMs);
  Duration get dnsTimeout => Duration(milliseconds: dnsTimeoutMs);
  Duration get dnsDelay => Duration(milliseconds: dnsDelayMs);

  AppSettings copyWith({
    int? httpTimeoutMs,
    int? itemDelayMs,
    int? dnsTimeoutMs,
    int? dnsDelayMs,
    String? huntName,
    List<String>? extraDomains,
    bool? useDefaultDomains,
    bool? alwaysOnTop,
    String? nicId,
    bool? running,
    bool? privacyMode,
    int? maxRounds,
    String? exportFormat,
  }) {
    return AppSettings(
      httpTimeoutMs: httpTimeoutMs ?? this.httpTimeoutMs,
      itemDelayMs: itemDelayMs ?? this.itemDelayMs,
      dnsTimeoutMs: dnsTimeoutMs ?? this.dnsTimeoutMs,
      dnsDelayMs: dnsDelayMs ?? this.dnsDelayMs,
      huntName: huntName ?? this.huntName,
      extraDomains: extraDomains ?? this.extraDomains,
      useDefaultDomains: useDefaultDomains ?? this.useDefaultDomains,
      alwaysOnTop: alwaysOnTop ?? this.alwaysOnTop,
      nicId: nicId ?? this.nicId,
      running: running ?? this.running,
      privacyMode: privacyMode ?? this.privacyMode,
      maxRounds: maxRounds ?? this.maxRounds,
      exportFormat: exportFormat ?? this.exportFormat,
    );
  }

  static AppSettings fromPrefs(SharedPreferences p) {
    return AppSettings(
      httpTimeoutMs: p.getInt('httpTimeoutMs') ?? 3000,
      itemDelayMs: p.getInt('itemDelayMs') ?? 400,
      dnsTimeoutMs: p.getInt('dnsTimeoutMs') ?? 2000,
      dnsDelayMs: p.getInt('dnsDelayMs') ?? 600,
      huntName: p.getString('huntName') ?? 'youtube.com',
      extraDomains: p.getStringList('extraDomains') ?? const [],
      useDefaultDomains: p.getBool('useDefaultDomains') ?? true,
      alwaysOnTop: p.getBool('alwaysOnTop') ?? false,
      nicId: p.getString('nicId') ?? 'any',
      running: p.getBool('running') ?? true,
      privacyMode: p.getBool('privacyMode') ?? false,
      maxRounds: p.getInt('maxRounds') ?? 0,
      exportFormat: p.getString('exportFormat') ?? 'markdown',
    );
  }

  Future<void> save(SharedPreferences p) async {
    await p.setInt('httpTimeoutMs', httpTimeoutMs);
    await p.setInt('itemDelayMs', itemDelayMs);
    await p.setInt('dnsTimeoutMs', dnsTimeoutMs);
    await p.setInt('dnsDelayMs', dnsDelayMs);
    await p.setString('huntName', huntName);
    await p.setStringList('extraDomains', extraDomains);
    await p.setBool('useDefaultDomains', useDefaultDomains);
    await p.setBool('alwaysOnTop', alwaysOnTop);
    await p.setString('nicId', nicId);
    await p.setBool('running', running);
    await p.setBool('privacyMode', privacyMode);
    await p.setInt('maxRounds', maxRounds);
    await p.setString('exportFormat', exportFormat);
  }
}
