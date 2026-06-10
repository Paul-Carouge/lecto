import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:version/version.dart';
import 'package:open_filex/open_filex.dart';

class UpdateInfo {
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;
  final bool isAvailable;
  const UpdateInfo({
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.isAvailable,
  });
}

class UpdaterService {
  final Dio _dio;
  static const _owner = 'Paul-Carouge';
  static const _repo = 'lecto';

  /// Path of the last downloaded APK (used for installation).
  String? lastDownloadedPath;

  UpdaterService()
      : _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 10)));

  /// Checks if an update is available on GitHub.
  /// Returns [UpdateInfo] if a newer version exists, or `null` on error / up-to-date.
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await _dio.get(
        'https://api.github.com/repos/$_owner/$_repo/releases/latest',
        options: Options(
          headers: {
            'Accept': 'application/vnd.github.v3+json',
            'User-Agent': 'Lecto-App',
          },
        ),
      );

      final data = response.data as Map<String, dynamic>;
      final tagName = data['tag_name'] as String;
      final remoteVersion = tagName.replaceFirst(RegExp(r'^v'), '');

      // Compare versions using the `version` package
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = Version.parse(packageInfo.version);
      final latestVersion = Version.parse(remoteVersion);

      final isAvailable = latestVersion > currentVersion;
      final releaseNotes = (data['body'] as String?) ?? '';

      // Find the APK asset from the release assets list
      final assets =
          (data['assets'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final apkAsset = _findApkAsset(assets);
      if (apkAsset == null) return null;

      final downloadUrl = apkAsset['browser_download_url'] as String;

      return UpdateInfo(
        latestVersion: remoteVersion,
        downloadUrl: downloadUrl,
        releaseNotes: releaseNotes,
        isAvailable: isAvailable,
      );
    } catch (_) {
      return null;
    }
  }

  /// Finds an APK asset from the release assets list.
  Map<String, dynamic>? _findApkAsset(List<Map<String, dynamic>> assets) {
    // Try known APK name patterns
    for (final name in ['universal', 'app-release', 'lecto-']) {
      for (final asset in assets) {
        final assetName = asset['name'] as String? ?? '';
        if (assetName.contains(name) && assetName.endsWith('.apk')) {
          return asset;
        }
      }
    }
    // Fallback: first APK found
    for (final asset in assets) {
      if ((asset['name'] as String?)?.endsWith('.apk') == true) return asset;
    }
    return null;
  }

  /// Downloads the APK with progress reporting.
  ///
  /// [url] — direct download URL from the release asset.
  /// [fileName] — the APK file name (e.g. 'lecto-v1.2.3.apk').
  /// [onProgress] — callback receiving a 0.0–1.0 progress ratio.
  /// Returns the local file path on success, or `null` on failure.
  Future<String?> downloadApk(
    String url,
    String fileName, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      final dir = await getExternalStorageDirectory();
      if (dir == null) return null;

      // Go up from Android/data/…/files to cache (accessible by Package Installer)
      final parentPath = dir.parent.path;
      final cacheDir = Directory('$parentPath/cache');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      final filePath = '${cacheDir.path}/$fileName';

      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      lastDownloadedPath = filePath;
      return filePath;
    } catch (_) {
      return null;
    }
  }

  /// Opens the APK with the Android package installer.
  ///
  /// First tries a direct platform channel (more reliable);
  /// falls back to [OpenFilex] if the channel isn't registered.
  Future<bool> installApk(String filePath) async {
    try {
      const channel = MethodChannel('com.lecto.app/installer');
      await channel.invokeMethod('installApk', {'filePath': filePath});
      return true;
    } on MissingPluginException {
      // Fallback to open_filex if the native channel isn't registered
      try {
        await OpenFilex.open(
          filePath,
          type: 'application/vnd.android.package-archive',
        );
        return true;
      } catch (_) {
        return false;
      }
    } catch (_) {
      return false;
    }
  }
}
