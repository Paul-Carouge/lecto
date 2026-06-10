import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:lecto/core/theme/themes.dart';
import 'package:lecto/core/theme/theme_provider.dart';
import 'package:lecto/core/database/providers.dart';
import 'package:lecto/features/updater/providers/updater_providers.dart';
import 'package:lecto/features/updater/widgets/update_dialog.dart';
import 'package:lecto/features/settings/providers/settings_providers.dart'
    hide isDarkModeProvider;

/// Paramètres de l'application — profil, thème, mises à jour, à propos.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _appVersion = '...';
  String _appBuildNumber = '...';
  final _nameController = TextEditingController();
  bool _nameInitialized = false;
  bool _nameModified = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = info.version;
        _appBuildNumber = info.buildNumber;
      });
    } catch (_) {
      setState(() {
        _appVersion = '1.0.0';
        _appBuildNumber = '1';
      });
    }
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    await ref.read(userNameProvider.notifier).setName(name);
    setState(() => _nameModified = false);
    if (context.mounted) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            name.isEmpty ? 'Nom effacé' : 'Nom enregistré',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentThemeOption = ref.watch(themeOptionProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);

    // Initialize name controller from provider on first build
    if (!_nameInitialized) {
      final savedName = ref.read(userNameProvider).valueOrNull ?? '';
      if (_nameController.text != savedName) {
        _nameController.text = savedName;
      }
      _nameInitialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Paramètres',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // ========== Section Profil ==========
          _SectionHeader(title: 'Profil'),
          const SizedBox(height: 10),

          // Profile card
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: colorScheme.primary.withValues(alpha: 0.12),
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            color: colorScheme.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nom d\'utilisateur',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Saisissez votre prénom pour personnaliser l\'accueil',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    onChanged: (value) {
                      final trimmed = value.trim();
                      final saved = ref.read(userNameProvider).valueOrNull ?? '';
                      final modified = trimmed != saved;
                      if (modified != _nameModified) {
                        setState(() => _nameModified = modified);
                      }
                    },
                    onSubmitted: (_) => _saveName(),
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'Votre prénom',
                      filled: true,
                      fillColor: colorScheme.onSurface.withValues(alpha: 0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      suffixIcon: _nameModified
                          ? IconButton(
                              icon: Icon(
                                Icons.check_circle_rounded,
                                color: colorScheme.primary,
                              ),
                              onPressed: _saveName,
                            )
                          : null,
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ========== Section Thème ==========
          _SectionHeader(title: 'Thème'),
          const SizedBox(height: 10),

          // Dark mode card
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: colorScheme.primary.withValues(alpha: 0.12),
                        ),
                        child: Icon(
                          isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          color: colorScheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mode sombre',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isDarkMode ? 'Thème sombre activé' : 'Thème clair activé',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isDarkMode,
                        onChanged: (value) {
                          HapticFeedback.lightImpact();
                          ref.read(isDarkModeProvider.notifier).setDarkMode(value);
                        },
                        activeColor: colorScheme.primary,
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, indent: 72, endIndent: 16),

                // Theme picker
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Palette de couleurs',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: AppThemeOption.values.map((option) {
                          final palette = ThemePalette.fromOption(option);
                          final isSelected = option == currentThemeOption;
                          return _ThemeCircle(
                            option: option,
                            palette: palette,
                            isSelected: isSelected,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              ref.read(themeOptionProvider.notifier).setTheme(option);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ========== Section Mise à jour ==========
          _SectionHeader(title: 'Mise à jour'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _SettingsTile(
              icon: Icons.system_update_rounded,
              title: 'Vérifier les mises à jour',
              subtitle: 'Rechercher une nouvelle version de Lecto',
              onTap: () => _checkForUpdate(context),
              colorScheme: colorScheme,
            ),
          ),

          const SizedBox(height: 28),

          // ========== Section À propos ==========
          _SectionHeader(title: 'À propos'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'Version',
                  subtitle: '$_appVersion ($_appBuildNumber)',
                  onTap: null,
                  colorScheme: colorScheme,
                ),
                const Divider(height: 1, indent: 72, endIndent: 16),
                _SettingsTile(
                  icon: Icons.favorite_outline_rounded,
                  title: 'Lecto',
                  subtitle: 'Votre carnet de lecture personnel',
                  onTap: null,
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ========== Section Données ==========
          _SectionHeader(title: 'Données'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.file_download_rounded,
                  title: 'Exporter les données',
                  subtitle: 'Sauvegarder vos données en JSON',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Exportation bientôt disponible !'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  colorScheme: colorScheme,
                ),
                const Divider(height: 1, indent: 72, endIndent: 16),
                _SettingsTile(
                  icon: Icons.file_upload_rounded,
                  title: 'Importer des données',
                  subtitle: 'Restaurer depuis un fichier de sauvegarde',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Importation bientôt disponible !'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  colorScheme: colorScheme,
                ),
                const Divider(height: 1, indent: 72, endIndent: 16),
                _SettingsTile(
                  icon: Icons.delete_forever_rounded,
                  title: 'Réinitialiser toutes les données',
                  subtitle: 'Effacer livres, sessions et objectifs',
                  onTap: () => _confirmReset(context),
                  iconColor: colorScheme.error,
                  titleColor: colorScheme.error,
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Footer
          Center(
            child: Text(
              'Lecto v$_appVersion',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkForUpdate(BuildContext context) async {
    HapticFeedback.lightImpact();
    final updaterService = ref.read(updaterServiceProvider);
    updaterService.resetSessionCache();
    try {
      final info = await updaterService.checkForUpdate();
      if (!context.mounted) return;
      if (info != null && info.isAvailable) {
        showUpdateDialog(context, info: info);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous avez déjà la dernière version !'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de vérifier les mises à jour.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _confirmReset(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Réinitialiser toutes les données ?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Cette action supprimera définitivement tous les livres, sessions de lecture, objectifs et recommandations. Cette opération est irréversible.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Annuler',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              HapticFeedback.lightImpact();
              Navigator.pop(ctx);
              final db = ref.read(databaseProvider);
              for (final book in db.getAllBooks()) {
                db.deleteBook(book.id);
              }
              for (final session in db.getAllSessions()) {
                db.deleteSession(session.id);
              }
              db.clearRecommendations();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Toutes les données ont été réinitialisées'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: Text(
              'Réinitialiser',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Section header widget
// ============================================================

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ============================================================
// Settings tile widget
// ============================================================

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;
  final ColorScheme colorScheme;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.iconColor,
    this.titleColor,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? colorScheme.primary;
    final effectiveTitleColor = titleColor ?? colorScheme.onSurface;

    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: effectiveIconColor.withValues(alpha: 0.12),
        ),
        child: Icon(icon, color: effectiveIconColor, size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: effectiveTitleColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
      trailing: onTap != null
          ? Icon(Icons.chevron_right_rounded, color: colorScheme.onSurface.withValues(alpha: 0.3), size: 20)
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

// ============================================================
// Theme picker circle widget
// ============================================================

class _ThemeCircle extends StatelessWidget {
  final AppThemeOption option;
  final ThemePalette palette;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCircle({
    required this.option,
    required this.palette,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.primary,
                border: Border.all(
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                  width: isSelected ? 3 : 0,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: palette.primary.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: isSelected
                  ? Icon(Icons.check_rounded, color: Colors.white, size: 22)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              palette.label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
