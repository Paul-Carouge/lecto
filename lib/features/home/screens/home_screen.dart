import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lecto/core/database/database.dart';
import 'package:lecto/core/theme/theme_provider.dart';
import 'package:lecto/core/utils/formatters.dart';
import 'package:lecto/features/books/providers/book_providers.dart';
import 'package:lecto/features/sessions/providers/session_providers.dart';
import 'package:lecto/features/recommendations/providers/recommendation_providers.dart';
import 'package:lecto/features/stats/providers/stats_providers.dart';
import 'package:lecto/features/goals/providers/goal_providers.dart';

/// Bold, modern home dashboard for Lecto — redesigned with a bento grid,
/// glassmorphism, gradient accents, and beautiful French typography.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTapHaptic() {
    HapticFeedback.lightImpact();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour ☀️';
    if (hour < 17) return 'Bon après-midi 🌤️';
    if (hour < 21) return 'Bonsoir 🌅';
    return 'Bonne nuit 🌙';
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    ref.invalidate(allBooksProvider);
    ref.invalidate(booksByStatusProvider);
    ref.invalidate(recentSessionsProvider);
    ref.invalidate(recommendationsProvider);
    ref.invalidate(bookshelfStatsProvider);
    ref.invalidate(goalsProvider);
    ref.invalidate(currentGoalProgressProvider);
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themePalette = ref.watch(themePaletteProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final horizontalPadding = isSmallScreen ? 12.0 : 16.0;

    // Providers
    final readingBooksAsync =
        ref.watch(booksByStatusProvider(ReadingStatus.reading));
    final recentSessionsAsync = ref.watch(recentSessionsProvider);
    final recommendationsAsync = ref.watch(recommendationsProvider);
    final allSessionsAsync = ref.watch(recentSessionsProvider);
    final statsAsync = ref.watch(bookshelfStatsProvider);
    final goalAsync = ref.watch(
      currentGoalProgressProvider(
        DateTime.now().year,
        month: DateTime.now().month,
      ),
    );

    final primary = themePalette.primary;
    final primaryLight = themePalette.primaryLight;
    final accent = themePalette.accent;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: primary,
        strokeWidth: 3,
        displacement: 80,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // ── App Bar ──
              SliverAppBar(
                pinned: true,
                elevation: 0,
                backgroundColor: colorScheme.surface,
                foregroundColor: colorScheme.onSurface,
                title: Row(
                  children: [
                    // Logo mark
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: [primary, primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'L',
                          style: GoogleFonts.outfit(
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
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.tune_rounded),
                    onPressed: () =>
                        Navigator.pushNamed(context, '/settings'),
                    splashRadius: 20,
                  ),
                ],
              ),

              // ── Main Body ──
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 8),

                    // ═══════════════════════════════════════════
                    // 1. HEADER: Greeting + Avatar + Quick Stats
                    // ═══════════════════════════════════════════
                    _buildHeader(context, primary, primaryLight, colorScheme,
                        isDark, statsAsync),

                    const SizedBox(height: 20),

                    // ═══════════════════════════════════════════
                    // 2. CURRENTLY READING (glassmorphism)
                    // ═══════════════════════════════════════════
                    readingBooksAsync.when(
                      loading: () => _buildLoadingCard(180),
                      error: (err, _) =>
                          _buildSubtitle('Erreur', colorScheme: colorScheme),
                      data: (books) {
                        if (books.isEmpty) {
                          return _buildEmptyReadingCard(
                              primary, primaryLight, colorScheme, isDark);
                        }
                        return _buildCurrentlyReading(books.first, primary,
                            primaryLight, colorScheme, isDark);
                      },
                    ),

                    const SizedBox(height: 20),

                    // ═══════════════════════════════════════════
                    // 3. BENTO GRID (2x2 asymmetric)
                    // ═══════════════════════════════════════════
                    _buildSectionTitle('Vue d\'ensemble', colorScheme),
                    const SizedBox(height: 12),
                    _buildBentoGrid(
                      context,
                      allSessionsAsync,
                      goalAsync,
                      statsAsync,
                      primary,
                      accent,
                      colorScheme,
                      isDark,
                      isSmallScreen,
                    ),

                    const SizedBox(height: 20),

                    // ═══════════════════════════════════════════
                    // 4. RECENT SESSIONS (horizontal scroll)
                    // ═══════════════════════════════════════════
                    _buildSectionTitleWithAction(
                      'Séances récentes',
                      'Voir tout',
                      colorScheme,
                      () => Navigator.pushNamed(context, '/sessions'),
                    ),
                    const SizedBox(height: 12),
                    recentSessionsAsync.when(
                      loading: () => _buildLoadingCard(100),
                      error: (err, _) =>
                          _buildSubtitle('Erreur de chargement'),
                      data: (sessions) {
                        if (sessions.isEmpty) {
                          return _buildEmptyHint(
                            '📖',
                            'Aucune séance pour l\'instant',
                            'Commencez une session de lecture pour voir votre activité ici.',
                            primary,
                          );
                        }
                        return _buildRecentSessions(
                            sessions, primary, colorScheme, isDark);
                      },
                    ),

                    const SizedBox(height: 20),

                    // ═══════════════════════════════════════════
                    // 5. RECOMMENDATIONS (horizontal scroll)
                    // ═══════════════════════════════════════════
                    _buildSectionTitleWithAction(
                      'Recommandations',
                      'Voir tout',
                      colorScheme,
                      () =>
                          Navigator.pushNamed(context, '/recommendations'),
                    ),
                    const SizedBox(height: 12),
                    recommendationsAsync.when(
                      loading: () => _buildLoadingCard(120),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (recs) {
                        if (recs.isEmpty) {
                          return _buildEmptyHint(
                            '📚',
                            'Aucune recommandation',
                            'Terminez des livres pour obtenir des recommandations personnalisées.',
                            primary,
                          );
                        }
                        return _buildRecommendations(
                            recs, primary, colorScheme, isDark);
                      },
                    ),

                    const SizedBox(height: 20),

                    // ═══════════════════════════════════════════
                    // 6. QUICK ACTION CHIPS
                    // ═══════════════════════════════════════════
                    _buildQuickActions(primary, colorScheme, isDark),

                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // 1. HEADER
  // ────────────────────────────────────────────────────────────────
  Widget _buildHeader(
    BuildContext context,
    Color primary,
    Color primaryLight,
    ColorScheme colorScheme,
    bool isDark,
    AsyncValue<BookshelfStats> statsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Greeting + Avatar row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Votre aventure de lecture',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            // Circular gradient avatar with initials
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [primary, primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'L',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Quick stats row (livres, pages, minutes)
        statsAsync.when(
          loading: () => Row(
            children: List.generate(
              3,
              (_) => Expanded(
                child: Container(
                  height: 60,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: colorScheme.surface,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (stats) {
            final items = [
              (
                Icons.auto_stories_rounded,
                '${stats.totalBooks}',
                'livres'
              ),
              (
                Icons.description_rounded,
                '${stats.totalPages}',
                'pages'
              ),
              (
                Icons.schedule_rounded,
                Formatters.formatDuration(stats.totalTime),
                'lecture'
              ),
            ];
            return Row(
              children: items.map((item) {
                return Expanded(
                  child: Container(
                    height: 60,
                    margin: EdgeInsets.only(
                        right: items.last == item ? 0 : 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: [
                          primary.withValues(alpha: isDark ? 0.12 : 0.08),
                          primary.withValues(alpha: isDark ? 0.05 : 0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item.$1, size: 18, color: primary),
                        const SizedBox(width: 6),
                        Text(
                          item.$2,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.$3,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────
  // 2. CURRENTLY READING — glassmorphism card
  // ────────────────────────────────────────────────────────────────
  Widget _buildCurrentlyReading(
    Book book,
    Color primary,
    Color primaryLight,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    // Calculate approximate progress from sessions
    final pagesProgress = book.pageCount != null && book.pageCount! > 0
        ? ref.watch(recentSessionsProvider).when(
              data: (sessions) {
                final bookSessions = sessions
                    .where((s) => s.bookId == book.id)
                    .toList();
                final totalRead = bookSessions.fold<int>(
                    0, (sum, s) => sum + (s.pagesRead ?? 0));
                return (totalRead / book.pageCount!).clamp(0.0, 1.0);
              },
              loading: () => 0.0,
              error: (_, __) => 0.0,
            )
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.menu_book_rounded, size: 18, color: primary),
            const SizedBox(width: 6),
            Text(
              'En cours de lecture',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            _onTapHaptic();
            Navigator.pushNamed(context, '/book/${book.id}');
          },
          child: AnimatedScale(
            scale: 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          primary.withValues(alpha: 0.2),
                          primary.withValues(alpha: 0.05),
                        ]
                      : [
                          primary.withValues(alpha: 0.15),
                          primary.withValues(alpha: 0.04),
                        ],
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : primary.withValues(alpha: 0.12),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  // Book cover
                  Hero(
                    tag: 'book_cover_${book.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 68,
                        height: 100,
                        child: book.coverUrl != null &&
                                book.coverUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: book.coverUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    _coverPlaceholder(primary),
                                errorWidget: (_, __, ___) =>
                                    _coverPlaceholder(primary),
                              )
                            : _coverPlaceholder(primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Book info
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
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          book.author,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        if (book.pageCount != null &&
                            book.pageCount! > 0) ...[
                          const SizedBox(height: 12),
                          // Glass progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(6),
                                color: isDark
                                    ? Colors.white.withValues(
                                        alpha: 0.08)
                                    : primary.withValues(alpha: 0.12),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: pagesProgress > 0
                                    ? pagesProgress
                                    : 0.02,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(6),
                                    gradient: LinearGradient(
                                      colors: [primary, primaryLight],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${(pagesProgress * 100).round()}% · ${book.pageCount} pages',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Play button
                  GestureDetector(
                    onTap: () {
                      _onTapHaptic();
                      Navigator.pushNamed(
                          context, '/session/${book.id}');
                    },
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          colors: [primary, primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyReadingCard(Color primary, Color primaryLight,
      ColorScheme colorScheme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.menu_book_rounded, size: 18, color: primary),
            const SizedBox(width: 6),
            Text(
              'En cours de lecture',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            _onTapHaptic();
            Navigator.pushNamed(context, '/add-book');
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primary.withValues(alpha: 0.15),
                width: 1.5,
              ),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : primary.withValues(alpha: 0.03),
            ),
            child: Column(
              children: [
                Icon(Icons.menu_book_rounded,
                    size: 40, color: primary.withValues(alpha: 0.4)),
                const SizedBox(height: 12),
                Text(
                  'Aucune lecture en cours',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface
                        .withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ajoutez un livre et commencez à lire !',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: colorScheme.onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────
  // 3. BENTO GRID
  // ────────────────────────────────────────────────────────────────
  Widget _buildBentoGrid(
    BuildContext context,
    AsyncValue<List<ReadingSession>> sessionsAsync,
    AsyncValue<GoalProgress> goalAsync,
    AsyncValue<BookshelfStats> statsAsync,
    Color primary,
    Color accent,
    ColorScheme colorScheme,
    bool isDark,
    bool isSmallScreen,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 10.0;
        final totalWidth = constraints.maxWidth;
        final leftWidth = totalWidth * 0.55 - gap / 2;
        final rightWidth = totalWidth * 0.45 - gap / 2;
        final tallHeight = 160.0;
        final shortHeight = 75.0;

        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);

        return Column(
          children: [
            // Top row: large left (Today's reading), stacked right (Goal + Streak-ish)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT: Today's reading (large)
                SizedBox(
                  width: leftWidth,
                  height: tallHeight,
                  child: sessionsAsync.when(
                    loading: () => _bentoSkeleton(leftWidth, tallHeight),
                    error: (_, __) =>
                        _bentoSkeleton(leftWidth, tallHeight),
                    data: (sessions) {
                      final todaySessions = sessions
                          .where((s) =>
                              s.startTime.isAfter(todayStart) ||
                              s.startTime
                                  .isAtSameMomentAs(todayStart))
                          .toList();
                      final totalPages = todaySessions.fold<int>(
                          0, (sum, s) => sum + (s.pagesRead ?? 0));
                      final totalSeconds = todaySessions.fold<int>(
                          0,
                          (sum, s) =>
                              sum + (s.durationSeconds ?? 0));
                      final hasData = totalPages > 0 || totalSeconds > 0;

                      return _buildBentoCard(
                        height: tallHeight,
                        gradientColors: [primary, primary.withValues(alpha: 0.7)],
                        isDark: isDark,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white
                                        .withValues(alpha: 0.2),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.today_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Aujourd\'hui',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white
                                        .withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            if (hasData) ...[
                              Text(
                                '${totalPages}p',
                                style: GoogleFonts.outfit(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                Formatters.formatSeconds(totalSeconds),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.white
                                      .withValues(alpha: 0.75),
                                ),
                              ),
                            ] else ...[
                              Text(
                                '—',
                                style: GoogleFonts.outfit(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Aucune session',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.white
                                      .withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              'pages · temps de lecture',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.white
                                    .withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: gap),
                // RIGHT column: stacked
                Column(
                  children: [
                    // Top right: Goal progress
                    SizedBox(
                      width: rightWidth,
                      height: shortHeight,
                      child: goalAsync.when(
                        loading: () =>
                            _bentoSkeleton(rightWidth, shortHeight),
                        error: (_, __) =>
                            _bentoSkeleton(rightWidth, shortHeight),
                        data: (goal) {
                          final pct = goal.percentage;
                          return _buildBentoCard(
                            height: shortHeight,
                            gradientColors: [accent, accent],
                            isDark: isDark,
                            child: Row(
                              children: [
                                // Circular progress
                                SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 44,
                                        height: 44,
                                        child: CircularProgressIndicator(
                                          value: pct,
                                          strokeWidth: 4,
                                          backgroundColor: Colors.white
                                              .withValues(alpha: 0.2),
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                  Color>(Colors.white),
                                        ),
                                      ),
                                      Text(
                                        '${(pct * 100).round()}%',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Objectif du mois',
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white
                                              .withValues(alpha: 0.85),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        goal.hasGoal
                                            ? '${goal.progress}/${goal.target}'
                                            : 'Aucun objectif',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.white
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: gap),
                    // Bottom right: Streak
                    SizedBox(
                      width: rightWidth,
                      height: shortHeight,
                      child: statsAsync.when(
                        loading: () =>
                            _bentoSkeleton(rightWidth, shortHeight),
                        error: (_, __) =>
                            _bentoSkeleton(rightWidth, shortHeight),
                        data: (stats) {
                          return _buildBentoCard(
                            height: shortHeight,
                            gradientColors: [
                              primary.withValues(alpha: 0.7),
                              primary.withValues(alpha: 0.4),
                            ],
                            isDark: isDark,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white
                                        .withValues(alpha: 0.2),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.local_fire_department_rounded,
                                    size: 22,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${stats.currentStreak} jours',
                                        style: GoogleFonts.outfit(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        'Série en cours',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.white
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: gap),
            // Bottom full-width: Books finished this month
            SizedBox(
              width: totalWidth,
              height: 68,
              child: statsAsync.when(
                loading: () => _bentoSkeleton(totalWidth, 68),
                error: (_, __) => _bentoSkeleton(totalWidth, 68),
                data: (stats) {
                  return _buildBentoCard(
                    height: 68,
                    gradientColors: [
                      primary.withValues(alpha: 0.2),
                      primary.withValues(alpha: 0.05),
                    ],
                    isDark: isDark,
                    useLightText: false,
                    colorScheme: colorScheme,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.auto_stories_rounded,
                            size: 22,
                            color: primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Livres terminés ce mois',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${stats.totalBooks}',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBentoCard({
    required double height,
    required List<Color> gradientColors,
    required bool isDark,
    bool useLightText = true,
    ColorScheme? colorScheme,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: useLightText
            ? [
                BoxShadow(
                  color: gradientColors.first.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }

  Widget _bentoSkeleton(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context)
            .colorScheme
            .onSurface
            .withValues(alpha: 0.04),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // 4. RECENT SESSIONS (horizontal scroll)
  // ────────────────────────────────────────────────────────────────
  Widget _buildRecentSessions(
    List<ReadingSession> sessions,
    Color primary,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final recent = sessions.take(5).toList();
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(right: 4),
        itemCount: recent.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final session = recent[index];
          return SizedBox(
            width: 220,
            child: Consumer(
              builder: (context, ref, _) {
                final bookAsync =
                    ref.watch(currentBookProvider(session.bookId));
                return bookAsync.when(
                  loading: () => _sessionCardSkeleton(primary, colorScheme),
                  error: (_, __) => _sessionCardSkeleton(primary, colorScheme),
                  data: (book) {
                    return GestureDetector(
                      onTap: () {
                        _onTapHaptic();
                        Navigator.pushNamed(context, '/sessions');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: isDark
                              ? colorScheme.surface
                              : Colors.white,
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : primary.withValues(alpha: 0.06),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Book cover mini
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 40,
                                height: 56,
                                child: book?.coverUrl != null &&
                                        book!.coverUrl!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: book.coverUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) =>
                                            _coverPlaceholder(primary),
                                        errorWidget: (_, __, ___) =>
                                            _coverPlaceholder(
                                                primary),
                                      )
                                    : _coverPlaceholder(primary),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(
                                    book?.title ?? 'Livre inconnu',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.schedule_rounded,
                                          size: 12,
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.5)),
                                      const SizedBox(width: 3),
                                      Text(
                                        Formatters.formatDuration(
                                          session.duration,
                                        ),
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                      if (session.pagesRead !=
                                              null &&
                                          session.pagesRead! > 0) ...[
                                        const SizedBox(width: 8),
                                        Icon(
                                            Icons
                                                .auto_stories_rounded,
                                            size: 12,
                                            color: colorScheme
                                                .onSurface
                                                .withValues(
                                                    alpha: 0.5)),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${session.pagesRead}p',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: colorScheme
                                                .onSurface
                                                .withValues(
                                                    alpha: 0.5),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _sessionCardSkeleton(
      Color primary, ColorScheme colorScheme) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surface,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: colorScheme.onSurface.withValues(alpha: 0.06),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 12,
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: colorScheme.onSurface
                        .withValues(alpha: 0.06),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: colorScheme.onSurface
                        .withValues(alpha: 0.04),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // 5. RECOMMENDATIONS (horizontal scroll)
  // ────────────────────────────────────────────────────────────────
  Widget _buildRecommendations(
    List<Recommendation> recs,
    Color primary,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final displayRecs = recs.take(5).toList();
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(right: 4),
        itemCount: displayRecs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final rec = displayRecs[index];
          return SizedBox(
            width: 200,
            child: Consumer(
              builder: (context, ref, _) {
                final bookAsync =
                    ref.watch(currentBookProvider(rec.bookId));
                return bookAsync.when(
                  loading: () => _recCardSkeleton(colorScheme),
                  error: (_, __) => _recCardSkeleton(colorScheme),
                  data: (book) {
                    final title = book?.title ?? 'Recommandation';
                    final author = book?.author ?? '';
                    final reason = switch (rec.recommendationType) {
                      'genre_similar' => 'Genre similaire',
                      'author_similar' => 'Même auteur',
                      'popular' => 'Populaire',
                      _ => 'Recommandé',
                    };
                    final reasonColor = switch (rec.recommendationType) {
                      'genre_similar' => primary,
                      'author_similar' => Theme.of(context)
                          .colorScheme
                          .secondary,
                      'popular' => const Color(0xFF10B981),
                      _ => primary,
                    };

                    return GestureDetector(
                      onTap: () {
                        _onTapHaptic();
                        Navigator.pushNamed(context,
                            '/book/${rec.bookId}');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: isDark
                              ? colorScheme.surface
                              : Colors.white,
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : primary.withValues(alpha: 0.06),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Mini cover
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 36,
                                    height: 52,
                                    child: book?.coverUrl != null &&
                                            book!.coverUrl!.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl:
                                                book.coverUrl!,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) =>
                                                _coverPlaceholder(
                                                    primary),
                                            errorWidget: (_, __,
                                                    ___) =>
                                                _coverPlaceholder(
                                                    primary),
                                          )
                                        : _coverPlaceholder(
                                            primary),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          fontWeight:
                                              FontWeight.w600,
                                          color:
                                              colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        author,
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(6),
                                color: reasonColor
                                    .withValues(alpha: 0.1),
                              ),
                              child: Text(
                                reason,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: reasonColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _recCardSkeleton(ColorScheme colorScheme) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color:
                      colorScheme.onSurface.withValues(alpha: 0.06),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: colorScheme.onSurface
                            .withValues(alpha: 0.06),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: colorScheme.onSurface
                            .withValues(alpha: 0.04),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // 6. QUICK ACTION CHIPS
  // ────────────────────────────────────────────────────────────────
  Widget _buildQuickActions(
    Color primary,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final actions = [
      (
        Icons.play_circle_filled_rounded,
        'Nouvelle session',
        () => Navigator.pushNamed(context, '/sessions'),
      ),
      (
        Icons.add_circle_rounded,
        'Ajouter un livre',
        () => Navigator.pushNamed(context, '/add-book'),
      ),
      (
        Icons.library_books_rounded,
        'Voir la bibliothèque',
        () => Navigator.pushNamed(context, '/library'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: actions.map((action) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    right: actions.last == action ? 0 : 8),
                child: GestureDetector(
                  onTap: () {
                    _onTapHaptic();
                    action.$3();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: isDark
                          ? primary.withValues(alpha: 0.12)
                          : primary.withValues(alpha: 0.08),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : primary.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(action.$1,
                            size: 22, color: primary),
                        const SizedBox(height: 6),
                        Text(
                          action.$2,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: primary,
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
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Shared helpers
  // ────────────────────────────────────────────────────────────────
  Widget _buildSectionTitle(
    String title,
    ColorScheme colorScheme,
  ) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
    );
  }

  Widget _buildSectionTitleWithAction(
    String title,
    String actionLabel,
    ColorScheme colorScheme,
    VoidCallback onAction,
  ) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            _onTapHaptic();
            onAction();
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: colorScheme.primary.withValues(alpha: 0.08),
            ),
            child: Text(
              actionLabel,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitle(String text, {ColorScheme? colorScheme}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: colorScheme?.onSurface.withValues(alpha: 0.5) ??
              Colors.grey,
        ),
      ),
    );
  }

  Widget _buildLoadingCard(double height) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context)
            .colorScheme
            .onSurface
            .withValues(alpha: 0.04),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );
  }

  Widget _buildEmptyHint(
    String emoji,
    String title,
    String subtitle,
    Color primary,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context)
            .colorScheme
            .onSurface
            .withValues(alpha: 0.03),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverPlaceholder(Color primary) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: 0.15),
            primary.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.book_rounded,
          size: 28,
          color: primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
