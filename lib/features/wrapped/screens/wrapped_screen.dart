import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lecto/core/theme/app_theme.dart';
import 'package:lecto/core/utils/formatters.dart';
import 'package:lecto/features/wrapped/providers/wrapped_providers.dart';
import 'package:lecto/shared/widgets/empty_state.dart';
import 'package:lecto/shared/widgets/stat_card.dart';

/// Monthly reading recap (like Spotify Wrapped).
///
/// Shows:
///   - Top stats: books read, pages, time, streak
///   - Top genre
///   - Favorite author
///   - Books completed
///   - Beautiful card-based layout with gradient backgrounds
///   - Month picker
class WrappedScreen extends ConsumerStatefulWidget {
  final int? initialMonth;
  final int? initialYear;

  const WrappedScreen({
    super.key,
    this.initialMonth,
    this.initialYear,
  });

  @override
  ConsumerState<WrappedScreen> createState() => _WrappedScreenState();
}

class _WrappedScreenState extends ConsumerState<WrappedScreen> {
  late int _month;
  late int _year;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = widget.initialMonth ?? now.month;
    _year = widget.initialYear ?? now.year;
  }

  void _previousMonth() {
    setState(() {
      _month--;
      if (_month == 0) {
        _month = 12;
        _year--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      _month++;
      if (_month > 12) {
        _month = 1;
        _year++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final wrappedAsync = ref.watch(monthlyWrappedProvider(_month, _year));
    final now = DateTime.now();
    final isCurrentMonth = _month == now.month && _year == now.year;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mon bilan',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              // Share wrapped - could use share_plus
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Month picker
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: _previousMonth,
                ),
                Expanded(
                  child: Text(
                    Formatters.formatMonthYear(_month, _year),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: isCurrentMonth ? null : _nextMonth,
                  color: isCurrentMonth ? AppTheme.textSecondary.withValues(alpha: 0.3) : null,
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: wrappedAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (wrapped) {
                if (wrapped.sessionCount == 0) {
                  return EmptyState(
                    emoji: '📊',
                    title: 'Aucune activité',
                    subtitle: 'Lisez des livres ce mois-ci pour voir votre bilan !',
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Hero stats
                      _buildHeroCard(wrapped),

                      const SizedBox(height: 20),

                      // Stats grid
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              label: 'Livres terminés',
                              value: wrapped.booksFinished.toString(),
                              icon: Icons.check_circle_rounded,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: StatCard(
                              label: 'Livres commencés',
                              value: wrapped.booksStarted.toString(),
                              icon: Icons.play_circle_rounded,
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
                              label: 'Pages lues',
                              value: Formatters.formatCompactNumber(wrapped.totalPages),
                              icon: Icons.auto_stories_rounded,
                              color: AppTheme.success,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: StatCard(
                              label: 'Temps de lecture',
                              value: Formatters.formatDuration(wrapped.totalDuration),
                              icon: Icons.schedule_rounded,
                              color: AppTheme.warning,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Session stats
                      _buildInfoCard(
                        'Sessions & habitudes',
                        Icons.timer_rounded,
                        [
                          _InfoRow('Sessions', '${wrapped.sessionCount}'),
                          _InfoRow(
                            'Moy. séance',
                            Formatters.formatDuration(wrapped.averageSessionDuration),
                          ),
                          _InfoRow(
                            'Moy. pages/séance',
                            wrapped.averagePagesPerSession.toStringAsFixed(1),
                          ),
                          _InfoRow(
                            'Session la + longue',
                            Formatters.formatDuration(wrapped.longestSession),
                          ),
                          _InfoRow(
                            'Max pages',
                            '${wrapped.mostPagesInSession} pages',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Genre & favorites
                      if (wrapped.topGenre != null)
                        _buildInfoCard(
                          'Genre préféré',
                          Icons.category_rounded,
                          [
                            _InfoRow('Genre le plus lu', wrapped.topGenre!),
                          ],
                          accentColor: AppTheme.accent,
                        ),

                      const SizedBox(height: 24),

                      // Insight
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primary.withValues(alpha: 0.1),
                              AppTheme.accent.withValues(alpha: 0.08),
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '💡',
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              wrapped.insight,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(MonthlyWrapped wrapped) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Votre bilan du mois',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.formatMonthYear(_month, _year),
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _HeroStat(
                value: '${wrapped.totalPages}',
                label: 'Pages',
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              _HeroStat(
                value: Formatters.formatDuration(wrapped.totalDuration),
                label: 'Temps',
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              _HeroStat(
                value: '${wrapped.sessionCount}',
                label: 'Séances',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    IconData icon,
    List<_InfoRow> rows, {
    Color? accentColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = accentColor ?? AppTheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;

  const _HeroStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
