import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:lecto/core/theme/theme_provider.dart';
import 'package:lecto/core/theme/themes.dart';
import 'package:lecto/core/database/database.dart';
import 'package:lecto/features/goals/providers/goal_providers.dart';
import 'package:lecto/features/stats/providers/stats_providers.dart';
import 'package:lecto/shared/widgets/empty_state.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────────────────────────────────────

/// Compact number formatting (e.g. 1 200 → "1.2k").
String _compactNumber(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return n.toString();
}

/// French month abbreviation helper.
String _frenchMonth(int month) {
  final date = DateTime(2024, month);
  return DateFormat('MMM', 'fr_FR').format(date);
}

// ──────────────────────────────────────────────────────────────────────────────
// Goal model used locally inside stats (mirrors the DB GoalProgress shape)
// ──────────────────────────────────────────────────────────────────────────────

/// Simple progress info derived from a [ReadingGoal].
class _GoalInfo {
  final int target;
  final int progress;
  final double percentage;

  const _GoalInfo({
    required this.target,
    required this.progress,
    required this.percentage,
  });

  bool get hasGoal => target > 0;
  bool get isComplete => percentage >= 1.0;
  int get remaining => (target - progress).clamp(0, target);
}

// ──────────────────────────────────────────────────────────────────────────────
// StatsScreen
// ──────────────────────────────────────────────────────────────────────────────

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  final GlobalKey _screenshotKey = GlobalKey();
  bool _sharing = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_initialized) {
        _initialized = true;
        final now = DateTime.now();
        ref.invalidate(bookshelfStatsProvider);
        ref.invalidate(monthlyStatsProvider(now.year));
        ref.invalidate(monthlyDurationProvider(now.year));
        ref.invalidate(topGenresProvider);
        ref.invalidate(currentGoalProgressProvider);
        ref.invalidate(goalsProvider);
      }
    });
  }

  Future<void> _shareScreenshot() async {
    try {
      setState(() => _sharing = true);
      await Future.delayed(const Duration(milliseconds: 300));

      final boundary = _screenshotKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null || !boundary.isRepaintBoundary) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      await Share.shareXFiles(
        [
          XFile.fromData(
            Uint8List.fromList(pngBytes),
            name: 'lecto_stats.png',
            mimeType: 'image/png',
          ),
        ],
        text: 'Mes statistiques de lecture 📚',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du partage : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final palette = ref.watch(themePaletteProvider);
    final now = DateTime.now();
    final year = now.year;
    final currentMonth = now.month;

    final statsAsync = ref.watch(bookshelfStatsProvider);
    final monthlyPagesAsync = ref.watch(monthlyStatsProvider(year));
    final monthlyDurationAsync = ref.watch(monthlyDurationProvider(year));
    final genresAsync = ref.watch(topGenresProvider);
    final monthlyGoalAsync =
        ref.watch(currentGoalProgressProvider(year, month: currentMonth));
    final allGoalsAsync = ref.watch(goalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Statistiques',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_sharing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.ios_share_rounded),
              tooltip: 'Partager',
              onPressed: _shareScreenshot,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final now = DateTime.now();
          ref.invalidate(bookshelfStatsProvider);
          ref.invalidate(monthlyStatsProvider(now.year));
          ref.invalidate(monthlyDurationProvider(now.year));
          ref.invalidate(topGenresProvider);
          ref.invalidate(currentGoalProgressProvider);
          ref.invalidate(goalsProvider);
        },
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Erreur : $err',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: const Color(0xFFEF4444)),
              ),
            ),
          ),
          data: (stats) {
            final hasData = stats.totalBooks > 0 ||
                stats.totalPages > 0 ||
                stats.totalSessions > 0 ||
                stats.totalTime.inMinutes > 0;

            if (!hasData) {
              return ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: const EmptyState(
                      emoji: '📊',
                      title: 'Commencez à lire pour voir vos statistiques',
                      subtitle:
                          'Ajoutez un livre et enregistrez vos sessions de lecture.',
                    ),
                  ),
                ],
              );
            }

            final totalMinutes = stats.totalTime.inMinutes;
            final streakDays = stats.currentStreak;

            // ── Resolve goal data ──────────────────────────────────
            // Monthly pages goal from currentGoalProgressProvider
            final GoalProgress? monthlyGoalData =
                monthlyGoalAsync.valueOrNull;
            final _GoalInfo monthlyGoal;
            if (monthlyGoalData != null && monthlyGoalData.hasGoal) {
              monthlyGoal = _GoalInfo(
                target: monthlyGoalData.target,
                progress: monthlyGoalData.progress,
                percentage: monthlyGoalData.percentage,
              );
            } else {
              monthlyGoal = const _GoalInfo(
                target: 0,
                progress: 0,
                percentage: 0.0,
              );
            }

            // Yearly books goal from allGoalsAsync
            final List<ReadingGoal>? allGoals = allGoalsAsync.valueOrNull;
            ReadingGoal? booksGoal;
            if (allGoals != null) {
              final matches = allGoals.where(
                (g) =>
                    g.type == 'books' &&
                    g.year == year &&
                    g.month == null,
              );
              if (matches.isNotEmpty) {
                booksGoal = matches.first;
              }
            }
            final _GoalInfo yearlyBooksGoal;
            if (booksGoal != null) {
              yearlyBooksGoal = _GoalInfo(
                target: booksGoal.target,
                progress: stats.totalBooks,
                percentage: booksGoal.target > 0
                    ? (stats.totalBooks / booksGoal.target).clamp(0.0, 1.0)
                    : 0.0,
              );
            } else {
              yearlyBooksGoal = const _GoalInfo(
                target: 0,
                progress: 0,
                percentage: 0.0,
              );
            }

            return RepaintBoundary(
              key: _screenshotKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  // ── 1. Cercle "XX livres lus" ──────────────────────
                  _BooksCircle(
                    count: stats.totalBooks,
                    palette: palette,
                  ),
                  const SizedBox(height: 24),

                  // ── 2. 3 cartes horizontales ───────────────────────
                  _StatsRow(
                    pages: stats.totalPages,
                    minutes: totalMinutes,
                    days: streakDays,
                    palette: palette,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 28),

                  // ── 3. Objectifs ────────────────────────────────────
                  _GoalsSection(
                    monthlyGoal: monthlyGoal,
                    yearlyBooksGoal: yearlyBooksGoal,
                    palette: palette,
                    isDark: isDark,
                    currentMonth: currentMonth,
                  ),
                  const SizedBox(height: 28),

                  // ── 4. Graphique barres : Pages par mois ───────────
                  _SectionHeader(title: 'Pages par mois'),
                  const SizedBox(height: 12),
                  monthlyPagesAsync.when(
                    loading: () => const SizedBox(height: 200),
                    error: (err, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Erreur chargement : $err',
                        style: GoogleFonts.inter(
                          color: isDark
                              ? palette.textOnDark.withValues(alpha: 0.5)
                              : palette.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    data: (monthlyData) => _PagesBarChart(
                      data: monthlyData,
                      currentMonth: currentMonth,
                      palette: palette,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── 5. Top genres ──────────────────────────────────
                  _SectionHeader(title: 'Genres favoris'),
                  const SizedBox(height: 12),
                  genresAsync.when(
                    loading: () => const SizedBox(height: 48),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (genres) {
                      if (genres.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Ajoutez des genres à vos livres.',
                            style: GoogleFonts.inter(
                              color: isDark
                                  ? palette.textOnDark.withValues(alpha: 0.5)
                                  : palette.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        );
                      }
                      return _GenreChips(
                        genres: genres,
                        palette: palette,
                        isDark: isDark,
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // ── 6. Ce mois-ci ──────────────────────────────────
                  _SectionHeader(title: 'Ce mois-ci'),
                  const SizedBox(height: 12),
                  monthlyPagesAsync.when(
                    loading: () => const SizedBox(height: 80),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (monthlyData) {
                      final pagesThisMonth =
                          monthlyData[currentMonth] ?? 0;
                      final durationThisMonth = monthlyDurationAsync.when(
                        data: (durationData) => Duration(
                          seconds: durationData[currentMonth] ?? 0,
                        ),
                        loading: () => Duration.zero,
                        error: (_, _) => Duration.zero,
                      );
                      return _MonthlyProgress(
                        pagesThisMonth: pagesThisMonth,
                        durationThisMonth: durationThisMonth,
                        monthlyGoal: monthlyGoal,
                        palette: palette,
                        isDark: isDark,
                      );
                    },
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Objectifs section — inline goals display
// ──────────────────────────────────────────────────────────────────────────────

class _GoalsSection extends StatelessWidget {
  final _GoalInfo monthlyGoal;
  final _GoalInfo yearlyBooksGoal;
  final ThemePalette palette;
  final bool isDark;
  final int currentMonth;

  const _GoalsSection({
    required this.monthlyGoal,
    required this.yearlyBooksGoal,
    required this.palette,
    required this.isDark,
    required this.currentMonth,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? palette.textOnDark : palette.textPrimary;
    final textSecondary =
        isDark ? palette.textOnDark.withValues(alpha: 0.5) : palette.textSecondary;
    final successColor = const Color(0xFF6B8E4E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Objectifs'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDark ? palette.surfaceCardDark : palette.surfaceCardLight,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // ---- Monthly pages goal ----
              _buildGoalRow(
                icon: Icons.auto_stories_rounded,
                label: 'Pages mensuelles (${_frenchMonth(currentMonth)})',
                current: monthlyGoal.progress,
                target: monthlyGoal.target,
                hasGoal: monthlyGoal.hasGoal,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                successColor: successColor,
                palette: palette,
              ),
              if (yearlyBooksGoal.hasGoal) ...[
                const SizedBox(height: 16),
                // ---- Yearly books goal ----
                _buildGoalRow(
                  icon: Icons.menu_book_rounded,
                  label: 'Livres annuels',
                  current: yearlyBooksGoal.progress,
                  target: yearlyBooksGoal.target,
                  hasGoal: yearlyBooksGoal.hasGoal,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  successColor: successColor,
                  palette: palette,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoalRow({
    required IconData icon,
    required String label,
    required int current,
    required int target,
    required bool hasGoal,
    required Color textPrimary,
    required Color textSecondary,
    required Color successColor,
    required ThemePalette palette,
  }) {
    if (!hasGoal) {
      return Row(
        children: [
          Icon(icon, size: 20, color: palette.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
          ),
          Text(
            'Pas d\'objectif',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: textSecondary,
            ),
          ),
        ],
      );
    }

    final percentage =
        target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final barColor = percentage >= 1.0 ? successColor : palette.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: palette.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
            ),
            Text(
              '$current / $target',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Cercle "XX livres lus"
// ──────────────────────────────────────────────────────────────────────────────

class _BooksCircle extends StatelessWidget {
  final int count;
  final ThemePalette palette;
  const _BooksCircle({required this.count, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              palette.primary,
              palette.primaryLight,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: palette.primary.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              count.toString(),
              style: GoogleFonts.outfit(
                fontSize: 42,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              count > 1 ? 'livres lus' : 'livre lu',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 3 cartes horizontales : Pages | Minutes | Jours
// ──────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int pages;
  final int minutes;
  final int days;
  final ThemePalette palette;
  final bool isDark;

  const _StatsRow({
    required this.pages,
    required this.minutes,
    required this.days,
    required this.palette,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            icon: Icons.auto_stories_rounded,
            value: _compactNumber(pages),
            label: 'Pages',
            color: palette.primary,
            palette: palette,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatCard(
            icon: Icons.schedule_rounded,
            value: _formatMinutesCompact(minutes),
            label: 'Minutes',
            color: palette.primary,
            palette: palette,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatCard(
            icon: Icons.local_fire_department_rounded,
            value: days.toString(),
            label: 'Jours',
            color: const Color(0xFFD97A60),
            palette: palette,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  String _formatMinutesCompact(int mins) {
    if (mins < 60) return mins.toString();
    final h = mins ~/ 60;
    final m = mins % 60;
    return m > 0 ? '${h}h$m' : '${h}h';
  }
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final ThemePalette palette;
  final bool isDark;

  const _MiniStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.palette,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? palette.surfaceCardDark : palette.surfaceCardLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? palette.textOnDark : palette.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? palette.textOnDark.withValues(alpha: 0.5)
                  : palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Section header
// ──────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Graphique à barres — Pages par mois (6 derniers mois)
// ──────────────────────────────────────────────────────────────────────────────

class _PagesBarChart extends StatelessWidget {
  final Map<int, int> data;
  final int currentMonth;
  final ThemePalette palette;
  final bool isDark;

  const _PagesBarChart({
    required this.data,
    required this.currentMonth,
    required this.palette,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Derniers 6 mois
    final months = List.generate(6, (i) {
      final m = currentMonth - 5 + i;
      if (m < 1) return m + 12;
      if (m > 12) return m - 12;
      return m;
    });

    final values = months.map((m) => (data[m] ?? 0).toDouble()).toList();
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxY > 0 ? maxY * 1.25 : 50.0;

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? palette.surfaceCardDark : palette.surfaceCardLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: effectiveMax,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final month = months[group.x.toInt()];
                return BarTooltipItem(
                  '${_frenchMonth(month)} : ${rod.toY.toInt()} pages',
                  TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= months.length) {
                    return const SizedBox.shrink();
                  }
                  final month = months[idx];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _frenchMonth(month),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? palette.textOnDark.withValues(alpha: 0.5)
                            : palette.textSecondary,
                      ),
                    ),
                  );
                },
                reservedSize: 24,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            horizontalInterval: effectiveMax > 0
                ? (effectiveMax / 4).ceilToDouble().clamp(1, double.infinity)
                : 10,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.grey.withValues(alpha: 0.1),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(months.length, (index) {
            final value = values[index];
            final month = months[index];
            final isCurrent = month == currentMonth;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: value,
                  color: isCurrent
                      ? palette.primary
                      : palette.primary.withValues(alpha: 0.55),
                  width: 20,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(5),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Genres en chips horizontaux
// ──────────────────────────────────────────────────────────────────────────────

class _GenreChips extends StatelessWidget {
  final Map<String, int> genres;
  final ThemePalette palette;
  final bool isDark;

  const _GenreChips({
    required this.genres,
    required this.palette,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: genres.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final entry = genres.entries.elementAt(index);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isDark
                  ? palette.primary.withValues(alpha: 0.15)
                  : palette.primary.withValues(alpha: 0.08),
              border: Border.all(
                color: isDark
                    ? palette.primary.withValues(alpha: 0.25)
                    : palette.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.key,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? palette.primaryLight : palette.primary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isDark
                        ? palette.primary.withValues(alpha: 0.3)
                        : palette.primary.withValues(alpha: 0.12),
                  ),
                  child: Text(
                    '${entry.value}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? palette.primaryLight : palette.primary,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Ce mois-ci — progression (REAL goal from DB)
// ──────────────────────────────────────────────────────────────────────────────

class _MonthlyProgress extends StatelessWidget {
  final int pagesThisMonth;
  final Duration durationThisMonth;
  final _GoalInfo monthlyGoal;
  final ThemePalette palette;
  final bool isDark;

  const _MonthlyProgress({
    required this.pagesThisMonth,
    required this.durationThisMonth,
    required this.monthlyGoal,
    required this.palette,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final goalPages = monthlyGoal.hasGoal ? monthlyGoal.target : 0;
    final progress = goalPages > 0
        ? (pagesThisMonth / goalPages).clamp(0.0, 1.0)
        : 0.0;

    // Format duration for display
    String _formatDuration(Duration d) {
      final hours = d.inHours;
      final minutes = d.inMinutes.remainder(60);
      if (hours > 0) {
        return minutes > 0 ? '${hours}h ${minutes}min' : '${hours}h';
      }
      return '${minutes} min';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? palette.surfaceCardDark : palette.surfaceCardLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne : Pages lues ce mois
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_stories_rounded,
                      size: 16, color: palette.primary),
                  const SizedBox(width: 6),
                  Text(
                    '$pagesThisMonth pages lues',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? palette.textOnDark : palette.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                monthlyGoal.hasGoal ? '$goalPages pages' : '',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? palette.textOnDark.withValues(alpha: 0.5)
                      : palette.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Ligne : Temps de lecture ce mois
          Row(
            children: [
              Icon(Icons.schedule_rounded,
                  size: 16, color: palette.primary),
              const SizedBox(width: 6),
              Text(
                '${_formatDuration(durationThisMonth)} de lecture',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? palette.textOnDark.withValues(alpha: 0.7)
                      : palette.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Barre de progression
          if (monthlyGoal.hasGoal) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1.0
                      ? const Color(0xFF6B8E4E)
                      : palette.primary,
                ),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Message objectif ou pas d'objectif
          if (!monthlyGoal.hasGoal)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: palette.primary.withValues(alpha: 0.08),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 16,
                    color: palette.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Définir un objectif',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: palette.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
