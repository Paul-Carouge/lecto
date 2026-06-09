import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lecto/core/database/database.dart';
import 'package:lecto/core/theme/app_theme.dart';
import 'package:lecto/core/utils/formatters.dart';
import 'package:lecto/core/database/providers.dart';
import 'package:lecto/features/books/providers/book_providers.dart';
import 'package:lecto/features/books/widgets/book_card.dart';
import 'package:lecto/features/sessions/providers/session_providers.dart';
import 'package:lecto/features/sessions/widgets/session_card.dart';
import 'package:lecto/features/recommendations/providers/recommendation_providers.dart';
import 'package:lecto/features/recommendations/widgets/recommendation_card.dart';
import 'package:lecto/shared/widgets/stat_card.dart';
import 'package:lecto/shared/widgets/empty_state.dart';

/// The main home/dashboard screen.
///
/// Features:
///   - Currently reading section (prominent card)
///   - Quick stats (today's reading: pages, time)
///   - Recent sessions
///   - Recommendations preview (2-3 cards)
///   - Beautiful scrollable layout
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // Get currently reading books
    final readingBooksAsync = ref.watch(booksByStatusProvider(ReadingStatus.reading));
    final recentSessionsAsync = ref.watch(recentSessionsProvider);
    final recommendationsAsync = ref.watch(recommendationsProvider);
    final allSessionsAsync = ref.watch(recentSessionsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            pinned: true,
            backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primaryDark],
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'L',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Lecto',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                onPressed: () => Navigator.pushNamed(context, '/settings'),
              ),
            ],
          ),

          // Body
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Greeting
                Text(
                  _greeting(),
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your Reading Journey',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 24),

                // Currently Reading section
                readingBooksAsync.when(
                  loading: () => const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => Text('Error: $err'),
                  data: (readingBooks) {
                    if (readingBooks.isNotEmpty) {
                      return _CurrentlyReadingSection(
                        books: readingBooks,
                        onTap: (book) =>
                            Navigator.pushNamed(context, '/book/${book.id}'),
                        onStartSession: (book) =>
                            Navigator.pushNamed(context, '/session/${book.id}'),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Quick navigation chips
                const SizedBox(height: 20),
                _QuickNavChips(onTap: (route) {
                  Navigator.pushNamed(context, route);
                }),

                const SizedBox(height: 24),

                // Today's reading stats
                _TodayStats(sessionsAsync: allSessionsAsync),

                const SizedBox(height: 24),

                // Library shortcut
                Row(
                  children: [
                    Text(
                      'Recent Activity',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/sessions'),
                      child: Text(
                        'See all',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Recent sessions
                recentSessionsAsync.when(
                  loading: () => const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => Text('Error: $err'),
                  data: (sessions) {
                    if (sessions.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: isDark
                              ? AppTheme.surfaceCard
                              : Colors.grey.withValues(alpha: 0.04),
                        ),
                        child: Row(
                          children: [
                            Text('📖', style: const TextStyle(fontSize: 32)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'No sessions yet',
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Start reading to see your activity here!',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: sessions.take(3).map((session) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _SessionWithBook(
                              session: session,
                              onTap: () =>
                                  Navigator.pushNamed(context, '/sessions'),
                            ),
                          )).toList(),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Recommendations preview
                Row(
                  children: [
                    Text(
                      'Recommendations',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/recommendations'),
                      child: Text(
                        'See all',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                recommendationsAsync.when(
                  loading: () => const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (recs) {
                    if (recs.isEmpty) {
                      return EmptyState(
                        emoji: '📖',
                        title: 'No recommendations yet',
                        subtitle: 'Finish some books to get personalized recommendations!',
                      );
                    }
                    return Column(
                      children: recs.take(2).map((rec) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: RecommendationCard(
                              title: 'Book #${rec.bookId.substring(0, 6)}',
                              author: 'Unknown',
                              recommendationType: rec.recommendationType,
                              score: rec.score,
                              onTap: () =>
                                  Navigator.pushNamed(context, '/recommendations'),
                            ),
                          )).toList(),
                    );
                  },
                ),

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning ☀️';
    if (hour < 17) return 'Good afternoon 🌤️';
    if (hour < 21) return 'Good evening 🌅';
    return 'Good night 🌙';
  }
}

class _CurrentlyReadingSection extends StatelessWidget {
  final List<Book> books;
  final void Function(Book) onTap;
  final void Function(Book) onStartSession;

  const _CurrentlyReadingSection({
    required this.books,
    required this.onTap,
    required this.onStartSession,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final book = books.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.menu_book_rounded, size: 18, color: AppTheme.primary),
            const SizedBox(width: 6),
            Text(
              'Currently Reading',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => onTap(book),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primary,
                  AppTheme.primaryDark,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                // Cover
                Hero(
                  tag: 'book_cover_${book.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 64,
                      height: 92,
                      child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: book.coverUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => _placeholder(),
                              errorWidget: (_, __, ___) => _placeholder(),
                            )
                          : _placeholder(),
                    ),
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
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.author,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      if (book.pageCount != null && book.pageCount! > 0) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: book.pageCount! > 0 ? 0.0 : 0.0,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            minHeight: 5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '0 of ${book.pageCount} pages',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Continue button
                GestureDetector(
                  onTap: () => onStartSession(book),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white.withValues(alpha: 0.15),
      ),
      child: Center(
        child: Icon(
          Icons.book_rounded,
          size: 30,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _QuickNavChips extends StatelessWidget {
  final void Function(String) onTap;

  const _QuickNavChips({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final chips = [
      ('📚', 'Library', '/library'),
      ('📊', 'Stats', '/stats'),
      ('🎯', 'Goals', '/goals'),
      ('📅', 'Recap', '/wrapped'),
    ];

    return SizedBox(
      height: 80,
      child: Row(
        children: chips.map((chip) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => onTap(chip.$3),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.surfaceCard
                        : Colors.grey.withValues(alpha: 0.06),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(chip.$1, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 4),
                      Text(
                        chip.$2,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TodayStats extends ConsumerWidget {
  final AsyncValue<List<ReadingSession>> sessionsAsync;

  const _TodayStats({required this.sessionsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    return sessionsAsync.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Text('Error: $err'),
      data: (sessions) {
        final todaySessions = sessions.where((s) =>
            s.startTime.isAfter(todayStart) ||
            s.startTime.isAtSameMomentAs(todayStart)).toList();

        final totalPages = todaySessions.fold<int>(
            0, (sum, s) => sum + (s.pagesRead ?? 0));
        final totalSeconds = todaySessions.fold<int>(
            0, (sum, s) => sum + (s.durationSeconds ?? 0));

        return Row(
          children: [
            Expanded(
              child: StatCardCompact(
                label: 'Today\'s Pages',
                value: Formatters.formatPagesShort(totalPages),
                icon: Icons.auto_stories_rounded,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCardCompact(
                label: 'Today\'s Time',
                value: Formatters.formatDuration(
                    totalSeconds > 0 ? Duration(seconds: totalSeconds) : null),
                icon: Icons.schedule_rounded,
                color: AppTheme.accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCardCompact(
                label: 'Sessions',
                value: '${todaySessions.length}',
                icon: Icons.timer_rounded,
                color: AppTheme.success,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SessionWithBook extends ConsumerWidget {
  final ReadingSession session;
  final VoidCallback onTap;

  const _SessionWithBook({
    required this.session,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(currentBookProvider(session.bookId));

    return bookAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (book) => SessionCard(
        session: session,
        bookTitle: book?.title,
        onTap: onTap,
      ),
    );
  }
}
