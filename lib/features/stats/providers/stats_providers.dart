import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:lecto/core/database/providers.dart';

part 'stats_providers.g.dart';

// ============================================================
// Bookshelf stats
// ============================================================

/// Aggregated bookshelf statistics: total books finished, total pages
/// read, total reading time, and the current reading streak.
class BookshelfStats {
  final int totalBooks;
  final int totalPages;
  final int totalSessions;
  final Duration totalTime;
  final int currentStreak;

  const BookshelfStats({
    this.totalBooks = 0,
    this.totalPages = 0,
    this.totalSessions = 0,
    this.totalTime = Duration.zero,
    this.currentStreak = 0,
  });
}

/// Provides aggregated bookshelf statistics.
@Riverpod(keepAlive: true)
Future<BookshelfStats> bookshelfStats(BookshelfStatsRef ref) async {
  final db = ref.watch(databaseProvider);
  return BookshelfStats(
    totalBooks: db.totalBooksRead(),
    totalPages: db.totalPagesRead(),
    totalSessions: db.totalSessions(),
    totalTime: db.totalReadingTime(),
    currentStreak: db.currentStreak(),
  );
}

// ============================================================
// Monthly pages
// ============================================================

/// Provides a map of month (1–12) to total pages read in that month
/// for the given [year].
@Riverpod(keepAlive: true)
Future<Map<int, int>> monthlyStats(MonthlyStatsRef ref, int year) async {
  final db = ref.watch(databaseProvider);
  return db.monthlyPages(year);
}

// ============================================================
// Monthly duration
// ============================================================

/// Provides a map of month (1–12) to total [Duration] spent reading
/// in that month for the given [year].
@Riverpod(keepAlive: true)
Future<Map<int, int>> monthlyDuration(MonthlyDurationRef ref, int year) async {
  final db = ref.watch(databaseProvider);
  return db.monthlyDuration(year);
}

// ============================================================
// Top genres
// ============================================================

/// Provides a map of genre/category to the number of finished books
/// in that genre. Sorted by count descending, limited to the top 5.
@Riverpod(keepAlive: true)
Future<Map<String, int>> topGenres(TopGenresRef ref) async {
  final db = ref.watch(databaseProvider);
  return db.topGenres();
}
