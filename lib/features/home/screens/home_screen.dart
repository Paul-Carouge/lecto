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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(themePaletteProvider);
    final isDark = ref.watch(isDarkModeProvider);
    final readingBooks = ref.watch(booksByStatusProvider(ReadingStatus.reading));
    final allSessions = ref.watch(recentSessionsProvider);

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
          },
          color: palette.primary,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      _GreetingHeader(palette: palette, isDark: isDark),
                      const SizedBox(height: 32),

                      // Stats row
                      readingBooks.when(
                        data: (books) => _StatsRow(
                          bookCount: ref.watch(allBooksProvider).valueOrNull?.length ?? 0,
                          readingCount: books.length,
                          palette: palette,
                          isDark: isDark,
                        ),
                        loading: () => const SizedBox(height: 80),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 32),

                      // Currently reading
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

                      // Recent sessions
                      Text(
                        'Dernières sessions',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      allSessions.when(
                        data: (sessions) {
                          if (sessions.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  'Commencez votre première session',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: muted,
                                  ),
                                ),
                              ),
                            );
                          }
                          return SizedBox(
                            height: 100,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: sessions.length > 5 ? 5 : sessions.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 10),
                              itemBuilder: (context, i) {
                                final s = sessions[i];
                                return _SessionMiniCard(
                                  session: s,
                                  palette: palette,
                                  surface: surface,
                                  muted: muted,
                                );
                              },
                            ),
                          );
                        },
                        loading: () => const SizedBox(height: 100),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 32),

                      // Quick actions
                      Text(
                        'Actions',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _QuickActions(palette: palette, muted: muted),
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

// ── Widgets ──────────────────────────────────────────────

class _GreetingHeader extends StatelessWidget {
  final ThemePalette palette;
  final bool isDark;
  const _GreetingHeader({required this.palette, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Bonjour'
        : hour < 18
            ? 'Bon après-midi'
            : 'Bonsoir';

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [palette.primary, palette.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              'L',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          greeting,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? palette.textOnDark : palette.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int bookCount;
  final int readingCount;
  final ThemePalette palette;
  final bool isDark;
  const _StatsRow({
    required this.bookCount,
    required this.readingCount,
    required this.palette,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatBadge(
          icon: Icons.menu_book_rounded,
          label: '$bookCount',
          sub: 'livres',
          color: palette.primary,
        ),
        const SizedBox(width: 12),
        _StatBadge(
          icon: Icons.auto_stories_rounded,
          label: '$readingCount',
          sub: 'en cours',
          color: palette.accent,
        ),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;

  const _StatBadge({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            sub,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final coverUrl = book.coverUrl;
    final hasCover = coverUrl != null && coverUrl.isNotEmpty;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRouter.bookDetail(book.id)),
      onLongPressStart: (_) => HapticFeedback.lightImpact(),
      child: Container(
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
                width: 64,
                height: 90,
                child: hasCover
                    ? CachedNetworkImage(
                        imageUrl: coverUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _CoverPlaceholder(palette: palette),
                        errorWidget: (_, __, ___) => _CoverPlaceholder(palette: palette),
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
                      color: isDark ? palette.textOnDark : palette.textPrimary,
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
                  // Progress
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 0.35,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [palette.primary, palette.primaryLight],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
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
      onTap: () => Navigator.pushNamed(context, AppRouter.addBook),
      child: Container(
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

class _QuickActions extends StatelessWidget {
  final ThemePalette palette;
  final Color muted;
  const _QuickActions({required this.palette, required this.muted});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.add_rounded,
            label: 'Ajouter un livre',
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, AppRouter.addBook);
            },
            primary: palette.primary,
            muted: muted,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            icon: Icons.library_books_rounded,
            label: 'Bibliothèque',
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, AppRouter.library);
            },
            primary: palette.primary,
            muted: muted,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color primary;
  final Color muted;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.primary,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: primary.withValues(alpha: 0.15),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: primary, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 13, color: muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  final Color surface;
  const _ShimmerCard({required this.surface});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
