import 'package:intl/intl.dart';

/// Utility functions for formatting dates, durations, page counts,
/// and other display values used throughout the Lecto app.
class Formatters {
  Formatters._();

  // ============================================================
  // Date formatting
  // ============================================================

  /// Formats a [DateTime] as a readable date, e.g. "Jan 15, 2025".
  static String formatDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat.yMMMd().format(date);
  }

  /// Formats a [DateTime] as a short date, e.g. "Jan 15".
  static String formatDateShort(DateTime? date) {
    if (date == null) return '—';
    return DateFormat.MMMd().format(date);
  }

  /// Formats a [DateTime] as a relative time (e.g. "2 hours ago", "Today", "Yesterday").
  static String formatRelativeDate(DateTime? date) {
    if (date == null) return '—';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    if (diff < 30) return '${(diff / 7).floor()} weeks ago';
    if (diff < 365) return '${(diff / 30).floor()} months ago';
    return '${(diff / 365).floor()} years ago';
  }

  /// Formats a [DateTime] to a full date-time string, e.g. "Jan 15, 2025 at 3:45 PM".
  static String formatDateTime(DateTime? date) {
    if (date == null) return '—';
    return DateFormat.yMMMd().add_jm().format(date);
  }

  /// Formats a month integer (1-12) to a short name, e.g. "Jan".
  static String formatMonth(int month) {
    if (month < 1 || month > 12) return '—';
    return DateFormat('MMM').format(DateTime(2000, month));
  }

  // ============================================================
  // Duration formatting
  // ============================================================

  /// Formats a [Duration] as a readable string, e.g. "2h 15m" or "45m".
  static String formatDuration(Duration? duration) {
    if (duration == null) return '—';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    if (minutes > 0) return '${minutes}m';
    final seconds = duration.inSeconds;
    if (seconds > 0) return '${seconds}s';
    return '0m';
  }

  /// Formats a [Duration] as a compact reading time string, e.g. "2h 30m".
  static String formatReadingTime(Duration? duration) {
    return formatDuration(duration);
  }

  /// Formats total seconds as a readable duration string.
  static String formatSeconds(int? seconds) {
    if (seconds == null || seconds <= 0) return '—';
    return formatDuration(Duration(seconds: seconds));
  }

  // ============================================================
  // Page count formatting
  // ============================================================

  /// Formats a page number or count, e.g. "245 pages" or "Page 42".
  static String formatPages(int? pages) {
    if (pages == null || pages <= 0) return '—';
    return '$pages page${pages == 1 ? '' : 's'}';
  }

  /// Formats a short page count (compact), e.g. "245p".
  static String formatPagesShort(int? pages) {
    if (pages == null || pages <= 0) return '—';
    return '${pages}p';
  }

  /// Formats a pair of page numbers as a range, e.g. "pp. 23–45".
  static String formatPageRange(int? start, int? end) {
    if (start == null && end == null) return '—';
    if (start == null) return 'p. $end';
    if (end == null) return 'p. $start';
    if (start == end) return 'p. $start';
    return 'pp. $start–$end';
  }

  // ============================================================
  // Numeric formatting
  // ============================================================

  /// Formats a number with a short scale, e.g. 1500 → "1.5K".
  static String formatCompactNumber(int? number) {
    if (number == null) return '—';
    if (number < 1000) return number.toString();
    if (number < 1000000) {
      final val = number / 1000;
      return '${val.toStringAsFixed(val == val.round() ? 0 : 1)}K';
    }
    final val = number / 1000000;
    return '${val.toStringAsFixed(val == val.round() ? 0 : 1)}M';
  }

  /// Formats a rating (0.0–5.0) with one decimal place, e.g. "4.5".
  static String formatRating(double? rating) {
    if (rating == null) return '—';
    return rating.toStringAsFixed(1);
  }

  /// Formats a percentage, e.g. 0.7532 → "75%".
  static String formatPercent(double? value) {
    if (value == null) return '—';
    return '${(value * 100).round()}%';
  }

  // ============================================================
  // Reading-specific formatting
  // ============================================================

  /// Formats the reading status into a human-readable label.
  static String formatStatus(String status) {
    switch (status) {
      case 'wantToRead':
        return 'Want to Read';
      case 'reading':
        return 'Currently Reading';
      case 'finished':
        return 'Finished';
      case 'abandoned':
        return 'Abandoned';
      default:
        return status;
    }
  }

  /// Returns an icon name for a given reading status.
  static String statusIcon(String status) {
    switch (status) {
      case 'wantToRead':
        return '📚';
      case 'reading':
        return '📖';
      case 'finished':
        return '✅';
      case 'abandoned':
        return '⏹️';
      default:
        return '📄';
    }
  }

  /// Formats a date range for a reading session, e.g. "Jan 15 → Jan 16".
  static String formatSessionDateRange(DateTime? start, DateTime? end) {
    if (start == null) return '—';
    if (end == null) return 'Started ${formatRelativeDate(start)}';
    return '${formatDateShort(start)} → ${formatDateShort(end)}';
  }

  /// Returns the month name and year for a wrapped view, e.g. "January 2025".
  static String formatMonthYear(int month, int year) {
    return '${DateFormat('MMMM').format(DateTime(year, month))} $year';
  }
}
