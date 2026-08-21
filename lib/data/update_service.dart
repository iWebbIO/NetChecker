import 'dart:convert';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ReleaseAsset {
  const ReleaseAsset({
    required this.name,
    required this.downloadUrl,
    required this.size,
    required this.contentType,
  });

  final String name;
  final String downloadUrl;
  final int size;
  final String contentType;

  factory ReleaseAsset.fromJson(Map<String, dynamic> json) {
    return ReleaseAsset(
      name: json['name'] as String? ?? '',
      downloadUrl: json['browser_download_url'] as String? ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
      contentType: json['content_type'] as String? ?? '',
    );
  }
}

class ReleaseInfo {
  const ReleaseInfo({
    required this.tagName,
    required this.name,
    required this.body,
    required this.htmlUrl,
    required this.assets,
    this.publishedAt,
  });

  final String tagName;
  final String name;
  final String body;
  final String htmlUrl;
  final List<ReleaseAsset> assets;
  final DateTime? publishedAt;

  factory ReleaseInfo.fromJson(Map<String, dynamic> json) {
    final assetList = (json['assets'] as List<dynamic>?)
            ?.map((e) => ReleaseAsset.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    DateTime? pubDate;
    if (json['published_at'] != null) {
      pubDate = DateTime.tryParse(json['published_at'] as String);
    }

    return ReleaseInfo(
      tagName: json['tag_name'] as String? ?? '',
      name: json['name'] as String? ?? (json['tag_name'] as String? ?? ''),
      body: json['body'] as String? ?? '',
      htmlUrl: json['html_url'] as String? ?? '',
      assets: assetList,
      publishedAt: pubDate,
    );
  }

  ReleaseAsset? get apkAsset {
    return assets.cast<ReleaseAsset?>().firstWhere(
          (a) => a != null && a.name.toLowerCase().endsWith('.apk'),
          orElse: () => null,
        );
  }

  ReleaseAsset? get windowsAsset {
    return assets.cast<ReleaseAsset?>().firstWhere(
          (a) =>
              a != null &&
              (a.name.toLowerCase().contains('windows') ||
                  a.name.toLowerCase().endsWith('.zip') ||
                  a.name.toLowerCase().endsWith('.exe')),
          orElse: () => null,
        );
  }

  ReleaseAsset? get linuxAsset {
    return assets.cast<ReleaseAsset?>().firstWhere(
          (a) =>
              a != null &&
              (a.name.toLowerCase().endsWith('.deb') ||
                  a.name.toLowerCase().endsWith('.rpm') ||
                  a.name.toLowerCase().contains('linux')),
          orElse: () => null,
        );
  }
}

class UpdateCheckResult {
  const UpdateCheckResult({
    required this.currentVersion,
    required this.isUpdateAvailable,
    this.latestRelease,
    this.errorMessage,
  });

  final String currentVersion;
  final bool isUpdateAvailable;
  final ReleaseInfo? latestRelease;
  final String? errorMessage;
}

class UpdateService {
  static const String defaultOwner = 'morewebs';
  static const String defaultRepo = 'netchecker';

