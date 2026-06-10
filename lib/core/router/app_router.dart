import 'package:flutter/material.dart';
import 'package:lecto/features/books/screens/book_detail_screen.dart';
import 'package:lecto/features/onboarding/screens/onboarding_screen.dart';
import 'package:lecto/features/sessions/screens/active_session_screen.dart';
import 'package:lecto/features/sessions/screens/session_history_screen.dart';
import 'package:lecto/features/goals/screens/goals_screen.dart';
import 'package:lecto/features/wrapped/screens/wrapped_screen.dart';
import 'package:lecto/core/widgets/main_shell.dart';

class AppRouter {
  static const String home = '/';
  static const String sessions = '/sessions';
  static const String goals = '/goals';
  static const String wrapped = '/wrapped';
  static const String onboarding = '/onboarding';

  static String bookDetail(String bookId) => '/book/$bookId';
  static String session(String bookId) => '/session/$bookId';
  static String wrappedWith(int month, int year) => '/wrapped?month=$month&year=$year';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
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
        builder: (_) => WrappedScreen(initialMonth: month, initialYear: year),
      );
    }

    // Static routes
    switch (path) {
      case home:
        return MaterialPageRoute(builder: (_) => const MainShell());
      case sessions:
        return MaterialPageRoute(builder: (_) => const SessionHistoryScreen());
      case goals:
        return MaterialPageRoute(builder: (_) => const GoalsScreen());
      case AppRouter.onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      default:
        return MaterialPageRoute(builder: (_) => const MainShell());
    }
  }
}
