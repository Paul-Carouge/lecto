import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lecto/core/database/database.dart';
import 'package:lecto/core/theme/app_theme.dart';
import 'package:lecto/core/database/providers.dart';
import 'package:lecto/features/sessions/providers/session_providers.dart';
import 'package:lecto/features/sessions/widgets/session_card.dart';
import 'package:lecto/shared/widgets/empty_state.dart';

/// List of all reading sessions grouped by date.
///
/// Each item shows book title, duration, pages read, time of day.
/// Swipe to delete.
class SessionHistoryScreen extends ConsumerWidget {
  const SessionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(recentSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reading History',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (sessions) {
          if (sessions.isEmpty) {
            return const EmptyState(
              emoji: '⏱️',
              title: 'No reading sessions yet',
              subtitle: 'Start a reading session to track your progress!',
            );
          }

          // Group by date
          final grouped = <DateTime, List<ReadingSession>>{};
          for (final session in sessions) {
            final dateKey = DateTime(
              session.startTime.year,
              session.startTime.month,
              session.startTime.day,
            );
            grouped.putIfAbsent(dateKey, () => []).add(session);
          }

          // Sort dates descending
          final sortedDates = grouped.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(recentSessionsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final date = sortedDates[index];
                final daySessions = grouped[date]!;
                return _DateGroup(
                  date: date,
                  sessions: daySessions,
                  onDelete: (session) async {
                    final db = ref.read(databaseProvider);
                    db.deleteSession(session.id);
                    ref.invalidate(recentSessionsProvider);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _DateGroup extends StatelessWidget {
  final DateTime date;
  final List<ReadingSession> sessions;
  final void Function(ReadingSession) onDelete;

  const _DateGroup({
    required this.date,
    required this.sessions,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = date == today;
    final yesterday = today.subtract(const Duration(days: 1));
    final isYesterday = date == yesterday;

    String label;
    if (isToday) {
      label = 'Today';
    } else if (isYesterday) {
      label = 'Yesterday';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      label = '${months[date.month - 1]} ${date.day}, ${date.year}';
    }

    final totalDuration = sessions.fold<int>(
      0,
      (sum, s) => sum + (s.durationSeconds ?? 0),
    );
    final totalPages = sessions.fold<int>(
      0,
      (sum, s) => sum + (s.pagesRead ?? 0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Row(
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '${sessions.length} session${sessions.length == 1 ? '' : 's'}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              if (totalDuration > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '· ${_formatDurationShort(totalDuration)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
              if (totalPages > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '· ${totalPages}p',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        ...sessions.map((session) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: SessionCard(
                session: session,
                onDelete: () => onDelete(session),
              ),
            )),
      ],
    );
  }

  String _formatDurationShort(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}