  /// Compares two semver strings (e.g. `v1.0.0+1` or `1.2.0`).
  /// Returns `true` if [latest] is strictly newer than [current].
  static bool isNewerVersion(String current, String latest) {
    final curParsed = _parseVersion(current);
    final latParsed = _parseVersion(latest);

    // Compare core version parts [major, minor, patch, ...]
    final maxLen = curParsed.numbers.length > latParsed.numbers.length
        ? curParsed.numbers.length
        : latParsed.numbers.length;

    for (int i = 0; i < maxLen; i++) {
      final c = i < curParsed.numbers.length ? curParsed.numbers[i] : 0;
      final l = i < latParsed.numbers.length ? latParsed.numbers[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }

    // If core versions match, compare build numbers if present (e.g. +1 vs +2)
    if (latParsed.buildNumber != null && curParsed.buildNumber != null) {
      return latParsed.buildNumber! > curParsed.buildNumber!;
    }
    if (latParsed.buildNumber != null && curParsed.buildNumber == null) {
      return latParsed.buildNumber! > 0;
    }

    return false;
  }

  static _ParsedVersion _parseVersion(String raw) {
    // Strip leading 'v' or 'V' and spaces
    String cleaned = raw.trim();
    if (cleaned.startsWith('v') || cleaned.startsWith('V')) {
      cleaned = cleaned.substring(1).trim();
    }

    int? buildNum;
    if (cleaned.contains('+')) {
      final parts = cleaned.split('+');
      cleaned = parts[0];
      if (parts.length > 1) {
        buildNum = int.tryParse(parts[1]);
      }
    }

    // Strip pre-release suffix (e.g., -beta.1) from core numbers for clean comparison
    if (cleaned.contains('-')) {
      cleaned = cleaned.split('-')[0];
    }

    final segments = cleaned
        .split('.')
        .map((s) => int.tryParse(s) ?? 0)
        .toList();

    return _ParsedVersion(numbers: segments, buildNumber: buildNum);
  }

  /// Queries GitHub Releases for the latest release.
  static Future<UpdateCheckResult> checkForUpdates({
    String owner = defaultOwner,
    String repo = defaultRepo,
    String? currentVersionOverride,
    HttpClient? httpClient,
  }) async {
    String currentVersion = currentVersionOverride ?? '1.0.0';
    if (currentVersionOverride == null) {
      try {
        final pkg = await PackageInfo.fromPlatform();
        currentVersion = pkg.buildNumber.isNotEmpty
            ? '${pkg.version}+${pkg.buildNumber}'
            : pkg.version;
      } catch (_) {
        // Fallback for tests or unsupported environments
        currentVersion = '1.0.0+1';
      }
    }

    final client = httpClient ?? HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);

    try {
      final uri = Uri.parse('https://api.github.com/repos/$owner/$repo/releases/latest');
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, 'NetChecker-App');
      request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github.v3+json');

      final response = await request.close();
      if (response.statusCode == 200) {
        final bodyStr = await response.transform(utf8.decoder).join();
        final json = jsonDecode(bodyStr) as Map<String, dynamic>;
        final release = ReleaseInfo.fromJson(json);

        final newer = isNewerVersion(currentVersion, release.tagName);
        return UpdateCheckResult(
          currentVersion: currentVersion,
          isUpdateAvailable: newer,
          latestRelease: release,
        );
      } else if (response.statusCode == 404) {
        return UpdateCheckResult(
          currentVersion: currentVersion,
          isUpdateAvailable: false,
          errorMessage: 'No releases found on repository.',
        );
      } else {
        return UpdateCheckResult(
          currentVersion: currentVersion,
          isUpdateAvailable: false,
          errorMessage: 'GitHub API returned status ${response.statusCode}',
        );
      }
    } catch (e) {
      return UpdateCheckResult(
        currentVersion: currentVersion,
        isUpdateAvailable: false,
        errorMessage: 'Network error: $e',
      );
    } finally {
      if (httpClient == null) {
        client.close(force: true);
      }
    }
  }

  /// Downloads an APK to the temporary directory with progress tracking.
  static Future<File> downloadApk({
    required String downloadUrl,
    required void Function(int received, int total) onProgress,
    HttpClient? httpClient,
  }) async {
    final client = httpClient ?? HttpClient();
    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/netchecker-update.apk';
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      final uri = Uri.parse(downloadUrl);
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, 'NetChecker-App');
      final response = await request.close();

      if (response.statusCode != 200 && response.statusCode != 302 && response.statusCode != 301) {
        throw Exception('Download failed with status: ${response.statusCode}');
      }

      // Follow redirect if GitHub returned 302/301 for asset download
      HttpClientResponse actualResponse = response;
      if (response.statusCode == 301 || response.statusCode == 302) {
        final location = response.headers.value(HttpHeaders.locationHeader);
        if (location != null) {
          final redirectReq = await client.getUrl(Uri.parse(location));
          actualResponse = await redirectReq.close();
        }
      }

      final totalBytes = actualResponse.contentLength;
      int receivedBytes = 0;

      final sink = file.openWrite();
      await for (final chunk in actualResponse) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        onProgress(receivedBytes, totalBytes);
      }
      await sink.flush();
      await sink.close();

      return file;
    } finally {
      if (httpClient == null) {
        client.close(force: true);
      }
    }
  }

  /// Opens the downloaded APK file to initiate Android Package Installer.
  static Future<OpenResult> installApk(String filePath) async {
    return await OpenFilex.open(filePath);
  }

  /// Opens any URL in the system's default browser.
  static Future<bool> openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}

class _ParsedVersion {
  const _ParsedVersion({required this.numbers, this.buildNumber});
  final List<int> numbers;
  final int? buildNumber;
}