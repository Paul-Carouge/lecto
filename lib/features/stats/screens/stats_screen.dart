import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lecto/core/theme/app_theme.dart';
import 'package:lecto/core/utils/formatters.dart';
import 'package:lecto/features/stats/providers/stats_providers.dart';
import 'package:lecto/shared/widgets/stat_card.dart';
import 'package:lecto/shared/widgets/empty_state.dart';

/// Full statistics dashboard.
///
/// Shows:
///   - Top summary cards: Total books, total pages, total time, current streak
///   - Monthly pages bar chart (fl_chart)
///   - Monthly duration chart
///   - Top genres list
///   - Books read this year count
///   - Beautiful, scrollable, clean layout
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = DateTime.now().year;
    final statsAsync = ref.watch(bookshelfStatsProvider);
    final monthlyPagesAsync = ref.watch(monthlyStatsProvider(year));
    final monthlyDurationAsync = ref.watch(monthlyDurationProvider(year));
    final genresAsync = ref.watch(topGenresProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Statistics',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary cards
              Text(
                'Overview',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Books Read',
                      value: stats.totalBooks.toString(),
                      icon: Icons.check_circle_rounded,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      label: 'Pages Read',
                      value: Formatters.formatCompactNumber(stats.totalPages),
                      icon: Icons.auto_stories_rounded,
                      color: AppTheme.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Reading Time',
                      value: Formatters.formatDuration(stats.totalTime),
                      icon: Icons.schedule_rounded,
                      color: AppTheme.success,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      label: 'Day Streak',
                      value: '${stats.currentStreak}',
                      icon: Icons.local_fire_department_rounded,
                      color: AppTheme.warning,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Monthly pages chart
              Text(
                'Pages per Month',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              monthlyPagesAsync.when(
                loading: () => const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => Text('Error: $err'),
                data: (monthlyData) => _PagesBarChart(
                  data: monthlyData,
                  year: year,
                ),
              ),

              const SizedBox(height: 28),

              // Monthly duration chart
              Text(
                'Minutes per Month',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              monthlyDurationAsync.when(
                loading: () => const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => Text('Error: $err'),
                data: (durationData) => _DurationBarChart(
                  data: durationData,
                  year: year,
                ),
              ),

              const SizedBox(height: 28),

              // Top genres
              Text(
                'Top Genres',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              genresAsync.when(
                loading: () => const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (genres) {
                  if (genres.isEmpty) {
                    return const EmptyState(
                      emoji: '🏷️',
                      title: 'No genres yet',
                      subtitle: 'Genres will appear as you finish books.',
                    );
                  }
                  return Column(
                    children: genres.entries.map((entry) {
                      final maxCount = genres.values.first;
                      final ratio = entry.value / maxCount;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _GenreRow(
                          genre: entry.key,
                          count: entry.value,
                          ratio: ratio,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _PagesBarChart extends StatelessWidget {
  final Map<int, int> data;
  final int year;

  const _PagesBarChart({required this.data, required this.year});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxY = data.values.reduce((a, b) => a > b ? a : b).toDouble();
    final now = DateTime.now();

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? AppTheme.surfaceCard : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY > 0 ? maxY * 1.2 : 50,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final month = group.x.toInt();
                return BarTooltipItem(
                  '${Formatters.formatMonth(month)}: ${rod.toY.toInt()} pages',
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
                  final month = value.toInt();
                  final label = Formatters.formatMonth(month).substring(0, 3);
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  );
                },
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
            horizontalInterval: maxY > 0 ? (maxY / 4).ceilToDouble() : 10,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.withValues(alpha: 0.1),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(12, (index) {
            final month = index + 1;
            final value = data[month]?.toDouble() ?? 0;
            final isCurrentMonth = month == now.month && year == now.year;

            return BarChartGroupData(
              x: month,
              barRods: [
                BarChartRodData(
                  toY: value,
                  color: isCurrentMonth ? AppTheme.accent : AppTheme.primary,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
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

class _DurationBarChart extends StatelessWidget {
  final Map<int, int> data;
  final int year;

  const _DurationBarChart({required this.data, required this.year});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final values = data.values.map((s) => (s / 60).toDouble()).toList();
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final now = DateTime.now();

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? AppTheme.surfaceCard : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY > 0 ? maxY * 1.2 : 50,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final month = group.x.toInt();
                final minutes = rod.toY.toInt();
                final hours = minutes ~/ 60;
                final mins = minutes % 60;
                final timeStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
                return BarTooltipItem(
                  '${Formatters.formatMonth(month)}: $timeStr',
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
                  final month = value.toInt();
                  final label = Formatters.formatMonth(month).substring(0, 3);
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  );
                },
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
            horizontalInterval: maxY > 0 ? (maxY / 4).ceilToDouble() : 10,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.withValues(alpha: 0.1),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(12, (index) {
            final month = index + 1;
            final value = ((data[month] ?? 0) / 60).toDouble();
            final isCurrentMonth = month == now.month && year == now.year;

            return BarChartGroupData(
              x: month,
              barRods: [
                BarChartRodData(
                  toY: value,
                  color: isCurrentMonth ? AppTheme.success : AppTheme.accent,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
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

class _GenreRow extends StatelessWidget {
  final String genre;
  final int count;
  final double ratio;

  const _GenreRow({
    required this.genre,
    required this.count,
    required this.ratio,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                genre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Text(
              '$count book${count == 1 ? '' : 's'}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
