import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lecto/core/database/database.dart';
import 'package:lecto/core/router/app_router.dart';
import 'package:lecto/core/theme/theme_provider.dart';
import 'package:lecto/core/theme/themes.dart';
import 'package:lecto/features/books/providers/book_providers.dart';
import 'package:lecto/features/sessions/providers/session_providers.dart';

/// A beautifully redesigned active reading session screen.
///
/// Clean, focused view with a large digital timer, intuitive page tracking,
/// reading stats, and a smooth end-session flow.
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
    }
  }

  /// Shows the end-session bottom sheet with "Avez-vous terminé ce livre ?"
  Future<void> _showEndSessionSheet(Book book) async {
    final palette = ref.read(themePaletteProvider);
    final isDark = ref.read(isDarkModeProvider);

    final result = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: isDark ? palette.surfaceCardDark : palette.surfaceCardLight,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 36),
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
              const SizedBox(height: 28),
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.primary.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  size: 32,
                  color: palette.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Avez-vous terminé ce livre ?',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark ? palette.textOnDark : palette.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                book.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              // "Oui" button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(sheetContext, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Oui',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // "Non" button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(sheetContext, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.primary,
                    side: BorderSide(color: palette.primary.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Non',
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
      },
    );

    if (result == null || !context.mounted) return;

    final notifier = ref.read(activeSessionProvider.notifier);

    if (result == true) {
      // "Oui" — mark book as finished, end session, navigate to wrapped
      HapticFeedback.mediumImpact();

      // Update book status to finished
      final bookId = book.id;
      await ref.read(updateBookStatusProvider(bookId, ReadingStatus.finished).notifier).applyUpdate();

      // End session (already invalidates bookSessionsProvider + recentSessionsProvider)
      notifier.endSession();

      // Also invalidate home screen providers
      ref.invalidate(allBooksProvider);
      ref.invalidate(booksByStatusProvider);

      if (mounted) {
        // Navigate to wrapped — pop back and then push wrapped
        final now = DateTime.now();
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
          (route) => false,
        );
        Navigator.pushNamed(
          context,
          AppRouter.wrappedWith(now.month, now.year),
        );
      }
    } else {
      // "Non" — just end the session, navigate back
      HapticFeedback.mediumImpact();
      notifier.endSession();

      // Invalidate home screen providers
      ref.invalidate(allBooksProvider);
      ref.invalidate(booksByStatusProvider);
      ref.invalidate(recentSessionsProvider);

      if (mounted) {
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
                // Page tracker (-1 / Page / +1)
                // -------------------------------------------------------
                if (hasStarted)
                  _PageTracker(
                    currentPage: sessionState.currentPage,
                    onPageChange: (page) {
                      ref
                          .read(activeSessionProvider.notifier)
                          .updateCurrentPage(page);
                    },
                    palette: palette,
                    isDark: isDark,
                    onSurface: onSurface,
                  )
                else
                  _StartSessionButton(
                    palette: palette,
                    onPressed: () {
                      ref
                          .read(activeSessionProvider.notifier)
                          .startSession(widget.bookId);
                    },
                  ),

                const SizedBox(height: 16),

                // -------------------------------------------------------
                // Stats row
                // -------------------------------------------------------
                if (hasStarted)
                  _StatsRow(
                    pagesRead: sessionState.pagesRead,
                    elapsed: sessionState.elapsed,
                    palette: palette,
                    isDark: isDark,
                    muted: muted,
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
// Page tracker (-1 / Page / +1)
// ============================================================
class _PageTracker extends StatefulWidget {
  final int? currentPage;
  final ValueChanged<int> onPageChange;
  final ThemePalette palette;
  final bool isDark;
  final Color onSurface;

  const _PageTracker({
    required this.currentPage,
    required this.onPageChange,
    required this.palette,
    required this.isDark,
    required this.onSurface,
  });

  @override
  State<_PageTracker> createState() => _PageTrackerState();
}

class _PageTrackerState extends State<_PageTracker> {
  double _minusScale = 1.0;
  double _plusScale = 1.0;

  void _onMinusPress() {
    HapticFeedback.mediumImpact();
    setState(() => _minusScale = 0.9);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _minusScale = 1.0);
    });
    final page = widget.currentPage ?? 0;
    if (page > 0) {
      widget.onPageChange(page - 1);
    }
  }

  void _onPlusPress() {
    HapticFeedback.mediumImpact();
    setState(() => _plusScale = 0.9);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _plusScale = 1.0);
    });
    final page = widget.currentPage ?? 0;
    widget.onPageChange(page + 1);
  }

  @override
  Widget build(BuildContext context) {
    final page = widget.currentPage ?? 0;
    final canDecrement = page > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // -1 button
        AnimatedScale(
          scale: _minusScale,
          duration: const Duration(milliseconds: 100),
          child: GestureDetector(
            onTap: canDecrement ? _onMinusPress : null,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: canDecrement
                    ? widget.palette.primary.withValues(alpha: 0.1)
                    : widget.palette.textSecondary.withValues(alpha: 0.08),
              ),
              child: Icon(
                Icons.remove_rounded,
                size: 28,
                color: canDecrement
                    ? widget.palette.primary
                    : widget.palette.textSecondary.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        // Current page number
        Container(
          constraints: const BoxConstraints(minWidth: 80),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: widget.palette.primary.withValues(alpha: 0.08),
          ),
          child: Text(
            page.toString(),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: widget.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 20),
        // +1 button
        AnimatedScale(
          scale: _plusScale,
          duration: const Duration(milliseconds: 100),
          child: GestureDetector(
            onTap: _onPlusPress,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: widget.palette.primary.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.add_rounded,
                size: 28,
                color: widget.palette.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// Stats row (Pages / Temps / Moyenne)
// ============================================================
class _StatsRow extends StatelessWidget {
  final int? pagesRead;
  final Duration elapsed;
  final ThemePalette palette;
  final bool isDark;
  final Color muted;

  const _StatsRow({
    required this.pagesRead,
    required this.elapsed,
    required this.palette,
    required this.isDark,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    // Format elapsed time as HH:MM (no seconds)
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);
    final timeStr =
        '${hours.toString().padLeft(2, '0')}h${minutes.toString().padLeft(2, '0')}m';

    // Calculate pages/min
    final totalMinutes =
        elapsed.inMinutes > 0 ? elapsed.inMinutes : 1;
    final pages = pagesRead ?? 0;
    final avg = pages > 0
        ? (pages / totalMinutes).toStringAsFixed(1)
        : '0.0';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StatChip(
            label: 'Pages',
            value: pages.toString(),
            muted: muted,
          ),
          const SizedBox(width: 16),
          _StatChip(
            label: 'Temps',
            value: timeStr,
            muted: muted,
          ),
          const SizedBox(width: 16),
          _StatChip(
            label: 'Moyenne',
            value: '$avg p/min',
            muted: muted,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color muted;

  const _StatChip({
    required this.label,
    required this.value,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: muted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: muted.withValues(alpha: 0.6),
          ),
        ),
      ],
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
