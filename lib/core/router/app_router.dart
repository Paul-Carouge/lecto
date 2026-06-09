import 'package:flutter/material.dart';
import 'package:lecto/features/home/screens/home_screen.dart';
import 'package:lecto/features/books/screens/library_screen.dart';
import 'package:lecto/features/books/screens/book_detail_screen.dart';
import 'package:lecto/features/books/screens/add_book_screen.dart';
import 'package:lecto/features/sessions/screens/active_session_screen.dart';
import 'package:lecto/features/sessions/screens/session_history_screen.dart';
import 'package:lecto/features/stats/screens/stats_screen.dart';
import 'package:lecto/features/goals/screens/goals_screen.dart';
import 'package:lecto/features/recommendations/screens/recommendations_screen.dart';
import 'package:lecto/features/wrapped/screens/wrapped_screen.dart';
import 'package:lecto/features/settings/screens/settings_screen.dart';

/// Simple named routes for the Lecto app.
///
/// Routes:
///   - / → HomeScreen
///   - /library → LibraryScreen
///   - /book/:id → BookDetailScreen
///   - /add-book → AddBookScreen
///   - /session/:bookId → ActiveSessionScreen
///   - /sessions → SessionHistoryScreen
///   - /stats → StatsScreen
///   - /goals → GoalsScreen
///   - /recommendations → RecommendationsScreen
///   - /wrapped → WrappedScreen (optional month/year via query params)
///   - /settings → SettingsScreen
class AppRouter {
  static const String home = '/';
  static const String library = '/library';
  static const String addBook = '/add-book';
  static const String sessions = '/sessions';
  static const String stats = '/stats';
  static const String goals = '/goals';
  static const String recommendations = '/recommendations';
  static const String wrapped = '/wrapped';
  static const String settings = '/settings';

  /// Generates a route path for a book detail by ID.
  static String bookDetail(String bookId) => '/book/$bookId';

  /// Generates a route path for a reading session by book ID.
  static String session(String bookId) => '/session/$bookId';

  /// Generates a route path for wrapped with optional month and year.
  static String wrappedWith(int month, int year) => '/wrapped?month=$month&year=$year';

  /// Route generator function for [MaterialApp.onGenerateRoute].
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    // Parse book/:id routes
    final uri = Uri.parse(settings.name ?? '/');
    final path = uri.path;
    final queryParams = uri.queryParameters;

    // Book detail: /book/:id
    if (path.startsWith('/book/')) {
      final bookId = path.split('/book/').last;
      if (bookId.isNotEmpty) {
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BookDetailScreen(bookId: bookId),
        );
      }
    }

    // Session: /session/:bookId
    if (path.startsWith('/session/')) {
      final bookId = path.split('/session/').last;
      if (bookId.isNotEmpty) {
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ActiveSessionScreen(bookId: bookId),
        );
      }
    }

    // Wrapped with optional params
    if (path == wrapped) {
      final month = queryParams['month'] != null
          ? int.tryParse(queryParams['month']!)
          : null;
      final year = queryParams['year'] != null
          ? int.tryParse(queryParams['year']!)
          : null;
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => WrappedScreen(
          initialMonth: month,
          initialYear: year,
        ),
      );
    }

    // Static routes
    switch (path) {
      case home:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const HomeScreen(),
        );
      case library:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LibraryScreen(),
        );
      case addBook:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AddBookScreen(),
        );
      case sessions:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SessionHistoryScreen(),
        );
      case stats:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const StatsScreen(),
        );
      case goals:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const GoalsScreen(),
        );
      case recommendations:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const RecommendationsScreen(),
        );
      case AppRouter.settings:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SettingsScreen(),
        );
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const HomeScreen(),
        );
    }
  }
}
