import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lecto/core/database/database.dart';
import 'package:lecto/core/database/providers.dart';
import 'package:lecto/core/router/app_router.dart';
import 'package:lecto/core/theme/theme_provider.dart';
import 'package:lecto/core/theme/themes.dart';
import 'package:lecto/features/books/providers/book_providers.dart';
import 'package:lecto/features/sessions/providers/session_providers.dart';
import 'package:lecto/features/stats/providers/stats_providers.dart';

/// A beautifully redesigned active reading session screen.
///
/// Clean, focused view with a large digital timer and a smooth end-session
/// flow with pages input + summary.
class ActiveSessionScreen extends ConsumerStatefulWidget {
  final String bookId;

  const ActiveSessionScreen({super.key, required this.bookId});

  @override
  ConsumerState<ActiveSessionScreen> createState() =>
      _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends ConsumerState<ActiveSessionScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final sessionState = ref.read(activeSessionProvider);
    if (state == AppLifecycleState.paused && sessionState.isRunning) {
      ref.read(activeSessionProvider.notifier).pauseSession();
    } else if (state == AppLifecycleState.resumed && !sessionState.isRunning && sessionState.sessionId != null) {
      ref.read(activeSessionProvider.notifier).resumeSession();
    }
  }

  /// Shows the end-session bottom sheet with pages input,
  /// book-finished toggle, summary display, and navigation.
  Future<void> _showEndSessionSheet(Book book) async {
    final palette = ref.read(themePaletteProvider);
    final isDark = ref.read(isDarkModeProvider);
    final sessionState = ref.read(activeSessionProvider);

    // Pre-fill default pages: currentPage - startPage
    final defaultPages = sessionState.pagesRead ?? 0;
    final durationMinutes = sessionState.elapsed.inMinutes > 0
        ? sessionState.elapsed.inMinutes
        : 1;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: isDark ? palette.surfaceCardDark : palette.surfaceCardLight,
      builder: (sheetContext) {
        return _EndSessionSheet(
          book: book,
          palette: palette,
          isDark: isDark,
          defaultPages: defaultPages,
          durationMinutes: durationMinutes,
          elapsed: sessionState.elapsed,
        );
      },
    );

    if (result == null || !mounted) return;

    final pagesRead = result['pagesRead'] as int;
    final bookFinished = result['bookFinished'] as bool;
    final durationMin = result['durationMinutes'] as int;
    final pagesPerMin = pagesRead > 0
        ? (pagesRead / durationMin).toStringAsFixed(1)
        : '0.0';

    // Build summary string
    final hours = sessionState.elapsed.inHours;
    final minutes = sessionState.elapsed.inMinutes.remainder(60);
    final timeStr = hours > 0
        ? '${hours}h${minutes.toString().padLeft(2, '0')}m'
        : '${minutes}m';

    final summary =
        '$pagesRead pages lues en $timeStr ($pagesPerMin pages/min)';

    HapticFeedback.mediumImpact();

    final notifier = ref.read(activeSessionProvider.notifier);

    if (bookFinished) {
      // Mark book as finished
      final now = DateTime.now();
      ref.read(databaseProvider).updateBook(book.id, {
        'status': ReadingStatus.finished.name,
        'date_finished': now.toIso8601String(),
      });

      // End session with pagesRead directly (no startPage set)
      notifier.endSession(pagesRead: pagesRead);

      // Invalidate all related providers
      ref.invalidate(allBooksProvider);
      ref.invalidate(booksByStatusProvider);
      ref.invalidate(currentBookProvider(book.id));
      ref.invalidate(bookshelfStatsProvider);

      if (mounted) {
        // Show summary snackbar before navigating
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(summary),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate to wrapped
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
          (route) => false,
        );
        Navigator.pushNamed(
          context,
          AppRouter.wrappedWith(DateTime.now().month, DateTime.now().year),
        );
      }
    } else {
      // Not finished — just end session
      notifier.endSession(pagesRead: pagesRead);

      // Invalidate all related providers
      ref.invalidate(allBooksProvider);
      ref.invalidate(booksByStatusProvider);
      ref.invalidate(bookshelfStatsProvider);
      ref.invalidate(recentSessionsProvider);

      if (mounted) {
        // Show summary snackbar before navigating back
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(summary),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );

        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(themePaletteProvider);
    final isDark = ref.watch(isDarkModeProvider);
    final bookAsync = ref.watch(currentBookProvider(widget.bookId));
    final sessionState = ref.watch(activeSessionProvider);

    final bg = isDark ? palette.surfaceDark : palette.surfaceLight;
    final onSurface = isDark ? palette.textOnDark : palette.textPrimary;
    final muted = isDark
        ? palette.textOnDark.withValues(alpha: 0.5)
        : palette.textSecondary;

    final hasStarted =
        sessionState.isRunning || sessionState.sessionId != null;

    return bookAsync.when(
      loading: () => Scaffold(
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: bg,
        body: Center(child: Text('Erreur : $err')),
      ),
      data: (book) {
        if (book == null) {
          return Scaffold(
            backgroundColor: bg,
            body: const Center(child: Text('Livre introuvable')),
          );
        }

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            leadingWidth: 200,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Book cover (40×56)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 40,
                      height: 56,
                      child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: book.coverUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => Container(
                                color: palette.primary.withValues(alpha: 0.1),
                                child: Icon(
                                  Icons.menu_book_rounded,
                                  size: 20,
                                  color: palette.primary.withValues(alpha: 0.4),
                                ),
                              ),
                              errorWidget: (_, _, _) => Container(
                                color: palette.primary.withValues(alpha: 0.1),
                                child: Icon(
                                  Icons.menu_book_rounded,
                                  size: 20,
                                  color: palette.primary.withValues(alpha: 0.4),
                                ),
                              ),
                            )
                          : Container(
                              color: palette.primary.withValues(alpha: 0.1),
                              child: Icon(
                                Icons.menu_book_rounded,
                                size: 20,
                                color: palette.primary.withValues(alpha: 0.4),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Title + author
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          book.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          book.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              // Close button
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: muted,
                    size: 24,
                  ),
                  onPressed: () => Navigator.pop(context),
                  splashRadius: 20,
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 1),

                // "En cours de lecture" label
                Text(
                  'En cours de lecture',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: muted,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 32),

                // -------------------------------------------------------
                // Timer + Pause button
                // -------------------------------------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),
                    _TimerDisplay(
                      elapsed: sessionState.elapsed,
                      isRunning: sessionState.isRunning,
                      palette: palette,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 12),
                    // Pause/Resume button (only visible when session started)
                    if (hasStarted)
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: 1.0,
                        child: GestureDetector(
                          onTap: () {
                            final notifier =
                                ref.read(activeSessionProvider.notifier);
                            HapticFeedback.selectionClick();
                            if (sessionState.isRunning) {
                              notifier.pauseSession();
                            } else {
                              notifier.resumeSession();
                            }
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: palette.primary.withValues(alpha: 0.1),
                            ),
                            child: Icon(
                              sessionState.isRunning
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 24,
                              color: palette.primary,
                            ),
                          ),
                        ),
                      ),
                    const Spacer(flex: 2),
                  ],
                ),

                const SizedBox(height: 24),

                // -------------------------------------------------------
                // Start session button (only if not started)
                // -------------------------------------------------------
                if (!hasStarted)
                  _StartSessionButton(
                    palette: palette,
                    onPressed: () {
                      ref
                          .read(activeSessionProvider.notifier)
                          .startSession(widget.bookId);
                    },
                  ),

                const Spacer(flex: 2),

                // -------------------------------------------------------
                // End session button
                // -------------------------------------------------------
                if (hasStarted)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => _showEndSessionSheet(book),
                        icon: const Icon(Icons.stop_rounded, size: 22),
                        label: Text(
                          'Terminer la session',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: palette.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// End-session bottom sheet (pages input + finished toggle)
// ============================================================

class _EndSessionSheet extends StatefulWidget {
  final Book book;
  final ThemePalette palette;
  final bool isDark;
  final int defaultPages;
  final int durationMinutes;
  final Duration elapsed;

  const _EndSessionSheet({
    required this.book,
    required this.palette,
    required this.isDark,
    required this.defaultPages,
    required this.durationMinutes,
    required this.elapsed,
  });

  @override
  State<_EndSessionSheet> createState() => _EndSessionSheetState();
}

class _EndSessionSheetState extends State<_EndSessionSheet> {
  late int _pages;
  bool _bookFinished = false;

  @override
  void initState() {
    super.initState();
    _pages = widget.defaultPages > 0 ? widget.defaultPages : 0;
  }

  void _decrement() {
    if (_pages > 0) {
      HapticFeedback.selectionClick();
      setState(() => _pages--);
    }
  }

  void _increment() {
    HapticFeedback.selectionClick();
    setState(() => _pages++);
  }

  Future<void> _showPageInputDialog() async {
    final palette = widget.palette;
    final isDark = widget.isDark;
    final controller = TextEditingController(text: _pages.toString());

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? palette.surfaceCardDark : palette.surfaceCardLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Entrer le nombre de pages',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? palette.textOnDark : palette.textPrimary,
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: GoogleFonts.outfit(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: isDark ? palette.textOnDark : palette.textPrimary,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              filled: true,
              fillColor: palette.primary.withValues(alpha: 0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Annuler',
                style: GoogleFonts.inter(
                  color: palette.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                if (value != null && value >= 0) {
                  Navigator.pop(dialogContext, value);
                }
              },
              child: Text(
                'OK',
                style: GoogleFonts.inter(
                  color: palette.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result != null) {
      HapticFeedback.selectionClick();
      setState(() => _pages = result);
    }
  }

  void _confirm() {
    Navigator.pop(context, {
      'pagesRead': _pages,
      'bookFinished': _bookFinished,
      'durationMinutes': widget.durationMinutes,
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final isDark = widget.isDark;
    final book = widget.book;

    // Compute pages/min for live preview
    final effectiveMinutes =
        widget.durationMinutes > 0 ? widget.durationMinutes : 1;
    final avg = _pages > 0
        ? (_pages / effectiveMinutes).toStringAsFixed(1)
        : '0.0';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isDark
                  ? palette.textOnDark.withValues(alpha: 0.2)
                  : palette.textSecondary.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 20),

          // Book icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.primary.withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              size: 28,
              color: palette.primary,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'Terminer la session',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? palette.textOnDark : palette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            book.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: palette.textSecondary,
            ),
          ),

          const SizedBox(height: 28),

          // -------------------------------------------------------
          // Pages input section
          // -------------------------------------------------------
          Text(
            'Combien de pages avez-vous lues ?',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? palette.textOnDark : palette.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Number stepper
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Minus button
              GestureDetector(
                onTap: _pages > 0 ? _decrement : null,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: _pages > 0 ? 1.0 : 0.3,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: palette.primary.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      Icons.remove_rounded,
                      size: 28,
                      color: palette.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Pages display (tappable)
              GestureDetector(
                onTap: _showPageInputDialog,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 100),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: palette.primary.withValues(alpha: 0.08),
                  ),
                  child: Text(
                    _pages.toString(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: isDark ? palette.textOnDark : palette.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Plus button
              GestureDetector(
                onTap: _increment,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: palette.primary.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: 28,
                    color: palette.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // -------------------------------------------------------
          // Live preview: pages/min
          // -------------------------------------------------------
          if (_pages > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: palette.primary.withValues(alpha: 0.06),
              ),
              child: Text(
                '~ $avg pages/min',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: palette.textSecondary,
                ),
              ),
            ),

          const SizedBox(height: 20),

          // -------------------------------------------------------
          // Finished toggle
          // -------------------------------------------------------
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDark
                  ? palette.textOnDark.withValues(alpha: 0.05)
                  : palette.textSecondary.withValues(alpha: 0.06),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 22,
                  color: _bookFinished
                      ? palette.primary
                      : palette.textSecondary.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Avez-vous terminé ce livre ?',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? palette.textOnDark : palette.textPrimary,
                    ),
                  ),
                ),
                Switch(
                  value: _bookFinished,
                  onChanged: (val) => setState(() => _bookFinished = val),
                  activeColor: palette.primary,
                  activeTrackColor: palette.primary.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // -------------------------------------------------------
          // Confirm button
          // -------------------------------------------------------
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'Confirmer',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Timer display
// ============================================================
class _TimerDisplay extends StatelessWidget {
  final Duration elapsed;
  final bool isRunning;
  final ThemePalette palette;
  final bool isDark;

  const _TimerDisplay({
    required this.elapsed,
    required this.isRunning,
    required this.palette,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);
    final seconds = elapsed.inSeconds.remainder(60);

    final timeStr =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 200),
      style: GoogleFonts.outfit(
        fontSize: 64,
        fontWeight: FontWeight.w600,
        color: palette.primary,
        height: 1.1,
      ),
      child: Text(timeStr),
    );
  }
}



// ============================================================
// Start session button (before session begins)
// ============================================================
class _StartSessionButton extends StatelessWidget {
  final ThemePalette palette;
  final VoidCallback onPressed;

  const _StartSessionButton({
    required this.palette,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Prêt à lire ?',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.primary,
              boxShadow: [
                BoxShadow(
                  color: palette.primary.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
      ],
    );
  }
}
