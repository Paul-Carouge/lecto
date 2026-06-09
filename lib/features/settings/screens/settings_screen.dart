import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:lecto/core/theme/app_theme.dart';
import 'package:lecto/core/database/providers.dart';
import 'package:lecto/features/settings/providers/settings_providers.dart';
import 'package:lecto/shared/widgets/empty_state.dart';

/// App settings screen.
///
/// Features:
///   - Dark mode toggle
///   - About section (version)
///   - Data management (export, import, reset)
///   - App info
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _appVersion = '...';
  String _appBuildNumber = '...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
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

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final isDarkBg = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Appearance section
          _SectionTitle(title: 'Appearance'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isDarkBg ? AppTheme.surfaceCard : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppTheme.primary.withValues(alpha: 0.1),
                ),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: AppTheme.primary,
                  size: 22,
                ),
              ),
              title: Text(
                'Dark Mode',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                isDark ? 'Dark theme is active' : 'Light theme is active',
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
              ),
              trailing: Switch(
                value: isDark,
                onChanged: (_) {
                  ref.read(themeModeSettingProvider.notifier).toggle();
                },
                activeThumbColor: AppTheme.primary,
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Data section
          _SectionTitle(title: 'Data Management'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isDarkBg ? AppTheme.surfaceCard : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.file_download_rounded,
                  title: 'Export Data',
                  subtitle: 'Save your reading data as JSON',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Export coming soon!')),
                    );
                  },
                ),
                const Divider(height: 1, indent: 64, endIndent: 16),
                _SettingsTile(
                  icon: Icons.file_upload_rounded,
                  title: 'Import Data',
                  subtitle: 'Restore data from a backup file',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Import coming soon!')),
                    );
                  },
                ),
                const Divider(height: 1, indent: 64, endIndent: 16),
                _SettingsTile(
                  icon: Icons.delete_forever_rounded,
                  title: 'Reset All Data',
                  subtitle: 'Clear all books, sessions, and goals',
                  onTap: () => _confirmReset(context),
                  iconColor: AppTheme.error,
                  titleColor: AppTheme.error,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // About section
          _SectionTitle(title: 'About'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isDarkBg ? AppTheme.surfaceCard : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
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
                ),
                const Divider(height: 1, indent: 64, endIndent: 16),
                _SettingsTile(
                  icon: Icons.favorite_outline_rounded,
                  title: 'Lecto',
                  subtitle: 'Your personal reading tracker',
                  onTap: null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Reset All Data?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'This will permanently delete all books, reading sessions, goals, and recommendations. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Reset database by deleting all records
              final db = ref.read(databaseProvider);
              // Delete all books and sessions
              for (final book in db.getAllBooks()) {
                db.deleteBook(book.id);
              }
              // Delete all sessions
              for (final session in db.getAllSessions()) {
                db.deleteSession(session.id);
              }
              // Clear recommendations
              db.clearRecommendations();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All data has been reset'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: (iconColor ?? AppTheme.primary).withValues(alpha: 0.1),
        ),
        child: Icon(icon, color: iconColor ?? AppTheme.primary, size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: titleColor ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
      ),
      trailing: onTap != null
          ? Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary, size: 20)
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}
