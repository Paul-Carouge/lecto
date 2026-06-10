import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

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
  static const _repoApi =
      'https://api.github.com/repos/Paul-Carouge/lecto/releases/latest';
  static const _downloadBase =
      'https://github.com/Paul-Carouge/lecto/releases/download';

  Future<UpdateInfo?> checkForUpdate() async {
    PackageInfo packageInfo;
    try {
      packageInfo = await PackageInfo.fromPlatform();
    } catch (_) {
      return null;
    }

    final currentVersion = packageInfo.version;

    http.Response response;
    try {
      response = await http.get(
        Uri.parse(_repoApi),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'Lecto-App',
        },
      ).timeout(const Duration(seconds: 10));
    } catch (_) {
      return null;
    }

    if (response.statusCode == 403) {
      // Rate limited — still compare using tag fallback or just return null
      return null;
    }

    if (response.statusCode != 200) return null;

    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }

    final tagName = json['tag_name'] as String?;
    if (tagName == null || !tagName.startsWith('v')) return null;

    final latestVersion = tagName.substring(1);
    final isAvailable = _compareVersions(latestVersion, currentVersion) > 0;
    final releaseNotes = (json['body'] as String?) ?? '';
    final downloadUrl = '$_downloadBase/$tagName/lecto-$tagName.apk';

    return UpdateInfo(
      latestVersion: latestVersion,
      downloadUrl: downloadUrl,
      releaseNotes: releaseNotes,
      isAvailable: isAvailable,
    );
  }

  int _compareVersions(String a, String b) {
    final aParts = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final bParts = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    while (aParts.length < 3) aParts.add(0);
    while (bParts.length < 3) bParts.add(0);
    for (int i = 0; i < 3; i++) {
      if (aParts[i] > bParts[i]) return 1;
      if (aParts[i] < bParts[i]) return -1;
    }
    return 0;
  }
}
