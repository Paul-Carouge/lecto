import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:lecto/core/database/database.dart';
import 'package:lecto/core/database/providers.dart';
import 'package:lecto/features/books/providers/book_providers.dart';
import 'package:lecto/features/stats/providers/stats_providers.dart';

part 'session_providers.g.dart';

// ============================================================
// Active reading session (timer + pages)
// ============================================================

/// State for an active reading session timer.
class ActiveSessionState {
  /// The database session ID (null if no session is active).
  final String? sessionId;

  /// The ID of the book being read.
  final String? bookId;

  /// The start time of the session.
  final DateTime? startTime;

  /// The elapsed duration since the session started.
  final Duration elapsed;

  /// The page the user started on.
  final int? startPage;

  /// The current page the user is on (updated live).
  final int? currentPage;

  /// Whether the timer is actively ticking.
  final bool isRunning;

  const ActiveSessionState({
    this.sessionId,
    this.bookId,
    this.startTime,
    this.elapsed = Duration.zero,
    this.startPage,
    this.currentPage,
    this.isRunning = false,
  });

  ActiveSessionState copyWith({
    String? sessionId,
    String? bookId,
    DateTime? startTime,
    Duration? elapsed,
    int? startPage,
    int? currentPage,
    bool? isRunning,
  }) {
    return ActiveSessionState(
      sessionId: sessionId ?? this.sessionId,
      bookId: bookId ?? this.bookId,
      startTime: startTime ?? this.startTime,
      elapsed: elapsed ?? this.elapsed,
      startPage: startPage ?? this.startPage,
      currentPage: currentPage ?? this.currentPage,
      isRunning: isRunning ?? this.isRunning,
    );
  }

  /// Returns the number of pages read so far (current - start).
  int? get pagesRead {
    if (currentPage == null || startPage == null) return null;
    final diff = currentPage! - startPage!;
    return diff >= 0 ? diff : null;
  }

  /// Computed alias for [pagesRead], accessible via the notifier.
  int? get pagesReadFromState => pagesRead;
}

/// Provider for the active reading session.
@Riverpod(keepAlive: true)
class ActiveSession extends _$ActiveSession {
  Timer? _timer;

