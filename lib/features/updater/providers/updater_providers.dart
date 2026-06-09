import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/updater_service.dart';

/// Instance unique du service de mise à jour.
final updaterServiceProvider = Provider<UpdaterService>((ref) {
  return UpdaterService();
});

/// Provider qui déclenche la vérification de mise à jour (paresseux).
///
/// La vérification n'est effectuée que lorsqu'un widget lit ce provider.
/// En cas d'échec (pas de réseau, etc.), la valeur est `null`.
final updateCheckProvider = FutureProvider<UpdateInfo?>((ref) async {
  final service = ref.read(updaterServiceProvider);
  return service.checkForUpdate();
});
