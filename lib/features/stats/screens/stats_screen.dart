import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lecto/core/theme/app_theme.dart';
import 'package:lecto/core/utils/formatters.dart';
import 'package:lecto/features/stats/providers/stats_providers.dart';
import 'package:lecto/shared/widgets/empty_state.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Palette terracotta
// ──────────────────────────────────────────────────────────────────────────────
const Color _terracotta = Color(0xFFC85A3E);
const Color _terracottaLight = Color(0xFFE8836A);
const Color _terracottaBg = Color(0xFFFDF3F0);

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final year = now.year;
    final currentMonth = now.month;

    final statsAsync = ref.watch(bookshelfStatsProvider);
    final monthlyPagesAsync = ref.watch(monthlyStatsProvider(year));
    final genresAsync = ref.watch(topGenresProvider);

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
          ref.invalidate(bookshelfStatsProvider);
          ref.invalidate(monthlyStatsProvider(year));
          ref.invalidate(topGenresProvider);
        },
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Erreur : $err',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppTheme.error),
              ),
            ),
          ),
          data: (stats) {
            final hasData = stats.totalBooks > 0 ||
                stats.totalPages > 0 ||
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

            return RepaintBoundary(
              key: _screenshotKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  // ── 1. Cercle "XX livres lus" ──────────────────────
                  _BooksCircle(count: stats.totalBooks),
                  const SizedBox(height: 24),

                  // ── 2. 3 cartes horizontales ───────────────────────
                  _StatsRow(
                    pages: stats.totalPages,
                    minutes: totalMinutes,
                    days: streakDays,
                  ),
                  const SizedBox(height: 28),

                  // ── 3. Graphique barres : Pages par mois ───────────
                  _SectionHeader(title: 'Pages par mois'),
                  const SizedBox(height: 12),
                  monthlyPagesAsync.when(
                    loading: () => _ChartPlaceholder(),
                    error: (err, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Erreur chargement : $err',
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    data: (monthlyData) => _PagesBarChart(
                      data: monthlyData,
                      currentMonth: currentMonth,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── 4. Top genres ──────────────────────────────────
                  _SectionHeader(title: 'Genres favoris'),
                  const SizedBox(height: 12),
                  genresAsync.when(
                    loading: () => _ChartPlaceholder(height: 48),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (genres) {
                      if (genres.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Ajoutez des genres à vos livres.',
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        );
                      }
                      return _GenreChips(genres: genres);
                    },
                  ),
                  const SizedBox(height: 28),

                  // ── 5. Ce mois-ci ──────────────────────────────────
                  _SectionHeader(title: 'Ce mois-ci'),
                  const SizedBox(height: 12),
                  monthlyPagesAsync.when(
                    loading: () => _ChartPlaceholder(height: 80),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (monthlyData) {
                      final pagesThisMonth =
                          monthlyData[currentMonth] ?? 0;
                      return _MonthlyProgress(
                        pagesThisMonth: pagesThisMonth,
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
// Cercle "XX livres lus"
// ──────────────────────────────────────────────────────────────────────────────

class _BooksCircle extends StatelessWidget {
  final int count;
  const _BooksCircle({required this.count});

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
              _terracotta,
              _terracottaLight,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: _terracotta.withValues(alpha: 0.35),
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

  const _StatsRow({
    required this.pages,
    required this.minutes,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            icon: Icons.auto_stories_rounded,
            value: Formatters.formatCompactNumber(pages),
            label: 'Pages',
            color: _terracotta,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatCard(
            icon: Icons.schedule_rounded,
            value: _formatMinutesCompact(minutes),
            label: 'Minutes',
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatCard(
            icon: Icons.local_fire_department_rounded,
            value: days.toString(),
            label: 'Jours',
            color: AppTheme.warning,
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

  const _MiniStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? AppTheme.surfaceCard : Colors.white,
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
              color: isDark ? Colors.white : AppTheme.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
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

  const _PagesBarChart({
    required this.data,
    required this.currentMonth,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        color: isDark ? AppTheme.surfaceCard : Colors.white,
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
                  '${Formatters.formatMonth(month)} : ${rod.toY.toInt()} pages',
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
                      Formatters.formatMonth(month).substring(0, 3),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
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
                  color: isCurrent ? _terracotta : _terracotta.withValues(alpha: 0.55),
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
  const _GenreChips({required this.genres});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  ? _terracotta.withValues(alpha: 0.15)
                  : _terracottaBg,
              border: Border.all(
                color: isDark
                    ? _terracotta.withValues(alpha: 0.25)
                    : _terracotta.withValues(alpha: 0.2),
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
                    color: isDark ? _terracottaLight : _terracotta,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isDark
                        ? _terracotta.withValues(alpha: 0.3)
                        : _terracotta.withValues(alpha: 0.12),
                  ),
                  child: Text(
                    '${entry.value}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? _terracottaLight : _terracotta,
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
// Ce mois-ci — progression
// ──────────────────────────────────────────────────────────────────────────────

class _MonthlyProgress extends StatelessWidget {
  final int pagesThisMonth;
  final bool isDark;

  const _MonthlyProgress({
    required this.pagesThisMonth,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Objectif par défaut : 500 pages/mois
    const goalPages = 500;
    final progress = (pagesThisMonth / goalPages).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? AppTheme.surfaceCard : Colors.white,
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
          // Ligne : Pages lues ce mois / Objectif
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$pagesThisMonth pages lues',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              Text(
                '$goalPages pages',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? AppTheme.success : _terracotta,
              ),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 14),

          // Message objectif
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Les objectifs seront bientôt disponibles !',
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: _terracotta.withValues(alpha: 0.08),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 16,
                    color: _terracotta,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Définir un objectif',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _terracotta,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Chart placeholder (loading)
// ──────────────────────────────────────────────────────────────────────────────

class _ChartPlaceholder extends StatelessWidget {
  final double height;
  const _ChartPlaceholder({this.height = 200});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
