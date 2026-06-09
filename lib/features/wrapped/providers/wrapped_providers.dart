import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:lecto/core/database/database.dart';
import 'package:lecto/core/database/providers.dart';

part 'wrapped_providers.g.dart';

// ============================================================
// Monthly wrapped data
// ============================================================

/// Aggregated statistics for the monthly "wrapped" view.
///
/// Similar to Spotify Wrapped, but for your reading habits.
class MonthlyWrapped {
  /// The month (1–12).
  final int month;

  /// The year.
  final int year;

  /// Total pages read this month.
  final int totalPages;

  /// Total reading time this month.
  final Duration totalDuration;

  /// Number of books finished this month.
  final int booksFinished;

  /// Number of books started this month.
  final int booksStarted;

  /// Number of reading sessions this month.
  final int sessionCount;

  /// Average session duration.
  final Duration averageSessionDuration;

  /// Average pages per session.
  final double averagePagesPerSession;

  /// The most-read genre this month (or null).
  final String? topGenre;

  /// The longest reading session this month.
  final Duration longestSession;

  /// The most pages read in a single session this month.
  final int mostPagesInSession;

  /// A random fun fact or insight.
  final String insight;

  const MonthlyWrapped({
    required this.month,
    required this.year,
    this.totalPages = 0,
    this.totalDuration = Duration.zero,
    this.booksFinished = 0,
    this.booksStarted = 0,
    this.sessionCount = 0,
    this.averageSessionDuration = Duration.zero,
    this.averagePagesPerSession = 0.0,
    this.topGenre,
    this.longestSession = Duration.zero,
    this.mostPagesInSession = 0,
    this.insight = '',
  });
}

/// Provides all data needed for the monthly "wrapped" view for a given
/// [month] and [year].
@Riverpod(keepAlive: true)
Future<MonthlyWrapped> monthlyWrapped(MonthlyWrappedRef ref, int month, int year) async {
  final db = ref.watch(databaseProvider);

  // Fetch sessions for the given month/year
  final allSessions = db.getAllSessions();
  final monthlySessions = allSessions.where((s) =>
      s.startTime.year == year && s.startTime.month == month).toList();

  if (monthlySessions.isEmpty) {
    return MonthlyWrapped(month: month, year: year, insight: 'No reading activity this month. Time to pick up a book!');
  }

  // Compute stats
  final sessionCount = monthlySessions.length;
  var totalPages = 0;
  var totalSeconds = 0;
  var longestSessionSeconds = 0;
  var mostPagesInSession = 0;
  final genreCount = <String, int>{};

  for (final session in monthlySessions) {
    totalPages += session.pagesRead ?? 0;
    totalSeconds += session.durationSeconds ?? 0;
    if ((session.durationSeconds ?? 0) > longestSessionSeconds) {
      longestSessionSeconds = session.durationSeconds ?? 0;
    }
    if ((session.pagesRead ?? 0) > mostPagesInSession) {
      mostPagesInSession = session.pagesRead ?? 0;
    }
  }

  final totalDuration = Duration(seconds: totalSeconds);
  final longestSession = Duration(seconds: longestSessionSeconds);
  final averageSessionDuration = sessionCount > 0
      ? Duration(seconds: (totalSeconds / sessionCount).round())
      : Duration.zero;
  final averagePagesPerSession = sessionCount > 0
      ? totalPages / sessionCount
      : 0.0;

  // Count books finished and started this month
  final allBooks = db.getAllBooks();
  var booksFinished = 0;
  var booksStarted = 0;

  for (final book in allBooks) {
    if (book.dateFinished != null &&
        book.dateFinished!.year == year &&
        book.dateFinished!.month == month) {
      booksFinished++;
    }
    if (book.dateStarted != null &&
        book.dateStarted!.year == year &&
        book.dateStarted!.month == month) {
      booksStarted++;
    }
    // Collect genres from finished books
    if (book.status == ReadingStatus.finished) {
      for (final cat in book.categories) {
        genreCount[cat] = (genreCount[cat] ?? 0) + 1;
      }
    }
  }

  // Find top genre
  String? topGenre;
  if (genreCount.isNotEmpty) {
    final sorted = genreCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    topGenre = sorted.first.key;
  }

  // Generate a fun insight
  final insight = _generateInsight(
    totalPages: totalPages,
    totalDuration: totalDuration,
    booksFinished: booksFinished,
    sessionCount: sessionCount,
  );

  return MonthlyWrapped(
    month: month,
    year: year,
    totalPages: totalPages,
    totalDuration: totalDuration,
    booksFinished: booksFinished,
    booksStarted: booksStarted,
    sessionCount: sessionCount,
    averageSessionDuration: averageSessionDuration,
    averagePagesPerSession: averagePagesPerSession,
    topGenre: topGenre,
    longestSession: longestSession,
    mostPagesInSession: mostPagesInSession,
    insight: insight,
  );
}

// ============================================================
// Generate and store a wrapped snapshot
// ============================================================

/// Generates a monthly wrapped snapshot and stores it.
///
/// This can be used to "freeze" a wrapped view at a point in time,
/// or to trigger a regeneration.
@Riverpod(keepAlive: true)
class GenerateWrapped extends _$GenerateWrapped {
  @override
  Future<MonthlyWrapped> build(int month, int year) {
    throw UnimplementedError(
      'Use ref.read(generateWrappedProvider(month, year).notifier).generate()',
    );
  }

  /// Generates the wrapped data for the given [month] and [year].
  ///
  /// In the future, this could also snapshot the data to a dedicated table
  /// for historical comparisons.
  Future<MonthlyWrapped> generate() async {
    final wrapped = await ref.read(monthlyWrappedProvider(month, year).future);
    return wrapped;
  }
}

// ============================================================
// Internal helpers
// ============================================================

/// Generates a human-readable insight string based on reading stats.
String _generateInsight({
  required int totalPages,
  required Duration totalDuration,
  required int booksFinished,
  required int sessionCount,
}) {
  final insights = <String>[];

  if (booksFinished >= 5) {
    insights.add('You devoured $booksFinished books this month — a true reading marathon!');
  } else if (booksFinished >= 3) {
    insights.add('You finished $booksFinished books this month. Great progress!');
  } else if (booksFinished >= 1) {
    insights.add('You completed $booksFinished book${booksFinished == 1 ? '' : 's'} this month.');
  }

  if (totalPages >= 1000) {
    insights.add('With $totalPages pages read, you\'re turning pages like a pro.');
  } else if (totalPages >= 500) {
    insights.add('You read $totalPages pages — keep that momentum going!');
  }

  final hours = totalDuration.inHours;
  if (hours >= 20) {
    insights.add('Over $hours hours of reading time shows serious dedication.');
  } else if (hours >= 10) {
    insights.add('You spent $hours hours lost in books this month.');
  } else if (hours >= 5) {
    insights.add('You read for $hours hours — every page counts!');
  }

  if (sessionCount >= 30) {
    insights.add('$sessionCount reading sessions — reading is part of your daily rhythm.');
  } else if (sessionCount >= 15) {
    insights.add('You sat down to read $sessionCount times this month.');
  }

  if (insights.isEmpty) {
    return 'A solid start to your reading journey this month.';
  }

  return insights.join(' ');
}
