import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// Résultat d'une vérification de mise à jour.
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

/// Service chargé de vérifier les nouvelles versions sur GitHub Releases.
///
/// Compare le tag de la dernière release (vX.Y.Z) avec la version actuelle
/// de l'application. Toutes les erreurs réseau sont capturées silencieusement
/// (retourne `null` en cas d'échec).
class UpdaterService {
  static const _repoApi =
      'https://api.github.com/repos/Paul-Carouge/lecto/releases/latest';
  static const _downloadBase =
      'https://github.com/Paul-Carouge/lecto/releases/download';

  /// Évite de lancer plusieurs vérifications durant une même session.
  bool _alreadyChecked = false;

  /// Vérifie si une mise à jour est disponible.
  ///
  /// Retourne [UpdateInfo] si la vérification a réussi,
  /// `null` en cas d'erreur réseau ou si déjà vérifié dans cette session.
  Future<UpdateInfo?> checkForUpdate() async {
    // Debounce : un seul check par session
    if (_alreadyChecked) return null;
    _alreadyChecked = true;

    PackageInfo packageInfo;
    try {
      packageInfo = await PackageInfo.fromPlatform();
    } catch (_) {
      // Impossible d'obtenir la version — on abandonne
      _alreadyChecked = false;
      return null;
    }

    final currentVersion = packageInfo.version; // ex: "1.4.0"

    http.Response response;
    try {
      response = await http.get(
        Uri.parse(_repoApi),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'Lecto-App',
        },
      );
    } catch (_) {
      // Pas de réseau ou timeout — pas de crash
      _alreadyChecked = false;
      return null;
    }

    if (response.statusCode != 200) {
      _alreadyChecked = false;
      return null;
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      _alreadyChecked = false;
      return null;
    }

    // Extraction du tag — ex: "v1.5.0"
    final tagName = json['tag_name'] as String?;
    if (tagName == null || !tagName.startsWith('v')) {
      _alreadyChecked = false;
      return null;
    }

    final latestVersion = tagName.substring(1); // enlève le 'v'

    // Comparaison sémantique simple
    final isAvailable = _compareVersions(latestVersion, currentVersion) > 0;

    // Corps de la release
    final releaseNotes = (json['body'] as String?) ?? '';

    // URL de téléchargement
    final downloadUrl =
        '$_downloadBase/$tagName/lecto-$tagName.apk';

    return UpdateInfo(
      latestVersion: latestVersion,
      downloadUrl: downloadUrl,
      releaseNotes: releaseNotes,
      isAvailable: isAvailable,
    );
  }

  /// Compare deux versions sémantiques "X.Y.Z".
  ///
  /// Retourne 1 si [a] > [b], -1 si [a] < [b], 0 si égal.
  int _compareVersions(String a, String b) {
    final aParts = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final bParts = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // Complète avec des 0 si les listes n'ont pas la même taille
    while (aParts.length < 3) aParts.add(0);
    while (bParts.length < 3) bParts.add(0);

    for (int i = 0; i < 3; i++) {
      if (aParts[i] > bParts[i]) return 1;
      if (aParts[i] < bParts[i]) return -1;
    }
    return 0;
  }

  /// Réinitialise le cache de session (utile pour les tests ou un check manuel).
  void resetSessionCache() {
    _alreadyChecked = false;
  }
}
