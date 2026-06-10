import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lecto/core/database/database.dart';
import 'package:lecto/core/database/providers.dart';
import 'package:lecto/core/router/app_router.dart';
import 'package:lecto/core/theme/theme_provider.dart';
import 'package:lecto/core/theme/themes.dart';
import 'package:lecto/features/books/providers/book_providers.dart';
import 'package:lecto/features/sessions/providers/session_providers.dart';
import 'package:lecto/features/stats/providers/stats_providers.dart';
import 'package:lecto/features/recommendations/providers/recommendation_providers.dart';
import 'package:lecto/features/settings/providers/settings_providers.dart'
    hide isDarkModeProvider;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(allBooksProvider);
        ref.invalidate(booksByStatusProvider);
        ref.invalidate(recentSessionsProvider);
        ref.invalidate(bookshelfStatsProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(themePaletteProvider);
    final isDark = ref.watch(isDarkModeProvider);
    final readingBooks = ref.watch(booksByStatusProvider(ReadingStatus.reading));
    final statsAsync = ref.watch(bookshelfStatsProvider);

    final bg = isDark ? palette.surfaceDark : palette.surfaceLight;
    final surface = isDark ? palette.surfaceCardDark : palette.surfaceCardLight;
    final onSurface = isDark ? palette.textOnDark : palette.textPrimary;
    final muted = isDark
        ? palette.textOnDark.withValues(alpha: 0.5)
        : palette.textSecondary;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allBooksProvider);
            ref.invalidate(booksByStatusProvider);
            ref.invalidate(recentSessionsProvider);
            ref.invalidate(bookshelfStatsProvider);
          },
          color: palette.primary,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Greeting header ──
                      _GreetingHeader(palette: palette, isDark: isDark),
                      const SizedBox(height: 32),

                      // ── Full-width stats row ──
                      _StatsRow(
                        statsAsync: statsAsync,
                        readingCount:
                            readingBooks.valueOrNull?.length ?? 0,
                        palette: palette,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 32),

                      // ── Currently reading ──
                      Text(
                        'En cours',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      readingBooks.when(
                        data: (books) {
                          if (books.isEmpty) {
                            return _EmptyReadingCard(
                              palette: palette,
                              surface: surface,
                              onSurface: onSurface,
                              muted: muted,
                            );
                          }
                          return _ReadingCard(
                            book: books.first,
                            palette: palette,
                            surface: surface,
                            isDark: isDark,
                          );
                        },
                        loading: () => _ShimmerCard(surface: surface),
                        error: (_, __) => _EmptyReadingCard(
                          palette: palette,
                          surface: surface,
                          onSurface: onSurface,
                          muted: muted,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Quick actions 2×2 grid ──
                      Text(
                        'Actions',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _QuickActionsGrid(
                        palette: palette,
                        onSurface: onSurface,
                        muted: muted,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Greeting Header
// ═══════════════════════════════════════════════════════════════

class _GreetingHeader extends ConsumerWidget {
  final ThemePalette palette;
  final bool isDark;

  const _GreetingHeader({
    required this.palette,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Bonjour'
        : hour < 18
            ? 'Bon après-midi'
            : 'Bonsoir';

    final userName = ref.watch(userNameProvider).valueOrNull ?? '';

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [palette.primary, palette.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Icon(
              Icons.auto_stories_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: isDark ? palette.textOnDark : palette.textPrimary,
                ),
              ),
              if (userName.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  userName,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: isDark 
                        ? palette.textOnDark.withValues(alpha: 0.7)
                        : palette.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Full‑width Stats Row — each stat fills an equal column
// ═══════════════════════════════════════════════════════════════

class _StatsRow extends StatelessWidget {
  final AsyncValue<BookshelfStats> statsAsync;
  final int readingCount;
  final ThemePalette palette;
  final bool isDark;

  const _StatsRow({
    required this.statsAsync,
    required this.readingCount,
    required this.palette,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final stats = statsAsync.valueOrNull ?? const BookshelfStats();

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.menu_book_rounded,
            value: '${stats.totalBooks}',
            label: 'livres',
            color: palette.primary,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.auto_stories_rounded,
            value: '$readingCount',
            label: 'en cours',
            color: palette.accent,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.chrome_reader_mode_rounded,
            value: '${stats.totalPages}',
            label: 'pages',
            color: palette.primaryLight,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_rounded,
            value: '${stats.currentStreak}',
            label: 'jours',
            color: const Color(0xFFE85D3A),
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

/// A single compact stat card used inside the full‑width stats row.
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.1)
            : color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Currently Reading Card  (full‑width)
// ═══════════════════════════════════════════════════════════════

class _ReadingCard extends ConsumerWidget {
  final Book book;
  final ThemePalette palette;
  final Color surface;
  final bool isDark;

  const _ReadingCard({
    required this.book,
    required this.palette,
    required this.surface,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coverUrl = book.coverUrl;
    final hasCover = coverUrl != null && coverUrl.isNotEmpty;
    final pagesRead = ref.watch(bookPagesReadProvider(book.id)).valueOrNull ?? 0;
    final progress = book.pageCount != null && book.pageCount! > 0
        ? (pagesRead / book.pageCount!).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, AppRouter.bookDetail(book.id)),
      onLongPressStart: (_) => HapticFeedback.lightImpact(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: palette.primary.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            // Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 72,
                height: 104,
                child: hasCover
                    ? CachedNetworkImage(
                        imageUrl: coverUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            _CoverPlaceholder(palette: palette),
                        errorWidget: (_, __, ___) =>
                            _CoverPlaceholder(palette: palette),
                      )
                    : _CoverPlaceholder(palette: palette),
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark ? palette.textOnDark : palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark
                          ? palette.textOnDark.withValues(alpha: 0.6)
                          : palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Progress bar
                  _ProgressBar(
                    palette: palette,
                    progress: progress,
                  ),
                  if (book.pageCount != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${(progress * 100).round()}% · ${book.pageCount} pages',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark
                              ? palette.textOnDark.withValues(alpha: 0.4)
                              : palette.textSecondary.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: palette.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final ThemePalette palette;
  final double progress;

  const _ProgressBar({
    required this.palette,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [palette.primary, palette.primaryLight],
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Empty Reading Card  (full‑width)
// ═══════════════════════════════════════════════════════════════

class _EmptyReadingCard extends StatelessWidget {
  final ThemePalette palette;
  final Color surface;
  final Color onSurface;
  final Color muted;

  const _EmptyReadingCard({
    required this.palette,
    required this.surface,
    required this.onSurface,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => route.isFirst),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: palette.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.add_rounded,
                color: palette.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ajouter un livre',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Commencez votre bibliothèque',
                    style: GoogleFonts.inter(fontSize: 13, color: muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Cover Placeholder
// ═══════════════════════════════════════════════════════════════

class _CoverPlaceholder extends StatelessWidget {
  final ThemePalette palette;

  const _CoverPlaceholder({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: palette.primary.withValues(alpha: 0.1),
      child: Icon(
        Icons.book_rounded,
        size: 28,
        color: palette.primary.withValues(alpha: 0.3),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Session Mini Card  (horizontal scroll)
// ═══════════════════════════════════════════════════════════════

class _SessionMiniCard extends StatelessWidget {
  final ReadingSession session;
  final ThemePalette palette;
  final Color surface;
  final Color muted;

  const _SessionMiniCard({
    required this.session,
    required this.palette,
    required this.surface,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final duration = session.durationSeconds ?? 0;
    final minutes = (duration / 60).round();
    final pages = session.pagesRead ?? 0;

    return Container(
      width: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 14, color: palette.primary),
              const SizedBox(width: 4),
              Text(
                '$minutes min',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: palette.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.menu_book_outlined, size: 14, color: muted),
              const SizedBox(width: 4),
              Text(
                '$pages pages',
                style: GoogleFonts.inter(fontSize: 13, color: muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Quick Actions Grid  (2 × 2)
// ═══════════════════════════════════════════════════════════════

class _QuickActionsGrid extends StatelessWidget {
  final ThemePalette palette;
  final Color onSurface;
  final Color muted;

  const _QuickActionsGrid({
    required this.palette,
    required this.onSurface,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: [
        _QuickActionTile(
          icon: Icons.library_books_rounded,
          label: 'Bibliothèque',
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => route.isFirst);
          },
          color: palette.primary,
        ),
        _QuickActionTile(
          icon: Icons.timer_outlined,
          label: 'Session',
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pushNamed(context, AppRouter.sessions);
          },
          color: palette.primaryLight,
        ),
        _QuickActionTile(
          icon: Icons.insert_chart_rounded,
          label: 'Stats',
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => route.isFirst);
          },
          color: palette.accent,
        ),
        _QuickActionTile(
          icon: Icons.flag_rounded,
          label: 'Objectifs',
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pushNamed(context, AppRouter.goals);
          },
          color: palette.primary,
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Shimmer Card  (full‑width)
// ═══════════════════════════════════════════════════════════════

class _ShimmerCard extends StatelessWidget {
  final Color surface;

  const _ShimmerCard({required this.surface});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