  @override
  ActiveSessionState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return const ActiveSessionState();
  }

  /// Starts a new reading session for [bookId], optionally specifying a [startPage].
  void startSession(String bookId, {int? startPage}) {
    // End any active session first
    if (state.isRunning) {
      endSession();
    }

    final db = ref.read(databaseProvider);
    final session = db.startSession(bookId, startPage: startPage);

    // Automatically update book status to reading and set dateStarted
    final book = db.getBook(bookId);
    if (book != null && book.status != ReadingStatus.reading) {
      final now = DateTime.now();
      db.updateBook(bookId, {
        'status': ReadingStatus.reading.name,
        'date_started': (book.dateStarted ?? now).toIso8601String(),
      });
      ref.invalidate(allBooksProvider);
      ref.invalidate(booksByStatusProvider);
      ref.invalidate(currentBookProvider(bookId));
      ref.invalidate(bookshelfStatsProvider);
    }

    state = ActiveSessionState(
      sessionId: session.id,
      bookId: bookId,
      startTime: session.startTime,
      elapsed: Duration.zero,
      startPage: startPage,
      currentPage: startPage,
      isRunning: true,
    );

    // Start the one-second tick timer
    _timer?.cancel();
    final start = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(
        elapsed: DateTime.now().difference(start),
      );
    });
  }

  /// Updates the current page the user is on.
  void updateCurrentPage(int page) {
    if (!state.isRunning) return;
    state = state.copyWith(currentPage: page);
  }

  /// Pauses the timer without ending the session.
  void pauseSession() {
    if (!state.isRunning) return;
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  /// Resumes the timer from where it was paused.
  /// Uses the frozen [state.elapsed] as base so lock-screen time isn't counted.
  void resumeSession() {
    if (state.isRunning || state.sessionId == null) return;
    final now = DateTime.now();
    // Use the frozen elapsed from pause, not now.difference(startTime)
    // which would count phone-locked time as reading time.
    final baseElapsed = state.elapsed;
    if (baseElapsed == Duration.zero && state.startTime != null) {
      // First resume (never paused before) — compute from start
      state = state.copyWith(elapsed: now.difference(state.startTime!), isRunning: true);
    } else {
      state = state.copyWith(elapsed: baseElapsed, isRunning: true);
    }
    final start = now;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(
        elapsed: DateTime.now().difference(start) + state.elapsed,
      );
    });
  }

  /// Ends the current session, persists it to the database, and resets state.
  void endSession({int? endPage, int? pagesRead}) {
    if (state.sessionId == null) return;

    _timer?.cancel();

    final db = ref.read(databaseProvider);
    db.endSession(
      state.sessionId!,
      endPage: endPage ?? state.currentPage,
      pagesRead: pagesRead ?? state.pagesRead,
    );

    // Invalidate all dependent providers
    if (state.bookId != null) {
      final bookId = state.bookId!;
      ref.invalidate(bookSessionsProvider(bookId));
      ref.invalidate(bookPagesReadProvider(bookId));
      ref.invalidate(bookRemainingPagesProvider(bookId));
      ref.invalidate(activeBookSessionProvider(bookId));
    }
    ref.invalidate(recentSessionsProvider);
    ref.invalidate(allBooksProvider);
    ref.invalidate(booksByStatusProvider);
    ref.invalidate(bookshelfStatsProvider);
    ref.invalidate(monthlyStatsProvider(DateTime.now().year));
    ref.invalidate(monthlyDurationProvider(DateTime.now().year));
    ref.invalidate(topGenresProvider);

    state = const ActiveSessionState();
  }

  /// Finishes the current session with a manually-specified page count.
  ///
  /// [pagesRead] is the exact number of pages the user read (required).
  /// If [finishedBook] is `true`, the book's status is updated to `finished`
  /// and its `dateFinished` is set to now.
  ///
  /// Uses [AppDatabase.updateSessionPages] to persist the data, then
  /// invalidates all related providers and resets state.
  void finishSession({required int pagesRead, bool finishedBook = false}) {
    if (state.sessionId == null) return;

    _timer?.cancel();

    final db = ref.read(databaseProvider);
    final bookId = state.bookId;

    // Compute endPage from startPage + pagesRead if startPage is known
    final int? endPage = state.startPage != null
        ? state.startPage! + pagesRead
        : null;

    // Use the elapsed duration from the state
    final int durationSeconds = state.elapsed.inSeconds;

    // Persist via updateSessionPages (sets end_time, pages_read, etc.)
    db.updateSessionPages(
      state.sessionId!,
      pagesRead: pagesRead,
      endPage: endPage,
      durationSeconds: durationSeconds > 0 ? durationSeconds : null,
    );

    // If the user finished the book, update its status
    if (finishedBook && bookId != null) {
      final now = DateTime.now();
      db.updateBook(bookId, {
        'status': ReadingStatus.finished.name,
        'date_finished': now.toIso8601String(),
      });
    }

    // Invalidate all related providers
    if (bookId != null) {
      ref.invalidate(bookSessionsProvider(bookId));
      ref.invalidate(currentBookProvider(bookId));
      ref.invalidate(bookPagesReadProvider(bookId));
      ref.invalidate(bookRemainingPagesProvider(bookId));
      ref.invalidate(activeBookSessionProvider(bookId));
    }
    ref.invalidate(recentSessionsProvider);
    ref.invalidate(allBooksProvider);
    ref.invalidate(booksByStatusProvider);
    ref.invalidate(bookshelfStatsProvider);
    ref.invalidate(monthlyStatsProvider(DateTime.now().year));
    ref.invalidate(monthlyDurationProvider(DateTime.now().year));
    ref.invalidate(topGenresProvider);

    state = const ActiveSessionState();
  }

  /// Convenience getter that delegates to [ActiveSessionState.pagesRead].
  int? get pagesReadFromState => state.pagesRead;
}

// ============================================================
// Sessions for a specific book
// ============================================================

/// Provides the list of reading sessions for a given [bookId],
/// ordered by start time (newest first).
@Riverpod(keepAlive: true)
Future<List<ReadingSession>> bookSessions(BookSessionsRef ref, String bookId) async {
  final db = ref.watch(databaseProvider);
  return db.getSessionsForBook(bookId);
}

// ============================================================
// All recent sessions
// ============================================================

/// Provides all reading sessions across all books, ordered by
/// start time (newest first).
@Riverpod(keepAlive: true)
Future<List<ReadingSession>> recentSessions(RecentSessionsRef ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllSessions();
}
