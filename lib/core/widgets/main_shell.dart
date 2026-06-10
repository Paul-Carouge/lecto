import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lecto/features/home/screens/home_screen.dart';
import 'package:lecto/features/books/screens/library_screen.dart';
import 'package:lecto/features/books/screens/add_book_screen.dart';
import 'package:lecto/features/stats/screens/stats_screen.dart';
import 'package:lecto/features/settings/screens/settings_screen.dart';
import 'package:lecto/core/theme/theme_provider.dart';

/// Main shell widget with 5-tab BottomNavigationBar and IndexedStack.
///
/// Tabs:
/// 0. Accueil (HomeScreen)       – Icons.home_rounded
/// 1. Bibliothèque (LibraryScreen) – Icons.auto_stories_rounded
/// 2. Recherche (AddBookScreen)  – Icons.search_rounded
/// 3. Statistiques (StatsScreen) – Icons.bar_chart_rounded
/// 4. Paramètres (SettingsScreen) – Icons.settings_rounded
class MainShell extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late int _currentIndex;

  final _screens = const [
    HomeScreen(),
    LibraryScreen(),
    AddBookScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(themePaletteProvider);
    final isDark = ref.watch(isDarkModeProvider);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: (isDark ? palette.textOnDark : palette.textPrimary)
                  .withValues(alpha: 0.06),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor:
              isDark ? palette.surfaceDark : palette.surfaceLight,
          selectedItemColor: palette.primary,
          unselectedItemColor: (isDark ? palette.textOnDark : palette.textPrimary)
              .withValues(alpha: 0.4),
          showSelectedLabels: false,
          showUnselectedLabels: false,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle:
              GoogleFonts.outfit(fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              GoogleFonts.outfit(fontWeight: FontWeight.w500),
          elevation: 0,
          onTap: (index) {
            HapticFeedback.lightImpact();
            setState(() => _currentIndex = index);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              activeIcon: Icon(Icons.home_rounded),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_stories_rounded),
              activeIcon: Icon(Icons.auto_stories_rounded),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              activeIcon: Icon(Icons.search_rounded),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              activeIcon: Icon(Icons.bar_chart_rounded),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              activeIcon: Icon(Icons.settings_rounded),
              label: '',
            ),
          ],
        ),
      ),
    );
  }
}
